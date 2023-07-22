# escape=`

# Note: Time-consuming operation contains: Download, install choco, install app by choco, install MSBuilds, build ovs.
# The way to optimize this dockerfile is to reduce the time spent on these time-consuming operations
# 另一种方式是把耗时操作放前面，把其他操作放后面，这样不会因为其他操作改变文件系统导致耗时操作的缓存失效，可以避免每次build都要执行耗时操作。
# 最耗时是安装msbuilds，其次是用choco安装软件。编译ovs本身应该也比较耗时

# FROM mcr.microsoft.com/windows/servercore:ltsc2022
FROM mcr.microsoft.com/windows/servercore:ltsc2022

# Download all of what need to download

# ADD https://aka.ms/vs/16/release/vs_buildtools.exe C:\TEMP\vs_buildtools.exe
# ADD https://go.microsoft.com/fwlink/?linkid=2085767 C:\TEMP\wdksetup.exe

# ADD https://chocolatey.org/install.ps1 C:\TEMP\choco-install.ps1

# ADD https://nchc.dl.sourceforge.net/project/pthreads4w/pthreads4w-code-v3.0.0.zip C:\TEMP\pthreads4w-code.zip

# ADD https://www.openvswitch.org/releases/openvswitch-3.1.2.tar.gz C:\TEMP\openvswitch-3.1.2.tar.gz

# They above is slow, so use COPY instead of it
COPY ./res/* C:/TEMP/


# Install choco
# For process of install of choco, it below will be downloaded automatically
# Downloading https://community.chocolatey.org/api/v2/package/chocolatey/2.1.0 to C:\Users\ContainerAdministrator\AppData\Local\Temp\chocolatey\chocoInstall\chocolatey.zip
# This download above is slow, so local file instead of it.
RUN copy C:\TEMP\chocolatey.2.1.0.nupkg C:\TEMP\chocolatey.2.1.0.zip
RUN powershell C:\TEMP\choco-install.ps1 -ChocolateyDownloadUrl C:\TEMP\chocolatey.2.1.0.zip


# Install tools by choco include msys2, python3 and 7z
# To improve speed used local package instead of network source.
# COPY ./res/choco/*.nupkg C:/TEMP/choco/
RUN choco install --source=C:/TEMP/ msys2 --params "/NoUpdate /InstallDir:C:/msys2" -y
RUN choco install --source=C:/TEMP/ python311 -y
RUN choco install --source=C:/TEMP/ 7zip.install -y
RUN choco install --source=C:/TEMP/ wixtoolset -y


# Install MSBuilds, SDK, WDK and other MS tools.
# A 3010 error signals that requested operation 
# is successfull but changes will not be effective
# until the system is rebooted.
RUN C:\TEMP\vs_buildtools.exe --quiet --wait --norestart --nocache `
    --installPath C:\BuildTools `
    --add Microsoft.VisualStudio.Workload.VCTools `
    --add Microsoft.VisualStudio.Workload.MSBuildTools `
    --add Microsoft.VisualStudio.Component.VC.Runtimes.x86.x64.Spectre `
    --add Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    --add Microsoft.VisualStudio.Component.Windows10SDK.18362 `
    --add Microsoft.VisualStudio.Component.VC.14.24.x86.x64 `
    --add Microsoft.VisualStudio.Component.VC.14.24.x86.x64.Spectre `
 || IF "%ERRORLEVEL%"=="3010" EXIT 0

# Install wdk
RUN C:\TEMP\wdksetup.exe /q
RUN copy "C:\Program Files (x86)\Windows Kits\10\Vsix\VS2019\WDK.vsix" C:\TEMP\wdkvsix.zip
RUN 7z x C:\TEMP\wdkvsix.zip -OC:\TEMP\wdkvsix
RUN robocopy.exe /e "C:/temp/wdkvsix/$MSBuild/Microsoft/VC/v160" "C:/BuildTools/MSBuild/Microsoft/VC/v160" || EXIT 0

# Install VC runtime Redist
RUN mkdir "C:\Program Files (x86)\Common Files\Merge Modules"
RUN copy C:\TEMP\Microsoft_VC140_CRT_x64.msm "C:\Program Files (x86)\Common Files\Merge Modules\Microsoft_VC140_CRT_x64.msm"
RUN copy C:\TEMP\Microsoft_VC140_CRT_x86.msm "C:\Program Files (x86)\Common Files\Merge Modules\Microsoft_VC140_CRT_x86.msm"


# Add WixToolSet to MSBuild
RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "cp -rf '/c/Program Files (x86)/MSBuild/Microsoft/WiX/' /c/BuildTools/MSBuild/Microsoft/WiX/"


# Install pthreads4w
RUN 7z x C:/TEMP/pthreads4w-code.zip -OC:\TEMP\pthreads4w
RUN cd C:\TEMP\pthreads4w\pthreads4w-code-07053a521b0a9deb6db2a649cde1f828f2eb1f4f `
    && c:\BuildTools\VC\\Auxiliary\\Build\\vcvarsall.bat  x64  10.0.18362.0 `
    && nmake realclean VC
RUN mkdir C:\pthread\include\
RUN copy C:\TEMP\pthreads4w\pthreads4w-code-07053a521b0a9deb6db2a649cde1f828f2eb1f4f\*.h C:\pthread\include\*.h
RUN mkdir C:\pthread\bin\
RUN copy C:\TEMP\pthreads4w\pthreads4w-code-07053a521b0a9deb6db2a649cde1f828f2eb1f4f\*.dll C:\pthread\bin\*.dll
RUN copy C:\TEMP\pthreads4w\pthreads4w-code-07053a521b0a9deb6db2a649cde1f828f2eb1f4f\*.lib C:\pthread\bin\*.lib
RUN mkdir C:\pthread\lib\
RUN copy C:\TEMP\pthreads4w\pthreads4w-code-07053a521b0a9deb6db2a649cde1f828f2eb1f4f\*.lib C:\pthread\lib\*.lib


# Config msys2 and python to suport configure script of ovs
RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "pacman --noconfirm -S automake autoconf libtool make patch"
RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "mv /usr/bin/link /usr/bin/link_bkup"
RUN msys2_shell.cmd -defterm -no-start -use-full-path -c "cp `which python` `which python`3"

# Install pypiwin32
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple
RUN python3 -m pip install pypiwin32 --disable-pip-version-check


# Decompressing ovs source
RUN 7z x C:\TEMP\openvswitch-3.1.2.tar.gz -OC:\TEMP\
RUN 7z x C:\TEMP\openvswitch-3.1.2.tar -OC:\TEMP\
# After above operations, top dir of source of ovs is in:
# win: C:\TEMP\openvswitch-3.1.2, or msys2: /c/TEMP/openvswitch-3.1.2/


# Build installer
RUN c:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat x64 10.0.18362.0 `
    && msys2_shell.cmd -defterm -no-start -msys2 -use-full-path -c `
    "cd /c/TEMP/openvswitch-3.1.2/ && ./boot.sh" 
    
RUN c:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat x64 10.0.18362.0 `
    && msys2_shell.cmd -defterm -no-start -msys2 -use-full-path -c `
    "cd /c/TEMP/openvswitch-3.1.2/ && ./configure CC=./build-aux/cccl LD='`which link`' LIBS='-lws2_32 -lShlwapi -liphlpapi -lwbemuuid -lole32 -loleaut32' --prefix='C:/openvswitch/usr' --localstatedir='C:/openvswitch/var' --sysconfdir='C:/openvswitch/etc' --with-pthread='C:/pthread' --with-vstudiotarget='Release' --with-vstudiotargetver='Win10' " 
    
RUN c:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat x64 10.0.18362.0 `
    && msys2_shell.cmd -defterm -no-start -msys2 -use-full-path -c `
    "cd /c/TEMP/openvswitch-3.1.2/ && make -j8 "

# 为构建安装包准备目录及文件
RUN cd C:\TEMP\openvswitch-3.1.2\windows\ovs-windows-installer `
    && mkdir Services Binaries Symbols Redist Driver Driver\Win8 Driver\Win8.1 Driver\Win10 `
    && msys2_shell.cmd -defterm -no-start -use-full-path -c "cd /c/TEMP/openvswitch-3.1.2/ && cp -rf  ./datapath-windows/x64/Win10Release/ ./datapath-windows/x64/Win8Release/" `
    && msys2_shell.cmd -defterm -no-start -use-full-path -c "cd /c/TEMP/openvswitch-3.1.2/ && cp -rf  ./datapath-windows/x64/Win10Release/ ./datapath-windows/x64/Win8.1Release/"

RUN c:\BuildTools\VC\Auxiliary\Build\vcvarsall.bat x64 10.0.18362.0 `
    && msys2_shell.cmd -defterm -no-start -msys2 -use-full-path -c `
    "cd /c/TEMP/openvswitch-3.1.2/ && make windows_installer"

CMD ["cmd", "echo", "Please installer and driver to host machine.",`
    "&&", "echo", "ovs-windows-installer -> C:\TEMP\openvswitch-3.1.2\windows\ovs-windows-installer\bin\x64\Release\OpenvSwitch.msi",`
    "&&", "echo", "driver: xxx",`
    "&&", "pause"]

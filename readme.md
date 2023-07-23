# 构建安装包和驱动

Note: 若不想自己构建，直接下载release中的installer.zip，然后进行`安装驱动和安装包`步骤即可

### 下载安装docker for windows，并切换到 windows 容器

### 在docker中构建安装包和驱动，并把安装包和驱动从docker复制到主机

执行下列命令(在cmd或docker中均可，其中docker cp命令可能需要管理员权限)

note：第三行的D:\指定主机存放安装包和驱动的位置

~~~bat
docker build . -t ovs_installer
docker create --name temp_installer ovs_installer
docker cp temp_installer:C:\TEMP\installer.zip D:\
docker rm temp_installer
~~~


# 安装驱动和安装包
note：一定要按顺序操作：先装驱动，再创建虚拟交换机，再开启ovs扩展，在双击安装包安装，顺序不对可能有问题

### 在主机中安装驱动

解压D:\installer.zip

然后执行下面命令（在cmd或powershell中均可，需要管理员权限）

note: 可能需要禁用驱动程序强制签名或者开启测试模式才能成功安装驱动

~~~cmd
cd D:\installer\installer\driver
uninstall.cmd
install.cmd
~~~


### 在主机中安装ovs扩展到hyperv

执行下列命令。需要在带管理员权限的powershell中执行。

note：在执行命令前，需要先把一个物理网卡改成英文名，下面的例子是已经把一块物理网卡改名为"phy_netcard"

~~~ps
# pyh_netcard是你要使用的物理网卡的名字
New-VMSwitch "OVS-Extended-Switch" -NetAdapterName "phy_netcard"
Enable-VMSwitchExtension "Open vSwitch Extension" OVS-Extended-Switch
~~~



### 安装ovs本体

双击 D:\installer\installer\OpenvSwitch.msi 执行即可

### 现在即可在主机中使用ovs

note: 执行ovs命令需要管理员权限





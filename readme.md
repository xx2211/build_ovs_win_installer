# 构建安装包和驱动
### 在docker中构建安装包和驱动，并把安装包和驱动从docker复制到主机

执行下列命令(在cmd或docker中均可，其中docker cp命令可能需要管理员权限)

note：第三行的D:\指定主机存放安装包和驱动的位置

note：执行下面名需要把doker切换为winows容器

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

~~~cmd
cd D:\installer\installer\driver
uninstall.cmd
install.cmd
~~~

note: 可能需要禁用驱动程序强制签名或者开启测试模式才能成功安装驱动

### 在主机中安装ovs扩展到hyperv

执行下列命令。需要再有管理员权限的powershell中执行。
note：在执行命令前，你需要先把一个物理网卡改成英文名，下面的例子是 "phy_netcard"

~~~ps
# 以太网是你要使用的物理网卡的名字
New-VMSwitch "OVS-Extended-Switch" -NetAdapterName "phy_netcard"
Enable-VMSwitchExtension "Open vSwitch Extension" OVS-Extended-Switch
~~~



### 安装ovs本体

双击 D:\installer\installer\OpenvSwitch.msi 执行即可

### 现在即可在主机中使用ovs





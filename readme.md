1. execute `docker build .` command.
2. if command above is executed unsuccessfully, please execute it again unitl success.
3. if command above is executed successfully, you will look output below
~~~
...
...
 ---> 49b41ea92a81
Successfully built 49b41ea92a81

What's Next?
  View summary of image vulnerabilities and recommendations → docker scout quickview
~~~
49b41ea92a81 is only an example. Each execution may be different and can be determined according to the actual execution result.
4. 执行`xxx`把安装包从docker image复制到宿主机






#### 安装驱动

note：从此处往后，若无特殊说明，命令皆在cmd下执行

~~~cmd
cd c:\TEMP\install_driver
uninstall.cmd
install.cmd
~~~

note: 关于安装未签名驱动以及给驱动签名 https://blog.csdn.net/muaxi8/article/details/111625191#:~:text=On%20the%20Windows%20login%20screen%20or%20under%20the,After%20your%20computer%20reboots%2C%20select%20the%20Troubleshoot%20option.




~~~ps
# 以太网是你要使用的物理网卡的名字
New-VMSwitch "OVS-Extended-Switch" -NetAdapterName "phy_netcard"
Enable-VMSwitchExtension "Open vSwitch Extension" OVS-Extended-Switch

~~~

note：先装驱动，在创建虚拟交换机并开启ovs扩展，在双击安装包安装，顺序不对可能有问题

### 使用

安装完驱动后，直接双击生成好的安装包安装即可。


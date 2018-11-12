##Linux启动流程

####kernel
<pre>
kernel：进程管理，内存管理，网络管理，驱动程序，文件系统，安全功能
rootfs：
        glbic
库：函数集合，function功能的意思，属于代码片段，没有作为自己程序运行入口，但是可以其它程序所调用
   过程调用：procedure
   函数调用：function   

程序：

</pre>

####内核设计流派
<pre>
单内核：Linux
    把所有的功能集成于同一个程序
微内核：Windows，Solaris
    每种功能使用一个单独子系统实现

Linux内核特点：
    支持模块化：.ko
    支持模块的动态装载和卸载

组成部分：
    核心文件：/boot/vmlinuz-3.10.0-514.el7.x86_64
            /boot/vmlinuz-version-release
            ramdisk：
            Centos 5:/boot/initrd-version-release.img
            Centos 7:/boot/initramfs-3.10.0-514.el7.x86_64.img
    模块文件：/lib/modules/3.10.0-514.el7.x86_64
            /boot/modules/version-release
</pre>

####CentOS 系统启动流程：
<pre>
POST：加电自检
BOOT Sequence：  
    按次序查找各个引导设备，第一个有引导程序的设备即为本机启动用到的设备
    
    bootloader：引导加载器，程序
        windows：ntloader
        Linux：
            LTLO：LInux  LOader
            GRUB：GRand Uniform Bootloader
                    GRUB 0.x：GRUB Leagacy
                    GRUB 1.x：GRUB2
            功能：提供一个菜单，允许用户选择要启动系统或不同的内核版本，把用户选定的内核转载到内存中的特定空间中，解压，展开，将整个系统的控制权移交给内核
    MBR:
        446：bootloader
        64：分区表
        2：55AA

    GRUB：
        bootloader：1st stage存放无MBR中，真正的bootloader存放的内容，其目的是找到硬盘的上的第二阶段
        disk：2nd stage


    kernel：
        自身初始化：
            探测可识别到的所有硬件设备
            加载硬件驱动程序：（有可能会借助于ramdisk加载驱动）
            以只读方式挂载根文件系统
            运行用户空间第一个应用程序：/sbin/init
                init程序类型：
                            SysV：init，CentOS 5
                                  1. 系统初始化工作借助于脚本来实现，脚本中的大量命令，大量创建进程和销毁进程
                                  2. 服务直接又有依赖和先后顺序，不能并行运行，如第一个服务没有启动完成第二个服务无法启动，导致开机速度特别慢
                             配置文件：/etc/inittab

                            Upstart：乌班图所研发的，重命名init，CentOS 6
                                  采用D-bus这个机制，服务启动无需完成，一旦启动就会通知给相关服务进程，无需等待某服务完全启动后再进程启动，接近于并行方式运行，由于centos6没有充分发挥upstart特性，依然使用脚本启动服务
                            配置文件：/etc/inittab，/etc/init/*.conf

                            Systemd：systemct，CentOS 7
                                  1. 无需任何脚本，systemd本身就是强大的解释器，自己就可以启动，无需借助其它任何程序来启动服务，无需bash参与
                                  2. systmd不真正在系统启动初始化的时候去初始化任何服务，只要服务没有用到，告诉你已经启动了，实际上没有启动，什么时候启动呢在第一次访问到时候才会真正的启动
                            配置问：/usr/lib/systemd/system，/etc/systemd/system
            

    ramdisk：
            内核中的特性之一：使用缓冲和缓存对磁盘上的文件访问
                ramdisk -- ramfs
                CentOS 5：initrd，工作程序：mkinitrd
                CentOS 6：initramfs，工具程序：dracut

</pre>


####系统初始化
<pre>
    POST -- Bootsequnce（Bios）--Bootload（MBR）--Kernel（ramdisk）--rootfs（只读）--init（systemd）

/sbin/init
    CentOS 5：
        运行级别：为了系统的运行或维护等应用目的而设定的
        0-6:7个级别
            0：关机
            1：单用户模式（root 无需登录），single，维护模式
            2：多用户模式，会启动网络功能，但不会启动NFS，维护模式
            3：多用户模式，正常模式，文件界面也叫命令行界面
            4：预留级别：可同3级别
            5：多用户级别，正常模式，图形界面
            6：重启
        默认级别：
             3,5
        切换级别 
             init #
        查看级别：
             who -r
             runlevel
    配置文件：/etc/inittab
        每一行定义一种action以及与之对应的processs
        
    chkconfig命令
        查看服务所在所有级别的启动或关闭设定情形
        
        添加：chkconfig --add name
        查询：chkconfig --list name
        删除：chkconfig --del name
        设置：chkconfig  name on|off
             chkconfig --devel 345 name on|off 省略表示2345
        
        注意：自定义脚本使用chkconfig管理需要增加如下两项
             # chkconfig: 345 13 95  不要和系统现有的冲突否则chkconfig --add 加入不成功
             # discription: message
            
             正常级别下，最后一个启动服务S99local设置没有链接至/etc/rc.d/init.d一个服务脚本，而指向了/etc/rc.local脚本，因此，不便或不需要为服务脚本放置于/etc/rc.d/init.d/目录，且又想开机自动运行的命令，可直接放置于/etc/rc.d/rc.local文件中
            

        /etc/rc.d/rc.sysinit：系统初始化脚本
            1. 设置主机名
            2. 设置欢迎信息
            3. 激活udev和selinux
            4. 挂载/etc/fstab文件中定义的文件系统
            5. 检测根文件系统，并以读写方式重新挂载根文件系统
            6. 设置系统时钟
            7. 激活swap设备
            8. 根据/etc/sysctl.conf文件设置内核参数
            9. 加载额外设备的驱动设备
            10. 清理操作
              
    CentOS 6 ：
            POS -- Boot Sequence -- BootLoader（MBR）-- Kernel（ramdisk）-- rootfs -- switchroot --/sbin/init -- (/etc/inittab  /etc/init/*.conf) -- 设定默认运行级别 -- 系统初始化脚本 -- 关闭或启动对应级别下的服务 --启动终端
            init程序为：upstart，其配置文件
            /etc/inittab   /etc/init/*.conf
            /etc/rc.d/rc.sysinit
    
</pre>


####GRUB(BOOT Loader)
<pre>
    grub：Grand Unified Bootloader
        grub 0.x：grub legacy
        grub 1.x：grub2


    grub legacy：
        stage1：mbr
        stage1_5：mbr之后的扇区，让stage1中的bootloader能够识别stage2所在分区上的文件系统
        stage2：磁盘分区(/boot/grub/)
        配置文件：/boot/grub/grub.conf <-- /etc/grub.conf
        
        stage2及内核等通常放置于一个基本磁盘分区
            功能：
                (1)提供菜单，并提供交换式接口
                    编辑模式：用于编辑菜单
                    命令模式：交互式接口
                (2)加载用户选择的内核或操作系统
                    允许传递参数给内核
                    可以隐藏此菜单
                (3)为菜单提供了保护机制
                    为编辑菜单进行认证
                    为启动内核或操作系统进行认证

   grub如何识别设备：
        (hd0,0)
            hd0：磁盘编号，用数字表示，从0开始
            0：分区编号，用数字表示，从0开始
        


   grub的命令行接口
       help：获取帮助列表
       help key：对响应的命令
       root (hd0,0)相当于cd 进入某个目录和分区
       find (hd0,0)相当于ls 查看目录下的文件
       kernel /path/to/kernel_file：设置本次启动时用到的内核文件
                                    额外还可以添加许多内核支持使用的cmdline参数
       initrd /path/to/initramfs_file：设定为选定的内核提供额外文件的ramdisk，ramdisk需要和内核版本完全一致否则无法加载
       boot：引导启动选定的内核
   
       手动在grub命令行接口启动系统：
            grub> root (hd0,0)切换至内核文件所在的分区设备上
            grub> kernel /vmlinuxz-VERSION-RELEASE ro root=/dev/DEVICE 如果boot分区没有单独分区，就使用如boot目录在/分区下面：kernel /boot/vmlinuxz-VERSION-RELEASE ro root=/dev/DEVICE
            grub> initrd /initramfs-VERSION-RELEASE.img
            grub> boot
        

    配置文件：/boot/grub/grub.conf
        配置项：
            default=0：设定默认启动菜单项，落单项(title)编号从0开始
            timeout=5：指定菜单项等待选择的时长
            splashimage：(hd0,0)/grub/splash.xpm.gz指明菜单背景的图片文件路径
            hiddenmenu：隐藏菜单
            password --md5 $1$Rnhbo/$oqFW745CMY4icqb14l66x/菜单编辑认证
            title CentOS (2.6.32-431.el6.x86_64)定义菜单项“标题”，可出现多次
                root (hd0,0)grub查找stage2及kernel文件所在的设备分区，为grub的“根”，而非文件系统的"根"
                kernel /vmlinuz-2.6.32-431.el6.x86_64 ro root=UUID=d448f2db-3ada-4fe0-bf4e-ec773626f8b8 rd_NO_LUKS rd_NO_LVM LANG=en_US.UTF-8 rd_NO_MDSYSFONT=latarcyrheb-sun16 crashkernel=auto  KEYBOARDTYPE=pc KEYTABLE=us rd_NO_DM rhgb quiet启动内核
                initrd /initramfs-2.6.32-431.el6.x86_64.img内核匹配的ramfs文件
                password --md5 $1$Rnhbo/$oqFW745CMY4icqb14l66x/启动选定的内核或操作系统进行认证
                密码使用grub-md5-crypt命令即可


    进入单用户模式：
        1. 编辑grub菜单（选定要编辑的title，而后使用e命令）
        2. 在选定的kernel后附加1，s或single都可以
        3. 在kernel所在行，键入"b"命令

    安装grub：
        1. grub-install 
           grub-install --root-directory=/ /dev/sda  
        2. grub
           grub> root (hd0,0)
           grub> setup (hd0)
           修复grub，确保文件和目录都要存在(boot目录，stage1，stage1_5，stage2都要存在)，否则无法修复
        
        centos 7下面
        3. grub>insmod xfs
           grub>set root=(hd0,1)分区编号从1开始        
           grub>linux16 /vmlinuz-xxxxx ro root=/dev/mapper/centos-root quiet
           grub>initrd16 /initramfs-.xxxxx.img
</pre>

<pre>
git is best world source soft
</pre>

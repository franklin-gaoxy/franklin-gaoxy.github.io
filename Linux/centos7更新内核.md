# centos7 更新内核

以centos7.9为例,默认内核版本是3.10.0

查看内核版本:

```shell
uname -r
```

效果

```shell
[root@localhost ~]# uname -r 
3.10.0-1160.el7.x86_64
```

#### 添加repo仓库

```shell
sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
sudo rpm -Uvh https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
```

#### 安装内核

##### 安装最新稳定版

```shell
sudo yum --enablerepo=elrepo-kernel install kernel-ml
```

##### 安装最新主线版

```shell
sudo yum --enablerepo=elrepo-kernel install kernel-lt
```

> 如果遇到问题:
> 
> ```shell
> Transaction check error:
>   installing package kernel-ml-6.8.1-1.el7.elrepo.x86_64 needs 2MB on the /boot filesystem
> 
> Error Summary
> -------------
> Disk Requirements:
>   At least 2MB more space needed on the /boot filesystem.
> ```
> 
> 那么则卸载现有的
> 
> ```shell
> [root@localhost ~]# rpm -q kernel
> kernel-3.10.0-1160.el7.x86_64
> kernel-3.10.0-1160.114.2.el7.x86_64
> [root@localhost ~]# yum remove kernel-3.10.0-1160.el7.x86_64 kernel-3.10.0-1160.114.2.el7.x86_64ystem.
> ```
> 
> remove 后面的参数就是上面查询出来的包

#### 更新grub配置

```shell
sudo grub2-mkconfig -o /boot/grub2/grub.cfg
sudo grub2-set-default 0
```

```shell
reboot
```

然后重新检查

```shell

```

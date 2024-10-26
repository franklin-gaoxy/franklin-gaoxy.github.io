# lsblk 命令更新

## Centos7

```shell
wget https://cbs.centos.org/kojifiles/packages/util-linux/2.29/2.el7/src/util-linux-2.29-2.el7.src.rpm
wget https://cbs.centos.org/kojifiles/packages/util-linux/2.29/2.el7/x86_64/libfdisk-2.29-2.el7.x86_64.rpm
wget https://cbs.centos.org/kojifiles/packages/util-linux/2.29/2.el7/x86_64/libuuid-2.29-2.el7.x86_64.rpm
wget https://cbs.centos.org/kojifiles/packages/util-linux/2.29/2.el7/x86_64/libblkid-2.29-2.el7.x86_64.rpm
wget https://cbs.centos.org/kojifiles/packages/util-linux/2.29/2.el7/x86_64/libsmartcols-2.29-2.el7.x86_64.rpm

yum localinstall \
util-linux-2.29-2.el7.x86_64.rpm \
libfdisk-2.29-2.el7.x86_64.rpm \
libmount-2.29-2.el7.x86_64.rpm \
libuuid-2.29-2.el7.x86_64.rpm \
libblkid-2.29-2.el7.x86_64.rpm \
libsmartcols-2.29-2.el7.x86_64.rpm

yum localinstall -y --setopt=protected_multilib=false util-linux-2.29-2.el7.x86_64.rpm libfdisk-2.29-2.el7.x86_64.rpm libmount-2.29-2.el7.x86_64.rpm libuuid-2.29-2.el7.x86_64.rpm libblkid-2.29-2.el7.x86_64.rpm libsmartcols-2.29-2.el7.x86_64.rpm
```
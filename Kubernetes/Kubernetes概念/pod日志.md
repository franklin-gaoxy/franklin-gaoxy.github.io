
通过命令
```shell
kubectl logs pod <pod name> -f
```
可以查看一个pod的所有运行日志.

这些运行日志统一保存在pod运行节点的/var/log/pods 目录下.在这个目录下可以看到例如:
```shell
root@debian:/var/log/pods# ls
default_printlog-6c4bbcfd6b-xdblw_2eca6ed6-f25b-4261-8c3f-c811f9391b6a     kube-system_kube-apiserver-master_61ddeae7ec5b3433eaca3fe400213025
kube-flannel_kube-flannel-ds-tj2cn_db7bb24c-6ab9-49d3-ab5f-c1abf213ef46    kube-system_kube-controller-manager-master_ae026680807d852435a47a1328392e1a
kube-system_coredns-74586cf9b6-5x648_25bc85bb-43b1-49c1-9008-324716dc8eb6  kube-system_kube-proxy-l8ntg_607efbc1-24d2-42f0-b262-0605da4b4645
kube-system_coredns-74586cf9b6-z26rd_d1887657-f095-4a46-9b84-52063239be70  kube-system_kube-scheduler-master_8c24129959637d41b500d260692e136b
kube-system_etcd-master_b63cf78908bc654dd04a10715923a599
```
名称格式: <namespace name>_<pod name>/<container name>
每个目录下存储的不是日志文件,依然是目录.他的目录是container的目录.因为一个pod可以有多个容器,所以每个容器一个单独的目录.
继续往下,路径: /var/log/pods/default_printlog-6c4bbcfd6b-xdblw_2eca6ed6-f25b-4261-8c3f-c811f9391b6a/printtime/0.log
这里的0.log 就是运行的容器的日志了.当服务重启后,会出现1.log 2.log ....以此类推.
但是这个日志文件序号会一直增加,之前的不会一直保留.比如在经历过一次重启后,日志文件会变成1.log,之前的0.log会被删除.
> 但是需要注意的是,pod一旦被重启,那么整个目录都会被删除.
> 这里说的是pod重启而非容器重启.容器重启是container内部进程异常导致的,但是pod重启比如 删除 ,这样连带存放日志的目录会被一并清空.





# Kubernetes Service的实现

## 基础内容

在了解Service之前,需要先了解一些额外的知识:

1. 命令: ip route show table all
2. DNAT
3. IPVS和iptables
4. 基础的网络知识(网关,网段或子网,转发)

### 1. 命令 ip route show table all

这条命令会列出主机内所有的路由.内容展示包含了对应的网段或者IP,要通过那个虚拟设备发送出去.示例:

```shell
root@debian:~/kubernetes# ip route show table all 
default via 10.0.0.2 dev ens33 onlink 
10.0.0.0/24 dev ens33 proto kernel scope link src 10.0.0.50 
10.244.0.0/24 dev cni0 proto kernel scope link src 10.244.0.1 
local 10.0.0.50 dev ens33 table local proto kernel scope host src 10.0.0.50 
broadcast 10.0.0.255 dev ens33 table local proto kernel scope link src 10.0.0.50 
local 10.96.0.1 dev kube-ipvs0 table local proto kernel scope host src 10.96.0.1 
......
```

摘取一条,比如:`local 10.96.0.1 dev kube-ipvs0 table local proto kernel scope host src 10.96.0.1`
local：这表示这是一个本地路由，用于指示目标地址是本地主机。
10.96.0.1：目标地址,即要匹配的 IP 地址.
dev kube-ipvs0：指定了数据包应该通过的网络接口，即 kube-ipvs0.
table local：指定了路由表名称,即 local 表.
proto kernel：表示该路由表项是内核生成的.
scope host：表示该路由的作用域仅限于本地主机.
src 10.96.0.1：源 IP 地址,即数据包的出站地址.

### 2. DNAT

在网络中发送数据包,都是要写明源IP地址及目标IP地址等信息的.可以参考OSI模型.
而DNAT就是,修改数据包中的目标IP为另一个IP,源IP不变.然后重新把这个数据包发送出去.实际上就是一个转发.
![](https://img-blog.csdnimg.cn/c868c3e006394e9ca854e89aef3f9fa4.png#id=sj23T&originHeight=461&originWidth=1370&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)

### 3. IPVS和iptables

kube-proxy是k8s中的一个组件.主要负责网络相关的事情,或者说Service就是基于kube-proxy实现的.
而kube-proxy实际上是调用了系统的iptables和IPVS.所以Service也是基于他们两个实现的.
前者是防火墙,后者是一个性能更好的转发服务.两者在k8s集群中起到的作用都是转发数据包,也就是DNAT.

查看IPVS：

```shell
root@debian:~/kubernetes# ipvsadm -Ln
IP Virtual Server version 1.2.1 (size=4096)
Prot LocalAddress:Port Scheduler Flags
  -> RemoteAddress:Port           Forward Weight ActiveConn InActConn
TCP  10.96.0.1:443 rr
  -> 10.0.0.50:6443               Masq    1      3          0         
TCP  10.96.0.10:53 rr
  -> 10.244.0.24:53               Masq    1      0          0         
  -> 10.244.0.25:53               Masq    1      0          0         
TCP  10.96.0.10:9153 rr
  -> 10.244.0.24:9153             Masq    1      0          0         
  -> 10.244.0.25:9153             Masq    1      0          0         
TCP  10.107.158.131:80 rr
  -> 10.244.0.30:80               Masq    1      0          0         
  -> 10.244.0.33:80               Masq    1      0          0         
  -> 10.244.0.34:80               Masq    1      0          0         
UDP  10.96.0.10:53 rr
  -> 10.244.0.24:53               Masq    1      0          0         
  -> 10.244.0.25:53               Masq    1      0          0
```

> rr表示轮询策略。


### 4. Service

Service 是一种抽象，用于定义一组 Pod 的逻辑网络端点。它是 Kubernetes 集群内部的一种资源对象，用于实现服务发现和负载均衡。
Service对应了一组endpoint。每个endpoint都是一个Pod的IP地址，他是基于IPVS实现的，所以你访问Service可以转发到对应的Pod上。
示例：

```shell
root@debian:~/kubernetes# kubectl get service
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP   34d
nginx        ClusterIP   10.107.158.131   <none>        80/TCP    36m
```

现在，集群里有一个nginx的Service。

```shell
root@debian:~/kubernetes# kubectl get endpoints -o wide 
NAME         ENDPOINTS                                      AGE
kubernetes   10.0.0.50:6443                                 34d
nginx        10.244.0.30:80,10.244.0.33:80,10.244.0.34:80   36m
```

查看他们对应的endpoints，可以看到nginx对应了三个IP地址。

```shell
root@debian:~/kubernetes# kubectl get pod -o wide 
NAME                                READY   STATUS    RESTARTS   AGE    IP            NODE     NOMINATED NODE   READINESS GATES
nginx-deployment-6595874d85-5hpvq   1/1     Running   0          4m9s   10.244.0.33   master   <none>           <none>
nginx-deployment-6595874d85-mm2m5   1/1     Running   0          4m9s   10.244.0.34   master   <none>           <none>
nginx-deployment-6595874d85-qtnwb   1/1     Running   0          41m    10.244.0.30   master   <none>           <none>
```

最后，我们看一下Pod的IP地址，和endpoint的是完全对应的。而endpoints和Service ClusterIP的地址，也是在上面ipvs表中可以找到对应关系的。

**所以，当创建或者更新了一个Pod的时候，controller会去同步更新endpoint的地址。接下来endpoint通知kube-proxy，kube-proxy更新IPVS的规则。**

## Service的实现

![](https://img-blog.csdnimg.cn/bd0f43c39d704a3a97d009d89d5ab1ca.png#id=EgGvE&originHeight=547&originWidth=1042&originalType=binary&ratio=1&rotation=0&showTitle=false&status=done&style=none&title=)

当Pod对一个Service发起请求后：

首先通过集群DNS解析到Service的IP地址。然后数据包源IP填写为当前Pod自己的IP，目标IP填写为对应的Service的IP，然后这个数据包通过虚拟设备来到宿主机。

> 对于虚拟设备和如何来到宿主机，可以参考[docker 网络通信原理](https://blog.csdn.net/weixin_44455125/article/details/124851836)，[kubernetes flannel 网络](https://blog.csdn.net/weixin_44455125/article/details/124872564)，[flannel的host-gw与calico](https://blog.csdn.net/weixin_44455125/article/details/124935012)。或者参考 [深入剖析 Kubernetes 张磊](https://time.geekbang.org/column/intro/100015201?tab=catalog)。


数据包来到宿主机后，这里就和Pod和Pod通信不同了。
通过命令可以看到，service的IP地址和Pod的IP地址完全不是一个网段：

```shell
root@debian:~/kubernetes# kubectl get pod -o wide 
NAME                                READY   STATUS    RESTARTS   AGE   IP            NODE     NOMINATED NODE   READINESS GATES
nginx-deployment-6595874d85-5hpvq   1/1     Running   0          14m   10.244.0.33   master   <none>           <none>
nginx-deployment-6595874d85-mm2m5   1/1     Running   0          14m   10.244.0.34   master   <none>           <none>
nginx-deployment-6595874d85-qtnwb   1/1     Running   0          51m   10.244.0.30   master   <none>           <none>
root@debian:~/kubernetes# kubectl get service -o wide 
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE   SELECTOR
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP   34d   <none>
nginx        ClusterIP   10.107.158.131   <none>        80/TCP    50m   app=nginx
```

Pod的地址是`10.244.0.30`，而Service的地址是`10.107.158.131`。
这就意味着，请求Service的数据包来到宿主机内核后，不能像其他到Pod的数据包一样直接通过CNI进行转发。

所以接下来查看下路由表：

```shell
root@debian:~/kubernetes# ip route show table all|grep "10.107.158.131"
local 10.107.158.131 dev kube-ipvs0 table local proto kernel scope host src 10.107.158.131
```

在这里可以看到。路由表中过滤了一下对应的IP地址，可以看到他要通过kube-ipvs0这个虚拟设备发出。
这个虚拟设备也是kube-proxy添加的了，这个虚拟设备就像一根网线，一端在宿主机上，一段对接到了IPVS。数据包接下来通过kube-ipvs0发送给了IPVS，IPVS根据自己的策略轮询选择一个endpoints：

```shell
# 这里只截取了重要部分
root@debian:~/kubernetes# ipvsadm -Ln
TCP  10.107.158.131:80 rr
  -> 10.244.0.30:80               Masq    1      0          0         
  -> 10.244.0.33:80               Masq    1      0          0         
  -> 10.244.0.34:80               Masq    1      0          0
```

IPVS里有目标IP为`10.107.158.131`的这一条记录。然后从对应的这三个IP轮询获取一个，重新DNAT数据包，比如选择了`10.244.0.30`这个IP，那么DNAT后数据包的目标IP就改为了`10.244.0.30`。

IPVS自己是发送不了数据包的。他只能把这个数据包重新发送到宿主机的网络栈里。但是这个时候经过IPVS加工处理过的数据包，和Pod请求Pod的数据包没什么区别了。源IP是发送数据包的Pod的IP，目标是nginx 的一个Pod的IP。
所以，主机内核就会根据路由表找到目标IP所在的主机节点发送出去。这里会根据使用的CNI和模式的不同，采取的策略也不同，同样参考上面的文档。但是数据包已经可以正常发送到对端Pod了。

## 简述

数据包从pod内发出后，在主机内核匹配路由表转发给了IPVS。IPVS虽然说是负载，但是实际上只做了一个DNAT的操作。然后操作结束后数据包的目标IP就不再是Service的，而是对端Pod的了。接下来数据包重新发送到主机网络栈，主机网络栈就可以根据CNI配置的规则进行下一步的转发了。

对于IPVS如何知道Pod的IP，是因为contaoller manage在创建Pod后，会更新endpoints，然后告知 kube-proxy。kube-proxy会去操作修改IPVS的规则表。这样，IPVS就可以轮流的使用多个IP转发数据包了。

所以kube-proxy实际上是操作的IPVS去工作。他们负责给每个节点的IPVS规则表里，加上整个集群的Service对应endpoints的规则。当集群Service较多的时候，iptables的性能就不如IPVS了。

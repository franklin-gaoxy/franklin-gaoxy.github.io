参考文档: [https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing](https://github.com/kubernetes/kubeadm/blob/main/docs/ha-considerations.md#options-for-software-load-balancing)
![](https://cdn.nlark.com/yuque/0/2023/svg/22303590/1689038998288-2ff6946c-db04-494d-80ee-38d521a00d59.svg#clientId=u11b4c486-2557-4&from=paste&height=611&id=uf8b147cc&originHeight=150&originWidth=200&originalType=url&ratio=1.25&rotation=0&showTitle=false&status=done&style=none&taskId=uaa514fc5-83fe-4c2d-aedc-4725332276f&title=&width=814)
这种方案下,三个节点上每个都需要安装scheduler controller-manager api-server etcd.
同时etcd组成集群,在前面增加负载均衡用于转发请求.负载均衡增加keepalived,生成虚拟IP.不管是worker还是客户端请求的时候都是访问了虚拟IP.接下来对应虚拟IP节点讲请求转发到控制平面节点.

## haproxy配置
```go
# /etc/haproxy/haproxy.cfg
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the control plane nodes
#---------------------------------------------------------------------
frontend apiserver
    bind *:${APISERVER_DEST_PORT}
    mode tcp
    option tcplog
    default_backend apiserver

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
        server ${HOST1_ID} ${HOST1_ADDRESS}:${APISERVER_SRC_PORT} check
        # [...]
```

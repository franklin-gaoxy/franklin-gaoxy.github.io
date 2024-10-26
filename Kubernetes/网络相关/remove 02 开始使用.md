# 简介

cilium使用eBPF(calico类似),同时支持封装(XVLAN/Geneve)和不封装两种模式,封装模式下性能会降低,但是这种情况的兼容性是最好的(启用巨型帧可以大幅缓解).不封装的情况下,性能较好,但是要求比较高.

同时,cilium还支持ServiceMesh,还可以监控服务流量请求,还可以替代kube-proxy.

其他:
支持BGP(边界网关,可以让一个路由器内部的内网机器,访问到另一个路由器内部的内网机器,简单来说是通过在路由表配置另一个路由器的内网网段来实现)

## 简介附属内容

### 启用巨型帧

#### Debian系统

修改网络配置文件 `/etc/network/interfaces`

```
iface eth0 inet manual
    up ifconfig eth0 jumbo 9000
```

### 封装和本机路由

[封装和本机路由](https://docs.cilium.io/en/stable/network/concepts/routing/#encapsulation)

# 组件概念

cilium agent: 运行在每个节点,负责配置该节点的网络

CLI: 客户端工具,可以查看cilium的服务状态,和修改操作cilium网络

Cilium Operator:负责管理集群中的任务

hubble: 在每个节点运行,负责监控服务网络

hubble-relay: 监控所有hubble的服务器

hubble-cli: hubble的客户端,连接到hubble-relay来检查事件和状态

hubble-ui: 提供图形页面的展示

# cilium

> 为了避免出现更多问题,尽量不要修改容器网段.
>
> 已知问题为如果修改容器网段为192.168.0.0/16,那么节点可能出现导入网络后依然处于NotReady状态(基于Ubuntu 24版本 kubernetes 1.28)
>
> 第二尽量创建集群的时候不要不安装kube-proxy,但是安装的时候可以开启cilium的替代kube-proxy,这样创建的集群不会有任何问题,然后等待cilium创建完成后删除kube-proxy.
>
> 否则可能出现集群内部的Service不生效的问题,这会导致DNS服务访问不到default名称空间的kubernetes Service启动失败

```shell
helm repo list
helm repo remove cilium
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.15.6 --namespace kube-system
```

## 导出值到对应文件的

```shell
helm get cilium cilium/cilium > values.yaml
# get用于获取已安装的 未安装的使用show
helm show values cilium/cilium >values.yaml
helm install cilium cilium/cilium --values values.yaml
```

# Hubble

[启用Hubble](https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/)

```shell
cilium hubble enable
```

安装Hubble客户端

```shell
HUBBLE_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
HUBBLE_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then HUBBLE_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/hubble/releases/download/$HUBBLE_VERSION/hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
sha256sum --check hubble-linux-${HUBBLE_ARCH}.tar.gz.sha256sum
sudo tar xzvfC hubble-linux-${HUBBLE_ARCH}.tar.gz /usr/local/bin
rm hubble-linux-${HUBBLE_ARCH}.tar.gz{,.sha256sum}
```

增加转发 这将占用4245端口

```shell
cilium hubble port-forward&
```

查看状态

```shell
hubble status
```

启用UI

```shell
# 需要先禁用Hubble
cilium hubble disable
cilium hubble enable --ui
```

> 这将会启动两个容器 一个Hubble 一个hublle-ui

## 开启LoadBalancer

用法参考 Kubernetes LoadBalancer.md文档

开启原因: 因为HubbleUI默认是localhost的端口,只能在当前主机访问.

通过开启LoadBalancer,然后修改Service,可以让他在集群间互相访问.

# 测试

循环运行测试案例,这将创建一个cilium-test的名称空间.

```shell
while true; do cilium connectivity test; done
```

接下来访问页面,选择对应的名称空间,这将看到对应服务的调用

![](./picture/01%20简介/HubbleUI.png)

## 还可以使用命令来检测

[Inspecting Network Flows with the CLI &mdash; Cilium 1.15.6 documentation](https://docs.cilium.io/en/stable/gettingstarted/hubble_cli/)

# 替代kube-proxy

## 基于已经安装的集群

```shell
kubectl -n kube-system delete ds kube-proxy
# Delete the configmap as well to avoid kube-proxy being reinstalled during a Kubeadm upgrade (works only for K8s 1.19 and newer)
kubectl -n kube-system delete cm kube-proxy
# Run on each node with root permissions:
iptables-save | grep -v KUBE | iptables-restore
```

```shell
API_SERVER_IP=192.168.137.100
# Kubeadm default is 6443
API_SERVER_PORT=6443
helm upgrade cilium cilium/cilium --version 1.15.6 \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT}
```

## 安装时直接不安装kube-proxy

```shell
kubeadm init --skip-phases=addon/kube-proxy
API_SERVER_IP=<your_api_server_ip>
# Kubeadm default is 6443
API_SERVER_PORT=6443
helm install cilium cilium/cilium --version 1.15.6 \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=${API_SERVER_IP} \
    --set k8sServicePort=${API_SERVER_PORT}
```

kubeadm init时如果使用--config,那么需要在配置文件添加

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
skipPhases:
  - addon/kube-proxy
```

## 开始验证

```shell
kubectl -n kube-system get pods -l k8s-app=cilium
```

> 这将显示出和对应节点数量的pod,并且应该是running状态

验证代理模式是否正确

```shell
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep KubeProxyReplacement
```

在输出的内容里找到`KubeProxyReplacement:   True`,即为正确

然后运行一个nginx容器用于测试

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 2
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
```

查看是否正在运行

```shell
kubectl get pods -l run=my-nginx -o wide
```

创建一个nodePort服务

```shell
kubectl expose deployment my-nginx --type=NodePort --port=80
```

验证

```shell
kubectl get svc my-nginx
```

验证cilium的eBPF是否创建了对应的规则

```shell
kubectl -n kube-system exec ds/cilium -- cilium-dbg service list
```

> 这将输出对应的主机和容器IP的规则,检查是否在每个主机都创建了规则转发到容器

检查是否还有kube-proxy的规则,输出应为空

```shell
iptables-save | grep KUBE-SVC
```

# 最终参数

> 优先使用已经修改好的yaml cilium-template.yaml
>
> 需要注意修改其中的k8sServiceHost参数

```
kubectl create namespace cilium
helm install cilium cilium/cilium --namespace cilium -f cilium-template.yaml
```

如果升级那么则将 install 替换为 upgrade

如果需要保留之前的参数 增加 --reuse-values

```shell
helm install cilium cilium/cilium --version 1.15.6 \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=10.0.0.21 \
    --set k8sServicePort=6443 \
    --set routingMode=native \
    --set loadBalancer.acceleration=disabled \
    --set loadBalancer.mode=dsr \
    --set loadBalancer.algorithm=maglev \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set bpf.lbExternalClusterIP=true \
    --set prometheus.enabled=true \
    --set operator.prometheus.enabled=true \
    --set hubble.enabled=true \
    --set hubble.metrics.enableOpenMetrics=true \
    --set ipam.operator.clusterPoolIPv4PodCIDRList="192.168.0.0/16" \
    --set ipam.operator.clusterPoolIPv4MaskSize=24 \
    --set ingressController.enabled=true \
    --set ingressController.loadbalancerMode=dedicated \
    --set loadBalancer.l7.backend=envoy \
    --set enableIPv4Masquerade=true \
    --set ipam.mode=cluster-pool \
    --set ipv4NativeRoutingCIDR="10.0.0.0/24" \
	--set hubble.tls.auto.enabled=true \
	--set hubble.tls.auto.method=helm \
	--set hubble.tls.auto.certValidityDuration=10950
```

参数含义：

```shell
# 安装Cilium版本1.15.6
helm install cilium cilium/cilium --version 1.15.6 \
    --namespace kube-system \  # 指定命名空间
    --set kubeProxyReplacement=true \  # 替代kube-proxy
    --set k8sServiceHost=10.0.0.21 \  # apiserver的地址
    --set k8sServicePort=6443 \  # apiserver的端口
    --set routingMode=native \  # 原生路由模式
    --set loadBalancer.acceleration=disabled \  # 禁用负载均衡加速
    --set loadBalancer.mode=dsr \  # 使用DSR模式
    --set loadBalancer.algorithm=maglev \  # 选择Maglev算法
    --set hubble.relay.enabled=true \  # 启用Hubble Relay
    --set hubble.ui.enabled=true \  # 启用Hubble UI
    --set bpf.lbExternalClusterIP=true \  # 启用外部Cluster IP的BPF负载均衡
    --set prometheus.enabled=true \  # 启用Prometheus
    --set operator.prometheus.enabled=true \  # 启用Operator Prometheus
    --set hubble.enabled=true \  # 启用Hubble
    --set hubble.metrics.enableOpenMetrics=true \  # 启用OpenMetrics
    --set ipam.operator.clusterPoolIPv4PodCIDRList="192.168.0.0/16" \  # pod的网段 如果和主机网段冲突需要修改
    --set ipam.operator.clusterPoolIPv4MaskSize=24 \  # 为每个节点分配的子网掩码大小
    --set ingressController.enabled=true \  # 启用Ingress控制器
    --set ingressController.loadbalancerMode=dedicated \  # 专用模式
    --set loadBalancer.l7.backend=envoy \  # 使用Envoy作为L7后端
    --set enableIPv4Masquerade=true \  # 启用IPv4地址伪装
    --set ipam.mode=cluster-pool \  # 使用集群池模式IPAM
    --set ipv4NativeRoutingCIDR="10.0.0.0/24" \  # 原生IPv4路由网段 不使用封装的网段,通过底层主机网络来传输的网段
    --set hubble.tls.auto.enabled=true \  # 启用Hubble的TLS自动化
    --set hubble.tls.auto.method=helm \  # 使用Helm管理TLS
    --set hubble.tls.auto.certValidityDuration=10950  # 设置证书有效期
```



### 无注释版本

```shell
helm upgrade cilium cilium/cilium --version 1.15.6 \
    --reuse-values \
    --namespace kube-system \
    --set kubeProxyReplacement=true \
    --set k8sServiceHost=192.168.137.100 \
    --set k8sServicePort=6443 \
    --set routingMode=native \
    --set kubeProxyReplacement=true \
    --set loadBalancer.acceleration=native \
    --set loadBalancer.mode=dsr \
    --set loadBalancer.algorithm=maglev \
    --set hubble.relay.enabled=true \
    --set hubble.ui.enabled=true \
    --set bpf.lbExternalClusterIP=true \
   --set prometheus.enabled=true \
   --set operator.prometheus.enabled=true \
   --set hubble.enabled=true \
   --set hubble.metrics.enableOpenMetrics=true \
   --set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
    --set cni.configMap.cluster-pool-ipv4-cidr=10.0.0.0/8 \
    --set cni.configMap.cluster-pool-ipv4-mask-size=24 \
    --set ingressController.enabled=true \
    --set ingressController.loadbalancerMode=dedicated \
    --set loadBalancer.l7.backend=envoy
```

# 拉取docker hub的镜像

```shell
sudo ctr image pull docker.io/library/nginx:latest
```

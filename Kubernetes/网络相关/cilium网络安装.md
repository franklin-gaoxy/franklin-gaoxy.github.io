# cilium安装



| 编辑时间   | 操作内容              |
| ---------- | --------------------- |
| 2024/09/02 | 文档首次编写 正式发布 |

## 详细信息

| 服务名称   | 版本    |
| ---------- | ------- |
| kubernetes | 1.28.13 |
| ubuntu     | 24      |
| containerd | 1.7.13  |
| cilium     | 1.16.1  |
|            |         |
|            |         |



## 安装

> 基于现有的kubernetes环境，安装的时候选择安装kube-proxy

实现内容：

- 替代kube-proxy
- 容器网络创建

### 安装cilium基础内容

首先安装cilium网络，不修改其他参数，因为service依赖kube-proxy实现，否则可能会出现DNS服务启动异常问题（访问不到default namespace的kubenetes service）。

添加镜像源：

```shell
helm repo list
helm repo remove cilium
helm repo add cilium https://helm.cilium.io/
```

安装基础内容：

```shell
helm install cilium cilium/cilium --version 1.15.6 \
	--namespace kube-system \
	--set k8sServiceHost=192.168.0.21 \
	--set k8sServicePort=6443 \
	--set ipam.operator.clusterPoolIPv4PodCIDRList="10.0.0.0/16" \
	--set ipam.operator.clusterPoolIPv4MaskSize=24 \
	--set ipv4NativeRoutingCIDR="192.168.0.0/24"
```

> ipam.operator.clusterPoolIPv4PodCIDRList：pod(容器)使用的网段
>
> ipam.operator.clusterPoolIPv4MaskSize：每个节点的掩码大小
>
> ipv4NativeRoutingCIDR：主机的网段

### 开启Hubble

```shell
helm upgrade cilium cilium/cilium --version 1.15.6 \
	--namespace kube-system \
	--set hubble.enabled=true \
	--set hubble.ui.enabled=true \
	--set hubble.relay.enabled=true \
	--set hubble.metrics.enableOpenMetrics=true \
	--set hubble.tls.auto.enabled=true \
	--set hubble.tls.auto.method=helm \
	--set hubble.tls.auto.certValidityDuration=10950
```

### 替代kube-proxy

https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/#kube-proxy-hybrid-modes

> 目前测试只能还原集群后，在新安装的时候跳过kube-proxy的安装，然后直接开启，完整的命令如下：

```shell
helm install cilium cilium/cilium --version 1.16.1 \
	--namespace kube-system \
	--set k8sServiceHost=192.168.0.21 \
	--set k8sServicePort=6443 \
	--set kubeProxyReplacement=true \
	--set ipam.operator.clusterPoolIPv4PodCIDRList="10.0.0.0/16" \
	--set ipam.operator.clusterPoolIPv4MaskSize=24 \
	--set ipv4NativeRoutingCIDR="192.168.0.0/24" \
	--set nodePort.enabled=true \
	--set nodePort.enableHealthCheck=false \
	--set hubble.enabled=true \
	--set hubble.ui.enabled=true \
	--set hubble.relay.enabled=true \
	--set hubble.metrics.enableOpenMetrics=true \
	--set hubble.tls.auto.enabled=true \
	--set hubble.tls.auto.method=helm \
	--set hubble.tls.auto.certValidityDuration=10950
```

#### 验证

```shell
kubectl apply -f test-ubuntu-deployment.yaml
kubectl apply -f test-nginx-deployment-service.yaml
kubectl exec -it `kubectl get pod |grep ubuntu |awk '{print $1}'` -- /bin/bash
apt-get update && apt-get install curl iputils-ping dnsutils -y
curl nginx-service
nslookup kubernetes
nslookup nginx-service
```

```shell
kubectl -n kube-system get pods -l k8s-app=cilium
kubectl -n kube-system exec ds/cilium -- cilium-dbg status | grep KubeProxyReplacement
kubectl -n kube-system exec ds/cilium -- cilium-dbg status --verbose
kubectl -n kube-system exec ds/cilium -- cilium-dbg service list
```

### 配合istio

如果希望使用istio的CNI模式，那么cilium需要指定CNI不要覆盖配置

> 增加参数 --set cni.exclusive=false

```shell
helm install cilium cilium/cilium --version 1.16.1 \
	--namespace kube-system \
	--set k8sServiceHost=192.168.0.21 \
	--set k8sServicePort=6443 \
	--set kubeProxyReplacement=true \
	--set ipam.operator.clusterPoolIPv4PodCIDRList="10.0.0.0/16" \
	--set ipam.operator.clusterPoolIPv4MaskSize=24 \
	--set ipv4NativeRoutingCIDR="192.168.0.0/24" \
	--set nodePort.enabled=true \
	--set nodePort.enableHealthCheck=false \
	--set hubble.enabled=true \
	--set hubble.ui.enabled=true \
	--set hubble.relay.enabled=true \
	--set hubble.metrics.enableOpenMetrics=true \
	--set hubble.tls.auto.enabled=true \
	--set hubble.tls.auto.method=helm \
	--set hubble.tls.auto.certValidityDuration=10950 \
	--set cni.exclusive=false
```


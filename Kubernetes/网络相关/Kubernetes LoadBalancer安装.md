# Loadbalancer 安装

| 编辑时间      | 操作内容   |
| --------- | ------ |
| 2024/6/24 | 文档首次编写 |

参考文档

[MetalLB, bare metal load-balancer for Kubernetes](https://metallb.io/installation/)

[MetalLB, bare metal load-balancer for Kubernetes](https://metallb.io/configuration/)

## 准备检查工作

如果在IPVS模式下使用LoadBalancer,那么需要开启严格APR模式

```shell
kubectl edit configmap -n kube-system kube-proxy
```

```yaml
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: "ipvs"
ipvs:
  strictARP: true
```

> 此段内容也可以加载kubeadm的配置文件中,直接初始化一个使用严格ARP模式的集群

自动更改方式

```shell
# see what changes would be made, returns nonzero returncode if different
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl diff -f - -n kube-system

# actually apply the changes, returns nonzero returncode on errors only
kubectl get configmap kube-proxy -n kube-system -o yaml | \
sed -e "s/strictARP: false/strictARP: true/" | \
kubectl apply -f - -n kube-system
```

## 安装

### 直接导入

```shell
kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/v0.14.5/config/manifests/metallb-native.yaml
```

> 此步骤仅安装服务,不会导入配置文件,在配置导入前,MetaILB将保持空置状态

### 使用helm安装

```shell
helm repo add metallb https://metallb.github.io/metallb
helm install metallb metallb/metallb
```

指定值文件安装:

```shell
helm install metallb metallb/metallb -f values.yaml
```

## 导入配置

### 定义分配的IP

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.10.0/24
  - 192.168.9.1-192.168.9.5
  - fc00:f853:0ccd:e799::/124
```

> 支持ipv4 ipv6,同时还支持指定域和部分IP的形式

### 二层配置

二层配置是最简单的,大部分情况下不需要其他的额外功能,而只是使用他的IP地址的功能

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: first-pool
  namespace: metallb-system
spec:
  addresses:
  - 192.168.1.240-192.168.1.250
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: example
  namespace: metallb-system
```

接下来直接kubectl apply -f 导入即可

# 使用

## 请求特定的IP

```ouyaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  annotations:
    metallb.universe.tf/loadBalancerIPs: 192.168.1.100
spec:
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: nginx
  type: LoadBalancer
```

## 问题解决

需要确认开放IP的节点是否存在`node.kubernetes.io/exclude-from-external-load-balancers`标签,如果存在需要删除

```shell
kubectl get nodes --show-labels
```

```shell
kubectl label nodes node-name node.kubernetes.io/exclude-from-external-load-balancers-
```

> 故障排除: https://metallb.universe.tf/troubleshooting/

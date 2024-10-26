# 基于Debian12的安装

| 编辑时间   | 操作内容     |
| ---------- | ------------ |
| 2024/05/26 | 文档首次编写 |



## 安装前内容

### IP地址和主机名

> 添加到hosts解析文件

| 主机名   | IP        | 角色   |
| -------- | --------- | ------ |
| kmaster1 | 10.0.0.21 | master |
| knode1   | 10.0.0.22 | node   |
| knode2   | 10.0.0.23 | node   |

### 系统版本

12.2

### CNI

cilium 1.15.5

### CRI

contaniner 1.7.13

runc 1.1.12

cni 1.4.0

## 预备事项

### 修改参数

```shell
localectl set-locale LANG=en_US.UTF-8
source /etc/locale.conf
cp /etc/sysctl.conf{,.bak}
cat >>/etc/sysctl.conf<<EOF
net.ipv4.ip_forward = 1
# 这些参数控制套接字接收和发送缓冲区的大小，可以提高网络性能。
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.optmem_max = 16777216
# 这些参数配置 TCP 套接字的内存使用，可以提高 TCP 连接的吞吐量和稳定性
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
# 这些参数控制 TCP 连接的 keepalive 行为，有助于检测和清理死连接。
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
# 这个参数控制系统的 swap 行为。较低的值（如 10）表示尽量避免使用 swap，更依赖物理内存。
vm.swappiness = 10
# 这个参数设置系统可以同时打开的文件描述符的最大数量，有助于处理大量并发连接。
fs.file-max = 1000000
# 这个参数控制进程可以拥有的内存映射区域的最大数量，尤其对于运行 Elasticsearch 等应用非常重要。
vm.max_map_count = 262144
# 这个参数控制 conntrack 表的大小，有助于处理大量的网络连接。
net.netfilter.nf_conntrack_max = 262144
# 这个参数设置 TCP 连接在已建立状态下的超时时间。
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
EOF
sudo sysctl -p
# 修改文件打开数
cat >>/etc/security/limits.conf<<EOF
* soft nofile 1000000
* hard nofile 1000000
* soft nproc 1000000
* hard nproc 1000000
EOF
# 加载br_netfilter 模块
modprobe br_netfilter
# 检查
lsmod | grep br_netfilter
# 设置iptables查看流量
cat <<EOF | tee /etc/modules-load.d/k8s.conf
br_netfilter
EOF

cat <<EOF | tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# load module <module_name>
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
# linux 内核4.19上面的命令会报错 使用如下命令
modprobe -- nf_conntrack 

# to check loaded modules, use
lsmod | grep -e ip_vs -e nf_conntrack_ipv4
# or
cut -f1 -d " "  /proc/modules | grep -e ip_vs -e nf_conntrack_ipv4

swapoff -a
sysctl --system
bash
```

### 时间同步

```shell
apt-get install ntp -y
systemctl start ntpd
```

### 安装基础软件

```shell
apt-get update
apt-get install -y curl wget vim net-tools sudo ipvsadm
```



## 安装基础依赖包

### demo下载路径

```shell
wget https://github.com/containernetworking/plugins/releases/download/v1.4.0/cni-plugins-linux-amd64-v1.4.0.tgz
wget https://github.com/opencontainers/runc/releases/download/v1.1.12/runc.amd64
wget https://github.com/containerd/containerd/releases/download/v1.7.13/containerd-1.7.13-linux-amd64.tar.gz
```

### 安装containerd

官方文档: https://github.com/containerd/containerd/blob/main/docs/getting-started.md

```shell
tar Cxzvf /usr/local containerd-*-linux-amd64.tar.gz
curl https://raw.githubusercontent.com/containerd/containerd/main/containerd.service >/usr/lib/systemd/system/containerd.service
# mv bin/* /usr/local/bin/
systemctl daemon-reload
systemctl enable --now containerd
```

### 安装runc

```shell
install -m 755 runc.amd64 /usr/local/sbin/runc
```

### 安装cni

```shell
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v*.tgz
```

### 清理环境

```shell
rm -rf containerd-1.*-linux-amd64.tar.gz cni-plugins-linux-amd64-v1.*.tgz runc.amd64
```



## 安装k8s

[阿里云kubernetes下载源使用页面](https://developer.aliyun.com/mirror/kubernetes)

```shell
apt-get update && apt-get install -y apt-transport-https gnupg2
curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/kubernetes-archive-keyring.gpg
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://mirrors.aliyun.com/kubernetes/apt/ kubernetes-xenial main
EOF
apt-get update
```

查看所有包

```shell
apt install apt-file -y && apt-file update
# 查看所有包
apt list kubeadm -a 
```

> debian 执行 curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 可能会遇到如下错误:
>
> ```shell
> root@debian:~# curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - 
> % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
>                            Dload  Upload   Total   Spent    Left  Speed
> 0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0E: gnupg, gnupg2 and gnupg1 do not seem to be installed, but one of them is required for this operation
> 100  2659  100  2659    0     0  15151      0 --:--:-- --:--:-- --:--:-- 15107
> curl: (23) Failed writing body
> ```
>
> 因为Debian系统极为精简,所以需要安装相关的包
>
> ```shell
> apt-get install gnupg2
> ```
>
> 

安装1.28.0-00版本

```shell
apt install -y kubeadm=1.28.0-00 kubectl=1.28.0-00 kubelet=1.28.0-00
```

主次区分情况：

```shell
apt install -y kubeadm=1.28.0-00 kubectl=1.28.0-00 kubelet=1.28.0-00
```

slave执行：

```shell
apt install -y kubelet=1.28.0-00
```



kubelet加入开机自启动

```shell
systemctl enable kubelet --now
```

修改containerd配置

```
mkdir /etc/containerd
containerd config default >/etc/containerd/config.toml
```



```shell
sandbox_image = "registry.k8s.io/pause:3.6"
# 值修改为
registry.aliyuncs.com/google_containers/pause:3.6

[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
SystemdCgroup = true
```

命令方式(和上面二选一)

```shell
sed -i 's#    sandbox_image = "registry.k8s.io/pause:3.8"#    sandbox_image = "registry.aliyuncs.com/google_containers/pause:3.6"#g' /etc/containerd/config.toml
sed -i 's#SystemdCgroup = false#SystemdCgroup = true#g' /etc/containerd/config.toml

systemctl restart containerd
```

## 初始化集群（主节点）

```shell
# 导出配置
kubeadm config print init-defaults >Kubernetes-cluster.yaml
```

修改配置`vim Kubernetes-cluster.yaml`

```shell
sed -i 's#registry.k8s.io#registry.aliyuncs.com/google_containers#g' Kubernetes-cluster.yaml
IP=`hostname -I|awk '{print $1}'`
sed -i "s#1.2.3.4#${IP}#g" Kubernetes-cluster.yaml
sed -i "s#name: node#name: `hostname`#g" Kubernetes-cluster.yaml
cat >>Kubernetes-cluster.yaml<<EOF
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
EOF
```

template:

```yaml
apiVersion: kubeadm.k8s.io/v1beta3
bootstrapTokens:
- groups:
  - system:bootstrappers:kubeadm:default-node-token
  token: abcdef.0123456789abcdef
  ttl: 24h0m0s
  usages:
  - signing
  - authentication
kind: InitConfiguration
localAPIEndpoint:
  # 将此处IP地址替换为主节点IP ETCD容器会试图通过此地址绑定端口 如果主机不存在则会失败
  advertiseAddress: 20.88.9.31
  bindPort: 6443
nodeRegistration:
  criSocket: /var/run/dockershim.sock
  imagePullPolicy: IfNotPresent
  name: node
  taints: null
---
apiServer:
  timeoutForControlPlane: 4m0s
apiVersion: kubeadm.k8s.io/v1beta3
certificatesDir: /etc/kubernetes/pki
clusterName: kubernetes
controllerManager: {}
dns: {}
etcd:
  local:
    dataDir: /var/lib/etcd
# 修改镜像下载地址
imageRepository: registry.aliyuncs.com/google_containers
kind: ClusterConfiguration
kubernetesVersion: 1.23.0
networking:
  dnsDomain: cluster.local
  # 增加配置 指定pod网段
  podSubnet: "10.244.0.0/16"
  serviceSubnet: 10.96.0.0/12
scheduler: {}
pod-network-cidr: '192.168.0.0/16'
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: ipvs
---
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
cgroupDriver: systemd
```

### 初始化集群

```shell
kubeadm init --config Kubernetes-cluster.yaml
```

## 加配置文件

```shell
echo 'export KUBECONFIG=/etc/kubernetes/admin.conf' >>/etc/profile
source /etc/profile
# or
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## 添加命令补全

```shell
apt install bash-completion -y
source /usr/share/bash-completion/bash_completion
echo "source <(kubectl completion bash)" >> ~/.bashrc
source .bashrc
```

## 安装helm

```shell
wget https://get.helm.sh/helm-v3.15.1-linux-amd64.tar.gz
tar xf helm-v*-linux-amd64.tar.gz
cp linux-amd64/helm /usr/local/bin/
rm -rf linux-amd64/
```

## 导入网络

### 安装cilium CIL

```shell
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
# check
cilium version --client
```

### helm安装网络

```shell
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.15.5 \
  --namespace kube-system
# restart pod
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod
```

#### 修改容器网段

> 默认情况下，cilium使用10.0.0.0/24的网段，如果和主机网段冲突需要修改

```shell
# 获取配置
helm show values cilium/cilium > cilium-values.yaml
```

> 修改ipam.operator.clusterPoolIPv4PodCIDRList的字段

导入配置

```shell
helm install cilium cilium/cilium --namespace kube-system -f cilium-values.yaml
```

```shell
# 或者如果已经安装了 Cilium，可以使用以下命令进行升级
helm upgrade cilium cilium/cilium --namespace kube-system -f cilium-values.yaml
```



#### 更多内容解析

```yaml
# Global Cilium configuration
global:
  # Specify the Cilium version to be installed
  image:
    tag: "v1.11.6"  # Cilium 版本
  # Enable or disable IPv4/IPv6 dual-stack
  ipv4:
    enabled: true  # 启用 IPv4 支持
  ipv6:
    enabled: false # 启用 IPv6 支持
  # Configuration for CNI
  cni:
    binPath: "/opt/cni/bin" # CNI 二进制文件路径
  # Cilium agent configuration
  agent:
    extraArgs: []  # 额外的命令行参数
    logging:
      level: "info"  # 日志级别 (debug, info, warn, error)
# IPAM (IP Address Management) configuration
ipam:
  operator:
    clusterPoolIPv4PodCIDR: "10.0.0.0/16"  # Pod 的 IPv4 网段
    clusterPoolIPv6PodCIDR: "fd00::/104"   # Pod 的 IPv6 网段
# Operator configuration
operator:
  enabled: true # 启用或禁用 Cilium Operator
  replicas: 2   # Operator 副本数
# Hubble (observability component) configuration
hubble:
  enabled: true  # 启用 Hubble
  ui:
    enabled: true  # 启用 Hubble UI
  metrics:
    enabled: true  # 启用 Hubble Metrics
# Enable or disable various Cilium features
featureGates:
  egressGateway: true  # 启用 Egress Gateway
  kubeProxyReplacement: "strict"  # 启用和设置 kube-proxy 替代模式 (disabled, partial, strict)
# KubeProxy replacement settings
kubeProxyReplacement: "strict"  # 设置为 "strict" 以完全替代 kube-proxy
# Configure ETCD
etcd:
  enabled: false  # 是否启用独立的 ETCD
# L7/HTTP visibility and monitoring
l7Proxy:
  enabled: true  # 启用 L7/HTTP 代理
  visibility:
    enabled: true  # 启用 L7/HTTP 可见性
# NodePort settings
nodePort:
  enabled: true  # 启用 NodePort 服务
# Tunnel mode configuration
tunnel:
  mode: "vxlan"  # 隧道模式 (vxlan, geneve, disabled)
# Define the number of replicas for Cilium DaemonSet
daemonSet:
  updateStrategy:
    type: RollingUpdate  # DaemonSet 更新策略 (RollingUpdate, OnDelete)
  affinity: {}  # 节点亲和性
  tolerations: []  # 容忍配置
# Define extra env vars for the Cilium agent
extraEnv: []  # 额外的环境变量
# Enable Prometheus metrics
prometheus:
  enabled: true  # 启用 Prometheus 指标
# Enable Grafana dashboards
grafana:
  enabled: true  # 启用 Grafana 仪表盘
# Define custom Cilium configuration
config: {}  # 自定义配置
# Configure the Cilium node init DaemonSet
nodeInit:
  enabled: true  # 启用 Cilium node init DaemonSet
# Configure the Cilium preflight DaemonSet
preflight:
  enabled: false  # 启用 Cilium preflight DaemonSet
```



## 遇到问题清理相关

```shell
sudo kubeadm reset --force
rm -rf /etc/cni/net.d
sudo rm -rf /etc/kubernetes/
sudo rm -rf /etc/kubernetes/
sudo rm -rf /var/lib/etcd/
sudo rm -rf /var/lib/kubelet/
sudo rm -rf /var/lib/dockershim/
sudo rm -rf /var/run/kubernetes/
sudo rm -rf /usr/local/bin/kube*
sudo rm -rf ~/.kube
```


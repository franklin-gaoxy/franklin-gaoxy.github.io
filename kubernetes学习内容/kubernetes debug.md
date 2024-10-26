# kubernetes debug

## 环境准备

代码仓库：[https://github.com/kubernetes/kubernetes](https://github.com/kubernetes/kubernetes)

### 安装基础包

```shell
apt-get install -y sudo vim build-essential rsync jq pip lrzsz wget git
```

### 安装golang

[根据此文档](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#go)来确定不同版本对应的golang的版本

```shell
curl -OL https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
mkdir /opt/golang
mkdir /opt/golang/gopath
tar xf go1.22.4.linux-amd64.tar.gz -C /opt/golang/
echo 'export PATH=${PATH}:/opt/golang/go/bin/' >>/etc/profile
echo 'GOPATH=/opt/golang/gopath' >>/etc/profile
source /etc/profile
```

### 安装containerd

#### runc

[https://github.com/opencontainers/runc/releases](https://github.com/opencontainers/runc/releases)

#### cni

[https://github.com/containernetworking/plugins/releases](https://github.com/containernetworking/plugins/releases)

#### containerd

[https://github.com/containerd/containerd/releases](https://github.com/containerd/containerd/releases)

```shell
wget https://github.com/containerd/containerd/releases/download/v1.7.18/containerd-1.7.18-linux-amd64.tar.gz
wget https://github.com/opencontainers/runc/releases/download/v1.1.13/runc.amd64
wget https://github.com/containernetworking/plugins/releases/download/v1.5.1/cni-plugins-linux-amd64-v1.5.1.tgz

wget https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
mv containerd.service /usr/lib/systemd/system/containerd.service
tar Cxzvf /usr/local containerd-1.7.18-linux-amd64.tar.gz
systemctl daemon-reload
systemctl enable --now containerd
install -m 755 runc.amd64 /usr/local/sbin/ru
mkdir -p /opt/cni/bin
tar Cxzvf /opt/cni/bin cni-plugins-linux-amd64-v1.1.1.tg
# 但是k8s脚本默认会在/usr下面去找。所以还需要创建一个软连接。
ln -s /opt/cni/bin/ /usr/lib/cniznc
```

启动

```shell
systemctl start containerd --now
```

接下来需要检查`/etc/containerd/config.toml`是否有这个配置文件,如果有,检查是否有以下内容

```shell
disabled_plugins = ["cri"]
```

这将禁用掉cri,使得kubelet无法连接,注释此内容,重启.

检查是否存在一下内容,如果没有则添加:

```shell
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "k8s.gcr.io/pause:3.2"
```

可以运行的配置文件:

```yaml
disabled_plugins = []
[plugins."io.containerd.grpc.v1.cri"]
  sandbox_image = "k8s.gcr.io/pause:3.2"
[plugins."io.containerd.grpc.v1.cri".registry]
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors]
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."mxov9ds4.mirror.aliyuncs.com"]
      endpoint = ["https://mxov9ds4.mirror.aliyuncs.com"]
```



### 下载代码

```shell
git clone https://github.com/kubernetes/kubernetes -b release-1.30
cd kubernetes
# 或者尽可能下载更少的代码
git clone --filter=blob:none https://github.com/kubernetes/kubernetes.git
```

#### 或者设置变量方式拉取

设置GOPATH变量

```shell
echo 'export GOPATH=/root/' >>/etc/profile
source /etc/profile
```

```shell
mkdir -p $GOPATH/src/k8s.io
cd $GOPATH/src/k8s.io
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
make
```

#### 切换分支

```shell
git fetch
git checkout -b release-1.26
```

#### 安装etcd

```shell
./hack/install-etcd.sh
```

#### 安装依赖包

```shell
go install github.com/cloudflare/cfssl/cmd/...@latest
PATH=$PATH:$GOPATH/bin
```

#### 检查是否有openssl

```shell
openssl
```

#### 尽可能安装pyyaml

```shell
 pip install pyyaml --break-system-packages
```

### 其他需要声明的变量

```shell
export CONTAINER_RUNTIME_ENDPOINT="unix:///run/containerd/containerd.sock"
export PATH=$PATH:$GOPATH/bin
export PATH="$GOPATH/src/k8s.io/kubernetes/third_party/etcd:${PATH}"
export KUBECONFIG=/var/run/kubernetes/admin.kubeconfig
export KUBERNETES_PROVIDER=local
```

## 编译和运行

如果需要只编译代码:

```shell
make all
# 如果希望编译指定的组件
make WHAT=cmd/kubectl
# 如果希望开启DEBUG信息
make WHAT="cmd/kubectl" DBG=1
```

如果希望运行一个测试集群:

```shell
./hack/install-etcd.sh
```

> 这将自动根据代码开始编译然后启动一个新的集群

如果希望使用已有的编译文件

```shell
./hack/local-up-cluster.sh -O
```

# 调试

## 调试记录

#### 调试api-server

安装dlv

```shell
go install github.com/go-delve/delve/cmd/dlv@latest
echo 'export PATH=${PATH}:$(go env GOPATH)/bin' >> /etc/profile
source /etc/profile
```

编译时需要添加调试参数

```shell
make WHAT="cmd/kube-apiserver" DBG=1
```

接下来启动,然后通过命令连接:

```shell
dlv attach PID
```

添加断点

```shell
b pkg/registry/core/pod/storage/storage.go:169
```

## 添加新节点

```shell
kubeadm token create --print-join-command
```



# 参考文档

[community/contributors/devel/development.md at master · kubernetes/community · GitHub](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#etcd)

[community/contributors/devel/development.md at master · kubernetes/community · GitHub](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md#go)

[community/contributors/devel/running-locally.md at master · kubernetes/community · GitHub](https://github.com/kubernetes/community/blob/master/contributors/devel/running-locally.md)

[community/contributors/devel/development.md at master · kubernetes/community · GitHub](https://github.com/kubernetes/community/blob/master/contributors/devel/development.md)

[community/contributors/devel at master · kubernetes/community · GitHub](https://github.com/kubernetes/community/tree/master/contributors/devel#readme)
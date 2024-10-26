以二进制方式安装kubernetes 1.18.3版本
一、Kubernetes简介
1.Kubernetes架构设计图
2、kubernetes常用组件介绍
二、Kubernetes二进制安装
1.创建CA证书和密钥
2.安装etcd组件
1）创建etcd证书和密钥
2) 生成证书和密钥
3) 创建启动脚本
4）启动etcd
3.安装flannel网络插件
1）创建法兰绒证书和密钥
2) 生成证书和密钥
3) 编写启动脚本
4) 启动并验证
4.安装docker服务

1. 创建启动脚本
2. 启动泊坞窗
5.安装kubectl服务
1）创建管理员证书和密钥
3. 生成证书和密钥
4. 创建 kubeconfig 文件
5）创建kubectl配置文件，配置命令补全工具
三、安装kubenetes相关组件
1.安装Kube apiserver组件
1）创建kubernetes证书和密钥
5. 生成证书和密钥
6. 配置 Kube apiserver 审计
7. 配置指标服务器
8. 创建启动脚本
9. 启动 Kube apiserver 并验证
2.安装控制器管理器组件
1）创建控制器管理器证书和密钥
10. 生成证书和密钥
3）创建kubeconfig文件
11. 创建启动脚本
12. 启动并验证
3.安装Kube调度器组件
13. 创建 Kube 调度程序证书和密钥
14. 生成证书和密钥
3）创建kubeconfig文件
15. 创建 Kube 调度器配置文件
16. 创建启动脚本
17. 启动并验证
4.安装kubelet组件
1）创建kubelet启动脚本
18. 启动并验证
19. 批准 CSR 请求
20. 手动批准服务器证书 CSR
21. Kubelet API 接口配置
5.安装Kube代理组件
22. 创建 Kube 代理证书和密钥
23. 生成证书和密钥
3）创建kubeconfig文件
24. 创建 Kube 代理配置文件
25. 创建启动脚本
26. 启动并验证
6.安装coredns插件
1）修改coredns配置
2）创建coredns并启动
27. 验证
7.安装仪表板
28. 创建证书
2）修改仪表板配置
29. 验证
一、Kubernetes简介
Kubernetes，又称k8s，是谷歌开源的容器集群管理系统。Kubernetes基于Docker 技术，为容器应用提供了一系列完整的功能，如部署和运行、资源调度、服务发现和动态扩展，提高了大规模容器集群管理的便利性。Kubernetes 官方

1.Kubernetes架构设计图
Kubernetes 由一个主节点和多个节点组成。master通过API提供服务，接收kubectl发送的请求，对整个集群进行调度和管理。

kubectl 是 k8s 平台的管理命令。
以二进制方式安装kubernetes 1.18.3版本（近60000字）

2、kubernetes常用组件介绍
APIServer：统一访问所有服务，提供认证、授权、访问控制、API注册和发现等机制；
Controller Manager：主要用于维护一个pod的副本数，比如故障检测、自动扩容、滚动更新等；
调度器：主要用于将任务分配给合适的节点（资源调度）
ETCD：键值对数据库将所有重要信息（持久化）存储在k8s集群中
Kubelet：直接与容器引擎交互，维护容器的一个生命周期；还负责卷（CVI）和网络（CNI）管理；
Kube-Porxy：用于编写规则到iptables或IPVS实现服务的映射访问；
其他组件：

coredns：主要用于为k8s服务提供域名和IP对应的解析关系。
Dashboard：主要用于为k8s提供B/S结构的访问系统（即我们可以通过web界面管理k8s）
Ingress 控制器：主要用于实现 HTTP 代理（第 7 层）。官方服务仅支持 TCP\UDP 代理（第 4 层）
Prometheus：主要是用来给k8s提供一个监控能力，让我们更清楚的看到k8s相关组件和pod的使用情况。
Elk：主要用于为k8s提供日志分析平台。
Kubernetes 的工作原理：

用户可以通过 kubectl 命令将要运行的 docker 容器提交到 k8s 的 apiserver 组件中；
然后，apiserver收到用户提交的请求后，会将请求存储在etcd的键值对存储中；
然后，控制器管理器组件创建一个用户定义的控制器类型（POD 副本集、部署守护进程等）
然后调度器组件会扫描etcd并将用户需要运行的docker容器分配给合适的主机；
最后，kubelet 组件与 docker 容器交互来创建、删除和停止容器。
kube-proxy主要为服务提供服务，实现pod内部访问service，外部nodeport访问service。

二、Kubernetes二进制安装
下面的安装方式是简单的使用二进制安装，没有对Kube apiserver组件进行高可用配置，因为如果我们安装k8s，主要是学习k8s，通过k8s完成一些事情，所以不需要关心高可用。

其实kubernetes做高可用并不难。比如云端的k8s一般通过SLB代理到两台不同的服务器，实现高可用；比如云下的k8s和上面基本一样。我们可以通过keepalived和nginx实现高可用。

准备：

主机名	操作系统	IP地址	所需组件
k8s-master01	CentOS 7.4	192.168.1.1	所有组件均已安装（合理利用资源）
k8s-master02	CentOS 7.4	192.168.1.2	所有组件均已安装
k8s-node	CentOS 7.4	192.168.1.3	docker kubelet kube-proxy
1）配置每个节点上的主机名和hosts文件

[root[@localhost ](/localhost ) ~]# hostnamectl set-hostname k8s-master01 
[root[@localhost ](/localhost ) ~]# bash 
[root[@k8s-master01 ](/k8s-master01 ) ~]# cat < > /etc/hosts
192.168.1.1 k8s-master01
192.168.1.2 k8s-master02
192.168.1.3 k8s-node01
END
2）在k8s-master01Configure SSH key pair on and send the public key to other hosts

[ root[@k8s ](/k8s ) -master01 ~]# ssh-keygen -t rsa 												#  Triple return 
[root[@k8s-master01 ](/k8s-master01 ) ~]# ssh-copy-id [root@192.168.1.1](mailto:root@192.168.1.1)
[root[@k8s-master01 ](/k8s-master01 ) ~]# ssh-copy-id [root@192.168.1.2](mailto:root@192.168.1.2)
[root[@k8s-master01 ](/k8s-master01 ) ~]# ssh-copy-id [root@192.168.1.3](mailto:root@192.168.1.3)
3）编写k8s初始环境脚本

[root[@k8s-master01 ](/k8s-master01 ) ~]# vim k8s-init.sh 
#!/bin/bash
##

# ScriptName: k8s-init.sh

# Initialize the machine. This needs to be executed on every machine.

# Mkdir k8s directory

yum -y install wget ntpdate && ntpdate ntp1.aliyun.com
wget -O /etc/yum.repos.d/CentOS-Base.repo [https://mirrors.aliyun.com/repo/Centos-7.repo](https://mirrors.aliyun.com/repo/Centos-7.repo)
yum -y install epel-release
mkdir -p /opt/k8s/bin/
mkdir -p /data/k8s/docker
mkdir -p /data/k8s/k8s

# Disable the SELinux.

swapoff -a
sed -i '/swap/s/^/#/' /etc/fstab

# Turn off and disable the firewalld.

systemctl stop firewalld
systemctl disable firewalld

# Modify related kernel parameters & Disable the swap.

cat > /etc/sysctl.d/k8s.conf << EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.tcp_tw_recycle = 0
vm.swappiness = 0
vm.overcommit_memory = 1
vm.panic_on_oom = 0
net.ipv6.conf.all.disable_ipv6 = 1
EOF
sysctl -p /etc/sysctl.d/k8s.conf >& /dev/null

# Add ipvs modules

cat > /etc/sysconfig/modules/ipvs.modules << EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- br_netfilter
modprobe -- nf_conntrack
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules
source /etc/sysconfig/modules/ipvs.modules

# Install rpm

yum install -y conntrack ntpdate ntp ipvsadm ipset jq iptables curl sysstat libseccomp wget gcc gcc-c++ make libnl libnl-devel libnfnetlink-devel openssl-devel vim openssl-devel bash-completion

# ADD k8s bin to PATH

echo 'export PATH=/opt/k8s/bin:$PATH' >> /root/.bashrc && chmod +x /root/.bashrc && source /root/.bashrc
[root[@k8s-master01 ](/k8s-master01 ) ~]# bash k8s-init.sh 
4）配置环境变量

[root[@k8s-master01 ](/k8s-master01 ) ~]# vim environment.sh 
#!/bin/bash
#Generate the encryption key required by encryptionconfig
export ENCRYPTION_KEY=$(head -c 32 /dev/urandom | base64)

#Cluster master machine IP array
export MASTER_IPS=(192.168.1.1 192.168.1.2)

#Host name array corresponding to cluster master IP
export MASTER_NAMES=(k8s-master01 k8s-master02)

#Cluster node machine IP array
export NODE_IPS=(192.168.1.3)

#Host name array corresponding to cluster node IP
export NODE_NAMES=(k8s-node01)

#IP array of all machines in the cluster
export ALL_IPS=(192.168.1.1 192.168.1.2 192.168.1.3)

#Host name array corresponding to all IP addresses of the cluster
export ALL_NAMES=(k8s-master01 k8s-master02 k8s-node01)

#Etcd cluster service address list
export ETCD_ENDPOINTS="[https://192.168.1.1:2379](https://192.168.1.1:2379),[https://192.168.1.2:2379](https://192.168.1.2:2379)"

#IP and port of communication between etcd clusters
export ETCD_NODES="k8s-master01=https://192.168.1.1:2380,k8s-master02=https://192.168.1.2:2380"

#IP and port of Kube apiserver
export KUBE_APISERVER="[https://192.168.1.1:6443](https://192.168.1.1:6443)"

#Name of interconnection network interface between nodes
export IFACE="ens32"

#Etcd data directory
export ETCD_DATA_DIR="/data/k8s/etcd/data"

#Etcd wal directory SSD partition is recommended Or etcd_ DATA_ Dir different disk partitions
export ETCD_WAL_DIR="/data/k8s/etcd/wal"

#Data directory of k8s components
export K8S_DIR="/data/k8s/k8s"

#Docker data directory
export DOCKER_DIR="/data/k8s/docker"

##The following parameters generally do not need to be modified
#Token used by TLS bootstrapping Can be generated using the command head - C 16 / dev / urandom | od - an - t x | tr - D '
BOOTSTRAP_TOKEN="41f7e4ba8b7be874fcff18bf5cf41a7c"

#It is best to define the service network segment and pod network segment with the currently unused network segment
#Service network segment Route unreachable before deployment Route reachability in the cluster after deployment (Kube proxy guarantee)
SERVICE_CIDR="10.20.0.0/16"

#Pod segment Recommendation / 16 segment address Route unreachable before deployment After deployment, the routes in the cluster can reach (guaranteed by flanneld)
CLUSTER_CIDR="10.10.0.0/16"

#Service port range
export NODE_PORT_RANGE="1-65535"

#Flanneld network configuration prefix
export FLANNEL_ETCD_PREFIX="/kubernetes/network"

#Kubernetes service IP (generally the first IP in service_cidr)
export CLUSTER_KUBERNETES_SVC_IP="10.20.0.1"

#Cluster DNS service IP (pre allocated from service_cidr)
export CLUSTER_DNS_SVC_IP="10.20.0.254"

#Cluster DNS domain name (without dot at the end)
export CLUSTER_DNS_DOMAIN="cluster.local"

#Add binary directory / opt / k8s / bin to path
export PATH=/opt/k8s/bin:$PATH
上面的IP地址和网卡要改成对应的信息。
[root[@k8s-master01 ](/k8s-master01 ) ~]# chmod +x environment.sh && source environment.sh 
对于后面的操作，我们只需要对k8s-master01主机进行操作即可（因为我们会通过forLoop发送给其他主机）

1.创建CA证书和密钥
因为kubernetes系统的各个组件都需要使用TLS证书对其通信进行加密和授权认证，所以我们需要在安装前生成相关的TLS证书；我们可以使用openssl cfssl easyrsa来生成 Kubernetes 的相关证书，我们使用cfsslWay。

1. 安装cfssl工具集

[root[@k8s-master01 ](/k8s-master01 ) ~]# mkdir -p /opt/k8s/cert 
[root[@k8s-master01 ](/k8s-master01 ) ~]# curl -L [https://pkg.cfssl.org/R1.2/cfssl_linux-amd64](https://pkg.cfssl.org/R1.2/cfssl_linux-amd64) -o /opt/k8s/bin/cfssl
[root[@k8s-master01 ](/k8s-master01 ) ~]# curl -L [https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64](https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64) -o /opt/k8s/bin/cfssljson
[root[@k8s-master01 ](/k8s-master01 ) ~]# curl -L [https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64](https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64) -o /opt/k8s/bin/cfssl-certinfo
[root[@k8s-master01 ](/k8s-master01 ) ~]# chmod +x /opt/k8s/bin/* 
2) 创建根证书配置文件

[root[@k8s-master01 ](/k8s-master01 ) ~]# mkdir -p /opt/k8s/work 
[root[@k8s-master01 ](/k8s-master01 ) ~]# cd /opt/k8s/work/ 
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > ca-config.json << EOF 
{
"signing": {
"default": {
"expiry": "876000h"
},
"profiles": {
"kubernetes": {
"expiry": "876000h",
"usages": [
"signing",
"key encipherment",
"server auth",
"client auth"
]
}
}
}
}
EOF
signing：表示当前证书可用于签署其他证书；
server auth：表示客户端可以使用这个CA来验证服务器提供的证书；
client auth：表示服务器可以使用这个CA来验证客户端提供的证书；
"expiry": "876000h"：表示当前证书有效期为100年；
3) 创建根证书签名请求文件

[root[@k8s-master01 ](/k8s-master01 ) work]# cat > ca-csr.json << EOF 
{
"CN": "kubernetes",
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "k8s",
"OU": "System"
}
],
"ca": {
"expiry": "876000h"
}
}
EOF
cn：kube apiserver 会将此字段作为请求的用户名，让浏览器验证网站是否合法。
C：国家；ST：州、省；L：地区、城市；O：机构名称；OU：机构名称、公司部门。
4）生成CA密钥ca-key.pem和证书ca.pem

[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -initca ca-csr.json | cfssljson -bare ca 
生成证书后，由于 kubernetes 集群需要双向 TLS 认证，所以我们可以将生成的文件传输到所有主机。
5）使用forLoop遍历数组，将配置发送给所有主机

[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40&id=FIdth){all_ip} "mkdir -p /etc/kubernetes/cert"
scp ca*.pem ca-config.json root@${all_ip}:/etc/kubernetes/cert
done
2.安装etcd组件
etcd 是基于 raftkey-value存储系统的分布式系统，由 coreos 开发，常用于服务发现、共享配置和并发控制（如leader选举、分布式锁等）；Kubernetes 主要使用 etcd 来存储所有的操作数据。

下载 etcd

[root[@k8s-master01 ](/k8s-master01 ) work]# wget [https://github.com/etcd-io/etcd/releases/download/v3.3.22/etcd-v3.3.22-linux-amd64.tar.gz](https://github.com/etcd-io/etcd/releases/download/v3.3.22/etcd-v3.3.22-linux-amd64.tar.gz)
[root[@k8s-master01 ](/k8s-master01 ) work]# tar -zxf etcd-v3.3.22-linux-amd64.tar.gz 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20etcd-v3.3.22-linux-amd64%2Fetcd*%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20etcd-v3.3.22-linux-amd64%2Fetcd%2A%20root%40&id=iafu5){master_ip}:/opt/k8s/bin
ssh root@${master_ip} "chmod +x /opt/k8s/bin/*"
done
1）创建etcd证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > etcd-csr.json << EOF 
{
"CN": "etcd",
"hosts": [
"127.0.0.1",
"192.168.1.1",
"192.168.1.2"
],
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "k8s",
"OU": "System"
}
]
}
EOF
hosts：用于指定etcd授权的IP地址或域名列表。
2) 生成证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -ca=/opt/k8s/work/ca.pem -ca-key=/opt/k8s/work/ca-key.pem -config=/opt/k8s/work/ca-config.json -profile=kubernetes etcd-csr.json | cfssljson -bare etcd 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20ssh%20root%40&id=krIoY){master_ip} "mkdir -p /etc/etcd/cert"
scp etcd*.pem root@${master_ip}:/etc/etcd/cert/
done
3) 创建启动脚本
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > etcd.service.template << EOF 
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=![](https://g.yuque.com/gr/latex?%7BETCD_DATA_DIR%7D%0AExecStart%3D%2Fopt%2Fk8s%2Fbin%2Fetcd%20%5C%5C%0A%20%20--enable-v2%3Dtrue%20%5C%5C%0A%20%20--data-dir%3D#card=math&code=%7BETCD_DATA_DIR%7D%0AExecStart%3D%2Fopt%2Fk8s%2Fbin%2Fetcd%20%5C%5C%0A%20%20--enable-v2%3Dtrue%20%5C%5C%0A%20%20--data-dir%3D&id=bJP9Y){ETCD_DATA_DIR} \
--wal-dir=![](https://g.yuque.com/gr/latex?%7BETCD_WAL_DIR%7D%20%5C%5C%0A%20%20--name%3D%23%23MASTER_NAME%23%23%20%5C%5C%0A%20%20--cert-file%3D%2Fetc%2Fetcd%2Fcert%2Fetcd.pem%20%5C%5C%0A%20%20--key-file%3D%2Fetc%2Fetcd%2Fcert%2Fetcd-key.pem%20%5C%5C%0A%20%20--trusted-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--peer-cert-file%3D%2Fetc%2Fetcd%2Fcert%2Fetcd.pem%20%5C%5C%0A%20%20--peer-key-file%3D%2Fetc%2Fetcd%2Fcert%2Fetcd-key.pem%20%5C%5C%0A%20%20--peer-trusted-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--peer-client-cert-auth%20%5C%5C%0A%20%20--client-cert-auth%20%5C%5C%0A%20%20--listen-peer-urls%3Dhttps%3A%2F%2F%23%23MASTER_IP%23%23%3A2380%20%5C%5C%0A%20%20--initial-advertise-peer-urls%3Dhttps%3A%2F%2F%23%23MASTER_IP%23%23%3A2380%20%5C%5C%0A%20%20--listen-client-urls%3Dhttps%3A%2F%2F%23%23MASTER_IP%23%23%3A2379%2Chttp%3A%2F%2F127.0.0.1%3A2379%20%5C%5C%0A%20%20--advertise-client-urls%3Dhttps%3A%2F%2F%23%23MASTER_IP%23%23%3A2379%20%5C%5C%0A%20%20--initial-cluster-token%3Detcd-cluster-0%20%5C%5C%0A%20%20--initial-cluster%3D#card=math&code=%7BETCD_WAL_DIR%7D%20%5C%5C%0A%20%20--name%3D%23%23MASTER_NAME%23%23%20%5C%5C%0A%20%20--cert-file%3D%2Fetc%2Fetcd%2Fcert%2Fetcd.pem%20%5C%5C%0A%20%20--key-file%3D%2Fetc%2Fetcd%2Fcert%2Fetcd-key.pem%20%5C%5C%0A%20%20--trusted-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--peer-cert-file%3D%2Fetc%2Fetcd%2Fcert%2Fetcd.pem%20%5C%5C%0A%20%20--peer-key-file%3D%2Fetc%2Fetcd%2Fcert%2Fetcd-key.pem%20%5C%5C%0A%20%20--peer-trusted-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--peer-client-cert-auth%20%5C%5C%0A%20%20--client-cert-auth%20%5C%5C%0A%20%20--listen-peer-urls%3Dhttps%3A%2F%2F%23%23MASTER_IP%23%23%3A2380%20%5C%5C%0A%20%20--initial-advertise-peer-urls%3Dhttps%3A%2F%2F%23%23MASTER_IP%23%23%3A2380%20%5C%5C%0A%20%20--listen-client-urls%3Dhttps%3A%2F%2F%23%23MASTER_IP%23%23%3A2379%2Chttp%3A%2F%2F127.0.0.1%3A2379%20%5C%5C%0A%20%20--advertise-client-urls%3Dhttps%3A%2F%2F%23%23MASTER_IP%23%23%3A2379%20%5C%5C%0A%20%20--initial-cluster-token%3Detcd-cluster-0%20%5C%5C%0A%20%20--initial-cluster%3D&id=HmSyc){ETCD_NODES} \
--initial-cluster-state=new \
--auto-compaction-mode=periodic \
--auto-compaction-retention=1 \
--max-request-bytes=33554432 \
--quota-backend-bytes=6442450944 \
--heartbeat-interval=250 \
--election-timeout=2000
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for (( A=0; A < 2; A++ )) 
do
sed -e "s/##MASTER_NAME##/![](https://g.yuque.com/gr/latex?%7BMASTER_NAMES%5BA%5D%7D%2F%22%20-e%20%22s%2F%23%23MASTER_IP%23%23%2F#card=math&code=%7BMASTER_NAMES%5BA%5D%7D%2F%22%20-e%20%22s%2F%23%23MASTER_IP%23%23%2F&id=TuG7N){MASTER_IPS[A]}/" etcd.service.template > etcd-${MASTER_IPS[A]}.service
done
4）启动etcd
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20etcd-#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20etcd-&id=TsUCz){master_ip}.service root@![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%3A%2Fetc%2Fsystemd%2Fsystem%2Fetcd.service%0A%20%20%20%20ssh%20root%40#card=math&code=%7Bmaster_ip%7D%3A%2Fetc%2Fsystemd%2Fsystem%2Fetcd.service%0A%20%20%20%20ssh%20root%40&id=dpsqM){master_ip} "mkdir -p ${ETCD_DATA_DIR} ![](https://g.yuque.com/gr/latex?%7BETCD_WAL_DIR%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7BETCD_WAL_DIR%7D%22%0A%20%20%20%20ssh%20root%40&id=P3Wmk){master_ip} "systemctl daemon-reload && systemctl enable etcd && systemctl restart etcd"
done
查看etcd的当前leader

[root[@k8s-master01 ](/k8s-master01 ) work]# ETCDCTL_API=3 /opt/k8s/bin/etcdctl 
-w table --cacert=/etc/kubernetes/cert/ca.pem 
--cert=/etc/etcd/cert/etcd.pem 
--key=/etc/etcd/cert/etcd-key.pem 
--endpoints=${ETCD_ENDPOINTS} endpoint status
以二进制方式安装kubernetes 1.18.3版本（近60000字）

3.安装flannel网络插件
Flannel 是基于overlay网络的跨主机容器网络解决方案，就是将 TCP 数据封装在另一个网络数据包中进行路由、转发和通信。Flannel 是使用 go 语言开发的，主要用于不同主机中的容器互连。

下载法兰绒

[root[@k8s-master01 ](/k8s-master01 ) work]# mkdir flannel 
[root[@k8s-master01 ](/k8s-master01 ) work]# wget [https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz](https://github.com/coreos/flannel/releases/download/v0.11.0/flannel-v0.11.0-linux-amd64.tar.gz)
[root[@k8s-master01 ](/k8s-master01 ) work]# tar -zxf flannel-v0.11.0-linux-amd64.tar.gz -C flannel 
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20scp%20flannel%2F%7Bflanneld%2Cmk-docker-opts.sh%7D%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20scp%20flannel%2F%7Bflanneld%2Cmk-docker-opts.sh%7D%20root%40&id=Liz3F){all_ip}:/opt/k8s/bin/
ssh root@${all_ip} "chmod +x /opt/k8s/bin/*"
done
1）创建法兰绒证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > flanneld-csr.json << EOF 
{
"CN": "flanneld",
"hosts": [],
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "k8s",
"OU": "System"
}
]
}
EOF
2) 生成证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -ca=/opt/k8s/work/ca.pem -ca-key=/opt/k8s/work/ca-key.pem -config=/opt/k8s/work/ca-config.json -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld 
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40&id=m3Fyb){all_ip} "mkdir -p /etc/flanneld/cert"
scp flanneld*.pem root@${all_ip}:/etc/flanneld/cert
done
配置pod的网段信息

[root[@k8s-master01 ](/k8s-master01 ) work]# etcdctl 
--endpoints=${ETCD_ENDPOINTS} 
--ca-file=/opt/k8s/work/ca.pem 
--cert-file=/opt/k8s/work/flanneld.pem 
--key-file=/opt/k8s/work/flanneld-key.pem 
mk ![](https://g.yuque.com/gr/latex?%7BFLANNEL_ETCD_PREFIX%7D%2Fconfig%20'%7B%22Network%22%3A%22'#card=math&code=%7BFLANNEL_ETCD_PREFIX%7D%2Fconfig%20%27%7B%22Network%22%3A%22%27&id=YhXfw){CLUSTER_CIDR}'", "SubnetLen": 21, "Backend": {"Type": "vxlan"}}'
以二进制方式安装kubernetes 1.18.3版本（近60000字）

3. 编写启动脚本
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > flanneld.service << EOF 
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
Type=notify
ExecStart=/opt/k8s/bin/flanneld \
-etcd-cafile=/etc/kubernetes/cert/ca.pem \
-etcd-certfile=/etc/flanneld/cert/flanneld.pem \
-etcd-keyfile=/etc/flanneld/cert/flanneld-key.pem \
-etcd-endpoints=![](https://g.yuque.com/gr/latex?%7BETCD_ENDPOINTS%7D%20%5C%5C%0A%20%20-etcd-prefix%3D#card=math&code=%7BETCD_ENDPOINTS%7D%20%5C%5C%0A%20%20-etcd-prefix%3D&id=EgJp9){FLANNEL_ETCD_PREFIX} \
-iface=${IFACE} \
-ip-masq
ExecStartPost=/opt/k8s/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
EOF
4) 启动并验证
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20scp%20flanneld.service%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20scp%20flanneld.service%20root%40&id=dZNbs){all_ip}:/etc/systemd/system/
ssh root@${all_ip} "systemctl daemon-reload && systemctl enable flanneld --now"
done
1）查看pod段信息

[root[@k8s-master01 ](/k8s-master01 ) work]# etcdctl 
--endpoints=${ETCD_ENDPOINTS} 
--ca-file=/etc/kubernetes/cert/ca.pem 
--cert-file=/etc/flanneld/cert/flanneld.pem 
--key-file=/etc/flanneld/cert/flanneld-key.pem 
get ${FLANNEL_ETCD_PREFIX}/config
以二进制方式安装kubernetes 1.18.3版本（近60000字）
2）查看分配的pod子网段列表

[root[@k8s-master01 ](/k8s-master01 ) work]# etcdctl 
--endpoints=${ETCD_ENDPOINTS} 
--ca-file=/etc/kubernetes/cert/ca.pem 
--cert-file=/etc/flanneld/cert/flanneld.pem 
--key-file=/etc/flanneld/cert/flanneld-key.pem 
ls ${FLANNEL_ETCD_PREFIX}/subnets
以二进制方式安装kubernetes 1.18.3版本（近60000字）
3）查看一个pod网段对应的节点IP和flannel接口地址

[root[@k8s-master01 ](/k8s-master01 ) work]# etcdctl 
--endpoints=${ETCD_ENDPOINTS} 
--ca-file=/etc/kubernetes/cert/ca.pem 
--cert-file=/etc/flanneld/cert/flanneld.pem 
--key-file=/etc/flanneld/cert/flanneld-key.pem 
get ${FLANNEL_ETCD_PREFIX}/subnets/10.10.208.0-21
以二进制方式安装kubernetes 1.18.3版本（近60000字）

4.安装docker服务
Docker运行和管理容器，kubelet通过容器运行时接口（CRI）与之交互。

下载泊坞窗

[root[@k8s-master01 ](/k8s-master01 ) work]# wget [https://download.docker.com/linux/static/stable/x86_64/docker-19.03.12.tgz](https://download.docker.com/linux/static/stable/x86_64/docker-19.03.12.tgz)
[root[@k8s-master01 ](/k8s-master01 ) work]# tar -zxf docker-19.03.12.tgz 
安装泊坞窗

[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20scp%20docker%2F*%20%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20scp%20docker%2F%2A%20%20root%40&id=gi3iB){all_ip}:/opt/k8s/bin/
ssh root@${all_ip} "chmod +x /opt/k8s/bin/*"
done

1. 创建启动脚本
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > docker.service << "EOF" 
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io

[Service]
WorkingDirectory=##DOCKER_DIR##
Environment="PATH=/opt/k8s/bin:/bin:/sbin:/usr/bin:/usr/sbin"
EnvironmentFile=-/run/flannel/docker
ExecStart=/opt/k8s/bin/dockerd $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
Restart=on-failure
RestartSec=5
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
Delegate=yes
KillMode=process

[Install]
WantedBy=multi-user.target
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# sed -i -e "s|##DOCKER_DIR##|${DOCKER_DIR}|" docker.service 
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20scp%20docker.service%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20scp%20docker.service%20root%40&id=Ibr7m){all_ip}:/etc/systemd/system/
done
配置daemon.json文件

[root[@k8s-master01 ](/k8s-master01 ) work]# cat > daemon.json << EOF 
{
"registry-mirrors": ["[https://ipbtg5l0.mirror.aliyuncs.com](https://ipbtg5l0.mirror.aliyuncs.com)"],
"exec-opts": ["native.cgroupdriver=cgroupfs"],
"data-root": "![](https://g.yuque.com/gr/latex?%7BDOCKER_DIR%7D%2Fdata%22%2C%0A%20%20%20%20%22exec-root%22%3A%20%22#card=math&code=%7BDOCKER_DIR%7D%2Fdata%22%2C%0A%20%20%20%20%22exec-root%22%3A%20%22&id=sPHm1){DOCKER_DIR}/exec",
"log-driver": "json-file",
"log-opts": {
"max-size": "100m",
"max-file": "5"
},
"storage-driver": "overlay2",
"storage-opts": [
"overlay2.override_kernel_check=true"
]
}
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40&id=qQ2Pu){all_ip} "mkdir -p /etc/docker/ ![](https://g.yuque.com/gr/latex?%7BDOCKER_DIR%7D%2F%7Bdata%2Cexec%7D%22%0A%20%20%20%20scp%20docker-daemon.json%20root%40#card=math&code=%7BDOCKER_DIR%7D%2F%7Bdata%2Cexec%7D%22%0A%20%20%20%20scp%20docker-daemon.json%20root%40&id=e0uSR){all_ip}:/etc/docker/daemon.json
done
2) 启动泊坞窗
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40&id=IKgrY){all_ip} "systemctl daemon-reload && systemctl enable docker --now"
done
5.安装kubectl服务
下载 kubectl

[root[@k8s-master01 ](/k8s-master01 ) work]# wget [https://storage.googleapis.com/kubernetes-release/release/v1.18.3/kubernetes-client-linux-amd64.tar.gz](https://storage.googleapis.com/kubernetes-release/release/v1.18.3/kubernetes-client-linux-amd64.tar.gz)
[root[@k8s-master01 ](/k8s-master01 ) work]# tar -zxf kubernetes-client-linux-amd64.tar.gz 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kubernetes%2Fclient%2Fbin%2Fkubectl%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kubernetes%2Fclient%2Fbin%2Fkubectl%20root%40&id=ygVL5){master_ip}:/opt/k8s/bin/
ssh root@${master_ip} "chmod +x /opt/k8s/bin/*"
done
1）创建管理员证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > admin-csr.json << EOF 
{
"CN": "admin",
"hosts": [],
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "system:masters",
"OU": "System"
}
]
}
EOF
3) 生成证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -ca=/opt/k8s/work/ca.pem -ca-key=/opt/k8s/work/ca-key.pem -config=/opt/k8s/work/ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin 
4) 创建 kubeconfig 文件
配置集群参数

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-cluster kubernetes 
--certificate-authority=/opt/k8s/work/ca.pem 
--embed-certs=true 
--server=${KUBE_APISERVER} 
--kubeconfig=kubectl.kubeconfig
配置客户端认证参数

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-credentials admin 
--client-certificate=/opt/k8s/work/admin.pem 
--client-key=/opt/k8s/work/admin-key.pem 
--embed-certs=true 
--kubeconfig=kubectl.kubeconfig
配置上下文参数

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-context kubernetes 
--cluster=kubernetes 
--user=admin 
--kubeconfig=kubectl.kubeconfig
配置默认上下文

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config use-context kubernetes --kubeconfig=kubectl.kubeconfig 
5）创建kubectl配置文件，配置命令补全工具
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20ssh%20root%40&id=NA2SS){master_ip} "mkdir -p ~/.kube"
scp kubectl.kubeconfig root@![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%3A~%2F.kube%2Fconfig%0A%20%20%20%20ssh%20root%40#card=math&code=%7Bmaster_ip%7D%3A~%2F.kube%2Fconfig%0A%20%20%20%20ssh%20root%40&id=lZLLf){master_ip} "echo 'export KUBECONFIG=![](https://g.yuque.com/gr/latex?HOME%2F.kube%2Fconfig'%20%3E%3E%20~%2F.bashrc%22%0A%20%20%20%20ssh%20root%40#card=math&code=HOME%2F.kube%2Fconfig%27%20%3E%3E%20~%2F.bashrc%22%0A%20%20%20%20ssh%20root%40&id=JsV3U){master_ip} "echo 'source <(kubectl completion bash)' >> ~/.bashrc"
done
以下命令需要k8s-master01和k8s-master02上层配置：

[root[@k8s-master01 ](/k8s-master01 ) work]# source /usr/share/bash-completion/bash_completion 
[root[@k8s-master01 ](/k8s-master01 ) work]# source <(kubectl completion bash) 
[root[@k8s-master01 ](/k8s-master01 ) work]# bash ~/.bashrc 
三、安装kubenetes相关组件
1.安装Kube apiserver组件
下载 Kubernetes 二进制文件

[root[@k8s-master01 ](/k8s-master01 ) work]# wget [https://storage.googleapis.com/kubernetes-release/release/v1.18.3/kubernetes-server-linux-amd64.tar.gz](https://storage.googleapis.com/kubernetes-release/release/v1.18.3/kubernetes-server-linux-amd64.tar.gz)
[root[@k8s-master01 ](/k8s-master01 ) work]# tar -zxf kubernetes-server-linux-amd64.tar.gz 
[root[@k8s-master01 ](/k8s-master01 ) work]# cd kubernetes 
[root[@k8s-master01 ](/k8s-master01 ) kubernetes]# tar -zxf kubernetes-src.tar.gz 
[root[@k8s-master01 ](/k8s-master01 ) kubernetes]# cd .. 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20-rp%20kubernetes%2Fserver%2Fbin%2F%7Bapiextensions-apiserver%2Ckube-apiserver%2Ckube-controller-manager%2Ckube-scheduler%2Ckubeadm%2Ckubectl%2Cmounter%7D%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20-rp%20kubernetes%2Fserver%2Fbin%2F%7Bapiextensions-apiserver%2Ckube-apiserver%2Ckube-controller-manager%2Ckube-scheduler%2Ckubeadm%2Ckubectl%2Cmounter%7D%20root%40&id=jnvWD){master_ip}:/opt/k8s/bin/
ssh root@![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%20%22chmod%20%2Bx%20%2Fopt%2Fk8s%2Fbin%2F*%22%0A%20%20done%0A1%EF%BC%89%E5%88%9B%E5%BB%BAkubernetes%E8%AF%81%E4%B9%A6%E5%92%8C%E5%AF%86%E9%92%A5%0A%5Broot%40k8s-master01%20work%5D%23%20cat%20%3E%20kubernetes-csr.json%20%3C%3C%20EOF%0A%7B%0A%20%20%22CN%22%3A%20%22kubernetes%22%2C%0A%20%20%22hosts%22%3A%20%5B%0A%20%20%20%20%22127.0.0.1%22%2C%0A%20%20%20%20%22192.168.1.1%22%2C%0A%20%20%20%20%22192.168.1.2%22%2C%0A%20%20%20%20%22#card=math&code=%7Bmaster_ip%7D%20%22chmod%20%2Bx%20%2Fopt%2Fk8s%2Fbin%2F%2A%22%0A%20%20done%0A1%EF%BC%89%E5%88%9B%E5%BB%BAkubernetes%E8%AF%81%E4%B9%A6%E5%92%8C%E5%AF%86%E9%92%A5%0A%5Broot%40k8s-master01%20work%5D%23%20cat%20%3E%20kubernetes-csr.json%20%3C%3C%20EOF%0A%7B%0A%20%20%22CN%22%3A%20%22kubernetes%22%2C%0A%20%20%22hosts%22%3A%20%5B%0A%20%20%20%20%22127.0.0.1%22%2C%0A%20%20%20%20%22192.168.1.1%22%2C%0A%20%20%20%20%22192.168.1.2%22%2C%0A%20%20%20%20%22&id=iDVt2){CLUSTER_KUBERNETES_SVC_IP}",
"kubernetes",
"kubernetes.default",
"kubernetes.default.svc",
"kubernetes.default.svc.cluster",
"kubernetes.default.svc.cluster.local."
],
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "k8s",
"OU": "System"
}
]
}
EOF
2) 生成证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -ca=/opt/k8s/work/ca.pem -ca-key=/opt/k8s/work/ca-key.pem -config=/opt/k8s/work/ca-config.json -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20ssh%20root%40&id=OUao2){master_ip} "mkdir -p /etc/kubernetes/cert"
scp kubernetes*.pem root@${master_ip}:/etc/kubernetes/cert/
done
3) 配置 Kube apiserver 审计
创建加密配置文件

[root[@k8s-master01 ](/k8s-master01 ) work]# cat > encryption-config.yaml << EOF 
kind: EncryptionConfig
apiVersion: v1
resources:

- resources: 
   - secrets
providers:
   - aescbc:
keys:
- name: zhangsan
secret: ${ENCRYPTION_KEY}
   - identity: {}
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0Ascp%20encryption-config.yaml%20root%40#card=math&code=%7Bmaster_ip%7D%22%0Ascp%20encryption-config.yaml%20root%40&id=YImGt){master_ip}:/etc/kubernetes/encryption-config.yaml
done
创建审计策略文件

[root[@k8s-master01 ](/k8s-master01 ) work]# cat > audit-policy.yaml << EOF 
apiVersion: audit.k8s.io/v1beta1
kind: Policy
rules:

# The following requests were manually identified as high-volume and low-risk, so drop them.

-  level: None
resources: 
   - group: ""
resources: 
      - endpoints
      - services
      - services/status
users:
   - 'system:kube-proxy'
verbs:
   - watch
-  level: None
resources: 
   - group: ""
resources: 
      - nodes
      - nodes/status
userGroups:
   - 'system:nodes'
verbs:
   - get
-  level: None
namespaces: 
   - kube-system
resources:
   - group: ""
resources: 
      - endpoints
users:
   - 'system:kube-controller-manager'
   - 'system:kube-scheduler'
   - 'system:serviceaccount:kube-system:endpoint-controller'
verbs:
   - get
   - update
-  level: None
resources: 
   - group: ""
resources: 
      - namespaces
      - namespaces/status
      - namespaces/finalize
users:
   - 'system:apiserver'
verbs:
   - get

# Don't log HPA fetching metrics.

- level: None
resources: 
   - group: metrics.k8s.io
users:
   - 'system:kube-controller-manager'
verbs:
   - get
   - list

# Don't log these read-only URLs.

- level: None
nonResourceURLs: 
   - '/healthz*'
   - /version
   - '/swagger*'

# Don't log events requests.

- level: None
resources: 
   - group: ""
resources: 
      - events

# node and pod status calls from nodes are high-volume and can be large, don't log responses for expected updates from nodes

-  level: Request
omitStages: 
   - RequestReceived
resources:
   - group: ""
resources: 
      - nodes/status
      - pods/status
users:
   - kubelet
   - 'system:node-problem-detector'
   - 'system:serviceaccount:kube-system:node-problem-detector'
verbs:
   - update
   - patch
-  level: Request
omitStages: 
   - RequestReceived
resources:
   - group: ""
resources: 
      - nodes/status
      - pods/status
userGroups:
   - 'system:nodes'
verbs:
   - update
   - patch

# deletecollection calls can be large, don't log responses for expected namespace deletions

- level: Request
omitStages: 
   - RequestReceived
users:
   - 'system:serviceaccount:kube-system:namespace-controller'
verbs:
   - deletecollection

# Secrets, ConfigMaps, and TokenReviews can contain sensitive & binary data,

# so only log at the Metadata level.

- level: Metadata
omitStages: 
   - RequestReceived
resources:
   - group: ""
resources: 
      - secrets
      - configmaps
   - group: authentication.k8s.io
resources: 
      - tokenreviews

# Get repsonses can be large; skip them.

- level: Request
omitStages: 
   - RequestReceived
resources:
   - group: ""
   - group: admissionregistration.k8s.io
   - group: apiextensions.k8s.io
   - group: apiregistration.k8s.io
   - group: apps
   - group: authentication.k8s.io
   - group: authorization.k8s.io
   - group: autoscaling
   - group: batch
   - group: certificates.k8s.io
   - group: extensions
   - group: metrics.k8s.io
   - group: networking.k8s.io
   - group: policy
   - group: rbac.authorization.k8s.io
   - group: scheduling.k8s.io
   - group: settings.k8s.io
   - group: storage.k8s.io
verbs:
   - get
   - list
   - watch

# Default level for known APIs

- level: RequestResponse
omitStages: 
   - RequestReceived
resources:
   - group: ""
   - group: admissionregistration.k8s.io
   - group: apiextensions.k8s.io
   - group: apiregistration.k8s.io
   - group: apps
   - group: authentication.k8s.io
   - group: authorization.k8s.io
   - group: autoscaling
   - group: batch
   - group: certificates.k8s.io
   - group: extensions
   - group: metrics.k8s.io
   - group: networking.k8s.io
   - group: policy
   - group: rbac.authorization.k8s.io
   - group: scheduling.k8s.io
   - group: settings.k8s.io
   - group: storage.k8s.io

# Default level for all other requests.

- level: Metadata
omitStages: 
   - RequestReceived
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0Ascp%20audit-policy.yaml%20root%40#card=math&code=%7Bmaster_ip%7D%22%0Ascp%20audit-policy.yaml%20root%40&id=hOsuj){master_ip}:/etc/kubernetes/audit-policy.yaml
done

4. 配置指标服务器
建立metrics-serverCA证书申请文件

[root[@k8s-master01 ](/k8s-master01 ) work]# cat > proxy-client-csr.json << EOF 
{
"CN": "system:metrics-server",
"hosts": [],
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "k8s",
"OU": "System"
}
]
}
EOF
生成证书和密钥

[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -ca=/opt/k8s/work/ca.pem -ca-key=/opt/k8s/work/ca-key.pem -config=/opt/k8s/work/ca-config.json -profile=kubernetes proxy-client-csr.json | cfssljson -bare proxy-client 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20proxy-client*.pem%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20proxy-client%2A.pem%20root%40&id=kMmc1){master_ip}:/etc/kubernetes/cert/
done
5) 创建启动脚本
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-apiserver.service.template << EOF 
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkube-apiserver%0AExecStart%3D%2Fopt%2Fk8s%2Fbin%2Fkube-apiserver%20%5C%5C%0A%20%20--insecure-port%3D0%20%5C%5C%0A%20%20--secure-port%3D6443%20%5C%5C%0A%20%20--bind-address%3D%23%23MASTER_IP%23%23%20%5C%5C%0A%20%20--advertise-address%3D%23%23MASTER_IP%23%23%20%5C%5C%0A%20%20--default-not-ready-toleration-seconds%3D360%20%5C%5C%0A%20%20--default-unreachable-toleration-seconds%3D360%20%5C%5C%0A%20%20--feature-gates%3DDynamicAuditing%3Dtrue%20%5C%5C%0A%20%20--max-mutating-requests-inflight%3D2000%20%5C%5C%0A%20%20--max-requests-inflight%3D4000%20%5C%5C%0A%20%20--default-watch-cache-size%3D200%20%5C%5C%0A%20%20--delete-collection-workers%3D2%20%5C%5C%0A%20%20--encryption-provider-config%3D%2Fetc%2Fkubernetes%2Fencryption-config.yaml%20%5C%5C%0A%20%20--etcd-cafile%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--etcd-certfile%3D%2Fetc%2Fkubernetes%2Fcert%2Fkubernetes.pem%20%5C%5C%0A%20%20--etcd-keyfile%3D%2Fetc%2Fkubernetes%2Fcert%2Fkubernetes-key.pem%20%5C%5C%0A%20%20--etcd-servers%3D#card=math&code=%7BK8S_DIR%7D%2Fkube-apiserver%0AExecStart%3D%2Fopt%2Fk8s%2Fbin%2Fkube-apiserver%20%5C%5C%0A%20%20--insecure-port%3D0%20%5C%5C%0A%20%20--secure-port%3D6443%20%5C%5C%0A%20%20--bind-address%3D%23%23MASTER_IP%23%23%20%5C%5C%0A%20%20--advertise-address%3D%23%23MASTER_IP%23%23%20%5C%5C%0A%20%20--default-not-ready-toleration-seconds%3D360%20%5C%5C%0A%20%20--default-unreachable-toleration-seconds%3D360%20%5C%5C%0A%20%20--feature-gates%3DDynamicAuditing%3Dtrue%20%5C%5C%0A%20%20--max-mutating-requests-inflight%3D2000%20%5C%5C%0A%20%20--max-requests-inflight%3D4000%20%5C%5C%0A%20%20--default-watch-cache-size%3D200%20%5C%5C%0A%20%20--delete-collection-workers%3D2%20%5C%5C%0A%20%20--encryption-provider-config%3D%2Fetc%2Fkubernetes%2Fencryption-config.yaml%20%5C%5C%0A%20%20--etcd-cafile%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--etcd-certfile%3D%2Fetc%2Fkubernetes%2Fcert%2Fkubernetes.pem%20%5C%5C%0A%20%20--etcd-keyfile%3D%2Fetc%2Fkubernetes%2Fcert%2Fkubernetes-key.pem%20%5C%5C%0A%20%20--etcd-servers%3D&id=iaKZf){ETCD_ENDPOINTS} \
--tls-cert-file=/etc/kubernetes/cert/kubernetes.pem \
--tls-private-key-file=/etc/kubernetes/cert/kubernetes-key.pem \
--audit-dynamic-configuration \
--audit-log-maxage=30 \
--audit-log-maxbackup=3 \
--audit-log-maxsize=100 \
--audit-log-truncate-enabled=true \
--audit-log-path=![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkube-apiserver%2Faudit.log%20%5C%5C%0A%20%20--audit-policy-file%3D%2Fetc%2Fkubernetes%2Faudit-policy.yaml%20%5C%5C%0A%20%20--profiling%20%5C%5C%0A%20%20--anonymous-auth%3Dfalse%20%5C%5C%0A%20%20--client-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--enable-bootstrap-token-auth%3Dtrue%20%5C%5C%0A%20%20--requestheader-allowed-names%3D%22system%3Ametrics-server%22%20%5C%5C%0A%20%20--requestheader-client-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--requestheader-extra-headers-prefix%3DX-Remote-Extra-%20%5C%5C%0A%20%20--requestheader-group-headers%3DX-Remote-Group%20%5C%5C%0A%20%20--requestheader-username-headers%3DX-Remote-User%20%5C%5C%0A%20%20--service-account-key-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--authorization-mode%3DNode%2CRBAC%20%5C%5C%0A%20%20--runtime-config%3Dapi%2Fall%3Dtrue%20%5C%5C%0A%20%20--enable-admission-plugins%3DNamespaceLifecycle%2CLimitRanger%2CServiceAccount%2CDefaultStorageClass%2CDefaultTolerationSeconds%2CMutatingAdmissionWebhook%2CValidatingAdmissionWebhook%2CResourceQuota%2CNodeRestriction%20%5C%5C%0A%20%20--allow-privileged%3Dtrue%20%5C%5C%0A%20%20--apiserver-count%3D3%20%5C%5C%0A%20%20--event-ttl%3D168h%20%5C%5C%0A%20%20--kubelet-certificate-authority%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--kubelet-client-certificate%3D%2Fetc%2Fkubernetes%2Fcert%2Fkubernetes.pem%20%5C%5C%0A%20%20--kubelet-client-key%3D%2Fetc%2Fkubernetes%2Fcert%2Fkubernetes-key.pem%20%5C%5C%0A%20%20--kubelet-https%3Dtrue%20%5C%5C%0A%20%20--kubelet-timeout%3D10s%20%5C%5C%0A%20%20--proxy-client-cert-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fproxy-client.pem%20%5C%5C%0A%20%20--proxy-client-key-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fproxy-client-key.pem%20%5C%5C%0A%20%20--service-cluster-ip-range%3D#card=math&code=%7BK8S_DIR%7D%2Fkube-apiserver%2Faudit.log%20%5C%5C%0A%20%20--audit-policy-file%3D%2Fetc%2Fkubernetes%2Faudit-policy.yaml%20%5C%5C%0A%20%20--profiling%20%5C%5C%0A%20%20--anonymous-auth%3Dfalse%20%5C%5C%0A%20%20--client-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--enable-bootstrap-token-auth%3Dtrue%20%5C%5C%0A%20%20--requestheader-allowed-names%3D%22system%3Ametrics-server%22%20%5C%5C%0A%20%20--requestheader-client-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--requestheader-extra-headers-prefix%3DX-Remote-Extra-%20%5C%5C%0A%20%20--requestheader-group-headers%3DX-Remote-Group%20%5C%5C%0A%20%20--requestheader-username-headers%3DX-Remote-User%20%5C%5C%0A%20%20--service-account-key-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--authorization-mode%3DNode%2CRBAC%20%5C%5C%0A%20%20--runtime-config%3Dapi%2Fall%3Dtrue%20%5C%5C%0A%20%20--enable-admission-plugins%3DNamespaceLifecycle%2CLimitRanger%2CServiceAccount%2CDefaultStorageClass%2CDefaultTolerationSeconds%2CMutatingAdmissionWebhook%2CValidatingAdmissionWebhook%2CResourceQuota%2CNodeRestriction%20%5C%5C%0A%20%20--allow-privileged%3Dtrue%20%5C%5C%0A%20%20--apiserver-count%3D3%20%5C%5C%0A%20%20--event-ttl%3D168h%20%5C%5C%0A%20%20--kubelet-certificate-authority%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--kubelet-client-certificate%3D%2Fetc%2Fkubernetes%2Fcert%2Fkubernetes.pem%20%5C%5C%0A%20%20--kubelet-client-key%3D%2Fetc%2Fkubernetes%2Fcert%2Fkubernetes-key.pem%20%5C%5C%0A%20%20--kubelet-https%3Dtrue%20%5C%5C%0A%20%20--kubelet-timeout%3D10s%20%5C%5C%0A%20%20--proxy-client-cert-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fproxy-client.pem%20%5C%5C%0A%20%20--proxy-client-key-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fproxy-client-key.pem%20%5C%5C%0A%20%20--service-cluster-ip-range%3D&id=xvXbz){SERVICE_CIDR} \
--service-node-port-range=${NODE_PORT_RANGE} \
--logtostderr=true \
--v=2
Restart=on-failure
RestartSec=10
Type=notify
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
6) 启动 Kube apiserver 并验证
[root[@k8s-master01 ](/k8s-master01 ) work]# for (( A=0; A < 2; A++ )) 
do
sed -e "s/##MASTER_NAME##/![](https://g.yuque.com/gr/latex?%7BMASTER_NAMES%5BA%5D%7D%2F%22%20-e%20%22s%2F%23%23MASTER_IP%23%23%2F#card=math&code=%7BMASTER_NAMES%5BA%5D%7D%2F%22%20-e%20%22s%2F%23%23MASTER_IP%23%23%2F&id=K6yhj){MASTER_IPS[A]}/" kube-apiserver.service.template > kube-apiserver-${MASTER_IPS[A]}.service
done
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-apiserver-#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-apiserver-&id=hZs1Z){master_ip}.service root@![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%3A%2Fetc%2Fsystemd%2Fsystem%2Fkube-apiserver.service%0A%20%20%20%20ssh%20root%40#card=math&code=%7Bmaster_ip%7D%3A%2Fetc%2Fsystemd%2Fsystem%2Fkube-apiserver.service%0A%20%20%20%20ssh%20root%40&id=Bwj3j){master_ip} "mkdir -p ![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkube-apiserver%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7BK8S_DIR%7D%2Fkube-apiserver%22%0A%20%20%20%20ssh%20root%40&id=rah6q){master_ip} "systemctl daemon-reload && systemctl enable kube-apiserver --now"
done
查看 Kube apiserver 写入 etcd 的数据

[root[@k8s-master01 ](/k8s-master01 ) work]# ETCDCTL_API=3 etcdctl 
--endpoints=${ETCD_ENDPOINTS} 
--cacert=/opt/k8s/work/ca.pem 
--cert=/opt/k8s/work/etcd.pem 
--key=/opt/k8s/work/etcd-key.pem 
get /registry/ --prefix --keys-only
查看集群信息

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl cluster-info 
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl get all --all-namespaces 
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl get componentstatuses 
[root[@k8s-master01 ](/k8s-master01 ) work]# netstat -anpt | grep 6443 
以二进制方式安装kubernetes 1.18.3版本（近60000字）
授予kube-apiserver访问kubeletAPI 权限

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl create clusterrolebinding kube-apiserver:kubelet-apis --clusterrole=system:kubelet-api-admin --user kubernetes 
2.安装控制器管理器组件
1）创建控制器管理器证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-controller-manager-csr.json << EOF 
{
"CN": "system:kube-controller-manager",
"hosts": [
"127.0.0.1",
"192.168.1.1",
"192.168.1.2"
],
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "system:kube-controller-manager",
"OU": "System"
}
]
}
EOF
2) 生成证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -ca=/opt/k8s/work/ca.pem -ca-key=/opt/k8s/work/ca-key.pem -config=/opt/k8s/work/ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-controller-manager*.pem%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-controller-manager%2A.pem%20root%40&id=n4n3Q){master_ip}:/etc/kubernetes/cert/
done
3）创建kubeconfig文件
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-cluster kubernetes 
--certificate-authority=/opt/k8s/work/ca.pem 
--embed-certs=true 
--server=${KUBE_APISERVER} 
--kubeconfig=kube-controller-manager.kubeconfig
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-credentials system:kube-controller-manager 
--client-certificate=kube-controller-manager.pem 
--client-key=kube-controller-manager-key.pem 
--embed-certs=true 
--kubeconfig=kube-controller-manager.kubeconfig
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-context system:kube-controller-manager 
--cluster=kubernetes 
--user=system:kube-controller-manager 
--kubeconfig=kube-controller-manager.kubeconfig
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config use-context system:kube-controller-manager --kubeconfig=kube-controller-manager.kubeconfig 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-controller-manager.kubeconfig%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-controller-manager.kubeconfig%20root%40&id=OafgF){master_ip}:/etc/kubernetes/
done
4) 创建启动脚本
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-controller-manager.service.template << EOF 
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkube-controller-manager%0AExecStart%3D%2Fopt%2Fk8s%2Fbin%2Fkube-controller-manager%20%5C%5C%0A%20%20--secure-port%3D10257%20%5C%5C%0A%20%20--bind-address%3D127.0.0.1%20%5C%5C%0A%20%20--profiling%20%5C%5C%0A%20%20--cluster-name%3Dkubernetes%20%5C%5C%0A%20%20--controllers%3D*%2Cbootstrapsigner%2Ctokencleaner%20%5C%5C%0A%20%20--kube-api-qps%3D1000%20%5C%5C%0A%20%20--kube-api-burst%3D2000%20%5C%5C%0A%20%20--leader-elect%20%5C%5C%0A%20%20--use-service-account-credentials%5C%5C%0A%20%20--concurrent-service-syncs%3D2%20%5C%5C%0A%20%20--tls-cert-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fkube-controller-manager.pem%20%5C%5C%0A%20%20--tls-private-key-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fkube-controller-manager-key.pem%20%5C%5C%0A%20%20--authentication-kubeconfig%3D%2Fetc%2Fkubernetes%2Fkube-controller-manager.kubeconfig%20%5C%5C%0A%20%20--client-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--requestheader-allowed-names%3D%22system%3Ametrics-server%22%20%5C%5C%0A%20%20--requestheader-client-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--requestheader-extra-headers-prefix%3D%22X-Remote-Extra-%22%20%5C%5C%0A%20%20--requestheader-group-headers%3DX-Remote-Group%20%5C%5C%0A%20%20--requestheader-username-headers%3DX-Remote-User%20%5C%5C%0A%20%20--cluster-signing-cert-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--cluster-signing-key-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca-key.pem%20%5C%5C%0A%20%20--experimental-cluster-signing-duration%3D87600h%20%5C%5C%0A%20%20--horizontal-pod-autoscaler-sync-period%3D10s%20%5C%5C%0A%20%20--concurrent-deployment-syncs%3D10%20%5C%5C%0A%20%20--concurrent-gc-syncs%3D30%20%5C%5C%0A%20%20--node-cidr-mask-size%3D24%20%5C%5C%0A%20%20--service-cluster-ip-range%3D#card=math&code=%7BK8S_DIR%7D%2Fkube-controller-manager%0AExecStart%3D%2Fopt%2Fk8s%2Fbin%2Fkube-controller-manager%20%5C%5C%0A%20%20--secure-port%3D10257%20%5C%5C%0A%20%20--bind-address%3D127.0.0.1%20%5C%5C%0A%20%20--profiling%20%5C%5C%0A%20%20--cluster-name%3Dkubernetes%20%5C%5C%0A%20%20--controllers%3D%2A%2Cbootstrapsigner%2Ctokencleaner%20%5C%5C%0A%20%20--kube-api-qps%3D1000%20%5C%5C%0A%20%20--kube-api-burst%3D2000%20%5C%5C%0A%20%20--leader-elect%20%5C%5C%0A%20%20--use-service-account-credentials%5C%5C%0A%20%20--concurrent-service-syncs%3D2%20%5C%5C%0A%20%20--tls-cert-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fkube-controller-manager.pem%20%5C%5C%0A%20%20--tls-private-key-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fkube-controller-manager-key.pem%20%5C%5C%0A%20%20--authentication-kubeconfig%3D%2Fetc%2Fkubernetes%2Fkube-controller-manager.kubeconfig%20%5C%5C%0A%20%20--client-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--requestheader-allowed-names%3D%22system%3Ametrics-server%22%20%5C%5C%0A%20%20--requestheader-client-ca-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--requestheader-extra-headers-prefix%3D%22X-Remote-Extra-%22%20%5C%5C%0A%20%20--requestheader-group-headers%3DX-Remote-Group%20%5C%5C%0A%20%20--requestheader-username-headers%3DX-Remote-User%20%5C%5C%0A%20%20--cluster-signing-cert-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%5C%0A%20%20--cluster-signing-key-file%3D%2Fetc%2Fkubernetes%2Fcert%2Fca-key.pem%20%5C%5C%0A%20%20--experimental-cluster-signing-duration%3D87600h%20%5C%5C%0A%20%20--horizontal-pod-autoscaler-sync-period%3D10s%20%5C%5C%0A%20%20--concurrent-deployment-syncs%3D10%20%5C%5C%0A%20%20--concurrent-gc-syncs%3D30%20%5C%5C%0A%20%20--node-cidr-mask-size%3D24%20%5C%5C%0A%20%20--service-cluster-ip-range%3D&id=lgyzg){SERVICE_CIDR} \
--cluster-cidr=${CLUSTER_CIDR} \
--pod-eviction-timeout=6m \
--terminated-pod-gc-threshold=10000 \
--root-ca-file=/etc/kubernetes/cert/ca.pem \
--service-account-private-key-file=/etc/kubernetes/cert/ca-key.pem \
--kubeconfig=/etc/kubernetes/kube-controller-manager.kubeconfig \
--logtostderr=true \
--v=2
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
4) 启动并验证
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-controller-manager.service.template%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-controller-manager.service.template%20root%40&id=yE9Ag){master_ip}:/etc/systemd/system/kube-controller-manager.service
ssh root@${master_ip} "mkdir -p ![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkube-controller-manager%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7BK8S_DIR%7D%2Fkube-controller-manager%22%0A%20%20%20%20ssh%20root%40&id=KAN5H){master_ip} "systemctl daemon-reload && systemctl enable kube-controller-manager --now"
done
查看输出指标

[root[@k8s-master01 ](/k8s-master01 ) work]# curl -s --cacert /opt/k8s/work/ca.pem --cert /opt/k8s/work/admin.pem --key /opt/k8s/work/admin-key.pem [https://127.0.0.1:10257/metrics](https://127.0.0.1:10257/metrics) | head
查看权限

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl describe clusterrole system:kube-controller-manager 
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl get clusterrole | grep controller 
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl describe clusterrole system:controller:deployment-controller 
查看当前领导

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl get endpoints kube-controller-manager --namespace=kube-system -o yaml 
3.安装Kube调度器组件

1. 创建 Kube 调度程序证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-scheduler-csr.json << EOF 
{
"CN": "system:kube-scheduler",
"hosts": [
"127.0.0.1",
"192.168.1.1",
"192.168.1.2"
],
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "system:kube-scheduler",
"OU": "System"
}
]
}
EOF
2. 生成证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -ca=/opt/k8s/work/ca.pem -ca-key=/opt/k8s/work/ca-key.pem -config=/opt/k8s/work/ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20scp%20kube-scheduler*.pem%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20scp%20kube-scheduler%2A.pem%20root%40&id=jNaCk){master_ip}:/etc/kubernetes/cert/
done
3）创建kubeconfig文件
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-cluster kubernetes 
--certificate-authority=/opt/k8s/work/ca.pem 
--embed-certs=true 
--server=${KUBE_APISERVER} 
--kubeconfig=kube-scheduler.kubeconfig
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-credentials system:kube-scheduler 
--client-certificate=kube-scheduler.pem 
--client-key=kube-scheduler-key.pem 
--embed-certs=true 
--kubeconfig=kube-scheduler.kubeconfig
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-context system:kube-scheduler 
--cluster=kubernetes 
--user=system:kube-scheduler 
--kubeconfig=kube-scheduler.kubeconfig
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config use-context system:kube-scheduler --kubeconfig=kube-scheduler.kubeconfig 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20scp%20kube-scheduler.kubeconfig%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20scp%20kube-scheduler.kubeconfig%20root%40&id=ZN8sT){master_ip}:/etc/kubernetes/
done
3. 创建 Kube 调度器配置文件
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-scheduler.yaml.template << EOF 
apiVersion: kubescheduler.config.k8s.io/v1alpha1
kind: KubeSchedulerConfiguration
bindTimeoutSeconds: 600
clientConnection:
burst: 200
kubeconfig: "/etc/kubernetes/kube-scheduler.kubeconfig"
qps: 100
enableContentionProfiling: false
enableProfiling: true
hardPodAffinitySymmetricWeight: 1
healthzBindAddress: 127.0.0.1:10251
leaderElection:
leaderElect: true
metricsBindAddress: 127.0.0.1:10251
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20scp%20kube-scheduler.yaml.template%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20scp%20kube-scheduler.yaml.template%20root%40&id=o6Cqa){master_ip}:/etc/kubernetes/kube-scheduler.yaml
done
4. 创建启动脚本
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-scheduler.service.template << EOF 
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes

[Service]
WorkingDirectory=${K8S_DIR}/kube-scheduler
ExecStart=/opt/k8s/bin/kube-scheduler \
--port=0 \
--secure-port=10259 \
--bind-address=127.0.0.1 \
--config=/etc/kubernetes/kube-scheduler.yaml \
--tls-cert-file=/etc/kubernetes/cert/kube-scheduler.pem \
--tls-private-key-file=/etc/kubernetes/cert/kube-scheduler-key.pem \
--authentication-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \
--client-ca-file=/etc/kubernetes/cert/ca.pem \
--requestheader-allowed-names="system:metrics-server" \
--requestheader-client-ca-file=/etc/kubernetes/cert/ca.pem \
--requestheader-extra-headers-prefix="X-Remote-Extra-" \
--requestheader-group-headers=X-Remote-Group \
--requestheader-username-headers=X-Remote-User \
--authorization-kubeconfig=/etc/kubernetes/kube-scheduler.kubeconfig \
--logtostderr=true \
--v=2
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF
6) 启动并验证
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-scheduler.service.template%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20%20%20%20scp%20kube-scheduler.service.template%20root%40&id=pwd9p){master_ip}:/etc/systemd/system/kube-scheduler.service
ssh root@${master_ip} "mkdir -p ![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkube-scheduler%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7BK8S_DIR%7D%2Fkube-scheduler%22%0A%20%20%20%20ssh%20root%40&id=Hlnva){master_ip} "systemctl daemon-reload && systemctl enable kube-scheduler --now"
done
[root[@k8s-master01 ](/k8s-master01 ) work]# netstat -nlpt | grep kube-schedule 
10251：接收httpRequest，非安全端口，未认证授权；
10259：接收https请求，安全端口，需要认证和授权（这两个接口都是外部提供的）/metrics和/healthz（访问）
查看输出指标

[root[@k8s-master01 ](/k8s-master01 ) work]# curl -s --cacert /opt/k8s/work/ca.pem --cert /opt/k8s/work/admin.pem --key /opt/k8s/work/admin-key.pem [https://127.0.0.1:10257/metrics](https://127.0.0.1:10257/metrics) | head
查看权限

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl describe clusterrole system:kube-controller-manager 
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl get clusterrole | grep controller 
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl describe clusterrole system:controller:deployment-controller 
查看当前领导

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl get endpoints kube-controller-manager --namespace=kube-system -o yaml 
4.安装kubelet组件
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20scp%20kubernetes%2Fserver%2Fbin%2Fkubelet%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20scp%20kubernetes%2Fserver%2Fbin%2Fkubelet%20root%40&id=EcbSU){all_ip}:/opt/k8s/bin/
ssh root@${all_ip} "chmod +x /opt/k8s/bin/*"
done
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_name in ${ALL_NAMES[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_name%7D%22%0A%20%20%20%20export%20BOOTSTRAP_TOKEN%3D#card=math&code=%7Ball_name%7D%22%0A%20%20%20%20export%20BOOTSTRAP_TOKEN%3D&id=a2Zdh)(kubeadm token create 
--description kubelet-bootstrap-token 
--groups system:bootstrappers:![](https://g.yuque.com/gr/latex?%7Ball_name%7D%20%5C%0A%20%20%20%20%20%20--kubeconfig%20~%2F.kube%2Fconfig)%0A%20%20%20%20kubectl%20config%20set-cluster%20kubernetes%20%5C%0A%20%20%20%20%20%20--certificate-authority%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%0A%20%20%20%20%20%20--embed-certs%3Dtrue%20%5C%0A%20%20%20%20%20%20--server%3D#card=math&code=%7Ball_name%7D%20%5C%0A%20%20%20%20%20%20--kubeconfig%20~%2F.kube%2Fconfig%29%0A%20%20%20%20kubectl%20config%20set-cluster%20kubernetes%20%5C%0A%20%20%20%20%20%20--certificate-authority%3D%2Fetc%2Fkubernetes%2Fcert%2Fca.pem%20%5C%0A%20%20%20%20%20%20--embed-certs%3Dtrue%20%5C%0A%20%20%20%20%20%20--server%3D&id=BGjXl){KUBE_APISERVER} 
--kubeconfig=kubelet-bootstrap-![](https://g.yuque.com/gr/latex?%7Ball_name%7D.kubeconfig%0A%20%20%20%20kubectl%20config%20set-credentials%20kubelet-bootstrap%20%5C%0A%20%20%20%20%20%20--token%3D#card=math&code=%7Ball_name%7D.kubeconfig%0A%20%20%20%20kubectl%20config%20set-credentials%20kubelet-bootstrap%20%5C%0A%20%20%20%20%20%20--token%3D&id=v1Jat){BOOTSTRAP_TOKEN} 
--kubeconfig=kubelet-bootstrap-![](https://g.yuque.com/gr/latex?%7Ball_name%7D.kubeconfig%0A%20%20%20%20kubectl%20config%20set-context%20default%20%5C%0A%20%20%20%20%20%20--cluster%3Dkubernetes%20%5C%0A%20%20%20%20%20%20--user%3Dkubelet-bootstrap%20%5C%0A%20%20%20%20%20%20--kubeconfig%3Dkubelet-bootstrap-#card=math&code=%7Ball_name%7D.kubeconfig%0A%20%20%20%20kubectl%20config%20set-context%20default%20%5C%0A%20%20%20%20%20%20--cluster%3Dkubernetes%20%5C%0A%20%20%20%20%20%20--user%3Dkubelet-bootstrap%20%5C%0A%20%20%20%20%20%20--kubeconfig%3Dkubelet-bootstrap-&id=B2Wfe){all_name}.kubeconfig
kubectl config use-context default --kubeconfig=kubelet-bootstrap-${all_name}.kubeconfig
done
[ root[@k8s ](/k8s ) -master01 work]# kubeadm token list --kubeconfig ~/. kube/config 					#  View the tokens created by kubedm for each node 
[ root[@k8s ](/k8s ) -master01 work]# kubectl get secrets -n kube-system | grep bootstrap-token 			#  View the secret associated with each token 
以二进制方式安装kubernetes 1.18.3版本（近60000字）

[root[@k8s-master01 ](/k8s-master01 ) work]# for all_name in ${ALL_NAMES[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_name%7D%22%0A%20%20%20%20scp%20kubelet-bootstrap-#card=math&code=%7Ball_name%7D%22%0A%20%20%20%20scp%20kubelet-bootstrap-&id=LKeBl){all_name}.kubeconfig root@${all_name}:/etc/kubernetes/kubelet-bootstrap.kubeconfig
done
创建 kubelet 参数配置文件

[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kubelet-config.yaml.template << EOF 
kind: KubeletConfiguration
apiVersion: kubelet.config.k8s.io/v1beta1
address: "##ALL_IP##"
staticPodPath: ""
syncFrequency: 1m
fileCheckFrequency: 20s
httpCheckFrequency: 20s
staticPodURL: ""
port: 10250
readOnlyPort: 0
rotateCertificates: true
serverTLSBootstrap: true
authentication:
anonymous:
enabled: false
webhook:
enabled: true
x509:
clientCAFile: "/etc/kubernetes/cert/ca.pem"
authorization:
mode: Webhook
registryPullQPS: 0
registryBurst: 20
eventRecordQPS: 0
eventBurst: 20
enableDebuggingHandlers: true
enableContentionProfiling: true
healthzPort: 10248
healthzBindAddress: "##ALL_IP##"
clusterDomain: "${CLUSTER_DNS_DOMAIN}"
clusterDNS:

- "![](https://g.yuque.com/gr/latex?%7BCLUSTER_DNS_SVC_IP%7D%22%0AnodeStatusUpdateFrequency%3A%2010s%0AnodeStatusReportFrequency%3A%201m%0AimageMinimumGCAge%3A%202m%0AimageGCHighThresholdPercent%3A%2085%0AimageGCLowThresholdPercent%3A%2080%0AvolumeStatsAggPeriod%3A%201m%0AkubeletCgroups%3A%20%22%22%0AsystemCgroups%3A%20%22%22%0AcgroupRoot%3A%20%22%22%0AcgroupsPerQOS%3A%20true%0AcgroupDriver%3A%20cgroupfs%0AruntimeRequestTimeout%3A%2010m%0AhairpinMode%3A%20promiscuous-bridge%0AmaxPods%3A%20220%0ApodCIDR%3A%20%22#card=math&code=%7BCLUSTER_DNS_SVC_IP%7D%22%0AnodeStatusUpdateFrequency%3A%2010s%0AnodeStatusReportFrequency%3A%201m%0AimageMinimumGCAge%3A%202m%0AimageGCHighThresholdPercent%3A%2085%0AimageGCLowThresholdPercent%3A%2080%0AvolumeStatsAggPeriod%3A%201m%0AkubeletCgroups%3A%20%22%22%0AsystemCgroups%3A%20%22%22%0AcgroupRoot%3A%20%22%22%0AcgroupsPerQOS%3A%20true%0AcgroupDriver%3A%20cgroupfs%0AruntimeRequestTimeout%3A%2010m%0AhairpinMode%3A%20promiscuous-bridge%0AmaxPods%3A%20220%0ApodCIDR%3A%20%22&id=FAPp5){CLUSTER_CIDR}"
podPidsLimit: -1
resolvConf: /etc/resolv.conf
maxOpenFiles: 1000000
kubeAPIQPS: 1000
kubeAPIBurst: 2000
serializeImagePulls: false
evictionHard:
memory.available:  "100Mi"
nodefs.available:  "10%"
nodefs.inodesFree: "5%"
imagefs.available: "15%"
evictionSoft: {}
enableControllerAttachDetach: true
failSwapOn: true
containerLogMaxSize: 20Mi
containerLogMaxFiles: 10
systemReserved: {}
kubeReserved: {}
systemReservedCgroup: ""
kubeReservedCgroup: ""
enforceNodeAllocatable: ["pods"]
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0Ased%20-e%20%22s%2F%23%23ALL_IP%23%23%2F#card=math&code=%7Ball_ip%7D%22%0Ased%20-e%20%22s%2F%23%23ALL_IP%23%23%2F&id=nSnG2){all_ip}/" kubelet-config.yaml.template > kubelet-config-![](https://g.yuque.com/gr/latex?%7Ball_ip%7D.yaml.template%0Ascp%20kubelet-config-#card=math&code=%7Ball_ip%7D.yaml.template%0Ascp%20kubelet-config-&id=MoOvn){all_ip}.yaml.template root@${all_ip}:/etc/kubernetes/kubelet-config.yaml
done
1）创建kubelet启动脚本
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kubelet.service.template << EOF 
[Unit]
Description=Kubernetes Kubelet
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=docker.service
Requires=docker.service

[Service]
WorkingDirectory=![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkubelet%0AExecStart%3D%2Fopt%2Fk8s%2Fbin%2Fkubelet%20%5C%5C%0A%20%20--bootstrap-kubeconfig%3D%2Fetc%2Fkubernetes%2Fkubelet-bootstrap.kubeconfig%20%5C%5C%0A%20%20--cert-dir%3D%2Fetc%2Fkubernetes%2Fcert%20%5C%5C%0A%20%20--cgroup-driver%3Dcgroupfs%20%5C%5C%0A%20%20--cni-conf-dir%3D%2Fetc%2Fcni%2Fnet.d%20%5C%5C%0A%20%20--container-runtime%3Ddocker%20%5C%5C%0A%20%20--container-runtime-endpoint%3Dunix%3A%2F%2F%2Fvar%2Frun%2Fdockershim.sock%20%5C%5C%0A%20%20--root-dir%3D#card=math&code=%7BK8S_DIR%7D%2Fkubelet%0AExecStart%3D%2Fopt%2Fk8s%2Fbin%2Fkubelet%20%5C%5C%0A%20%20--bootstrap-kubeconfig%3D%2Fetc%2Fkubernetes%2Fkubelet-bootstrap.kubeconfig%20%5C%5C%0A%20%20--cert-dir%3D%2Fetc%2Fkubernetes%2Fcert%20%5C%5C%0A%20%20--cgroup-driver%3Dcgroupfs%20%5C%5C%0A%20%20--cni-conf-dir%3D%2Fetc%2Fcni%2Fnet.d%20%5C%5C%0A%20%20--container-runtime%3Ddocker%20%5C%5C%0A%20%20--container-runtime-endpoint%3Dunix%3A%2F%2F%2Fvar%2Frun%2Fdockershim.sock%20%5C%5C%0A%20%20--root-dir%3D&id=YzBh2){K8S_DIR}/kubelet \
--kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
--config=/etc/kubernetes/kubelet-config.yaml \
--hostname-override=##ALL_NAME## \
--pod-infra-container-image=registry.aliyuncs.com/google_containers/pause-amd64:3.2 \
--image-pull-progress-deadline=15m \
--volume-plugin-dir=${K8S_DIR}/kubelet/kubelet-plugins/volume/exec/ \
--logtostderr=true \
--v=2
Restart=always
RestartSec=5
StartLimitInterval=0

[Install]
WantedBy=multi-user.target
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_name in ${ALL_NAMES[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_name%7D%22%0A%20%20%20%20sed%20-e%20%22s%2F%23%23ALL_NAME%23%23%2F#card=math&code=%7Ball_name%7D%22%0A%20%20%20%20sed%20-e%20%22s%2F%23%23ALL_NAME%23%23%2F&id=YjmGh){all_name}/" kubelet.service.template > kubelet-![](https://g.yuque.com/gr/latex?%7Ball_name%7D.service%0A%20%20%20%20scp%20kubelet-#card=math&code=%7Ball_name%7D.service%0A%20%20%20%20scp%20kubelet-&id=j1Dh1){all_name}.service root@${all_name}:/etc/systemd/system/kubelet.service
done
2) 启动并验证
授予授权

[root[@k8s-master01 ](/k8s-master01 ) ~]# kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --group=system:bootstrappers 
启动 kubelet

[root[@k8s-master01 ](/k8s-master01 ) work]# for all_name in ${ALL_NAMES[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_name%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Ball_name%7D%22%0A%20%20%20%20ssh%20root%40&id=xDj5N){all_name} "mkdir -p ![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkubelet%2Fkubelet-plugins%2Fvolume%2Fexec%2F%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7BK8S_DIR%7D%2Fkubelet%2Fkubelet-plugins%2Fvolume%2Fexec%2F%22%0A%20%20%20%20ssh%20root%40&id=Y67Ho){all_name} "systemctl daemon-reload && systemctl enable kubelet --now"
done
查看 kubelet 服务

[root[@k8s-master01 ](/k8s-master01 ) work]# for all_name in ${ALL_NAMES[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_name%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Ball_name%7D%22%0A%20%20%20%20ssh%20root%40&id=X2YfO){all_name} "systemctl status kubelet | grep active"
done
[ root[@k8s ](/k8s ) -master01 work]# kubectl get csr 									#  Because we haven't certified yet So the Pengding status is displayed 
以二进制方式安装kubernetes 1.18.3版本（近60000字）

3. 批准 CSR 请求
自动批准CSR请求（创建三个clusterrolebinding为自动approve client renew client renew server（证书）

[root[@k8s-master01 ](/k8s-master01 ) work]# cat > csr-crb.yaml << EOF 

# Approve all CSRs for the group "system:bootstrappers"

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
name: auto-approve-csrs-for-group
subjects:

- kind: Group
name: system:bootstrappers
apiGroup: rbac.authorization.k8s.io
roleRef:
kind: ClusterRole
name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
apiGroup: rbac.authorization.k8s.io

---

# To let a node of the group "system:nodes" renew its own credentials

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
name: node-client-cert-renewal
subjects:

- kind: Group
name: system:nodes
apiGroup: rbac.authorization.k8s.io
roleRef:
kind: ClusterRole
name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
apiGroup: rbac.authorization.k8s.io

---

# A ClusterRole which instructs the CSR approver to approve a node requesting a

# serving cert matching its client cert.

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
name: approve-node-server-renewal-csr
rules:

- apiGroups: ["certificates.k8s.io"]
resources: ["certificatesigningrequests/selfnodeserver"]
verbs: ["create"]

---

# To let a node of the group "system:nodes" renew its own server credentials

kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
name: node-server-cert-renewal
subjects:

- kind: Group
name: system:nodes
apiGroup: rbac.authorization.k8s.io
roleRef:
kind: ClusterRole
name: approve-node-server-renewal-csr
apiGroup: rbac.authorization.k8s.io
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl apply -f csr-crb.yaml 
验证（等待一1 ~ 5分钟），三个节点的CSR是自动的approved）

[ root[@k8s ](/k8s ) -master01 work]# kubectl get csr | grep boot 				#  After waiting for a period of time (1-10 minutes), the CSR of the three nodes are automatically approved 
[ root[@k8s ](/k8s ) -master01 work]# kubectl get nodes 							#  All nodes are ready 
以二进制方式安装kubernetes 1.18.3版本（近60000字）

[root[@k8s-master01 ](/k8s-master01 ) ~]# ls -l /etc/kubernetes/kubelet.kubeconfig 
[root[@k8s-master01 ](/k8s-master01 ) ~]# ls -l /etc/kubernetes/cert/ | grep kubelet 
以二进制方式安装kubernetes 1.18.3版本（近60000字）

4. 手动批准服务器证书 CSR
出于安全原因，CSRapproving controllers不自动approve kubelet server证书签名请求，手动approve

[root[@k8s-master01 ](/k8s-master01 ) ~]# kubectl get csr | grep node 
以二进制方式安装kubernetes 1.18.3版本（近60000字）

[root[@k8s-master01 ](/k8s-master01 ) ~]# kubectl get csr | grep Pending | awk '{print $1}' | xargs kubectl certificate approve 
[root[@k8s-master01 ](/k8s-master01 ) ~]# ls -l /etc/kubernetes/cert/kubelet-* 
以二进制方式安装kubernetes 1.18.3版本（近60000字）

5. Kubelet API 接口配置
Kubelet API 认证和授权

[root[@k8s-master01 ](/k8s-master01 ) ~]# curl -s --cacert /etc/kubernetes/cert/ca.pem [https://192.168.1.1:10250/metrics](https://192.168.1.1:10250/metrics)
[root[@k8s-master01 ](/k8s-master01 ) ~]# curl -s --cacert /etc/kubernetes/cert/ca.pem -H "Authorization: Bearer 123456" [https://192.168.1.1:10250/metrics](https://192.168.1.1:10250/metrics)
以二进制方式安装kubernetes 1.18.3版本（近60000字）
证书认证和授权

//Insufficient default permissions
[root[@k8s-master01 ](/k8s-master01 ) ~]# curl -s --cacert /etc/kubernetes/cert/ca.pem --cert /etc/kubernetes/cert/kube-controller-manager.pem --key /etc/kubernetes/cert/kube-controller-manager-key.pem [https://192.168.1.1:10250/metrics](https://192.168.1.1:10250/metrics)
//Use admin with the highest permission
[root[@k8s-master01 ](/k8s-master01 ) ~]# curl -s --cacert /etc/kubernetes/cert/ca.pem --cert /opt/k8s/work/admin.pem --key /opt/k8s/work/admin-key.pem [https://192.168.1.1:10250/metrics](https://192.168.1.1:10250/metrics) | head
创建熊令牌认证和授权

[root[@k8s-master01 ](/k8s-master01 ) ~]# kubectl create serviceaccount kubelet-api-test 
[root[@k8s-master01 ](/k8s-master01 ) ~]# kubectl create clusterrolebinding kubelet-api-test --clusterrole=system:kubelet-api-admin --serviceaccount=default:kubelet-api-test 
[root[@k8s-master01 ](/k8s-master01 ) ~]# SECRET=$(kubectl get secrets | grep kubelet-api-test | awk '{print ![](https://g.yuque.com/gr/latex?1%7D')%0A%5Broot%40k8s-master01%20~%5D%23%20TOKEN%3D#card=math&code=1%7D%27%29%0A%5Broot%40k8s-master01%20~%5D%23%20TOKEN%3D&id=K8kes)(kubectl describe secret ${SECRET} | grep -E '^token' | awk '{print $2}')
[root[@k8s-master01 ](/k8s-master01 ) ~]# echo ${TOKEN} 
[root[@k8s-master01 ](/k8s-master01 ) ~]# curl -s --cacert /etc/kubernetes/cert/ca.pem -H "Authorization: Bearer ${TOKEN}" [https://192.168.1.1:10250/metrics](https://192.168.1.1:10250/metrics) | head
5.安装Kube代理组件
Kube proxy 运行在所有主机上，监控 apiserver 中 service 和 endpoint 的变化，并创建路由规则提供服务 IP 和负载均衡功能。

[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20scp%20kubernetes%2Fserver%2Fbin%2Fkube-proxy%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20scp%20kubernetes%2Fserver%2Fbin%2Fkube-proxy%20root%40&id=lvkOT){all_ip}:/opt/k8s/bin/
ssh root@${all_ip} "chmod +x /opt/k8s/bin/*"
done

1. 创建 Kube 代理证书和密钥
为 Kube 代理创建 CA 证书请求文件

[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-proxy-csr.json << EOF 
{
"CN": "system:kube-proxy",
"key": {
"algo": "rsa",
"size": 2048
},
"names": [
{
"C": "CN",
"ST": "Shanghai",
"L": "Shanghai",
"O": "k8s",
"OU": "System"
}
]
}
EOF
2) 生成证书和密钥
[root[@k8s-master01 ](/k8s-master01 ) work]# cfssl gencert -ca=/opt/k8s/work/ca.pem -ca-key=/opt/k8s/work/ca-key.pem -config=/opt/k8s/work/ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy 
3）创建kubeconfig文件
[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-cluster kubernetes 
--certificate-authority=/opt/k8s/work/ca.pem 
--embed-certs=true 
--server=${KUBE_APISERVER} 
--kubeconfig=kube-proxy.kubeconfig

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-credentials kube-proxy 
--client-certificate=kube-proxy.pem 
--client-key=kube-proxy-key.pem 
--embed-certs=true 
--kubeconfig=kube-proxy.kubeconfig

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config set-context default 
--cluster=kubernetes 
--user=kube-proxy 
--kubeconfig=kube-proxy.kubeconfig

[root[@k8s-master01 ](/k8s-master01 ) work]# kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig 
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20scp%20kube-proxy.kubeconfig%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20scp%20kube-proxy.kubeconfig%20root%40&id=KnYTd){all_ip}:/etc/kubernetes/
done
4) 创建 Kube 代理配置文件
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-proxy-config.yaml.template << EOF 
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
burst: 200
kubeconfig: "/etc/kubernetes/kube-proxy.kubeconfig"
qps: 100
bindAddress: ##ALL_IP##
healthzBindAddress: ##ALL_IP##:10256
metricsBindAddress: ##ALL_IP##:10249
enableProfiling: true
clusterCIDR: ${CLUSTER_CIDR}
hostnameOverride: ##ALL_NAME##
mode: "ipvs"
portRange: ""
kubeProxyIPTablesConfiguration:
masqueradeAll: false
kubeProxyIPVSConfiguration:
scheduler: rr
excludeCIDRs: []
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for (( i=0; i < 3; i++ )) 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7BALL_NAMES%5Bi%5D%7D%22%0A%20%20%20%20sed%20-e%20%22s%2F%23%23ALL_NAME%23%23%2F#card=math&code=%7BALL_NAMES%5Bi%5D%7D%22%0A%20%20%20%20sed%20-e%20%22s%2F%23%23ALL_NAME%23%23%2F&id=x1tUX){ALL_NAMES[i]}/" -e "s/##ALL_IP##/![](https://g.yuque.com/gr/latex?%7BALL_IPS%5Bi%5D%7D%2F%22%20kube-proxy-config.yaml.template%20%3E%20kube-proxy-config-#card=math&code=%7BALL_IPS%5Bi%5D%7D%2F%22%20kube-proxy-config.yaml.template%20%3E%20kube-proxy-config-&id=In8mk){ALL_NAMES[i]}.yaml.template
scp kube-proxy-config-![](https://g.yuque.com/gr/latex?%7BALL_NAMES%5Bi%5D%7D.yaml.template%20root%40#card=math&code=%7BALL_NAMES%5Bi%5D%7D.yaml.template%20root%40&id=YGtf5){ALL_NAMES[i]}:/etc/kubernetes/kube-proxy-config.yaml
done
4) 创建启动脚本
[root[@k8s-master01 ](/k8s-master01 ) work]# cat > kube-proxy.service << EOF 
[Unit]
Description=Kubernetes Kube-Proxy Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target

[Service]
WorkingDirectory=${K8S_DIR}/kube-proxy
ExecStart=/opt/k8s/bin/kube-proxy \
--config=/etc/kubernetes/kube-proxy-config.yaml \
--logtostderr=true \
--v=2
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_name in ${ALL_NAMES[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_name%7D%22%0A%20%20%20%20scp%20kube-proxy.service%20root%40#card=math&code=%7Ball_name%7D%22%0A%20%20%20%20scp%20kube-proxy.service%20root%40&id=WPtO9){all_name}:/etc/systemd/system/
done
5) 启动并验证
[root[@k8s-master01 ](/k8s-master01 ) work]# for all_ip in ${ALL_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Ball_ip%7D%22%0A%20%20%20%20ssh%20root%40&id=f7PMr){all_ip} "mkdir -p ![](https://g.yuque.com/gr/latex?%7BK8S_DIR%7D%2Fkube-proxy%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7BK8S_DIR%7D%2Fkube-proxy%22%0A%20%20%20%20ssh%20root%40&id=AJu46){all_ip} "modprobe ip_vs_rr"
ssh root@${all_ip} "systemctl daemon-reload && systemctl enable kube-proxy --now"
done
请参阅ipvs路由规则

[root[@k8s-master01 ](/k8s-master01 ) work]# ipvsadm -ln 
以二进制方式安装kubernetes 1.18.3版本（近60000字）
问题：当我们在开始kube-proxy组装后，通过systemctl查看这个组件的状态时，出现如下错误

Not using `--random-fully` in the MASQUERADE rule for iptables because the local version of iptables does not support it
上面报错是因为我们的iptables版本不支持--random-fully配置（1.6.2版本支持），所以我们需要iptables进行升级操作。

[root[@master01 ](/master01 ) work]# wget [https://www.netfilter.org/projects/iptables/files/iptables-1.6.2.tar.bz2](https://www.netfilter.org/projects/iptables/files/iptables-1.6.2.tar.bz2) --no-check-certificate
[root[@master01 ](/master01 ) work]# for all_name in ${ALL_NAMES[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Ball_name%7D%22%0A%20%20%20%20scp%20iptables-1.6.2.tar.bz2%20root%40#card=math&code=%7Ball_name%7D%22%0A%20%20%20%20scp%20iptables-1.6.2.tar.bz2%20root%40&id=pHXRg){all_name}:/root/
ssh root@![](https://g.yuque.com/gr/latex?%7Ball_name%7D%20%22yum%20-y%20install%20gcc%20make%20libnftnl-devel%20libmnl-devel%20autoconf%20automake%20libtool%20bison%20flex%20libnetfilter_conntrack-devel%20libnetfilter_queue-devel%20libpcap-devel%20bzip2%22%0A%20%20%20%20ssh%20root%40#card=math&code=%7Ball_name%7D%20%22yum%20-y%20install%20gcc%20make%20libnftnl-devel%20libmnl-devel%20autoconf%20automake%20libtool%20bison%20flex%20libnetfilter_conntrack-devel%20libnetfilter_queue-devel%20libpcap-devel%20bzip2%22%0A%20%20%20%20ssh%20root%40&id=ulrLK){all_name} "export LC_ALL=C && tar -xf iptables-1.6.2.tar.bz2 && cd iptables-1.6.2 && ./autogen.sh && ./configure && make && make install"
ssh root@![](https://g.yuque.com/gr/latex?%7Ball_name%7D%20%22systemctl%20daemon-reload%20%26%26%20systemctl%20restart%20kubelet%20%26%26%20systemctl%20restart%20kube-proxy%22%0A%20%20done%0A6.%E5%AE%89%E8%A3%85coredns%E6%8F%92%E4%BB%B6%0A1%EF%BC%89%E4%BF%AE%E6%94%B9coredns%E9%85%8D%E7%BD%AE%0A%5Broot%40k8s-master01%20~%5D%23%20cd%20%2Fopt%2Fk8s%2Fwork%2Fkubernetes%2Fcluster%2Faddons%2Fdns%2Fcoredns%0A%5Broot%40k8s-master01%20coredns%5D%23%20cp%20coredns.yaml.base%20coredns.yaml%0A%5Broot%40k8s-master01%20coredns%5D%23%20sed%20-i%20-e%20%22s%2F__PILLAR__DNS__DOMAIN__%2F#card=math&code=%7Ball_name%7D%20%22systemctl%20daemon-reload%20%26%26%20systemctl%20restart%20kubelet%20%26%26%20systemctl%20restart%20kube-proxy%22%0A%20%20done%0A6.%E5%AE%89%E8%A3%85coredns%E6%8F%92%E4%BB%B6%0A1%EF%BC%89%E4%BF%AE%E6%94%B9coredns%E9%85%8D%E7%BD%AE%0A%5Broot%40k8s-master01%20~%5D%23%20cd%20%2Fopt%2Fk8s%2Fwork%2Fkubernetes%2Fcluster%2Faddons%2Fdns%2Fcoredns%0A%5Broot%40k8s-master01%20coredns%5D%23%20cp%20coredns.yaml.base%20coredns.yaml%0A%5Broot%40k8s-master01%20coredns%5D%23%20sed%20-i%20-e%20%22s%2F__PILLAR__DNS__DOMAIN__%2F&id=ntsgo){CLUSTER_DNS_DOMAIN}/" -e "s/**PILLAR**DNS**SERVER**/${CLUSTER_DNS_SVC_IP}/" -e "s/**PILLAR**DNS**MEMORY**LIMIT__/200Mi/" coredns.yaml
2）创建coredns并启动
配置调度策略

[root[@k8s-master01 ](/k8s-master01 ) coredns]# kubectl label nodes k8s-master01 node-role.kubernetes.io/master=true 
[root[@k8s-master01 ](/k8s-master01 ) coredns]# kubectl label nodes k8s-master02 node-role.kubernetes.io/master=true 
[root[@k8s-master01 ](/k8s-master01 ) coredns]# vim coredns.yaml 
......
apiVersion: apps/v1
kind: Deployment
......
spec:
replicas: 2 															#  Configure as two copies
......
tolerations:
- key: "node-role.kubernetes.io/master"
operator: "Equal"
value: ""
effect: NoSchedule
nodeSelector:
node-role.kubernetes.io/master: "true"
......
[root[@k8s-master01 ](/k8s-master01 ) coredns]# kubectl create -f coredns.yaml 
以二进制方式安装kubernetes 1.18.3版本（近60000字）

kubectl describe pod Pod-Name -n kube-system 											#  Pod name you need to change to your own
因为上图使用的是k8s官方镜像（国外），可能会出现：

Normal   BackOff    72s (x6 over 3m47s)   kubelet, k8s-master01  Back-off pulling image "k8s.gcr.io/coredns:1.6.5"
Warning  Failed     57s (x7 over 3m47s)   kubelet, k8s-master01  Error: ImagePullBackOff
出现上述问题后，我们可以拉取其他仓库中的图片，拉取后重新标注。
For example: docker pull k8s gcr. io/coredns:1.6.5

We can:
docker pull registry.aliyuncs.com/google_containers/coredns:1.6.5
docker tag registry.aliyuncs.com/google_containers/coredns:1.6.5 k8s.gcr.io/coredns:1.6.5
3) 验证
[root[@k8s-master01 ](/k8s-master01 ) coredns]# kubectl run -it --rm test-dns --image=busybox:1.28.4 sh 
If you don't see a command prompt, try pressing enter.
/ #
/ # nslookup kubernetes
Server:    10.20.0.254
Address 1: 10.20.0.254 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.20.0.1 kubernetes.default.svc.cluster.local
7.安装仪表板
[root[@k8s-master01 ](/k8s-master01 ) coredns]# cd /opt/k8s/work/ 
[root[@k8s-master01 ](/k8s-master01 ) work]# mkdir metrics 
[root[@k8s-master01 ](/k8s-master01 ) work]# cd metrics/ 
[root[@k8s-master01 ](/k8s-master01 ) metrics]# wget [https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml](https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.6/components.yaml)
[root[@k8s-master01 ](/k8s-master01 ) metrics]# vim components.yaml 
......
apiVersion: apps/v1
kind: Deployment
metadata:
name: metrics-server
namespace: kube-system
labels:
k8s-app: metrics-server
spec:
replicas: 2 												#  Number of copies modified
selector:
matchLabels:
k8s-app: metrics-server
template:
metadata:
name: metrics-server
labels:
k8s-app: metrics-server
spec:
hostNetwork: true 										#  Configure host network
serviceAccountName: metrics-server
volumes:
# mount in tmp so we can safely use from-scratch images and/or read-only containers
- name: tmp-dir
emptyDir: {}
containers:
- name: metrics-server
image: registry. aliyuncs. com/google_ containers/metrics-server-amd64:v0. three point six 		#  Modify image name
imagePullPolicy: IfNotPresent
args:
- --cert-dir=/tmp
- --secure-port=4443
- --kubelet-insecure-tls 							#  Newly added
- --kubelet-preferred-address-types=InternalIP,Hostname,InternalDNS,ExternalDNS,ExternalIP 	#  Newly added
......
[root[@k8s-master01 ](/k8s-master01 ) metrics]# kubectl create -f components.yaml 
确认：
以二进制方式安装kubernetes 1.18.3版本（近60000字）

1. 创建证书
[root[@k8s-master01 ](/k8s-master01 ) metrics]# cd /opt/k8s/work/ 
[root[@k8s-master01 ](/k8s-master01 ) work]# mkdir -p /opt/k8s/work/dashboard/certs 
[root[@k8s-master01 ](/k8s-master01 ) work]# openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout tls.key -out tls.crt -subj "/C=CN/ST=ZheJiang/L=HangZhou/O=Xianghy/OU=Xianghy/CN=k8s.odocker.com" 
[root[@k8s-master01 ](/k8s-master01 ) work]# for master_ip in ${MASTER_IPS[@]} 
do
echo ">>> ![](https://g.yuque.com/gr/latex?%7Bmaster_ip%7D%22%0A%20ssh%20root%40#card=math&code=%7Bmaster_ip%7D%22%0A%20ssh%20root%40&id=iJ2M9){master_ip} "mkdir -p /opt/k8s/work/dashboard/certs"
scp tls.* root@${master_ip}:/opt/k8s/work/dashboard/certs/
done
2）修改仪表板配置
手动创建秘密

[root[@master01 ](/master01 ) ~]# kubectl create namespace kubernetes-dashboard 
[root[@master01 ](/master01 ) ~]# kubectl create secret generic kubernetes-dashboard-certs --from-file=/opt/k8s/work/dashboard/certs -n kubernetes-dashboard 
修改dashboard的配置（可以通过这个地址查看dashboard的配置yaml文件：传送门）

## [root[@k8s-master01 ](/k8s-master01 ) work]# cd dashboard/ 
[root[@k8s-master01 ](/k8s-master01 ) dashboard]# vim dashboard.yaml 
apiVersion: v1
kind: ServiceAccount
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard
namespace: kubernetes-dashboard

## kind: Service
apiVersion: v1
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard
namespace: kubernetes-dashboard
spec:
type: NodePort
ports:
- port: 443
targetPort: 8443
nodePort: 30080
selector:
k8s-app: kubernetes-dashboard

## apiVersion: v1
kind: Secret
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard-csrf
namespace: kubernetes-dashboard
type: Opaque
data:
csrf: ""

## apiVersion: v1
kind: Secret
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard-key-holder
namespace: kubernetes-dashboard
type: Opaque

## kind: ConfigMap
apiVersion: v1
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard-settings
namespace: kubernetes-dashboard

kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard
namespace: kubernetes-dashboard
rules:

- apiGroups: [""]
resources: ["secrets"]
resourceNames: ["kubernetes-dashboard-key-holder", "kubernetes-dashboard-certs", "kubernetes-dashboard-csrf"]
verbs: ["get", "update", "delete"]
- apiGroups: [""]
resources: ["configmaps"]
resourceNames: ["kubernetes-dashboard-settings"]
verbs: ["get", "update"]
- apiGroups: [""]
resources: ["services"]
resourceNames: ["heapster", "dashboard-metrics-scraper"]
verbs: ["proxy"]
- apiGroups: [""]
resources: ["services/proxy"]
resourceNames: ["heapster", "http:heapster:", "https:heapster:", "dashboard-metrics-scraper", "http:dashboard-metrics-scraper"]
verbs: ["get"]

---

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard
rules:

# Allow Metrics Scraper to get metrics from the Metrics server

- apiGroups: ["metrics.k8s.io"]
resources: ["pods", "nodes"]
verbs: ["get", "list", "watch"]

---

apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard
namespace: kubernetes-dashboard
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: Role
name: kubernetes-dashboard
subjects:

- kind: ServiceAccount
name: kubernetes-dashboard
namespace: kubernetes-dashboard

---

apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
name: kubernetes-dashboard
roleRef:
apiGroup: rbac.authorization.k8s.io
kind: ClusterRole
name: kubernetes-dashboard
subjects:

- kind: ServiceAccount
name: kubernetes-dashboard
namespace: kubernetes-dashboard

---

## kind: Deployment
apiVersion: apps/v1
metadata:
labels:
k8s-app: kubernetes-dashboard
name: kubernetes-dashboard
namespace: kubernetes-dashboard
spec:
replicas: 1
revisionHistoryLimit: 10
selector:
matchLabels:
k8s-app: kubernetes-dashboard
template:
metadata:
labels:
k8s-app: kubernetes-dashboard
spec:
containers:
- name: kubernetes-dashboard
image: kubernetesui/dashboard:v2.0.0-beta8
imagePullPolicy: IfNotPresent
ports:
- containerPort: 8443
protocol: TCP
args:
- --auto-generate-certificates
- --namespace=kubernetes-dashboard
- --tls-key-file=tls.key
- --tls-cert-file=tls.crt
- --token-ttl=3600
volumeMounts:
- name: kubernetes-dashboard-certs
mountPath: /certs
- mountPath: /tmp
name: tmp-volume
livenessProbe:
httpGet:
scheme: HTTPS
path: /
port: 8443
initialDelaySeconds: 30
timeoutSeconds: 30
securityContext:
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
runAsUser: 1001
runAsGroup: 2001
volumes:
- name: kubernetes-dashboard-certs
secret:
secretName: kubernetes-dashboard-certs
- name: tmp-volume
emptyDir: {}
serviceAccountName: kubernetes-dashboard
nodeSelector:
"beta.kubernetes.io/os": linux
tolerations:
- key: node-role.kubernetes.io/master
effect: NoSchedule

## kind: Service
apiVersion: v1
metadata:
labels:
k8s-app: dashboard-metrics-scraper
name: dashboard-metrics-scraper
namespace: kubernetes-dashboard
spec:
ports:
- port: 8000
targetPort: 8000
selector:
k8s-app: dashboard-metrics-scraper

kind: Deployment
apiVersion: apps/v1
metadata:
labels:
k8s-app: dashboard-metrics-scraper
name: dashboard-metrics-scraper
namespace: kubernetes-dashboard
spec:
replicas: 1
revisionHistoryLimit: 10
selector:
matchLabels:
k8s-app: dashboard-metrics-scraper
template:
metadata:
labels:
k8s-app: dashboard-metrics-scraper
annotations:
seccomp.security.alpha.kubernetes.io/pod: 'runtime/default'
spec:
containers:
- name: dashboard-metrics-scraper
image: kubernetesui/metrics-scraper:v1.0.1
imagePullPolicy: IfNotPresent
ports:
- containerPort: 8000
protocol: TCP
livenessProbe:
httpGet:
scheme: HTTP
path: /
port: 8000
initialDelaySeconds: 30
timeoutSeconds: 30
volumeMounts:
- mountPath: /tmp
name: tmp-volume
securityContext:
allowPrivilegeEscalation: false
readOnlyRootFilesystem: true
runAsUser: 1001
runAsGroup: 2001
serviceAccountName: kubernetes-dashboard
nodeSelector:
"beta.kubernetes.io/os": linux
tolerations:
- key: node-role.kubernetes.io/master
effect: NoSchedule
volumes:
- name: tmp-volume
emptyDir: {}
[root[@k8s-master01 ](/k8s-master01 ) dashboard]# kubectl create -f dashboard.yaml 
创建管理员帐户

[root[@k8s-master01 ](/k8s-master01 ) dashboard]# kubectl create serviceaccount admin-user -n kubernetes-dashboard 
[root[@k8s-master01 ](/k8s-master01 ) dashboard]# kubectl create clusterrolebinding admin-user --clusterrole=cluster-admin --serviceaccount=kubernetes-dashboard:admin-user 
3) 验证
获取登录令牌

[root[@k8s-master01 ](/k8s-master01 ) dashboard]# kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user | awk '{print $1}') 
以二进制方式安装kubernetes 1.18.3版本（近60000字）
访问：[https://192.168.1.1:30080](https://192.168.1.1:30080)
以二进制方式安装kubernetes 1.18.3版本（近60000字）
以二进制方式安装kubernetes 1.18.3版本（近60000字）
至此，我们的kubernetes已经搭建完成。如果安装有问题，可以通过以下推广信息联系博主。

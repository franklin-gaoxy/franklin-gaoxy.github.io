基于Debian 12.2版本
# 获取源码
[Kubernetes官方网站](https://github.com/kubernetes/kubernetes)
## 安装工具
```shell
apt-get install git curl make gcc rsync vim wget -y
```
## 安装go语言环境
[golang官方下载页面](https://go.dev/dl/)
```shell
wget https://go.dev/dl/go1.21.5.linux-amd64.tar.gz
tar xf go1.21.5.linux-amd64.tar.gz -C /opt/
echo 'export PATH=${PATH}:/opt/go/bin/' >>/etc/profile
echo 'export GOPATH="/code/"' >>/etc/profile
source /etc/profile
```
## 拉取源码
```shell
mkdir -p $GOPATH/src/k8s.io
cd $GOPATH/src/k8s.io
git clone https://github.com/kubernetes/kubernetes
cd kubernetes
make
```
加入环境变量
```shell
echo 'export PATH=${PATH}:${GOPATH}/src/k8s.io/kubernetes/_output/bin/' >>/etc/profile
source /etc/profile
```
# 准备证书
## 安装工具
```shell
mkdir -p /opt/k8s/cert /opt/k8s/bin
curl -L https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -o /opt/k8s/bin/cfssl
curl -L https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -o /opt/k8s/bin/cfssljson
curl -L https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -o /opt/k8s/bin/cfssl-certinfo
chmod +x /opt/k8s/bin/*
```
## 生成证书
```shell
mkdir -p /opt/k8s/work
cd /opt/k8s/work/
```
生成根证书配置文件
```shell
cat > ca-config.json << EOF 
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
]}}}}
EOF
```
> signing：表示当前证书可用于签署其他证书
server auth：表示客户端可以使用这个CA来验证服务器提供的证书
client auth：表示服务器可以使用这个CA来验证客户端提供的证书
"expiry": "876000h"：表示当前证书有效期为100年


创建根证书签名请求文件
```shell
cat > ca-csr.json << EOF 
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
"expiry": "876000h"}}
EOF
```
> cn:kube apiserver 会将此字段作为请求的用户名,让浏览器验证网站是否合法.
C:国家
> ST:州,省
> L：地区,城市
> O:机构名称
> OU:机构名称、公司部门.


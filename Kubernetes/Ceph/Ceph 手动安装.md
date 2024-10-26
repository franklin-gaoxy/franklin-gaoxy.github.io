# ceph基础知识
首先,一个ceph集群由以下几部分组成:

1. monitor 监视器:集群中最少需要一个monitor节点.但是最好有多个提供高可用,他负责监视集群节点状态,节点管理和元数据维护.
2. OSD 对象存储器: 每个存储节点都要运行OSD,负责存储和管理对象数据,处理数据的平衡,复制,恢复等操作.
3. MDS 元数据服务器: 只在使用分布式存储时需要,管理处理cephFS的元数据,确保文件系统的一致性.
# 开始安装
## 基础操作
```shell
# 修改主机名
hostnamectl set-hostname monitor
hostnamectl set-hostname osd1
hostnamectl set-hostname osd2
```
添加对应的解析
```shell
echo '10.0.0.60 monitor
10.0.0.61 osd1
10.0.0.62 osd2'>>/etc/hosts
```
节点免密
```shell
ssh-keygen
ssh-copy-id osd1
....
scp /root/.ssh/ osd1:/root/
....
```
## 安装monitor
```shell
curl --remote-name --location https://github.com/ceph/ceph/raw/quincy/src/cephadm/cephadm
```
```shell
chmod +x cephadm
```
配置存储库
```shell
apt-get install gnupg software-properties-common -y
wget -q -O- 'https://download.ceph.com/keys/release.asc' | sudo apt-key add -
sudo apt-add-repository 'deb https://mirrors.tuna.tsinghua.edu.cn/ceph/debian-octopus/ buster main'
sudo apt update
```

安装
```shell
./cephadm install ceph-common
```
```shell
apt-get update && sudo apt-get install ceph ceph-mds
```
# 配置monitor启动
```shell
echo "fsid = `uuidgen`" > /etc/ceph/ceph.conf
```
添加主机到列表
```shell
echo "mon_initial_members = ceph01" >>/etc/ceph/ceph.conf
echo "mon_host = 10.0.0.55" >>/etc/ceph/ceph.conf
```
创建密钥并生成监视器密钥
```shell
ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'
```
创建管理员密钥并创建用户 client.admin
```shell
ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
```
引导osd密钥环
```shell
ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'
```
添加生成的密钥到ceph.client.admin.keyring
```shell
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
```
更改文件的所有者
```shell
chown ceph:ceph /tmp/ceph.mon.keyring
```
使用主机名 主机IP和FSID生成监控映射
```shell
monmaptool --create --add {hostname} {ip-address} --fsid {uuid} /tmp/monmap
# 示例
monmaptool --create --add ceph01 10.0.0.55 --fsid d256a802-6eb6-4d61-9d2f-547571aad9d3 /tmp/monmap
```
> FSID就是前面加入配置的那个密钥

在监视器主机创建数据目录
```shell
mkdir /var/lib/ceph/mon/{cluster-name}-{hostname}
```
> 此处创建的集群名字很重要.比如使用了ceph-cm,那么接下来的下一条命令,直接忽略集群名称,参数-i cm.
> 而在启动时依然需要用到. systemctl start ceph-mon@cm

使用监视器映射和密钥环填充监视器守护程序
```shell
sudo -u ceph ceph-mon --mkfs -i ceph01 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
```
> 需要注意配置文件:
> [global]
> fsid = d256a802-6eb6-4d61-9d2f-547571aad9d3
> mon_initial_members = ceph01
> mon_host = 10.0.0.55
> 而ceph目录权限也完全正确
> chown -R ceph:ceph /var/lib/ceph

一份示例的配置
```shell
[global]
fsid = a7f64266-0894-4f1e-a635-d0aeaca0e993
mon_initial_members = mon-node1
mon_host = 192.168.0.1
public_network = 192.168.0.0/24
auth_cluster_required = cephx
auth_service_required = cephx
auth_client_required = cephx
#设置默认存储池（pool）的副本数量。这个参数决定了每个对象在集群中应有的副本数量，设为 3 表示每个对象将在集群中保留三个副本
osd_pool_default_size = 3
#设置默认存储池的最小副本数量。这个参数表示在集群中允许的最小副本数量，设为 2 表示即使集群中只剩下两个 OSD 时，存储池仍然保持可用状态
osd_pool_default_min_size = 2
# 置默认存储池的 PG（Placement Group）数量。PG 是 Ceph 用于数据分布和负载均衡的基本单元。这个参数指定存储池所使用的 PG 的数量，设为 333 表示该存储池将使用 333 个 PG。
osd_pool_default_pg_num = 333
# 设置 CRUSH 算法在选择叶子节点时的类型。CRUSH 是 Ceph 使用的数据分布算法。这个参数指定了在 CRUSH 计算中如何选择叶子节点，设为 1 表示使用均衡算法来选择叶子节点。
osd_crush_chooseleaf_type = 1
```
启动
```shell
systemctl start ceph-mon@ceph01
```
检查是否正在运行
```shell
ceph -s
```
# 安装OSD
## 创建OSD
从monitor节点复制key文件到osd节点
```shell
scp -3 /var/lib/ceph/bootstrap-osd/ceph.keyring root@osd1:/var/lib/ceph/bootstrap-osd/ceph.keyring
scp -3 /var/lib/ceph/bootstrap-osd/ceph.keyring root@osd2:/var/lib/ceph/bootstrap-osd/ceph.keyring
```
复制配置
```shell
scp /etc/ceph/ceph.conf osd1:/etc/ceph/
scp /etc/ceph/ceph.conf osd2:/etc/ceph/
```
ceph创建卷
```shell
sudo ceph-volume lvm create --data /dev/sdb
```
> 磁盘必须是干净的,没有被使用过的新挂载的磁盘.
> 如果使用过可以使用 vgremove pvremove 删除逻辑分区,使用fdisk 输入d 删除磁盘信息.
> 这一步执行完成以后,在monitor节点执行ceph -s 可以看到osd 节点增加了

激活
```shell
# 查看 ID 和FSID
sudo ceph-volume lvm list
```
然后运行激活命令,示例:
```shell
sudo ceph-volume lvm activate 0 77b2db7c-78c7-4919-aa98-b2100781ade3
```

# 启动和停止集群
现在osd节点停止服务(结尾数字为当前节点的ID)
```shell
systemctl stop ceph-osd@0
systemctl stop ceph-osd@1
```
停止mon
```shell
systemctl stop ceph-mon@monitor
```
# MDS
> mds是可选安装组件.并非必须安装组件.

## 来自于博客
[https://zhuanlan.zhihu.com/p/439075869](https://zhuanlan.zhihu.com/p/439075869)
创建数据目录
```shell
mkdir -p /var/lib/ceph/mds/ceph-{hostname}
```
创建mds用户
```shell
ceph auth get-or-create mds.{hostname} osd "allow rwx" mds "allow" mon "allow profile mds"
```
获取密钥并导入
```shell
ceph auth get mds.{hostname} | tee /var/lib/ceph/mds/ceph-{hostname}/keyring
```
启动
```shell
systemctl restart ceph-mds@{hostname} & systemctl enable ceph-mds@{hostname}
```
## 来自于官方
[https://docs.ceph.com/en/latest/install/manual-deployment/](https://docs.ceph.com/en/latest/install/manual-deployment/)
创建mds的数据目录
```shell
mkdir -p /var/lib/ceph/mds/{cluster-name}-{id}
```
创建密钥环
```shell
ceph-authtool --create-keyring /var/lib/ceph/mds/{cluster-name}-{id}/keyring --gen-key -n mds.{id}
```
导入密钥环
```shell
ceph auth add mds.{id} osd "allow rwx" mds "allow *" mon "allow profile mds" -i /var/lib/ceph/mds/{cluster}-{id}/keyring
```
添加到ceph.conf配置
```shell
[mds.{id}]
host = {id} 
```
启动守护程序
```shell
ceph-mds --cluster {cluster-name} -i {id} -m {mon-hostname}:{mon-port} [-f]
```
使用ceph.conf启动
```shell
service ceph start 
```

如果遇到错误查看密钥
```shell
ceph auth get mds.{id}
```

[创建文件系统](https://docs.ceph.com/en/latest/cephfs/createfs/)
# MGR
生成密钥
```shell
ceph auth get-or-create mgr.{hostname} mon 'allow *' osd 'allow *'
```
创建数据目录
```shell
mkdir /var/lib/ceph/mgr/ceph-{hostname}/
```
保存密钥文件
```shell
ceph auth get mgr.{hostname} -o /var/lib/ceph/mgr/ceph-{hostname}/keyring
```
启动
```shell
ceph-mgr -i {hostname}
```
# dashbord
安装依赖
```shell
apt-get install ceph-mgr-dashboard -y
```
ceph.conf的[global]添加配置
```shell
mgr_initial_modules = dashboard
```
启用
```shell
ceph mgr module enable dashboard
```
生成证书
```shell
ceph dashboard create-self-signed-cert
```
创建管理员
```shell
echo '1qaz@WSX' >pass.txt
ceph dashboard set-login-credentials -i pass.txt gao
```
> -i 指定文件 gao 用户名

启动
```shell
ceph mgr services
```
# 创建存储
创建存储池
```shell
ceph osd pool create kubernetes 2
```
创建rbd
```shell
rbd create k8s --pool kubernetes --size 2048
rbd feature disable kubernetes/k8s object-map fast-diff deep-flatten
```
查看admin用户的key
```shell
ceph auth  get-key client.admin
```
列出所有用户
```shell
ceph auth list
```
挂载测试
```shell
mount -t ceph monitor:/ /mnt/ceph -o name=admin,secret=AQBL9bxk5r1YChAA17kiJuqoyAfGDHYMq3K+7g==
```
修改类型为cephfs
```shell
ceph osd pool application enable kubernetes cephfs
```
```shell
ceph osd pool application enable <poolname> [cephfs,rbd,rgw]
```
# 对接到k8s
## 成功案例
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cephfs2
spec:
  containers:
  - name: cephfs-rw
    image: docker.io/library/debian:unstable-slim
    command: ["tail"]
    args: ["-f","/etc/hosts"]
    volumeMounts:
    - mountPath: "/mnt/cephfs"
      name: cephfs
  volumes:
  - name: cephfs
    cephfs:
      monitors:
      - monitor:6789
      user: admin
      secretRef:
        name: ceph-secret
```
## 失败案例
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: ceph-secret
  namespace: default
data:
  keyring: |-
    QVFCTDlieGs1cjFZQ2hBQTE3a2lKdXFveUFmR0RIWU1xM0srN2c9PQ==
---
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: ceph-storage
provisioner: ceph.com/cephfs
parameters:
  monitors: monitor:6789
  pool: kubernetes
  adminId: admin
  adminSecretName: ceph-secret
  adminSecretNamespace: default
  userId: admin
  userSecretName: ceph-secret
  fsName: ext4
  readOnly: "false"
---
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ceph-storage
  resources:
    requests:
      storage: 10Mi
---
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: cephfs-provisioner
  namespace: default
rules:
  - apiGroups: [""]
    resources: ["persistentvolumes"]
    verbs: ["get", "list", "watch", "create", "delete"]
  - apiGroups: [""]
    resources: ["persistentvolumeclaims"]
    verbs: ["get", "list", "watch", "update"]
  - apiGroups: ["storage.k8s.io"]
    resources: ["storageclasses"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["create", "update", "patch"]
  - apiGroups: [""]
    resources: ["endpoints"]
    verbs: ["get", "list", "watch", "create", "update", "patch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["create", "get", "delete"]
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
        volumeMounts: 
          - name: volume1
            mountPath: /ceph
      volumes:
        - name: volume1
          persistentVolumeClaim:
            claimName: myclaim
```
## 参考文件
[https://blog.csdn.net/hxpjava1/article/details/80161866](https://blog.csdn.net/hxpjava1/article/details/80161866)


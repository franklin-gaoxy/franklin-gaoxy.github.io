# minio Linux部署

添加主机名和解析

格式化磁盘 必须格式化为xfs类型 必须是单独的磁盘

```shell
apt-get install xfsprogs
```



```shell
hostname -f
mkfs.xfs /dev/sdb
echo "`blkid /dev/sdb |awk '{print $2}'` /mnt/data01 xfs defaults 0 0" >>/etc/fstab
mkdir /mnt/data01
systemctl daemon-reload 
mount -a 

apt-get install sudo wget -y
wget https://dl.min.io/server/minio/release/linux-amd64/archive/minio_20240803043323.0.0_amd64.deb -O minio.deb
sudo dpkg -i minio.deb
```

```shell
echo '
[Unit]
Description=MinIO
Documentation=https://min.io/docs/minio/linux/index.html
Wants=network-online.target
After=network-online.target
AssertFileIsExecutable=/usr/local/bin/minio

[Service]
WorkingDirectory=/usr/local

User=minio-user
Group=minio-user
ProtectProc=invisible

EnvironmentFile=-/etc/default/minio
ExecStartPre=/bin/bash -c "if [ -z \"${MINIO_VOLUMES}\" ]; then echo \"Variable MINIO_VOLUMES not set in /etc/default/minio\"; exit 1; fi"
ExecStart=/usr/local/bin/minio server $MINIO_OPTS $MINIO_VOLUMES

# MinIO RELEASE.2023-05-04T21-44-30Z adds support for Type=notify (https://www.freedesktop.org/software/systemd/man/systemd.service.html#Type=)
# This may improve systemctl setups where other services use `After=minio.server`
# Uncomment the line to enable the functionality
# Type=notify

# Let systemd restart this service always
Restart=always

# Specifies the maximum file descriptor number that can be opened by this process
LimitNOFILE=65536

# Specifies the maximum number of threads this process can create
TasksMax=infinity

# Disable timeout logic and wait until process is stopped
TimeoutStopSec=infinity
SendSIGKILL=no

[Install]
WantedBy=multi-user.target

# Built for ${project.name}-${project.version} (${project.name})
' > /etc/systemd/system/minio.service
```

```shell
groupadd -r minio-user
useradd -M -r -g minio-user minio-user
chown minio-user:minio-user /mnt/data01
```

```shell
echo '# Set the hosts and volumes MinIO uses at startup
# The command uses MinIO expansion notation {x...y} to denote a
# sequential series.
#
# The following example covers four MinIO hosts
# with 4 drives each at the specified hostname and drive locations.
# The command includes the port that each MinIO server listens on
# (default 9000)

# 如果多个不同名称 使用空格分隔
MINIO_VOLUMES="http://minio0{1...3}:9000/mnt/data01/minio"

# Set all MinIO server options
#
# The following explicitly sets the MinIO Console listen address to
# port 9001 on all network interfaces. The default behavior is dynamic
# port selection.

MINIO_OPTS="--console-address :9001"

# Set the root username. This user has unrestricted permissions to
# perform S3 and administrative API operations on any resource in the
# deployment.
#
# Defer to your organizations requirements for superadmin user name.

MINIO_ROOT_USER=minioadmin

# Set the root password
#
# Use a long, random, unique string that meets your organizations
# requirements for passwords.

MINIO_ROOT_PASSWORD=miniopass'>/etc/default/minio
```

```shell
systemctl daemon-reload
systemctl start minio
```



```
admin admin@1024

YnmWN9hfgrMMzovBZv0L
0rEaEMRpoEPpWcOjcZRqrYFUqylw03VB7Twov7lJ
```

access keys:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: minio-storage
provisioner: minio.csi.s3
parameters:
  endpoint: http://10.0.0.31:9000,http://10.0.0.32:9000,http://10.0.0.33:9000
  accessKeyID: YnmWN9hfgrMMzovBZv0L
  secretAccessKey: 0rEaEMRpoEPpWcOjcZRqrYFUqylw03VB7Twov7lJ
  bucket: kubernetes-prod
  region: test
```

---

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: minio-secret
  namespace: default
stringData:
  accessKey: "WW5tV045aGZnck1Nem92Qlp2MEw="
  secretKey: "MHJFYUVNUnBvRVBwV2NPamNaUnFyWUZVcXlsdzAzVkI3VHdvdjdsSg=="
---
```


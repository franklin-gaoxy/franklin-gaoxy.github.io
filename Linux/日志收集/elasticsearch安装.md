# Debian12 elasticsearch 单机安装

下载
```shell
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.11.0-linux-x86_64.tar.gz
```

解压,新建用户
```shell
tar xf elasticsearch-8.11.0-linux-x86_64.tar.gz
mv elasticsearch-8.11.0 /opt/
useradd elasticsearch -m
chown -R elasticsearch. /opt/elasticsearch-8.11.0/
```
切换用户
```shell
su - elasticsearch
bash
cd /opt/elasticsearch-8.11.0/
```

修改配置

```shell
http.port: 9200
cluster.name: elasticsearch
node.name: es1
network.host: 0.0.0.0
cluster.initial_master_nodes: [es1]
discovery.seed_hosts: ["es1"]
xpack.security.enabled: true
xpack.license.self_generated.type: basic
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12
```

因为是开启xpack的,所以需要生成证书

```shell
./bin/elasticsearch-certutil ca
# 回车 回车
./bin/elasticsearch-certutil cert --ca /opt/elasticsearch-8.11.0/elastic-stack-ca.p12
# 回车 回车 回车
mv elastic-certificates.p12 elastic-stack-ca.p12 config/
```

启动

```shell
./bin/elasticsearch -d
```

设置密码
```shell
./bin/elasticsearch-setup-passwords interactive
```
# filebetas

## 下载安装

[下载页面](https://www.elastic.co/cn/downloads/past-releases#filebeat)

```shell
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.11.0-linux-x86_64.tar.gz
tar xf filebeat-8.11.0-linux-x86_64.tar.gz -C /opt/
```

## 配置

[官方配置页面](https://www.elastic.co/guide/en/beats/filebeat/current/filebeat-overview.html)

### 默认配置

```shell
cd /opt/filebeat-8.11.0-linux-x86_64/
egrep -v "^($|#| *#)" filebeat.yml
```

```yaml
# 这是Filebeat的输入配置部分，定义了Filebeat如何获取日志数据。
filebeat.inputs:
# 使用filestream类型输入，这是用于读取日志文件的一种方式，是Filebeat最新推荐的日志文件读取方式，用以替代旧的log输入类型。
- type: filestream
  id: my-filestream-id # 为输入源分配的唯一标识符。
  enabled: false # 默认是禁用的
  paths: # 指定Filebeat需要监视的文件路径
    - /var/log/*.log # 监视/var/log目录下所有以.log结尾的文件
filebeat.config.modules: # 指定Filebeat模块的配置文件位置
  # 具体的配置文件路径，${path.config}是Filebeat安装目录下的config目录的变量引用
  path: ${path.config}/modules.d/*.yml
  # 是否启用动态重新加载模块配置文件的功能,不启用
  reload.enabled: false 
setup.template.settings:
  # 定义了Filebeat在Elasticsearch中创建索引模板时的设置
  index.number_of_shards: 1 # 设置每个索引的分片数为1
# 用于配置Filebeat连接Kibana的设置
setup.kibana:
# 定义了Filebeat的输出目标是Elasticsearch
output.elasticsearch:
  hosts: ["localhost:9200"]
# 处理器用于在事件被发送到输出之前对其进行处理或增强
processors:
  - add_host_metadata: # 添加主机元数据到事件中。这里还有一个条件判断，仅当事件未包含forwarded标签时才添加元数据。
      when.not.contains.tags: forwarded
  - add_cloud_metadata: ~ # 尝试添加云提供商的元数据
  - add_docker_metadata: ~ # 添加Docker容器的元数据
  - add_kubernetes_metadata: ~ # 添加Kubernetes的元数据
```

备份现有文件

```shell
cp filebeat.yml{,-bak}
cat >filebeat.yml<<EOF
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
    - /var/log/nginx/error.log
output.logstash:
  hosts: ["192.168.137.200:5044"]
EOF
```

### 增加tag和fields

```yaml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/nginx/access.log
    - /var/log/nginx/error.log
  fields:
    server_name: "nginx"
    environment: "test"
  tags: ["nginx01"]
output.logstash:
  hosts: ["192.168.137.200:5044"]
```

> fields和tag主要用于多个filebeta对接到同一个logstash的时候,区分两个机器的日志使用

## 启动

```shell
./filebeta -e -c filebeta.yml
# -e 输出日志到控制台
# -c 指定配置文件
```

### 简单的启停脚本

```shell
cat >start.sh<<EOF
#!/bin/bash

kill `ps -ef |grep "filebea[t]"|awk '{print $2}'`
nohup ./filebeat -e -c filebeat.yml &
EOF
chmod +x start.sh
```
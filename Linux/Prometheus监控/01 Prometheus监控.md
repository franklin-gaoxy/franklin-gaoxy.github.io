# Prometheus安装

| 编辑时间   | 操作内容     |
| ---------- | ------------ |
| 2024/07/22 | 文档首次编写 |
|            |              |

[下载页面](https://prometheus.io/download/)

[官网地址](https://prometheus.io/docs/prometheus/latest/getting_started/)

## 描述

Prometheus本身只是一个数据采集和存储的服务,他可以采集对应页面的对应数据,并配置一些告警规则,当触发这些告警规则的时候,可以发送到指定的地址(如alertmanager),也可以发送到其他(如自己编写的服务),同时还支持多种语言的client(导入SDK后可以快速监听端口提供对应的参数给Prometheus)

## 下载安装

```shell
prom_package_name='prometheus-2.53.1.linux-amd64.tar.gz'
wget https://github.com/prometheus/prometheus/releases/download/v2.53.1/${prom_package_name}
```

```shell
prom_install_dir='/opt/prometheus'
mkdir -p ${prom_install_dir}
tar xf ${prom_package_name} -C ${prom_install_dir}
```

## 启动

进入解压后的目录下面,执行:

```shell
./prometheus
```

即可.

> Prometheus默认从当前目录下读取配置文件,默认使用的prometheus.yml文件
>
> 也可以通过参数 --config.file=./prometheus.yml 来指定配置

# 监控linux主机

## 安装node_export

[node_export下载页面](https://prometheus.io/download/#node_exporter)

```shell
prom_install_dir='/opt/prometheus'
wget https://github.com/prometheus/node_exporter/releases/download/v1.8.2/node_exporter-1.8.2.linux-amd64.tar.gz
tar xf node_exporter-1.8.2.linux-amd64.tar.gz -C ${prom_install_dir}
```

接下来进入目录启动:

```shell
cd ${prom_install_dir}/node_exporter-1.8.2.linux-amd64/
nohup ./node_exporter >node_export.log &
```

> 它默认监听9100端口,接下来请求 http://192.168.137.100:9100/metrics 可以看到各项指标
>
> **这里的指标都是临时的,或者说主机当前的,node_export本身没有任何存储功能!**

接下来修改Prometheus的配置

## 配置prometheus

进入Prometheus的安装目录,编辑`prometheus.yml`文件,在下面添加:

```yaml
  - job_name: "local node" # 可以随意定义一个名称 最好和主机名一致 便于区分
    static_configs:
      - targets: ['localhost:9100'] # 这里是一个列表 可以填写多个地址作为一组
```

整个配置文件:

```yaml
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
alerting:
  alertmanagers:
    - static_configs:
        - targets:
rule_files:
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "local node"
    static_configs:
      - targets: ['localhost:9100']
```

为了方便快速启停,可以配置一个脚本:

```shell
#!/bin/bash

PID=`ps -ef|grep '[p]rometheus'|awk '{print $2}'`
kill -9 ${PID}
nohup ./prometheus >prom.log &
echo "End execution, enter any key."
```



## 页面检查

接下来回到页面 http://192.168.137.100:9090/graph 输入`node_cpu_seconds_total` 这将读取到很多CPU相关的参数,其中"{}"中的内容为标签,你能看到带有'local node'的字样,Prometheus SQL可以支持根据这些过滤,如:`node_cpu_seconds_total{job="local node"}`

在 `Status` -> `Targets`页面下面,可以看到有关`local node`这个组的机器监控相关信息,他会显示`UP`表示正常



## 不同的主机添加不同组

配置修改

```yaml
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
alerting:
  alertmanagers:
    - static_configs:
        - targets:
rule_files:
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "local node"
    static_configs:
      - targets: ['localhost:9100']
        labels:
          group: 'test'
      - targets: ["10.0.0.100:9000","10.0.0.101:9000"]
        labels:
          group: 'prod'
```

> 这样将会具备两个不同的组 prod 和 test
>
> labels:下面的key和value都是可以自由定义的
>
> prod组的主机配置为演示使用 页面会显示异常
>
> 蓝色为 test 红色为 prod

![1721639203429](picture\01 Prometheus监控\1721639203429.png)

## 添加到systemd管理

### prometheus

```shell
cat >/etc/systemd/system/prometheus.service<<EOF
[Unit]
Description=prometheus monitor Service
After=network.target

[Service]
Environment="InstallDir=/opt/prometheus/prometheus-2.53.1.linux-amd64/" "VAR2=value2"
ExecStart=/opt/prometheus/prometheus-2.53.1.linux-amd64/prometheus --config.file /opt/prometheus/prometheus-2.53.1.linux-amd64/prometheus.yml
ExecStop=kill `ps -ef|grep "[p]rometheus"|awk '{print $2}'`
Restart=always
User=root
Group=root
WorkingDirectory=/opt/prometheus/prometheus-2.53.1.linux-amd64/

[Install]
WantedBy=multi-user.target
EOF
```

```shell
systemctl daemon-reload
```

```
systemctl start prometheus.service
```

### node_export

```shell
cat >/etc/systemd/system/node_exporter.service<<EOF
[Unit]
Description=prometheus node monitor Service
After=network.target

[Service]
ExecStart=/opt/prometheus/node_exporter-1.8.2.linux-amd64/node_exporter
ExecStop=kill `ps -ef|grep "[n]ode_exporter"|awk '{print $2}'`
Restart=always
User=root
Group=root
Environment="VAR1=value1" "VAR2=value2"

[Install]
WantedBy=multi-user.target
EOF
```

```shell
systemctl daemon-reload
```

```shell
systemctl start node_export.service
```

## 其他启动参数

`--storage.tsdb.path`: Prometheus写入数据的位置

`--storage.tsdb.retention.time`:数据在存储中保留多长时间

`--storage.tsdb.retention.size`:要保留的最大字节数,也可以写`512MB`

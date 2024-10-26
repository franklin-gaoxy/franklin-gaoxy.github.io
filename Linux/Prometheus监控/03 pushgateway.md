# PushGateway

pushgateway 一个鸡肋的组件

## 安装

```shell
wget https://github.com/prometheus/pushgateway/releases/download/v1.9.0/pushgateway-1.9.0.linux-amd64.tar.gz
tar xf pushgateway-1.9.0.linux-amd64.tar.gz
cd pushgateway-1.9.0.linux-amd64/
# 启动
./pushgateway
```

## 介绍

访问9091端口来访问pushgateway,这可以查看到他的相关指标,如果要查看pushgateway提供给Prometheus的数据,可以访问 http://192.168.137.100:9091/metrics

之所以说他鸡肋,是因为Prometheus实际上是直接抓取对应页面的 /metrics页面下的数据,这个页面给他展示了一些数据如:

```
# HELP go_goroutines Number of goroutines that currently exist.
# TYPE go_goroutines gauge
go_goroutines 12
# HELP go_info Information about the Go environment.
# TYPE go_info gauge
go_info{version="go1.22.4"} 1
# HELP go_memstats_alloc_bytes Number of bytes allocated and still in use.
# TYPE go_memstats_alloc_bytes gauge
go_memstats_alloc_bytes 2.73004e+06
# HELP go_memstats_alloc_bytes_total Total number of bytes allocated, even if freed.
# TYPE go_memstats_alloc_bytes_total counter
go_memstats_alloc_bytes_total 6.126472e+06
# HELP go_memstats_buck_hash_sys_bytes Number of bytes used by the profiling bucket hash table.
# TYPE go_memstats_buck_hash_sys_bytes gauge
go_memstats_buck_hash_sys_bytes 1.452056e+06
```

格式解释:

```
# HELP <metric_name> <help_text> 名称和描述
# TYPE <metric_name> <type> 名称和指标类型 常见类型包括 counter(计数,只能增加或者清零) gauge(仪表盘) histogram(直方图)和 summary(摘要) 常用数字就用gauge histogram和summary也可以表示数字
<metric_name>{<label1>="<value1>", ...} key 指标行 {}内容为组信息或者其他参数 最后的才是值
```



哪怕你自己启动一个服务监听端口,提供这个页面和复合标准的数据,那么完全可以不需要pushgateway,而且pushgateway还面临单点问题

## 使用python推送数据

```shell
pip install prometheus_client
```

```python
from prometheus_client import CollectorRegistry, Gauge, push_to_gateway
import time

# 创建一个注册表
registry = CollectorRegistry()

# 创建一个 Gauge 类型的指标
g = Gauge('job_last_success', 'Last time a job successfully finished', registry=registry)

# 设置 Gauge 的值为当前时间
g.set_to_current_time()
gatewayPath = 'http://192.168.137.100:9091/'
# 将指标推送到 Pushgateway grouping_key:添加组信息
push_to_gateway(gatewayPath, job='batch_job', registry=registry, grouping_key={'instance': 'instance1'})

print("Metrics pushed to Pushgateway")
```


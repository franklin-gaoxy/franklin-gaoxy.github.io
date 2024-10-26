# logstash

## 下载和安装

## 配置

### 对接filebeta 发送到elasticsearch

```shell
cat >config/nginx.conf<<EOF
input {
  beats {
    port => 5044
  }
}

filter {
  # 在这里添加任何特定的日志处理和过滤
}

output {
  elasticsearch {
    hosts => ["http://192.168.137.200:9200"]
    index => "filebeta-nginx-logs-%{+YYYY.MM.dd}"
    # 用户认证信息（如果需要）
    user => "elastic"
    password => "0nsKfMYbPiPhx--MvQOP"
  }
}
EOF
```

### 直接收集节点数据

```yaml
input {
  file {
    path => ["/var/log/nginx/access.log", "/var/log/nginx/error.log"]
    start_position => "beginning"
  }
}

filter {
  grok {
    match => { "message" => "%{COMBINEDAPACHELOG}" }
  }
  date {
    match => [ "timestamp" , "dd/MMM/yyyy:HH:mm:ss Z" ]
  }
}

output {
  elasticsearch {
    hosts => ["http://192.168.137.200:9200"]
    user => "elastic"
    password => "0nsKfMYbPiPhx--MvQOP"
    index => "nginx-access-%{+YYYY.MM.dd}"
  }
}
```

### 根据不同标签发送到不同的索引

```conf
input {
  beats {
    port => 5044
  }
}

filter {
  # 确保fields.server_name字段存在
  if [fields][server_name] == "log_producer" {
    grok {
      match => { "message" => "\[%{TIMESTAMP_ISO8601:log_timestamp}\] \[%{DATA:thread_info}\] \[%{LOGLEVEL:log_level}\] \[\] %{GREEDYDATA:log_message}" }
    }
  }
}

output {
  if [fields][server_name] == "nginx" {
    elasticsearch {
      hosts => ["http://192.168.137.200:9200"]
      user => "elastic"
      password => "0nsKfMYbPiPhx--MvQOP"
      index => "nginx-%{+YYYY.MM.dd}"
      # 其他Elasticsearch输出配置
    }
  } else if [fields][server_name] == "log_producer" {
    elasticsearch {
      hosts => ["http://192.168.137.200:9200"]
      user => "elastic"
      password => "0nsKfMYbPiPhx--MvQOP"
      index => "log_producer-%{+YYYY.MM.dd}"
      workers => 1
    }
  } else {
    elasticsearch {
      hosts => ["http://192.168.137.200:9200"]
      user => "elastic"
      password => "0nsKfMYbPiPhx--MvQOP"
      index => "other-%{+YYYY.MM.dd}"
    }
  }
}
```

> **output参数解析**
> 
> workers => 1: 指定并行工作线程的数量来发送数据。增加此值可以提高吞吐量，但也会增加资源使用量。
> 
> **grok参数解析:**
> 
> - `%{TIMESTAMP_ISO8601:log_timestamp}`：匹配并提取ISO 8601格式的时间戳，并将其存储在字段`log_timestamp`中。
> - `%{DATA:thread_info}`：使用`DATA`模式（任意文本数据，直到下一个空格或逗号）匹配线程信息，并将其存储在字段`thread_info`中。
> - `%{LOGLEVEL:log_level}`：匹配日志级别（如INFO、ERROR、WARN等），并将其存储在字段`log_level`中。
> - `%{GREEDYDATA:log_message}`：匹配日志消息的其余部分，并将其存储在字段`log_message`中。
> 
> **filter其他参数:**
> 
> 1. **`date`**：解析字段中的日期信息，并使用该日期作为事件的时间戳。这对于将日志文件中的时间字符串转换为Logstash事件的`@timestamp`字段非常有用。
> 
> 2. **`dissect`**：和`grok`相似，`dissect`插件用于从日志消息中提取未结构化的数据。与`grok`相比，`dissect`不使用正则表达式，而是使用分隔符，这使得`dissect`在某些情况下性能更好。
> 
> 3. **`geoip`**：根据IP地址解析地理位置信息。这对于分析日志中的IP地址来源地非常有用，可以用于地图可视化和地理位置分析。
> 
> 4. **`drop`**：根据配置的条件丢弃事件。这对于过滤掉不需要的日志非常有用。
> 
> 5. **`clone`**：克隆事件，可以对克隆出的事件应用不同的处理逻辑。
> 
> 6. **`translate`**：类似于查找表，可以根据事件中的某个字段值查找并添加新的字段。
> 
> 7. **`kv`**：解析键值对格式的数据。这在处理类似`key1=value1 key2=value2`这样格式的日志时非常有用。
> 
> 8. **`ruby`**：运行自定义的Ruby代码，为高级处理提供了极大的灵活性。
> 
> 9. **`json`**：解析JSON格式的字符串，并将其转换为Logstash事件中的字段。
> 
> 10. **`xml`**：解析XML格式数据，并将其转换为Logstash事件中的字段。
> 
> 11. **`csv`**：解析CSV（逗号分隔值）格式的数据到事件字段中。
> 
> 12. **`useragent`**：解析HTTP用户代理字符串，提取浏览器、操作系统、设备等信息。

### 开启持久化

> 启动需要指定该配置文件,参考 指定配置文件和pipeline

```
# 启用持久化队列
queue.type: persisted

# 指定持久化队列的存储路径
path.queue: /var/lib/logstash/queue

# 设置每个队列页面的大小
queue.page_capacity: 250mb

# 设置队列可以存储的最大事件数，设置为0表示无限制
queue.max_events: 0

# 设置队列文件的最大总大小
queue.max_bytes: 10gb
```



## 启动

```shell
bin/logstash -f config/nginx.conf
```

如果涉及其他用户相关文件,直接使用root用户启动或者

```shell
sudo bin/logstash -f config/nginx.conf
```

打开debug模式

```shell
sudo ./bin/logstash -f config/nginx.conf --log.level=debug
```

### 简单的启停脚本

```shell
cat >start.sh<<EOF
#!/bin/bash
#sudo ./bin/logstash -f config/nginx.conf --log.level=debug
ps -ef |grep "[l]ogstash"|awk '{print $2}'|xargs sudo kill
nohup sudo ./bin/logstash -f config/nginx.conf &
EOF
chmod +x start.sh
```

### 指定配置文件和pipeline文件

```shell
bin/logstash -f /etc/logstash/conf.d/logstash-pipeline.conf --path.settings /etc/logstash
```
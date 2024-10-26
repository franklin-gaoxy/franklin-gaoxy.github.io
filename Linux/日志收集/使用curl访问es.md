# 使用curl访问es

> index name: filebeta-nginx-logs-2024.04.30
> es host: 192.168.137.200:9200


## 使用
### 查询所有

> pretty: es格式化json显示

```shell
curl -u "elastic:0nsKfMYbPiPhx--MvQOP" -X GET "http://192.168.137.200:9200/filebeta-nginx-logs-2024.04.30/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match_all": {}
  }
}
'
```

### 根据fields查询
```shell
curl -u "elastic:0nsKfMYbPiPhx--MvQOP" -X GET "http://192.168.137.200:9200/filebeta-nginx-logs-2024.04.30/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "fields.environment": "test"
    }
  }
}
'
```

### 根据tag查询

```shell
curl -u "elastic:0nsKfMYbPiPhx--MvQOP" -X GET "http://192.168.137.200:9200/filebeta-nginx-logs-2024.04.30/_search?pretty" -H 'Content-Type: application/json' -d'
{
  "query": {
    "term": {
      "tags": {
        "value": "nginx02"
      }
    }
  }
}
'
```

### 根据filter的grok分组进行查询

> size=1000 显示1000条记录

```shell
curl -u "elastic:0nsKfMYbPiPhx--MvQOP" -X GET "http://192.168.137.200:9200/log_producer-2024.04.30/_search?pretty&size=10" -H 'Content-Type: application/json' -d'
{
  "query": {
    "match": {
      "thread_info": "Thread-9"
    }
  }
}
'
```

### 查看一个索引的所有字段和类型
```shell
curl -u "elastic:0nsKfMYbPiPhx--MvQOP" -X GET "http://192.168.137.200:9200/log_producer-2024.05.11/_mapping?pretty"
```

### 根据字段精确查找
```shell
curl -u "elastic:0nsKfMYbPiPhx--MvQOP" -X POST "http://192.168.137.200:9200/l
og_producer-2024.05.11/_search?pretty&size=100" -H 'Content-Type: application/json' -d'
{
  "query": {
    "term": {
      "thread_info.keyword": {
        "value": "Thread-9"
      }
    }
  }
}'
```
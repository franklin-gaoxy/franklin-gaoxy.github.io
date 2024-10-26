# tcpdump

输出指定包的数量

```shell
tcpdump -c 100
```

输出详细信息

```shell
tcpdump -vv 
```

指定设备

```shell
tcpdump -i ens33
```

输出网络包的数据

```shell
tcpdump -i ens33 -xx
```

禁止将IP地址和端口号转换为对应的主机名和端口服务名

```shell
tcpdump -n
```

指定源主机

```shell
tcpdump src host 10.0.0.11
```

指定目标主机

```shell
tcpdump dst host 10.0.0.11
```

根据协议过滤

```shell
tcpdump tcp src host 10.0.0.11
```



[TCP使用](https://baijiahao.baidu.com/s?id=1671144485218215170&wfr=spider&for=pc)
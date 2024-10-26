# kubernetes 必须修改参数

```
net.ipv4.ip_forward = 1
```

# kubernetes建议修改参数

```
# 这些参数控制套接字接收和发送缓冲区的大小，可以提高网络性能。
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.core.rmem_default = 262144
net.core.wmem_default = 262144
net.core.optmem_max = 16777216
# 这些参数配置 TCP 套接字的内存使用，可以提高 TCP 连接的吞吐量和稳定性
net.ipv4.tcp_rmem = 4096 87380 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
# 这些参数控制 TCP 连接的 keepalive 行为，有助于检测和清理死连接。
net.ipv4.tcp_keepalive_time = 600
net.ipv4.tcp_keepalive_intvl = 60
net.ipv4.tcp_keepalive_probes = 5
# 这个参数控制系统的 swap 行为。较低的值（如 10）表示尽量避免使用 swap，更依赖物理内存。
vm.swappiness = 10
# 这个参数设置系统可以同时打开的文件描述符的最大数量，有助于处理大量并发连接。
fs.file-max = 1000000
# 这个参数控制进程可以拥有的内存映射区域的最大数量，尤其对于运行 Elasticsearch 等应用非常重要。
vm.max_map_count = 262144
# 这个参数控制 conntrack 表的大小，有助于处理大量的网络连接。
net.netfilter.nf_conntrack_max = 262144
# 这个参数设置 TCP 连接在已建立状态下的超时时间。
net.netfilter.nf_conntrack_tcp_timeout_established = 86400
```

修改方式:
```
vi /etc/sysctl.conf
sudo sysctl -p
```

编辑 /etc/security/limits.conf 文件，添加以下内容：
```
* soft nofile 1000000
* hard nofile 1000000
* soft nproc 1000000
* hard nproc 1000000
```
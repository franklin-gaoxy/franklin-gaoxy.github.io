# kubernetes 重做



## 清理集群

```shell
kubeadm reset --force
```

## 删除相关文件

```shell
rm -rf /etc/cni/net.d/
rm -rf $HOME/.kube/
rm -rf /var/lib/kubelet/*
```

## 清理ipvs和iptables

```shell
ipvsadm --clear
```



```shell
# Flush all rules in the filter table
iptables -F

# Flush all rules in the nat table
iptables -t nat -F

# Flush all rules in the mangle table
iptables -t mangle -F

# Flush all rules in the raw table
iptables -t raw -F

# Flush all rules in the security table
iptables -t security -F

# Delete all custom chains in the filter table
iptables -X

# Delete all custom chains in the nat table
iptables -t nat -X

# Delete all custom chains in the mangle table
iptables -t mangle -X

# Delete all custom chains in the raw table
iptables -t raw -X

# Delete all custom chains in the security table
iptables -t security -X

# Set default policies to ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
```

## 删除残留的网络设备

列出所有的网络设备

```shell
ip link show
```

删除

```shell
ip link del kube-ipvs0
ip link del cilium_net
ip link del cilium_vxlan
```

## 重启节点

> 清理完成以上内容后一定要重启一下节点！

```shell
reboot
```


# create

[Cilium Quick Installation &mdash; Cilium 1.15.5 documentation](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)

> 务必开启内核转发!

内核转发
```
# 临时
sudo sysctl -w net.ipv4.ip_forward=1
# 永久
echo 'net.ipv4.ip_forward = 1' >>/etc/sysctl.conf
sudo sysctl -p
```

```shell
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

```

安装到kubernetes

```shell
cilium install --version 1.15.5
```

helm安装
```
helm repo add cilium https://helm.cilium.io/
helm install cilium cilium/cilium --version 1.15.5  --namespace kube-system
```


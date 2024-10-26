# 

I encountered some problems when installing istio. I wanted to enable the cni function of istio, but it failed during the installation.

My basic environment:

```shell
root@knode1:~# kubectl version 
Client Version: v1.28.13
Kustomize Version: v5.0.4-0.20230601165947-6ce0bf390ce3
Server Version: v1.28.0
root@knode1:~# 
```

The container basic network uses cilium 1.16.1 version. I enabled its hubble function and replaced kube-proxy. The installation command is as follows:

```shell
helm install cilium cilium/cilium --version 1.16.1 \
	--namespace kube-system \
	--set k8sServiceHost=192.168.0.21 \
	--set k8sServicePort=6443 \
	--set kubeProxyReplacement=true \
	--set ipam.operator.clusterPoolIPv4PodCIDRList="10.0.0.0/16" \
	--set ipam.operator.clusterPoolIPv4MaskSize=24 \
	--set ipv4NativeRoutingCIDR="192.168.0.0/24" \
	--set nodePort.enabled=true \
	--set nodePort.enableHealthCheck=false \
	--set hubble.enabled=true \
	--set hubble.ui.enabled=true \
	--set hubble.relay.enabled=true \
	--set hubble.metrics.enableOpenMetrics=true \
	--set hubble.tls.auto.enabled=true \
	--set hubble.tls.auto.method=helm \
	--set hubble.tls.auto.certValidityDuration=10950
```

The problem I encountered when installing istio's cni:

After executing the helm install command, it waits for a long time and then throws an exception:

```shell
root@knode1:~# helm install istio-cni istio/cni -n istio-system --wait
Error: INSTALLATION FAILED: context deadline exceeded
```

The pod status is all running, but the number does not match, and there is no restart record.

```shell
root@knode1:~# kubectl get pod -n istio-system 
NAME                   READY   STATUS    RESTARTS   AGE
istio-cni-node-4mfkc   0/1     Running   0          8m16s
istio-cni-node-x2hk7   0/1     Running   0          8m16s
istio-cni-node-xqdlg   0/1     Running   0          8m16s
```

I intercepted part of the log at the end, but I didn't see any information about the errors level, and it kept repeating the same content.

```shell
2024-09-17T10:04:21.295868Z	info	cni-agent	configuration requires updates, (re)writing CNI config file at "/host/etc/cni/net.d/05-cilium.conflist": istio-cni CNI config removed from CNI config file: /host/etc/cni/net.d/05-cilium.conflist
2024-09-17T10:04:21.305668Z	info	cni-agent	created CNI config /host/etc/cni/net.d/05-cilium.conflist
2024-09-17T10:04:21.305758Z	info	cni-agent	Istio CNI configuration and binaries validated/reinstalled
2024-09-17T10:04:21.312993Z	info	file modified: /host/etc/cni/net.d/.05-cilium.conflist4276606968
2024-09-17T10:04:21.314925Z	info	cni-agent	detected changes to the node-level CNI setup, checking to see if configs or binaries need redeploying
2024-09-17T10:04:21.366487Z	info	cni-agent	Copied istio-cni to /host/opt/cni/bin
2024-09-17T10:04:21.366852Z	info	cni-agent	wrote kubeconfig file /var/run/istio-cni/istio-cni-kubeconfig with: 
apiVersion: v1
clusters:
- cluster:
    certificate-authority: REDACTED
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJSVZGVHYxdjBIRU13RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRBNU1UY3dOVFUzTXpoYUZ3MHpOREE1TVRVd05qQXlNemhhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUN1bzFYWWhwVmcyazM4WnJHU2YrSW5QY2h1V0lIVU1PY3JPakMrb3dsNzBtcFVPYTdMSExzWmcxbmsKUnJ4VTg5T3Vic2p6a1NTeHZORXNUQXppNWk4aGJzZHF6bUxhWFVjeTNYT0tPYklCSFpqWnZETFRiemFQZXpjUApXcXlBbzdGL3N4ZCtrSUhST1kxdTJxMEMzQXpYL3paWW9FaTdRWHdXa1E4T1FNWEE4azZpaUxseElFc0dlU3h4CkxhZFpPVlpXb1BCQlgvVTdGLzRGZ1VyU1dRWGt2YzVhbGN5Q29LdWtkL0ZSdlpNZEJnWUxxK2tYMWdUYnFxeloKRFZPUzdJUE1iYUJJY05STkh1enM5M3Vscko1U0pTNlpMd1BHcjh6dDNOVklydVNVWG01akliWFJRMlZvQlFKYgpoTWJHa2htVlhYZ3Fld1h2cGZaNHlTb0FMd29qQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSMkdKUTNSRXVZUjZkMDNpU1RKR3F4YXVkL29qQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ2I3WWJRWExaNApCQ1AwbVpVQVpCcGdZVFpUUnU5M3ljaFRQYXc3OVRJcnJSTjlmSiswdTYxUGZDREExZGJiZDA4MnExM3VwVFJICjNKc2FoNFhGVDNsNFBaR2NCMmxJaGpxS1hJeE1Hc21ibndrSDNJSEV6d2FiamZMOGJWTzI0OU55RnZwWk1NV0YKcG9SVVhpU3h3T3VtbllYeDlsekVscHZuMVJZM0RMUVV2TUl6N3ExbmVBKzBwUUQyNkZCWG1MT3Y5eUUvdDd5Ywptam5oT3ExeHp2SFdvZ252cjNsblBQVnd2WElweklwVG05WEhRZ0hUWVRrdjNmYUM3bDZTTkRJdjFNUkRyc2dpCjd2b0sraTJaSnNmNjNDWk5uQ2lZN2VnMTRsdW51UzI5R3ErMUw1R01HZCt3bGgvRFduWEp6RldYN1hmMXcxSm4KYkJxMit2dXlwd0xzCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://10.96.0.1:443
  name: local
contexts:
- context:
    cluster: local
    user: istio-cni
  name: istio-cni-context
current-context: istio-cni-context
kind: Config
preferences: {}
users:
- name: istio-cni
  user:
    token: REDACTED

2024-09-17T10:04:21.366935Z	info	cni-agent	configuration requires updates, (re)writing CNI config file at "/host/etc/cni/net.d/05-cilium.conflist": istio-cni CNI config removed from CNI config file: /host/etc/cni/net.d/05-cilium.conflist
2024-09-17T10:04:21.374272Z	info	cni-agent	created CNI config /host/etc/cni/net.d/05-cilium.conflist
2024-09-17T10:04:21.374288Z	info	cni-agent	Istio CNI configuration and binaries validated/reinstalled
2024-09-17T10:04:21.384881Z	info	cni-agent	detected changes to the node-level CNI setup, checking to see if configs or binaries need redeploying
2024-09-17T10:04:21.447969Z	info	cni-agent	Copied istio-cni to /host/opt/cni/bin
2024-09-17T10:04:21.448464Z	info	cni-agent	wrote kubeconfig file /var/run/istio-cni/istio-cni-kubeconfig with: 
apiVersion: v1
clusters:
- cluster:
    certificate-authority: REDACTED
    certificate-authority-data: LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSURCVENDQWUyZ0F3SUJBZ0lJSVZGVHYxdjBIRU13RFFZSktvWklodmNOQVFFTEJRQXdGVEVUTUJFR0ExVUUKQXhNS2EzVmlaWEp1WlhSbGN6QWVGdzB5TkRBNU1UY3dOVFUzTXpoYUZ3MHpOREE1TVRVd05qQXlNemhhTUJVeApFekFSQmdOVkJBTVRDbXQxWW1WeWJtVjBaWE13Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLCkFvSUJBUUN1bzFYWWhwVmcyazM4WnJHU2YrSW5QY2h1V0lIVU1PY3JPakMrb3dsNzBtcFVPYTdMSExzWmcxbmsKUnJ4VTg5T3Vic2p6a1NTeHZORXNUQXppNWk4aGJzZHF6bUxhWFVjeTNYT0tPYklCSFpqWnZETFRiemFQZXpjUApXcXlBbzdGL3N4ZCtrSUhST1kxdTJxMEMzQXpYL3paWW9FaTdRWHdXa1E4T1FNWEE4azZpaUxseElFc0dlU3h4CkxhZFpPVlpXb1BCQlgvVTdGLzRGZ1VyU1dRWGt2YzVhbGN5Q29LdWtkL0ZSdlpNZEJnWUxxK2tYMWdUYnFxeloKRFZPUzdJUE1iYUJJY05STkh1enM5M3Vscko1U0pTNlpMd1BHcjh6dDNOVklydVNVWG01akliWFJRMlZvQlFKYgpoTWJHa2htVlhYZ3Fld1h2cGZaNHlTb0FMd29qQWdNQkFBR2pXVEJYTUE0R0ExVWREd0VCL3dRRUF3SUNwREFQCkJnTlZIUk1CQWY4RUJUQURBUUgvTUIwR0ExVWREZ1FXQkJSMkdKUTNSRXVZUjZkMDNpU1RKR3F4YXVkL29qQVYKQmdOVkhSRUVEakFNZ2dwcmRXSmxjbTVsZEdWek1BMEdDU3FHU0liM0RRRUJDd1VBQTRJQkFRQ2I3WWJRWExaNApCQ1AwbVpVQVpCcGdZVFpUUnU5M3ljaFRQYXc3OVRJcnJSTjlmSiswdTYxUGZDREExZGJiZDA4MnExM3VwVFJICjNKc2FoNFhGVDNsNFBaR2NCMmxJaGpxS1hJeE1Hc21ibndrSDNJSEV6d2FiamZMOGJWTzI0OU55RnZwWk1NV0YKcG9SVVhpU3h3T3VtbllYeDlsekVscHZuMVJZM0RMUVV2TUl6N3ExbmVBKzBwUUQyNkZCWG1MT3Y5eUUvdDd5Ywptam5oT3ExeHp2SFdvZ252cjNsblBQVnd2WElweklwVG05WEhRZ0hUWVRrdjNmYUM3bDZTTkRJdjFNUkRyc2dpCjd2b0sraTJaSnNmNjNDWk5uQ2lZN2VnMTRsdW51UzI5R3ErMUw1R01HZCt3bGgvRFduWEp6RldYN1hmMXcxSm4KYkJxMit2dXlwd0xzCi0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K
    server: https://10.96.0.1:443
  name: local
contexts:
- context:
    cluster: local
    user: istio-cni
  name: istio-cni-context
current-context: istio-cni-context
kind: Config
preferences: {}
users:
- name: istio-cni
  user:
    token: REDACTED

2024-09-17T10:04:21.448590Z	info	cni-agent	configuration requires updates, (re)writing CNI config file at "/host/etc/cni/net.d/05-cilium.conflist": istio-cni CNI config removed from CNI config file: /host/etc/cni/net.d/05-cilium.conflist
2024-09-17T10:04:21.458752Z	info	cni-agent	created CNI config /host/etc/cni/net.d/05-cilium.conflist
2024-09-17T10:04:21.458774Z	info	cni-agent	Istio CNI configuration and binaries validated/reinstalled
2024-09-17T10:04:21.465084Z	info	file modified: /host/etc/cni/net.d/.05-cilium.conflist1896331522
2024-09-17T10:04:21.468913Z	info	cni-agent	detected changes to the node-level CNI setup, checking to see if configs or binaries need redeploying

```

Finally, here are the pod related events:

```shell
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  10m                 default-scheduler  Successfully assigned istio-system/istio-cni-node-xqdlg to knode3
  Normal   Pulled     10m                 kubelet            Container image "docker.io/istio/install-cni:1.23.1" already present on machine
  Normal   Created    10m                 kubelet            Created container install-cni
  Normal   Started    10m                 kubelet            Started container install-cni
  Warning  Unhealthy  14s (x70 over 10m)  kubelet            Readiness probe failed: HTTP probe failed with statuscode: 503
```

Can anyone help me?


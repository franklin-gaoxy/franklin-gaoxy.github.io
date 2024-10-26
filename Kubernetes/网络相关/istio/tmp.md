

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-destination
  namespace: default
spec:
  host: bookinfo.default.svc.cluster.local  # 内部服务的 FQDN 此字段和VirtualService进行绑定 也就是VirtualService的FQDN 且只能是FQDN
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bookinfo
  namespace: default
spec:
  gateways:
  - bookinfo-gateway
  hosts:
  - 192.168.0.220
  http:
  - match:
    - uri:
        prefix: /productpage
      headers:
        version:
          exact: v1  # 如果请求头中带有 version: v1
    route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v1  # 路由到 reviews 的 v1 子集
  - match:
    - uri:
        prefix: /productpage
    - uri:
        prefix: /static
    route:
    - destination:
        host: productpage
        port:
          number: 9080
```



```yaml
apiVersion: networking.istio.io/v1
kind: VirtualService
metadata:
  labels:
    kiali_wizard: traffic_shifting
  name: reviews
  namespace: default
spec:
  hosts:
  - reviews.default.svc.cluster.local
  http:
  - match:
    - headers:
        version:
          exact: v1
    route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v1
  - route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v1
      weight: 0
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v2
      weight: 80
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v3
      weight: 20
```



```yaml
kubectl apply -f - <<EOF
apiVersion: gateway.networking.k8s.io/v1
kind: HTTPRoute
metadata:
  name: reviews
spec:
  parentRefs:
  - kind: Service
    name: reviews
    port: 9080
  rules:
  - matches:
    - headers:
        - name: version
          value: v3
    backendRefs:
    - name: reviews-v3
      port: 9080
  - matches:
    - headers:
        - name: version
          value: v2
    backendRefs:
    - name: reviews-v2
      port: 9080
  - backendRefs:
    - name: reviews-v1
      port: 9080
EOF
```



```yaml
a
```



```yaml
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/platform/kube/bookinfo.yaml
kubectl delete -f https://raw.githubusercontent.com/istio/istio/release-1.23/samples/bookinfo/platform/kube/bookinfo-versions.yaml

```

Gateway+HTTPRoute 可以在集群内暴露服务，创建gateway后执行：

```shell
kubectl annotate gateway bookinfo-gateway networking.istio.io/service-type=ClusterIP --namespace=default
```

可以修改为集群内部IP 否则是ClusterIP类型。

HttpRoute用来定义访问的二级目录，桶过spec.parentRefs.name[]=bookinfo-gateway来绑定gateway。

gateway会自动创建一个地址，如果是对外的会默认使用LoadBalancer，如果是ClusterIP那么则创建一个新的service

```shell
root@knode1:~# kubectl get gateway
NAME               CLASS   ADDRESS                                            PROGRAMMED   AGE
bookinfo-gateway   istio   bookinfo-gateway-istio.default.svc.cluster.local   True         6m38s
```

ADDRESS表示的就是访问这个gateway的地址



### istio的IngressGateway

```
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: hello-gateway
spec:
  selector:
    istio: ingress # use the default IngressGateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "www.vvar.com"
    - "192.168.0.220"

---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend-ingress
spec:
  hosts:
  - "www.vvar.com"
  - "192.168.0.220"
  gateways:
  - hello-gateway
  http:
  - route:
    - destination:
        host: productpage.default.svc.cluster.local
        port:
          number: 9080
EOF
```



```yaml
kubectl apply -f - <<EOF
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: hello-gateway
spec:
  selector:
    istio: ingress # use the default IngressGateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "www.vvar.com"
    - "192.168.0.220"

---
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: frontend-ingress
spec:
  hosts:
  - "www.vvar.com"
  - "192.168.0.220"
  gateways:
  - hello-gateway
  http:
  - route:
    - destination:
        host: productpage.default.svc.cluster.local
        port:
          number: 9080
---
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-destination
  namespace: default
spec:
  host: reviews.default.svc.cluster.local  # 内部服务的 FQDN 此字段和VirtualService进行绑定 也就是VirtualService的FQDN 且只能是FQDN
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
  - name: v3
    labels:
      version: v3
---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bookinfo
  namespace: default
spec:
  hosts:
  - reviews.default.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /productpage
      headers:
        version:
          exact: v1  # 如果请求头中带有 version: v1
    route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v1  # 路由到 reviews 的 v1 子集
  - match:
    - uri:
        prefix: /productpage
    route:
    # 默认路由到v2 v3 各自50%流量
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v2
      weight: 50
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v3
      weight: 50
EOF
```

```
spec:
  gateways:
  - bookinfo-gateway
  hosts:
  - 192.168.0.220
  http:
  - match:
    - uri:
        prefix: /productpage
      headers:
        version:
          exact: v1  # 如果请求头中带有 version: v1
    route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v1  # 路由到 reviews 的 v1 子集
  - match:
    - uri:
        prefix: /productpage
    - uri:
        prefix: /static
    route:
    - destination:
        host: productpage
        port:
          number: 9080
```

```
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: bookinfo
  namespace: default
spec:
  hosts:
  - reviews.default.svc.cluster.local
  http:
  - match:
    - uri:
        prefix: /productpage
      headers:
        version:
          exact: v1  # 如果请求头中带有 version: v1
    route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v1  # 路由到 reviews 的 v1 子集
  - match:
    - uri:
        prefix: /productpage
    route:
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v2
      weight: 50
    - destination:
        host: reviews.default.svc.cluster.local
        subset: v3
      weight: 50

```


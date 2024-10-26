# Kubernetes的QoS

QoS(Quality of Service,服务质量)表示的是一个容器对于资源请求和限制的种类的划分,Kubernetes对于不同的种类在调度和驱逐的时候会采取不同的策略.

每个pod都有一个自己的QoS类(即便没有指定他),QoS总共可以分为三类:

1. Guaranteed
2. Burstable
3. BestEffort

## Guaranteed

### 定义标准

- pod中每个容器都必须指定了资源限制(CPU和内存)和资源请求,同时两者相等.

### pod模板示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed
spec:
  containers:
  - name: guaranteed
    image: nginx
    resources:
      limits:
        memory: "200Mi"
        cpu: "700m"
      requests:
        memory: "200Mi"
        cpu: "700m"
```

查看:

```shell
kubectl get pod guaranteed -o=yaml |grep "qosClass"
```

> 如果一个容器只指定了资源请求而没有指定限制,那么Kubernetes默认会使用请求的值作为限制.
>  
> 同样如果指定了限制而没有指定请求,那么默认使用指定的值作为请求的值.
>  
> 对于指定了任意一种值而没有指定另一种的pod来说,他都属于`guaranteed`.


## Burstable

### 定义标准

- pod不符合Guaranteed的标准,但pod中又有一个容器指定了资源请求或者限制.
- pod的资源请求值小于资源限制数值

### pod模板

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: burstable
spec:
  containers:
  - name: burstable
    image: nginx
    resources:
      limits:
        memory: "200Mi"
      requests:
        memory: "100Mi"
```

```shell
kubectl get pod burstable -o=yaml|grep "qosClass"
```

## BestEffort

### 定义标准

- pod没有指定内存和CPU的资源请求和限制

### pod模板示例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: besteffort
spec:
  containers:
  - name: besteffort
    image: nginx
```

```shell
kubectl get pod besteffort -o=yaml |grep "qosClass"
```

# QoS的作用

当节点资源不足的时候,会触发驱逐策略.

驱逐的时候首先驱逐BestEffort 类型的pod,其次驱逐Burstable类型的pod,最后开始驱逐Guaranteed 类型的pod.对于Guaranteed 只会驱逐那些使用资源超过limits限制的pod.

也就是BestEffort 优先级为0,而Burstable优先级为1,Guaranteed优先级为2.调度和驱逐的时候都会挑选优先级更低的优先驱逐.

调度过程中自然也根据服务的QoS来评判了,如一个机器剩余可用内存只有1GB,而服务requests和limit都设置为了2G,那么在调度的时候这个节点就不符合规则.

但如果一个主机剩余资源满足pod requests的资源,同时又不满足limit的值,那么pod还是有可能会被调度到这个节点.但是当pod使用资源越来越多超过了requests导致节点资源不足,触发释放资源时,也会被优先释放

# CPU set

默认情况下,多个pod是可以使用同一个CPU的计算资源的.这种情况下的CPU会在多个进程之间快速来回切换以达到"并行"的目的.

但是CPU set支持把一个pod绑定到一颗CPU上运行.在Kubernetes中实现只需要设置一个Guaranteed类,然后将requests和limits的CPU**都设置为一个整数**即可.如:

```yaml
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      limits:
        memory: "200Mi"
        cpu: "2"
      requests:
        memory: "200Mi"
        cpu: "2"
```

然后,Kubernetes会为你随机挑选两个CPU进行绑定.


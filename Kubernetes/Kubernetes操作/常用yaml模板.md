## 
# deployment
## 简单的deployment
```yaml
apiVersion: apps/v1
# 使用的资源种类
kind: Deployment
metadata:
  # 创建的deployment资源的名称
  name: nginx-deployment
  labels:
    app: nginx
spec:
  # 指定要创建的pod数量
  replicas: 3
  # 标签选择器 定义如何查找要管理的pod 意为控制带有app=nginx标签的pod的数量或版本等
  selector:
    matchLabels:
      app: nginx
  # pod模板
  template:
    metadata:
      # pod标签
      labels:
        app: nginx
    spec:
      # 容器描述信息
      containers:
      - name: nginx
        image: nginx:1.14.2
        ports:
        - containerPort: 80
```

## 带有emptydir的Deployment
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pd
spec:
  containers:
  - image: nginx
    name: test-container
    # 声明要将那个卷 挂载到容器的那个位置
    volumeMounts:
    - mountPath: /cache
      # name字段为判断声明的存储类型的那一个 此字段要和spec.volumes.name相对应
      name: cache-volume
  # 声明pod要使用的存储的名称及类型
  volumes:
  - name: cache-volume
    emptyDir: {}
```

## 使用pvc
```yaml
kind: Pod
apiVersion: v1
metadata:
  name: write-pod
spec:
  containers:
  - name: write-pod
    image: busybox
    command:
      - "/bin/sh"
    args:
      - "-c"
      - "touch /mnt/SUCCESS && exit 0 || exit 1"
    volumeMounts:
      - name: nfs-pvc
        mountPath: "/mnt"
  restartPolicy: "Never"
  volumes:
    - name: nfs-pvc
      persistentVolumeClaim:
        claimName: myclaim
---
# 创建PVC
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: myclaim
spec:
  accessModes:
    - ReadWriteOnce
  # 存储类名称
  storageClassName: nfs-provisioner
  resources:
    requests:
      # 申请空间大小
      storage: 1Mi
```
## 复杂的deployment
# 配置
## configMap
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: game-demo
data:
  # 类属性键；每一个键都映射到一个简单的值
  player_initial_lives: "3"
  ui_properties_file_name: "user-interface.properties"
  # 类文件键
  game.properties: |
    enemy.types=aliens,monsters
    player.maximum-lives=5    
  user-interface.properties: |
    color.good=purple
    color.bad=yellow
    allow.textmode=true  
```
### 根据configmap创建pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-demo-pod
spec:
  containers:
    - name: demo
      image: alpine
      command: ["sleep", "3600"]
      env:
        # 定义环境变量 值从对应的configMap中获取
        - name: PLAYER_INITIAL_LIVES # 请注意这里和 ConfigMap 中的键名是不一样的
          valueFrom:
            configMapKeyRef:
              name: game-demo           # 这个值来自 ConfigMap
              key: player_initial_lives # 需要取值的键
        - name: UI_PROPERTIES_FILE_NAME
          valueFrom:
            configMapKeyRef:
              name: game-demo
              key: ui_properties_file_name
      volumeMounts:
      # 配置文件挂载的目录
      - name: config
        mountPath: "/config"
        readOnly: true
  volumes:
    # 你可以在 Pod 级别设置卷，然后将其挂载到 Pod 内的容器中
    - name: config
      configMap:
        # 提供你想要挂载的 ConfigMap 的名字
        name: game-demo
        # 来自 ConfigMap 的一组键，将被创建为文件
        items:
        - key: "game.properties"
          # 配置文件挂载名称
          path: "game"
        - key: "user-interface.properties"
          path: "user-interface.properties"
```

## Secret
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: secret-sa-sample
  annotations:
    # 此字段设置为某个已有服务的账号名称
    kubernetes.io/service-account.name: "sa-name"
type: kubernetes.io/service-account-token
data:
  # 你可以像 Opaque Secret 一样在这里添加额外的键/值偶对
  extra: YmFyCg==
```
### dockerconfigjson
```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: secret-dockercfg
type: kubernetes.io/dockercfg
data:
  # .dockerconfigjson为固定键 内容可通过 cat ~/.docker/config.json|base64 来查看
  .dockerconfigjson: |
    ewoJImF1dGhzIjogewoJCSJodWIuc21hcnRvbmUubmV0LmNuIjogewoJCQkiYXV0aCI6ICJZV1J0YVc0NlUybE9iMEF4TWpNdVEyOU4iCgkJfQoJfQp9
EOF
```
### 使用Secret的pod
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mypod
    image: redis
    volumeMounts:
    - name: foo
      # 挂载路径
      mountPath: "/etc/foo"
      readOnly: true
  volumes:
  # 挂载卷来自
  - name: foo
    secret:
      # Secret资源名称
      secretName: config
      # 指定文件权限.默认情况下为0644 256为0400权限
      defaultMode: 256
```
### 使用Secret的pod(子路径方式)
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: mypod
spec:
  containers:
  - name: mypod
    image: redis
    volumeMounts:
    - name: foo
      # 挂载路径
      mountPath: "/etc/foo"
      readOnly: true
  volumes:
  # 挂载卷来自
  - name: foo
    secret:
      # Secret资源名称
      secretName: config
      items:
      - key: game.properties
        path: my-group/my-username
        # 制定权限 为不同的文件指定不同的权限 511为0777
        mode: 511
```

# StatefuleSet
## 基础的statefulset
```yaml
# 创建一个service类型资源 clusterIP: None为Headless(无头服务)类型.
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  ports:
  - port: 80
    name: web
  clusterIP: None
  selector:
    app: nginx
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  selector:
    matchLabels:
      app: nginx # has to match .spec.template.metadata.labels
  serviceName: "nginx"
  replicas: 3 # by default is 1
  template:
    metadata:
      labels:
        app: nginx # has to match .spec.selector.matchLabels
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80
          name: web
        volumeMounts:
        - name: www
          mountPath: /usr/share/nginx/html
  # 挂载卷模板
  volumeClaimTemplates:
  - metadata:
      name: www
    spec:
      # 多主机读写
      accessModes: [ "ReadWriteMany" ]
      # 使用的存储类名称 可通过 kubectl get storageclas查看,也就刚才创建的.
      storageClassName: "nfs-provisioner"
      resources:
        requests:
          storage: 100Mi
```

# DaemonSet
## 基础的DaemonSet
```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluentd-elasticsearch
  labels:
    k8s-app: fluentd-logging
spec:
  # 标签选择器 指定要控制的pod具有什么标签
  selector:
    matchLabels:
      name: fluentd-elasticsearch
  # pod模板
  template:
    metadata:
      labels:
        # pod标签
        name: fluentd-elasticsearch
    spec:
      tolerations:
      # 此字段为主节点同样要运行一个pod
      - key: node-role.kubernetes.io/master
        operator: Exists
        effect: NoSchedule
      containers:
        # 容器名称和使用镜像
      - name: fluentd-elasticsearch
        image: fluentd:v1.14.0-debian-1.0
        # 将存储卷挂载到容器
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
      terminationGracePeriodSeconds: 30
      # 声明此pod要使用的存储
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
```

# Service
## 基础的Service
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  labels:
    run: my-nginx
spec:
  ports:
    # service端口
  - port: 80
    # 协议
    protocol: TCP
  # 要绑定的pod具有的标签
  selector:
    run: my-nginx
```
## NodePort类型
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: default
  labels:
    run: my-nginx
spec:
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      # 映射到的节点端口
      nodePort: 30000
  selector:
    run: my-nginx
  # 类型 改为NodePort
  type: NodePort
```

## LoadBalancer类型
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: default
  labels:
    run: my-nginx
spec:
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
  selector:
    run: my-nginx
  # 类型 改为LoadBalancer
  type: LoadBalancer
```

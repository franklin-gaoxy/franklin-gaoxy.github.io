```yaml
kubectl apply -f -<<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    k8s-app: jenkins
  name: jenkins-admin
  namespace: devops
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: jenkins-rbac
  namespace: devops
rules:
  - apiGroups: ["extensions", "apps"]
    resources: ["deployments"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["services"]
    verbs: ["create", "delete", "get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["pods"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["pods/exec"]
    verbs: ["create","delete","get","list","patch","update","watch"]
  - apiGroups: [""]
    resources: ["pods/log"]
    verbs: ["get","list","watch"]
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["get"]
  - apiGroups: [""]
    resources: ["events"]
    verbs: ["watch"] 
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: jenkins-admin
  namespace: devops
  labels:
    k8s-app: jenkins
subjects:
  - kind: ServiceAccount
    name: jenkins-admin
    namespace: devops
roleRef:
  kind: ClusterRole
  name: jenkins-rbac
  apiGroup: rbac.authorization.k8s.io
EOF



kubectl apply -f -<<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: jenkins-home-pvc
  namespace: devops
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-provisioner
  volumeMode: Filesystem
EOF
```

部署服务

```
kubectl apply -f -<<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: jenkins
  name: jenkins
  namespace: devops
spec:
  replicas: 1
  selector:
    matchLabels:
      app: jenkins
  template:
    metadata:
      labels:
        app: jenkins
    spec:
      containers:
        - env:
            - name: JAVA_OPTS
              value: >-
                -XshowSettings:vm -Dhudson.slaves.NodeProvisioner.initialDelay=0
                -Dhudson.slaves.NodeProvisioner.MARGIN=50
                -Dhudson.slaves.NodeProvisioner.MARGIN0=0.85
                -Duser.timezone=Asia/Shanghai
          image: 'jenkins/jenkins:lts'
          imagePullPolicy: IfNotPresent
          livenessProbe:
            failureThreshold: 12
            httpGet:
              path: /login
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 60
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5
          name: jenkins
          ports:
            - containerPort: 8080
              name: web
              protocol: TCP
            - containerPort: 50000
              name: agent
              protocol: TCP
          readinessProbe:
            failureThreshold: 12
            httpGet:
              path: /login
              port: 8080
              scheme: HTTP
            initialDelaySeconds: 60
            periodSeconds: 10
            successThreshold: 1
            timeoutSeconds: 5
          resources:
            limits:
              cpu: '1'
              memory: 1Gi
            requests:
              cpu: 500m
              memory: 512M
          volumeMounts:
            - mountPath: /var/jenkins_home
              name: jenkinshome
      restartPolicy: Always
      securityContext:
        fsGroup: 1000
      serviceAccount: jenkins-admin
      serviceAccountName: jenkins-admin
      volumes:
        - name: jenkinshome
          persistentVolumeClaim:
            claimName: jenkins-home-pvc
---
apiVersion: v1
kind: Service
metadata:
  annotations:
  labels:
    app: jenkins
  name: jenkins
  namespace: devops
spec:
  type: ClusterIP
  ports:
    - name: web
      port: 8080
      protocol: TCP
      targetPort: 8080
    - name: agent
      port: 50000
      protocol: TCP
      targetPort: 50000
  selector:
    app: jenkins
EOF
```

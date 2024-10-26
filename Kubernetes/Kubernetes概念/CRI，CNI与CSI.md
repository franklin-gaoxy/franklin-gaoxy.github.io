## CRI
kubernetes通过当前节点的socket文件去调用docker或者containerd。而对应的docker或者containerd也需要遵守kubernetes的CRI调用协议。
## CNI
CNI也是一个协议，不过是用来实现容器网络的。
CNI的实现组件都是二进制的文件，大多都是go语言编写的。同时他们要接受对应的参数，如网段信息，网卡信息，这些参数都是kubernetes自动填充调用的，所以对应的插件也要遵守CNI的参数传递的协议。
## CSI
CSI是用来实现存储相关的内容的。他是利用的Grpc框架，通过rpc请求互相完成的调用。
grpc框架根据对应的模板可以自动生成对应的一些代码，而模板就是kubernetes官方提供的，要去实现它对应的接口。
kubelet通过unix domain socket和CSI进行通信，而master不直接和csi通信，需要经过kubernetes API，所以CSI需要监视kubernetes API，以便做出操作。
### grpc的安装
```shell
go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.28
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.2
```
添加到环境变量
```shell
export PATH="$PATH:$(go env GOPATH)/bin"
```


### 相关地址
[https://github.com/container-storage-interface/spec/tree/master](https://github.com/container-storage-interface/spec/tree/master)
[https://github.com/kubernetes-csi/csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs) 
[https://kubernetes-csi.github.io/docs/introduction.html](https://kubernetes-csi.github.io/docs/introduction.html) 



安装依赖
```shell
go get k8s.io/client-go
```
# 简单使用

## 链接到k8s
```go
package main

import (
	"context"
	"fmt"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
)

func main() {
	// 获取 kubeconfig 配置文件路径
	kubeconfig := "admin.conf"

	// 使用 kubeconfig 创建 config，获取集群配置
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		panic(err)
	}

	// 使用 config 创建 Kubernetes 客户端
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
}
```

## 列出所有节点名称
```go
	// 使用客户端获取节点列表
	nodes, err := clientset.CoreV1().Nodes().List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		panic(err)
	}

	// 打印节点名称
	for _, node := range nodes.Items {
		fmt.Println(node.Name)
	}
```
## 列出所有的pods
```go
	// 获取所有的 Pod
	pods, err := clientset.CoreV1().Pods("").List(context.TODO(), metav1.ListOptions{})
	if err != nil {
		panic(err.Error())
	}

	// 输出 Pod 信息
	fmt.Println("Pods:")
	for _, pod := range pods.Items {
		fmt.Printf("%s :%s Status:%s\n", pod.Namespace, pod.Name, pod.Kind)
	}
```
## 创建一个deployment
```go
package main

import (
	"context"
	"fmt"
	"io/ioutil"
	appsv1 "k8s.io/api/apps/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"sigs.k8s.io/yaml"
)

func main() {
	// 获取 kubeconfig 配置文件路径
	kubeconfig := "admin.conf"

	// 使用 kubeconfig 创建 config，获取集群配置
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		panic(err)
	}

	// 使用 config 创建 Kubernetes 客户端
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}

	// 读取 deploy.yaml 文件内容
	deployYAML, err := ioutil.ReadFile("deploy.yaml")
	if err != nil {
		panic(err.Error())
	}

	// 解析 deploy.yaml 文件内容为 Deployment 对象
	deployment := &appsv1.Deployment{}
	err = yaml.Unmarshal(deployYAML, deployment)
	if err != nil {
		panic(err.Error())
	}

	// 创建 Deployment
	result, err := clientset.AppsV1().Deployments("default").Create(context.TODO(), deployment, metav1.CreateOptions{})
	if err != nil {
		panic(err.Error())
	}

	fmt.Printf("Deployment created: %s\n", result.Name)
}

```
## 判断创建的类型及创建statefulset
```go
package main

import (
	"context"
	"fmt"
	"io/ioutil"
	appsv1 "k8s.io/api/apps/v1"
	v1beta1 "k8s.io/api/apps/v1beta1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	"k8s.io/apimachinery/pkg/apis/meta/v1/unstructured"
	"k8s.io/client-go/kubernetes"
	"k8s.io/client-go/tools/clientcmd"
	"k8s.io/client-go/util/retry"
	"sigs.k8s.io/yaml"
)

func main() {
	// 获取clientset
	clientset := createKubernetesClientSet()
	// 获取文件句柄
	obj,fileContent := unmarshalYaml()

	// 根据文件类型创建对应的资源
	switch obj.GetKind() {
	case "StatefulSet":
		statefulSet := &appsv1.StatefulSet{}
		err := yaml.Unmarshal(fileContent, statefulSet)
		if err != nil {
			panic(err.Error())
		}

		// 创建或更新 StatefulSet
		err = createOrUpdateStatefulSet(clientset, statefulSet)
		if err != nil {
			panic(err.Error())
		}
		fmt.Printf("StatefulSet created or updated: %s\n", statefulSet.Name)

	case "StatefulSet_v1beta1":
		statefulSet := &v1beta1.StatefulSet{}
		err := yaml.Unmarshal(fileContent, statefulSet)
		if err != nil {
			panic(err.Error())
		}

		// 创建或更新 v1beta1 StatefulSet
		err = createOrUpdateStatefulSetV1Beta1(clientset, statefulSet)
		if err != nil {
			panic(err.Error())
		}
		fmt.Printf("v1beta1 StatefulSet created or updated: %s\n", statefulSet.Name)

	default:
		fmt.Println("Unsupported resource type")
	}
}

// 创建一个客户端
func createKubernetesClientSet() *kubernetes.Clientset{
	// 获取 kubeconfig 配置文件路径
	kubeconfig := "admin.conf"

	// 使用 kubeconfig 创建 config，获取集群配置
	config, err := clientcmd.BuildConfigFromFlags("", kubeconfig)
	if err != nil {
		panic(err)
	}

	// 使用 config 创建 Kubernetes 客户端
	clientset, err := kubernetes.NewForConfig(config)
	if err != nil {
		panic(err)
	}
	return clientset
}

// 解析yaml文件
func unmarshalYaml() (*unstructured.Unstructured,[]byte) {
	// 读取文件内容
	fileContent, err := ioutil.ReadFile("file.yaml")
	if err != nil {
		panic(err.Error())
	}

	// 解析 YAML 文件
	obj := &unstructured.Unstructured{}
	err = yaml.Unmarshal(fileContent, &obj)
	if err != nil {
		panic(err.Error())
	}
	return obj,fileContent
}

// 创建或更新 StatefulSet
func createOrUpdateStatefulSet(clientset *kubernetes.Clientset, statefulSet *appsv1.StatefulSet) error {
	_, err := clientset.AppsV1().StatefulSets(statefulSet.Namespace).Get(context.TODO(), statefulSet.Name, metav1.GetOptions{})
	if err != nil {
		_, err = clientset.AppsV1().StatefulSets(statefulSet.Namespace).Create(context.TODO(), statefulSet, metav1.CreateOptions{})
	} else {
		err = retry.RetryOnConflict(retry.DefaultBackoff, func() error {
			_, updateErr := clientset.AppsV1().StatefulSets(statefulSet.Namespace).Update(context.TODO(), statefulSet, metav1.UpdateOptions{})
			return updateErr
		})
	}
	return err
}

// 创建或更新 v1beta1 StatefulSet
func createOrUpdateStatefulSetV1Beta1(clientset *kubernetes.Clientset, statefulSet *v1beta1.StatefulSet) error {
	_, err := clientset.AppsV1beta1().StatefulSets(statefulSet.Namespace).Get(context.TODO(), statefulSet.Name, metav1.GetOptions{})
	if err != nil {
		_, err = clientset.AppsV1beta1().StatefulSets(statefulSet.Namespace).Create(context.TODO(), statefulSet, metav1.CreateOptions{})
	} else {
		err = retry.RetryOnConflict(retry.DefaultBackoff, func() error {
			_, updateErr := clientset.AppsV1beta1().StatefulSets(statefulSet.Namespace).Update(context.TODO(), statefulSet, metav1.UpdateOptions{})
			return updateErr
		})
	}
	return err
}

```

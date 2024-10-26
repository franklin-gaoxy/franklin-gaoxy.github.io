# 简介
viper包可以和Cobra包结合使用.
viper包实现的是从配置文件读取内容,并绑定到对应的参数.
# 简单使用
## 安装
```shell
go get -u github.com/spf13/viper
```
## 使用
main.go
```go
package main

import (
	"errors"
	"flag"
	"fmt"
	"github.com/spf13/viper"
)

// 定义一个命令行参数 -c指定配置文件 默认使用 conf.yaml
var cfg = flag.String("c", "conf.yaml", "config file.")

func main() {
	flag.Parse()

	if *cfg != "" {
		// 绑定配置文件
		viper.SetConfigFile(*cfg)
		// 类型为yaml类型
		viper.SetConfigType("yaml")
	} else {
		// 没有指定文件则使用默认路径
		viper.AddConfigPath(".")
		// 设置路径
		viper.AddConfigPath("$HOME/.config")
		// 设置文件名
		viper.SetConfigName("cfg")
	}

	// 读取配置文件
	if err := viper.ReadInConfig(); err != nil {
		// 返回值为true 表示没有找到配置
		if _, ok := err.(viper.ConfigFileNotFoundError); ok {
			fmt.Println(errors.New("config file not found"))
		} else {
			fmt.Println(errors.New("config file was found but another error was produced"))
		}
		return
	}
	fmt.Printf("using config file: %s\n", viper.ConfigFileUsed())

	// 读取配置值 输出到控制台
	fmt.Printf("username: %s\n", viper.Get("username"))
	fmt.Printf("ip:port %s:%v\n", viper.Get("server.ip"), viper.Get("server.port"))
}
```
创建配置文件 conf.yaml,内容:
```yaml
username: zhangsan
password: hahahhaha
server:
  ip: 127.0.0.1
  port: 8080
```
命令行执行:
```shell
go run .\main.go
using config file: conf.yaml
username: zhangsan
ip:port 127.0.0.1:8080
```
### 读取子配置的其他方式
```go
package main

import (
	"fmt"
	"github.com/spf13/viper"
)

func main() {
	viper.SetConfigFile("./conf.yaml")
	viper.ReadInConfig()

	// 获取 server 子树
	srvCfg := viper.Sub("server")

	// 读取配置值
	fmt.Printf("ip: %v\n", srvCfg.Get("ip"))
	fmt.Printf("port: %v\n", srvCfg.Get("port"))
}
```
### 多实例对象
```go
package main

import "github.com/spf13/viper"

func main() {

	// 设置第一个对象
	one := viper.New()
	one.SetConfigName("./conf.yaml")
	if err := one.ReadInConfig(); err != nil {
		panic(err)
	}
	// 设置第二个对象
	two := viper.New()
	two.SetConfigName("./conf2.yaml")
	two.ReadInConfig()
	
	fmt.Println("one username: ", one.Get("username"))
	fmt.Println("two username: ", two.Get("username"))
}

```
## 配置文件的热加载
```go
package main

import (
	"fmt"
	"github.com/fsnotify/fsnotify"
	"github.com/spf13/viper"
	"time"
)

func main() {
	viper.SetConfigFile("./conf.yaml")
	if err := viper.ReadInConfig(); err != nil {
		panic(err)
	}
	// 启动时先输出一次内容
	fmt.Println(viper.Get("username"))

	// 每次配置文件发生更改后 会调用次回执函数
	viper.OnConfigChange(func(in fsnotify.Event) {
		fmt.Println("config file change: ", in.Name)
		fmt.Println(viper.Get("username"))
	})
	// 监控
	viper.WatchConfig()

	// 阻塞程序
	time.Sleep(time.Second * 10)
	// 读取配置值
	fmt.Println(viper.Get("username"))
}
```
## 读取系统的环境变量
```go
package main

import (
	"fmt"
	"github.com/spf13/viper"
)

func main() {
	// 读取系统的环境变量
	viper.AutomaticEnv()
	// 输出值
	fmt.Println(viper.Get("GOPATH"))

	// 从系统获取单个值 为空返回 nil
	viper.BindEnv("TEST")
	fmt.Println(viper.Get("TEST"))
}

```

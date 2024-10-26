# installer

```yaml
go get -u github.com/spf13/cobra@latest
go get k8s.io/klog/v2
```

需求:

那么他如何和cobra结合使用,接下来你需要写一个程序,使用cobra和klog,程序需要接受两个子命令,一个是init 执行后输出一段init即可,另一个是version 执行后输出v1.0.0,init子命令需要接受两个参数,一个可为空是--db ,他会传入一个例如 10.0.0.100:3306的参数,另一个是--data-path,他是不可为空的,必须传入一个路径
最后,给init加一个子命令run,执行后输出 running 然后进入sleep 30秒即可

code:

`main.go`

```go
package main

import (
    "flag"
    "fmt"
    "os"
    "time"

    "github.com/spf13/cobra"
    "k8s.io/klog/v2"
)

var (
    db       string
    dataPath string
)

func main() {
    // 初始化 klog
    klog.InitFlags(nil)
    flag.Set("v", "2")
    flag.Parse()
    defer klog.Flush()

    // 定义根命令
    var rootCmd = &cobra.Command{Use: "app"}

    // 定义 version 子命令
    var versionCmd = &cobra.Command{
        Use:   "version",
        Short: "Print the version number of the application",
        Run: func(cmd *cobra.Command, args []string) {
            fmt.Println("v1.0.0")
        },
    }

    // 定义 init 子命令
    var initCmd = &cobra.Command{
        Use:   "init",
        Short: "Initialize the application",
        Run: func(cmd *cobra.Command, args []string) {
            if dataPath == "" {
                klog.Fatalf("Error: --data-path is required")
            }
            klog.Infof("Initializing with db: %s, data-path: %s", db, dataPath)
            fmt.Println("init")
        },
    }

    // 添加 init 子命令的标志
    initCmd.Flags().StringVar(&db, "db", "", "Database connection string (can be empty)")
    initCmd.Flags().StringVar(&dataPath, "data-path", "", "Path to the data (required)")
    initCmd.MarkFlagRequired("data-path")

    // 定义 init 子命令下的 run 子命令
    var runCmd = &cobra.Command{
        Use:   "run",
        Short: "Run the initialized application",
        Run: func(cmd *cobra.Command, args []string) {
            fmt.Println("running")
            time.Sleep(30 * time.Second)
        },
    }

    // 将 run 子命令添加到 init 子命令下
    initCmd.AddCommand(runCmd)

    // 将 init 和 version 子命令添加到根命令下
    rootCmd.AddCommand(initCmd, versionCmd)

    // 执行根命令
    if err := rootCmd.Execute(); err != nil {
        fmt.Println(err)
        os.Exit(1)
    }
}
```

按照等级区分日志内容的klog

```go
package main

import (
	"flag"
	"fmt"

	"k8s.io/klog/v2"
)

func main() {
	fmt.Println("start ...")
	klog.InitFlags(nil)
	flag.Set("v","5")
	flag.Parse()
	defer klog.Flush()
	writeLog()
	fmt.Println("end ...")
}

func writeLog() {
	klog.V(3).Info("this is a v3 info!")
	klog.V(6).Info("this is a v6 info!")
	klog.V(3).ErrorS(nil,"this is a v3 error!")
	klog.V(8).Error(nil,"this is a v8 error!")
	klog.Warning("this is a warning!")
	klog.Error("this is a error!")
	klog.Fatal("this is a fatal!")
}



```
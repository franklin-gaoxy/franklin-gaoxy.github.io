# 文档
官方文档: [https://cobra.dev/](https://cobra.dev/)
github: [https://github.com/spf13/cobra](https://github.com/spf13/cobra)
# 概念
## 命令
```go
# 这里的add就是命令
git add
```
## 参数
```go
# 这里的README.MD就是参数
git add README.MD 
```
## 标志
```go
# 这里的--hard就是标志 他类似于一个参数 但是具有他自己单独的功能
git set xxx --hard
```
持久化标识: 持久化标识可以全局范围可用,比如-h参数.所有的子命令都可以执行它.
相对立的是本地标志.只能当前子命令调用.
# 安装
```shell
go get -u github.com/spf13/cobra
go get -u github.com/spf13/viper
```
> viper可以用于读取配置文件

# 使用
```go
package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"os"
)

var rootCmd = &cobra.Command{
	// 输入什么会执行这个命令
	Use: "hugo",
	// 简单描述信息
	Short: "Hugo is a very fast static site generator",
	// 长描述信息
	Long: `A Fast and Flexible Static Site Generator built with
                love by spf13 and friends in Go.
                Complete documentation is available at http://hugo.spf13.com`,
	// 执行这个命令的时候 运行什么
	Run: func(cmd *cobra.Command, args []string) {
		// Do Stuff Here
		fmt.Println("this is a Hugo!")
	},
}
var versionCmd = &cobra.Command{
	Use:   "version",
	Short: "Print the version number of Hugo",
	Long:  `All software has versions. This is Hugo's`,
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("Hugo Static Site Generator v0.9 -- HEAD")
	},
	// 参数不能多余两个 ExactArgs(int) 参数不为n则报错 MinimumNArgs(int) 最少几个参数
	Args: cobra.MaximumNArgs(2),
}

func Execute() {
	// 默认值 什么都不输入 就运行rootCmd.Execute
	if err := rootCmd.Execute(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}

func init() {
	// 绑定一个新的命令
	rootCmd.AddCommand(versionCmd)
	//持久标志 usage:描述 shorthand:-v name: --verbose
	var Verbose bool
	rootCmd.PersistentFlags().BoolVarP(&Verbose, "verbose", "v", false, "verbose output")
	// 本地标志
	var Source string
	rootCmd.Flags().StringVarP(&Source, "source", "s", "", "Source directory to read from")
	// 必选标志 参数-r
	var Region string
	rootCmd.Flags().StringVarP(&Region, "region", "r", "", "AWS region (required)")
	rootCmd.MarkFlagRequired("region")
}
```

## 获取配置
main.go
```go
package main

import "app/cmd"

func main() {
	cmd.Execute()
}

```
cmd/root.go
```go
package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"os"
)

var rootCmd = cobra.Command{
	Use:   "add",
	Short: "Short: add a file",
	Long:  "Long: add a file.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("root cmd start!")
		// 输出获取的值
		fmt.Println(cmd.PersistentFlags().Lookup("author").Value)
		// 输出viper获取的内容
		fmt.Println(viper.GetString("age"))
		fmt.Println("root cmd stop!")
	},
}

// Cobra 程序的入口
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		panic(err)
	}
}

var configFile string

func init() {
	// 初始化配置 传递函数名称
	cobra.OnInitialize(initConfig)
	// 持久化标识 value:默认值 usage:描述
	rootCmd.PersistentFlags().Bool("viper", true, "viper")
	// 带有P的函数 可以添加一个所写 如 --author 和 -a 是一个效果
	rootCmd.PersistentFlags().StringP("author", "a", "YOU NAME", "")
	// 赋值给字段
	rootCmd.PersistentFlags().StringVar(&configFile, "config", "null", "input config file path.")

	// viper读取配置获取的 name 的内容绑定到参数 author 上
	viper.BindPFlag("name", rootCmd.PersistentFlags().Lookup("author"))
	// 设置默认值 author参数 默认值 lisi
	viper.SetDefault("author", "lisi")
}

// 初始化配置文件 读取配置文件内容
func initConfig() {
	if configFile != "" {
		// 绑定配置
		viper.SetConfigFile(configFile)
	} else {
		// 获取当前目录位置 然后读取配置文件
		home, err := os.UserHomeDir()
		cobra.CheckErr(err)
		viper.AddConfigPath(home)
		// 设置格式
		viper.SetConfigFile("yaml")
		// 默认的配置文件名称
		viper.SetConfigName(".cobar")
	}
	// 绑定配置文件的键值对
	viper.AutomaticEnv()
	if err := viper.ReadInConfig(); err != nil {
		panic(err)
	}
	fmt.Println("use config file in :", viper.ConfigFileUsed())
}

```
运行命令:
```shell
go run .\main.go --config conf.yaml
use config file in : conf.yaml
root cmd start!
YOU NAME
20
root cmd stop!
```
> 需要创建 conf.yaml 文件,内容可以自定义一些.

## 一个更加完整的root.go
```go
package cmd

import (
	"fmt"
	"github.com/spf13/cobra"
	"github.com/spf13/viper"
	"os"
)

var rootCmd = cobra.Command{
	Use:   "add",
	Short: "Short: add a file",
	Long:  "Long: add a file.",
	Run: func(cmd *cobra.Command, args []string) {
		fmt.Println("root cmd start!")
		// 输出获取的值
		fmt.Println(cmd.PersistentFlags().Lookup("author").Value)
		// 输出viper获取的内容
		fmt.Println(viper.GetString("age"))
		fmt.Println("root cmd stop!")
	},
	// 最少需要一个参数
	Args: cobra.MinimumNArgs(0),
	/*
		PreRun PersistentPreRun 等都有 E函数 则 PersistentPreRunE() PreRunE()
		表示函数执行时出现错误则返回Error 如果定义了PreRunE函数 PreRun则不会再被执行 其他同理
	*/
	// 在Run函数执行前执行 PostRun则相反
	PreRun: func(cmd *cobra.Command, args []string) {
		fmt.Println("PreRun!")
	},
	//PreRun函数执行前执行 PersistentPostRun则相反
	PersistentPreRun: func(cmd *cobra.Command, args []string) {
		fmt.Println("PersistentPreRun!")
	},
}

// Cobra 程序的入口
func Execute() {
	if err := rootCmd.Execute(); err != nil {
		panic(err)
	}
}

var configFile string

func init() {
	// 初始化配置 传递函数名称
	cobra.OnInitialize(initConfig)
	// 持久化标识 value:默认值 usage:描述
	rootCmd.PersistentFlags().Bool("viper", true, "viper")
	// 带有P的函数 可以添加一个所写 如 --author 和 -a 是一个效果
	rootCmd.PersistentFlags().StringP("author", "a", "YOU NAME", "")
	// 赋值给字段
	rootCmd.PersistentFlags().StringVar(&configFile, "config", "null", "input config file path.")

	// viper读取配置获取的 name 的内容绑定到参数 author 上
	viper.BindPFlag("name", rootCmd.PersistentFlags().Lookup("author"))
	// 设置默认值 author参数 默认值 lisi
	viper.SetDefault("author", "lisi")

	//
}

// 初始化配置文件 读取配置文件内容
func initConfig() {
	if configFile != "" {
		// 绑定配置
		viper.SetConfigFile(configFile)
	} else {
		// 获取当前目录位置 然后读取配置文件
		home, err := os.UserHomeDir()
		cobra.CheckErr(err)
		viper.AddConfigPath(home)
		// 设置格式
		viper.SetConfigFile("yaml")
		// 默认的配置文件名称
		viper.SetConfigName(".cobar")
	}
	// 绑定配置文件的键值对
	viper.AutomaticEnv()
	if err := viper.ReadInConfig(); err != nil {
		panic(err)
	}
	fmt.Println("use config file in :", viper.ConfigFileUsed())
}
```
# 相关文档
[Go 语言现代命令行框架 Cobra 详解](https://zhuanlan.zhihu.com/p/627848739)


## gomod和GOPATH
GOPATH是go语言中一直都有的.而gomod是新版本中新增的包管理工具.
两者可以共用.共用的时候GOPATH指定的是一个大范围的目录: 如/root/go_code 而gomod则是在GOPATH中子文件夹中创建.如: /root/go_code/project ,执行命令 go mod init. 初始化结束后,会出现一个go.mod的文件(/root/go_code/project/go.mod) 这个文件开头记录了当前包的名字 也就是 module project.
> GOPATH模式下,自己写的未发布的包一般存储于 $GOPATH/src 目录下
> $GOPATH/pkg 存储编译好的包或者库文件
> $GOPATH/bin 存储可执行文件

而gomod模式下,自己写的包一般存储于go.mod文件同级目录.比如 GOPATH=/root/go_code,而gomod位于/root/go_code/server_api/ ,那么自己定义了一个包utils,那么这个文件夹应该放在 /root/go_code/server_api/utils,然后文件是/root/go_code/server_api/utils/utils.go .
main文件则位于/root/go_code/server_api/main.go
正确设置了GOPATH，但是构建依然找不到模块，可以配置 go env -w GO111MODULE=off来关闭gomod模式。
## main包构建问题
main包中，默认不会加载其他文件的内容。如果main包有多个文件，构建需要使用命令 `go build *.go`。

## mysql链接问题
sql.Open() 函数是默认系统中自带的.但是可能会提示 找不到驱动mysql.
驱动安装:
```shell
go get github.com/go-sql-driver/mysql
```
然后再文件开头指定:
```go
import (
    _ "github.com/go-sql-driver/mysql"
)
```

## 全局变量问题
```go
package main
// 定义了一个全局变量
var db *sql.DB

func main() {
	var err error
    // 必须声明err或者使用下划线忽略 此处不能使用:= 赋值
	db, err = sql.Open("mysql", "liulaoliu:MyNewPass4!@tcp(43.138.58.139:3306)/game")
	if err != nil {}
}

```
错误demo:
```go
var db *sql.DB

func main() {
    // 使用了类型推导赋值
	db, err := sql.Open("mysql", "liulaoliu:MyNewPass4!@tcp(43.138.58.139:3306)/game")
	if err != nil {
	}
}
```
> 错误demo存在的问题在于: 它编译时不会报错. 运行期可能也不会报错.
> 之所以说可能也不会,是因为如果在main方法中使用db这个对象,那么是没有问题的
> 但是如果在其他函数中使用,则会提示 内存地址有问题.


## 指针使用
如果想要在其他函数中,修改当前函数中的某个变量的值,那么则需要指针传递.

# mysql 连接
```shell
go get github.com/go-sql-driver/mysql
```
```go
package main
import (_ "github.com/go-sql-driver/mysql")

func main(){
    var db sql.DB
    db, err := sql.Open("mysql", "liulaoliu:MyNewPass4!@tcp(43.138.58.139:3306)/game")
    ......
    db.SetConnMaxLifetime(time.Minute * 3)
	db.SetMaxOpenConns(10)
	db.SetMaxIdleConns(10)
    defer db.Close()
}
```
## 查询
传参方式
```go
    rows, err := db.Query("SELECT * FROM users WHERE age > ?", 18)
    if err != nil {
        fmt.Println("Failed to execute query:", err)
        return
    }
```
```go
rows, err := db.Query("SELECT column1, column2 FROM table")
if err != nil {
    panic(err.Error())
}
defer rows.Close()

for rows.Next() {
    var column1 int
    var column2 string
    if err := rows.Scan(&column1, &column2); err != nil {
        panic(err.Error())
    }
    fmt.Println(column1, column2)
}
```
## 其他 增删改
```shell
deleteStmt, err := db.Prepare("DELETE FROM users WHERE id = ?")
if err != nil {
    panic(err.Error())
}

res, err := deleteStmt.Exec(1)
if err != nil {
    panic(err.Error())
}

rowsAffected, err := res.RowsAffected()
if err != nil {
    panic(err.Error())
}

fmt.Printf("Deleted %d rows\n", rowsAffected)
```
## 全局声明方式
```go
package main

import (_ "github.com/go-sql-driver/mysql")

var db *sql.DB
func main() {
    ConnMysql(&db)
    UseMysql(db)
}
func ConnMysql(db **sql.DB) {
	var err error
	*db, err = sql.Open("mysql", "liulaoliu:MyNewPass4!@tcp(43.138.58.139:3306)/game")
	if err != nil {
		panic("conn mysql error!")
	}
	(*db).SetConnMaxLifetime(time.Minute * 3)
	(*db).SetMaxOpenConns(10)
	(*db).SetMaxIdleConns(10)
}
func UseMysql(db *sql.DB) {
    db.Query()
    ....
}
```

# 基础内容
### 声明一个map
```go
func main() {
	var mapa map[string]string
	mapa = make(map[string]string, 10)
}
```
### 声明slice切片
```go
func main() {
	var sli []string
    // 添加内容到slice
	sli = append(sli, "hello")
}
```
### 匿名函数语法
```go
func main() {
	func(num int) {
		for i := 1; i <= num; i++ {
			time.Sleep(time.Second / 2)
			fmt.Printf("%v\n", i)
		}
    // 调用和传参
	}(10)
}
```
### 获取当前时间戳
```go
func main(){
    startTime := time.Now().Unix()
}
```
### 字符串格式化
```go
str := fmt.Sprintf("----%s----", "zhangsan")
// name 类型string age类型int
str := fmt.Sprintf("%s is %d years old.", name, age) 
```

## 函数接收不固定参数
```go
package main

func main() {
	var s []string
	s = append(s, "lisi", "wangwu")
	// slice也可以加入其中
	task("zhangsan", "lisi", "wangwu", "zhaoliu", 88888, s)
}

func task(args ...interface{}) {
	for k, v := range args {
		fmt.Println(k, v)
	}
}
```
## 返回任意类型的数据
```go
package main

func main() {
	k1 := task()
	// 判断类型
	switch k1.(type) {
	case int:
		fmt.Println("int类型数据!")
	case string:
		fmt.Println("string类型数据!")
	case float32:
		fmt.Println("float32类型数据!")
	case bool:
		fmt.Println("bool类型数据!")
	}
}
// interface{} 表示任意类型数据
func task() interface{} {
	return true
}
```
## 判断变量的类型
上面同样也是这一章节的内容,不同的是哪个是switch方式.
```go
package main

func main() {
	var name string = "zhang san"
	fmt.Println(reflect.TypeOf(name))
	// 接收task函数的返回值 并输出类型
	fmt.Println(reflect.TypeOf(task()))
}
func task() interface{} {
	return true
}
```
## switch 传递参数
> 一般情况下,Switch用法都如 "返回任意类型的数据" 章节那样.但是它还可以接受一个变量,然后把这个变量传递给里面的参数

```go
package main

func main() {
	value := task()
    // 将value的值赋值给变量v 这样在switch中可以使用变量v
	switch v := value.(type) {
	case string:
		fmt.Printf("value type is a : %v", v)
	case int:
		fmt.Printf("value type is a : %v", v)
	case bool:
		fmt.Printf("value type is a : %v", v)
	}
}
func task() interface{} {
	return true
}
```
# 文件操作
### 读取小文件
```go
func main() {
	content, err := ioutil.ReadFile("D:/aaa")
	if err != nil {
		fmt.Println(err)
	}
	fmt.Println(content)
}
```
### 写入小文件
```go
	err := ioutil.WriteFile("F:/json", data, 0644)
	if err != nil {
		fmt.Println(err)
	}
```
### 读取大文件
```go
func main() {
	file, err := os.Open("F:\\goland\\src\\main\\test.txt")
	if err != nil {
		fmt.Println(err)
	}
	defer file.Close()
	reader := bufio.NewReader(file)
	for {
		str, err := reader.ReadString('\n')
		if err == io.EOF {
			fmt.Println("读取结束!")
			break
		}
		fmt.Print(str)
	}
}
```
### 写入大文件
```go
func main() {
	file, err := os.OpenFile("F:\\goland\\src\\main\\test1.txt", syscall.O_WRONLY|os.O_CREATE, 0666)
	if err != nil {
		fmt.Println(err)
	}
	defer file.Close()
	write := bufio.NewWriter(file)
	_, _ = write.WriteString("hello world!")
	_ = write.Flush()
}
```
### 写入常用模式
```go
const (
    O_RDONLY int = syscall.O_RDONLY // 只读模式打开文件
    O_WRONLY int = syscall.O_WRONLY // 只写模式打开文件
    O_RDWR   int = syscall.O_RDWR   // 读写模式打开文件
    O_APPEND int = syscall.O_APPEND // 写操作时将数据附加到文件尾部
    O_CREATE int = syscall.O_CREAT  // 如果不存在将创建一个新文件
    O_EXCL   int = syscall.O_EXCL   // 和O_CREATE配合使用，文件必须不存在
    O_SYNC   int = syscall.O_SYNC   // 打开文件用于同步I/O
    O_TRUNC  int = syscall.O_TRUNC  // 如果可能，打开时清空文件
)
```
### 判断目录或者文件是否存在
```go
func main() {
	_, err := os.Stat("F:\\goland\\src\\main\\testaaa.txt")
	if os.IsNotExist(err) {
		fmt.Print("文件不存在")
    }
	_, err = os.Stat("F:\\goland\\src\\main\\test.txt")
	if err == nil {
		fmt.Print("test.txt 文件存在")
	} else {
		fmt.Print("test.txt文件不存在")
	}
}
```
# json相关操作
### 序列化为json(转换为json)
```go
func transformation(attr *attribute) []byte {
	data, err := json.Marshal(&attr)
	if err != nil {
		fmt.Println(err)
	}
	return data
}
```
### 反序列化
```go
func transformation(jsonData string) test {
	var t test
	err := json.Unmarshal([]byte(jsonData), &t)
	if err != nil {
		fmt.Println(err)
	}
	return t
}
```
# 多线程/协程 相关操作
### 管道方式 等待子线程全部完成退出
```go
func process(exitChan chan bool) {
	// 等待一秒
	time.Sleep(time.Second)
	exitChan <- true
}
func main() {
	var exitChan chan bool
	exitChan = make(chan bool, 10)
	for i := 1; i <= 10; i++ {
		go process(exitChan)
	}
	// 接收等待 取出十次后退出
	for i := 1; i <= 10; i++ {
		<-exitChan
    }
}

```
### 第三方包 等待子线程全部完成退出
```go
func main() {
	var wg sync.WaitGroup
	// 将等待的线程数加入 如此处加入两个 wait需要收到两个Done函数的确认信号才会推出
	wg.Add(2)
	intchan := make(chan int, 51)
	go writeData(&wg)
	go readData(wg.Done)
	wg.Wait()
}
func writeData(*sync.WaitGroup){
    wg.Done()
}
func readData(done func()) {
    done()
}
```
### 第三方包 等待子线程全部完成退出(不限制线程方式)
```go
package main

import (
	"fmt"
	"sync"
)

func main() {
	var wg sync.WaitGroup
	var n int
	n = 10
	for i := 0; i < n; i++ {
		wg.Add(1)
		go func() {
			fmt.Println("你好, 世界")
			wg.Done()
		}()
	}
	wg.Wait()
}
```
# channel
### 写入和读取
```go
func main(){
    var strChan chan string
    strChan = make(chan string,10)
    // 或者直接make
    intChan = make(chan int,10)
    close(intChan)

    // 写入
    strChan <- "hello world"
    // 读取
    <-strChan
    // 或者赋值
    str := <-strChan
}
```
### 循环写入和读取
```go
	for {
		_, ok := <-boolchan
        // 判断取出内容
		if !ok {
			break
		}
	}
```
# 指针
## 函数操作其他函数切片(向其他函数slice中写入数据)
```go
package main

func test(a *[]int) {
	*a = append(*a, 100)
}
func main() {
	var a []int
	test(&a)
}
```
# 时间相关
## 睡眠 sleep 等待
```go
// Second 秒 等待三秒 Nanoseconds纳秒
time.Sleep(time.Second * 3)
```
## 获取当前时间戳
```go
tima := time.Now().Unix()
```
# 网络编程
## 简单收发请求
### server.go
```go
func main() {
	// 监听地址
	listen, _ := net.Listen("tcp", "0.0.0.0:8888")
	defer listen.Close()
	for {
		// 循环创建连接 当有新请求进入时创建一个单独的线程负责 也就是 go ProcessConn
		conn, _ := listen.Accept()
		go ProcessConn(conn)
	}
}
func ProcessConn(conn net.Conn) {
	defer conn.Close()
	for {
		// 创建一个切片 接收数据
		tmpSlice := make([]byte, 1024)
		n, err := conn.Read(tmpSlice)
		if err == io.EOF {
			fmt.Println("客户端已断开,退出当前进程.")
			return
		}
		// 打印内容
		fmt.Print(string(tmpSlice[:n]))
	}
}

```
### client.go
```go
func main() {
	// 创建连接
	conn, _ := net.Dial("tcp", "127.0.0.1:8888")
	defer conn.Close()

	remoteAddr := conn.RemoteAddr().String()
	fmt.Printf("远程服务器地址: %v\n", remoteAddr)

	for {
		// os.Stdin 标准输入 Stdout 标准输出 Stderr 标准错误输出
		// 此处为从控制台读取输入内容
		reader := bufio.NewReader(os.Stdin)
		// 输入换行符认为读取结束 也就是按下回车
		content, _ := reader.ReadString('\n')
		// []byte() 强制转换为byte切片
		num, _ := conn.Write([]byte(content))
		fmt.Printf("发送了%d字节\n", num)
	}
}
```
# Redis连接
## 常用单进程模式
```go
go get github.com/gomodule/redigo/redis
```
```go
package main

import (
	"fmt"
	"github.com/gomodule/redigo/redis"
)

func main() {
	// 连接远程Redis tcp协议 然后写地址
	conn, err := redis.Dial("tcp", "10.0.0.15:6379")
	if err != nil {
		fmt.Println(err)
	}

	defer conn.Close()

	// 认证 如果带有密码的话 那么需要auth 输入密码才能使用
	_, err = conn.Do("auth", "123456")
	if err != nil {
		fmt.Println(err)
		return
	} else {
		fmt.Println("登陆成功!")
	}

	// 写入数据
	_, err = conn.Do("set", "name", "zhang san")
	if err != nil {
		fmt.Println("写入数据出错!", err)
	}
}
```
## pool 连接池方式
```go
package main

import "github.com/gomodule/redigo/redis"

var pool *redis.Pool
// 初始化时候则创建连接池
func init() {
	pool = &redis.Pool{
		Dial:            func() (redis.Conn, error) { return redis.Dial("tcp", "10.0.0.15") },
		DialContext:     nil,
		TestOnBorrow:    nil,
		MaxIdle:         8,   // 最大空闲连接数
		MaxActive:       0,   //最大连接数 0 表示不限制
		IdleTimeout:     300, // 最大空闲时间
		Wait:            false,
		MaxConnLifetime: 0,
	}
}
func main() {
	conn := pool.Get()
	conn.Do("mset", "user1", "name", "zhangsan")
    // 一旦执行了Close 就没办法再取出东西了 但是如果执行pool.Get()是没问题 但是执行pool.Do()就会报错了
	conn.Close()
}
```

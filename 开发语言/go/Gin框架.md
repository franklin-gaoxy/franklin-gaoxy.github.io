# Gin

## 安装

```shell
go get -u github.com/gin-gonic/gin
```

> 注意: 安装最好开启gomod. idea需要再设置里单独开启.
>  
> GOPATH指定一个大的目录范围,比如 /root/go_code gomod则在下面的小文件夹里执行创建 比如 /root/go_code/one_project 目录下执行.
>  
> gomod init命令: go mod init (module name)
>  
> 寻找自定义的 未发布的包 会在 GOPATH/src 文件夹中找.
>  
> GOPATH/pkg 一般存放编译好的包和库文件
>  
> GOPATH/bin 存放可执行文件


## 快速入门

### 简单案例

文件结构

```
数据结构
	main
		main.go
		go.mod
	pkg
		......
	src
```

```go
package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()
	router.GET("/", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"message": "Hello, world!",
		})
	})
	if router.Run(":8080") != nil {
		panic("listen 8080 error.")
	}
}
```

> 请求 8080 端口 这将返回一个 json串.


### 返回中文

> 尽管上面哪种方式也行


```go
package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func main() {
	r := gin.Default()
	// 返回中文内容(非ASCII字符)
	r.GET("/someJSON", func(c *gin.Context) {
		data := map[string]interface{}{
			"lang": "GO语言",
			"tag":  "<br>",
		}

		// will output : {"lang":"GO\u8bed\u8a00","tag":"\u003cbr\u003e"}
		c.AsciiJSON(http.StatusOK, data)
	})

	// Listen and serve on 0.0.0.0:8080
	r.Run(":8080")
}
```

### 接收参数并返回

```go
package main

import (
	"github.com/gin-gonic/gin"
)

/*
先声明了两个结构体 分别是A和B 用于接收不同的参数
*/
type StructA struct {
	// 结构体A字段(名称必须大写) 然后定义一个接收的参数名 如 field_a 会接收url里的 &filed_a=hello 的参数
	FieldA string `form:"field_a"`
}

func GetA(c *gin.Context) {
	var a StructA
	// 进行绑定 接收参数
	c.Bind(&a)
	// 返回json格式内容
	c.JSON(200, gin.H{
		"a": a.FieldA,
	})
}

type StructB struct {
	FieldB      string `form:"field_b"`
	StructField StructA
}

func GetB(c *gin.Context) {
	var b StructB
	c.Bind(&b)
	// 返回json格式内容 因为a对应的字段 StructField 也是一个结构体 所以会被解析为两个json {"b": "hello" ,{"a":"world!"}}
	c.JSON(200, gin.H{
		"b": b.FieldB,
		"a": b.StructField,
	})
}

func main() {
	g := gin.Default()
	// 将函数和地址进行绑定
	g.GET("/a", GetA)
	g.GET("/b", GetB)
	g.Run(":8080")
}
```

请求 `:8080/a?field_a=hello%20world` 返回

```
{
    "a": "hello world"
}
```

请求 `:8080/b?field_a=hello&field_b=world` 返回

```
{
    "a": {
        "FieldA": "hello"
    },
    "b": "world"
}
```
### 从json获取数据
```go
// 声明结构体
type loginContent struct {
	Username string `json:"username"`
	Password string `json:"password"`
}
// 函数代码
func VerifyLogin(g *gin.Context, db *sql.DB) {
	// 获取传入的用户名密码
	var l loginContent
	if err := g.ShouldBindJSON(&l); err != nil {
		g.JSON(200, gin.H{"login status": false, "error": err})
		return
	}
}
```
### 绑定HTML复选框代码

```go
package main

import "github.com/gin-gonic/gin"

type MyFrom struct {
	Colors []string `form:"colors[]"`
}
// POST请求函数 获取FROM表单内容 返回json串
func formHandler(c *gin.Context ){
	var form MyFrom
	c.ShouldBind(&form)
	c.JSON(200,gin.H{
		"color": form.Colors,
	})
}
// GET 请求函数 返回from表单的页面
func from(c *gin.Context) {
	c.HTML(200,"index.html",gin.H{"title":"he"})
}
func main(){
	g := gin.Default()
	// LoadHTMLFiles 打开文件 g.LoadHTMLGlob() 打开目录 用于返回前端页面使用
	g.LoadHTMLFiles("F:\\GoProject\\数据结构\\main\\index.html")
	// 对 / 路径监听两个操作 分别是GET 和POST.并且调用不同的函数
	g.POST("/",formHandler)
	g.GET("/",from)
	g.Run(":8080")
}
```

index.html内容

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>from</title>
</head>
<body>

<h5>提交内容</h5>

<form action="http://127.0.0.1:8080/" method="POST">
    <p>Check some colors</p>
    <label for="red">Red</label>
    <input type="checkbox" name="colors[]" value="red" id="red">
    <label for="green">Green</label>
    <input type="checkbox" name="colors[]" value="green" id="green">
    <label for="blue">Blue</label>
    <input type="checkbox" name="colors[]" value="blue" id="blue">
    <input type="submit">
</form>

</body>
</html>
```

### 获取传入数据

```go
package main

import (
	"github.com/gin-gonic/gin"
	"log"
	"time"
)

type Person struct {
	Name string `form:"name"`
	Address string `form:"address"`
	// 时间类型数据 按照什么格式进行格式化
	Birthday time.Time `form:"birthday" time_format:"2006-01-02" time_utc:"1"`
}
func Handler (c *gin.Context){
	var person Person
	if c.ShouldBind(&person) == nil {
		// 输出到控制台
		log.Println(person.Name)
		log.Println(person.Address)
		log.Println(person.Birthday)
	}
	c.String(200,"Success.")
}
func main(){
	g := gin.Default()
	g.GET("/",Handler)
	g.Run(":8080")
}
```

> [http://127.0.0.1:8080/?name=appleboy&address=iiio&birthday=1998-03-15](http://127.0.0.1:8080/?name=appleboy&address=iiio&birthday=1998-03-15)


### 绑定uri

```go
package main

import (
	"github.com/gin-gonic/gin"
	"log"
)

type Person struct {
	// 从uri地址接收两个变量
	ID string `uri:"id" binding:"required,uuid"`
	Name string `uri:"name" binding:"required"`
}
func Handler (c *gin.Context){
	var person Person
	// ShouldBindUri 将变量和uri进行绑定
	if err := c.ShouldBindUri(&person); err != nil {
		// 遇到错误 输出错误并返回
		log.Println(err)
		c.JSON(400,gin.H{"msg": err})
	} else {
		// 没有错误 返回uuid和用户名
		c.JSON(200,gin.H{"name": person.Name,"uuid": person.ID})
	}
}
func main(){
	g := gin.Default()
	// 接收的参数
	g.GET("/:name/:id",Handler)
	g.Run(":8080")
}
```

> 请注意: uuid有一定的格式,不是随机字符串组成
>  
> [http://127.0.0.1:8080/zhangsan/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d](http://127.0.0.1:8080/zhangsan/9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d)


也可以去掉后面的uuid 这样将不会进行uuid检查 示例:

```go
type Person struct {
	// 从uri地址接收两个变量
	ID string `uri:"id" binding:"required"`
	Name string `uri:"name" binding:"required"`
}
```

他还支持`number`数字类型,`email` 邮箱类型,`default`是否设置了默认值,`eq`是否相等,`ne`是否不等....

### 日志着色

在默认情况,启动后的控制台日志输出,会给默认的一些如状态码添加颜色.如果想关闭,可以使用:

```go
func main(){
	// 关闭日志着色
	gin.DisableConsoleColor()
	g := gin.Default()
	// 接收的参数
	g.GET("/:name/:id",Handler)
	g.Run(":8080")
}
```

### 自定义HTTP配置

```go
package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func main(){
	route := gin.Default()
	// 定义路径
	route.GET("/", func(c *gin.Context) {
		c.JSON(200,gin.H{"msg":"ok"})
	})
	// 自定义http 配置
	s := &http.Server{
		// 监听端口
		Addr:                         ":8080",
		// 调用函数 上面声明的route
		Handler:                      route,
		DisableGeneralOptionsHandler: false,
		TLSConfig:                    nil,
		ReadTimeout:                  0,
		ReadHeaderTimeout:            0,
		WriteTimeout:                 0,
		IdleTimeout:                  0,
		MaxHeaderBytes:               0,
		TLSNextProto:                 nil,
		ConnState:                    nil,
		ErrorLog:                     nil,
		BaseContext:                  nil,
		ConnContext:                  nil,
	}
	// 监听端口
	if err := s.ListenAndServe(); err != nil && err != http.ErrServerClosed {
		panic(err)
	}
}
```

### 自定义日志格式

```go
package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"time"
)

func main(){
	// 创建一个对象 New为不带中间件的模式 这样可以允许自己编写的中间件插入其中
	router := gin.New()
	// 使用自定义的中间件
	router.Use(gin.LoggerWithFormatter(func(param gin.LogFormatterParams) string {
		return fmt.Sprintf("%s - [%s] \"%s %s %s %d %s \"%s\" %s\"\n",
			param.ClientIP,
			param.TimeStamp.Format(time.RFC1123),
			param.Method,
			param.Path,
			param.Request.Proto,
			param.StatusCode,
			param.Latency,
			param.Request.UserAgent(),
			param.ErrorMessage,
		)
	}))
	// 自定义处理panic
	router.Use(gin.Recovery())
	router.GET("/ping", func(c *gin.Context) {
		c.String(200, "pong")
	})
	router.Run(":8080")
}
```

> 中间件 指的是接收到请求之后,在执行Handler处理函数之前的一些操作,如日志处理,路径判断,格式检查等.


### 定义路由日志的格式

```go
package main

import (
	"github.com/gin-gonic/gin"
	"log"
)

func main(){
	router := gin.Default()
	// 定义路由日志的格式
	gin.DebugPrintRouteFunc = func(httpMethod, absolutePath, handlerName string, nuHandlers int) {
		log.Printf("endpoint : request type: %v, listing path: %v, execute func: %v,number: %v\n", httpMethod, absolutePath, handlerName, nuHandlers)
	}
	router.GET("/ping", func(c *gin.Context) {
		c.String(200, "pong")
	})
	router.Run(":8080")
}
```

### 使用goroutines处理异步请求

```go
package main

import (
	"fmt"
	"time"

	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	// 注册一个全局中间件
	router.Use(func(c *gin.Context) {
		start := time.Now()
		fmt.Println("start processing request...")
		// 在接受到请求后创建一个goroutines去处理单独的操作
		go func() {
			time.Sleep(5 * time.Second)
			fmt.Println("finish processing request.")
		}()
		// 让程序继续向下执行而不要等待上面协程的执行
		c.Next()
		end := time.Now()
		latency := end.Sub(start)
		fmt.Printf("latency: %s\n", latency.String())
	})

	// 注册路由和处理函数
	router.GET("/", func(c *gin.Context) {
		c.String(200, "Hello, World!")
	})

	// 启动 HTTP 服务器
	router.Run(":8080")
}
```

这样可以再接收到用户请求后快速处理降低响应时间(尽管任务没有执行结束),然后后台创建单独的线程继续去处理其他操作.

### 优雅的关闭

在接收到kill信号后,可以单独做一些其他处理,比如写入日志等操作.然后调用shutdown方法.

```go
package main

import (
	"context"
	"fmt"
	"github.com/gin-gonic/gin"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func main() {
	router := gin.Default()

	// 注册路由和处理函数
	router.GET("/", func(c *gin.Context) {
		c.String(200, "Hello, World!")
	})

	// 自定义 HTTP 服务器配置
	srv := http.Server{
		Addr: ":8080",
		Handler: router,
	}
	// 创建一个线程去启动它
	go func() {
		if err := srv.ListenAndServe();err != nil && err != http.ErrServerClosed {
			fmt.Printf("listen: %v\n",err)
		}
	}()
	// 监听退出信号 创建一个管道
	quit := make(chan os.Signal)
	// 监听系统发送的结束信号
	signal.Notify(quit,syscall.SIGINT,syscall.SIGTERM)
	// 从管道取出内容
	<-quit
	fmt.Println("shutdown server...")
	// context.WithTimeout() 接收一个上下文和超时时间 返回一个关闭函数
	ctx , cancel := context.WithTimeout(context.Background(),5*time.Second)
	defer cancel()

	// 调用Shutdown()方法 关闭对象
	if err := srv.Shutdown(ctx);err != nil {
		fmt.Printf("server forced to shutdown : %v\n",err)
	}
	fmt.Println("process exiting.")
}
```

### 路由分组

```go
package main

import (
	"github.com/gin-gonic/gin"
)

func task (c *gin.Context){
	c.JSON(200,gin.H{"msg":"ok"})
}

func main(){
	route := gin.Default()

	// 定义第一个组 v1 具有子路径 /login /home 只能处理 POST请求
	v1 := route.Group("/v1")
	{
		v1.POST("/login",task)
		v1.POST("/home",task)
	}
	// 定义第二个组 v2 具有子路径 /login /home 只能处理 GET请求
	v2 := route.Group("/v2")
	{
		v2.GET("/login",task)
		v2.GET("/home",task)
	}
	route.Run(":8080")
}
```

请求地址为 :8080/v2/login 或者 :8080/v2/home 可以使用curl进行请求(**需要注意请求方式不同**)

```
C:\Users\gaoxiuyang>curl 127.0.0.1:8080/v2/login
{"msg":"ok"}
C:\Users\gaoxiuyang>curl -XPOST 127.0.0.1:8080/v1/login
{"msg":"ok"}
```

### 日志保存

```go
package main

import (
	"github.com/gin-gonic/gin"
	"io"
	"os"
)

func main()  {
	// 关闭控制台颜色
	gin.DisableConsoleColor()

	// 指定日志文件
	f,_ := os.Create("gin.log")
	gin.DefaultWriter = io.MultiWriter(f)

	// 逻辑处理
	route := gin.Default()
	route.GET("/", func(c *gin.Context) {
		c.JSON(200,gin.H{
			"msg" :"success",
		})
	})
	if route.Run(":8080") != nil {
		panic("run server error!")
	}
}
```

> 将日志保存到文件,控制台就不会在输出了 可以去日志文件里查看


### JSONP

> 据说可以处理跨域请求,返回内容可以嵌套在前端传入的 callback参数里


```go
package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func main()  {
	route := gin.Default()
    // 根路径函数 返回 callback(data)
	route.GET("/", func(c *gin.Context) {
		data := map[string]interface{}{
			"foo": "bar",
		}
		c.JSONP(http.StatusOK,data)
	})
	route.Run(":8080")
}
```

```
C:\Users\gaoxiuyang>curl 127.0.0.1:8080?callback=asd
asd({"foo":"bar"});
```

### 多类型参数绑定

```go
package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

// 定义结构体 存放登录用户名和密码
type Login struct {
	User     string `form:"user" json:"user" xml:"user"  binding:"required"`
	Password string `form:"password" json:"password" xml:"password" binding:"required"`
}

func main() {
	router := gin.Default()

	// 绑定 JSON 数据: ({"user": "manu", "password": "123"})
	router.POST("/loginJSON", func(c *gin.Context) {
		var json Login
		if err := c.ShouldBindJSON(&json); err != nil {
			// 如果绑定失败 返回错误
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}
		
		// 判断用户名密码是否相符
		if json.User != "manu" || json.Password != "123" {
			// 不相等则返回认证失败
			c.JSON(http.StatusUnauthorized, gin.H{"status": "unauthorized"})
			return
		}

		// 返回登录成功
		c.JSON(http.StatusOK, gin.H{"status": "you are logged in"})
	})

	/*
		绑定xml格式参数
		Example for binding XML (
			<?xml version="1.0" encoding="UTF-8"?>
			<root>
				<user>manu</user>
				<password>123</password>
			</root>)
	 */

	router.POST("/loginXML", func(c *gin.Context) {
		var xml Login
		// 此处的方法由 ShouldBindJSON 更换为了 ShouldBindXML
		if err := c.ShouldBindXML(&xml); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if xml.User != "manu" || xml.Password != "123" {
			c.JSON(http.StatusUnauthorized, gin.H{"status": "unauthorized"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": "you are logged in"})
	})

	// 绑定来自HTML或者url的参数 (user=manu&password=123)
	router.POST("/loginForm", func(c *gin.Context) {
		var form Login
		// This will infer what binder to use depending on the content-type header.
		if err := c.ShouldBind(&form); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		if form.User != "manu" || form.Password != "123" {
			c.JSON(http.StatusUnauthorized, gin.H{"status": "unauthorized"})
			return
		}

		c.JSON(http.StatusOK, gin.H{"status": "you are logged in"})
	})

	// Listen and serve on 0.0.0.0:8080
	router.Run(":8080")
}
```

> windows下curl比较坑 不能使用单引号传递json 必须要用双引号加转义 如 -d "{\"name\":\"asd\"}"


```
curl -XPOST "http://127.0.0.1:8080/loginJSON" -H "Content-Type: application/json" -d "{\"user\":\"manu\",\"password\":\"123\"}"
```

### 处理form表单绑定数据并返回

```go
package main

import (
	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	// 返回前端页面
	router.LoadHTMLFiles("F:\\GoProject\\数据结构\\main\\index.html")
	router.GET("/", func(c *gin.Context) {
		c.HTML(200,"index.html",gin.H{})
	})

	// 处理表单数据
	router.POST("/form_post", func(c *gin.Context) {
		// 根据key 取值 
		message := c.PostForm("message")
		// 指定默认值
		nick := c.DefaultPostForm("nick", "anonymous")

		c.JSON(200, gin.H{
			"status":  "posted",
			"message": message,
			"nick":    nick,
		})
	})
	router.Run(":8080")
}
```

```html
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8" />
    <title>Form Post Test</title>
</head>
<body>
<h1>Form Post Test</h1>
<form action="/form_post" method="post">
    <label for="message">Message:</label>
    <input type="text" id="message" name="message" />


    <label for="nick">Nick:</label>
    <input type="text" id="nick" name="nick" value="anonymous" />


    <input type="submit" value="Submit" />
</form>
</body>
</html>
```

### 仅绑定url参数

```go
package main

import (
	"github.com/gin-gonic/gin"
	"log"
)

type Preson struct {
	Name string `from:"name"`
	Address string `from:"address"`
}

func main() {
	router := gin.Default()
	router.Any("/", func(c *gin.Context) {
		// 判断请求方式
		if c.Request.Method == "GET" {
			var p Preson
			// ShouldBindQuery 只从url获取传入的参数
			c.ShouldBindQuery(&p)
			log.Println(p.Name,p.Address)
			c.String(200,"success.")
		} else {
			c.String(200,"Unsupported method.")
		}
	})
	router.Run(":8080")
}
```

```
curl "127.0.0.1:8080/?name=lisi&addres=beijing"
```

### 获取路径参数

```go
package main

import "github.com/gin-gonic/gin"

func main()  {
	route := gin.Default()

	// :(name) 表示这是个路径参数 赋值给 name 这个变量 *path 表示后面所有的 都赋值给这一个路径
	route.GET("/user/:groupname/:username/*path", func(c *gin.Context) {
		// 取值 使用Param函数 传入要获取的变量名称
		groupname := c.Param("groupname")
		username := c.Param("username")
		path := c.Param("path")
		// 拼接返回
		c.String(200,groupname + ":" +username + "-" + path)
	})
	route.Run(":8080")
}
```

```
curl "http://127.0.0.1:8080/user/a/zhangsan/aaa/a"
### result ###
a:zhangsan-/aaa/a
```

### 查询参数

适用于url中传递了多个参数的时候,在其中查询固定内容

```go
package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func main()  {
	router := gin.Default()


	router.GET("/welcome", func(c *gin.Context) {
		firstname := c.DefaultQuery("firstname", "Guest")
		lastname := c.Query("lastname")

		c.String(http.StatusOK, "Hello %s %s", firstname, lastname)
	})
	router.Run(":8080")
}
```

```
curl "http://127.0.0.1:8080/welcome?name=zhangsan&address=beijing&lastname=lisi&firstname=wangwu"

Hello wangwu lisi
```

### 路由重定向

```go
package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func main()  {
	router := gin.Default()

	// 路由重定向 重定向到其他域名
	router.GET("/bd", func(c *gin.Context) {
		c.Redirect(http.StatusMovedPermanently, "http://www.baidu.com/")
	})

	// 重定向到其他子路径 访问/foo 重定向到/test
	router.GET("/foo", func(c *gin.Context) {
		c.Redirect(http.StatusFound, "/test")
	})

	/*
	方法重定向 访问 /test 转发到 /test2 并且调用他的处理函数
	这样路由不会被重定向到/test2 而且也能返回test2的内容
	 */
	router.GET("/test", func(c *gin.Context) {
		c.Request.URL.Path = "/test2"
		router.HandleContext(c)
	})
	router.GET("/test2", func(c *gin.Context) {
		c.JSON(200, gin.H{"hello": "world"})
	})
	router.Run(":8080")
}
```

### 同时运行多个服务

[运行多个服务 |杜松子酒网络框架 (gin-gonic.com)](https://gin-gonic.com/docs/examples/run-multiple-service/)

### 读取静态文件

```go
package main

import (
	"github.com/gin-gonic/gin"
	"net/http"
)

func main() {
	router := gin.Default()
	// 访问 /assets 的时候 从 ./assets目录下找文件 assets/css/style.css -> ./assets/css/style.css
	router.Static("/assets", "./assets")
	// 请求 more_static/css/style.css 从 my_file_system/css/style.css 读取
	router.StaticFS("/more_static", http.Dir("my_file_system"))
	// 直接返回文件 请求 /favicon.ico 文件 读取./resources/favicon.ico 返回
	router.StaticFile("/favicon.ico", "./resources/favicon.ico")

	// Listen and serve on 0.0.0.0:8080
	router.Run(":8080")
}
```

### 设置cookie

```go
package main

import (
	"fmt"

	"github.com/gin-gonic/gin"
)

func main() {

	router := gin.Default()

	router.GET("/cookie", func(c *gin.Context) {

		// 先获取cookie的gin_cookie字段 
		cookie, err := c.Cookie("gin_cookie")
		// 如果从cookie中获取不到 那么则需要设置cookie
		if err != nil {
			cookie = "NotSet"
			// 先将cookie赋值上字符串 然后SetCookie配置Cookie的 name和 value 指定过期时间 生效路径 生效域名
			c.SetCookie("gin_cookie", "test", 3600, "/", "localhost", false, true)
		}
		fmt.Printf("Cookie value: %s \n", cookie)
	})

	router.Run()
}
```

> 这样,在浏览器的控制台 就能看到一个gin_cookie的字段了(需要请求两次).


### 上传文件

#### 上传多个文件

```go
package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
	"log"
	"net/http"
)

func main() {
	router := gin.Default()

	// 设置一个更低的内存限制，用于对多部分表单进行解析（默认为 32 MiB）
	router.MaxMultipartMemory = 8 << 20 // 8 MiB

	// 注册一个 POST 请求路由 /upload
	router.POST("/upload", func(c *gin.Context) {
		// 处理多部分表单数据
		form, err := c.MultipartForm()
		if err != nil {
			c.String(http.StatusBadRequest, "Error: %s", err.Error())
			return
		}
		files := form.File["upload[]"]

		// 遍历文件列表并逐个保存到服务器
		for _, file := range files {
			log.Println(file.Filename)

			// 将上传的文件保存到指定目录下
			dst := "./" + file.Filename
			c.SaveUploadedFile(file, dst)
		}

		// 返回上传成功的文件数目
		c.String(http.StatusOK, fmt.Sprintf("%d files uploaded!", len(files)))
	})

	// 启动 HTTP 服务并监听 8080 端口
	router.Run(":8080")
}
```

```shell
curl -X POST http://localhost:8080/upload -F "upload[]=@F:\桌面快捷方式\项目.txt" -F "upload[]=@F:\桌面快捷方式\婚姻和事业.txt" -H "Content-Type: multipart/form-data"
```

#### 上传单个文件

> 代码有问题 暂时不修改


```go
func main() {
	router := gin.Default()
	// Set a lower memory limit for multipart forms (default is 32 MiB)
	router.MaxMultipartMemory = 8 << 20  // 8 MiB
	router.POST("/upload", func(c *gin.Context) {
		// single file
		file, _ := c.FormFile("file")
		log.Println(file.Filename)

		// Upload the file to specific dst.
		c.SaveUploadedFile(file, dst)

		c.String(http.StatusOK, fmt.Sprintf("'%s' uploaded!", file.Filename))
	})
	router.Run(":8080")
}
```

### 下载文件

```go
package main

import (
	"fmt"
	"github.com/gin-gonic/gin"
)

func main() {
	router := gin.Default()

	// 注册一个 GET 请求路由 /download
	router.GET("/download", func(c *gin.Context) {
		// 下载指定路径下的文件
		filePath := "F:\\GoProject\\数据结构\\main\\main.exe"
		// 设置响应头 配置下载的文件名字
		c.Header("Content-Disposition", fmt.Sprintf("attachment; filename=%s", "main.exe"))
		c.File(filePath)
	})

	// 启动 HTTP 服务并监听 8080 端口
	router.Run(":8080")
}
```

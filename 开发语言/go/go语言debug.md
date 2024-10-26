# golang的debug

[官方地址](https://github.com/go-delve/delve)

## 安装dlv

```shell
go install github.com/go-delve/delve/cmd/dlv@latest
echo 'export PATH=${PATH}:$(go env GOPATH)/bin' >> /etc/profile
source /etc/profile
```

## 使用

### debug正在运行的进程

```shell
dlv attach 2898097
```

### 直接启动

```shell
dlv exec ./main.exe -- --config document/config_company.yaml
# -- 后面跟原有命令的参数
```

示例 dlv kubeadm

需要添加编译参数
```shell
make WHAT="cmd/kube-apiserver" DBG=1
```

```shell
dlv exec $(which kubeadm) -- init --config Kubernetes-cluster.yaml
b main.main
```

## 翻译

### 命令
```shell
Delve 是 Go 程序的源代码级调试器。
﻿
Delve 使您能够通过控制进程的执行来与程序进行交互，
评估变量，并提供线程/goroutine状态、CPU寄存器状态等信息。
﻿
该工具的目标是提供一个简单但功能强大的界面来调试 Go 程序。
﻿
使用“--”将标志传递给您正在调试的程序，例如：
﻿
`dlv exec ./hello --server --config conf/config.toml`

可用命令:
    attach      附加到正在运行的进程并开始调试。
    completion  为指定的shell生成自动补全脚本。
    connect     通过终端客户端连接到无头调试服务器。
    core        检查一个核心转储。
    dap         启动一个通过调试适配器协议（DAP）进行通信的无头TCP服务器。
    debug       在当前目录编译并开始调试主包，或指定的包。
    exec        执行一个预编译的二进制文件，并开始一个调试会话。
    help        关于任何命令的帮助。
    test        编译测试二进制文件并开始调试程序。
    trace       编译并开始追踪程序。
    version     打印版本信息。

其他主题帮助:
    dlv backend    关于--backend标志的帮助信息。
    dlv log        关于日志标志的帮助信息。
    dlv redirect   关于文件重定向的帮助信息。
```

#### attach

```shell
dlv attach 命令用于附加到已经运行的进程并开始对它进行调试。

这个命令使Delve接管一个已经运行的进程，并开始一个新的调试会话。当退出调试会话时，你将有选项让进程继续运行或是终止它。

使用方法:
  dlv attach pid [executable] [flags]

标志:
      --continue                 启动时继续被调试的进程。
  -h, --help                     attach命令的帮助信息。
      --waitfor string           等待一个以此前缀开头的进程名。
      --waitfor-duration float   等待进程的总时间。
      --waitfor-interval float   检查进程列表的间隔时间，以毫秒为单位 (默认1)。

全局标志:
      --accept-multiclient               允许无头服务器通过JSON-RPC或DAP接受多个客户端连接。
      --allow-non-terminal-interactive   允许Delve的交互式会话不使用终端作为标准输入、输出和错误输出。
      --api-version int                  在无头模式下选择JSON-RPC API版本。新客户端应使用v2。可以通过RPCServer.SetApiVersion重新设置。参见Documentation/api/json-rpc/README.md。(默认1)
      --backend string                   后端选择(见'dlv help backend')。(默认"default")
      --check-go-version                 如果使用的Go版本与Delve的版本不兼容（太旧或太新），则退出。(默认true)
      --headless                         仅运行调试服务器，以无头模式。服务器将接受JSON-RPC或DAP客户端连接。
      --init string                      终端客户端执行的初始化文件。
  -l, --listen string                    调试服务器监听地址。使用'unix:'前缀可以使用Unix域套接字。(默认"127.0.0.1:0")
      --log                              启用调试服务器日志记录。
      --log-dest string                  将日志写入指定的文件或文件描述符(见'dlv help log')。
      --log-output string                应产生调试输出的组件的逗号分隔列表(见'dlv help log')
      --only-same-user                   仅允许启动此Delve实例的同一用户的连接。(默认true)
```

#### completion

```shell
为dlv生成指定shell的自动补全脚本。有关如何使用生成的脚本的详细信息，请参阅每个子命令的帮助。

使用方法:
  dlv completion [command]

可用命令:
  bash        为bash生成自动补全脚本
  fish        为fish生成自动补全脚本
  powershell  为powershell生成自动补全脚本
  zsh         为zsh生成自动补全脚本

标志:
  -h, --help   自动补全命令的帮助信息

全局标志:
      --accept-multiclient               允许无头服务器通过JSON-RPC或DAP接受多个客户端连接。
      --allow-non-terminal-interactive   允许Delve的交互式会话不使用终端作为标准输入、输出和错误输出。
      --api-version int                  在无头模式下选择JSON-RPC API版本。新客户端应使用v2。可以通过RPCServer.SetApiVersion重新设置。参见Documentation/api/json-rpc/README.md。(默认1)
      --backend string                   后端选择(见'dlv help backend')。(默认"default")
      --build-flags string               构建标志，传递给编译器。例如: --build-flags="-tags=integration -mod=vendor -cover -v"
      --check-go-version                 如果使用的Go版本与Delve的版本不兼容（太旧或太新），则退出。(默认true)
      --disable-aslr                     禁用地址空间随机化
      --headless                         仅运行调试服务器，以无头模式。服务器将接受JSON-RPC或DAP客户端连接。
      --init string                      终端客户端执行的初始化文件。
  -l, --listen string                    调试服务器监听地址。使用'unix:'前缀可以使用Unix域套接字。(默认"127.0.0.1:0")
      --log                              启用调试服务器日志记录。
      --log-dest string                  将日志写入指定的文件或文件描述符(见'dlv help log')。
      --log-output string                应产生调试输出的组件的逗号分隔列表(见'dlv help log')
      --only-same-user                   仅允许启动此Delve实例的同一用户的连接。(默认true)
  -r, --redirect stringArray             指定目标进程的重定向规则(见'dlv help redirect')
      --wd string                        运行程序的工作目录。

使用 "dlv completion [command] --help" 获取有关命令的更多信息。
```

#### connect

```shell
使用终端客户端连接到正在运行的无头调试服务器。使用'unix:'前缀以使用Unix域套接字。

使用方法:
  dlv connect addr [flags]

标志:
  -h, --help   连接命令的帮助信息

全局标志:
      --backend string      后端选择(见'dlv help backend')。(默认"default")
      --init string         终端客户端执行的初始化文件。
      --log                 启用调试服务器日志记录。
      --log-dest string     将日志写入指定的文件或文件描述符(见'dlv help log')。
      --log-output string   应产生调试输出的组件的逗号分隔列表(见'dlv help log')
```

#### core

```shell
检查核心转储（仅支持Linux和Windows核心转储）。

core命令将打开指定的核心文件和相关的可执行文件，并让你检查核心转储拍摄时进程的状态。

目前支持linux/amd64和linux/arm64核心文件，windows/amd64最小转储和由Delve的'dump'命令生成的核心文件。

使用方法:
  dlv core <executable> <core> [flags]

标志:
  -h, --help   核心命令的帮助信息

全局标志:
      --accept-multiclient               允许无头服务器通过JSON-RPC或DAP接受多个客户端连接。
      --allow-non-terminal-interactive   允许Delve的交互式会话不使用终端作为标准输入、输出和错误输出。
      --api-version int                  在无头模式下选择JSON-RPC API版本。新客户端应使用v2。可以通过RPCServer.SetApiVersion重新设置。参见Documentation/api/json-rpc/README.md。(默认1)
      --check-go-version                 如果使用的Go版本与Delve的版本不兼容（太旧或太新），则退出。(默认true)
      --headless                         仅运行调试服务器，以无头模式。服务器将接受JSON-RPC或DAP客户端连接。
      --init string                      终端客户端执行的初始化文件。
  -l, --listen string                    调试服务器监听地址。使用'unix:'前缀可以使用Unix域套接字。(默认"127.0.0.1:0")
      --log                              启用调试服务器日志记录。
      --log-dest string                  将日志写入指定的文件或文件描述符(见'dlv help log')。
      --log-output string                应产生调试输出的组件的逗号分隔列表(见'dlv help log')
      --only-same-user                   仅允许启动此Delve实例的同一用户的连接。(默认true)
```

### 参数

```shell
以下命令可用:

运行程序:
    call ------------------------ 恢复进程，注入函数调用（实验！！！）
    continue (alias: c) --------- 运行直到断点或程序终止。
    next (alias: n) ------------- 跳到下一行源代码。
    rebuild --------------------- 重建目标可执行文件并重新启动它。 如果可执行文件不是由 delve 构建的，则它不起作用。
    restart (alias: r) ---------- 重新启动进程。
    step (alias: s) ------------- 单步执行程序。
    step-instruction (alias: si)  单步执行单个 cpu 指令。
    stepout (alias: so) --------- 跳出当前函数。

Manipulating breakpoints:
    break (alias: b) ------- 设置断点。
    breakpoints (alias: bp)  打印出活动断点的信息。
    clear ------------------ 删除断点。
    clearall --------------- 删除所有断点。
    condition (alias: cond)  设置断点条件。
    on --------------------- 当遇到断点时执行命令。
    toggle ----------------- Toggles on or off a breakpoint.
    trace (alias: t) ------- 设置跟踪点。
    watch ------------------ 设置观察点。

Viewing program variables and memory:
    args ----------------- 打印函数参数。
    display -------------- 每次程序停止时打印表达式的值。
    examinemem (alias: x)  检查给定地址处的原始内存。
    locals --------------- 打印局部变量。
    print (alias: p) ----- 计算表达式的值。
    regs ----------------- 打印CPU寄存器的内容。
    set ------------------ 更改变量的值。
    vars ----------------- 打印包变量。
    whatis --------------- 打印表达式的类型。

Listing and switching between threads and goroutines:
    goroutine (alias: gr) -- 显示或更改当前的goroutine。
    goroutines (alias: grs)  列出程序的所有goroutine。
    thread (alias: tr) ----- 切换到指定的线程。
    threads ---------------- 打印跟踪的每个线程的信息。

Viewing the call stack and selecting frames:
    deferred --------- 在延迟调用的上下文中执行命令。
    down ------------- 将当前帧向下移动。
    frame ------------ 设置当前帧，或在另一个帧上执行命令。
    stack (alias: bt)  打印堆栈跟踪。
    up --------------- 将当前帧向上移动。

Other commands:
    config --------------------- 更改配置参数。
    disassemble (alias: disass)  反汇编器。
    dump ----------------------- 从当前进程状态创建核心转储。
    edit (alias: ed) ----------- 在$DELVE_EDITOR或$EDITOR中打开当前位置。
    exit (alias: quit | q) ----- 退出调试器。
    funcs ---------------------- 打印函数列表。
    help (alias: h) ------------ 打印帮助信息。
    libraries ------------------ 列出加载的动态库。
    list (alias: ls | l) ------- 显示源代码。
    packages ------------------- 打印包列表。
    source --------------------- 执行包含一系列delve命令的文件。
    sources -------------------- 打印源文件列表。
    target --------------------- 管理子进程调试。
    transcript ----------------- 将命令输出附加到文件中。
    types ---------------------- 打印类型列表。
```
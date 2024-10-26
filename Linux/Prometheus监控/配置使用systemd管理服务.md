# 使用systemd管理服务

以Prometheus为例,服务安装在/opt/prometheus目录下.



创建文件:`/etc/systemd/system/prometheus.service`

```
[Unit]
Description=prometheus monitor Service
After=network.target

[Service]
ExecStart=/opt/prometheus/prometheus-2.53.1.linux-amd64/prometheus --config.file /opt/prometheus/prometheus-2.53.1.linux-amd64/prometheus.yml
ExecStop=kill `ps -ef|grep "[p]rometheus"|awk '{print $2}'`
Restart=always
User=root
Group=root
Environment="VAR1=value1" "VAR2=value2"

[Install]
WantedBy=multi-user.target
```

更新systemd服务

```shell
systemctl daemon-reload
```

## 解析

- [Unit] :包含描述和服务依赖项
  - Description: 对这个服务的描述
  - After: 服务启动顺序,在指定的服务启动完成后启动
- [Service] :定义服务启动命令 运行用户等
  - ExecStart: 服务启动命令,也可以是可执行的脚本文件
  - ExecStop: 服务停止命令
  - ExecReload: 重新加载服务的命令
  - Restart: 服务的重启策略,可选`no`(不重启)`always`(总是重启)`on-failure`(只有非零退出时重启)
  - User: 运行服务的用户
  - Group: 运行服务的组
  - Environment: 设置环境变量,用法`Environment="VAR1=value1" "VAR2=value2"`这里定义的环境变量既可以在ExecStart等参数中使用,也可以在运行的服务中获取到
  - WorkingDirectory: 服务的工作目录
  - Type: 服务的启动类型,可选:`simple`默认类型,ExecStart启动的为主进程,`forking`派生一个子进程,服务在子进程中运行`oneshot`一次性进程`notify`进程启动后会向systemd发送通知
  - ExecStartPre: 启动前执行的命令
  - ExecStartPost: 启动之后执行的命令
  - TimeoutStartSec: 定义启动超时的时间
  - TimeoutStopSec: 定义停止超时的时间
- [Install] : 定义了服务的目标
  - WantedBy: 定义服务依赖关系,当启用该服务时,它会被添加到这个目标中,常用目标:`multi-user.target`多用户模式和`graphical.target`图形页面模式
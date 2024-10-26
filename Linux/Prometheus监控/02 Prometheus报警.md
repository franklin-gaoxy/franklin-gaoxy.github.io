# Prometheus报警

告警需要通过alertManager来实现,alertmanager可以对告警进行区分,控制发送时间,发送间隔,以及分组告警发送到不同邮箱等.

## 添加监控项

首先需要在Prometheus添加一些监控指标

监控指标为了便于区分 相关配置放在`config/alert/*.yml`下面或许会存放许多指标,如`node.yaml`,`app.yaml`等

prometheus.yml

```yaml
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
alerting:
  alertmanagers:
    - static_configs:
        - targets:
           - 192.168.137.100:9093 # 这里定义altermanager的地址和端口
rule_files:
  - "config/alert/*.yml" # 这里读取对应监控的配置
scrape_configs:
  - job_name: "prometheus"
    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "local node"
    static_configs:
      - targets: ['localhost:9100']
        labels:
          group: 'test'
      - targets: ["10.0.0.100:9000","10.0.0.101:9000"]
        labels:
          group: 'prod'
```

这里只添加了一个配置文件

`config/alert/node.yml`

```yaml
groups:
- name: node cpu montior
  rules:
  - alert: CPU User Use # name
    expr: sum(node_cpu_seconds_total{job='local node',mode='user'}) > 10 # 规则 大于10则触发
    for: 10m # 持续时间 持续10m则报警
    labels:
      severity: page # 标签 定义级别 key和value可以是任意内容
    annotations:
      description: cpu_user_use # 描述字段 key和value可以是任意内容
  - alert: CPU Idle Use
    expr: sum(node_cpu_seconds_total{job='local node',mode='idle'}) > 10000
    for: 10m
    labels:
      severity: page
    annotations:
      description: cpu_idle_use
```

## 安装alertmanager

```shell
wget https://github.com/prometheus/alertmanager/releases/download/v0.27.0/alertmanager-0.27.0.linux-amd64.tar.gz
tar xf alertmanager-0.27.0.linux-amd64.tar.gz -C /opt/prometheus/
```

进入目录,修改配置文件`alertmanager.yml`

```yaml
global:
  # 使用邮箱告警
  smtp_smarthost: 'smtp.163.com:25'
  smtp_from: 'gxiuyang@163.com'
  smtp_auth_username: 'gxiuyang@163.com'
  smtp_auth_password: 'XBOUCKSJGHHRIOJE'
  smtp_require_tls: true
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'email-receiver'
receivers:
  - name: 'web.hook'
    webhook_configs:
      - url: 'http://127.0.0.1:5001/'
  - name: 'email-receiver'
    email_configs:
      - to: 'gxiuyang@163.com'
        send_resolved: true
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

> 这里在global下面配置了邮箱告警

1. **global**:

   - 配置全局参数，包括 SMTP 配置。
   - `smtp_smarthost`: SMTP 服务器地址和端口，例如 `smtp.example.com:587`。
   - `smtp_from`: 发送告警邮件的发件人地址。
   - `smtp_auth_username`: SMTP 服务器的用户名，通常是你的邮箱地址。
   - `smtp_auth_password`: SMTP 服务器的密码。
   - `smtp_require_tls`: 是否要求使用 TLS 加密，通常设为 `true`。

2. **route**:

   - 配置告警路由规则。
   - `group_by`: 告警分组标签。
   - `group_wait`: 初始等待时间，等待收集更多告警。
   - `group_interval`: 分组发送间隔时间。
   - `repeat_interval`: 相同告警重复发送的间隔时间,间隔1小时发送一次。
   - `receiver`: 默认接收器名称，这里是 `email-receiver`。

3. **receivers**:

   - 配置告警接收器。

   - `name`: 接收器名称，这里是 `email-receiver`。

   - ```
     email_configs
     ```

     : 配置邮件发送。

     - `to`: 收件人邮箱地址，可以配置多个收件人，用逗号分隔。
     - `send_resolved`: 是否发送告警已解决的通知，设为 `true` 表示发送。

4. **inhibit_rules**:

   - 配置告警抑制规则。
   - `source_match`: 源告警条件，`severity: 'critical'` 表示严重度为 `critical` 的告警。
   - `target_match`: 目标告警条件，`severity: 'warning'` 表示严重度为 `warning` 的告警。
   - `equal`: 相同标签的条件，只有源告警和目标告警具有相同的 `alertname`、`dev` 和 `instance` 标签时，抑制规则才生效。

## AlertManager添加到systemd

```shell
cat >/etc/systemd/system/alertmanager.service<<EOF
[Unit]
Description=prometheus alert manager Service
After=network.target

[Service]
ExecStart=/opt/prometheus/alertmanager-0.27.0.linux-amd64/alertmanager --config.file=/opt/prometheus/alertmanager-0.27.0.linux-amd64/alertmanager.yml
ExecStop=kill `ps -ef|grep "[a]lertmanager"|awk '{print $2}'`
Restart=always
User=root
Group=root
Environment="VAR1=value1" "VAR2=value2"
WorkingDirectory=/opt/prometheus/alertmanager-0.27.0.linux-amd64/

[Install]
WantedBy=multi-user.target
EOF
```

```shell
systemctl daemon-reload
```

```shell
systemctl start alertmanager.service
```

# 分组告警

AlertManager支持根据不同标签或者不同级别区分告警

alertmanager.yml

```yaml
global:
  resolve_timeout: 5m
route:
  group_by: ['alertname']
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: 'local-email' # 默认渠道
  # 分组
  routes:
    - receiver: 'local-email'
      match_re:
        severity: critical
    - receiver: 'remote-email'
      # 使用正则匹配
      match_re:
        severity: warning # 如果标签存在serverity: warning 则使用此渠道 也可以写作 *.xxx等匹配内容
    - receiver: 'remote-email'
      # 直接匹配固定的标签
      match:
        group: prod # 如果标签存在group:prod 则使用此渠道
receivers:
  - name: 'local-email'
    email_configs:
      - to: 'gxiuyang@163.com'
        send_resolved: true
        smarthost: 'smtp.163.com:25'
        from: 'gxiuyang@163.com'
        auth_username: 'gxiuyang@163.com'
        auth_password: 'XBOUCKSJGHHRIOJE'
  - name: 'remote-email'
    email_configs:
      - to: '528909316@qq.com'
        send_resolved: true
        smarthost: 'smtp.163.com:25'
        from: 'gxiuyang@163.com'
        auth_username: 'gxiuyang@163.com'
        auth_password: 'XBOUCKSJGHHRIOJE'
inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
```

`prometheus.yml`

```shell
# my global config
global:
  scrape_interval: 15s # Set the scrape interval to every 15 seconds. Default is every 1 minute.
  evaluation_interval: 15s # Evaluate rules every 15 seconds. The default is every 1 minute.
  # scrape_timeout is set to the global default (10s).

# Alertmanager configuration
alerting:
  alertmanagers:
    - static_configs:
        - targets:
           - 192.168.137.100:9093

# Load rules once and periodically evaluate them according to the global 'evaluation_interval'.
rule_files:
  - "config/alter/*.yml"
  # - "first_rules.yml"
  # - "second_rules.yml"

# A scrape configuration containing exactly one endpoint to scrape:
# Here it's Prometheus itself.
scrape_configs:
  # The job name is added as a label `job=<job_name>` to any timeseries scraped from this config.
  - job_name: "prometheus"

    # metrics_path defaults to '/metrics'
    # scheme defaults to 'http'.

    static_configs:
      - targets: ["localhost:9090"]
  - job_name: "local node"
    static_configs:
      - targets: ['localhost:9100']
        labels:
          group: 'test'
  - job_name: "remote node"
    static_configs:
      - targets: ["10.0.0.100:9000","10.0.0.101:9000"]
        labels:
          group: 'prod'
          instance: '100-101'
```

`config/alter/node.yml`

```yaml
groups:
- name: node cpu montior
  rules:
  - alert: CPU User Use
    expr: sum(node_cpu_seconds_total{job='local node',mode='user'}) > 10
    for: 10m
    labels:
      severity: page
    annotations:
      description: cpu_user_use > 10
  - alert: CPU Idle Use
    expr: sum(node_cpu_seconds_total{job='local node',mode='idle'}) > 10000
    for: 10m
    labels:
      severity: page
    annotations:
      description: cpu_idle_use > 1000
- name: node_down
  rules:
  - alert: InstanceDown
    expr: up == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Instance {{ $labels.instance }} down"
      description: "{{ $labels.instance }} of job {{ $labels.job }} has been down for more than 5 minutes."
- name: prometheus server running
  rules:
  - alert: prometheus server is running
    expr: prometheus_ready == 1
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "prometheus is running!"
      description: "prometheus server is running!"
```


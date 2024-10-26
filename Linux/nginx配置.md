
#### 监听端口转发到其他端口 同时去除二级目录
```nginx
server {
    listen 81;
    server_name _;

    location /server/ {
        # 参见注释一
        rewrite ^/server(/.*) $1 break;
        proxy_pass http://localhost:8081/;
        proxy_set_header Host $host;
    }

    # 其他配置项...
}
```
> 注释一: rewrite表示重写路径. 然后匹配^/server 开头的地址,(/.*)表示捕获剩余部分.$1表示捕获到的剩余地址,作为$1的值.
> 然后$1的值会被拼接在 proxy_pass 后面,所以 http://domain.com/server/api/.... 会被重写为 /api/....
> 如果^/server(/.*) 写作了 ^/server/(.*) , 那么 http://domain.com/server/api/.... 会被重写为 api/....

#### 监听端口并实现带密码的文件服务器
创建密码文件
```shell
sudo htpasswd -c /etc/nginx/.htpasswd username
```
```nginx
server {
    listen 80;
    server_name example.com;  # 替换为你的域名

    location / {
        auth_basic "Restricted Content";  # 设置认证提示信息
        auth_basic_user_file /etc/nginx/.htpasswd;  # 指定密码文件路径

        autoindex on;  # 启用目录自动索引
        autoindex_exact_size off;  # 允许目录中文件大小显示约数
        autoindex_localtime on;  # 显示文件的本地时间

        root /path/to/your/files;  # 替换为你的文件目录路径
    }
}
```
#### 服务配置
```nginx
server {
        listen 443 ssl;   
        server_name _; 
        # 启用SSL
        ssl_certificate /etc/nginx/HTTPS/server.crt;  
        ssl_certificate_key /etc/nginx/HTTPS/server.key; 
        ssl_session_timeout 5m;
        ssl_protocols TLSv1.2; 
				ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:ECDHE:ECDH:AES:HIGH:!NULL:!aNULL:!MD5:!ADH:!RC4;
        ssl_prefer_server_ciphers on;
      	add_header Strict-Transport-Security "max-age=31536000; includeSubdomains; preload";
      	add_header X-Frame-Options SAMEORIGIN;
        # 启用gzip压缩
      	gzip on;
      	gzip_min_length 10k;
      	gzip_buffers 10 16k;
      	gzip_http_version 1.1;
      	gzip_comp_level 9;
        # 需要gzip压缩的文件类型
      	gzip_types text/plain application/x-javascript text/css application/xml text/javascript application/x-httpd-php application/javascript application/json html htm;
      	gzip_vary on; 
        location / {
            # 监听目录
            root   /html/kod;
            index  index.html index.php;
            # 请求*.php的 转发到9000端口
            location ~ \.php$ {
                root   /html/kod;
                fastcgi_index index.php;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                fastcgi_pass  127.0.0.1:9000;
                fastcgi_param HTTPS on; 
                include fastcgi_params;
            }
         }
}
server {
   listen 80;
   server_name _;
   # 重定向到443端口
   rewrite ^(.*)$ https://43.138.58.139 permanent;
}

```

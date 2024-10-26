# 关闭debug后静态文件无法访问问题
urls.py
```python
from django.urls import path,re_path
from django.contrib.staticfiles.views import serve
def return_static(request, path, insecure=True, **kwargs):
    return serve(request, path, insecure, **kwargs)
urlpatterns = [
    re_path('^static/(?P<path>.*)$',return_static, name = "static"),
]
```
# 导入单独目录的文件
目录结构
```python
DjangoProject
	bootstrap
	function # 单独目录的代码文件 不属于Django项目
    	test.py
	app # 应用目录
	DjangoProject
	templates
```
test.py文件:
```python
def test():
    print("this is a test function!")
```
views.py文件:
```python
from function import test
from django.view import View
from django.shortcuts import render,HttpResponse
class request(View):
    def get(self,request):
        # 调用test文件的函数
        test.test()
        # 返回页面
    	return render(request,"test.html")
```
# 常用配置
## 静态文件配置
settings.py
```python
# 静态文件访问url 比如现在的会请求 http://localhost:8000/django/static/
STATIC_URL = '/django/static/'

# 加入下面一行 表示从那个目录引入文件
STATICFILES_DIRS = [
    os.path.join(BASE_DIR,"bootstrap")
]
# 允许访问的主机列表
ALLOWED_HOSTS = ['*']
```
# 常用操作方法
```python
from django.shortcuts import render,HttpResponse,redirect
```
## 重定向
```python
return redirect("/django/login")
# or
return redirect("login") # 此处的login是urls.py文件中的别名 name="login"
```
## 返回字符串
```python
return HttpResponse("登陆失败!")
```
## 返回页面并传参
```python
# request 是函数传参 update_result.html 是页面 result_data是传参 dict类型
return render(request,"update_result.html",result_data)
```
## urls配置
```python
from django import views

urlpatterns = [
    path('sendemail/',views.sendemail.as_view(),name="sendemail"),
]
```
### 视图函数
```python
from django.views import View

class sendemail(View):
    def get(self,request):
        pass
    def post(self,request):
        pass
```
## cookie
### 设置cookie
```python
    def post(self,request):
        username = request.POST.get("username")
        password = request.POST.get("password")
        # 判断账号密码 正确则设置cookie 然后重定向到home页面
        if username == "qqq" and password == "qqq":
            # 注意: 这里的home为url的别名
            result = redirect("home")
            result.set_cookie("isLogin",True)
            return result
        else:
            return HttpResponse("登陆失败!")
```
### 检查cookie
```python
    def get(self,request):
        # 获取对应的cookie的值 然后判断是否为True
        cookie = request.COOKIES.get("isLogin")
        if bool(cookie) == True:
            # 是则返回home页面
            return render(request,"home.html")
        else:
            # 否则跳转到登录页 login为urls的别名
            return redirect("login")
```
## 读取POST表单提交数据
```python
from django.views import View
class sendemail(View):
    def post(self,request):
        title = request.POST.get("title")
        content = request.POST.get("content")
```
## 读取接口POST提交数据
```python
from django.views import View
from json import loads
class sendemail(View):
    def post(self,request)
        data = loads(request.body)
    	title = data.get("title")
    	content = data.get("content")
```
```shell
curl -X POST -d '{"title": "this is a title." ,"content": "this is a content"}' -H "Content-Type: application/json" <path>
```
# 配置静态文件
全图网online/全图网online/settings.py
```python
# 给下面的目录取得别名 使用的时候就是用/static/开头
STATIC_URL = '/static/'
# 加入下面一行 表示从那个目录引入文件 
STATICFILES_DIRS = [
    os.path.join(BASE_DIR,"bootstrap")
]
```
### 静态文件使用
```html
<link href="/static/css/bootstrap.min.css" rel="stylesheet">
```
或者
开头加入: 
```html
{% load static %}
```
```html
<link href="{% static "css/bootstrap.min.css" %}" rel="stylesheet">
```
### 基础框架
```html
{% load static %}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- 上述3个meta标签*必须*放在最前面，任何其他内容都*必须*跟随其后！ -->
    <title>bootstrap</title>
    <link href="{% static "css/bootstrap.min.css" %}" rel="stylesheet">
</head>
<body>




<!-- jQuery (Bootstrap 的所有 JavaScript 插件都依赖 jQuery，所以必须放在前边) -->
    <script src="{% static "jquery.js" %}"></script>
<!-- 加载 Bootstrap 的所有 JavaScript 插件。你也可以根据需要只加载单个插件。 -->
<script src="{% static "js/bootstrap.min.js" %}"></script>
</body>
</html>
```

### form表单
```html
<form action="/login/" method="post">
    {% csrf_token %}
    <h1>登陆页面</h1>
    <!-- 文本框和提交按钮 -->
    用户名: <input type="text" name="username">
    密码: <input type="text" name="password">
    <input type="submit">
</form>
```
## 模板
### 格式化变量
```html
<p>{{ nameDict }}</p>
<!-- 从字典中取一个值 -->
<p>从字典取值: {{ nameDict.money }}</p>
<!-- 从字典中取一个值 -->
<p>从列表中取值: {{ nameList.2 }}</p>
```
#### 格式化变量的更多方法
```html
<!-- 如果value为空 那么使用默认值 None -->
<p>{{ value|default:"None" }}</p>
<!-- 统计长度 -->
<p>{{ value|length }}</p>
<!-- 将大小格式化为更容易阅读的 如1MB 1GB-->
<p>{{ value|filesizeformat }}</p>
<!-- slice切片 -->
<p>{{ value|slice:"0,3" }}</p>
<!-- 时间格式化 传入参数为 datetime.datetime.now() -->
<p>{{ value|date:"Y-m-d H:i:s" }}</p>
<!-- 从字符串中删除字母"a" -->
<p>{{ value|cut:"a" }}</p>
<!-- 将字符串code 当做代码去处理 -->
<p>{{ code|safe }}</p>
```
## 标签
### for循环
```html
    {% for key,value in nameDict.items %}
        <li>{{ key }} -- {{ value }}</li>
        <!-- 当前循环的循环序号 从1开始 -->
        counter: {{ forloop.counter }}
        <!-- 从0开始 -->
        counter0: {{ forloop.counter0 }}
        <!-- 倒数 -->
        revcounter: {{ forloop.revcounter }}
        <!-- 判断是不是第一次 是返回True -->
        first: {{ forloop.first }}
        <!-- 判断是不是最后一次 -->
        last: {{ forloop.last }}

        <!-- if判断 如果是最后一次 那么则显示h5字体 -->
        {% if forloop.last %}
            <h5>hahaha</h5>
            {% else %}
            还没结束...
        {% endif %}
    {% endfor %}
```
### 判断
> 支持and ,or ,==,>=,<=,in,,not in ,is ,is not

```html
{% if 10 > 100 or 50 > 100 %}
<!-- 不满足条件的不会显示 -->
    <h3>10大于100或50大于100</h3>
{% elif 50 > 10 %}
    <h3>50大于10</h3>
{% endif %} 
```
#### 统计长度是否大于
```html
{% if nameList|length > 10 %}
<!-- 统计长度大于10则显示 -->
    <h3>10大于100或50大于100</h3>
{% endif %} 
```
# crfs
```html
    <!-- form表单中不能有别的无关杂项,如最开始<h1>在form表单中就不能使用 -->
    <form action="/app1/login/" method="post">
        {% csrf_token %}

        用户名: <input type="text" name="username">
        密码: <input type="password" name="password">
        <!-- input或者button都可以实现提交 -->
        <button>提交</button>
    </form>
```
# 配置页面不同样式
```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>base</title>

    <style>
        {#指定从页面边缘开始 不留空白#}
        body {
            margin: 0;
            padding: 0;
        }

        .nav {
        {#指定为蓝色#} background-color: blue;
            height: 40px;
        }

        {#    定义左侧菜单栏的样式#}
        .left-menu {
            background-color: aquamarine;
            color: blueviolet;
            width: 150px;
            height: 500px;
            float: left;
        }

        {#设置ul标签的间隔 间隔为0表示不留空 也就是左侧边栏的位置#}
        ul {
            margin: 0;
        }
        .content{
            width: 80%;
            float: right;
        }
        .clearfix{
            content: "";
            display: block;
            clear: both;
        }
    </style>
</head>
<body>
{#头部菜单栏#}
<div class="nav">
    <a href="">选项1</a>
    <a href="">选项2</a>
    <a href="">选项3</a>
    <a href="">选项4</a>
    <input type="text">
    <button>搜索</button>
</div>
{#左侧菜单栏#}
<div class="clearfix">
    <div class="left-menu">
        <ul>
            <li><a href="/app1/menu1/">菜单1</a></li>
            <li><a href="/app1/menu2/">菜单2</a></li>
        </ul>


    </div>
    {#其他页面填充内容#}
    <div class="content">
        {#继承核心位置 content为取名 可以随意 block里面的内容会被其他页面替换掉#}
        {% block content %}
            <h1>模板页面</h1>
        {% endblock %}
    </div>

</div>

</body>
</html>
```
# bootstrap
[bootstrap官网](https://v3.bootcss.com/components/#panels)

解压,然后下载jquery.js

[jquery.js](https://code.jquery.com/jquery-3.6.4.min.js)

目录结构:

```
bootstrap-3.4.1-dist
	css
	fonts
	js
	jquery.js
	index.html
```

index.html手动创建,基础内容:

```html
{% load static %}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <!-- 上述3个meta标签*必须*放在最前面，任何其他内容都*必须*跟随其后！ -->
    <title>bootstrap</title>
    <link href="{% static "css/bootstrap.min.css" %}" rel="stylesheet">
</head>
<body>

<!-- jQuery (Bootstrap 的所有 JavaScript 插件都依赖 jQuery，所以必须放在前边) -->
    <script src="{% static "jquery.js" %}"></script>
<!-- 加载 Bootstrap 的所有 JavaScript 插件。你也可以根据需要只加载单个插件。 -->
<script src="{% static "js/bootstrap.min.js" %}"></script>
</body>
</html>
```

##### 添加一个容器

```html
<div class="container"></div>
```

##### 靠右显示

使用 pull-right

```html
<button type="button" class="btn btn-success pull-right">下一步</button>
```

##### 修改宽度

col-sm-2表示列宽,如果加大可以col-sm-8,结尾数字变化

```html
<label for="inputname" class="col-sm-2 control-label">姓名</label>
```
# ORM
### 简单使用
```python
from django.db import models

# Create your models here.

# # create table userInfo
class userInfo(models.Model):
    # (id int primary key auto_increment) AutoField: 自增 primary_key = True:此列是主键
    id = models.AutoField(primary_key = True)
    # name varchar(10) CharField:字符串类型 最大10个字符
    name = models.CharField(max_length=10)
    # age int 数字类型
    age = models.IntegerField()
    # curr_date date 时间类型
    curr_date = models.DateField()
```
#### 初始化命令
```shell
# 创建记录
python manage.py makemigrations
# 执行语句 
python manage.py migrate
```
#### 其他可用字段
```python
CharField: 字符串字段，用于存储较短的文本数据。
TextField: 文本字段，用于存储较长的文本数据。
IntegerField: 整数字段，用于存储整数值。
FloatField: 浮点数字段，用于存储浮点数值。
BooleanField: 布尔字段，用于存储True或False值。
DateField: 日期字段，用于存储日期值。
DateTimeField: 日期时间字段，用于存储日期和时间值。
TimeField: 时间字段，用于存储时间值。
EmailField: 电子邮件字段，用于存储电子邮件地址。
URLField: URL字段，用于存储URL地址。
ForeignKey: 外键字段，用于与其他模型建立关系。
ManyToManyField: 多对多字段，用于表示多对多关系。
FileField: 文件字段，用于上传和存储文件。
ImageField: 图像字段，用于上传和存储图像文件。
```
#### 可传参数
```python
CharField:
max_length: 最大字符长度，默认为255。
unique: 是否唯一，默认为False。
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

TextField:
max_length: 最大字符长度，默认为None。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

IntegerField:
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

FloatField:
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

BooleanField:
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

DateField:
auto_now: 是否每次保存时自动更新为当前日期，默认为False。
auto_now_add: 是否在创建时自动设置为当前日期，默认为False。
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

DateTimeField:
auto_now: 是否每次保存时自动更新为当前日期和时间，默认为False。
auto_now_add: 是否在创建时自动设置为当前日期和时间，默认为False。
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

TimeField:
auto_now: 是否每次保存时自动更新为当前时间，默认为False。
auto_now_add: 是否在创建时自动设置为当前时间，默认为False。
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

EmailField:
max_length: 最大字符长度，默认为254。
unique: 是否唯一，默认为False。
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

URLField:
max_length: 最大字符长度，默认为200。
unique: 是否唯一，默认为False。
default: 默认值。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

ForeignKey:
to: 关联的目标模型。
on_delete: 级联删除行为，默认为CASCADE。
related_name: 设置反向关联名称。

ManyToManyField:
to: 关联的目标模型。
related_name: 设置反向关联名称。

FileField:
upload_to: 指定文件上传的目录路径。
max_length: 最大字符长度，默认为100。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。

ImageField:
upload_to: 指定图片上传的目录路径。
width_field: 图片宽度字段。
height_field: 图片高度字段。
max_length: 最大字符长度，默认为100。
blank: 是否可以为空，默认为False。
null: 是否可以为Null，默认为False。
```
### mysql类型使用
settings.py
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.mysql',
        'NAME': 'test', # 库名
        'USER': 'liulaoliu', # 用户
        'PASSWORD': 'MyNewPass4!', # 密码
        'HOST': '43.138.58.139', # 主机地址
        'PORT': 3306, # 端口
    }
}
```
/project/apps/__init__.py
```python
import pymysql
# 将Django连接MySQL的驱动(默认mysqldb,但他已经过时了)替换为pymysql
pymysql.install_as_MySQLdb()
```
```shell
pip install pymysql
python -m pip install pymysql
```
如果存在问题,可以尝试:
```python
import pymysql

pymysql.version_info = (1, 4, 13, "final", 0)
pymysql.install_as_MySQLdb()
```
### sqlite类型使用
settings.py
```python
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.sqlite3',
        'NAME': BASE_DIR / 'db.sqlite3',
    }
}
```
### 插入一条数据
```python
import datetime

from django.shortcuts import render
from django.shortcuts import HttpResponse

from app import models
# Create your views here.

def index(request):
    nowTime = datetime.datetime.now()
    # 创建一个对象 传入数据
    obj = models.userInfo(
        name="zhangsan",
        age=10,
        curr_date=nowTime
    )
    # 保存数据
    obj.save()

    return HttpResponse("<h1>index!<h1>")

```
### 查询一条数据
```python
        config_obj = models.config.objects.filter(id=1).first()
        if config_obj == None:
            return HttpResponse("error!")
        # password smtp_server 为数据库字段
        send_password = config_obj.password
        smtp_server = config_obj.smtp_server
        smtp_port = config_obj.smtp_port
        email = config_obj.email
```
# 新建app
```shell
python manage.py startapp myapp
```
在你的Django项目的`settings.py`文件中，找到`INSTALLED_APPS`配置项，并将新创建的app添加到其中。在INSTALLED_APPS配置项中添加myapp


```python
INSTALLED_APPS = [
    ...
    'myapp',
    ...
]
```
app迁移或者修改了表结构
```python
python manage.py makemigrations
python manage.py migrate
```

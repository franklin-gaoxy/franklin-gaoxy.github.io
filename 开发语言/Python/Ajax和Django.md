# Ajax

Ajax主要用于浏览器异步请求服务器获取一些数据,并添加到页面中.

## 基于jQuery Ajax配合Django实现的登录

首先需要配置静态目录,添加`jQuery.js`脚本文件,放在statics目录下.

配置Django `settings.py`.

```python
STATICFILES_DIRS = [
    os.path.join(BASE_DIR,"statics"),
]
```

`urls.py`文件

```python
from apps import views

urlpatterns = [
    path('admin/', admin.site.urls),
    path('login/', views.loginView.as_view()),
    path('index/', views.index),
]
```

`apps/views.py`

```python
from django.shortcuts import render,HttpResponse
from django.views import View
# Create your views here.

import json

class loginView(View):
    def get(self,requests):
        return render(requests,"login.html")
    def post(self,requests):
        username = requests.POST.get("username")
        password = requests.POST.get("password")
        if username == "liulaoliu" and password == "1qaz@WSX":
            jdata = json.dumps({"status":301,"redirect_url":"/index/"})
            # content_type="application/json" 设置响应头信息 传递的是一个json数据
            return HttpResponse(jdata,content_type="application/json")
        return HttpResponse(json.dumps({"status":600,"redirect_url":"账号或密码错误!"}),content_type="application/json")

def index(requests):
    return render(requests,"index.html")
```

也可以直接相应json数据

```python
from django.http import JsonResponse
data = {"name":"zhangsan","age",18}
# 这样连json序列化也不需要了
return JsonResponse(data)
```

`template/index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>首页</title>
</head>
<body>

<h1>首页!</h1>

</body>
</html>
```

`template/login.html`

```html
{% load static %}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>hello</title>
</head>
<body>

<h1>ajax登录</h1>

<form action="/login/" method="post">
    {% csrf_token %}
    用户名: <input type="text" id="username" name="username">
    密码: <input type="password" id="password" name="password">
    {#  此处form表单的按钮类型应该改为button 这样点击后才不会触发form表单的提交  #}
    <input type="button" id="sub" value="确认">
</form>

<script src="{% static 'jquery.js' %}"></script>
<script>
    $("#sub").click(function () {
            console.log("点击了按钮.")
            $.ajax({
                {#请求地址和请求类型#}
                url: "/login/",
                type: "post",
                {#data 传参 $("username") 找到对应的id的代码段 .val 取值#}
                data: {
                    username: $("#username").val(), password: $("#password").val(),
                    {# 此处为通过csrf认证机制 "[name=csrfmiddlewaretoken]"写法为标签选择器 获取name=csrfmiddlewaretoken对应的value #}
                    {# 源代码为:<input type="hidden" name="csrfmiddlewaretoken" value="Ryv...Bq5"> #}
                    csrfmiddlewaretoken: $("[name=csrfmiddlewaretoken]").val()
                    {# 也可以写作 csrfmiddlewaretoken: "{{ csrf_token }}" #}
                },
                {#res接收服务器返回数据#}
                success: function (res) {
                    {#写入到日志#}
                    console.log(res,typeof res);
                    {#转换为json数据 注意 如果本身就是JSON数据 那么不支持再次转换 #}
                    var jsonRes = JSON.parse(res);
                    if (jsonRes["status"] === 301) {
                        {#跳转到index页面 jsonRes["redirect_url"]为相应内容需要跳转的地址#}
                        location.href=jsonRes["redirect_url"];
                    } else if (jsonRes["status"] === 600) {
                        {#在form表单后面 添加输出账号密码错误内容#}
                        var spanEle = document.createElement("span");
                        $(spanEle).text(jsonRes["redirect_url"]);
                        $("form").append(spanEle);
                        {#弹窗提示 账号密码错误#}
                        window.alert(jsonRes["redirect_url"])
                    }
                },
                error: function (res) {
                    console.log("execute failed!")
                    console.log(res)
                }
            })
        }
    )
</script>

</body>
</html>
```

## 利用Ajax获取对象

`views.py`

```python
from django.http import JsonResponse
def data(requests):
    if requests.method == "POST":
        # 获取传入的json数据
        data = requests.body.decode("utf-8")
        print(data,type(data)) # {"name":"zhangsan","age":80} <class 'str'> 需要手动转换类型
        # 回复非json数据需要添加参数 safe=False 这样会强制序列化
        return JsonResponse(["zhangsan","lisi","wangwu"],safe=False)
    else:
        return render(requests,"data.html")
```

`data.html`

```html
{% load static %}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>data</title>
</head>
<body>

<h1>DATA!</h1>

<div class="container" id="data">
</div>

<script src="{% static 'jquery.js' %}"></script>
<script>
    $.ajax({
        url:"/data/",
        type: "post",
        // 传入请求数据 同时指定了格式为json类型
        data: JSON.stringify({"name":"zhangsan","age":80}),
        contentType: "application/json",
        success: function (res) {
            console.log(res)
            // 获取对应的div对象
            obj = document.getElementById("data");
            // 循环接收到的参数
            for (i in res){
                // 然后创建li对象 然后将循环的每个元素取值添加到新创建的对象里
                var newLi = document.createElement("li");
                newLi.append(res[i]);
                // 最后把添加好数据的li对象 加入到对应的div里面
                obj.append(newLi);
            }
        }
    })
</script>

</body>
</html>
```

> django没有处理接收json数据类型的模块.所以接收到的是string类型,需要手动转换.


## 文件上传

### form表单

`views.py`

```python
class upload(View):
    def get(self,requests):
        return render(requests,"upload.html")

    def post(self,requests):
        print(requests.POST)
        print(requests.FILES)
        # 指定获取的文件的 name代码字段
        fileObj = requests.FILES.get("head-pic")
        # 获取名称
        filename = fileObj.name
        # 写入文件
        with open(filename,mode="wb") as w:
            for i in fileObj:
                w.write(i)
            # 两种方式都可以 chuncks是每次读取64k 依次写入文件
            for i in fileObj.chuncks():
                w.write(i)
        return HttpResponse("end")
```

`upload.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>upload</title>
</head>
<body>

<h1>UPLOAD</h1>

{#enctype="multipart/form-data" 传输文件使用#}
<form action="/upload/" method="post" enctype="multipart/form-data">
    头像:<input type="file" name="head-pic">
    用户名: <input type="text" name="username">
    <input type="submit">
</form>

</body>
</html>
```

### ajax上传文件

`views.py`

```python
class upload(View):
    def get(self,requests):
        return render(requests,"upload.html")

    def post(self,requests):
        print(requests.POST)
        print(requests.FILES)
        # 指定获取的文件的 name代码字段
        fileObj = requests.FILES.get("head-pic")
        # 获取名称
        filename = fileObj.name
        # 写入文件
        with open(filename,mode="wb") as w:
            for i in fileObj:
                w.write(i)
            # 两种方式都可以 chuncks是每次读取64k 依次写入文件
            # for i in fileObj.chuncks():
            #     w.write(i)
        return HttpResponse("end")
```

`upload.html`

```html
{% load static %}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>upload</title>
</head>
<body>

<h1>UPLOAD</h1>

{#enctype="multipart/form-data" 传输文件使用#}
<form action="/upload/" method="post" enctype="multipart/form-data">
    头像:<input type="file" name="head-pic">
    用户名: <input type="text" name="username">
    <input type="submit">
</form>

<h1>ajax上传</h1>
文件: <input type="file" id="pfile">
用户名: <input type="text" id="ausername">
<button id="btn">提交</button>

<script src="{% static 'jquery.js' %}"></script>
<script>
    $('#btn').click(function (){
        // Ajax传输文件必须依靠 FormData
        var formdata = new FormData();
        // 用户名和文件信息传入FormData
        formdata.append("username",$("#ausername").val());
        formdata.append("head-pic",$("#pfile")[0].files[0]);
        console.log(formdata)
        $.ajax({
            url:"/upload/",
            type:"post",
            data: formdata, // 传入FormData
            processData: false, // 不处理数据
            contentType: false, //不设置内容类型
            success: function (res){
                console.log(res)
                window.alert("上传完成!");
            },
            error: function (res){
                console.log(res)
                window.alert("上传失败!")
            }
        })
    })
</script>

</body>
</html>
```

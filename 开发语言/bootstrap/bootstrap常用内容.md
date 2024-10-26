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
# 


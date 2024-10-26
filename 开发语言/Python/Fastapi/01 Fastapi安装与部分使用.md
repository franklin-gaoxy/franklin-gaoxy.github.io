# FastAPI

## 安装

```python
pip install uvicorn fastapi
```

## 使用

### 简单入门

```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/")
async def test():
    # 可以返回 List Dict string 等
    return {"message": "hello world!",}

if __name__ == '__main__':
    import uvicorn
    # 启动 app为 app=FastAPI()处实例化的变量
    uvicorn.run(app,host="0.0.0.0",port=8080)
```

### 路径参数

```python
from fastapi import FastAPI

app = FastAPI()

# 匹配一个变量 变量名称为 path 然后传入参数即可调用
@app.get("/{path}")
async def test(path):
    # 访问 http://127.0.0.1:8080/asd 返回 {"requestPath":"asd"}
    return {"requestPath": path}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8080)
```

> 注意：{path}只能匹配一个参数 也就是url中两个 / 中间的


匹配多层使用：

```python
from fastapi import FastAPI
from enum import Enum

class path(str,Enum):
    login = "login"
    admin = "admin"
    logout = "logout"

app = FastAPI()

@app.get("/files/{file_path:path}")
async def read_file(file_path: str):
    return {"file_path": file_path}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8080)
```

#### 预设值

```python
from fastapi import FastAPI
from enum import Enum

class path(str,Enum):
    login = "login"
    admin = "admin"
    logout = "logout"

app = FastAPI()

# 匹配一个变量 变量名称为 path 然后传入参数即可调用
@app.get("/{url}")
# url: path 表示接收一个url变量 类型为path 当然也可以使用 int string等类型指定他
async def test(url: path):
    '''
    根据不同的路径 做出不同的操作
    值得注意的是 当使用了此方法 访问的子路径必须是 class中存在的 否则报错
    取值方式除了下面的判断 还可以写作 if url.value == "login":
    :param url:
    :return:
    '''
    if url is path.login:
        return "不能访问login!"
    if url is path.admin:
        return "admin是后台管理,你没权限!"
    if url is path.logout:
        return "你都没有登陆,怎么能推出呢?"
    return "走到最后啦!"

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8080)
```

### url传参

访问地址:

> [http://127.0.0.1:8080/sum/?num1=20&num2=40](http://127.0.0.1:8080/sum/?num1=20&num2=40)


```python
from fastapi import FastAPI

app = FastAPI()

@app.get("/sum/")
# 接收两个参数 并转为数字类型 同时默认值为 0
async def test(num1: int = 0,num2: int = 0):
    # 如果两个数字都不为 0 那么则返回和 否则返回0
    if num1 != 0 and num2 != 0:
        return num1 + num2
    else:
        return 0

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8080)
```

返回结果

> 60


#### 可选参数 传入空参数

> [http://127.0.0.1:8080/sum/test?num1=20&num2=43&type=sum](http://127.0.0.1:8080/sum/test?num1=20&num2=43&type=sum)


```python
from fastapi import FastAPI
from typing import Union

app = FastAPI()

@app.get("/sum/{path}")
async def test(path: str,num1: int = 0,num2: int = 0,type : Union[str, None] = None):
    '''
    函数接受四个参数 同时 type参数可为空
    :param path: url中的路径参数 Fastapi会自动识别
    :param num1: 第一个数字 默认为0
    :param num2: 第二个数据 默认为0
    :param type: 类型.如sum会返回两个数字的和
    :return:
    '''
    if type:
        if type == "sum":
            return {"path": path,"sum": num1 + num2}
    return "没有传入计算类型哦"

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8080)
```

如上,代码会计算两个数字的和.

> 默认传入的参数都是string类型.只是指定了类型会被转换.


如果一个参数是必须的,那么可以写为:

```python
# 只要不指定默认类型 如 num1 和 num2 ,那么他就是必须的.
async def test(path: str,num1: int,num2: int,type : Union[str, None] = None):
```

请求测试:

```
http://127.0.0.1:8080/sum/aaa?num1=100&num2=30&type=sum
```

#### 查询参数类型转换

```python
from typing import Union
from fastapi import FastAPI

app = FastAPI()


@app.get("/items/{item_id}")
async def read_item(item_id: str, q: Union[str, None] = None, short: bool = False):
    # item_id 为路径参数 q和short均为可选传参
    item = {"item_id": item_id}
    # 如果 q 不为空 那么返回q
    if q:
        item.update({"q": q})
    # 如果 short 不为True 那么则返回description
    if not short:
        item.update(
            {"description": "This is an amazing item that has a long description"}
        )
    return item


if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8000)
```

请求地址

> [http://127.0.0.1:8000/items/aaaaa?short=True&q=qq](http://127.0.0.1:8000/items/aaaaa?short=True&q=qq)
>  
> [http://127.0.0.1:8000/items/aaaaa?short=1](http://127.0.0.1:8000/items/aaaaa?short=1)


#### 多个路径和查询参数

```python
from typing import Union
from fastapi import FastAPI

app = FastAPI()


@app.get("/user/{user_id}/group/{group_id}")
async def user(user_id: int,group_id: int,q : Union[str ,None] = None):
    if q:
        return {"q":q}
    return {"user id": user_id,"group id": group_id}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8000)
```

请求地址

> [http://127.0.0.1:8000/user/111/group/2254](http://127.0.0.1:8000/user/111/group/2254)


### 请求体

```python
from typing import Union
from fastapi import FastAPI
from pydantic import BaseModel

# 声明json
class JSONDATA(BaseModel):
    name : str
    # 如果为空 默认值为 0
    age : int = 0
    address : str
    # 可为空
    description : Union[str,None] = None

app = FastAPI()

@app.post("/user/")
# 接收一个JSONDATA类型的数据
async def user(jsondata: JSONDATA):
    return jsondata

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8000)
```

请求

```shell
curl -X 'POST' \
  'http://127.0.0.1:8000/user/' \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d '{
  "name": "zhangsan",
  "age": 30,
  "address": "china",
  "description": "none"
}'
```

### 参数校验

#### 长度校验

```python
from typing import Union
from fastapi import FastAPI,Query

app = FastAPI()
@app.get("/user")
async def task(q:Union[str,None] = Query(default=None,max_length=20)):
    '''
    接收一个参数q 可以为空 最大长度20
    :param q: string类型
    :return:
    '''
    # 没有传入q 返回null
    if not q:
        return {"data":None}
    # 返回q和长度
    return {"data":q,"lenth":len(q)}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8000)
```

#### 更多校验

```python
from typing import Union
from fastapi import FastAPI,Query

app = FastAPI()
@app.get("/user")
async def task(q:Union[str,None] = Query(default=None,max_length=20,min_length=5,pattern="^key.*value$")):
    '''
    接收一个参数q 可以为空 最大长度20 最小长度为5 同时使用正则表达式匹配
    :param q: string类型
    :return:
    '''
    # 没有传入q 返回null
    if not q:
        return {"data":None}
    # 返回q和长度
    return {"data":q,"lenth":len(q)}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8000)
```

请求

```
http://127.0.0.1:8000/user?q=keyaaaaaaavalue
```

#### 必须参数

```python
from typing import Union
from fastapi import FastAPI,Query

app = FastAPI()
@app.get("/user")
async def task(q = Query(max_length=20,min_length=5)):
    '''
    接收一个参数q 必须参数 最大长度20 最小长度为5
    :param q: string类型
    :return:
    '''
    # 没有传入q 返回null
    if not q:
        return {"data":None}
    # 返回q和长度
    return {"data":q,"lenth":len(q)}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8000)
```

#### 接收列表参数

```python
from typing import Union,List
from fastapi import FastAPI,Query

app = FastAPI()
@app.get("/user")
async def task(q: Union[List[str], None] = Query(default=None)):
    '''
    接收一个参数q 必须参数 列表类型
    :param q: ["string"]
    :return:
    '''
    # 返回q和长度
    return {"data":q,"lenth":len(q)}

if __name__ == '__main__':
    import uvicorn
    uvicorn.run(app,host="0.0.0.0",port=8000)
```

请求

> [http://127.0.0.1:8000/user?q=a&q=b&q=c](http://127.0.0.1:8000/user?q=a&q=b&q=c)

相应:
```
{"data":["a","b","c"],"lenth":3}
```

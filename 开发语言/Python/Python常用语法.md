# 多线程/多进程 相关
## 多进程
```python
from multiprocessing import Pool
# or
from concurrent.futures import ProcessPoolExecutor

def main():
    pool = Pool(10)
    for i in range(0,10):
        pool.apply_async(func=ProcessFunc,args=(i,))
def ProcessFunc(number):
    pass
```
## 基于类创建的多线程
```python
from threading import Thread

class mythread(Thread):
    def __init__(self,name):
        super().__init__()
        self.name = name
    def run(self):
        print("Hello! you is:",self.name)

if __name__ == '__main__':
    my = mythread(name='刘老六')
    my.start()
    print("运行结束")
```

## 一行代码
```python
[ a.join() for a in process_list ]
```
## 队列
### 先进先出
```python
import queue

d = queue.Queue(3)
d.put(1)
d.put(2)
d.put(3)
print(d.full())
try:
    d.put_nowait(4)
except Exception:
    print("插入第四个失败!")
print(d.get())
print(d.get())
print(d.get())
print("是否为空",d.empty())
try:
    d.get_nowait()
except Exception:
    print("获取第四个失败")
```
### 先进后出
```python
import queue
q = queue.LifoQueue(3)
q.put(1)
q.put(2)
q.put(3)
print(q.get())
print(q.get())
print(q.get())
```
## 线程池
### submit方式
```python
from threading import current_thread
from concurrent.futures import ThreadPoolExecutor,ProcessPoolExecutor
from time import sleep
def function_01(number):
    sleep(1)
    print("%s号线程开始启动!"%number)
    return number*number

if __name__ == '__main__':
    thread = ThreadPoolExecutor(4) # 默认数量是CPU核数的5倍
    list_1 = []
    for i in range(10):
        # 异步提交任务给线程池
        res = thread.submit(function_01,i)
        # 将返回结果加入到列表中
        list_1.append(res)
    # 等待线程池线程执行结束 否则运行程序直接结束 相当于多进程的close + join
    thread.shutdown()
    # 输出返回值
    for i in list_1:
        print(i.result())
    print("主线程结束")
```
### 异步提交
```python
# 异步提交任务 理念同进程池
from threading import current_thread
from concurrent.futures import ThreadPoolExecutor,ProcessPoolExecutor
from time import sleep
def function_01(number):
    sleep(1)
    print("%s号线程开始启动!"%number)

if __name__ == '__main__':
    thread = ThreadPoolExecutor(4) # 默认数量是CPU核数的5倍
    # 异步提交线程 同进程池,后面放置的必须是可迭代参数
    thread.map(function_01,range(10))
```
### 等待线程池运行结束
```python
thread.shutdown()
```
## 多进程

```python
from multiprocessing import Process

def functionA():
    print("this is a function A!")

if __name__ == '__main__':
    p1 = Process(target=functionA,args=())
    p1.start()
    p1.join()
```

# 爬虫相关
## POST传参
> 第一种: 传递表单或者原始数据.会将参数作为普通数据发送,

```python
from requests import Session
data = {"username":"gao","password":"123456"}
session = Session()
response = session.post(url="http://127.0.0.1",data=data)
```
> 第二种 传递json参数

```python
from requests import Session
jsondata = {"username":"gao","password":"123456"}
session = Session()
response = session.post(url="http://127.0.0.1",json=jsondata)
```
## userAgent

```python
headers = {
    'User-Agent':'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3766.400 QQBrowser/10.6.4163.400'
}
```

## 定义header头和传参数

```python
session = requests.Session()
headers = {'Content-Type':'application/json','User-Agent':'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/70.0.3538.25 Safari/537.36 Core/1.70.3861.400 QQBrowser/10.7.4313.400'}
dingUrlPath = 'https://oapi.dingtalk.com/robot/send'
dingToken = '1046b4f3b02eb65bd8bb9b4ace3cbf9ff1013b3448d427416660182fd71556b8'
data = {"msgtype": "text",
        "text": {"content": "【测试信息】spark任务 测试信息请忽略！"},
        "at": {"atMobiles": ['15369877965'],"isAtAll": 'false'}
                }
jsonData = json.dumps(data)
params = {"access_token":dingToken}
status = self.session.post(url=dingUrlPath,params=params,data=jsonData,headers=self.headers).content.decode('utf-8')
```

## 连接MySQL

```python
self.mydb = pymysql.connect(host='10.0.0.20',db='HostInformation',user='root',passwd='Sinobase@123')
self.cursor = self.mydb.cursor()
```

## 获取格式化时间

```python
print(time.strftime("%Y-%m-%d %H:%M:%S"))
print(time.strftime("%H"))
```

## 获取字符串位置和根据位置获取字符串

```
# ord 给出一个文字,他给出文字编码位置
print(ord("中"))
# 输出编码位置:20013
# chr 给出一个编码位,输出字
print(chr(20013))
# 输出:中
```

## re 正则表达式

```python
it = re.finditer("\d+", "baby123456789的电话号是: 185123456789")
```

## 
## Linux编译报错

```
https://www.baidu.com/link?url=uj1P1p2lb2EUJ4gnyOb0zgPk2pKEjTr9l8gC6_YhlqkfSrJyn-CAnt5o4Jqc6AgTAVq3LdqXJD718SulvOjV339coo_Sud2TuP7S6e5Foke&wd=&eqid=ff66ac1e00262aef00000003602a7429
yum install python3-devel
```

## flask

```python
from flask import Flask

api = Flask(__name__)
@api.route("/send",methods=['get'])
def sendMessage():
    pass

if __name__ == '__main__':
    api.run(port=9000,debug=True,host='127.0.0.1')
```

## 大文件的循环读取

```python
with open('SunloginClient_12.0.1.39931_x64.rar',mode="rb") as r:
    with open('sun.rar',mode="wb") as w:
        while True:
            data = r.read(1000)
            if not data:
                break
            w.write(data)
```
上面的操作有一个问题: 当文件中存在一个空行的时候,被读取出容易认为读取完成,从而关闭当前文件.
```python
with open("test.txt",mode="r",encoding="utf=8") as r:
    for index ,content in enumerate(r):
        # index 为行号 content为内容 读取到文件结束自动停止
        print("当前读取到第{}行,内容为:{}".format(index,content))
```
## 生成器
```python
def test():
    for i in range(0,1000):
        yield i
t = test()
print(t.__next__)
print(t.__next__)
print(t.__next__)
```
## 判断目录是否存在与创建多级目录
```python
if not os.path.exists(tmpPath):
	os.makedirs(tmpPath)
```
# 文件保存相关
## 保存和读取列表
### 方式1
```python
import pickle

alist = ["zhangsan","lisi","wangwu"]
with open("test.txt",mode="wb" ) as w:
    pickle.dump(alist,w)
with open("test.txt",mode="rb") as r:
    data = pickle.load(r)
print(data)
```
### 方式2
```python
import pickle

alist = ["zhangsan","lisi","wangwu"]
with open("test.txt",mode="w" ,encoding="utf-8") as w:
    w.write(str(alist))
with open("test.txt",mode="r",encoding="utf-8") as r:
    data = r.read()
# eval函数转换
data = eval(data)
print(data)
```
## 文件的递归压缩
```python
class test():
    def ZipPicture(self,DirectoryName):
        fileName = self.SavePath + DirectoryName + ".zip"
        with zipfile.ZipFile(fileName, 'w',zipfile.ZIP_DEFLATED) as target:
            for i in walk(self.SavePath + DirectoryName):
                print(i)
                for n in i[2]:
                    target.write(i[0] + '/' + n)
```

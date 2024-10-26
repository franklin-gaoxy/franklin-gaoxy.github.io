# Mongodb



## 安装(Debian 11 and 12)

```shell
sudo apt-get install gnupg curl
```

```shell
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
   sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
   --dearmor
```

debian11:

```shell
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bullseye/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
```

debian12:

```shell
echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/7.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list
```

更新

```shell
sudo apt-get update
```

```shell
sudo apt-get install -y mongodb-org
```

```shell
sudo systemctl start mongod
```

连接

```shell
mongosh
```

## 使用

### 开启认证

修改/etc/mongod.conf

```yaml
security:
  authorization: enabled
```

### 修改端口

```yaml
net:
  port: 27000
  bindIp: 127.0.0.1
```

### 创建用户

```
use admin
db.createUser(
  {
    user: "admin",
    pwd: "admin@admin",
    roles: [ { role: "readWrite", db: "test" } ]
  }
)
```

### 连接

```shell
mongosh 'mongodb://127.0.0.1:27000/?directConnection=true&serverSelectionTimeoutMS=2000&appName=mongosh+2.3.0' --username admin
```

### 使用

#### 创建数据库

> mongodb没有专用的数据库创建语句,当切换到一个不存在的库并写入数据的时候回自动添加上.
>
> 如果没有写入数据,那么这个库也不会被创建

```shell
use test
db.myCollection.insertOne({ name: "MongoDB", type: "Database" })
db.myCollection.find().pretty()
```

#### 插入单个文档

db.collection.insertOne() 将单个文档插入到集合中.如果没有指定id,Mongodb会将_id具有objectid值的字段添加到新文档.

如插入到`test.movies`中

```shell
use test

db.movies.insertOne(
  {
    title: "The Favourite",
    genres: [ "Drama", "History" ],
    runtime: 121,
    rated: "R",
    year: 2018,
    directors: [ "Yorgos Lanthimos" ],
    cast: [ "Olivia Colman", "Emma Stone", "Rachel Weisz" ],
    type: "movie"
  }
)
```

#### 查询插入的文档

```
db.movies.find( { title: "The Favourite" } )
```

#### 插入多个文档

db.collection.insertMany()可以将多个文档插入到集合.

将两个文档插入到test.movies中:

```
use test

db.movies.insertMany([
   {
      title: "Jurassic World: Fallen Kingdom",
      genres: [ "Action", "Sci-Fi" ],
      runtime: 130,
      rated: "PG-13",
      year: 2018,
      directors: [ "J. A. Bayona" ],
      cast: [ "Chris Pratt", "Bryce Dallas Howard", "Rafe Spall" ],
      type: "movie"
    },
    {
      title: "Tag",
      genres: [ "Comedy", "Action" ],
      runtime: 105,
      rated: "R",
      year: 2018,
      directors: [ "Jeff Tomsic" ],
      cast: [ "Annabelle Wallis", "Jeremy Renner", "Jon Hamm" ],
      type: "movie"
    }
])
```

#### 查询插入的所有文档

```
db.movies.find( {} )
```









## 相关文档

https://www.mongodb.com/docs/manual/tutorial/install-mongodb-on-debian/

https://www.mongodb.com/docs/mongodb-shell/crud/insert/#std-label-mongosh-insert
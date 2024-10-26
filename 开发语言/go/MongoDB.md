# MongoDB

| 编辑时间   | 操作内容     |
| ---------- | ------------ |
| 2024/08/20 | 文档首次编写 |

## 安装相关包

```shell
go get go.mongodb.org/mongo-driver/mongo
```

添加其他依赖项:

```shell
go get github.com/joho/godotenv
```

> 这个包可以从环境变量或者.env文件中读取对应的变量内容,此文档没有使用

## 连接到MongoDB

### 插入

```go
package main

import (
	"context"
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	clientOptions := options.Client().ApplyURI("mongodb://localhost:27017")
	client, err := mongo.Connect(context.TODO(), clientOptions)
	if err != nil {
		log.Fatal(err)
	}

	err = client.Ping(context.TODO(), nil)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Successfully connected to MongoDB")

	collection := client.Database("testdb").Collection("test")
	doc := bson.D{
		{Key: "hostname", Value: "knode1"},
		{Key: "ipaddress", Value: bson.A{"192.168.1.1", "10.0.1.2"}},
		{Key: "group", Value: bson.A{"group1", "group2"}},
		{Key: "username", Value: "root"},
		{Key: "password", Value: "1qaz@WSX"},
		{Key: "port", Value: 22},
		{Key: "status", Value: "active"},
		{Key: "tag", Value: bson.D{
			{Key: "role", Value: "master"},
			{Key: "type", Value: "linux"},
			{Key: "isSave", Value: "false"},
		}},
	}

	insertResult, err := collection.InsertOne(context.TODO(), doc)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Inserted a single document: ", insertResult.InsertedID)

	findOptions := options.Find()
	var results []bson.M

	cur, err := collection.Find(context.TODO(), bson.D{}, findOptions)
	if err != nil {
		log.Fatal(err)
	}

	for cur.Next(context.TODO()) {
		var elem bson.M
		err := cur.Decode(&elem)
		if err != nil {
			log.Fatal(err)
		}
		results = append(results, elem)
	}

	if err := cur.Err(); err != nil {
		log.Fatal(err)
	}

	cur.Close(context.TODO())
	fmt.Println("Found documents: ", results)

	err = client.Disconnect(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connection to MongoDB closed.")
}
```

### 查询

```go
package main

import (
	"context"
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	clientOptions := options.Client().ApplyURI("mongodb://localhost:27017")
	client, err := mongo.Connect(context.TODO(), clientOptions)
	if err != nil {
		log.Fatal(err)
	}

	err = client.Ping(context.TODO(), nil)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Successfully connected to MongoDB")

	collection := client.Database("testdb").Collection("test")

	filter := bson.D{
		{Key: "hostname", Value: "knode1"},
		{Key: "status", Value: "active"},
	}

	// 执行查询
	var result bson.M
	err = collection.FindOne(context.TODO(), filter).Decode(&result)
	if err != nil {
		log.Fatal(err)
	}

	// 打印查询结果
	fmt.Println("Found a document: ", result)

	// 关闭连接
	err = client.Disconnect(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connection to MongoDB closed.")
}
```

## 修改

> 代码运行后将会查询不到任何结果

```go
package main

import (
	"context"
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func main() {
	clientOptions := options.Client().ApplyURI("mongodb://localhost:27017")
	client, err := mongo.Connect(context.TODO(), clientOptions)
	if err != nil {
		log.Fatal(err)
	}

	err = client.Ping(context.TODO(), nil)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Successfully connected to MongoDB")

	collection := client.Database("testdb").Collection("test")

	// 查询条件
	filter := bson.D{
		{Key: "hostname", Value: "knode1"},
		{Key: "status", Value: "active"},
	}
	// 更新操作
	update := bson.D{
		{Key: "$set", Value: bson.D{
			{Key: "status", Value: "inactive"},
		}},
	}

	// 执行更新
	updateResult, err := collection.UpdateOne(context.TODO(), filter, update)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Printf("Matched %d documents and modified %d documents.\n", updateResult.MatchedCount, updateResult.ModifiedCount)

	// 查询更新后的文档
	var result bson.M
	err = collection.FindOne(context.TODO(), filter).Decode(&result)
	if err != nil {
		log.Fatal(err)
	}

	// 打印查询结果
	fmt.Println("Updated document: ", result)

	// 关闭连接
	err = client.Disconnect(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connection to MongoDB closed.")
}
```

### 读取数据转为struct

```go
package main

import (
	"context"
	"fmt"
	"log"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// 定义一个结构体来匹配MongoDB文档结构
type Document struct {
	Hostname  string   `bson:"hostname"`
	IPAddress []string `bson:"ipaddress"`
	Group     []string `bson:"group"`
	Username  string   `bson:"username"`
	Password  string   `bson:"password"`
	Port      int      `bson:"port"`
	Status    string   `bson:"status"`
	Tag       Tag      `bson:"tag"`
}

type Tag struct {
	Role   string `bson:"role"`
	Type   string `bson:"type"`
	IsSave string `bson:"isSave"`
}

func main() {
	// 设置MongoDB连接URI
	clientOptions := options.Client().ApplyURI("mongodb://localhost:27017")

	// 创建一个新的MongoDB客户端并连接到MongoDB
	client, err := mongo.Connect(context.TODO(), clientOptions)
	if err != nil {
		log.Fatal(err)
	}

	// 确认连接是否成功
	err = client.Ping(context.TODO(), nil)
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Successfully connected to MongoDB")

	// 选择数据库和集合
	collection := client.Database("testdb").Collection("test")

	// 查询条件
	filter := bson.D{
		{Key: "hostname", Value: "knode2"},
		{Key: "status", Value: "active"},
	}

	// 执行查询
	var result Document
	err = collection.FindOne(context.TODO(), filter).Decode(&result)
	if err != nil {
		fmt.Println("get data error!")
		log.Fatal(err)
	}

	// 打印查询结果
	fmt.Printf("Found a document: %+v\n", result)

	// 关闭连接
	err = client.Disconnect(context.TODO())
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("Connection to MongoDB closed.")
}
```


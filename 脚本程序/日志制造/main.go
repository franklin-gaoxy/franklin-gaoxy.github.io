package main

import (
	"bufio"
	"fmt"
	"log"
	"math/rand"
	"os"
	"strings"
	"time"
)

// 定义一个结构体用来存放解析后的内容
type Content struct {
	Level   string
	Content string
}

func main() {
	contents := ReadFileContent()

	// 确保slice不为空
	if len(contents) == 0 {
		fmt.Println("没有内容")
		return
	}

	// 设置随机种子
	rand.Seed(time.Now().UnixNano())

	// 演示：循环10次随机选择
	num := 0
	sign := 0
	for {
		num = num + 1
		sleepTime()
		index := rand.Intn(len(contents)) // 生成一个[0, len(contents))之间的随机索引
		selected := contents[index]       // 使用随机索引选择一个Content

		if selected.Level == "info" {
			log.Println(selected.Content)
		} else if selected.Level == "warn" {
			log.Println(selected.Content)
		} else if selected.Level == "error" {
			sign = sign + 1
			if num > 200 && sign >= 20 {
				log.Fatalln(selected.Content)
			}
		}
	}
}

func ReadFileContent() []Content {
	// 打开文件
	file, err := os.Open("data.txt")
	if err != nil {
		panic(err)
	}
	defer file.Close()

	var contents []Content // 用来存放所有解析后的内容

	// 创建一个bufio.Reader对象
	scanner := bufio.NewScanner(file)
	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.Fields(line)
		if len(parts) >= 2 {
			// 假设每一行至少有两个以空格分隔的部分
			// 第一部分是Level，第二部分及之后是Content
			// 这里简单地将第二部分及之后的所有部分合并作为Content，使用空格分隔
			contentPart := strings.Join(parts[1:], " ")
			contents = append(contents, Content{
				Level:   parts[0],
				Content: contentPart,
			})
		}
	}

	// 检查扫描时是否出现错误
	if err := scanner.Err(); err != nil {
		fmt.Println("读取文件时发生错误:", err)
	}
	return contents
}

func sleepTime() {
	num := rand.Intn(300) * 1000
	time.Sleep(time.Microsecond * time.Duration(num))
}

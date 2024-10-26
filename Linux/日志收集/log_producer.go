package main

import (
	"fmt"
	"sync"
	"time"
)

func worker(id int, data <-chan int, logChan chan<- string, wg *sync.WaitGroup) {
	defer wg.Done()
	for num := range data {
		// 接收数据并尝试发送日志
		now := time.Now()
		logMessage := fmt.Sprintf("[%s] [Thread-%d] [INFO] [] : time: %d, data: %d",
			now.Format("2006-01-02 15:04:05.000"), id, now.Unix(), num)
		select {
		// 尝试发送日志，如果logChan满了，则本次不发送
		case logChan <- logMessage:
		default:
		}
	}
}

func logger(logChan <-chan string) {
	for logMsg := range logChan {
		fmt.Println(logMsg)
	}
}

func main() {
	var wg sync.WaitGroup
	dataChan := make(chan int)
	logChan := make(chan string, 1) // 使logChan有一个缓冲，确保每秒只能有一个日志消息

	// 启动logger goroutine
	go logger(logChan)

	// 启动10个worker goroutine
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go worker(i, dataChan, logChan, &wg)
	}

	// 发送数据
	num := 0
	for {
		select {
		case dataChan <- num:
			num++
			time.Sleep(1 * time.Second)
		}
	}
}

#!/usr/bin/env python
# -*-coding:utf-8-*-
'''
    describe:
'''
import os
from urllib.parse import quote
import sys

blacklist = [".git",".idea"]
# address = "https://gitee.com/gaoyang_111/study_document/{urltype}/master/"
address = "http://47.95.223.11:3000/gaoxiuyang/study/src/branch/main/"
# rpath = "D:\\document"
# rpath = "E:\\桌面快捷方式\\学习空间\\study"
if len(sys.argv) > 1:
    rpath = sys.argv[1]
else:
    print("please input path!")
    os.exit(1)
lineSymbol = "<br>"
def DirAndFile(path,a,symbol = ""):
    fileList = os.listdir(path)
    totleNum = len(fileList)
    num = 1
    for i in fileList:
        # 如果是黑名单目录 那么直接跳过
        if i in blacklist:
            num = num + 1
            continue
        # 如果是图片也跳过

        tmpPath = os.path.join(path,i)
        # print(tmpPath)
        # 判断是否为当前目录的最后一个
        url = address + tmpPath.replace(rpath,"").replace("\\","/")
        content = "[" + i + "](" + "{url}" + ")"
        if os.path.isfile(tmpPath):
            # url转码
            url = quote(url.format(urltype="blob")).replace("%3A",":")

            # 判断是否为最后一个
            if num == totleNum:
                a.write(symbol + "&ensp;└─&nbsp;" + content.format(url=url) + lineSymbol)
                # print(symbol + "  └─ ",i)
            else:
                a.write(symbol + "&ensp;├─&nbsp;" + content.format(url=url) + lineSymbol)
                # print(symbol + "  ├─ ",i)
        else:
            # url转码
            url = quote(url.format(urltype="tree")).replace("%3A",":")

            # 判断目录是否为最后一个
            if num == totleNum:
                a.write(symbol + "&ensp;└─&nbsp;" + content.format(url=url) + lineSymbol)
                # print(symbol + "  └─ ",i)
                DirAndFile(tmpPath,a,symbol +  "     ")
            else:
                a.write(symbol + "&ensp;├─&nbsp;" + content.format(url=url) + lineSymbol)
                # print(symbol + "  ├─ ", i)
                DirAndFile(tmpPath,a,symbol + "&ensp;│&ensp;")
        num = num + 1

if __name__ == '__main__':
    if os.path.exists("index.md") :
        os.remove("index.md")
    with open("index.md",mode="a",encoding="utf-8") as a:
        a.write("document" + lineSymbol)
        # print("document")
        DirAndFile(rpath,a)


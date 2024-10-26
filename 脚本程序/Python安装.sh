#!/bin/bash


function vars()
{
    installLogFile="installPython.log"
}
function environmentCheck()
{
    # 检查网络是否通畅
    curl -s http://www.baidu.com >>/dev/null 2>&1
    checkExecute "检查网络"
    echo "安装相关依赖..."
    yum install openssl openssl-devel gcc zlib zlib-devel python3-devel -y >>${installLogFile} 2>&1
    checkExecute "下载依赖"
}
function getVersion()
{
    # 获取所有Python版本
    echo "开始获取版本列表..."
    curl -s https://www.python.org/downloads/|egrep "Python [0-9]+\.[0-9]+\.[0-9]+"|awk -F"[>,<]+" '{print $4}'
    checkExecute "获取版本"
}
function obtainVersion()
{
    # 获取安装版本和包
    read -p "[请输入安装版本,复制上面输出即可,示例: Python 3.5.1]>" version
    echo "开始获取下载地址..."
    downloadPath=`curl -s https://www.python.org/downloads/|egrep "Python [0-9]+\.[0-9]+\.[0-9]+"|egrep ">${version}<"|awk -F'"' '{print $4}'`
    downloadPath=`curl -s https://www.python.org/${downloadPath}|egrep "Gzipped source tarball"|awk -F'"' '{print $2}'`
    echo "开始下载安装包,下载地址: ${downloadPath}"
    curl -Os $downloadPath
    checkExecute "下载安装包"
}
function installPackage()
{
    echo "开始检查安装包"
    # 获取安装包名 检查与下载的是否一致
    packageName=`echo "$downloadPath"|awk -F'/' '{print $NF}'`
    if [ -f ${packageName} ];then
        echo "检查完毕"
    else
        echo "没有找到安装包!";exit
    fi
    echo "开始安装..."
    tar xf ${packageName}  >>${installLogFile} 2>&1 
    # 获取目录名称
    symbol=`echo $packageName|awk -F"." '{print $NF}'`
    directoryName=`echo $packageName|awk -F".${symbol}" '{print $1}'`
    cd ${directoryName}
    ./configure >>${installLogFile} 2>&1 
    checkExecute "安装 ./configure"
    make;make install >>${installLogFile} 2>&1 
    checkExecute "编译 make ;make install"
    echo "Python安装完成."
}
function checkExecute()
{
    if [ $? -eq 0 ];then
        echo "$1 成功."
    else
        echo "$1 失败!"
        echo "详细错误内容见日志${installLogFile}";exit
    fi
}
function installPip()
{
    wget https://files.pythonhosted.org/packages/73/8e/7774190ac616c69194688ffce7c1b2a097749792fea42e390e7ddfdef8bc/pip-20.2.2.tar.gz
    tar xf pip-20.2.2.tar.gz
    cd pip-20.2.2;python3 setup.py install
}
main(){
    vars
    environmentCheck
    getVersion
    obtainVersion
    installPackage
}
main
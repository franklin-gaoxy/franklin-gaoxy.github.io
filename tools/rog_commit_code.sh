#!/bin/bash
project_home="/h/桌面快捷方式/私有仓库/study"

echo "==> pull code ..."
git pull origin main

echo "==> update index ..."
cd $project_home
cd ./脚本程序/仓库脚本工具
python "Generate structural information.py" ${project_home}
cd ../../

echo "==> push code ..."
git add .
hn=`hostname`
us=`whoami`
git commit -m "[${hn}:${us}]:Auto submit"
git push origin
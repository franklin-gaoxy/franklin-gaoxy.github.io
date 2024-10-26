#!/bin/bash

#######################################
# 默认备份资源如下:
#   deployment statefulset daemonset service pvc pv replicasets configmap secret pod 
# 可通过命令 kubectl api-resources 查看集群支持的所有资源
#######################################


function vars()
{
    resource=("deployment" "statefulset" "daemonset" "service" "pvc" "pv" "replicasets" "configmaps" "secret" "pod")
    namespace=("default" "kuboard")
}
function mkdir_directory()
{
    if [ -d $1 ];then
        echo "directory $i exist, skip."
    else
        mkdir $1;cd $1
    fi
}
function backup()
{
    mkdir `date +%F`;cd `date +%F`
    for ns in ${namespace[@]};do 
        ns_path=`pwd`
        mkdir_directory $ns
        for i in ${resource[@]};do 
            echo "[`date +%F_%T`] backup resource ${ns} ${i}."
            resource_path=`pwd`
            mkdir_directory $i
            for name in `kubectl get $i -n $ns|sed '/NAME/d'|awk '{print $1}'`;do 
                # name_path=`pwd`
                # mkdir_directory $n
                echo "backup resource ${ns} ${i} $name"
                kubectl get $i $n -o=yaml -n $ns >$name.yaml
            done 
            cd ${resource_path}
        done
        cd ${ns_path}
    done
}

function main()
{
    vars
    backup
}
main
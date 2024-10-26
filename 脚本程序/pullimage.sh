#！/bin/bash

function vars(){
    remote_host="47.95.223.11"
    remote_keys="/root/.ssh/root.pem"
}

function echo_green(){
    echo -e "\033[0;32m$1\033[0m"
}

function echo_red(){
    echo -e "\033[0;31m$1\033[0m"
}

function echo_yellow(){
    echo -e "\033[0;33m$1\033[0m"
}

function if_status(){
    if [ $? -eq 0 ];then
        echo_green "$1 successed!"
    else
        echo_red "$1 error!"
        exit 1
    fi
}

function ssh_remote_pull_and_push_image(){
    echo_green "start ssh remote host pull image..."
    ssh -i ${remote_keys} ${remote_host} "docker pull $1" >/dev/null
    if_status "ssh remote host pull image $1:"
    ssh -i ${remote_keys} ${remote_host} "docker tag $1 $2"
    ssh -i ${remote_keys} ${remote_host} "docker push $2" >/dev/null
    ssh -i ${remote_keys} ${remote_host} "docker image rm $1 $2"
    if_status "ssh remote remove image:"
}

function pull_image(){
    docker pull $1
    if_status "localhost pull image $1:"

}

function push_image(){
    docker push $1
    if_status "localhost push image $1:"
}

function main(){
    vars
    symbol=`echo $1|awk -F"/" '{print $1}'`
    suffix=`echo $1|sed "s#$symbol##g"`
    remote_name="${remote_host}:5000${suffix}"
    local_name="10.0.0.10:5000${suffix}"
    # new_name=`sed 's#47.95.223.11:5000#10.0.0.10:5000#g' $1`
    # 从云服务器拉取镜像 并推送到本地仓库
    ssh_remote_pull_and_push_image $1 $remote_name
    pull_image $remote_name >/dev/null
    docker tag $remote_name $local_name
    push_image $local_name >/dev/null
    echo_green "push image successed."
    docker image rm $remote_name $local_name >/dev/null
}

# input 47.95.223.11:5000/calico/cni:v3.25.0
# input docker.io/calico/cni:v3.25.0 
main $1
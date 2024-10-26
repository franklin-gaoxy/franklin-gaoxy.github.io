# 拉去镜像推送到指定的机器

hostList=("10.0.0.21" "10.0.0.22" "10.0.0.23")
if [[ "x$1" == "x" ]];then
    echo "请输入镜像名称"
    exit 1
fi

echo "start pull image $1"
docker pull $1
if [[ $? == 0 ]];then
    echo "download success."
else
    echo "download failed."
    exit 1
fi

echo "start export image."
docker save $1 > image.tar

imageName=`echo $1|sed "s#docker.io/##g"`
for host in ${hostList[@]};do
    echo "start load image to $host"
    scp image.tar root@$host:/root/image.tar
    if [[ $? == 0 ]];then
        echo "load success."
    else
        echo "load failed."
        exit 1
    fi

    ssh root@$host "ctr -n k8s.io i import image.tar"
    ssh root@$host "ctr -n k8s.io i tag $1 ${imageName}"
    ssh root@$host "rm -rf /root/image.tar"
done
# Ubuntu安装mysql 8.0版本

```shell
mkdir mysql ;cd mysql
wget https://dev.mysql.com/get/Downloads/MySQL-8.0/mysql-server_8.0.36-1debian12_amd64.deb-bundle.tar
tar xf mysql-server_8.0.36-1debian12_amd64.deb-bundle.tar
rm -rf mysql-server_8.0.36-1debian12_amd64.deb-bundle.tar
```

安装

```shell
apt-get update
apt-get upgrade
sudo apt-get install ./mysql-common_8.0.36-1debian12_amd64.deb \
./mysql-community-client-core_8.0.36-1debian12_amd64.deb \
./mysql-community-client_8.0.36-1debian12_amd64.deb \
./mysql-client_8.0.36-1debian12_amd64.deb \
./mysql-community-client-plugins_8.0.36-1debian12_amd64.deb \
./mysql-community-server-core_8.0.36-1debian12_amd64.deb \
./mysql-community-server_8.0.36-1debian12_amd64.deb \
./mysql-server_8.0.36-1debian12_amd64.deb
# or
apt-get install ./*.deb -y
```

如果有残留则卸载
```shell
dpkg -l |grep mysql |awk '{print $2 }'|xargs dpkg -r
dpkg -l |grep mariadb |awk '{print $2 }'|xargs dpkg -r
```
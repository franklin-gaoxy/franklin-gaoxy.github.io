
下载页面: [https://dev.mysql.com/downloads/mysql/](https://dev.mysql.com/downloads/mysql/) 
```shell
tar xf mysql-server_8.0.31-1ubuntu22.04_amd64.deb-bundle.tar
```
安装:
```shell
apt --fix-broken install
apt-get install libssl-dev -y
apt-get install libnuma1 build-essential aptitude libstdc++6
dpkg -i mysql-{common,community-client,community-client-core,community-client-plugins,client,community-server,community-server-core,server}_*.deb

dpkg -i mysql-community-server_8.0.31-1ubuntu22.04_amd64.deb

ufw disable
apt --fix-broken install
```

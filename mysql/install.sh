# Install MySQL
set -e

export DEBIAN_FRONTEND=noninteractive

debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''"
#debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${ROOT_MYSQL_PASSWORD}"
#debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${ROOT_MYSQL_PASSWORD}"

apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 5072E1F5
echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7" | tee -a /etc/apt/sources.list.d/mysql.list
apt-get update -y && apt-get install mysql-server expect -y
update-alternatives --remove my.cnf /etc/mysql/my.cnf.migrated
service mysql start

#expect \"Enter password for user root:\"
#send \"$ROOT_MYSQL_PASSWORD\r\"


expect -c "
set timeout 10
spawn mysql_secure_installation

expect \"Press y|Y for Yes, any other key for No:\"
send \"n\r\"

expect \"New password:\"
send \"$ROOT_MYSQL_PASSWORD\r\"

expect \"Re-enter new password:\"
send \"$ROOT_MYSQL_PASSWORD\r\"

expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"y\n\"

expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect eof"

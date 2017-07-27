# Install MySQL
set -e

debconf-set-selections <<< "mysql-community-server mysql-community-server/data-dir select ''"
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password ${ROOT_MYSQL_PASSWORD}"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password ${ROOT_MYSQL_PASSWORD}"

apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 5072E1F5
echo "deb http://repo.mysql.com/apt/ubuntu/ trusty mysql-5.7" | tee -a /etc/apt/sources.list.d/mysql.list
apt-get update -y

apt-get install mysql-server -y
update-alternatives --remove my.cnf /etc/mysql/my.cnf.migrated
service mysql start

apt-get install expect -y

expect -c "
set timeout 10
spawn mysql_secure_installation

expect \"Enter password for user root:\"
send \"$ROOT_MYSQL_PASSWORD\r\"

expect \"Press y|Y for Yes, any other key for No:\"
send \"n\r\"

expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
send \"n\r\"

expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
send \"y\r\"

expect eof"

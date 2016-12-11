debconf-set-selections <<< "mysql-server mysql-server/root_password password $ROOT_MYSQL_PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $ROOT_MYSQL_PASSWORD"

apt-get install expect mysql-server -y

if [ $IS_ON_DOCKER == true ]; then
	service mysql start
fi

mysql_install_db
expect -c "

set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"$ROOT_MYSQL_PASSWORD\r\"

expect \"Change the root password?\"
send \"n\r\"

expect \"Remove anonymous users?\"
send \"y\r\"

expect \"Disallow root login remotely?\"
send \"y\r\"

expect \"Remove test database and access to it?\"
send \"y\r\"

expect \"Reload privilege tables now?\"
send \"y\r\"

expect eof"

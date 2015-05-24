# INSTALL Roundcube and all its dependences

ROUNDCUBE_DIR="$CURRENT_DIR/roundcube"

apt-get install nginx php5-fpm php5-mcrypt php5-intl php5-mysql -y

if [ $IS_ON_DOCKER == true ]; then
	apt-get install  wget -y
fi

rm -r /etc/nginx/sites-enabled/*
cp $ROUNDCUBE_DIR/nginx_config /etc/nginx/sites-enabled/roundcube
set_hostname /etc/nginx/sites-enabled/roundcube

cd /tmp && wget http://netcologne.dl.sourceforge.net/project/roundcubemail/roundcubemail/1.1.1/roundcubemail-1.1.1-complete.tar.gz
tar -xvzf roundcubemail-1.1.1-complete.tar.gz
mkdir /usr/share/roundcubemail
cp -r roundcubemail-1.1.1/ /usr/share/nginx/roundcubemail
cd /usr/share/nginx/roundcubemail/
sed -i "s/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini

mysqladmin -u$ROOT_MYSQL_USERNAME -p$ROOT_MYSQL_PASSWORD create $ROUNDCUBE_MYSQL_DATABASE	
mysql -h $MYSQL_HOSTNAME -u$ROOT_MYSQL_USERNAME -p$ROOT_MYSQL_PASSWORD << EOF
GRANT SELECT, EXECUTE, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, TRIGGER, UPDATE, LOCK TABLES ON $ROUNDCUBE_MYSQL_DATABASE.* TO '$ROUNDCUBE_MYSQL_USERNAME'@'$MYSQL_HOSTNAME' IDENTIFIED BY '$ROUNDCUBE_MYSQL_PASSWORD';
GRANT SELECT, UPDATE  ON $MYSQL_DATABASE.* TO '$ROUNDCUBE_MYSQL_USERNAME'@'$MYSQL_HOSTNAME';
FLUSH PRIVILEGES;
USE $ROUNDCUBE_MYSQL_DATABASE;
EOF

chmod -R 644 /usr/share/nginx/roundcubemail/temp /usr/share/nginx/roundcubemail/logs
cp $ROUNDCUBE_DIR/config /usr/share/nginx/roundcubemail/config/config.inc.php
sed -i "s/__EASYMAIL_MYSQL_HOSTNAME__/$MYSQL_HOSTNAME/g" /usr/share/nginx/roundcubemail/config/config.inc.php
sed -i "s/__EASYMAIL_ROUNDCUBE_MYSQL_DATABASE__/$ROUNDCUBE_MYSQL_DATABASE/g" /usr/share/nginx/roundcubemail/config/config.inc.php
sed -i "s/__EASYMAIL_ROUNDCUBE_MYSQL_USERNAME__/$ROUNDCUBE_MYSQL_USERNAME/g" /usr/share/nginx/roundcubemail/config/config.inc.php
sed -i "s/__EASYMAIL_ROUNDCUBE_MYSQL_PASSWORD__/$ROUNDCUBE_MYSQL_PASSWORD/g" /usr/share/nginx/roundcubemail/config/config.inc.php

mysql -h $MYSQL_HOSTNAME -u$ROUNDCUBE_MYSQL_USERNAME -p$ROUNDCUBE_MYSQL_PASSWORD $ROUNDCUBE_MYSQL_DATABASE < /usr/share/nginx/roundcubemail/SQL/mysql.initial.sql
rm -r /usr/share/nginx/roundcubemail/installer
cd /usr/share/nginx/roundcubemail/plugins/password/
cp config.inc.php.dist config.inc.php 

cat $ROUNDCUBE_DIR/password_plugin_config >> /usr/share/nginx/roundcubemail/plugins/password/config.inc.php
sed -i "s/<?php/<?php \n # PLEASE READ ME \n #Some of the array values are overwritten in the end of this file!/" config.inc.php
sed -i "s/__EASYMAIL_MYSQL_HOSTNAME__/$MYSQL_HOSTNAME/g" config.inc.php
sed -i "s/__EASYMAIL_ROUNDCUBE_MYSQL_DATABASE__/$ROUNDCUBE_MYSQL_DATABASE/g" config.inc.php
sed -i "s/__EASYMAIL_ROUNDCUBE_MYSQL_USERNAME__/$ROUNDCUBE_MYSQL_USERNAME/g" config.inc.php
sed -i "s/__EASYMAIL_ROUNDCUBE_MYSQL_PASSWORD__/$ROUNDCUBE_MYSQL_PASSWORD/g" config.inc.php
sed -i "s/__EASYMAIL_MYSQL_DATABASE__/$MYSQL_DATABASE/g" config.inc.php

service php5-fpm restart
service nginx restart

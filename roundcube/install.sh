# INSTALL Roundcube and all its dependences
apt-get install nginx php5-fpm php5-mcrypt php5-intl php5-mysql -y

if [ $IS_ON_DOCKER == true ]; then
	apt-get install  wget -y
fi

rm -r /etc/nginx/sites-enabled/*
cp $CURRENT_DIR/nginx_config_for_roundcube /etc/nginx/sites-enabled/roundcube
set_hostname /etc/nginx/sites-enabled/roundcube

cd /tmp && wget http://netcologne.dl.sourceforge.net/project/roundcubemail/roundcubemail/1.1.1/roundcubemail-1.1.1-complete.tar.gz
tar -xvzf roundcubemail-1.1.1-complete.tar.gz
mkdir /usr/share/roundcubemail
cp -r roundcubemail-1.1.1/ /usr/share/nginx/roundcubemail
cd /usr/share/nginx/roundcubemail/
sed -i "s/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini


mysqladmin -uroot -p$PASSWORD create roundcube	
mysql -uroot -p$PASSWORD << EOF
GRANT SELECT ON roundcube.* TO 'roundcube'@'127.0.0.1' IDENTIFIED BY '';
GRANT EXECUTE, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, TRIGGER, UPDATE, LOCK TABLES ON roundcube.* TO 'roundcube'@'127.0.0.1' IDENTIFIED BY '$PASSWORD';
GRANT SELECT, UPDATE  ON mailserver.* TO 'roundcube'@'127.0.0.1';
FLUSH PRIVILEGES;
USE roundcube;
EOF

chmod -R 644 /usr/share/nginx/roundcubemail/temp /usr/share/nginx/roundcubemail/logs
cp $CURRENT_DIR/roundcube_config /usr/share/nginx/roundcubemail/config/config.inc.php
set_password /usr/share/nginx/roundcubemail/config/config.inc.php

mysql -uroot -p$PASSWORD roundcube < /usr/share/nginx/roundcubemail/SQL/mysql.initial.sql
rm -r /usr/share/nginx/roundcubemail/installer

cd /usr/share/nginx/roundcubemail/plugins/password/
cp config.inc.php.dist config.inc.php 

sed -i "s/<?php/<?php \n # PLEASE READ ME \n #Some array values are overwritten in the end of this file!/" config.inc.php
cat $CURRENT_DIR/roundcube_password_plugin_config >> /usr/share/nginx/roundcubemail/plugins/password/config.inc.php
set_password /usr/share/nginx/roundcubemail/plugins/password/config.inc.php

service php5-fpm restart
service nginx restart

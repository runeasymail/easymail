# INSTALL Roundcube and all its dependences

ROUNDCUBE_DIR="$CURRENT_DIR/roundcube"

apt-get install -y language-pack-en-base
LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php -y
apt-get update
apt-get install --assume-yes \
  nginx \
  php7.0-fpm \ 
  mcrypt \ 
  php7.0-mcrypt \ 
  php7.0-intl \ 
  php7.0-mysql \ 
  php7.0-mbstring \ 
  php-curl \
  php7.0-zip \
  php7.0-xml \
  php-xml \
  php-xml-parser \
  php7.0-cli \
  php7.0-gd \
  php-apcu \
  php7.0-imap \
  php-mail \
  php-mail-mimedecode \
  php-mime-type \
  php-mail-mime

phpenmod intl zip

if [ $IS_ON_DOCKER == true ]; then
	apt-get install  wget -y
fi

rm -r /etc/nginx/sites-enabled/*
cp $ROUNDCUBE_DIR/nginx_config /etc/nginx/sites-enabled/roundcube
set_hostname /etc/nginx/sites-enabled/roundcube
sed -i "s#__EASYMAIL_SSL_CA_BUNDLE_FILE__#$SSL_CA_BUNDLE_FILE#g" /etc/nginx/sites-enabled/roundcube
sed -i "s#__EASYMAIL_SSL_PRIVATE_KEY_FILE__#$SSL_PRIVATE_KEY_FILE#g" /etc/nginx/sites-enabled/roundcube

cd /tmp && wget -O roundcubemail.tar.gz https://github.com/roundcube/roundcubemail/releases/download/$ROUNDCUBE_VERSION/roundcubemail-$ROUNDCUBE_VERSION-complete.tar.gz
tar -xvzf roundcubemail.tar.gz
mkdir /usr/share/roundcubemail
cp -r roundcubemail-$ROUNDCUBE_VERSION/ /usr/share/nginx/roundcubemail

cd /usr/share/nginx/roundcubemail/
cp /etc/php/7.0/fpm/php.ini /etc/php/7.0/fpm/php.ini.orig
sed -i "s/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/" /etc/php/7.0/fpm/php.ini
sed -i "s/post_max_size =.*/post_max_size = 16M/" /etc/php/7.0/fpm/php.ini
sed -i "s/upload_max_filesize =.*/upload_max_filesize = 15M/" /etc/php/7.0/fpm/php.ini

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

service php7.0-fpm restart
service nginx restart

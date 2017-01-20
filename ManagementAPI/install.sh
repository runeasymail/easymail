
export MANAGEMENT_API_DIR=$EASY_MAIL_DIR/ManagementAPI

mkdir $MANAGEMENT_API_DIR && cd $MANAGEMENT_API_DIR
wget https://github.com/runeasymail/ManagementAPI/releases/download/v0.1/ManagementAPI
chmod +x ManagementAPI

echo "
[app]
port=7080
[mysql]
dsn=$MYSQL_USERNAME:$MYSQL_PASSWORD@tcp($MYSQL_HOSTNAME:3306)/$MYSQL_DATABASE
" > config.ini

./ManagementAPI

apt-get install apache2-utils -y

htpasswd -cb $ManagementAPI_DIR/.htpasswd $MANAGEMENT_API_USERNAME $MANAGEMENT_API_PASSWORD

cp $CURRENT_DIR/ManagementAPI/ManagementAPI-nginx.conf $MANAGEMENT_API_DIR/ManagementAPI-nginx.conf

sed -i "s|#__EASY_MAIL_INCLUDE__|include $MANAGEMENT_API_DIR/ManagementAPI-nginx.conf;|g" /etc/nginx/sites-enabled/roundcube


 
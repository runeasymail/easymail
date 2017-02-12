
export MANAGEMENT_API_DIR=$EASY_MAIL_DIR/ManagementAPI

mkdir $MANAGEMENT_API_DIR && cd $MANAGEMENT_API_DIR
wget https://github.com/runeasymail/ManagementAPI/releases/download/0.2-RC1/ManagementAPI
chmod +x ManagementAPI

echo "
[app]
port=7080
[mysql]
dsn=$MYSQL_USERNAME:$MYSQL_PASSWORD@tcp($MYSQL_HOSTNAME:3306)/$MYSQL_DATABASE

[auth]
secretKey:jKL29048klmxzq2uiu,ashkj4ae9878yuks
username:$MANAGEMENT_API_USERNAME
password:$MANAGEMENT_API_PASSWORD
" > config.ini


cp $CURRENT_DIR/ManagementAPI/ManagementAPI-nginx.conf $MANAGEMENT_API_DIR/ManagementAPI-nginx.conf

sed -i "s|# __EASY_MAIL_INCLUDE__|include $MANAGEMENT_API_DIR/ManagementAPI-nginx.conf;|g" /etc/nginx/sites-enabled/roundcube

service nginx reload
 
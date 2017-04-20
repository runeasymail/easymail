
export MANAGEMENT_API_DIR=$EASY_MAIL_DIR/ManagementAPI

mkdir $MANAGEMENT_API_DIR && cd $MANAGEMENT_API_DIR

apt-get install wget -y

wget https://github.com/runeasymail/ManagementAPI/releases/download/v0.4/ManagementAPI
chmod +x ManagementAPI

echo "
[app]
port=7080
[mysql]
dsn=$MYSQL_USERNAME:$MYSQL_PASSWORD@tcp($MYSQL_HOSTNAME:3306)/$MYSQL_DATABASE

[auth]
secretKey:$MANAGEMENT_API_SECRETKEY
username:$MANAGEMENT_API_USERNAME
password:$MANAGEMENT_API_PASSWORD
" > config.ini


cp $CURRENT_DIR/ManagementAPI/ManagementAPI-nginx.conf $MANAGEMENT_API_DIR/ManagementAPI-nginx.conf

sed -i "s|# __EASY_MAIL_INCLUDE__|include $MANAGEMENT_API_DIR/ManagementAPI-nginx.conf;|g" /etc/nginx/sites-enabled/roundcube

./ManagementAPI &
service nginx reload
 

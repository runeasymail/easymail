# Implement ManagementAPI
set -e

export MANAGEMENT_API_DIR=$EASY_MAIL_DIR/ManagementAPI

mkdir $MANAGEMENT_API_DIR && cd $MANAGEMENT_API_DIR

apt-get install wget -y

wget https://github.com/runeasymail/ManagementAPI/releases/download/v$MANAGEMENT_API_VERSION/ManagementAPI
chmod +x ManagementAPI

echo "
[app]
port=7080
hostname=__EASYMAIL_HOSTNAME__

[mysql]
dsn=$MYSQL_USERNAME:$MYSQL_PASSWORD@tcp($MYSQL_HOSTNAME:3306)/$MYSQL_DATABASE

[auth]
secretKey=$MANAGEMENT_API_SECRETKEY
username=$MANAGEMENT_API_USERNAME
password=$MANAGEMENT_API_PASSWORD
" > config.ini


cp $CURRENT_DIR/ManagementAPI/ManagementAPI-nginx.conf $MANAGEMENT_API_DIR/ManagementAPI-nginx.conf
cp $CURRENT_DIR/ManagementAPI/renew_letsencrypt_certificate.sh $MANAGEMENT_API_DIR/renew_letsencrypt_certificate.sh

sed -i "s|# __EASY_MAIL_INCLUDE__|include $MANAGEMENT_API_DIR/ManagementAPI-nginx.conf;|g" /etc/nginx/sites-enabled/roundcube

crontab <<EOF
0 0 1 * * sh $MANAGEMENT_API_DIR/renew_letsencrypt_certificate.sh
EOF

service cron start

./ManagementAPI &
service nginx reload
 

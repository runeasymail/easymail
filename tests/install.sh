export EASY_MAIL_DIR="/opt/easymail"
export PHP_MAILER_TAG="5.2.23"
export PASSWORD=$(cat "$EASY_MAIL_DIR/config.ini" | grep roundcube_web_password: | awk -F':' '{ print $2;}')

apt-get install wget -y

cd /easymail/tests/

wget -O PHPMailer.tar.gz https://github.com/PHPMailer/PHPMailer/archive/v$PHP_MAILER_TAG.tar.gz
tar -xvzf PHPMailer.tar.gz
mv PHPMailer-$PHP_MAILER_TAG PHPMailer

sed -i "s#__ROUNDCUBE_WEB_PASSWORD__#$PASSWORD#g" /easymail/tests/config.php

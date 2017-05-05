export EASY_MAIL_DIR="/opt/easymail"
export PASSWORD=$(cat "$EASY_MAIL_DIR/config.ini" | grep roundcube_web_password: | awk -F':' '{ print $2;}')

apt-get install git -y

cd /easymail/tests/

git clone https://github.com/PHPMailer/PHPMailer.git

sed -i "s#__ROUNDCUBE_WEB_PASSWORD__#$PASSWORD#g" $EASY_MAIL_DIR/tests/config.php
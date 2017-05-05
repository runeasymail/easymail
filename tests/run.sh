

export $PASSWORD='PUT password here'

cd /easymail/tests/
git clone https://github.com/PHPMailer/PHPMailer.git
sed -i "s#__ROUNDCUBE_WEB_PASSWORD__#$PASSWORD#g" $EASY_MAIL_DIR/tests/config.php

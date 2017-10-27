set -e

# tmp workaround, please have a look at https://github.com/moby/moby/issues/13555 
#apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
#apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
#gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 94558F59
#gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4

# Update and install initially required services
apt-get update -y && apt-get install openssl python dialog cron -y

export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export HOSTNAME="__EASYMAIL_HOSTNAME__"
export SSL_CA_BUNDLE_FILE="/etc/dovecot/dovecot.pem"
export SSL_PRIVATE_KEY_FILE="/etc/dovecot/private/dovecot.pem"

export ADMIN_EMAIL="admin@$HOSTNAME"
export ADMIN_PASSWORD_UNENCRYPTED='__EASYMAIL_ADMIN_PASSWORD_UNENCRYPTED__'
export ADMIN_PASSWORD=$(openssl passwd -1 $ADMIN_PASSWORD_UNENCRYPTED)

export ROOT_MYSQL_USERNAME='root'
export ROOT_MYSQL_PASSWORD='__EASYMAIL_ROOT_MYSQL_PASSWORD__'

export MYSQL_DATABASE='mailserver'
export MYSQL_HOSTNAME='127.0.0.1'
export MYSQL_USERNAME='mailuser'
export MYSQL_PASSWORD='__EASYMAIL_MYSQL_PASSWORD__'

export ROUNDCUBE_MYSQL_DATABASE='roundcube_dbname'
export ROUNDCUBE_MYSQL_USERNAME='roundcube_user'
export ROUNDCUBE_MYSQL_PASSWORD='__EASYMAIL_ROUNDCUBE_MYSQL_PASSWORD__'
export ROUNDCUBE_VERSION=1.2.5

export MANAGEMENT_API_USERNAME='__EASYMAIL_MANAGEMENT_API_USERNAME__'
export MANAGEMENT_API_PASSWORD='__EASYMAIL_MANAGEMENT_API_PASSWORD__'
export MANAGEMENT_API_SECRETKEY='__EASYMAIL_MANAGEMENT_API_SECRETKEY__'
export MANAGEMENT_API_VERSION=0.9.17

export EASY_MAIL_DIR="/opt/easymail" && mkdir $EASY_MAIL_DIR

function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" $1
}

export -f set_hostname

# Install
bash $CURRENT_DIR/mysql/install.sh
bash $CURRENT_DIR/postfix/install.sh
bash $CURRENT_DIR/dovecot/install.sh
bash $CURRENT_DIR/nginx/install.sh
bash $CURRENT_DIR/roundcube/install.sh
bash $CURRENT_DIR/autoconfig/install.sh
bash $CURRENT_DIR/spamassassin/install.sh
bash $CURRENT_DIR/autostart/install.sh
bash $CURRENT_DIR/ManagementAPI/install.sh
bash $CURRENT_DIR/dkim/install.sh

# Save the system configurations
echo "
[general]
general_hostname:__EASYMAIL_HOSTNAME__

[ssl]
public_dovecot_key:$SSL_CA_BUNDLE_FILE
private_dovecot_key:$SSL_PRIVATE_KEY_FILE

[mysql_root]
mysql_root_username:$ROOT_MYSQL_USERNAME
mysql_root_password:$ROOT_MYSQL_PASSWORD

[mysql_easymail]
mysql_easymail_database:$MYSQL_DATABASE
mysql_easymail_hostname:$MYSQL_HOSTNAME
mysql_easymail_username:$MYSQL_USERNAME
mysql_easymail_password:$MYSQL_PASSWORD

[mysql_roundcube]
mysql_roundcube_database:$ROUNDCUBE_MYSQL_DATABASE
mysql_roundcube_username:$ROUNDCUBE_MYSQL_USERNAME
mysql_roundcube_password:$ROUNDCUBE_MYSQL_PASSWORD

[roundcube_web]
roundcube_web_url:https://__EASYMAIL_HOSTNAME__
roundcube_web_username:admin@__EASYMAIL_HOSTNAME__
roundcube_web_password:$ADMIN_PASSWORD_UNENCRYPTED

[api]
api_url:https://__EASYMAIL_HOSTNAME__/api/
api_username:__EASYMAIL_MANAGEMENT_API_USERNAME__
api_password:__EASYMAIL_MANAGEMENT_API_PASSWORD__
"  >> $EASY_MAIL_DIR/config.ini

cp $CURRENT_DIR/exportDb.sh $EASY_MAIL_DIR/exportDb.sh
cp $CURRENT_DIR/importDb.sh $EASY_MAIL_DIR/importDb.sh

cp $CURRENT_DIR/post_install.sh $EASY_MAIL_DIR/post_install.sh

cp /etc/opendkim /opendkim -r

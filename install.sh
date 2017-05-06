set -e

export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export HOSTNAME=""
export SSL_CA_BUNDLE_FILE="/etc/dovecot/dovecot.pem"
export SSL_PRIVATE_KEY_FILE="/etc/dovecot/private/dovecot.pem"

# tmp workaround, please have a look at https://github.com/moby/moby/issues/13555 
apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "Please log in as root"
   exit
fi

# Check for min system requirements
if (($(($(free -mt|awk '/^Total:/{print $2}')*1)) <= 900)); then
   echo -e "The installation of EasyMail has been stopped because of the following minimum requirements:\n";
   echo -e "- RAM (or RAM + SWAP) >= 1GB\n\n";
   exit;
fi

# Update and install initially required services
apt-get update -y && apt-get install openssl python dialog cron -y

# Define some functions and variables
function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" $1
}

function get_rand_password() {
	openssl rand  32 | md5sum | awk '{print $1;}'
}

export -f set_hostname

export PASSWORD=$(get_rand_password)

export ADMIN_EMAIL="admin@__EASYMAIL_HOSTNAME__"
export ADMIN_PASSWORD=$(openssl passwd -1 $PASSWORD)

export ROOT_MYSQL_USERNAME='root'
export ROOT_MYSQL_PASSWORD=$(get_rand_password)

export MYSQL_DATABASE='mailserver'
export MYSQL_HOSTNAME='127.0.0.1'
export MYSQL_USERNAME='mailuser'
export MYSQL_PASSWORD=$(get_rand_password)

export ROUNDCUBE_MYSQL_DATABASE='roundcube_dbname'
export ROUNDCUBE_MYSQL_USERNAME='roundcube_user'
export ROUNDCUBE_MYSQL_PASSWORD=$(get_rand_password)
export ROUNDCUBE_VERSION=1.2.3

export MANAGEMENT_API_USERNAME='easyadmin'
export MANAGEMENT_API_PASSWORD=$(get_rand_password)
export MANAGEMENT_API_SECRETKEY=$(get_rand_password)

export EASY_MAIL_DIR="/opt/easymail" && mkdir $EASY_MAIL_DIR

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
bash $CURRENT_DIR/tests/install.sh

# Save the system configurations
echo "
[general]
general_hostname:

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
roundcube_web_url:
roundcube_web_username:
roundcube_web_password:$PASSWORD

[api]
api_url:
api_username:$MANAGEMENT_API_USERNAME
api_password:$MANAGEMENT_API_PASSWORD
"  >> $EASY_MAIL_DIR/config.ini

export HOSTNAME=$(cat "$EASY_MAIL_DIR/config.ini" | grep general_hostname: | awk -F':' '{ print $2;}')
cp $CURRENT_DIR/post_install.sh $EASY_MAIL_DIR/post_install.sh

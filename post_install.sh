set -e

# Check for min system requirements
if (($(($(free -mt|awk '/^Total:/{print $2}')*1)) <= 700)); then
   echo -e "EasyMail has been stopped because of the following minimum requirements:\n";
   echo -e "- RAM (or RAM + SWAP) >= 1GB\n\n";
   exit;
fi

bash /run.sh; 

# run only once
ALREADY_RUN_POST_INSTALL_FILE="/opt/easymail/already-run-post-install.txt"

if [ -e "$ALREADY_RUN_POST_INSTALL_FILE" ]; then
  exit;
fi

touch $ALREADY_RUN_POST_INSTALL_FILE

# Get variables
export EASYMAIL_CONFIG="/opt/easymail/config.ini"

export SSL_CA_BUNDLE_FILE=$(cat "$EASYMAIL_CONFIG" | grep public_dovecot_key: | awk -F':' '{ print $2;}')
export SSL_PRIVATE_KEY_FILE=$(cat "$EASYMAIL_CONFIG" | grep private_dovecot_key: | awk -F':' '{ print $2;}')

export ROUNDCUBE_MYSQL_USERNAME=$(cat "$EASYMAIL_CONFIG" | grep mysql_roundcube_username: | awk -F':' '{ print $2;}')

export MYSQL_HOSTNAME=$(cat "$EASYMAIL_CONFIG" | grep mysql_easymail_hostname: | awk -F':' '{ print $2;}')
export MYSQL_USERNAME=$(cat "$EASYMAIL_CONFIG" | grep mysql_easymail_username: | awk -F':' '{ print $2;}')

export ROOT_MYSQL_USERNAME=$(cat "$EASYMAIL_CONFIG" | grep mysql_root_username: | awk -F':' '{ print $2;}')
export OLD_ROOT_MYSQL_PASSWORD=$(cat "$EASYMAIL_CONFIG" | grep mysql_root_password: | awk -F':' '{ print $2;}')
export MYSQL_DATABASE=$(cat "$EASYMAIL_CONFIG" | grep mysql_easymail_database: | awk -F':' '{ print $2;}')
export HOSTNAME=$1

# Define some functions
function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" $1
}

function get_rand_password() {
	< /dev/urandom tr -dc A-Z-_{}[]a-z-0-9 | head -c${1:-60};
}

export -f set_hostname

# Re-generate the passwords
export ADMIN_PASSWORD_UNENCRYPTED=$(get_rand_password)
export ADMIN_PASSWORD=$(openssl passwd -1 $ADMIN_PASSWORD_UNENCRYPTED)
export ROOT_MYSQL_PASSWORD=$(get_rand_password)
export MYSQL_PASSWORD=$(get_rand_password)
export ROUNDCUBE_MYSQL_PASSWORD=$(get_rand_password)
export MANAGEMENT_API_PASSWORD=$(get_rand_password)
export MANAGEMENT_API_SECRETKEY=$(get_rand_password)

# Re-generate the Dovecot's self-signed certificate
openssl req -new -x509 -days 365000 -nodes -subj "/C=/ST=/L=/O=/CN=EasyMail" -out "$SSL_CA_BUNDLE_FILE" -keyout "$SSL_PRIVATE_KEY_FILE"

# Set HOSTNAME for auto configurations
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autoconfig.php
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autodiscover.php
	
# Set HOSTNAME for Roundcube
set_hostname /etc/nginx/sites-enabled/roundcube
	
# Set HOSTNAME for Postfix
debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME"

# Set HOSTNAME for MySQL 
export ADMIN_EMAIL="admin@$HOSTNAME"
mysql -h $MYSQL_HOSTNAME -u$ROOT_MYSQL_USERNAME -p$OLD_ROOT_MYSQL_PASSWORD << EOF

USE $MYSQL_DATABASE;

UPDATE \`virtual_domains\`
SET \`name\`='$HOSTNAME'
WHERE \`id\`='1';

UPDATE \`virtual_users\`
SET \`email\`='$ADMIN_EMAIL', \`password\`='$ADMIN_PASSWORD'
WHERE \`id\`='1';

ALTER USER 'root'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD';
EOF

# Set HOSTNAME for Dovecot
mv /var/mail/vhosts/__EASYMAIL_HOSTNAME__ /var/mail/vhosts/$HOSTNAME
sed -i "s/admin@__EASYMAIL_HOSTNAME__/admin@$HOSTNAME/g" /etc/dovecot/conf.d/20-lmtp.conf
	
# Reload services
service nginx restart 
service dovecot reload
service postfix reload
	
# Set HOSTNAME Management API
sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" /opt/easymail/ManagementAPI/config.ini
sed -i "s/__MANAGEMENT_API_SECRETKEY__/$MANAGEMENT_API_SECRETKEY/g" /opt/easymail/ManagementAPI/config.ini
sed -i "s/__MANAGEMENT_API_PASSWORD__/$MANAGEMENT_API_PASSWORD/g" /opt/easymail/ManagementAPI/config.ini

echo "Create a log dir"
mkdir /opt/easymail/logs/

echo "Kill ManagementAPI"
pkill ManagementAPI && cd /opt/easymail/ManagementAPI

echo "Run ManagementAPI"
./ManagementAPI > /opt/easymail/logs/ManagementAPI.log 2>&1 &

echo "Add new configurations to easymail config file"
sed -i "s/mysql_root_password:.*/mysql_root_password:$ROOT_MYSQL_PASSWORD/" $EASYMAIL_CONFIG
sed -i "s/mysql_easymail_password:.*/mysql_easymail_password:$MYSQL_PASSWORD/" $EASYMAIL_CONFIG
sed -i "s/mysql_roundcube_password:.*/mysql_roundcube_password:$ROUNDCUBE_MYSQL_PASSWORD/" $EASYMAIL_CONFIG
sed -i "s/roundcube_web_password:.*/roundcube_web_password:$ADMIN_PASSWORD_UNENCRYPTED/" $EASYMAIL_CONFIG
sed -i "s/api_password:.*/api_password:$MANAGEMENT_API_PASSWORD/" $EASYMAIL_CONFIG

sed -i "s/general_hostname:.*/general_hostname:$HOSTNAME/" $EASYMAIL_CONFIG
sed -i "s/roundcube_web_url:.*/roundcube_web_url:https:\/\/$HOSTNAME\//" $EASYMAIL_CONFIG
sed -i "s/roundcube_web_username:.*/roundcube_web_username:$ADMIN_EMAIL/" $EASYMAIL_CONFIG
sed -i "s/api_url:.*/api_url:https:\/\/$HOSTNAME\/api/" $EASYMAIL_CONFIG

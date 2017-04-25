set -e

export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export HOSTNAME=""
export IS_ON_DOCKER=""
export SSL_CA_BUNDLE_FILE="/etc/dovecot/dovecot.pem"
export SSL_PRIVATE_KEY_FILE="/etc/dovecot/private/dovecot.pem"

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

apt-get update -y && apt-get install openssl python dialog -y

function is_installed {
    is_installed=$(dpkg -l | grep $1 | wc -c)

    if [ $is_installed != "0" ]; then
        is_installed=1
    fi

   echo $is_installed
}

# Use config.
while [[ "$#" > 1 ]]; do case $1 in
    --config) useConfig="$2";;
    -c) useConfig="$2";;
    *) break;;
  esac; shift; shift
done

while [[ "$#" > 1 ]]; do case $1 in
    --config) useConfig="$2";;
    -c) useConfig="$2";;
    *) break;;
  esac; shift; shift
done

if [  "$useConfig" != "" ]; then
        if [ -f "$useConfig" ]; then     
                export HOSTNAME=$(cat $useConfig | grep HOSTNAME: | awk '{ print $2 }')   
                export IS_ON_DOCKER=$(cat $useConfig | grep IS_ON_DOCKER: | awk '{ print $2 }')
        else
                echo "The config file does not exist!"; exit;
        fi
fi

if [ $(is_installed php) == 1 ]; then
	echo "PHP is already installed, installation aborted"; exit
elif [ $(is_installed nginx) == 1 ]; then
	echo "Nginx is already installed, installation aborted"; exit
elif [ $(is_installed postfix) == 1 ]; then
	echo "Postfix is already installed, installation aborted"; exit
elif [ $(is_installed dovecot) == 1 ]; then
	echo "Dovecot is already installed, installation aborted"; exit
elif [ $(is_installed mysql) == 1 ]; then
	echo "MySQL is already installed, installation aborted"; exit
elif [ $(is_installed spamassassin) == 1 ]; then
	echo "SpamAssassin is already installed, installation aborted"; exit
fi

if [ "$IS_ON_DOCKER" == "" ]; then
	read -e -p "Is this installation on Docker? [N/y] " IS_ON_DOCKER
fi

IS_ON_DOCKER="${IS_ON_DOCKER:-N}"

if [ "$IS_ON_DOCKER" == "y"  ] || [ "$IS_ON_DOCKER" == "Y"  ]; then
	IS_ON_DOCKER=true
else
	IS_ON_DOCKER=false
fi


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

bash $CURRENT_DIR/mysql/install.sh
bash $CURRENT_DIR/postfix/install.sh













DOVECOT_DIR="$CURRENT_DIR/dovecot"

debconf-set-selections <<< "dovecot-core dovecot-core/ssl-cert-exists string error"
debconf-set-selections <<< "dovecot-core dovecot-core/ssl-cert-name string localhost"
debconf-set-selections <<< "dovecot-core dovecot-core/create-ssl-cert boolean true"

apt-get install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql -y

cp /etc/postfix/master.cf /etc/postfix/master.cf.orig
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig
cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig
cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
cp /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.orig
cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig 

echo "
#Automatic added by script for auto install mail server.
465     inet  n       -       n       -       -       smtpd
  -o syslog_name=postfix/smtps
  -o smtpd_tls_wrappermode=yes
  -o smtpd_sasl_auth_enable=yes
  -o smtpd_client_restrictions=permit_sasl_authenticated,reject
submission inet n       -       -       -       -       smtpd
 -o smtpd_tls_security_level=encrypt
 -o smtpd_sasl_auth_enable=yes
 -o smtpd_client_restrictions=permit_sasl_authenticated,reject
"  >> /etc/postfix/master.cf

echo "
#Automatic added by script for auto install mail server.
protocols = imap pop3 lmtp sieve	
" >> /etc/dovecot/dovecot.conf

sed -i "s/mail_location = .*/mail_location = maildir:\/var\/mail\/vhosts\/%d\/\%n/g" /etc/dovecot/conf.d/10-mail.conf
sed -i "s/#mail_privileged_group =/mail_privileged_group = mail/g" /etc/dovecot/conf.d/10-mail.conf

mkdir -p /var/mail/vhosts/__EASYMAIL_HOSTNAME__
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/mail
chown -R vmail:vmail /var/mail

sed -i "s/^#disable_plaintext_auth = .*/disable_plaintext_auth = yes/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/^auth_mechanisms = .*/auth_mechanisms = plain login/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/\!include auth-system.conf.ext/#\!include auth-system.conf.ext/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/#\!include auth-sql.conf.ext/\!include auth-sql.conf.ext/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/#ssl = .*/ssl = required/g" /etc/dovecot/conf.d/10-ssl.conf
sed -i "s#ssl_cert =.*#ssl_cert = <$SSL_CA_BUNDLE_FILE#g" /etc/dovecot/conf.d/10-ssl.conf
sed -i "s#ssl_key =.*#ssl_key = <$SSL_PRIVATE_KEY_FILE#g" /etc/dovecot/conf.d/10-ssl.conf

echo '
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}
' > /etc/dovecot/conf.d/auth-sql.conf.ext

echo " 
	driver = mysql
	connect = host=$MYSQL_HOSTNAME dbname=$MYSQL_DATABASE user=$MYSQL_USERNAME password=$MYSQL_PASSWORD
	default_pass_scheme = CRYPT
	password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';
" >> /etc/dovecot/dovecot-sql.conf.ext

chown -R vmail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot

cp $DOVECOT_DIR/10-master.conf /etc/dovecot/conf.d/10-master.conf

# Generate self-signed certificate
openssl req -new -x509 -days 365000 -nodes -subj "/C=/ST=/L=/O=/CN=EasyMail" -out "$SSL_CA_BUNDLE_FILE" -keyout "$SSL_PRIVATE_KEY_FILE"

# Configure Sieve
apt-get install dovecot-sieve dovecot-managesieved php-net-sieve apache2- -y

echo "
plugin {
	sieve = ~/.dovecot.sieve 
 	sieve_global_path = /var/lib/dovecot/sieve/default.sieve 
 	sieve_dir = ~/sieve 
 	sieve_global_dir = /var/lib/dovecot/sieve/ 
}
service managesieve-login {
 	inet_listener sieve { 
 		port = 4190 
 		address = 127.0.0.1
 	}
 
 	service_count = 1 
 	process_min_avail = 1 
 	vsz_limit = 64M 
}
service managesieve {
 	process_limit = 10 
}
protocol lda {
	mail_plugins = "sieve"
	postmaster_address = $ADMIN_EMAIL
} 	
" >> /etc/dovecot/dovecot.conf

# Kill all processes (Apache) listening on port 80 because this may prevent the start of NGINX
fuser -k 80/tcp

if [ $IS_ON_DOCKER == true ]; then
	/usr/sbin/dovecot
	/etc/init.d/postfix restart
else 
	service dovecot reload
	service postfix reload
fi






















#bash $CURRENT_DIR/dovecot/install.sh
bash $CURRENT_DIR/nginx/install.sh
bash $CURRENT_DIR/roundcube/install.sh
bash $CURRENT_DIR/autoconfig/install.sh
bash $CURRENT_DIR/spamassassin/install.sh
bash $CURRENT_DIR/autostart/install.sh
bash $CURRENT_DIR/ManagementAPI/install.sh

# after that part all the code should be executed for each container too.

# Ask for input data
if [ "$HOSTNAME" == "" ]; then
	read -p "Type hostname: " HOSTNAME
fi

# re-generate the Dovecot's self-signed certificate
openssl req -new -x509 -days 365000 -nodes -subj "/C=/ST=/L=/O=/CN=EasyMail" -out "$SSL_CA_BUNDLE_FILE" -keyout "$SSL_PRIVATE_KEY_FILE"

# Set HOSTNAME
	# Auto configurations
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autoconfig.php
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autodiscover.php
	# Roundcube
set_hostname /etc/nginx/sites-enabled/roundcube
	# Postfix
debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME"
	# MySQL 
export ADMIN_EMAIL="admin@$HOSTNAME"
mysql -h $MYSQL_HOSTNAME -u$ROOT_MYSQL_USERNAME -p$ROOT_MYSQL_PASSWORD << EOF
USE $MYSQL_DATABASE;

UPDATE \`virtual_domains\`
SET \`name\`='$HOSTNAME'
WHERE \`id\`='1';

UPDATE \`virtual_users\`
SET \`email\`='$ADMIN_EMAIL'
WHERE \`id\`='1';

EOF
	# Dovecot
mv /var/mail/vhosts/__EASYMAIL_HOSTNAME__ /var/mail/vhosts/$HOSTNAME
sed -i "s/admin@__EASYMAIL_HOSTNAME__/admin@$HOSTNAME/g" /etc/dovecot/conf.d/20-lmtp.conf
	# Reload services
service nginx restart 
if [ $IS_ON_DOCKER == true ]; then
	/usr/sbin/dovecot
	/etc/init.d/postfix reload
else 
	service dovecot reload
	service postfix reload
fi
	# DKIM
bash $CURRENT_DIR/dkim/install.sh


sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" /opt/easymail/ManagementAPI/config.ini
# restart the ManagementAPI 
pkill ManagementAPI && cd /opt/easymail/ManagementAPI && ./ManagementAPI &

echo -e "\n----------------------"
echo "Database - access:"
echo "Root MySQL username: $ROOT_MYSQL_USERNAME | password: $ROOT_MYSQL_PASSWORD"
echo "Easymail MySQL db: $MYSQL_DATABASE | username: $MYSQL_USERNAME | password: $MYSQL_PASSWORD"
echo "Roundcube MySQL db: $ROUNDCUBE_MYSQL_DATABASE | username: $ROUNDCUBE_MYSQL_USERNAME | password: $ROUNDCUBE_MYSQL_PASSWORD"

echo -e "\nApplications - access:"
echo "Roundcube: https://$HOSTNAME/ | username: $ADMIN_EMAIL | password: $PASSWORD"
echo "API url: https://$HOSTNAME/api/ | username: $MANAGEMENT_API_USERNAME | password: $MANAGEMENT_API_PASSWORD"

echo -e "\nInstallation has finished"
echo "All services have been started automatically"


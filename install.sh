export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
export HOSTNAME=""
export IS_ON_DOCKER=""
export SSL_CA_BUNDLE_FILE=""
export SSL_PRIVATE_KEY_FILE=""

function is_installed {
    is_installed=$(dpkg -l | grep $1 | wc -c)

    if [ $is_installed != "0" ]; then
        is_installed=1
    fi

   echo $is_installed
}

# Make sure only root can run our script
if [ "$(id -u)" != "0" ]; then
   echo "Please log in as root"
   exit
fi

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
                export PASSWORD=$(cat $useConfig | grep PASSWORD: | awk '{ print $2 }')
                export IS_ON_DOCKER=$(cat $useConfig | grep IS_ON_DOCKER: | awk '{ print $2 }')
		export SSL_INSTALL_OWN=$(cat $useConfig | grep SSL_INSTALL_OWN: | awk '{ print $2 }')
                export SSL_CA_BUNDLE_FILE=$(cat $useConfig | grep SSL_CA_BUNDLE_FILE: | awk '{ print $2 }')
                export SSL_PRIVATE_KEY_FILE=$(cat $useConfig | grep SSL_PRIVATE_KEY_FILE: | awk '{ print $2 }')
        else
                echo "The config file is not exit!"; exit;
        fi
fi

bash $CURRENT_DIR/event/before-install.sh

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

if [ "$HOSTNAME" == "" ]; then
	read -p "Type hostname: " HOSTNAME
fi

if [ "$PASSWORD" == "" ]; then
	read -s -p "Type admin's email password: " PASSWORD && echo -e  
fi

if [ "$SSL_INSTALL_OWN" == "" ]; then
	read -e -p "Do you want to install your own ssl certificates? [n/Y] " SSL_INSTALL_OWN 
fi

if [ "$SSL_INSTALL_OWN" == "n"  ] || [ "$SSL_INSTALL_OWN" == "N"  ]; then
	#by default use dovecot's self-signed certificate
	SSL_CA_BUNDLE_FILE=/etc/dovecot/dovecot.pem
	SSL_PRIVATE_KEY_FILE=/etc/dovecot/private/dovecot.pem
else
	if [ "$SSL_CA_BUNDLE_FILE" == "" ]; then
		while [ ! -f "$SSL_CA_BUNDLE_FILE" ]; do
			read -p "[SSL] CA Bundle file path: " SSL_CA_BUNDLE_FILE
		done
	fi
 
	if [ "$SSL_PRIVATE_KEY_FILE" == "" ]; then
		while [ ! -f "$SSL_PRIVATE_KEY_FILE" ]; do
			read -p "[SSL] Private key file path: " SSL_PRIVATE_KEY_FILE
		done 
	fi
fi


if [ "$IS_ON_DOCKER" == "" ]; then
	read -e -p "Is this installation is on Docker? [N/y] " IS_ON_DOCKER
fi


if [ "$IS_ON_DOCKER" == "y"  ] || [ "$IS_ON_DOCKER" == "Y"  ]; then
	IS_ON_DOCKER=true
else
	IS_ON_DOCKER=false
fi

function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" $1
}
export -f set_hostname

function get_rand_password() {
	openssl rand  32 | md5sum | awk '{print $1;}'
}

echo "
# EASY MAIL INSTALL CONFIGURATION

HOSTNAME: $HOSTNAME
PASSWORD: $PASSWORD
IS_ON_DOCKER: $IS_ON_DOCKER
SSL_INSTALL_OWN: $SSL_INSTALL_OWN
SSL_CA_BUNDLE_FILE: $SSL_CA_BUNDLE_FILE
SSL_PRIVATE_KEY_FILE: $SSL_PRIVATE_KEY_FILE

" > easy-mail-install.config

export ADMIN_EMAIL="admin@$HOSTNAME"
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

apt-get update

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

echo "Root MySQL username: $ROOT_MYSQL_USERNAME | password: $ROOT_MYSQL_PASSWORD"
echo "Easymail MySQL db: $MYSQL_DATABASE | username: $MYSQL_USERNAME | password: $MYSQL_PASSWORD"
echo "Roundcube MySQL db: $ROUNDCUBE_MYSQL_DATABASE | username: $ROUNDCUBE_MYSQL_USERNAME | password: $ROUNDCUBE_MYSQL_PASSWORD"
echo "API username: $MANAGEMENT_API_USERNAME | password: $MANAGEMENT_API_PASSWORD"

echo "Installation has finished"
echo "All services have been started automatically"

bash $CURRENT_DIR/event/after-install.sh


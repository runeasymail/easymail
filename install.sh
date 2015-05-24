export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export HOSTNAME
read -p "Type hostname: " HOSTNAME

export IS_ON_DOCKER
echo -e "\nIs this installation is on Docker:"

select opt in "no" "yes" ; do
	if [ "$opt" = "yes" ]; then
        IS_ON_DOCKER=true
        break
	elif [ "$opt" = "no" ]; then
        IS_ON_DOCKER=false
        break
	fi
done

function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" $1
}
export -f set_hostname

export ROOT_MYSQL_USERNAME='root'
export ROOT_MYSQL_PASSWORD='root_mysql_pass'

export MYSQL_DATABASE='mailserver'
export MYSQL_HOSTNAME='127.0.0.1'
export MYSQL_USERNAME='mailuser'
export MYSQL_PASSWORD='mailuserpass'

export ROUNDCUBE_MYSQL_DATABASE='roundcube_dbname'
export ROUNDCUBE_MYSQL_USERNAME='roundcube_user'
export ROUNDCUBE_MYSQL_PASSWORD='roundcube_pass'

apt-get update 

bash $CURRENT_DIR/mysql/install.sh
bash $CURRENT_DIR/postfix/install.sh
bash $CURRENT_DIR/dovecot/install.sh
bash $CURRENT_DIR/roundcube/install.sh
bash $CURRENT_DIR/autoconfig/install.sh
bash $CURRENT_DIR/spamassassin/install.sh

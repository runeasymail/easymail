export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

export HOSTNAME
read -p "Type hostname: " HOSTNAME

export PASSWORD
read -s -p "Type password: " PASSWORD

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

function set_password {
	sed -i "s/__EASYMAIL_PASSWORD__/$PASSWORD/g" $1
}
export -f set_password

function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/g" $1
}
export -f set_hostname

apt-get update 

bash $CURRENT_DIR/mysql/install.sh
bash $CURRENT_DIR/postfix/install.sh
bash $CURRENT_DIR/dovecot/install.sh
bash $CURRENT_DIR/roundcube/install.sh
bash $CURRENT_DIR/autoconfig/install.sh
bash $CURRENT_DIR/spamassassin/install.sh





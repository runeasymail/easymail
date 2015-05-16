export CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

##################
# Specific for Docker
#/usr/sbin/dovecot
#service postfix status
#service mysql start
##################
# Example for Docker
# apt-get update && apt-get install docker.io -y
# docker run -it -p=110:110 -p=25:25 -p=995:995 -p=8080:80 -p=587:587 -p=993:993 -p=143:143 -h <HOSTNAME>  --name="email_server"  ubuntu:14.04 /bin/sh -c "if [ -f /run.sh ]; then bash /run.sh; fi; exec /bin/bash"
###################


export HOSTNAME
read -p "Type hostname: " HOSTNAME

export PASSWORD
read -s -p "Type password: " PASSWORD

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

# Tests

# Spamassassin
# Check your local.cf syntax
# spamassassin --lint
# tail -f /var/log/spamassassin/spamd.log
# Message with content  XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X must always be spam.

# Postfix
# postmap -q admin@$HOSTNAME mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf must return 1
# postmap -q alias@$HOSTNAME mysql:/etc/postfix/mysql-virtual-alias-maps.cf must return admin@$HOSTNAME
# postmap -q $HOSTNAME mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf must return 1

# Debugging
# openssl passwd -1 123456  WORKING CUURECTLY
# openssl passwd -1 123456  = $1$pfhfftkU$3/0sv66/HiM0Dn6l3qRiq/


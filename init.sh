#BASIC 
CURRENT_DIR=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# What I have to improve in this script.
# Make satisfaction way for certificate.

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

HOSTNAME="TYPE_YOUR_HOSTNAME_HERE"
PASSWORD="TYPE_YOUR_PASSWORD_HERE"

function set_password {
	sed -i "s/__EASYMAIL_PASSWORD__/$PASSWORD/" $1
}

function set_hostname {
	sed -i "s/__EASYMAIL_HOSTNAME__/$HOSTNAME/" $1
}

debconf-set-selections <<< "mysql-server mysql-server/root_password password $PASSWORD"
debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $PASSWORD"
debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"
debconf-set-selections <<< "dovecot-core dovecot-core/ssl-cert-exists string error"
debconf-set-selections <<< "dovecot-core dovecot-core/ssl-cert-name string localhost"
debconf-set-selections <<< "dovecot-core dovecot-core/create-ssl-cert boolean true"

apt-get update && apt-get install expect postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql mysql-server -y

mysql_install_db
expect -c "

set timeout 10
spawn mysql_secure_installation

expect \"Enter current password for root (enter for none):\"
send \"$PASSWORD\r\"

expect \"Change the root password?\"
send \"n\r\"

expect \"Remove anonymous users?\"
send \"y\r\"

expect \"Disallow root login remotely?\"
send \"y\r\"

expect \"Remove test database and access to it?\"
send \"y\r\"

expect \"Reload privilege tables now?\"
send \"y\r\"

expect eof"

mysqladmin -uroot -p$PASSWORD create mailserver	
mysql -uroot -p$PASSWORD << EOF
GRANT SELECT ON mailserver.* TO 'mailuser'@'127.0.0.1' IDENTIFIED BY 'mailuserpass';
FLUSH PRIVILEGES;
USE mailserver;
CREATE TABLE \`virtual_domains\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`name\` varchar(50) NOT NULL,
  PRIMARY KEY (\`id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE \`virtual_users\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`domain_id\` int(11) NOT NULL,
  \`password\` varchar(106) NOT NULL,
  \`email\` varchar(100) NOT NULL,
  PRIMARY KEY (\`id\`),
  UNIQUE KEY \`email\` (\`email\`),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE \`virtual_aliases\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`domain_id\` int(11) NOT NULL,
  \`source\` varchar(100) NOT NULL,
  \`destination\` varchar(100) NOT NULL,
  PRIMARY KEY (\`id\`),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;


INSERT INTO \`mailserver\`.\`virtual_domains\` (\`id\` ,\`name\`) 
VALUES('1', '$HOSTNAME');
  
INSERT INTO \`mailserver\`.\`virtual_users\` (\`id\`, \`domain_id\`, \`password\` , \`email\`)
VALUES ('1', '1', '\$1\$pfhfftkU\$3/0sv66/HiM0Dn6l3qRiq/', 'admin@$HOSTNAME');
# This password $1$pfhfftkU$3/0sv66/HiM0Dn6l3qRiq/ IS 123456 
# note must escape \$ in that way in linux EOP  

INSERT INTO \`mailserver\`.\`virtual_aliases\` (\`id\`, \`domain_id\`, \`source\`, \`destination\`)
VALUES('1', '1', 'alias@$HOSTNAME', 'admin@$HOSTNAME');
EOF

cp /etc/postfix/main.cf /etc/postfix/main.cf.orig

postconf -e mydestination=localhost
postconf -# smtpd_tls_session_cache_database
postconf -# smtp_tls_session_cache_database
postconf -e smtpd_tls_cert_file=/etc/dovecot/dovecot.pem
postconf -e smtpd_tls_key_file=/etc/dovecot/private/dovecot.pem
postconf -e smtpd_use_tls=yes
postconf -e smtpd_tls_auth_only=yes
postconf -e smtpd_sasl_type=dovecot
postconf -e smtpd_sasl_path=private/auth
postconf -e smtpd_sasl_auth_enable=yes
postconf -e smtpd_recipient_restrictions=permit_sasl_authenticated,permit_mynetworks,reject_unauth_destination
postconf -e virtual_transport=lmtp:unix:private/dovecot-lmtp
postconf -e virtual_mailbox_domains=mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf
postconf -e virtual_mailbox_maps=mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf
postconf -e virtual_alias_maps=mysql:/etc/postfix/mysql-virtual-alias-maps.cf	

echo "
user = mailuser
password = mailuserpass
hosts = 127.0.0.1
dbname = mailserver
query = SELECT 1 FROM virtual_domains WHERE name='%s'
" > /etc/postfix/mysql-virtual-mailbox-domains.cf

echo "
user = mailuser
password = mailuserpass
hosts = 127.0.0.1
dbname = mailserver
query = SELECT 1 FROM virtual_users WHERE email='%s'
" > /etc/postfix/mysql-virtual-mailbox-maps.cf

echo "
user = mailuser
password = mailuserpass
hosts = 127.0.0.1
dbname = mailserver
query = SELECT destination FROM virtual_aliases WHERE source='%s'
" > /etc/postfix/mysql-virtual-alias-maps.cf

cp /etc/postfix/master.cf /etc/postfix/master.cf.orig
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig
cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig
cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig
cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
cp /etc/dovecot/conf.d/10-ssl.conf /etc/dovecot/conf.d/10-ssl.conf.orig

echo "
#Automatic added by script for auto install mail server.
smtps      inet n       -       -       -       -       smtpd
submission inet n       -       -       -       -       smtpd
 -o smtpd_tls_security_level=encrypt
 -o smtpd_sasl_auth_enable=yes
 -o smtpd_client_restrictions=permit_sasl_authenticated,reject
"  >> /etc/postfix/master.cf

echo "
#Automatic added by script for auto install mail server.
protocols = imap pop3 lmtp	
" >> /etc/dovecot/dovecot.conf

sed -i "s/mail_location = .*/mail_location = maildir:\/var\/mail\/vhosts\/%d\/\%n/g" /etc/dovecot/conf.d/10-mail.conf
sed -i "s/#mail_privileged_group =/mail_privileged_group = mail/g" /etc/dovecot/conf.d/10-mail.conf

mkdir -p /var/mail/vhosts/$HOSTNAME
groupadd -g 5000 vmail
useradd -g vmail -u 5000 vmail -d /var/mail
chown -R vmail:vmail /var/mail

sed -i "s/^#disable_plaintext_auth = .*/disable_plaintext_auth = yes/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/^auth_mechanisms = .*/auth_mechanisms = plain login/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/\!include auth-system.conf.ext/#\!include auth-system.conf.ext/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/#\!include auth-sql.conf.ext/\!include auth-sql.conf.ext/g" /etc/dovecot/conf.d/10-auth.conf
sed -i "s/#ssl = .*/ssl = required/g" /etc/dovecot/conf.d/10-ssl.conf

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
	connect = host=127.0.0.1 dbname=mailserver user=mailuser password=mailuserpass
	default_pass_scheme = CRYPT
	password_query = SELECT email as user, password FROM virtual_users WHERE email='%u';
" >> /etc/dovecot/dovecot-sql.conf.ext

chown -R vmail:dovecot /etc/dovecot
chmod -R o-rwx /etc/dovecot

cp $CURRENT_DIR/10-master.conf /etc/dovecot/conf.d/10-master.conf

service dovecot restart
service postfix restart

# INSTALL Roundcube and all its dependences
apt-get install nginx php5-fpm php5-mcrypt php5-intl php5-mysql -y

rm -r /etc/nginx/sites-enabled/*
cp $CURRENT_DIR/nginx_config_for_roundcube /etc/nginx/sites-enabled/roundcube
set_hostname /etc/nginx/sites-enabled/roundcube

cd /tmp && wget http://netcologne.dl.sourceforge.net/project/roundcubemail/roundcubemail/1.1.1/roundcubemail-1.1.1-complete.tar.gz
tar -xvzf roundcubemail-1.1.1-complete.tar.gz
mkdir /usr/share/roundcubemail
cp -r roundcubemail-1.1.1/ /usr/share/nginx/roundcubemail
cd /usr/share/nginx/roundcubemail/
sed -i "s/;cgi.fix_pathinfo=.*/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini


mysqladmin -uroot -p$PASSWORD create roundcube	
mysql -uroot -p$PASSWORD << EOF
GRANT SELECT ON roundcube.* TO 'roundcube'@'127.0.0.1' IDENTIFIED BY '';
GRANT EXECUTE, SHOW VIEW, ALTER, ALTER ROUTINE, CREATE, CREATE ROUTINE, CREATE TEMPORARY TABLES, CREATE VIEW, DELETE, DROP, EVENT, INDEX, INSERT, REFERENCES, TRIGGER, UPDATE, LOCK TABLES ON roundcube.* TO 'roundcube'@'127.0.0.1' IDENTIFIED BY '$PASSWORD';
GRANT SELECT, UPDATE  ON mailserver.* TO 'roundcube'@'127.0.0.1';
FLUSH PRIVILEGES;
USE roundcube;
EOF

chmod -R 644 /usr/share/nginx/roundcubemail/temp /usr/share/nginx/roundcubemail/logs
cp $CURRENT_DIR/roundcube_config /usr/share/nginx/roundcubemail/config/config.inc.php
set_password /usr/share/nginx/roundcubemail/config/config.inc.php

mysql -uroot -p$PASSWORD roundcube < /usr/share/nginx/roundcubemail/SQL/mysql.initial.sql
rm -r /usr/share/nginx/roundcubemail/installer

cd /usr/share/nginx/roundcubemail/plugins/password/
cp config.inc.php.dist config.inc.php 

sed -i "s/<?php/<?php \n # PLEASE READ ME \n #Some array values are overwritten in the end of this file!/" config.inc.php
cat $CURRENT_DIR/roundcube_password_plugin_config >> /usr/share/nginx/roundcubemail/plugins/password/config.inc.php
set_password /usr/share/nginx/roundcubemail/plugins/password/config.inc.php

service php5-fpm restart
service nginx reload

# Install autoconfig and autodiscover
mkdir /usr/share/nginx/autoconfig_and_autodiscover
cp $CURRENT_DIR/autoconfig.php /usr/share/nginx/autoconfig_and_autodiscover/
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autoconfig.php

cp $CURRENT_DIR/autodiscover.php /usr/share/nginx/autoconfig_and_autodiscover/
set_hostname /usr/share/nginx/autoconfig_and_autodiscover/autodiscover.php

cp $CURRENT_DIR/nginx_config_for_autoconfig_and_autodiscover /etc/nginx/sites-enabled/autoconfig_and_autodiscover
set_hostname /etc/nginx/sites-enabled/nginx_config_for_autoconfig_and_autodiscover

# Install SpamAssassin
apt-get install spamassassin spamc -y
groupadd spamd
useradd -g spamd -s /bin/false -d /var/log/spamassassin spamd
mkdir /var/log/spamassassin
chown spamd:spamd /var/log/spamassassin
cp /etc/default/spamassassin /etc/default/spamassassin.orig
sed -i "s/ENABLED=0/ENABLED=1/" /etc/default/spamassassin
sed -i "s/CRON=0/CRON=1/" /etc/default/spamassassin

# Clean version 
# SAHOME="/var/log/spamassassin/" 
# OPTIONS="--create-prefs --max-children 2 --username spamd -H ${SAHOME} -s ${SAHOME}spamd.log"
sed -i "s/OPTIONS=.*/SAHOME=\"\/var\/log\/spamassassin\/\"\nOPTIONS=\"--create-prefs --max-children 2 --username spamd -H \${SAHOME} -s \${SAHOME}spamd.log\"/" /etc/default/spamassassin

# ADD "-o content_filter=spamassassin" AFTER smtp      inet  n       -       -       -       -       smtpd
sed -i "s/smtp .* smtpd/smtp      inet  n       -       -       -       -       smtpd\n -o content_filter=spamassassin/" /etc/postfix/master.cf

echo "
spamassassin unix -     n       n       -       -       pipe
 user=spamd argv=/usr/bin/spamc -f -e
 /usr/sbin/sendmail -oi -f \${sender} \${recipient}
"  >> /etc/postfix/master.cf
service postfix restart
service spamassassin restart
 
#Move spam message to spam folder
apt-get install dovecot-sieve dovecot-managesieved

echo "
protocol lmtp {
	postmaster_address = admin@$HOSTNAME
	mail_plugins = \$mail_plugins sieve
}
" >> /etc/dovecot/conf.d/20-lmtp.conf
 
 
echo "
plugin {
 sieve = ~/.dovecot.sieve
 sieve_global_path = /var/lib/dovecot/sieve/default.sieve
 sieve_dir = ~/sieve
 sieve_global_dir = /var/lib/dovecot/sieve/
}
" > /etc/dovecot/conf.d/90-sieve.conf
 
service dovecot restart
mkdir /var/lib/dovecot/sieve/
echo "
require \"fileinto\";
if header :contains \"X-Spam-Flag\" \"YES\" {
  fileinto \"Junk\";
}
" > /var/lib/dovecot/sieve/default.sieve
chown -R vmail:vmail /var/lib/dovecot
sievec /var/lib/dovecot/sieve/default.sieve

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




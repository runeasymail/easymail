debconf-set-selections <<< "postfix postfix/mailname string $HOSTNAME"
debconf-set-selections <<< "postfix postfix/main_mailer_type string 'Internet Site'"

apt-get install postfix postfix-mysql -y

mysqladmin -u$ROOT_MYSQL_USERNAME -p$ROOT_MYSQL_PASSWORD create $MYSQL_DATABASE	
mysql -h $MYSQL_HOSTNAME -u$ROOT_MYSQL_USERNAME -p$ROOT_MYSQL_PASSWORD << EOF
GRANT SELECT ON $MYSQL_DATABASE.* TO '$MYSQL_USERNAME'@'$MYSQL_HOSTNAME' IDENTIFIED BY '$MYSQL_PASSWORD';
FLUSH PRIVILEGES;
USE $MYSQL_DATABASE;
CREATE TABLE \`virtual_domains\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`name\` varchar(50) NOT NULL,
  PRIMARY KEY (\`id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE \`virtual_users\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`domain_id\` int(11) NOT NULL,
  \`password\` char(36) NOT NULL,
  \`email\` varchar(100) NOT NULL,
  PRIMARY KEY (\`id\`),
  UNIQUE KEY \`email\` (\`email\`),
  FOREIGN KEY (domain_id) REFERENCES virtual_domains(id) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

CREATE TABLE \`virtual_aliases\` (
  \`id\` int(11) NOT NULL auto_increment,
  \`source\` varchar(100) NOT NULL,
  \`destination\` varchar(100) NOT NULL,
  PRIMARY KEY (\`id\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
 
CREATE TABLE \`recipient_bcc\` (
 \`from_address\` varchar(100) NOT NULL,
 \`to_address\` varchar(100) NOT NULL,
 KEY \`from_address\` (\`from_address\`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT INTO \`virtual_domains\` (\`id\` ,\`name\`) 
VALUES('1', '$HOSTNAME');
  
INSERT INTO \`virtual_users\` (\`id\`, \`domain_id\`, \`password\` , \`email\`)
VALUES ('1', '1', '$ADMIN_PASSWORD', '$ADMIN_EMAIL');
EOF

cp /etc/postfix/main.cf /etc/postfix/main.cf.orig

postconf -e mydestination=localhost
postconf -# smtpd_tls_session_cache_database
postconf -# smtp_tls_session_cache_database
postconf -e smtpd_tls_cert_file=$SSL_CA_Bundle_File
postconf -e smtpd_tls_key_file=$SSL_Private_Key_File
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
postconf -e recipient_bcc_maps=mysql:/etc/postfix/mysql-recipient-bcc-maps.cf	

# increase message limit to 25 MB
postconf -e message_size_limit=26214400

function postfix_mysql_file {
	echo "user = $MYSQL_USERNAME
password = $MYSQL_PASSWORD
hosts = $MYSQL_HOSTNAME
dbname = $MYSQL_DATABASE 
$1 " > $2
}

cd /etc/postfix/
postfix_mysql_file "query = SELECT 1 FROM virtual_domains WHERE name='%s'" mysql-virtual-mailbox-domains.cf
postfix_mysql_file "query = SELECT 1 FROM virtual_users WHERE email='%s'" mysql-virtual-mailbox-maps.cf
postfix_mysql_file "query = SELECT destination FROM virtual_aliases WHERE source='%s'" mysql-virtual-alias-maps.cf
postfix_mysql_file "query = SELECT to_address FROM recipient_bcc WHERE from_address='%s'" mysql-recipient-bcc-maps.cf

if [ $IS_ON_DOCKER == true ]; then 
	/etc/init.d/postfix start
else 
	service postfix start
fi


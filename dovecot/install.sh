debconf-set-selections <<< "dovecot-core dovecot-core/ssl-cert-exists string error"
debconf-set-selections <<< "dovecot-core dovecot-core/ssl-cert-name string localhost"
debconf-set-selections <<< "dovecot-core dovecot-core/create-ssl-cert boolean true"

apt-get install dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql -y

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
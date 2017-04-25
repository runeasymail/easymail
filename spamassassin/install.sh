# Install SpamAssassin
set -e

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

# ADD "-o content_filter=spamassassin\n-o receive_override_options=no_address_mappings" AFTER smtp      inet  n       -       -       -       -       smtpd
sed -i "s/smtp .* smtpd/smtp      inet  n       -       -       -       -       smtpd\n -o content_filter=spamassassin\n -o receive_override_options=no_address_mappings/" /etc/postfix/master.cf

echo "
spamassassin unix -     n       n       -       -       pipe
 user=spamd argv=/usr/bin/spamc -f -e
 /usr/sbin/sendmail -oi -f \${sender} \${recipient}
"  >> /etc/postfix/master.cf

if [ $IS_ON_DOCKER == true ]; then
	chown -R postfix:postfix /var/spool/postfix/maildrop/
	chmod -R 0770 /var/spool/postfix/maildrop/ 
	postfix reload
else 
	service postfix restart
fi
service spamassassin restart
 
#Move spam message to spam folder
apt-get install dovecot-sieve dovecot-managesieved -y

echo "
protocol lmtp {
	postmaster_address = admin@__EASYMAIL_HOSTNAME__
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
 

mkdir /var/lib/dovecot/sieve/
echo "
require \"fileinto\";
if header :contains \"X-Spam-Flag\" \"YES\" {
	fileinto \"Junk\";
}
" > /var/lib/dovecot/sieve/default.sieve
chown -R vmail:vmail /var/lib/dovecot
sievec /var/lib/dovecot/sieve/default.sieve

service dovecot restart

#if [ $IS_ON_DOCKER == true ]; then
#	/usr/sbin/dovecot
#	/etc/init.d/postfix restart
#else 
#	service dovecot restart
#fi

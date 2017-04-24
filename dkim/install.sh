# Install DKIM

apt-get install opendkim opendkim-tools -y

echo "
AutoRestart             Yes
AutoRestartRate         10/1h
UMask                   002
Syslog                  yes
SyslogSuccess           Yes
LogWhy                  Yes

Canonicalization        relaxed/simple

ExternalIgnoreList      refile:/etc/opendkim/TrustedHosts
InternalHosts           refile:/etc/opendkim/TrustedHosts
KeyTable                refile:/etc/opendkim/KeyTable
SigningTable            refile:/etc/opendkim/SigningTable

Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256

UserID                  opendkim:opendkim

Socket                  inet:12301@localhost
" > /etc/opendkim.conf

echo 'SOCKET="inet:12301@localhost"' > /etc/default/opendkim

echo "
milter_protocol = 2
milter_default_action = accept
smtpd_milters = unix:/spamass/spamass.sock, inet:localhost:12301
non_smtpd_milters = unix:/spamass/spamass.sock, inet:localhost:12301
" >>  /etc/postfix/main.cf

mkdir /etc/opendkim/keys -p

echo "
127.0.0.1
localhost
192.168.0.1/24

*$HOSTNAME
# add more domains
#*<DOMAIN>
" > /etc/opendkim/TrustedHosts

echo "
mail._domainkey.$HOSTNAME $HOSTNAME:mail:/etc/opendkim/keys/$HOSTNAME/mail.private

# add more domains in following format.
#mail._domainkey.<DOMAIN> <DOMAIN>:mail:/etc/opendkim/keys/<DOMAIN>/mail.private
" > /etc/opendkim/KeyTable

echo "
*@$HOSTNAME mail._domainkey.$HOSTNAME

# Add more domains in following format.
#*@<DOMAIN> mail._domainkey.<DOMAIN>
" > /etc/opendkim/SigningTable

cd /etc/opendkim/keys && mkdir $HOSTNAME && cd $HOSTNAME
opendkim-genkey -s mail -d $HOSTNAME
chown opendkim:opendkim mail.private

service postfix restart
service opendkim restart

echo "Create mail._domainkey.$HOSTNAME TXT record with following content"
echo ""
tail mail.txt  -n 1 | awk '{ print $1 }' | sed 's/p=/v=DKIM1; k=rsa; p=/g'
echo ""



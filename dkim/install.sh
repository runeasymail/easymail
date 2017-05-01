# Install DKIM
set -e

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

" > /etc/opendkim/TrustedHosts

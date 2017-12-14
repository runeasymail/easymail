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
KeyTable                dsn:mysql://root:$ROOT_MYSQL_PASSWORD@localhost/mailserver/table=dkim?keycol=id?datacol=domain_name,selector,private_key
SigningTable            dsn:mysql://root:$ROOT_MYSQL_PASSWORD@localhost/mailserver/table=dkim?keycol=domain_name?datacol=id


Mode                    sv
PidFile                 /var/run/opendkim/opendkim.pid
SignatureAlgorithm      rsa-sha256

UserID                  opendkim:opendkim

Socket                  inet:12301@localhost

RequireSafeKeys         false

Selector                mail

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

wget http://mirrors.kernel.org/ubuntu/pool/universe/libo/libopendbx/libopendbx1-mysql_1.4.6-9build1_amd64.deb
dpkg -i libopendbx1-mysql_1.4.6-9build1_amd64.deb

mysql -h $MYSQL_HOSTNAME -u$ROOT_MYSQL_USERNAME -p$ROOT_MYSQL_PASSWORD << EOF
USE $MYSQL_DATABASE;
CREATE TABLE IF NOT EXISTS dkim (
  id int(11) NOT NULL AUTO_INCREMENT,
  domain_name varchar(50) NOT NULL,
  selector varchar(50) NOT NULL,
  private_key text NOT NULL,
  public_key text NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=1 DEFAULT CHARSET=utf8;
EOF

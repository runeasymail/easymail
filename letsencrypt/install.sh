#install let's encrypt

cd /
mkdir -p /ssl
cd /ssl
#wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py
cp $CURRENT_DIR/letsencrypt/acme-tiny.py /ssl/acme_tiny.py
openssl genrsa 4096 > account.key
openssl genrsa 4096 > domain.key
openssl req -new -sha256 -key domain.key -subj "/CN=${HOSTNAME}" > domain.csr
mkdir -p /var/www/challenges/
sed -i "s|# __EASY_MAIL_INCLUDE_LETSENCRYPT__|include $CURRENT_DIR/letsencrypt/lets_encrypt.conf;|g" /etc/nginx/sites-enabled/roundcube
service nginx reload
python acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir /var/www/challenges/ > ./signed.crt
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem
cat signed.crt intermediate.pem > chained.pem

cp /ssl/chained.pem $SSL_CA_BUNDLE_FILE
cp /ssl/domain.key $SSL_PRIVATE_KEY_FILE

if [ $IS_ON_DOCKER == true ]; then
	/usr/sbin/dovecot
	/etc/init.d/postfix restart
else 
	service dovecot restart
fi

service nginx reload
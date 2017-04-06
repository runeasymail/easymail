#install let's encrypt

openssl req -new -sha256 -key domain.key -subj "/CN=${HOSTNAME}" > domain.csr
python acme_tiny.py --account-key ./account.key --csr ./domain.csr --acme-dir /var/www/challenges/ > ./signed.crt
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

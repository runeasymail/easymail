cd /
mkdir -p /ssl
cd /ssl
#wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py
cp $CURRENT_DIR/letsencrypt/acme-tiny.py /ssl/acme_tiny.py
openssl genrsa 4096 > account.key
openssl genrsa 4096 > domain.key
mkdir -p /var/www/challenges/
sed -i "s|# __EASY_MAIL_INCLUDE_LETSENCRYPT__|include $CURRENT_DIR/letsencrypt/lets_encrypt.conf;|g" /etc/nginx/sites-enabled/roundcube
service nginx reload
wget -O - https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem > intermediate.pem

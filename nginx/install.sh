# Install Nginx
set -e

apt-get update -y 
apt-get install nginx -y 

rm -r /etc/nginx/sites-enabled/*

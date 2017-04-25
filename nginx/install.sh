# Install Nginx
set -e
echo "Step 1!"
exit;
apt-get update -y 
apt-get install nginx -y 

rm -r /etc/nginx/sites-enabled/*

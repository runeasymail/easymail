# Set up the bash script for autostarting the services in case of reboot
set -e

AUTOSTART_DIR="$CURRENT_DIR/autostart"

cp $AUTOSTART_DIR/run.sh /run.sh

if [ $IS_ON_DOCKER == true ]; then 
  chmod +x /run.sh
  sh /run.sh
fi

echo "cd $EASY_MAIL_DIR/ManagementAPI && ./ManagementAPI &" >> /run.sh

# Set up the bash script for autostarting the services in case of reboot

AUTOSTART_DIR="$CURRENT_DIR/autostart"

cp $AUTOSTART_DIR/run.sh /run.sh

echo "cd $EASY_MAIL_DIR/ManagementAPI && ./ManagementAPI" >> /run.sh

if [ $IS_ON_DOCKER == true ]; then 
  chmod +x /run.sh
  sh /run.sh
fi

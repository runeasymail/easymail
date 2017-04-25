# Set up the bash script for autostarting the services in case of reboot
set -e

AUTOSTART_DIR="$CURRENT_DIR/autostart"

cp $AUTOSTART_DIR/run.sh /run.sh
chmod +x /run.sh

echo "cd $EASY_MAIL_DIR/ManagementAPI && ./ManagementAPI &" >> /run.sh

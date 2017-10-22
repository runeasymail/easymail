export EASYMAIL_CONFIG="/opt/easymail/config.ini"

export HOSTNAME=$(cat "$EASYMAIL_CONFIG" | grep mysql_easymail_hostname: | awk -F':' '{ print $2;}')
export DATABASE=$(cat "$EASYMAIL_CONFIG" | grep mysql_easymail_database: | awk -F':' '{ print $2;}')
export DATABASE2=$(cat "$EASYMAIL_CONFIG" | grep mysql_roundcube_database: | awk -F':' '{ print $2;}')

export USERNAME=$(cat "$EASYMAIL_CONFIG" | grep mysql_root_username: | awk -F':' '{ print $2;}')
export PASSWORD=$(cat "$EASYMAIL_CONFIG" | grep mysql_root_password: | awk -F':' '{ print $2;}')

mysqldump -u$USERNAME -p$PASSWORD -h$HOSTNAME --databases $DATABASE $DATABASE2 > /opt/easymail/dbBackup.sql

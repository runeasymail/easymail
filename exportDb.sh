export EASYMAIL_CONFIG="/opt/easymail/config.ini"

export DATABASE=$(cat "$EASYMAIL_CONFIG" | grep mysql_easymail_database: | awk -F':' '{ print $2;}')
export DATABASE2=$(cat "$EASYMAIL_CONFIG" | grep mysql_roundcube_database: | awk -F':' '{ print $2;}')

export USERNAME=$(cat "$EASYMAIL_CONFIG" | grep mysql_root_username: | awk -F':' '{ print $2;}')
export PASSWORD=$(cat "$EASYMAIL_CONFIG" | grep mysql_root_password: | awk -F':' '{ print $2;}')

mysqldump -u$USERNAME -p$PASSWORD --databases $DATABASE $DATABASE2 > /opt/easymail/data/mysql/db.sql

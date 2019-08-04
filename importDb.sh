export EASYMAIL_CONFIG="/opt/easymail/config.ini"

export DATABASE=$(cat "$EASYMAIL_CONFIG" | grep mysql_easymail_database: | awk -F':' '{ print $2;}')
export DATABASE2=$(cat "$EASYMAIL_CONFIG" | grep mysql_roundcube_database: | awk -F':' '{ print $2;}')

export USERNAME=$(cat "$EASYMAIL_CONFIG" | grep mysql_root_username: | awk -F':' '{ print $2;}')
export PASSWORD=$(cat "$EASYMAIL_CONFIG" | grep mysql_root_password: | awk -F':' '{ print $2;}')

mysql -u$USERNAME -p$PASSWORD -e "DROP DATABASE IF EXISTS $DATABASE; CREATE DATABASE $DATABASE;"
mysql -u$USERNAME -p$PASSWORD -e "DROP DATABASE IF EXISTS $DATABASE2; CREATE DATABASE $DATABASE2;"
mysql -u$USERNAME -p$PASSWORD < /opt/easymail/data/mysql/db.sql

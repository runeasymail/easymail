# Tests

# Spamassassin
# Check your local.cf syntax
# spamassassin --lint
# tail -f /var/log/spamassassin/spamd.log
# Message with content  XJS*C4JDBQADN1.NSBN3*2IDNEN*GTUBE-STANDARD-ANTI-UBE-TEST-EMAIL*C.34X must always be spam.

# Postfix
# postmap -q admin@$HOSTNAME mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf must return 1
# postmap -q alias@$HOSTNAME mysql:/etc/postfix/mysql-virtual-alias-maps.cf must return admin@$HOSTNAME
# postmap -q $HOSTNAME mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf must return 1

# Debugging
# openssl passwd -1 123456  WORKING CUURECTLY
# openssl passwd -1 123456  = $1$pfhfftkU$3/0sv66/HiM0Dn6l3qRiq/

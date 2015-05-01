# easymail - easy way for installing mail server
This script install:
- Dovecot
- Postfix
- Roundcube
- SpamAssassin
- Nginx 
- Mysql

## Requirement
- Dedicated machine or Virtual private server (VPS) and parametres not lower than:
  - RAM 512 MB 
  - HDD/SSD 10 GB.
- Fresh installed Debian or Ubuntu server with 14.04 or newer.

## Instalation
To run installation we have to:
- Update the package lists from the repositories ```apt-get update``` 
- Install git if we don't have it ```apt-get install git -y ```
- Clone the "easymail" repository ```git clone git@github.com:GyunerZeki/easymail.git /easymail```
- Run bash script ```bash /easymail/init.sh```

or just run:
```
apt-get update && apt-get install git -y && git clone git@github.com:GyunerZeki/easymail.git /easymail && bash /easymail/init.sh
```



# EasyMail - easy way for installing mail server
![Logo](https://raw.githubusercontent.com/GyunerZeki/EasyMail/master/resources/easymail-logo.png)

## Dependencies (will be installed automatically)
- Dovecot
- Postfix
- Roundcube
- SpamAssassin
- Nginx 
- MySQL

## Configuration
- Dedicated machine or Virtual private server (VPS) and parametres not lower than:
  - RAM 512 MB 
  - HDD/SSD 10 GB.
- Fresh installed Debian or Ubuntu server with 14.04 or newer.

## (optional) Using with Docker container
Example configuration for Docker usage:
```
docker run -it -p=110:110 -p=25:25 -p=995:995 -p=80:80 -p=443:443  -p=587:587 -p=993:993 -p=143:143 -p=465:465 -h "your-hostname.here" --name="easymail"  ubuntu:14.04 /bin/sh -c "if [ -f /run.sh ]; then bash /run.sh; fi; exec /bin/bash"
```

## Instalation
To run installation we have to:
- Update the package lists from the repositories ```apt-get update``` 
- Install git if we don't have it ```apt-get install git -y ```
- Clone the "easymail" repository ```git clone https://github.com/GyunerZeki/easymail.git /easymail```
- Run bash script ```bash /easymail/install.sh```

or just run:
```
apt-get update && apt-get install git -y && git clone https://github.com/GyunerZeki/easymail.git /easymail && bash /easymail/install.sh
```

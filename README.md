# EasyMail - easy way for installing mail server
![Logo](https://raw.githubusercontent.com/GyunerZeki/EasyMail/master/resources/easymail-logo.png)

Below are described all steps required for the configuration of the mail server. Before we start a few clarifications are required. For the installation and configurations below we use two domain names. One for the mail server and a second one for the email domain which will be used for the email accounts _(for example: contacts@example.com)_. For the mail server we will use:

    mail.example.com
  
And for the email domain name:

    example.com 
  
Feel free to change them to your own domains or sub domains. But keep in mind something very important. The two domains must be registered and verified. Otherwise you take the risk your server or IP address to be blocked.

## Dependencies
Below are listed dependencies which will be installed automatically during the installation of “EasyMail”:
- Dovecot
- Postfix
- Roundcube
- SpamAssassin
- Nginx 
- MySQL

## Requirements
- Dedicated machine or Virtual private server _(VPS)_ and parametres not lower than:
  - RAM 512 MB 
  - HDD/SSD 10 GB.
- Fresh installed Debian or Ubuntu server with 14.04 or newer.

## Build on Docker (optional)
There are cases when we may want to build the mail server on Docker. To do so, follow the steps below.

Install docker if you still don't have it on your machine. For further information check <a href="https://docs.docker.com/engine/installation/" target="_blank">Docker installation</a>.

For this tutorial we will use a docker image of Ubuntu 14.04. Go to the terminal of your machine and execute the following command:
```
docker run -it -p=110:110 -p=25:25 -p=995:995 -p=80:80 -p=443:443  -p=587:587 -p=993:993 -p=143:143 -h "mail.example.com" --name="easymail" -v /etc/ssl/certs/:/etc/ssl/certs/ ubuntu:14.04 /bin/sh -c "if [ -f /run.sh ]; then bash /run.sh; fi; exec /bin/bash"
```

Further explanations are required. The command above will build a new container _(named “easymail”)_ with a new fresh installation of Ubuntu 14.04 and mapping for the following ports: 110, 25, 995, 80, 443, 587, 993 and 143.

For the proper work of the mail server, it is important each of those ports to be freed and not occupied by the services running on your physical machine. Each of them is used for:

    110 - POP3
    25 - SMTP (Non-Exctypted) used by Postfix
    995 - POP3 with SSL
    80 - web service Nginx
    443 - web service Nginx with SSL
    587 - SMTP (StartTLS)
    993 - IMAP (SSL)
    143 - IMAP (StartTLS)
  
If any of the ports above is already occupied you will have to use another one or to free them. For example, if you have a web services installed on your physical machine, you most probably use ports 80 and 443, so you will have to use different ports in order to finish the installation above. For example you can use 8080 instead of 80 and 44380 instead of 443. The command above will change: 
```
docker run -it -p=110:110 -p=25:25 -p=995:995 -p=8080:80 -p=44380:443  -p=587:587 -p=993:993 -p=143:143 -h "mail.example.com" --name="easymail" -v /etc/ssl/certs/:/etc/ssl/certs/ ubuntu:14.04 /bin/sh -c "if [ -f /run.sh ]; then bash /run.sh; fi; exec /bin/bash"
```

As you may have noticed, during the installation of the container we have mapped the directory: /etc/ssl/certs/. This is the directory which contains the SSL certificates for the domain name of the mail server - mail.example.com. We can use the SSL certificates to encrypt the communication with the mail server or we can skip this option. This is entirely an optional step.

When the creation of the container completes, you will be let inside the Docker container. Continue with the installation of “EasyMail”.

## Instalation
Execute the following commands:
```
apt-get install nano
apt-get update && apt-get install git -y
```

If you use Docker, you have to install git because the docker image above does not have it.

Clone the project “EasyMail” and start the script install.sh:
```
git clone https://github.com/GyunerZeki/easymail.git /easymail && bash /easymail/install.sh
```

During the installation you will be asked a few questions. Below you will find example answers which are applicable only for the current example.

    Type hostname: mail.example.com
    Type admin's email password: iu34urc389fu349
    Do you want to install your own ssl certificates? [n/Y] 
    
If you press “Yes”, you will be asked two additional questions addressed to the SSL certificates _(this step requires the ssl directory to be mapped during the creation of the docker container)_:

    [SSL] CA Bundle file path: /etc/ssl/certs/CERTIFICATE-NAME.crt
    [SSL] Private key file path: /etc/ssl/certs/CERTIFICATE-NAME.key
    
After the configuration of the SSL certificates:

    Is this installation is on Docker? [N/y] y

At the end of the installation, the installation script will generate a random password for the MySQL database which will be displayed on the screen in additional to a few further steps important for the completion of the installation process _(we will review them below anyway)_. Please, write down the MySQL password. If you have missed to write it down, don’t worry, follow the additional steps below in order to restart it:
- Stop MySQL:
```
sudo /etc/init.d/mysql stop
```
- Next we need to start MySQL in safe mode - that is to say, we will start MySQL but skip the user privileges table.
```
sudo mysqld_safe --skip-grant-tables &
```
- Log in to MySQL:
```
mysql -uroot
```
- Next, instruct MySQL which database to use:
```
use mysql;
```
- Enter the new password for the root user as follows:
```
update user set password=PASSWORD("mynewpassword") where User='root';
```
- and finally, flush the privileges:
```
flush privileges;
```
- Quit and restart MySQL:
```
quit

sudo /etc/init.d/mysql stop
sudo /etc/init.d/mysql start
```

When you finish the installation "EasyMail" will automatically start all services _(MySQL, Nginx, php5-fpm, Postfix, Dovecot and Spamassassin)_.

## Configuration
The next important step is to add MX, CNAME and SPF records and to install and configure DKIM for the domain name used for the emails accounts. The SPF record and DKIM are optional but advisable.

### MX record
Steps:
- Go to the domain register of your domain names.
- Add a new MX record for the domain you want to use for you emails. Example:
```
Hostname: example.com
Priority: 0
```

### CNAME records
The configuration of the CNAME is required if we want to configure our email address with a Desktop mail client. Steps:
- Go to the domain register of your domain names.
- Add the following two CNAME records for the domain name of the maill server. Example:
```
Name: autoconfig 
Hostname: mail.example.com.
```

and
```
Name: autodiscover
Hostname: mail.example.com.
```

With the help of these CNAMES, the mail server is able to generate the following XMLs:
<a href="http://autoconfig.mail.example.com:80/mail/config-v1.1.xml" target="_blank">http://autoconfig.mail.example.com:80/mail/config-v1.1.xml<a/>
<a href="http://autodiscover.mail.example.com:80/autodiscover/autodiscover.xml" target="_blank">http://autodiscover.mail.example.com:80/autodiscover/autodiscover.xml<a/>

They are used by the desktop mail clients for automatic configuration with your mail server. You can also use the information within the XML for other manual setups. 

Please take into account that we can access the XML documents through port 80 but this port may vary depending on the configurations of your web service.

### SPF record
It is up to you, how you will set up the SPF record but for the sake of clarity we will present a short example. 

If you want to know more about how to add SPF records and the different configuration options just google for "add SPF record" or read this tutorial <a href="https://www.digitalocean.com/community/tutorials/how-to-use-an-spf-record-to-prevent-spoofing-improve-e-mail-reliability" target="_blank">SPF Record</a>.

Example: 
- Go to the domain register of your domain names.
- Add the following TXT record to the domain name used for the email accounts _(in our case this is example.com)_:
```
Name:  @
Text: "v=spf1 a:mail.example.com ~all"
```

Everyone who receives an email from an email account with domain name example.com _(for example: contact@example.com)_ can check the SPF record of this domain and to see that it authorizes only the server with IP address recorded in the DNS A record of the mail server mail.example.com, to send emails. If somebody else try to send emails on behalf of example.com from a different server, this server most probably will go to the spam filters and permanently blocked.

### DKIM configuration
For the configuration of DKIM follow this tutorial <a href="https://www.digitalocean.com/community/tutorials/how-to-install-and-configure-dkim-with-postfix-on-debian-wheezy" target="_blank">DKIM Configuration</a>.

## RoundCube
“EasyMail” comes with a nice mail client “RoundCube”. In order to access it go to your web browser and type the following:
```
mail.example.com:44380
```

or
```
IP_ADDRESS_OF_THE_MAIL_SERVER:44380
```
    
Of course, you will need an email account to log in. Continue reading for further information how to add email accounts.

When you access your email account with RoundCube, you can change your password from “Settings” -> “Password”.

## Add email accounts
All email accounts are stored in the MySQL database. The reason to store them in the database is for easy management. To add a new email account you will have to access the MySQL database _(remember, you will need the MySQL password)_. We will do that through the terminal.

- Log in to your physical machine and access the terminal of the Ubuntu container if you use Docker. 
- Log in to MySQL:
```
mysql -u root -p
```
- List the  databases:
```
mysql> show databases;
```
The database used by “EasyMail” is “mailserver”.
- List all tables inside database “mailserver”.
```
mysql> show tables in mailserver;
```
You will find four tables: 

    recipient_bcc
    virtual_aliases
    virtual_domains
    virtual_users

The name of the tables are chosen in accordance with Postfix standards for email management. Better understanding of Postfix email management will give you more clear idea of how to work with these tables. The table “virtual_users” contains all email accounts. We can list them:
```
mysql> select * from mailserver.virtual_users;
```

or we can add a new record. Please bear in mind that the password field is encrypted with openssl_encrypt enctyption.

## Additional
### Autostart the service after reboot
"EasyMail" is configured to start all required services automatically if the machine reboots. This will save you some time because you don't have to start the services by yourself. We will review how this works.

- Go to:
```
cd /
```
- List all files in the directory:
```
ln -ls
```
- You will see the file "run.sh". Open it:
```
nano run.sh
```
The file contains the following code:
```
service mysql start
service nginx start
service php5-fpm start
/etc/init.d/postfix start
/usr/sbin/dovecot
service spamassassin start
```
These are the services which will be starter automatically if the machine reboots. That's all you need to know, "EasyMail" takes care for the rest.

### Forward emails
If you want to forward all incomming emails to another email:
- Go to the terminal.
- Access mysql database.
- Add a new record to table “recipient_bcc”.

If you want to forward emails to Gmail, another option is to use Gmail SMTP client.

### Transactional emails
The good thing about the current mail server is that it can be used to send transactional emails. For the configuration with an external client we can use:

    Host: mail.example.com
    Username: contact@example.com
    SMTP Secure: tls
    Port: 587
    
Example for Laravel:

    MAIL_DRIVER=smtp
    MAIL_HOST=mail.example.com
    MAIL_PORT=587
    MAIL_USERNAME=contact@example.com
    MAIL_PASSWORD=
    MAIL_ENCRYPTION=tls

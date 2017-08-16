<p align="center"><a href="http://www.runeasymail.com/" target="_blank"><img src="https://raw.githubusercontent.com/runeasymail/easymail/master/resources/easymail-logo.png"></a></p>

<p align="center">
<a href="https://travis-ci.org/runeasymail/easymail"><img src="https://travis-ci.org/laravel/framework.svg" alt="Build Status"></a>
<a href="https://github.com/runeasymail/easymail/releases/tag/v0.6"><img src="https://img.shields.io/badge/stable-v0.6-blue.svg" alt="Last stable version"></a>
<a href="https://github.com/runeasymail/easymail/blob/master/LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="License"></a>
</p>

# Easy way to install
```
docker run -itd -p=110:110 -p=25:25 -p=995:995 -p=80:80 -p=443:443 -p=587:587 -p=993:993 -p=143:143 -p=465:465 -h "YOUR_DOMAIN_NAME" --name="" easymail/easymail:v1.0.3 /bin/sh -c "bash /opt/easymail/post_install.sh YOUR_DOMAIN_NAME; exec /bin/bash"
```

## About EasyMail
EasyMail is an open-sourced software which will help you to build your own mail server.

It is accessible and powerful tool which can be used for your personal projects and as a mail server in your company (SMTP server solution).

## Learn EasyMail
More detail information can be found on the website [www.runeasymail.com](http://www.runeasymail.com/).

For the installation instructions, please read [the documentation of EasyMail](http://www.runeasymail.com/master/installation).

## Contributing
Thank you for considering contributing to EasyMail! The contribution guide can be found in the [EasyMail documentation](http://www.runeasymail.com/master/contribution-guide).

Every individual, company or organization who uses and likes EasyMail can support it by providing their names, logos and other initials in order to be used on the website, the Github repository and advertisement materials whose purpose is to popularize EasyMail.

## License
EasyMail is open-sourced software licensed under the [MIT license](https://github.com/runeasymail/easymail/blob/master/LICENSE).

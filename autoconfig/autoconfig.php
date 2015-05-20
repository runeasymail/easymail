<?php

header ("Content-Type:text/xml");

$domain = $_SERVER["HTTP_HOST"];
$mail = $_GET['emailaddress'];
$host = '__EASYMAIL_HOSTNAME__';

echo <<<EOP
<?xml version="1.0"?> 
<clientConfig version="1.1">
    <emailProvider id="{$domain}">
        <domain>{$domain}</domain>
        <displayName>{$mail}</displayName>
        <displayShortName>{$mail}</displayShortName>
        <incomingServer type="imap">
            <hostname>{$host}</hostname>
            <port>143</port>
            <socketType>STARTTLS</socketType>
            <username>{$mail}</username>
            <authentication>password-cleartext</authentication>
        </incomingServer>
        <outgoingServer type="smtp">
            <hostname>{$host}</hostname>
            <port>587</port>
            <socketType>STARTTLS</socketType>
            <authentication>password-cleartext</authentication>
            <username>{$mail}</username>
        </outgoingServer>
    </emailProvider>
</clientConfig>
EOP;



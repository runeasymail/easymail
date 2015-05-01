<?php
//get raw POST data so we can extract the email address
$data = file_get_contents("php://input");
preg_match("/\<EMailAddress\>(.*?)\<\/EMailAddress\>/", $data, $matches);
//set Content-Type
header("Content-Type: application/xml");
$host = 'cursedly-host.gzeki.com';

echo '<?xml version="1.0" encoding="utf-8" ?>'; ?>

<Autodiscover xmlns="http://schemas.microsoft.com/exchange/autodiscover/responseschema/2006">
    <Response xmlns="http://schemas.microsoft.com/exchange/autodiscover/outlook/responseschema/2006a">
        <Account>
            <AccountType>email</AccountType>
            <Action>settings</Action>
            <Protocol>
                <Type>IMAP</Type>
                <Server><? echo $host; ?></Server>
                <Port>993</Port>
                <DomainRequired>off</DomainRequired>
                <LoginName><?php echo $matches[1]; ?></LoginName>
                <SPA>off</SPA>
                <SSL>on</SSL>
                <AuthRequired>on</AuthRequired>
            </Protocol>
            <Protocol>
                <Type>POP3</Type>
                <Server><? echo $host; ?></Server>
                <Port>995</Port>
                <DomainRequired>off</DomainRequired>
                <LoginName><?php echo $matches[1]; ?></LoginName>
                <SPA>off</SPA>
                <SSL>on</SSL>
                <AuthRequired>on</AuthRequired>
            </Protocol> 
            <Protocol>
                <Type>SMTP</Type>
                <Server><? echo $host; ?></Server>
                <Port>587</Port>
                <DomainRequired>off</DomainRequired>
                <LoginName><?php echo $matches[1]; ?></LoginName>
                <SPA>off</SPA>
                <AuthRequired>on</AuthRequired>
                <UsePOPAuth>off</UsePOPAuth>
                <SMTPLast>off</SMTPLast>
				<Encryption>TLS</Encryption>
				<TLS>on</TLS>
            </Protocol>
        </Account>
    </Response>
</Autodiscover>
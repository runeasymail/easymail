<?php

require 'PHPMailer/PHPMailerAutoload.php';
require 'config.php';

// Define variables
$subject = "Test";
$from = "EasyMail";
$body = "Test.";

/*=============================== POP3 ===============================*/
        // STARTTLS on port 110
$imap_stream = imap_open("{".$hostname.":993/imap/ssl/novalidate-cert}INBOX", $email, $password) or die2("Can't connect over IMAP, SSL on port 993: ".imap_last_error());
$inbox = (array) imap_check($imap_stream);
$messages_in_inbox = $inbox['Nmsgs'];

$pop = new POP3;
$pop->authorise($hostname, 110, 30, $email, $password);
$mail = new PHPMailer; 
$mail->SMTPDebug = 0; 
$mail->SMTPSecure = 'tls';
$mail->SMTPOptions = array(
    'ssl' => array(
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true
    )
); 
$mail->Host = $hostname;
$mail->From = $email;
$mail->setFrom($email, $from);
$mail->addAddress($email, $from);
$mail->Subject = $subject;
$mail->isHTML(false);
$mail->Body = $body;

if (!$mail->send()) {
    die2("Can't send email over POP3, STARTTLS on port 110: ".$mail->ErrorInfo);
}

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die2("Message not received over POP3, STARTTLS on port 110: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];

        // SSL on port 995
$pop = new POP3;
$pop->authorise($hostname, 995, 30, $email, $password);
$mail = new PHPMailer; 
$mail->SMTPDebug = 0;  
$mail->SMTPSecure = 'ssl';
$mail->SMTPOptions = array(
    'ssl' => array(
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true
    )
); 
$mail->Host = $hostname;
$mail->From = $email;
$mail->setFrom($email, $from);
$mail->addAddress($email, $from);
$mail->Subject = $subject;
$mail->isHTML(false);
$mail->Body = $body;

if (!$mail->send()) {
    die2("Can't send email over POP3, SSL on port 995: ".$mail->ErrorInfo);
}

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die2("Message not received over POP3, SSL on port 995: ".imap_last_error());
}

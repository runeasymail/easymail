<?php

require 'PHPMailer/PHPMailerAutoload.php';
require 'config.php';

// Define variables
$subject = "Test";
$from = "EasyMail";
$body = "Test.";

/*=============================== SMTP ===============================*/
        // STARTTLS on port 587
$imap_stream = imap_open("{".$hostname.":993/imap/ssl/novalidate-cert}INBOX", $email, $password) or die2("Can't connect over IMAP, SSL on port 993: ".imap_last_error());
$inbox = (array) imap_check($imap_stream);
$messages_in_inbox = $inbox['Nmsgs'];

$mail = new PHPMailer;
$mail->Host = $hostname;
$mail->Port = 587;
$mail->isSMTP();
$mail->SMTPDebug = 0;
$mail->SMTPSecure = 'tls';
$mail->SMTPOptions = array(
        'ssl' => array(
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true
    )
); 
$mail->SMTPAuth = true;
$mail->Username = $email;
$mail->Password = $password;
$mail->setFrom($email, $from);
$mail->addAddress($email, $from);
$mail->Subject = $subject;
$mail->isHTML(false);
$mail->Body = $body;

if (!$mail->send()) {
    die2("Can't send email over SMTP, STARTTLS on port 587: ".$mail->ErrorInfo);
}

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die2("Message not received over SMTP, STARTTLS on port 587: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];

        // SSL on port 465
$imap_stream = imap_open("{".$hostname.":993/imap/ssl/novalidate-cert}INBOX", $email, $password) or die2("Can't connect over IMAP, SSL on port 993: ".imap_last_error());
$mail = new PHPMailer;
$mail->Host = $hostname;
$mail->Port = 465;
$mail->isSMTP();
$mail->SMTPDebug = 0;
$mail->SMTPSecure = 'ssl';
$mail->SMTPOptions = array(
        'ssl' => array(
        'verify_peer' => false,
        'verify_peer_name' => false,
        'allow_self_signed' => true
    )
); 
$mail->SMTPAuth = true;
$mail->Username = $email;
$mail->Password = $password;
$mail->setFrom($email, $from);
$mail->addAddress($email, $from);
$mail->Subject = $subject;
$mail->isHTML(false);
$mail->Body = $body;

if (!$mail->send()) {
    die2("Can't send email over SMTP, SSL on port 465: ".$mail->ErrorInfo);
}

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die2("Message not received over SMTP, SSL on port 465: ".imap_last_error());
}

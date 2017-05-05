<?php

require 'PHPMailer/PHPMailerAutoload.php';

// Define variables
$domain = "__HOSTNAME__"
$email = "admin@".$domain;
$password = "__ROUNDCUBE_WEB_PASSWORD__";
$subject = "Test";
$from = "EasyMail";
$body = "Test.";

/*=============================== IMAP ===============================*/
        // STARTTLS on port 143
$imap_stream = imap_open("{".$domain.":143/imap/tls/novalidate-cert}INBOX", $email, $password) or die("Can't connect over IMAP, STARTTLS on port 143: ".imap_last_error());
$inbox = (array) imap_check($imap_stream);
$messages_in_inbox = $inbox['Nmsgs'];
imap_mail($email, $subject, $body) or die("Can't send email over IMAP, STARTTLS on port 143: ".imap_last_error());
sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over IMAP, STARTTLS on port 143: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];
imap_close($imap_stream);

        // SSL on port 993
$imap_stream = imap_open("{".$domain.":993/imap/ssl/novalidate-cert}INBOX", $email, $password) or die("Can't connect over IMAP, SSL on port 993: ".imap_last_error());
imap_mail($email, $subject, $body) or die("Can't send email over IMAP, SSL on port 993: ".imap_last_error());
sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over IMAP, SSL on port 993: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];

/*=============================== POP3 ===============================*/
        // STARTTLS on port 110
$pop = new POP3;
$pop->authorise($domain, 110, 30, $email, $password);
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
$mail->Host = $domain;
$mail->From = $email;
$mail->setFrom($email, $from);
$mail->addAddress($email, $from);
$mail->Subject = $subject;
$mail->isHTML(false);
$mail->Body = $body;

if (!$mail->send()) {
    die("Can't send email over POP3, STARTTLS on port 110: ".$mail->ErrorInfo);
}

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over POP3, STARTTLS on port 110: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];

        // SSL on port 995
$pop = new POP3;
$pop->authorise($domain, 995, 30, $email, $password);
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
$mail->Host = $domain;
$mail->From = $email;
$mail->setFrom($email, $from);
$mail->addAddress($email, $from);
$mail->Subject = $subject;
$mail->isHTML(false);
$mail->Body = $body;

if (!$mail->send()) {
    die("Can't send email over POP3, SSL on port 995: ".$mail->ErrorInfo);
}

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over POP3, SSL on port 995: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];

/*=============================== SMTP ===============================*/
        // STARTTLS on port 587
$mail = new PHPMailer;
$mail->Host = $domain;
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
    die("Can't send email over SMTP, STARTTLS on port 587: ".$mail->ErrorInfo);
}

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over SMTP, STARTTLS on port 587: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];

        // SSL on port 465
$mail = new PHPMailer;
$mail->Host = $domain;
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
    die("Can't send email over SMTP, SSL on port 465: ".$mail->ErrorInfo);
}

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over SMTP, SSL on port 465: ".imap_last_error());
}

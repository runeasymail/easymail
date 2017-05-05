<?php

require 'PHPMailer/PHPMailerAutoload.php';

// Define variables
$domain = "__HOSTNAME__"
$email = "admin@".$domain;
$password = "__ROUNDCUBE_WEB_PASSWORD__";
$subject = "Test";
$from = "EasyMail";
$message = "Test.";

/*=============================== IMAP ===============================*/
        // STARTTLS on port 143
$imap_stream = imap_open("{".$domain.":143/imap/tls/novalidate-cert}INBOX", $email, $password) or die("Can't connect over IMAP, STARTTLS on port 143: ".imap_last_error());
$inbox = (array) imap_check($imap_stream);
$messages_in_inbox = $inbox['Nmsgs'];
imap_mail($email, $subject, $message) or die("Can't send email over IMAP, STARTTLS on port 143: ".imap_last_error());
sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over IMAP, STARTTLS on port 143: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];
imap_close($imap_stream);

        // SSL on port 993
$imap_stream = imap_open("{".$domain.":993/imap/ssl/novalidate-cert}INBOX", $email, $password) or die("Can't connect over IMAP, SSL on port 993: ".imap_last_error());
imap_mail($email, $subject, $message) or die("Can't send email over IMAP, SSL on port 993: ".imap_last_error());
sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over IMAP, SSL on port 993: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];

/*=============================== POP3 ===============================*/
        // STARTTLS on port 110

        // SSL on port 995

/*=============================== SMTP ===============================*/
        // STARTTLS on port 587
$mail = new PHPMailer;
$mail->isSMTP();
$mail->SMTPDebug = 2;
$mail->Debugoutput = 'html';
$mail->Host = $domain;
$mail->Port = 587;
$mail->SMTPSecure = 'tls';
$mail->SMTPAuth = true;
$mail->Username = $email;
$mail->Password = $password;
$mail->setFrom($email, $from);
$mail->addAddress($email, $from);
$mail->Subject = $subject;
$mail->msgHTML($message);

if (!$mail->send()) {
    die("Can't send email over SMTP, STARTTLS on port 587: ".$mail->ErrorInfo);
}

$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over SMTP, STARTTLS on port 587: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];

        // SSL on port 465
$mail = new PHPMailer;
$mail->isSMTP();
$mail->SMTPDebug = 2;
$mail->Debugoutput = 'html';
$mail->Host = $domain;
$mail->Port = 465;
$mail->SMTPSecure = 'ssl';
$mail->SMTPAuth = true;
$mail->Username = $email;
$mail->Password = $password;
$mail->setFrom($email, $from);
$mail->addAddress($email, $from);
$mail->Subject = $subject;
$mail->msgHTML($message);

if (!$mail->send()) {
    die("Can't send email over SMTP, SSL on port 465: ".$mail->ErrorInfo);
}

$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over SMTP, SSL on port 465: ".imap_last_error());
}

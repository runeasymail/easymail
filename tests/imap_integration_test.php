<?php

require 'PHPMailer/PHPMailerAutoload.php';
require 'config.php';

// Define variables
$subject = "Test";
$from = "EasyMail";
$body = "Test.";

/*=============================== IMAP ===============================*/
        // STARTTLS on port 143
$imap_stream = imap_open("{".$hostname.":143/imap/tls/novalidate-cert}INBOX", $email, $password) or die2("Can't connect over IMAP, STARTTLS on port 143: ".imap_last_error());
$inbox = (array) imap_check($imap_stream);
$messages_in_inbox = $inbox['Nmsgs'];
imap_mail($email, $subject, $body) or die2("Can't send email over IMAP, STARTTLS on port 143: ".imap_last_error());

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die2("Message not received over IMAP, STARTTLS on port 143: ".imap_last_error());
}

$messages_in_inbox = $inbox['Nmsgs'];
imap_close($imap_stream);

        // SSL on port 993
$imap_stream = imap_open("{".$hostname.":993/imap/ssl/novalidate-cert}INBOX", $email, $password) or die2("Can't connect over IMAP, SSL on port 993: ".imap_last_error());
imap_mail($email, $subject, $body) or die2("Can't send email over IMAP, SSL on port 993: ".imap_last_error());

sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die2("Message not received over IMAP, SSL on port 993: ".imap_last_error());
}

imap_close($imap_stream);

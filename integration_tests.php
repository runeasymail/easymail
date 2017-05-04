<?php

include 'PHPMailer/class.pop3.php';
include 'PHPMailer/class.smtp.php';

// Define variables
$domain = "test.example.com"
$email = "admin@test.example.com";
$password = "__ROUNDCUBE_MYSQL_PASSWORD__";
$subject = "Test";
$message = "Test.";

/*=============================== IMAP ===============================*/
        // STARTTLS on port 143
$imap_stream = imap_open("{".$domain.":143/imap/tls/novalidate-cert}INBOX", $email, $password) or die("Can't connect over STARTTLS on port 143: ".imap_last_error());
$inbox = (array) imap_check($imap_stream);
$messages_in_inbox = $inbox['Nmsgs'];
imap_mail($email, $subject, $message) or die("Can't send email over STARTTLS on port 143: ".imap_last_error());
sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over STARTTLS on port 143: ".imap_last_error());
}

imap_close($imap_stream);

        // SSL on port 993
$imap_stream = imap_open("{".$domain.":993/imap/ssl/novalidate-cert}INBOX", $email, $password) or die("Can't connect over SSL on port 993: ".imap_last_error());
$inbox = (array) imap_check($imap_stream);
$messages_in_inbox = $inbox['Nmsgs'];
imap_mail($email, $subject, $message) or die("Can't send email over SSL on port 993: ".imap_last_error());
sleep(1);
$inbox = (array) imap_check($imap_stream);

if ($messages_in_inbox == $inbox['Nmsgs']) {
        die("Message not received over SSL on port 993: ".imap_last_error());
}

imap_close($imap_stream);

/*=============================== POP3 ===============================*/
        // STARTTLS on port 110

        // SSL on port 995

/*=============================== SMTP ===============================*/
        // STARTTLS on port 587

        // SSL on port 465

<?php

// Define variables
$hostname = "test.example.com";
$email = "admin@".$hostname;

$config = file_get_contents('/opt/easymail/config.ini');

$matches = [];
preg_match('/roundcube_web_password:(.*)/', $config, $matches);
$password = $matches[1];


// Define functions
function die2($input) {
  echo $input; 
  exit(1);
}

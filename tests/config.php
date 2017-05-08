<?php

// Define variables
$hostname = "test.example.com";
$email = "admin@".$hostname;
$password = "__ROUNDCUBE_WEB_PASSWORD__";

// Define functions
function die2($input) {
  echo $input; 
  exit(1);
}

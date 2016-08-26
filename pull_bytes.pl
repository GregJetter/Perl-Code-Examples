#!/usr/bin/perl 
#
# pull_bytes.pl
#
#
# This script connects via a telnet session to a 4948 switch at
#  172.25.92.1 . Then it  issues the show command "show int gi 1/17"
# gatheres the returned output and parses it for two sets of numbers
# bytes in and bytes out.
# 
# it then  records the numbers plus there total for  that interation.
# this is run as a cron job and executes every 5 min 24/7 .
# 
# it is part of the swreports web application.
# by Greg Jetter  July ,2014.

use strict;
use DBI;
use Net::Telnet::Cisco;


# find the current time and make it  mysql friendly
my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) =
localtime(time);

$mon = $mon + 1;
$year = $year + 1900 ;

if($year < 10) { $year = "0".$year ; }
if($mon < 10) { $mon = "0" .$mon ;}
if($mday < 10) { $mday = "0" . $mday ; }
if($hour < 10) { $hour = "0" . $hour ; }
if($min < 10) { $min = "0" . $min ; }
if($sec < 10) { $sec = "0" . $sec ; }

my $DT = $year . "-" . $mon . "-" . $mday . " ". $hour . ":" .$min .":" . $sec ;


# db connection info
my $db = "swreports";
my $dbhost = "localhost" ;
my $user = "swreports" ;
my $password_db = "xxxxxxx";


# make db connection
my $dbh = DBI->connect("DBI:mysql:database=$db:host=$dbhost",$user,$password_db) or die "Can't connect to database: $DBI::errstr\n";


# telnet connection
# vars
my $host = '172.25.92.1';
my $login = 'gjetter';
my $password = 'xxxxxxx';
my $command = 'show int gi 1/17';
# login
my $session = Net::Telnet::Cisco->new(Host => $host);
   $session->login($login,$password);
   
   
# now issue commands and capture  returned values

# send comman
my @output = $session->cmd($command);

my ($bytes_in,$bytes_out);
 
# process the returned string and extract  data
for(@output) { 
 chomp;
if($_=~/input,\s(\d+)\sbytes/ ) { $bytes_in = $1;}
if($_=~/output,\s(\d+)\sbytes/) { $bytes_out = $1;}

}


my $bytes_total = $bytes_in + $bytes_out ;

# insert data into DB
my $query = "INSERT INTO TelNet_172_25_90_1_1_17 (
time,
bytes_in,
bytes_out,
bytes_total
)VALUES(?,?,?,?)";

my $dbResult = $dbh->prepare($query);
my $rows = $dbResult->execute($DT,$bytes_in,$bytes_out,$bytes_total);   
if($rows < 1) { print "DB insert failed : $DBI::errstr" ; }

# clean up
$session->close();

exit 0 ;



#!/usr/bin/perl -w
#
#
# pull_bytes_snmp
#
# All the  oid's are  for the  fast gigbyte 1/17 interface.
# 
#
use strict;
use warnings;
use Net::SNMP;
use DBI;


# db connection info
my $db = "swreports";
my $dbhost = "localhost" ;
my $user = "swreports" ;
my $password = "xxxxxxxx";

# make db connection
my $dbh = DBI->connect("DBI:mysql:database=$db:host=$dbhost",$user,$password) or die "Can't connect to database: $DBI::errstr\n";

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

# oid's we want to fetch
my $OID_InOctets    = '1.3.6.1.2.1.2.2.1.10.18';
my $OID_InDiscards  = '1.3.6.1.2.1.2.2.1.13.18';
my $OID_OutOctets   = '1.3.6.1.2.1.2.2.1.16.18';
my $OID_OutDiscards = '1.3.6.1.2.1.2.2.1.19.18';

# vars
my $hostname  = '172.25.92.1';
my $community = 'xxxxxxxxx';
my $version   = 'snmpv2c';
my $seconds   = '30';
my $count     = '5';

# create the snmp object
my ($session, $error) = Net::SNMP->session(
     -hostname  => $hostname,
     -community => $community,
     -version   => $version,
     -timeout   => $seconds,
     -retries   => $count,
     );
     

# make sure the object is there
if(!defined($session)) {
     printf("ERROR: %s.\n", $error);
     exit 1;}
     
# ok we have a session send it and process result
my $result0 = $session->get_request(-varbindlist => [$OID_InOctets],);
my $result1 = $session->get_request(-varbindlist => [$OID_InDiscards],);
my $result2 = $session->get_request(-varbindlist => [$OID_OutOctets],);
my $result3 = $session->get_request(-varbindlist => [$OID_OutDiscards],);

# handle non sucess
if(!defined $result0) 

{
     printf "ERROR: %s.\n", $session->error();
     $session->close();
     exit 1;
}


# we have results to record.
my $in_bytes     = $result0->{$OID_InOctets};
my $in_discards  = $result1->{$OID_InDiscards};
my $out_bytes    = $result2->{$OID_OutOctets};
my $out_discards = $result3->{$OID_OutDiscards};
my $total_bytes  = $in_bytes + $out_bytes ;


#print "in bytes = $in_bytes\n";
#print "out bytes = $out_bytes\n";
#print "Total bytes = $total_bytes\n";


# mysql query
my $query = "INSERT INTO sw172_25_90_1_gi1_17 ( 
time,
bytes_in,
bytes_out,
total_bytes,
bytes_in_discard,
bytes_out_discard
)VALUES('$DT',$in_bytes,$out_bytes,$total_bytes,$in_discards,$out_discards)";


#print $query ;
#exit;


my $dbResult = $dbh->prepare($query);
my $rows = $dbResult->execute();   
if($rows < 1) { print "DB insert failed : $DBI::errstr" ; }

# clean up
$session->close();

exit 0 ;




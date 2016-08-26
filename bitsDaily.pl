#!/usr/bin/perl -w
#
# bitsDaily.pl
#
# This script queries the TelNet_bytes_by_hour table and 
# computes max/min/avg and total for the day of both RX and TX bits.
# the records are in bytes so each has to be converted to bits.
# each record is in bytes per hour , that must be converted to 
# bits per second for the day. Then the max /min and average found 
# and stored in the Telnet_bits_by_day table for further processing.
#
# this script is  to be run from a cron job nightly after the bytesByHour.pl script.


use strict;
use DBI;
use DateTime;
use List::Util qw( min max sum );

# db connection info
my $db = "swreports";
my $dbhost = "localhost" ;
my $user = "swreports" ;
my $password_db = "xxxxxxxx";

# make db connection
my $dbh = DBI->connect("DBI:mysql:database=$db:host=$dbhost",$user,$password_db) or die "Can't connect to database: $DBI::errstr\n";


# find the date
my($day,$month,$year) = (localtime)[3,4,5];

# fix date for db
$month = $month + 1;
$year = $year + 1900 ;

my $dt = DateTime->new(year => $year,
                       month => $month,
                       day   => $day);
                       
my $date = $dt->subtract( days => 1);  
$date=~/(\d+-\d+-\d+)/;

# change date here 
my $SearchDate = $1;


#vars
my($hour,$bytes_in,$bytes_out) ;
my(@in,@out,@inOutTotal);


# get hour data from db
my $query = "SELECT hour,bytes_in,bytes_out
             FROM TelNet_bytes_by_hour
             WHERE date = ? ";
             
my $result = $dbh->prepare($query);
   $result->execute($SearchDate);
   $result->bind_columns(undef,\($hour,$bytes_in,$bytes_out));

while($result->fetch) {
          
     
   my $inBits = $bytes_in * 8 ;
   my $outBits = $bytes_out * 8 ;

     #record in and out and total
     push @in , $inBits ;
     push @out , $outBits ;
     my $total =  $inBits + $outBits ;
     push @inOutTotal , $total ;
                       
}

# now arrays are loaded we can calculate 

my($total_bits_in,$total_bits_out,$in_out_total);

# do totals
for(@in){ $total_bits_in += $_ ;}
for(@out){$total_bits_out += $_ ;}
for(@inOutTotal) { $in_out_total += $_; }

# do RX
my $in_min = min @in;
my $in_max = max @in;
my $in_avg = sum(@in)/@in;

# do TX
my $out_min = min @out;
my $out_max = max @out ;
my $out_avg = sum(@out)/@out;

# do daily
my $inOutmin = min @inOutTotal;
my $inOutmax = max @inOutTotal;
my $inOutavg = sum(@inOutTotal)/@inOutTotal;

# calculate Mega bit per second
my $mbps = ($in_out_total / 86400) / 1000000 ;

# store all calculated values
my $queryInsert = "INSERT INTO TelNet_bits_by_day(
date,
total_bits_in,
max_bits_in,
min_bits_in,
avg_bits_in,
total_bits_out,
max_bits_out,
min_bits_out,
avg_bits_out,
inout_total,
inout_max,
inout_min,
inout_avg,
MegabitsPerSecond
)VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?)";

my $resultInsert = $dbh->prepare($queryInsert);
my $rows = $resultInsert->execute($SearchDate,$total_bits_in,$in_max,$in_min,$in_avg,
                          $total_bits_out,$out_max,$out_min,$out_avg,
                          $in_out_total,$inOutmax,$inOutmin,$inOutavg,$mbps);


 if($rows < 1) { print "DB insert failed : $DBI::errstr" ; }


# clean up
$dbh->disconnect;



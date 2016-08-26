#!/usr/bin/perl -w
#
# PingTimes.pl
#
# this script check latency of ping to a  address
# it records it into a text file for further work.
#
#

use strict;
use Net::Ping;
use Time::HiRes qw(tv_interval gettimeofday);
use DateTime ;


my($host) = shift() || die("Usage: $0 <IP address>\n");

my $file = "FentoTest.txt";

open(FILE , ">",$file);

my $ofh = select FILE ;
$| = 1;
select $ofh ;

my($ping) = Net::Ping->new("icmp");

my $time = 604800;

#my $time = 10 ;

while ($time) {
    my($timeStart) = [gettimeofday()];
    my $dt = DateTime->now(time_zone => 'America/Anchorage');
    
    if ($ping->ping($host, 2)) {
        my($timeElapsed) = tv_interval($timeStart, [gettimeofday()]);
        
        my $t = $timeElapsed * 1000 ;
        
        my $string = "$dt\t$t ms\n";
        
        print FILE $string ;
                         
     #   printf  "%s:\t %.3f msec\n",$dt, $timeElapsed * 1000;
        
    } else {
        my($timeElapsed) = tv_interval($timeStart, [gettimeofday()]);
        printf("%s failed: %.3f\n", $host, $timeElapsed * 1000);
    }
    sleep(1);
  $time -- ;
}
close(FILE);
$ping->close();

exit();

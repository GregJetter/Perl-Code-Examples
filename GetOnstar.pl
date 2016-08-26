#!/usr/bin/perl -w
#
# GetOnstar.pl
#
# This script  goes through a  file of  phone numbers and
# creates a query against the  LDAP server. It executes the query and records 
# the returned values , creating a new file  of the values. for later use.
#
#
use strict;
use Net::LDAP;
use Net::LDAP::LDIF;


#VARs
my $phoneFile = "Onstar_sub_numbers.txt";

open(INFILE,"<",$phoneFile) or die "can not open $phoneFile : $!\n";

my $ldap = Net::LDAP->new('172.21.255.35') or die "$@";
my $mesg = $ldap->bind ;



while(<INFILE>){
chop;chop;

print " Searching for $_ \n";

my $filter = $_;

$mesg = $ldap->search(
                        base => "dc=acsalaska,dc=net",
                        filter => "(uid=$filter)"
                          );
                          
# record exest
if($mesg->count() > 0) { 
 print "Found $filter\n";
                                                       
my @entries = $mesg->entries;

 my $ldif = Net::LDAP::LDIF->new("./Onstar.ldif","a") or die $!;
    $ldif->write_entry($mesg->all_entries());
                                                
 }else{                        
        $mesg->code && warn $mesg->error ;
   
       }
      
  }   
  
   $mesg = $ldap->unbind;
  
  print "Finished run\n";                     
#!/usr/bin/perl -w
#
# addAttribute.pl
#
#
# this script adds the attribute  named "acscdmavpnname" to GCI_ACDMA
# to a list of phonenumbers in the dest_contex_nums file , it generates
# an ldif file to be run agaisted the ldap  db.

use strict;

my $numFile = "dest_contex_nums";
my $addLdifFile = "AddVpnName.ldif";


open(INFILE,"<",$numFile) or die "can not open $numFile :$!\n";
open(OUTFILE ,">",$addLdifFile) or die "can not open $addLdifFile : $!\n";


while(<INFILE>) {
chomp;	
my $string = "dn: uid=$_,ou=People,dc=acsalaska,dc=net\nchangetype: modify\nadd: acscdmadavpnname\nacscdmadavpnname: GCI_ACDMA\n\n";
	
print OUTFILE $string ;	
	
	
}

print "Finisghed run";	
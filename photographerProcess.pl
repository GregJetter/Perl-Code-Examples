#!/usr/bin/perl -w
#
# photographerProcess.pl
#
# This script is called various ways , from a web pages
# it receives data and creates a record  , modifies or deletes the
# Photographer Record in the  Data base.
# it is part of the  akstocphoto.com web application.

use strict;
use CGI;
use DBI;
use Email::Valid;


# set up db stuff
# connect to the db
my $db = "AKSTOCKPHOTOS";
my $host = "localhost";
my $user = "stock_user";
my $password = "xxxxxxx";
my $dbh = DBI->connect("DBI:mysql:database=$db:$host=$host",$user,$password) or die "cannot connect to DB: $DBI::errstr\n";

# make cgi object
my $q = new CGI;


# find out how were are called
my $type = $q->param("TYPE");


if($type eq "ADD")    { &addRecord ; }
if($type eq "CHANGE") { &changeRecord ; }
if($type eq "DELETE") { &deleteRecord ; }
if($type eq "EDIT")   { &editRecord ; }

exit ;


################################# addRecord ###########################
sub addRecord {
	
	my $Fname = $q->param("FN") ;
	my $Lname = $q->param("LN") ;
	my $Aline1 = $q->param("ALINE1");
	my $Aline2 = $q->param("ALINE2");
	my $city = $q->param("CITY");
	my $state = $q->param("STATE");
	my $zip = $q->param("ZIP");
	my $company = $q->param("COMPANY");
	my $email = $q->param("EMAIL");
	my $areaCode = $q->param("AC");
	my $phone = $q->param("PN");
	
# check for valid data 
if($zip) {
           if($zip!~/^\d{5}$/) { &error(3) ; exit;}
           }
# area code           
if($areaCode){
	       if($areaCode!~/^\d{3}$/) {&error(4); exit;}
	       }
	       
# phone number	       
if($phone) {
	     if($phone!~/^\d{7}$/) { &error(6); exit; }	       
	    } 
	      
# email address	
if($email){
	    if((Email::Valid->address($email) ? 'yes' : 'no')  eq 'no'){ &error(5); exit;}
	    }
	


# check to see if  name is all ready in DB
my $nameQuery = "SELECT First_Name,Last_Name 
                 FROM AKSTOCKPHOTOS.Photographer_INFO
                 WHERE First_Name = ? AND Last_Name = ? ";
   
   my $result = $dbh->prepare($nameQuery);
      $result->execute($Fname,$Lname);
   my $rows = $result->rows ;
   if($rows > 0 ) { &error(6); exit;}

# not in the DB add it
my $active = "YES";
	
my $addQuery = "INSERT INTO AKSTOCKPHOTOS.Photographer_INFO(
                First_Name,
                Last_Name,
                AddressLine1,
                AddressLine2,
                City,
                State,
                Zipcode,
                AreaCode,
                PhoneNumber,
                Email,
                Company,
                active)Values(?,?,?,?,?,?,?,?,?,?,?,?)";
                                
my $addResult = $dbh->prepare($addQuery);                
   $addResult->execute($Fname,$Lname,$Aline1,$Aline2,$city,$state,$zip,$areaCode,$phone,$email,$company,$active);              
                
my $addRows = $addResult->rows ;
if($addRows > 0) {
	       print $q->header();
               print '<script language="JavaScript">;' . "\n";
               print 'alert("Photograper added to data base.");';
               print 'history.go(-1);';
               print '</script>;';
              } 
	
	
	}
	
############################### changeRecord ##########################
sub changeRecord {
   
        use HTML::Template;
	my $template = "../template/editPhotographer.tmpl";
	my $tmpl = new HTML::Template(filename => $template);
		
	my @SELECTION = $q->param("SELECTION") || &error(10) ;
	if($#SELECTION+1 > 1) { &error(7); exit; }
	 
	
	for(@SELECTION) {
	   
	
	my $query = "SELECT First_Name,Last_Name,
	                    AddressLine1,AddressLine2,City,
	                    State,Zipcode,AreaCode,PhoneNumber,Email,Company
	                    FROM AKSTOCKPHOTOS.Photographer_INFO
	                    WHERE ID = ?";	
	my ( $Fname,$Lname,$Al1,$Al2,$city,$st,$zip,$ac,$pn,$email,$company);	
	my $ID = $_ ;
	my $result = $dbh->prepare($query);
	   $result->execute($ID);
	   $result->bind_columns(undef,\($Fname,$Lname,$Al1,$Al2,$city,$st,$zip,$ac,$pn,$email,$company));
		
		
				
		while($result->fetch) {
		   		   
		    $tmpl->param ( FNAME => $Fname , 
		                  LNAME => $Lname ,
		                  AL1   => $Al1,
		                  AL2   => $Al2,
		                  CITY  => $city,
		                  STATE => $st,
		                  ZIP   => $zip,
		                  ACODE => $ac,
		                  PHONE => $pn,
		                  EMAIL => $email,
		                  CO    => $company,
		                  ID    => $ID);
		    		    
                  		   }
		   
	#create template and  push to browser.
	print $q->header();
        print $tmpl->output;	   
		
		}
	
	
	
	} # end changeRecord
############################### editRecord ############################
sub editRecord{
	
	# receive data from page and  update DB
	my $Fname = $q->param("FN") ;
	my $Lname = $q->param("LN") ;
	my $Aline1 = $q->param("ALINE1");
	my $Aline2 = $q->param("ALINE2");
	my $city = $q->param("CITY");
	my $state = $q->param("STATE");
	my $zip = $q->param("ZIP");
	my $company = $q->param("COMPANY");
	my $email = $q->param("EMAIL");
	my $areaCode = $q->param("AC");
	my $phone = $q->param("PN");
	my $ID    = $q->param("ID");
	
# check for valid data 
if($zip) {
           if($zip!~/^\d{5}$/) { &error(3) ; exit;}
           }
# area code           
if($areaCode){
	       if($areaCode!~/^\d{3}$/) {&error(4); exit;}
	       }
	       
# phone number	       
if($phone) {
	     if($phone!~/^\d{7}$/) { &error(6); exit; }	       
	    } 
	      
# email address	
if($email){
	    if((Email::Valid->address($email) ? 'yes' : 'no')  eq 'no'){ &error(5); exit;}
	    }
	
my $editQuery = "UPDATE	AKSTOCKPHOTOS.Photographer_INFO SET First_Name   = ?,
                                                            Last_Name    = ?,
                                                            AddressLine1 = ?,
                                                            AddressLine2 = ?,
                                                            City         = ?,
                                                            State        = ?,
                                                            Zipcode      = ?,
                                                            AreaCode     = ?,
                                                            PhoneNumber  = ?,
                                                            EMail        = ?,
                                                            Company      = ?
                                                            WHERE ID = ? " ;
	
	my $result = $dbh->prepare($editQuery);
	   $result->execute($Fname,$Lname,$Aline1,$Aline2,$city,$state,$zip,$areaCode,$phone,$email,$company,$ID);
	
	
		        
			print $q->header();
                        print '<script language="JavaScript">;' . "\n";
                        print 'alert("Photograper Has been Updated in the data base.");';
                        print 'history.go(-2);';
                        print '</script>;';
               	     		
	
	
	}




############################### deleteRecord ##########################
sub deleteRecord {
	
	my @SELECTION = $q->param("SELECTION") || &error(9);
	
	for(@SELECTION) {
		
	my $query = "UPDATE AKSTOCKPHOTOS.Photographer_INFO SET active = 'NO' WHERE  ID = $_";	
	my $resultDelete = $dbh->prepare($query);
	   $resultDelete->execute();
		
		        
			print $q->header();
                        print '<script language="JavaScript">;' . "\n";
                        print 'alert("Photograper Deleted from data base.");';
                        print 'history.go(-1);';
                        print '</script>;';
               	     		
		}
		
	
	
	}
	
################################## errors #############################
sub error {
	
my $num = shift ;

print $q->header();
print '<script language="JavaScript">;' . "\n";
print 'alert("You submitted a blank form , please try again");' . "\n" if $num == 1 ;
print 'alert("Photographer Name you submitted is all ready in the table");' . "\n" if $num == 2 ;
print 'alert("Zipcode must be a  5 didget number , example: 99645");' . "\n" if $num == 3 ;
print 'alert("Area Code must be a three didget number only!");' . "\n" if $num == 4 ;
print 'alert("the email you entered is not a valid email , check and try again");' . "\n" if $num == 5 ;
print 'alert("The name you entered is  all ready in the data base.");' . "\n" if $num == 6 ;
print 'alert("You can chose only one record to edit at a time, no more.");' . "\n" if $num == 7 ;
print 'alert("You did not select any Photographers to Delete , try again.");' . "\n" if $num == 9 ;
print 'alert("You did not select a Photographer to work on , please try again.");' . "\n" if $num == 10 ;
print 'history.go(-1);';
print '</script>;';

exit ;
}
	

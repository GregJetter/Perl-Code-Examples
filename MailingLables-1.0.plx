#!/usr/bin/perl -w
#
# MailingLables-1.0.plx
#
# processess SubdivisionMailingList-1.0.tmpl
#
#   The Script takes as input  County passed in a hidden field.
#   count , passed as a hidden field.
#   And any number of additional numbered fields containing Subdivision numbers
#   to include in the mailing list , these are  gleemed by the params hash.
#   The format type  determins what the end resulting file should look like,
#   At present  either a CVS file or an Onmi Forms data file .

use strict;
use HTML::Template;
use DBI;
use CGI  qw(-debug);
use AlaskaMLS;
my $q = new CGI;

# set up database access

my $local_settings = new AlaskaMLS;
my $DATABASE = $local_settings->DATABASE();
my $USERNAME = $local_settings->USERNAME();
my $PASSWORD = $local_settings->PASSWORD();
my $HOSTNAME = $local_settings->SERVER();
my $data_Source = "DBI:mysql:".$DATABASE .":".$HOSTNAME;
my $dbh = DBI->connect($data_Source,$USERNAME,$PASSWORD)
    or die "$DBI::errstr\n";

my $County = $q->param("County");
my $count = $q->param("count");
my $Format = $q->param("formatType");
my  %params = $q->Vars;
my @lables ;
my $lableData;
my @line1;
my @line2;

# check for proper data
if($County eq "--Borough--") { &error(1) ; }
if($Format eq "-Format-") { &error(4); }


if($County eq "Matanuska Susitna" )
   {

my  $query = "Select DISTINCT TX_owners_name1 ,TX_owners_mailing_address1, TX_owners_city , TX_owners_state, TX_owners_zip From Current_Tax_County WHERE TX_subdivision_number = ";

my $test =0 ;

for(1..$count )
  {
     my $number = "number" . $_ ;

    if(exists($params{ $number}))
       {

        my $String = $params{$number} ;

       my $query2 = $query . " '$String' " . "  order by TX_owners_name1 ASC";




        &doQuery($query2);
         $test ++ ;
       }

  }

  if($test == 0)
             {
              &error(2) ;
              }


}


if($Format eq "FormDocs")
   {
     my $number_of_fields = @line2 ;
     my $countString ;
     for (1 ..$number_of_fields )
        {
          $countString = "\"Field" . $_  ."\",";
          push @line1 ,$countString  ;
         }

# pull the last comma off
$line1[$number_of_fields -1] =~ s/,//;
 $line2[$number_of_fields -1] =~ s/,//;

     my $filename =  "MailingLabels.txt";
     print $q->header(-type =>"application/octet-stream",-Content_Disposition =>"attachment;filename=$filename" );
     print @line1;
     print "\x0D\x0A";
     print @line2;
     exit;
   }

 if($Format eq "CSV")
       {
         my $filename =  "MailingLabels.csv";
         print $q->header(-type =>"application/octet-stream",-Content_Disposition =>"attachment;filename=$filename" );
        print @lables ;
        exit;
       }





#--------------------------------- do query ------------------------------------------
# prepare the query and execute it , if there are no results then
# issue a  error message.
sub doQuery {
my $query = shift;
my ($name , $address , $city,$state,$zip);


my $table_output = $dbh->prepare($query);
     $table_output->execute;
my $rows = $table_output->rows;
if( $rows < 1) { &error( 3); }

 $table_output->bind_columns(undef,\($name , $address , $city,$state,$zip));

 # fetch each row  and place them in an array to be written out to the  browser
while ($table_output->fetch)
   {
      $name = &reverse_name($name);
      $name =~ s/^\s//;

      if ($Format eq "CSV")
        {
          $lableData = $name . "," . $address . "," . $city . "," . $state . "," . $zip."\x0D\x0A";
          push @lables , $lableData ;
        }

      if($Format eq "FormDocs")
        {
          $name = "\"$name\"" . "," ;
          push @line2 , $name ;

          $address = "\"$address\"" . ",";
          push @line2 , $address ;

          $city = "\"$city\"" . "," ;
          push @line2 , $city ;

          $state = "\"$state\"" . "," ;
          push @line2 , $state ;

          $zip = "\"$zip\"" . ",";
          push @line2 , $zip;

         }

    } # end while

} # end of doQuery
##########################################################


# -------------------------------------- reverse names ----------------------------
sub reverse_name {
my $string = shift ;
# first check to see if  the string should be  fixed or not
# if a string contains  , INC ,  CORP , CO , it should not be changed.
if( $string =~/\bI\b/) { return $string;}
if( $string =~/\bII\b/) { return $string;}
if( $string =~/\bIII\b/) { return $string;}
if( $string =~/\bAK\b/) { return $string;}
if( $string =~/\bALASKA\b/) { return $string;}
if( $string =~/\bASSN\b/) { return $string;}
if( $string =~/\bAURORA\b/) { return $string;}
if( $string =~/\bBANK\b/) { return $string;}
if( $string =~/\bBAR\b/) { return $string;}
if( $string =~/\bBIG\b/) { return $string;}
if( $string =~/\bBIG\sLAKE\b/) { return $string;}
if( $string =~/\bBUILDERS\b/) { return $string;}
if( $string =~/\bCHEVRON\b/) { return $string;}
if( $string =~/\bCHICKALOON\b/) { return $string;}
if( $string =~/\bCHUGIAK\b/) { return $string;}
if( $string =~/\bCHUGACH\b/) { return $string;}
if( $string =~/\bCHURCH\b/) { return $string;}
if( $string =~/\bCITY\b/) {return $string;}
if( $string =~/\bCLUB\b/) { return $string;}
if( $string =~/\bCO\b/) { return $string;}
if( $string =~/\bCOMM\b/) { return $string;}
if( $string =~/\bCOMPANY\b/) { return $string;}
if( $string =~/\bCONST\b/) { return $string;}
if( $string =~/\bCONT\b/) { return $string;}
if( $string =~/\bCONSTRUCTION\b/) { return $string;}
if( $string =~/\bCORP\b/) {return $string;}
if( $string =~/\bCREEK\b/) { return $string;}
if( $string =~/\bCRK\b/) { return $string;}
if( $string =~/\bDENALI\b/) { return $string;}
if( $string =~/\bDISTRIBUTING\b/) { return $string;}
if( $string =~/\bEKLUTNA\b/) { return $string;}
if( $string =~/\bGARAGE\b/) { return $string;}
if( $string =~/\bGEN\b/) { return $string;}
if( $string =~/\bGLOBAL\b/) { return $string;}
if( $string =~/\bHOUSTON\b/) { return $string;}
if( $string =~/\bINC\b/ ) { return $string ;}
if( $string =~/\bINLET\b/) { return $string;}
if( $string =~/\bINV\b/) { return $string;}
if( $string =~/\bINVESTMENT\b/) { return $string;}
if( $string =~/\bINVESTMENTS\b/) { return $string;}
if( $string =~/\bLLC\b/) { return $string;}
if( $string =~/\bLTD\b/) { return $string;}
if( $string =~/\bEST\b/) { return $string;}
if( $string =~/\bESTATE\b/) { return $string;}
if( $string =~/\bFAM\b/) { return $string;}
if( $string =~/\bFAMILY\b/) { return $string;}
if( $string =~/\bGAS\b/) { return $string;}
if( $string =~/\bLAKE\b/) { return $string;}
if( $string =~/\bLK\b/) { return $string;}
if( $string =~/\bLVG\b/) { return $string;}
if( $string =~/\bMALL\b/) { return $string;}
if( $string =~/\bMARKETING\b/) { return $string;}
if( $string =~/\bMAT\b/) { return $string;}
if( $string =~/\bMAT-SU\b/) { return $string;}
if( $string =~/\bMATANUSKA-SUSITNA\b/) {return $string;}
if( $string =~/\bNATIONAL\b/) { return $string;}
if( $string =~/\bNORTHRIM\b/) { return $string;}
if( $string =~/\bOIL\b/) { return $string;}
if( $string =~/\bPALMER\b/) { return $string;}
if( $string =~/\bPARTNERSHIP\b/) { return $string;}
if( $string =~/\bPARK\b/) { return $string;}
if( $string =~/\bPAWN\b/) { return $string;}
if( $string =~/\bPLAZA\b/) { return $string;}
if( $string =~/\bPLUMBING\b/) { return $string;}
if( $string =~/\bPOINT\b/) { return $string;}
if( $string =~/\bPROP\b/) { return $string;}
if( $string =~/\bPROPERTIES\b/) { return $string;}
if( $string =~/\bPROPERTY\b/) { return $string;}
if( $string =~/\bPRTNRSHP\b/) { return $string;}
if( $string =~/\bRESTAURANT\b/) { return $string;}
if( $string =~/\bREV\b/) { return $string;}
if( $string =~/\bRIVER\b/) { return $string;}
if( $string =~/\bSALES\b/) { return $string;}
if( $string =~/\bSERV\b/) { return $string;}
if( $string =~/\bSERVICE\b/) { return $string;}
if( $string =~/\bSHOP\b/) { return $string;}
if( $string =~/\bSTORE\b/) { return $string;}
if( $string =~/\bSUPPLIES\b/) { return $string;}
if( $string =~/\bSUPPLY\b/) { return $string;}
if( $string =~/\bSUTTON\b/) { return $string;}
if( $string =~/\bSVC\b/) { return $string;}
if( $string =~/\bTALKEETNA\b/) { return $string;}
if( $string =~/\bTHE\b/) { return $string;}
if( $string =~/\bTIRE\b/) { return $string;}
if( $string =~/\bTR\b/) { return $string;}
if( $string =~/\bTRE\b/) { return $string;}
if( $string =~/\bTRES\b/) { return $string;}
if( $string =~/\bTRUST\b/) { return $string;}
if( $string =~/\bTRUSTEE\b/) { return $string;}
if( $string =~/\bTRUSTEES\b/) {return $string;}
if( $string =~/\UNITED\sSTATES\sOF\sAMERICA/) { return $string ;}
if( $string =~/\bUNIVERSITY\b/) { return $string;}
if( $string =~/\bVALLEY\b/) { return $string;}
if( $string =~/\bVAN\b/) { return $string;}
if( $string =~/\bVFW\b/) { return $string;}
if( $string =~/\bVIEW\b/) { return $string;}
if( $string =~/\bWASILLA\b/) { return $string;}
if( $string =~/\bWILLOW\b/) { return $string;}
# added for kenai
if( $string =~/\bCOOK\sINLET\b/) {return $string;}
if( $string =~/\bUNITED\sSTATES\b/) { return $string;}


#
# next we strip off the first word of the string and store it in a varable for later
$string =~ /\b([A-Za-z\']+)\b/ ;
my $string2 = $1;
$string=~ s/$1//;
#next we check the string to see if the next word is abreviated
# if it is we expand it
if($string =~/\b(CHAS)\b/) {$string =~s/$1/CHARLES/ ; }
if($string =~/\b(DAN\'L)\b/) { $string =~s/$1/DANIEL/ ; }
if($string =~/\b(EDW)\b/) { $string =~ s/$1/EDWARD/ ; }
if($string =~/\b(GEO)\b/) { $string =~ s/$1/GEORGE/ ; }
if($string =~/\b(JAS)\b/) { $string =~ s/$1/JAMES/ ; }
if($string =~/\b(JOS)\b/) { $string =~ s/$1/JOSEPH/ ;}
if($string =~/\b(ROBT)\b/) { $string =~ s/$1/ROBERT/ ; }
if( $string =~/\b(THEO)\b/) { $string =~ s/$1/THEODORE/ ;}
if( $string =~/\b(THOS)\b/) { $string =~ s/$1/THOMAS/ ;}
if( $string =~/\b(WM)\b/) { $string =~ s/$1/WILLIAM/ ;}
if( $string =~/\b(TR)\b/) { $string =~ s/$1/TRUST/;}
if( $string =~/\b(TRE)\b/){ $string =~ s/$1/TRUSTEE/ ;}

my $final = $string." ".$string2;
return $final;
}






# -------------------------------------- error routine ---------------------------------
sub error {
my $num = shift;
print $q->header(),$q->start_html;
      print '<script language="JavaScript">'."\n";
      print 'alert( "Please  select a County or Borough Name and try again.");'. "\n" if $num ==1;
      print 'alert("Please select a Subdivision to include in your Mailing List.");' . "\n" if $num == 2 ;
      print 'alert("There are No results from your search , try again");'." \n" if $num == 3;
      print 'alert(" Please Selecte a Format for the mailing labels data. ");' . "\n" if $num == 4 ;
      print 'history.go(-1);'. "\n";
      print '</script>'. "\n";
      print $q->end_html;
      exit;
}
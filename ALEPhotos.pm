# ALEPhotos.pm
#
# this module provides a subrouteen that  takes an MLS number and
# returns a array of Photo URL's for any paticular MLS number. or a single string in
# the case of mainPhotoURL
#

package ALEPhotos;

use CGI;
use LWP::UserAgent;

my $string;
my $q = new CGI;
BEGIN
{
  use Exporter();
  @ISA = qw(Exporter);
  @EXPORT_OK = qw( &getPhotoURL);
}



#***********************************************************************#
#                      getPhotoURL                                      #
#***********************************************************************#

sub getPhotoURL {
my $MLS = shift;
my $HiRES = shift;
my $dataquery;


#print $q->header();
#print "Arrived inside photos\n";
#exit;


my @URL ; 
my $ua = LWP::UserAgent->new();
$ua->credentials('retsgw.flexmls.com:80','rets@flexmls.com','ak.rets.propertyinc','xxxxxxxx');

if($HiRES) 
     {
       $dataquery = "http://retsgw.flexmls.com/rets2_0/GetObject?Type=HiRes&Resource=Property&ID=$MLS:*&Location=1";   
     }else 
       {
         $dataquery = "http://retsgw.flexmls.com/rets2_0/GetObject?Type=Photo&Resource=Property&ID=$MLS:*&Location=1";
       }

#print $q->header();
#print $dataquery ;
#exit;



my $respons = $ua->get($dataquery);  # send off the query to the server

#print $q->header();
#print $respons->content;
#exit;

my $data ;

if ($respons->is_success) {
    $data = $respons->content;  
 }
 else {
     return ;
 }
       
my @Stuff = split/\n\r/,$data ;


for(@Stuff) 
   {
  
     my $string;
     my $url;
     my $num; 
 
     if($_ eq ""){ next;}  # blank line skip it

     if($_=~/Location: (http:\/\/photos.flexmls.com\/ak\/\d*\.jpg)/)
         {
           $url = $1;
  
             if($_=~/Object-ID: (\d*)/)
                {
                  $num = $1;
                }
              $string = "$num|$url";
              push @URL , $string;

           }

    } # end for loop

return @URL ;

} # end getPhotoURL




1;

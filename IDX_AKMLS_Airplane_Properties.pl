#!/usr/bin/perl -w
#
# This script is for AlaskaProperty.Biz via FTP to Mydomains Server
#
# IDX_AKMLS_Airplane_Propteries.pl
#
# this script creates a list of Airplane Properties

use HTML::Template;
use LocalSite;
use DBI;
use Net::FTP;

my $local_settings = new LocalSite;
my $DATABASE = $local_settings->DATABASE();
my $USERNAME = $local_settings->USERNAME();
my $PASSWORD = $local_settings->PASSWORD();
my $HOSTNAME = $local_settings->SERVER();
my $data_Source = "DBI:mysql:".$DATABASE .":".$HOSTNAME;

# connect to db
my $dbh = DBI->connect($data_Source,$USERNAME,$PASSWORD)
    or die "$DBI::errstr\n";

#get template
my $template = "../../KB/Associations/ak/11738_Debbie_Erickson/tmpl_includes/IDX_AKMLS_Airplane_Properties.tmpl";
my $tmpl = new HTML::Template(filename => $template);

my @Properties;
my $ResultsCount;
my $back_page = 0;
my $next_page = 2;
my $no_page = 0;

# make up  the date
my ($Day , $Month , $Year) = (localtime)[3,4,5] ;
$Year = $Year+1900 ;
$Month = $Month + 1 ;

my $today = "$Month-$Day-$Year";

my $numPerPage = 15;

my $query = "SELECT DISTINCT
ListOffice_name,
concat_ws(' ',ListingAddress_StreetNumber,ListingAddress_StreetDirection,ListingAddress_StreetName,
ListingAddress_UnitNumber,ListingAddress_StreetType) as property_address,
ListingAddress_City,
ListingPrice,
PropertyClass,
ALE_Borough_Map2.Borough_Name,
ListAgent_ID,
ALE1.ListingNumber,
NF_LN,
Number_Bath,
Number_Bedroom,
Number_GarageOrCarport,
SqFt_Structure,
SqFt_Building,
MultiType1

FROM ALE1, ALE2,ALE3,ALE_Borough_Map2,ALE_MLS_Trans
WHERE Features_Exterior1 rlike 'Airplane Access'
AND ALE1.ListingNumber= ALE2.ListingNumber
AND ALE2.ListingNumber = ALE3.ListingNumber
AND ALE1.Area = ALE_Borough_Map2.Area_Number
AND ALE_MLS_Trans.ListingNumber = ALE1.ListingNumber
AND PropertyClass IN (1,2,4,5)
order by PropertyClass DESC
 ";

# vars for query results
my($ListOffice_name,
	$property_address,
	$ListingAddress_City,
	$ListingPrice,
	$PropertyClass,
	$Borough_Name,
	$ListAgent_ID,
	$ListingNumber,
	$NF_LN,
	$Number_Bath,
	$Number_Bedroom,
	$Number_GarageOrCarport,
	$SqFt_Structure,
	$SqFt_Building,
	$MultiType1
	);

# bind columns
my $listing_result = $dbh->prepare($query);
   $listing_result->execute;
   $listing_result->bind_columns(undef,\($ListOffice_name,
   $property_address,
   $ListingAddress_City,
   $ListingPrice,
   $PropertyClass,
   $Borough_Name,
   $ListAgent_ID,
   $ListingNumber,
   $NF_LN,
   $Number_Bath,
   $Number_Bedroom,
   $Number_GarageOrCarport,
   $SqFt_Structure,
   $SqFt_Building,
   $MultiType1
   ));

my $rows = $listing_result->rows ;

if($rows < 1) { exit; }

while($listing_result->fetch) {
my $string;
$ResultsCount ++;

# place commas
$ListingPrice = &commify($ListingPrice);

# do photo
my @num = split(//,$ListingNumber);
my $dir = pop(@num); 
my $main_photo ;
my $test_photo = "/home/rgudproperties/property_images/ALE/$dir/$ListingNumber.jpg";

# see if there is a photo if not  use  no photo image
if(-e  $test_photo) 
    { 
      $main_photo = "http://www.rgudproperties.com/property_images/ALE/$dir/$ListingNumber.jpg";
    }else{ $main_photo = "../../images/no_photo2.jpg"; }

# determine class of property
my $classString;
if($PropertyClass eq "1") { $classString = "Single-Family" ; }
if($PropertyClass eq "2") { $classString = "Condo" ;}
if($PropertyClass eq "4") { $classString = "Multi-Family" ;}
if($PropertyClass eq "5") { $classString = "Commercial/Industrial" ;}

my $propertyLinkString = "http://www.alaskaproperty.biz/Alaska_Real_Estate/" . $NF_LN . ".shtml";

# if Residential
if ($PropertyClass eq "1")
{
$string .= "<table id=\"box1\"><tr><td valign=\"top\" align=\"center\">";
$string .= "<table id=\"box2\"><tr><td>";
$string .= "$classString<br>&nbsp;For Sale&nbsp;";
$string .= "</td></tr></table><a href=\"$propertyLinkString\" target= \"_top\">";
$string .= "<img src=\"$main_photo\" height=\"95\" width=\"126\" border=\"0\"></a> ";
$string .= "<br><b>\$ $ListingPrice</b>&nbsp;&nbsp;&nbsp;MLS#&nbsp;$NF_LN ";
$string .= "<br><b>Beds:</b> $Number_Bedroom&nbsp;&nbsp;<b>Baths:</b> $Number_Bath<br><b>Living Area:</b> $SqFt_Structure<br><b>Garage:</b> $Number_GarageOrCarport";
$string .= "<br><a href=\"$propertyLinkString\" target= \"_top\"><b>$property_address<br>$ListingAddress_City, area</b></a>";
$string .= "<br>$ListOffice_name<br><img src=\"http://www.alaskamls.com/logos/ale.gif\"></td></tr></table>";
}

# if Condo
if ($PropertyClass eq "2")
{
$string .= "<table id=\"box1\"><tr><td valign=\"top\" align=\"center\">";
$string .= "<table id=\"box21\"><tr><td>";
$string .= "$classString<br>&nbsp;For Sale&nbsp;";
$string .= "</td></tr></table><a href=\"$propertyLinkString\" target= \"_top\">";
$string .= "<img src=\"$main_photo\" height=\"95\" width=\"126\" border=\"0\"></a> ";
$string .= "<br><b>\$ $ListingPrice</b>&nbsp;&nbsp;&nbsp;MLS#&nbsp;$NF_LN ";
$string .= "<br><b>Beds:</b> $Number_Bedroom&nbsp;&nbsp;<b>Baths:</b> $Number_Bath<br><b>Living Area:</b> $SqFt_Structure<br><b>Garage:</b> $Number_GarageOrCarport";
$string .= "<br><a href=\"$propertyLinkString\" target= \"_top\"><b>$property_address<br>$ListingAddress_City, area</b></a>";
$string .= "<br>$ListOffice_name<br><img src=\"http://www.alaskamls.com/logos/ale.gif\"></td></tr></table>";
}

# if Multi-Family
if ($PropertyClass eq "4")
{
$string .= "<table id=\"box1\"><tr><td valign=\"top\" align=\"center\">";
$string .= "<table id=\"box24\"><tr><td>";
$string .= "$classString<br>&nbsp;For Sale&nbsp;";
$string .= "</td></tr></table><a href=\"$propertyLinkString\" target= \"_top\">";
$string .= "<img src=\"$main_photo\" height=\"95\" width=\"126\" border=\"0\"></a> ";
$string .= "<br><b>\$ $ListingPrice</b>&nbsp;&nbsp;&nbsp;MLS#&nbsp;$NF_LN ";
$string .= "<br><b>Style:</b> $MultiType1<br><b>Building Area:</b> $SqFt_Building";
$string .= "<br><a href=\"$propertyLinkString\" target= \"_top\"><b>$property_address<br>$ListingAddress_City, area</b></a>";
$string .= "<br>$ListOffice_name<br><img src=\"http://www.alaskamls.com/logos/ale.gif\"></td></tr></table>";
}

# if Commercial
if($PropertyClass eq "5" )
{
$string .= "<table id=\"box1\"><tr><td valign=\"top\" align=\"center\">";
$string .= "<table id=\"box22\"><tr><td>";
$string .= "$classString<br>&nbsp;For Sale&nbsp;";
$string .= "</td></tr></table><a href=\"$propertyLinkString\" target= \"_top\">";
$string .= "<img src=\"$main_photo\" height=\"95\" width=\"126\" border=\"0\"></a> ";
$string .= "<br><b>\$ $ListingPrice</b>&nbsp;&nbsp;&nbsp;MLS#&nbsp;$NF_LN ";
$string .= "<br><a href=\"$propertyLinkString\" target= \"_top\"><b>$property_address<br>$ListingAddress_City, area</b></a>";
$string .= "<br>$ListOffice_name<br><img src=\"http://www.alaskamls.com/logos/ale.gif\"></td></tr></table>";
}

# add to the array 
push @Properties , $string ;
}

# the array is build
# now build the page and print it out
# the array is built
my @tr_data ;
my $totalProps = $#Properties + 1 ;

# how many pages
my $PageCount ;
if($totalProps < $numPerPage ) 
  { 
    $PageCount = 1 ;
   }
   else
    {
      $PageCount = $totalProps / $numPerPage ;
      my $Remainder = $totalProps % $numPerPage ;
       if($Remainder >0 ) { $PageCount ++ ; }
      }

for(1..$PageCount)
{
    for(1...5)
     {
      my %hash = (table_data1 => pop(@Properties) ,
                  table_data2 => pop(@Properties) ,
		  table_data3 => pop(@Properties) );
       push @tr_data , \%hash ;
     }

my $outfile = "/home/AKMLS/KB/Associations/ak/11738_Debbie_Erickson/FTP/";
   $outfile .= "Airplane_Properties$_" ;
   $outfile .= ".shtml";
   
 # kb 3-30-11
 my $back_page = $back_page  ++ ;
 my $next_page = $next_page ++ ;
 if($next_page > $PageCount) { $next_page = 0 };
 if($PageCount >= 2 ){ $no_page = 1 };
 
 $tmpl->param( back_page => $back_page);
 $tmpl->param( next_page => $next_page);
 $tmpl->param( no_page => $no_page);   
 $tmpl->param(ResultsCount => $totalProps);  
 $tmpl->param(tr_data => \@tr_data);
 $tmpl->param(TODAY => $today);
 $tmpl->param(pageNumber => $_ );

# pass the template pages var
for(1..$PageCount)
    { 
      my $page = "page$_" ;
      $tmpl->param( $page => 1) ;
    }

#print $outfile ; exit;

open(OUTFILE , ">$outfile") or die "can't open index file : $!";
print OUTFILE $tmpl->output;
close OUTFILE; 

@tr_data = ();
$outfile =~ s/\d+Airplane_Properties\.shtml$//;
} # end for    

$dbh->disconnect;

# ok now we got another set of files lets ftp them to their new home
my $user = "akproperty";
my $pass = "Trussell";

my $local_path = "/home/AKMLS/KB/Associations/ak/11738_Debbie_Erickson/FTP/";
my $remote_path = "/webspace/httpdocs/";
my $ftp = Net::FTP->new("d1138983-4.mydomainwebhost.com" , Debug => 0) or die "cannot connect to alaskaproperty.biz: $@";
   $ftp->login($user,$pass) or die "Cannot login", $ftp->message;

#read the  storage directory  , match for  ap , then call  ftp->put on that file
opendir(EXPORTS, $local_path) or die "can not open directory $local_path";
my $file;
while(defined ($file = readdir EXPORTS))
{
  next if $file =~ /^\.\.?$/;
  if($file =~ m/^Airplane_Properties/ )
    {
      my $local_file = $local_path . $file ;
      my $remote_file = $remote_path . $file ;
      $ftp->put($local_file , $remote_file) or die "put failed" , $ftp->message;
     
    }

}

$ftp->quit;



#------------------------- place commas into numbers ----------------------------
sub commify {
my $text = reverse $_[0] ;
$text =~ s/(\d\d\d)(?=\d)(?!\d*\.)/$1,/g;
return scalar reverse $text;
}


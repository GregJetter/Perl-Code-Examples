#!/usr/bin/perl -w
#
# ManagePhotos.pl
#
# This script can be called from many diffrent  web pages , it manages the
# Add , Edit  and Delete functions for photographs . It is the  main interactive 
# gateway for  the photo data base  records. It is part of the akstockphotos.com web application.



use strict;
use DBI;
use CGI;
use HTML::Template ;

# set up db stuff
# connect to the db
my $db = "AKSTOCKPHOTOS";
my $host = "localhost";
my $user = "stock_user";
my $password = "xxxxxxx";


my $dbh = DBI->connect("DBI:mysql:database=$db:$host=$host",$user,$password) or die "cannot connect to DB: $DBI::errstr\n";

# make cgi object
my $q = new CGI;


# some global vars
my($displayImage,$thumbImage);


# main , if this  script is called with no passed values then create the 
# data entry screen.
# find out how were are called
my $type = $q->param("TYPE");

if($type eq "ADD")    { &addRecord ; }
if($type eq "CHANGE") { &changeRecord ; }
if($type eq "DELETE") { &deleteRecord ; }
if($type eq "EDIT")   { &editRecord ; }
if($type eq "VIEW")   {&viewRecord ;}

# we were called with no passed param so lets create the page.

my $template = "../template/Add_Photos.tmpl";

# vars
my $tmpl = new HTML::Template(filename => $template);

# load up  values for the  add photo template

# do photoraphers
my @PHOTOGRAPHER_DATA ;
my ($id,$fname,$lname);
my $photographerQuery = "SELECT ID,First_Name,Last_Name FROM AKSTOCKPHOTOS.Photographer_INFO";
my $result = $dbh->prepare($photographerQuery);
   $result->execute();
   $result->bind_columns(undef,\($id,$fname,$lname));
   
   while($result->fetch) {
      
      my %table = ( ID => $id , FNAME => $fname , LNAME => $lname);
      push @PHOTOGRAPHER_DATA , \%table ;
                                 
      }
      
$tmpl->param( PHOTOGRAPHER_DATA => \@PHOTOGRAPHER_DATA);

# next load catagories
my @CATAGORY_DATA;
my ($id2,$catagory);
my $catagoryQuery = "SELECT ID,Name FROM AKSTOCKPHOTOS.Catagories";
my $catResult = $dbh->prepare($catagoryQuery);
   $catResult->execute();
   $catResult->bind_columns(undef,\($id2,$catagory));
   
   while($catResult->fetch){
      
      my %table = ( ID2 => $id2 , CAT => $catagory);
      push @CATAGORY_DATA , \%table ;
   }
$tmpl->param( CATAGORY_DATA => \@CATAGORY_DATA) ;
             

# print the template
print $q->header();
print $tmpl->output;  

############################### add Record ###########################################

sub addRecord {
   
# extract the passed values and check them . 

my $photographer = $q->param("PHOTOGRAPHER");
my $catagory     = $q->param("CATAGORY");  # make sure  no select is accepted.
my $title        = $q->param("TITLE");
my $image_date   = $q->param("DATE_TAKEN");
my $location     = $q->param("LOCATION"); 
my $release      = $q->param("MODEL_RELEASE");
my $caption      = $q->param("CAPTION");
my $file         = $q->param("file");
my $ImageSize    = $q->param("FILESIZE");
my $width        = $q->param("WIDTH");
my $height       = $q->param("HEIGHT");
my $resolution ;


# check for valid input

if($catagory=~/^---/) { &error(6);}
if(!$file) { &error(7);}


if($ImageSize) {
		  unless ($ImageSize=~/^[-+]?([0-9]+(\.[0-9]+)?|\.[0-9]+)$/) { &error(4); }
   
		}

if($width) {
		unless ($width =~/^\d{2,4}$/) { &error(5);}
            }
            
if($height) {
		unless ($height =~/^\d{2,4}$/) { &error(5);}
            }            


# create resolution string
if($width && $height) { $resolution = $width . "X" . $height ; }


# upload the file , change its name 	
my $dir = "/media/sda1/HiRes/";
my $photoID = $photographer . "_" . $catagory . "_" . $file ;
my $image = $dir . $photoID;

open(LOCAL, ">$image") or die $! ;
while(<$file>) {
   print LOCAL $_;
}


# make up the thumb and watermarked image
my $imagesMade = &makeImages($catagory,$photoID,$image);

	
#  wirte out the data record	
# first check for existing record
my $existQuery = "SELECT PhotoIdentifier FROM AKSTOCKPHOTOS.Photo WHERE PhotoIdentifier = ? AND Photographer = ? ";
my $result = $dbh->prepare($existQuery);
   $result->execute($photoID,$photographer);
my $rows = $result->rows;



# if no existing record then add the record.
 if($rows < 1) {
       
    
		my $addQuery = "INSERT INTO AKSTOCKPHOTOS.Photo(
		                        PhotoIdentifier,
		                        Photographer,
		                        Catagory,
		                        Model_Release,
		                        Title,
		                        Caption,
		                        Date_Taken,
		                        Path_HR,
		                        Path_WM,
		                        Path_Thum,
		                        Geo_Location,
		                        File_Size_MB,
		                        Width_pixels,
		                        Height_pixels,
		                        Resolution)VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)";
		
		my $addResult = $dbh->prepare($addQuery);
		   $addResult->execute($photoID,$photographer,$catagory,$release,$title,$caption,$image_date,$image,
		                       $displayImage,$thumbImage,$location,$ImageSize,$width,$height,$resolution);
		                           
             my $insertRows = $addResult->rows;
             if($insertRows < 1) {
					&error(1); 
					}
					else { # notify user of success.
					       print $q->header();
                                               print '<script language="JavaScript">;' . "\n";
                                               print 'alert("New Photo added to the database");' ."\n" ;
                                               print 'history.go(-1);';
                                               print '</script>;';
                                             }
                       }	
	
}	


############################################# makeThumbs and display images #######################################
sub makeImages {
   
use Image::Magick;

my $catagory = shift;
my $photoID = shift;
my $hiResImage = shift;
my $cat_Name ;


# translage catagory into string , look up catagory 
my $query = " SELECT Name FROM AKSTOCKPHOTOS.Catagories WHERE ID = ? "; 
my $result = $dbh->prepare($query);
   $result->execute($catagory);
   $result->bind_col(1,\$cat_Name);
   $result->fetch ;
   
$displayImage = "/media/sda1/photos/$cat_Name/"  . $photoID ;

$thumbImage   = "/media/sda1/thumbs/$cat_Name/"  . $photoID;

# create  images
# make thumb
my $Thumb = Image::Magick->new;
my $x2 = $Thumb->Read($hiResImage);
   $x2 = $Thumb->Thumbnail(geometry => '150x150');
warn "$x2" if "$x2";
$x2 = $Thumb->Write(filename=>$thumbImage);
warn "$x2" if "$x2";
undef $Thumb;

# make display image
my $Display = Image::Magick->new;
my $x3 = $Display->Read($hiResImage);
warn "$x3" if "$x3";
$x3 = $Display->Scale(geometry => '600x400');
warn "$x3" if "$x3" ;
my $logofile = "watermark1.png";
my $logo = Image::Magick->new;
   $logo->Read($logofile);
    
$x3 = $Display->Composite( compose=>'blend',
                          blend=> '50x50',
                          x=>'50', y=>'50',
                          image=>$logo, gravity=>'South');
warn "$x3" if "$x3" ;
$x3 = $Display->Write(filename=> $displayImage);
warn "$x3" if "$x3";

undef $Display;

return 1 ;
	
}
################################ view records ###########################################
sub viewRecord {

my $template2 = "../template/view_photos.tmpl";
my $tmpl2 = new HTML::Template(filename => $template2);
my $photographer = $q->param("PHOTOGRAPHER");
my ($ID,$PhotoID,$catagory,$title,$caption,$date,$path,$path2,$resolution);
my @PHOTO_DATA;
my $query = "SELECT ID,PhotoIdentifier,Catagory,Title,Caption,Date_Taken,Path_WM,Path_Thum,Resolution FROM AKSTOCKPHOTOS.Photo WHERE Photographer = ? ";
my $result = $dbh->prepare($query);
   $result->execute($photographer);
   $result->bind_columns(undef,\($ID,$PhotoID,$catagory,$title,$caption,$date,$path,$path2,$resolution));
   
   my $rows = $result->rows ;
   
   # if  no photos for that photographer  error and exit gracefully.
   if($rows < 1 ) { &error(2) ; }
   
   while($result->fetch){
      
      
      # look up catagory and get  it's name from number
      my $name;
      my $lookupQuery = "SELECT Name FROM AKSTOCKPHOTOS.Catagories WHERE ID = '$catagory' ";
      my $nameResult = $dbh->prepare($lookupQuery);
         $nameResult->execute();
         $nameResult->bind_col(1,\$name);
      $nameResult->fetch;
               
      my %table = (ID => $ID, PATH => $path , PATH2 => $path2, CAPTION => $caption , PHOTOID => $PhotoID , TITLE => $title , CATAGORY => $name , DATE => $date , RESOLUTION => $resolution );
      push @PHOTO_DATA , \%table ;
            
      }
   
   $tmpl2->param( PHOTO_DATA => \@PHOTO_DATA);
   print $q->header();
   print $tmpl2->output;  

exit;   
}

############################### change Record ###########################################
sub changeRecord {
# build the edit screen for the chosen photo here

my $ID = $q->param("ID") || &error(3);

# create error if more than one




# get  infor for edit form from db photo table

my $template3 = "../template/Change_Photos.tmpl";
my $tmpl3 = new HTML::Template(filename => $template3);

my($Title,$Caption,$Path,$Location);
my $query = "SELECT Title,Caption,Path_HR,Geo_Location FROM AKSTOCKPHOTOS.Photo WHERE ID = ? ";
my $result = $dbh->prepare($query);
   $result->execute($ID);
   $result->bind_columns(undef,\($Title,$Caption,$Path,$Location));
   $result->fetch;
   
  $tmpl3->param( ID => $ID , TITLE => $Title , CAPTION => $Caption , PATH => $Path , LOCATION => $Location ); 
	
print $q->header();
print $tmpl3->output;
		
exit;	
}
################################ delete Record #######################################
sub deleteRecord {
# allow  the deletion of the record and  the image file.	
	
	
	
	
}
############################### edit Record #########################################
sub editRecord {
# check then commit the record changes here

my $Title = $q->param("TITLE");
my $Location = $q->param("LOCATION");
my $Id = $q->param("ID");
my $Caption = $q->param("CAPTION");

my $query = "UPDATE AKSTOCKPHOTOS.Photo SET Title = ? ,Geo_Location = ? , Caption = ? WHERE  ID = ?";
my $result = $dbh->prepare($query);
   $result->execute($Title,$Location,$Caption,$Id);
   
print $q->header();
                        print '<script language="JavaScript">;' . "\n";
                        print 'alert("The Photo Information Has been Updated in the data base.");';
                        print 'history.go(-2);';
                        print '</script>;';



exit;
	
}
################################### errors ##########################################
sub error {
	
my $num = shift;
print $q->header();
print '<script language="JavaScript">;' . "\n";
print 'alert("Adding new photo failed ! contact  administrator !");' . "\n" if $num == 1 ;
print 'alert("The Photographer you selected currently has no images in the system .");' . "\n" if $num == 2 ;
print 'alert("You forgot to select a photo information record to edit , try again.");' . "\n" if $num == 3 ;
print 'alert("File Size must be a floating point number . example =  1.2 , try again.");' . "\n" if $num == 4 ;
print 'alert("Width and height must be 3 to 4 didgets only.");' . "\n" if $num == 5 ;
print 'alert("Please Select a Catagory !.");' . "\n" if $num == 6;
print 'alert("Please Select a Photo File to Upload ! ");' . "\n" if $num == 7 ;
print 'history.go(-1);';
print '</script>;';

exit ;	
	
	
}







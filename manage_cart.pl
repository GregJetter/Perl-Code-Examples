#!/usr/bin/perl -w
#
# manage_cart.pl
#
# This script when called  , gets the cookie called "ShoppingCart" from the 
# calling browser , it then parses out the value and displays it to the user.
# the user than can select items to remove  , continue shopping or check out.

use strict;
use HTML::Template;
use CGI;
use DBI;

# connect to the db
my $db = "AKSTOCKPHOTOS";
my $host = "localhost";
my $user = "stock_user";
my $password = "xxxxxxx";
my $dbh = DBI->connect("DBI:mysql:database=$db:$host=$host",$user,$password) or die "cannot connect to DB: $DBI::errstr\n";

# create the cgi object
my $q = new CGI;

# check for cookie , if  user not registered re direct to signup page.
my $theCookie = $q->cookie('USER-ID');
if(!$theCookie) { &goToSignup();}

# check against the members table.
my $query_members = "SELECT TOKEN FROM AKSTOCKPHOTOS.Member WHERE TOKEN = ?";
my $result_members = $dbh->prepare($query_members);
   $result_members->execute($theCookie);
my $rows_members = $result_members->rows;

if($rows_members < 1){ &goToSignup(); }



# see how we are called
my $type = $q->param("TYPE");

if($type eq "SHOW"){
&ViewCart();
}

if($type eq "UPDATE") {
   &UpDate();
}

# view the  contents of the cookie and create the edit page
#################################### View Cart contents ########################
sub ViewCart{

my $template = "/home/akstockphotos/template/manageCart.tmpl";
my $tmpl = new HTML::Template(filename => $template);	
my @PHOTO_DATA ;
	
## read the cookie
my $CartCookie = $q->cookie('ShoppingCart');

if($CartCookie) {
   
# hard code price
my $price ;
my $total;
my $path_thumb;
# convert incoded colen to string

# take out the word null	
$CartCookie=~s/null//g;

# split into componet parts
my @items = split(/:/,$CartCookie);


#print $q->header();
#for(@items) { print $_ ; }
#exit;


   for(@items){
	   
    ## get the DB info on cart contents
	my $query = "SELECT Path_Thum ,Price
                     FROM AKSTOCKPHOTOS.Photo 
                     WHERE Photo.ID = ? ";
                     
                                         
        my $result = $dbh->prepare($query);
           $result->execute($_);
           $result->bind_columns(undef,\($path_thumb,$price));   
           
           while($result->fetch) {
              
              my %table = (PHOTO_ID => $_ ,
	             PATH_THUMB => $path_thumb,
	             PRICE => $price ,
	             TOTAL => $total + $price );
	             
	      push @PHOTO_DATA , \%table ;
             $total = $total + $price;
                      
           }
           
	
   }
## fill in template and  show page
$tmpl->param( PHOTO_DATA => \@PHOTO_DATA) ;
print $q->header();

print $tmpl->output;

}
else { &error(1); exit;}


} # end view cart

###################################### update the cart contents ####################
sub UpDate {

use CGI::Cookie ;


# get list of items to delete from cookie
my @DELETES = $q->param("DELETE") or &error(2);
 
 
  
# read the current value of the cookie
#my $CartCookie = $q->cookie('ShoppingCart');
my %cookies = CGI::Cookie->fetch;
my $CartCookie = $cookies{ShoppingCart}->value;


# take out the word null	
$CartCookie=~s/null//g;

# split into componet parts
my @items = split(/:/,$CartCookie);


# delete items
for(@DELETES) {

my $item = $_ ;
@items = grep { $_ ne $item } @items ;
 
}


# re write cookie with updated values
my $cookie_string = "null:" ;
for(@items) {
   $cookie_string .= "$_" . ":" ;

}



my $cookie = CGI::Cookie->new( -name => 'ShoppingCart',
                               -value   => $cookie_string ,
                               -expires => '+3d' ,
                               -domain  => '.akstockphotos.com',
                               -path    => '/');

$cookie->bake;



# reload the cart page 

print '<script language="JavaScript">;' . "\n";
print 'window.location.assign("http://akstockphotos.com/cgi-bin/manage_cart.pl?TYPE=SHOW");';
#print 'history.go(-2);';
print '</script>;';

   
   
    
} # end update


########################################## GO TO SIGNUP #############################
sub goToSignup {
   
        print $q->header();
	print '<script language="JavaScript">;' . "\n";	
	print 'alert( "To view or purchase images on this site you must first redigster ");' . "\n"; 
	print 'window.location.assign("http://akstockphotos.com/SignUp.html");';
        print '</script>;';
exit;
}


########################################## errors ####################################
sub error {
	
my $num = shift;

print $q->header();
print '<script language="JavaScript">;' . "\n";
print 'alert("Your Shopping cart is Empty !");' . "\n" if $num == 1 ;
print 'alert("You have not selected any thing to delete from your cart.\n OR\n Your Cart is empty");' . "\n" if $num == 2 ;
print 'history.go(-1);';
print '</script>;';	
		
} 



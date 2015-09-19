#!/usr/bin/perl 
use lib 'include/mods';
use Controller::WebSpider;
use CGI qw(:standard); 

print header(-type => "text/plain",-charset => 'iso-8859-1');

my $agent = new Controller::WebSpider;
my $url = 'http://helm3url.tld:8086';

#Helm3 spider
$agent->get($url);
#logon
$agent->form_name('frmLogon');
$agent->field('txtUsername','Admin');
$agent->field('txtPassword','Helm2Password');
$agent->field('selLanguageCode','EN');
$agent->submit;

#redirected
if ($agent->response and my $refresh = $agent->response->header('Refresh') ){
    my($delay, $uri) = splitm/;url=/i, $refresh;
    $uri ||= $agent->uri; # No URL; reload current URL.
    sleep $delay;
    $agent->get($uri);
}

#Look if domain exist
$agent->form_name('frmJumpToDomain');
my $domain = 'ADomainRegisteredOnHelm3.com.br';
$agent->field('txtDomainName',$domain);
$agent->submit;
unless ($agent->response and $agent->content =~ m/There are currently no domains to display/) {
	die "Domain already exists";	
}

#Create domain's user
#Choose username
$userinc = (split(/\./, $domain))[0];
my $i = 0; my $ok = 0; my $user; 
while ($ok == 0) {
	if ($i < 1) {
		$user = $userinc;
	} else {		 
		$user = $userinc.$i;
	}
	##Look if username exist
	$agent->form_name('frmJumpToUser');
	$agent->field('txtUserAccNum',$user);
	$agent->submit;
	if ($agent->response and $agent->content =~ m/There are currently no users to display/) {
		$ok = 1;	
	}
	$i++;		  
}

#Create reseller's user
$agent->get($url.'/interfaces/standard/addUser.asp');
$agent->form_name('frmAddUser');
$agent->select('UserType','1');#Reseller
#... .an so on.....
#if ("The username you have specified is already in use or invalid.  Please type a different account number and try again.")
#Response.write "Reseller: " & User & vbcrlf

print $agent->content;
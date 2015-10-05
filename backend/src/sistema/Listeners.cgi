#!/usr/bin/perl
use CGI qw(:standard);
#use DBI();
#use Digest::MD5;
use CGI::Carp qw(fatalsToBrowser set_message);
# IMPRIME ERROS
use Cwd; 

#use strict;
use lib getcwd;
use lib 'include/mods';

use Controller;
$CGI::DISABLE_UPLOADS = 0;
$CGI::POST_MAX = 2048 * 1024;

use vars qw[ $system $dbhost $dbuser $dbpass $dbname $q ];

require "../db.cfg";

eval{
	our $q = new CGI;
	#Controller::Post2Get($q);
	$system = new Controller (
				'_type'=>'mysql', 			
				'_host'=>$dbhost,
				'_user'=>$dbuser,
				'_pass'=>$dbpass,
				'_inst'=>$dbname,
				'_cwd'=>getcwd,
				'_fd_logs'=>'../logs',
	);

	#Modulos personalizados	
	push @INC, $system->setting('app').'/modules';

	#Suites de teste
	require $system->setting('app').'/modules/Listeners/'.$q->url_param('module').".pl"; # The param() method will always return the contents of the POSTed fill-out form, ignoring the URL's query string. To retrieve URL parameters, call the url_param() method.
};

if ($@) {
	print "Content-type: text/plain\n\n";
	print $@;
}

END{};
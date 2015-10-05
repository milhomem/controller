#!/usr/bin/perl
use CGI qw(:standard);                                 
use DBI();                                             
use Digest::MD5;
use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS
use Cwd;
	
use strict;
use lib getcwd;    
use lib 'include/mods';
use Controller;

$CGI::DISABLE_UPLOADS = 0;
$CGI::POST_MAX = 2048 * 1024;

use vars qw[ $dbh $theme $language $action $bypass $dbname $dbhost $dbuser $dbpass $WIN %global $q %template $sect $tfile %LANG $system ]; 

require "include/conf.cgi";

eval {                                  
	$q = CGI->new(); 
	my $qs = $q->query_string();
	my $protocol = $ENV{'SERVER_PROTOCOL'};
	Post2Get($q);
	$system = new Controller ( 
			'_type'=>'mysql', 
			'_host'=>$dbhost, 
			'_user'=>$dbuser, 
			'_pass'=>$dbpass, 
			'_inst'=>$dbname,
			'_cwd'=>getcwd,
			'_fd_logs'=>'../logs',
			);                         
	
	if ($system->setting('trustedkey') ne $q->param('key')) {
		my $err;
		foreach (keys %ENV) {
			$err .= "$_ = $ENV{$_}\n"; 
		}
		$system->set_error($err.$qs."\nSERVER_PROTOCOL: $protocol\n");
		die "Erro na chave;"
	} 

	$language = $q->param('lang') || $q->cookie('ulanguage') || $system->setting('language');
	#Alternando configurações
	$system->_setlang($q->param('lang') || $q->cookie('language'));	
	
	do "$global{app}/lang/$language/lang.inc";
	require "include/api_subs.cgi";
	navigate();
};

if ($@) { 
	LOG_ERROR("$@");                                       
	script_error("$@");
}                                                       

sub navigate
{         
	$action = $q->param('action');
	if ($q->param('do')) {
		section($q->param('do'));   
	} elsif($action) {
		check_user();
		print "Content-type: text/html\n\n";
		function("$action");
	} else {
		section("login");
	}
}

END 
{
}
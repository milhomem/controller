#!/usr/bin/perl

use CGI qw(:standard);                                 
use DBI();                                             
use Digest::MD5;
use Socket;
use MIME::Base64 qw(encode_base64);
use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS
use Time::HiRes qw(sleep gettimeofday tv_interval);
use Cwd;
	
use strict;
use lib getcwd;  
use lib 'include/mods';
use Mail::Sender;
use Controller;

use vars qw[ $dbh $theme $language $action $bypass $dbname $dbhost $dbuser $dbpass $WIN %global $q %template $sect $dbuser $tfile %LANG $system ]; 

require "include/conf.cgi";

eval {
	$dbh   =  DBI->connect("DBI:mysql:$dbname:$dbhost","$dbuser","$dbpass") || script_fatal("Erro ao conectar-se com o banco:<br>*$DBI::errstr");
	%global   =  get_vars();                                    
	$q        =  CGI->new();  

	$system = new Controller ( 
			'_type'=>'mysql', 
			'_host'=>$dbhost, 
			'_user'=>$dbuser, 
			'_pass'=>$dbpass, 
			'_inst'=>$dbname,
			'_cwd'=>getcwd,
			'_fd_logs'=>'../logs',
			);   
			
	&get_time($q->cookie('tzo'));
	
	$language = $q->param('lang') || $q->cookie('language') || $global{'language'};
	$theme = $q->param('skin') || $q->cookie('skin') || $global{'skin'};

	#refazendo cookie lang e skin
	print cookies(0,'1y','language:'.$language,'skin:'.$theme);     

	do "$global{app}/lang/$language/lang.inc";
	require "include/parse/navigator.cgi";
	require "include/nav_subs.cgi";

	$dbh->disconnect;

};

if ($@) { 
	LOG_ERROR("$@");
	$dbh->disconnect;                                            
	script_error("$@");
}    
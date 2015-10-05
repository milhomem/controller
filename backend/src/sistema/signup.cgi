#!/usr/bin/perl

use CGI qw(:standard);                                 
use DBI();                                             
#use Digest::MD5;
use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS
use Cwd;
	
use strict;
use lib getcwd;  
use lib 'include/mods';
use Controller;

$CGI::DISABLE_UPLOADS = 0;
$CGI::POST_MAX = 500 * 1024; 

use vars qw[ $dbh $theme $language $dbname $dbhost $dbuser $dbpass $WIN %global $q %template %LANG $system]; 

require "include/conf.cgi"; 

eval {
	$dbh   =  DBI->connect("DBI:mysql:$dbname:$dbhost","$dbuser","$dbpass") || script_fatal("Erro ao conectar-se com o banco:<br>*$DBI::errstr");
	%global   =  get_vars();                                    
	$q        =  CGI->new(); 
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
				
	&get_time();
	
	$language = $q->param('lang') || $q->cookie('language') || $global{'language'};
	$theme = $q->param('skin') || $q->cookie('skin') || $global{'skin'};  
	#Alternando configurações
	$system->_setlang($q->param('lang') || $q->cookie('language'));
	$system->_setskin($q->param('skin') || $q->cookie('skin'));

	#Modulos personalizados	
	push @INC, $system->setting('app').'/modules';
		
	#refazendo cookie lang e skin
	print cookies(0,'1y','language:'.$language,'skin:'.$theme);     

	do "$global{app}/lang/$language/lang.inc";
	require "include/func_services.cgi";
	require "include/func_tickets.cgi";
	require "include/signup_subs.cgi";

	$dbh->disconnect;
};

if ($@) { 
	LOG_ERROR("$@");
	$dbh->disconnect;                                            
	script_error("$@");
}                                                       

END 
{
}
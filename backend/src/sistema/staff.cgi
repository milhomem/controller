#!/usr/bin/perl

use CGI qw(:standard);                                 
use DBI();                                             
use Digest::MD5;
use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS
use Cwd;
	
#use strict;
use lib getcwd;  
use lib 'include/mods';
use Controller;

$CGI::DISABLE_UPLOADS = 0;
$CGI::POST_MAX = 2048 * 1024;

use vars qw[ $dbh $sect $theme $language $action $bypass $dbname $dbhost $dbuser $dbpass $WIN $global %global $q %template $Cookie $sect $tfile %LANG $system]; 

$tfile = "staff.cgi";
$sect = "staff";

require "include/conf.cgi";

eval {
	$dbh = DBI->connect("DBI:mysql:$dbname:$dbhost","$dbuser","$dbpass") || script_fatal("Erro ao conectar-se com o banco:<br>*$DBI::errstr");

	%global = get_vars();	
	$q = CGI->new();
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

	sub Controller::logcron {return;} #Não loga no cron
			
	die_nice("Arquivo acima do limite especificado") if $q->cgi_error =~ m/413/;

	&get_time();

	$language = $q->param('lang') || $q->cookie('language') || $global{'language'};
	$theme = $q->param('skin') || $q->cookie('skin') || $global{'skin'};
	
	#Alternando configurações
	$system->_setlang($q->param('lang') || $q->cookie('ulanguage'));
	$system->_setskin($q->param('skin') || $q->cookie('uskin'));
	
	#Modulos personalizados	
	push @INC, $system->setting('app').'/modules';
	
	#refazendo cookie lang e skin
	print cookies(0,'1y','','language:'.$language,'skin:'.$theme);     

	local $Controller::SWITCH{skip_logmail} = 1; #Não logar emails do staff
	do "$global{app}/lang/$language/lang.inc";
	require "include/parse/staff.cgi";
	require "include/staff_subs.cgi";
	require "include/func_tickets.cgi";
	navigate();

	$dbh->disconnect;
};

if ($@) {     
	LOG_ERROR("$@");
	$dbh->disconnect;                                            
	script_error("$@");
	exit;
}                                                       

sub navigate
{         
	$action = $q->param('action');
	if ($q->param('do')) {
		section($q->param('do'));   
	} elsif ($action) {
		check_user();
	#	print "Content-type: text/html\n\n";
		function($action);
	} else {
		section("login");
	}
}

END
{
}
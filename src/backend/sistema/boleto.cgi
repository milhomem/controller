#!/usr/bin/perl

use CGI qw(:standard);                                 
use DBI();
use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS
use Cwd;
	
use strict;
use lib getcwd;      
use lib 'include/mods';
#Modulos personalizados
use lib '../app/modules';

use Controller;

use vars qw[ $dbh $theme $language $bypass $dbname $dbhost $dbuser $dbpass $WIN %global $q %template $tfile %LANG $system]; 

$tfile = "boleto.cgi";

require "include/conf.cgi";
 
eval {
	$dbh = DBI->connect("DBI:mysql:$dbname:$dbhost","$dbuser","$dbpass");
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
				
	&get_time();

	$language = $q->param('lang') || $q->cookie('language') || $global{'language'};
	$theme = $q->param('skin') || $q->cookie('skin') || $global{'skin'};  

	#refazendo cookie lang e skin
	print cookies(0,'1y','language:'.$language,'skin:'.$theme);     

	do "$global{app}/lang/$language/lang.inc";
	require "include/bl_subs.cgi";
};

if ($@){
	LOG_ERROR("$@");
	$dbh->disconnect; 
	script_error("$@");
	print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=1 color=#666666><b>BOLETO </b></font><font color=#CC0000>NÃO EXISTENTE EM NOSSO SISTEMA</font>.</b><br><br> </font></p>|;
	exit;
}

END
{
}
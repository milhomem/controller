#!/usr/bin/perl

use CGI qw(:standard);  
use DBI;
use Time::HiRes qw(sleep gettimeofday tv_interval);
#use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS
use Cwd;
	
use strict;
use lib getcwd;   
use lib 'include/mods';
#Modulos personalizados
use lib '../app/modules';

use Controller;

use vars qw[ $dbh $theme $language $bypass $dbname $dbhost $dbuser $dbpass $WIN $global %global $q %template $Etipo $Eid $tfile %LANG $system $DEBUG ]; 

$tfile = "cron.cgi";
$DEBUG = $ARGV[1]; #ARGV[0] é o nome da aplicação cliente rodando

require "include/conf.cgi";

eval
{
	$dbh   =  DBI->connect("DBI:mysql:$dbname:$dbhost","$dbuser","$dbpass") || script_fatal("Erro ao conectar-se com o banco:<br>*$DBI::errstr");
	%global   =  get_vars();                                    
	$q        =  CGI->new();
	&get_time();
	$system = new Controller ( 
		'_type'=>'mysql', 
		'_host'=>$dbhost, 
		'_user'=>$dbuser, 
		'_pass'=>$dbpass, 
		'_inst'=>$dbname,
		'_cwd'=>getcwd,
		'_fd_logs'=>'../logs',
	);
			
	$language = $global{'language'};
	$theme = $global{'skin'};  

	print "Content-type: text/html\n\n";
	#Die for browser
	die_nice("Cannot run from browser.") if $ENV{'HTTP_USER_AGENT'};
	#Die if cron is already running
	if ($WIN) {
		eval{
			require Proc::PID_File;
			warn("Another process is running."),exit(0) if Proc::PID_File::hold_pid_file($system->setting('app').'/cron.pid');
		};
		if ($@) {
			die("Windows requires Proc::PID_File");			
		}			
	} else {
		eval {
			require Proc::PID::File;
			warn("Another process is running."),exit(0) if Proc::PID::File->running({dir => $system->setting('app'), name => 'cron'});
		};
		if ($@) {
			die("Linux requires Proc::PID::File");
		}
	}
	
	do "$global{app}/lang/$language/lang.inc";
 	require "include/func_invoices.cgi";
 	require "include/func_services.cgi"; 	
	require "include/cron_exec.cgi";
	$dbh->disconnect;
};
	
if ($@) {
	LOG_ERROR("$@");
	$dbh->disconnect;
	script_error("$@"); 
	email ( To => "$global{'controller_mail'}", From => "Cron - Controller", Subject => "Erro de Execução", Body => "$@");
	$system=undef;	
	exit;
}
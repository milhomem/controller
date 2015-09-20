#!/usr/bin/perl
use CGI qw(:standard);  
use DBI;
use Cwd;
#use open ':utf8', ':std';  

use lib getcwd;
use lib 'include/mods';
use Controller;

require "include/conf.cgi";

use vars qw[ $dbh $theme $language $dbname $dbhost $dbuser $dbpass %global $q %template $system]; 

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
		
#Modulos personalizados
push @INC, $system->setting('app').'/modules';			

&get_time();
	
$language = $global{'language'};
$theme = $global{'skin'};

###CHANGE THE OUTPUT####
local *STDOUT;
local *STDERR;
open(STDOUT, ">>".$system->setting('app')."/output");
open(STDERR, ">&STDOUT");
########################

sub Controller::DBConnector::_mysql {
	my ($self) = shift;
	
	my $DSN = qq|DBI:mysql:database=$self->{_inst};host=$self->{_host};mysql_connect_timeout=$self->{_timeout}|;
	$DSN .= qq|port=$self->{_port}| if $self->{_port};
    $self->{dbh} = DBI->connect($DSN, $self->{_user}, $self->{_pass}) ||
    				do { $self->{ERR}=$DBI::errstr; return undef;};
	$self->{dbh}->{HandleError} = sub { $self->Controller::DBConnector::MySQLerror(@_) };
	$self->{dbh}->{PrintError} = 0;
	$self->{dbh}->{RaiseError} = 0;
	$self->{dbh}->{mysql_auto_reconnect} = 1;
	$self->{dbh}->do("SET NAMES 'utf8';"); #READ IN UTF8
	
	return $self->{dbh};
}

require 'include/email_subs.cgi';

exit(0);
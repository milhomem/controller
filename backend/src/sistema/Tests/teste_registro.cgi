#!/usr/bin/perl

use CGI qw(:standard);                                 
use DBI();                                             
use Digest::MD5;

use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS

sub dir{ $root = $0; $root =~ s/(\\|\/)?teste_registro\.cgi//i;$root =~ s/\\/\//g;return $root;}

#use strict;
use lib dir;     
use lib dir.'include/mods';
use Mail::Sender;

use vars qw[ $dbh $datadir $language $action $bypass $dbname $dbhost $dbuser $dbpass $WIN $global %global $q %template $Cookie $sect]; 

require "include/conf.cgi"; 

eval {
	$dbh   =  DBI->connect("DBI:mysql:$dbname:$dbhost","$dbuser","$dbpass") || script_fatal("Erro ao conectar-se com o banco:<br>*$DBI::errstr");

	%global   =  get_vars();                                    
	$q        =  CGI->new();                         
	
	&get_time();
	
	#this will supply content-type and \n to end header
	print header(-type => "text/html",-charset => $global{'iso'});

	$RegistroBR::Epp::DEBUG = 1;
	my $xml = homologar() || die_nice($RegistroBR::Epp::ERR);
	print $xml;

	$dbh->disconnect;
}; 

if ($@) {                                               
	script_error("$@");
	exit;
}
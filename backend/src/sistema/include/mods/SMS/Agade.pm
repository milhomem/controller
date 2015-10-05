#!/usr/bin/perl
# agade.com.br - Agade.pm              
# Use: Module
# Controller - Is For Web - is4web.com.br
# 2007

package SMS::Agade;

require 5.004;
require Exporter;
#use strict;
use Socket;
use Carp;
#use CGI::Carp qw(fatalsToBrowser);

use vars qw(@ISA $VERSION);

#defaults
# Host: agade.com.br:8080
# File: /gatesms.cgi

sub new
{
   my ($host);
   my ($user);
   my ($pass);
   my ($from);
   my ($port);
   my ($error);
   my ($timeout) = 300;
   my $self = {};

   bless($self);

   return($self);
}

sub request {
	my($self,$request,$method,$formdata) = @_;
	$method ||= "GET";
	my(@PAGE);
	$self->{error} = '';
	my $timeout = $self->{timeout} || 300;
	$request .= "&login=" . $self->{user} . "&senha=" . $self->{pass} . "&remetente=" . $self->{from} if $method eq "GET";
	$formdata .= "&login=" . $self->{user} . "&senha=" . $self->{pass} . "&remetente=" . $self->{from} if $method eq "POST";

	eval {
		$SIG{'ALRM'} = sub {
			$self->{error} = 'Connection Timed Out';
			close(STDOUT);
			die "Timeout while attaching to SMS";
		};
		$SIG{'PIPE'} = sub {
			$self->{error} = 'Connection is broken (broken pipe)';
			close(STDOUT);
			die "Connection is broken (broken pipe)";
		};
		alarm($timeout);
	
		my $proto = getprotobyname('tcp');
		socket(SMS, AF_INET, SOCK_STREAM, $proto);
		my $iaddr = gethostbyname($self->{host}) || do {
			$self->{error} = "Unable to resolve $self->{host}";
			return();
		};
		my $sin = sockaddr_in($self->{port}, $iaddr);
		connect(SMS, $sin)  || do { 
			$self->{error} = "Unable to connect to $self->{host} port = '$self->{port}'";
			return();
		};	

		if ($method ne "POST") {
			send SMS, "GET ${request} HTTP/1.0\n", 0;
			#push @PAGE, "GET ${request} HTTP/1.0\n\n<BR>";
		} else {
			send SMS, "POST ${request} HTTP/1.0\n", 0;
			#push @PAGE, "POST ${request} HTTP/1.0\n\n<br>";
			send SMS, "Content-Type: application/x-www-form-urlencoded\n", 0;
			#push @PAGE, "Content-Type: application/x-www-form-urlencoded<br>";
		 	send SMS, "Content-Length: " . length($formdata) . "\n\n", 0; 
			send SMS, "$formdata\n\n", 0; 
			#push @PAGE, "Content-Length: " . length($formdata) . "\n\n<br>";
			#push @PAGE, "$formdata<br>";
		}
		
		send SMS, "Host: $self->{host}\n", 0;
		send SMS, "Connection: close\n\n", 0;
		#push @PAGE, "Host: $self->{host}\n\n<BR>Connection: close\n\n\n\n<br>";
 
		my $inheaders = 1;
		while(<SMS>) {
			s/[\r|\n]*//g;
			if (!$inheaders) {
				push(@PAGE,$_);
				if ($_ ne "") {
					alarm(0);
				} else {
					alarm($timeout);
				}					
			}
			if (/^$/ && $inheaders) { $inheaders = 0; }
		}
	
		alarm(0);
	};
 
	return (@PAGE);
}

sub send {
	my($self,$prefixo,$celular,$msg) = @_;
	my($response);

	my ($requrl) = "pais=${prefixo}&";
	#Verificar se o celular está entre as operadoras brasileiras
	if ($celular !~ m/[1-9]{2}[7-9]{1}[0-9]{7}/) {
		$self->{error} = "Numéro não confere: $celular";
		#Verificar se está entre as operadoras do plano Agade (Oi, Claro, Tim, Vivo, Amazonia, Telemig)
		#falta;
		#Ddds do Brail 11,12,13,14,15,16,17,18,19,21,22,24,27,28,31,32,33,34,35,37,38,41,42,43,44,45,46
		#47,48,49,51,53,54,55,61,62,63,64,65,66,67,68,69,71,73,74,75,77,79,81,82,83,84,85,86,87,88,89,91,92,93,94,95,96,97,98,99
		return ()
	}
	$requrl .= "mobile=${celular}&";
	$requrl .= "msg=${msg}&";
	$requrl .= "id=".time();

	my (@PAGE) = $self->request("/gatesms.cgi?".$requrl);

	if ($self->{error} ne "") { return(); }

	foreach $_ (@PAGE) {
		s/\n//g;
		$response .= $_ . "\n";
	}	
	
	return($response);
}

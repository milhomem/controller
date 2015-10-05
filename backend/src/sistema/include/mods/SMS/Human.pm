#!/usr/bin/perl
# human.com.br - Human.pm              
# Use: Module
# Controller - Is For Web - is4web.com.br
# 2007

package SMS::Human;

require 5.004;
require Exporter;
#use strict;
use Socket;
use Carp;
#use CGI::Carp qw(fatalsToBrowser);

use vars qw(@ISA $VERSION);

#defaults
# Host: system.human.com.br:8080
# File: /GatewayIntegration/msgSms.do 

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
	$request .= "&account=" . $self->{user} . "&code=" . $self->{pass} . "&from=" . $self->{from} if $method eq "GET";
	$formdata .= "&account=" . $self->{user} . "&code=" . $self->{pass} . "&from=" . $self->{from} if $method eq "POST";

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
	my $response; my @PAGE;

	my $tam = 141 - length($self->{from}); #maximo 142 caracteres
	while (length($msg) > 20) { #minimo 20 caracteres
		my ($requrl) = "to=${prefixo}";
		#Verificar se o celular está entre as operadoras brasileiras
		if ($celular !~ m/[1-9]{2}[7-9]{1}[0-9]{7}/) {
			$self->{error} = "Numéro não confere: $celular";
			#suporte a todas operadoras brasileiras
			return();
		}
		$requrl .= "${celular}&";
		$requrl .= "msg=".$self->url(substr($msg,0,$tam))."&";
		$requrl .= "dispatch=send&";
		$requrl .= "id=".time();
	
		(@PAGE) = $self->request("/GatewayIntegration/msgSms.do","POST",$requrl);

		$msg = substr($msg,$tam);
	}

	if ($self->{error} ne "") { return(); }

	foreach $_ (@PAGE) {
		s/\n//g;
		$response .= $_;
	}	

	$response = $self->error($response);

	return($response);
}


sub error {
	my($self,$errorcode) = @_;

	$errorcode =~ s/^\D*(\d{3}).+/$1/;

	my %errormsg;
	$errormsg{"000"} = "1,Mensagem enviada com sucesso";
	$errormsg{"010"} = "0,Mensagem vazia";
	$errormsg{"011"} = "0,Corpo da mensagem inválido";
	$errormsg{"012"} = "0,Corpo da mensagem excedeu o limite. Os campos 'from' e 'body' devem ter juntos no máximo 142 caracteres";
	$errormsg{"013"} = "0,Número do destinatário está incompleto ou inválido. O número deve conter o código do país e código de área além do número. Apenas dígitos são aceitos.";
	$errormsg{"014"} = "0,Número do destinatário está vazio";
	$errormsg{"015"} = "0,A data de agendamento está mal formatada. O formato correto deve ser: dd/MM/aaaa hh:mm:ss";
	$errormsg{"016"} = "0,ID informado ultrapassou o limite de 20 caracteres";
	$errormsg{"080"} = "0,Já foi enviada uma mensagem de sua conta com o mesmo identificador";
	$errormsg{"900"} = "0,Erro de autenticação em account e/ou code";
	$errormsg{"990"} = "0,Seu limite de segurança foi atingido. Contate nosso suporte para verificação/liberação";
	$errormsg{"999"} = "0,Erro desconhecido. Contate nosso suporte";
	
	return "$errormsg{$errorcode}";
}

sub url {
	my($self,$url) = @_;
	$url =~ s/([^\w\-\.\@])/sprintf("%%%2.2x",ord($1))/eg;
	return $url;
}
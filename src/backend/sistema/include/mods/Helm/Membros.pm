#!/usr/bin/perl
# Helm3 - Membros.pm              
#
# Mebros
# 2005
# Controller - Is4Web.com.br 
# 2008

package Helm::Membros;

use Socket;
use MIME::Base64 qw(encode_base64);

require 5.004;
require Exporter;
use strict;
use Carp;
#use CGI::Carp qw(fatalsToBrowser);

use vars qw(@ISA $VERSION);

@ISA = qw(Exporter);

sub new
{
   my ($host);
   my ($user);
   my ($usessl);
   my ($accesshash);
   my ($ns1);
   my ($ns2);
   my ($ip);
   my ($port);
   my ($error);
   my ($timeout) = 60;
   my  $self = {};

   bless ($self);

   return ($self);
}

sub helmreq {
	my($self,$request,$method,$formdata) = @_;
	$method ||= "GET";
	my(@PAGE);
	$self->{error} = '';
	my $timeout = $self->{timeout} || 600;
	my $cleanaccesshash = $self->{accesshash};
	$cleanaccesshash =~ s/[\r|\n]*//g;
	$request .= "&key=" . $cleanaccesshash . "&username=" . $self->{user} if $method eq "GET";
	$formdata .= "&key=" . $cleanaccesshash . "&username=" . $self->{user} if $method eq "POST";

	eval {
		local $SIG{'ALRM'} = sub {
			$self->{error} = 'Connection Timed Out';
			close(STDOUT);
			die "Timeout while attaching to HELM";
		};
		local $SIG{'PIPE'} = sub {
			$self->{error} = 'Connection is broken (broken pipe)';
			close(STDOUT);
			die "Connection is broken (broken pipe)";
		};
		alarm($timeout);
		if ($self->{usessl}) {
			eval { 
				require Net::SSLeay;
			};
			if ($@) {
				$self->{usessl} = 0;
			}     
		}

		if ($self->{usessl}) {
			my($page, $result, %headers);
			if ($method ne "POST") {
				($page, $result, %headers)
				= Net::SSLeay::get_https($self->{host}, $self->{port}, $request,
				Net::SSLeay::make_headers('Connection' => 'close'));
			} else {
				($page, $result, %headers)
				= Net::SSLeay::post_https($self->{host}, $self->{port}, $request,
				Net::SSLeay::make_headers('Connection' => 'close'),
				$formdata);
			}
			if (! defined($result) ) {
				$self->{error} = "Connection to $self->{host}:$self->{port} failed.";
				return();
			}
			if ($result !~ /OK/) {
				$self->{error} = $result;
				return();
			}
			@PAGE = split(/\n/, $page);
		} else {
			my $proto = getprotobyname('tcp');
			socket(HELM, AF_INET, SOCK_STREAM, $proto);
			my $iaddr = gethostbyname($self->{host}) || do {
				$self->{error} = "Unable to resolve $self->{host}";
				return();
			};
        
			my $sin = sockaddr_in($self->{port}, $iaddr);
			connect(HELM, $sin)  || do { 
				$self->{error} = "Unable to connect to $self->{host} port = '$self->{port}'";
				return();
			};	

			if ($method ne "POST") {
				send HELM, "GET ${request} HTTP/1.0\n", 0;
				#push @PAGE, "GET ${request} HTTP/1.0\n\n<BR>";
			} else {
				send HELM, "POST ${request} HTTP/1.0\n", 0;
				#push @PAGE, "POST ${request} HTTP/1.0\n\n<br>";
				send HELM, "Content-Type: application/x-www-form-urlencoded\n", 0;
				#push @PAGE, "Content-Type: application/x-www-form-urlencoded<br>";
			 	send HELM, "Content-Length: " . length($formdata) . "\n\n", 0; 
				send HELM, "$formdata\n\n", 0; 
				#push @PAGE, "Content-Length: " . length($formdata) . "\n\n<br>";
				#push @PAGE, "$formdata<br>";
			}

			send HELM, "Host: $self->{host}\n", 0;
			send HELM, "Connection: close\n\n", 0;
			#push @PAGE, "Host: $self->{host}\n\n<BR>Connection: close\n\n\n\n<br>";
	 
			my $inheaders = 1;
			while(<HELM>) {
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
			sleep 1;
		}	
		alarm(0);
	};
  
	return (@PAGE);
}

sub plansR {
   my($self) = @_;
   my(%PKGS);
   my(@PKGS);

   my (@PAGE) = $self->helmreq("/GatewayMembros.asp?caso=ListaPlanosRevenda");

   if ($self->{error} ne "") { return(); }

   foreach $_ (@PAGE) {
      s/\n//g;
      my($key,$value) = split(/=/, $_);
	  push(@PKGS,$key,$value);
   }
   
   %PKGS = (@PKGS);	
   return (%PKGS);
}	

sub plansH {
	my($self,$userhosp) = @_;
	my(%PKGS);
	my(@PKGS);

	my $url = "/GatewayMembros.asp";
	my $data = "caso=ListaPlanosHospedagem&UserHosp=".$self->url($userhosp)."";
	my (@PAGE) = $self->helmreq($url,"POST",$data);
 
	if ($self->{error} ne "") { return(); }

	foreach $_ (@PAGE) {
		s/\n//g;
		my($key,$value) = split(/=/, $_);
		push(@PKGS,$key,$value);
	}
   
	%PKGS = (@PKGS);
	return (%PKGS);
}	

sub creseller {
	my($self,$name,$email,$endereco,$CEP,$empresa,$cidade,$estado,$telefone,$pass,$plano,$dominio,$NS1,$NS2,$NS1IP,$NS2IP) = @_;

	my $url = "/GatewayMembros.asp";
	my $data = "caso=CriaRevenda&name=".$self->url($name)."&email=".$self->url($email)."&endereco=".$self->url($endereco)."&CEP=".$self->url($CEP)."&empresa=".$self->url($empresa)."&cidade=".$self->url($cidade)."&estado=".$self->url($estado)."&telefone=".$self->url($telefone)."&pass=".$self->url($pass)."&plano=".$self->url($plano)."&dominio=".$self->url(Controller::iso2puny($dominio))."&NS1=".$self->url($NS1)."&NS1IP=".$self->url($NS1IP)."&NS2=".$self->url($NS2)."&NS2IP=".$self->url($NS2IP)."";
	my (@PAGE) = $self->helmreq($url,"POST",$data);
  
	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub chospedagem {
	my($self,$name,$email,$endereco,$CEP,$empresa,$cidade,$estado,$telefone,$pass,$plano,$dominio,$NS1,$NS2,$userhosp,$planname,$NS1IP,$NS2IP) = @_;

	my $url = "/GatewayMembros.asp";
	my $data = "caso=CriaHospedagem&name=".$self->url($name)."&email=".$self->url($email)."&endereco=".$self->url($endereco)."&CEP=".$self->url($CEP)."&empresa=".$self->url($empresa)."&cidade=".$self->url($cidade)."&estado=".$self->url($estado)."&telefone=".$self->url($telefone)."&pass=".$self->url($pass)."&plano=".$self->url($plano)."&dominio=".$self->url(Controller::iso2puny($dominio))."&NS1=".$self->url($NS1)."&NS1IP=".$self->url($NS1IP)."&NS2=".$self->url($NS2)."&NS2IP=".$self->url($NS2IP)."&UserHosp=".$self->url($userhosp)."&PlanoNome=".$self->url($planname)."";
	my (@PAGE) = $self->helmreq($url,"POST",$data);

	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub suspend_h {
	my($self,$useracc,$dominio,$reseller) = @_;

	my $useracch = $reseller == 1 ? $self->url(Controller::iso2puny($dominio)) : $self->url($useracc); #Arriscando o usuário de hospedagem
	$dominio = $self->url(Controller::iso2puny($dominio));
	
	my (@PAGE) = $self->helmreq("/GatewayMembros.asp?caso=BloquearHospedagem&dominio=$dominio&Useracc=$useracch");
	if ($reseller) {#precisa? teve um caso do braweb que nao acertou o usuario de hospedagem e se a acao eh bloquear, abaixo já vai bloquear tudo! && grep {/Sucesso/} @PAGE){
		@PAGE = undef;		 
		push(@PAGE,$self->helmreq("/GatewayMembros.asp?caso=BloquearRevenda&dominio=$dominio&Useracc=$useracc")); 
	}

	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub unsuspend_h {
	my($self,$useracc,$dominio,$revenda) = @_;

	$useracc = $self->url($useracc);
	$dominio = $self->url(Controller::iso2puny($dominio));
	
	my (@PAGE) = $self->helmreq("/GatewayMembros.asp?caso=DesbloquearHospedagem&dominio=$dominio&Useracc=$useracc");
	if ($revenda && grep {/Sucesso/} @PAGE){
		@PAGE = undef;
		push(@PAGE,$self->helmreq("/GatewayMembros.asp?caso=DesbloquearRevenda&dominio=$dominio&Useracc=$useracc"));
	}
		
	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub removeacct {
	my (@PAGE);
	my($self,$useracc,$dominio,$reseller,$NS1,$NS2) = @_;

	$useracc = $self->url($useracc);
	$dominio = $self->url(Controller::iso2puny($dominio));
	$NS1 = $self->url($NS1);
	$NS2 = $self->url($NS2);
	
	if ($reseller){ 
		@PAGE = $self->helmreq("/GatewayMembros.asp?caso=RemoveRevenda&Useracc=$useracc&NS1=$NS1&NS2=$NS2"); 
	}else{
		@PAGE = $self->helmreq("/GatewayMembros.asp?caso=RemoveHospedagem&dominio=$dominio&Useracc=$useracc");

}

	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub updown_h {
	my (@PAGE);
	my($self,$useracc,$dominio,$plano,$nome) = @_;
	
	my $url = "/GatewayMembros.asp?caso=AlterarPlanoHospedagem&dominio=".$self->url(Controller::iso2puny($dominio))."&Useracc=".$self->url($useracc)."&plano=".$self->url($plano)."&PlanoNome=".$self->url($nome)."";
	@PAGE = $self->helmreq($url);

	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub updown_hres {
	my (@PAGE);
	my($self,$useracc,$plano,$nome) = @_;

	my $url = "/GatewayMembros.asp?caso=AlterarPlanoRevenda&Useracc=".$self->url($useracc)."&plano=".$self->url($plano)."&PlanoNome=".$self->url($nome)."";
	@PAGE = $self->helmreq($url);

	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub url {
	my($self,$url) = @_;
	#$url =~ s/([^\w\-\.\@])/sprintf("%%%2.2x",ord($1))/eg; #ASP não sabe traduzir de volta o valor
	$url =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
	return $url;
}
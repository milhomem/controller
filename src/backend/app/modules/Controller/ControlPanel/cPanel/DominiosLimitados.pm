#!/usr/bin/perl
# Use: Module
# Controller - is4web.com.br
# 2008
#Pacote personalizado para modificar o comportamento do módulo padrão do cPanel
package Controller::ControlPanel::cPanel::DominiosLimitados;

require 5.008;
require Exporter;
#use strict;
use Controller::ControlPanel::cPanel;

use vars qw(@ISA $VERSION $DEBUG $ERR $emailtxt);

@ISA = qw(Controller::ControlPanel::cPanel);

$VERSION = "0.1";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	#Depende do Controller
	my $self = new Controller::ControlPanel::cPanel( @_ );	
	%$self = (
		%$self,
		'ERR' => undef,
	);
	
	bless($self, $class);

	return $self;
}

sub email_txt { return $emailtxt; }

sub create_cpanel_acc {
	my $self = shift;
	die 'Não existe suporte para Hospedagem';
}

sub create_cpanel_res {
	my $self = shift;
	
	local *Controller::ControlPanel::cPanel::createres = \&createres;
	my @response = $self->Controller::ControlPanel::cPanel::createres();
	
    if ($self->error) { die("There was an error while processing your request: '".Controller::iso2puny($self->service('dominio'))."' ".$self->error."\n"); }
    
	my $plaintext = join("\n",@response);
	my %dados;
	foreach (@response){
		if ($_ =~ ": "){
			s/\s*(\w)/$1/;
			my ($campo,$valor)=split(/: /,$_);
			$dados{$campo} = $valor;
		}
	}	

	if ($plaintext !~ 'error.gif' && $plaintext !~ 'Sorry' && $plaintext ne '' && $dados{'UserName'}) {
		#Post create
		my ($auto) = $self->plan('auto');
		my ($user, $domain) = ($self->service('useracc'), $self->service('dominio')); 
		my ($host,$ip,$ns1,$ns2) = ($self->server('host'),$self->server('ip'),$self->server('ns1'),$self->server('ns2'));
		my (@PAGE2) = $self->SUPER::whmreq("/scripts/addres?remote=1&nohtml=1&res=${user}&cowner=1");
		my (@PAGE3) = $self->SUPER::whmreq("/scripts2/editressv?remote=1&nohtml=1&limits_number_of_accounts=1&resnumlimitamt=${auto}&res=${user}&acl-list-accts=1&acl-show-bandwidth=1&acl-create-acct=1&acl-suspend-acct=1&acl-kill-acct=1&acl-upgrade-account=1&acl-edit-mx=1&acl-frontpage=1&acl-mod-subdomains=1&acl-passwd=1&acl-res-cart=1&acl-create-dns=1&acl-edit-dns=1&acl-park-dns=1&acl-kill-dns=1&acl-add-pkg=1&acl-edit-pkg=1&acl-allow-unlimited-pkgs=1&acl-allow-addoncreate=1&acl-allow-parkedcreate=1&acl-onlyselfandglobalpkgs=1&acl-disallow-shell=1&acl-stats=1&acl-status=1&acl-mailcheck=1&acl-news=1&ns1=ns1.${domain}&ns2=ns2.${domain}&limits_resources=0&acl-allow-unlimited-bw-pkgs=1&acl-allow-unlimited-disk-pkgs=1&acl-allow-unlimited-bw-pkgs=1&acl-allow-unlimited-disk-pkgs=1");	
		my (@PAGE4) = $self->SUPER::whmreq("/cgi/zoneeditor.cgi?remote=1&nohtml=1&prog=savezone&zone=${domain}.db&line-1-1=\;\%20Modified\%20by\%20Web\%20Host\%20Manager&line-2-1=\;\%20Zone\%20File\%20for\%20${domain}&line-3-1=\$TTL%2014400&line-4-1=@&line-4-2=14440&line-4-3=IN&line-4-4=SOA&line-4-5=ns1.${host}.&line-4-6=suporte.${host}.&line-4-7=\(&line-4-8=1&line-4-9=14400&line-4-10=7200&line-4-11=3600000&line-4-12=86400&line-4-13=\)&line-5-1=&line-6-1=${domain}.&line-6-2=14400&line-6-3=IN&line-6-4=NS&line-6-5=ns1.${host}.&line-7-1=${domain}.&line-7-2=14400&line-7-3=IN&line-7-4=NS&line-7-5=ns2.${host}.&line-8-1=&line-9-1=${domain}.&line-9-2=14400&line-9-3=IN&line-9-4=A&line-9-5=${ip}&line-10-1=&line-11-1=localhost.${domain}.&line-11-2=14400&line-11-3=IN&line-11-4=A&line-11-5=127.0.0.1&line-12-1=&line-13-1=${domain}.&line-13-2=14400&line-13-3=IN&line-13-4=MX&line-13-5=0&line-13-6=${domain}.&line-14-1=&line-15-1=mail&line-15-2=14400&line-15-3=IN&line-15-4=CNAME&line-15-5=${domain}.&line-16-1=www&line-16-2=14400&line-16-3=IN&line-16-4=CNAME&line-16-5=${domain}.&line-17-1=ftp&line-17-2=14400&line-17-3=IN&line-17-4=CNAME&line-17-5=${domain}.&line-18-1=&line-19-1=ns1.${domain}.&line-19-2=14400&line-19-3=IN&line-19-4=A&line-19-5=${ns1}&line-20-1=&line-21-1=ns2.${domain}.&line-21-2=14400&line-21-3=IN&line-21-4=A&line-21-5=${ns2}&line-22-1=whm.${domain}.&line-22-2=14400&line-22-3=IN&line-22-4=A&line-22-5=${ip}&line-23-1=cpanel.${domain}.&line-23-2=14400&line-23-3=IN&line-23-4=A&line-23-5=${ip}&line-24-1=webmail.${domain}.&line-24-2=14400&line-24-3=IN&line-24-4=A&line-24-5=${ip}");
	
		$self->service('useracc',$dados{'UserName'});
		$self->create_service;
		return %dados;
	} else {
		$self->set_error($plaintext);
	}
	
	return ();
}

sub createres {
	my($self) = @_;
	my($response);
	my($user,@PAGE,$sb,$i,$t,@userinc,$userinc,$ok);
	my $domain = $self->service('dominio');

	my $plan = url('Plano Revenda'); #Temporariamente
	my ($auto) = $self->plan('auto'); 
	$userinc = $self->SUPER::defineuser();

	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$self->service('dados','Senha', $chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)]) if $self->service('dados','Senha') =~ m/\Q$userinc/;	
	my $pass = url($self->service('dados','Senha'));

	$i = 1;	$t = 0;
	until($ok eq 1) {
		if ($t<5){ 
			$user = substr($userinc,0,8-$t);
		} else { 
			$sb = length($i);
			$user = substr($userinc,0,8-$sb) . $i;
		}
		#RODA COM A VARIÁVEL $user
		@PAGE = $self->SUPER::whmreq("/scripts/wwwacct?remote=1&nohtml=1&username=${user}&password=${pass}&domain=${domain}&plan=${plan}");

		my ($err) = join("",@PAGE);

		if ($err =~ m/username \($user\) is\staken/i || $err =~ m/name $user already exists/i || $err =~ m/Sorry, a group for that username already exists/i || $err =~ m/Sorry, a passwd entry for that username already exists/i) {
			$t++ if $t<5;
			$i++ if $t>=5;
		} else {
			$ok = 1;
			$self->service('useracc',$user);
		}
	}
 
	if ($self->error) { return(); }

   return (@PAGE);	
}

sub updowngrade {
	my ($self) = @_;
	
	if ($self->plan('tipo') eq 'Revenda') {
		return $self->Controller::ControlPanel::cPanel::DominiosLimitados::updown_cpanel_res();
	} else {
		die 'Não existe suporte para Hospedagem';
	}	
}

sub updown_cpanel_res {
    my ($self,%cp_details) = @_;

	my @response = $self->Controller::ControlPanel::cPanel::DominiosLimitados::updown_res();

	my ($err) = join("",@response);
	my $user = $self->service('useracc');
	if ($err =~ m/Modified reseller .*\Q$user/i) {
		$self->grade_service;
		return 1;
	} else {
		$self->set_error($err);
	}
	return undef;
}

sub updown_res {
	my($self) = @_;
	my($response);

	my $user = url($self->service('useracc'));
	my ($auto) = url(split(" ",$self->plan('auto')));
	my $domain = url(Controller::iso2puny($self->service('dominio')));
	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $user;

	my $url = "/scripts2/editressv?remote=1&nohtml=1&limits_number_of_accounts=1&resnumlimitamt=${auto}&res=${user}&acl-list-accts=1&acl-show-bandwidth=1&acl-create-acct=1&acl-suspend-acct=1&acl-kill-acct=1&acl-upgrade-account=1&acl-edit-mx=1&acl-frontpage=1&acl-mod-subdomains=1&acl-passwd=1&acl-res-cart=1&acl-create-dns=1&acl-edit-dns=1&acl-park-dns=1&acl-kill-dns=1&acl-add-pkg=1&acl-edit-pkg=1&acl-allow-unlimited-pkgs=1&acl-allow-addoncreate=1&acl-allow-parkedcreate=1&acl-onlyselfandglobalpkgs=1&acl-disallow-shell=1&acl-stats=1&acl-status=1&acl-mailcheck=1&acl-news=1&ns1=ns1.${domain}&ns2=ns2.${domain}&limits_resources=0&acl-allow-unlimited-bw-pkgs=1&acl-allow-unlimited-disk-pkgs=1&acl-allow-unlimited-bw-pkgs=1&acl-allow-unlimited-disk-pkgs=1";
	my (@PAGE) = $self->Controller::ControlPanel::cPanel::whmreq($url);

	if ($self->error) { return(); }

	foreach $_ (@PAGE) {
		s/\n//g;
		$response .= $_ . "\n";
	}

	return($response);
}

sub url {
   return Controller::ControlPanel::cPanel::url(@_);
}

1;
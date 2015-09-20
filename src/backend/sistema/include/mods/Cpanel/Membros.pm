#!/usr/bin/perl
# WHM 10.8.0 - Membros.pm              
#
# Mebros
# 2006
# Controller - Is4Web.com.br 
# 2008
# Atualizado WHM 11.2.0

package Cpanel::Membros;

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
   my ($ip);
   my ($user);
   my ($usessl);
   my ($accesshash);
   my ($ns1);
   my ($ns2);
   my ($port);
   my ($error);
   my ($timeout) = 600;
   my $self = {};

   bless($self);

   return($self);
}	

sub addpkg {
   my($self,$name,$hasshell,$bwlimit,$quota,$ip,$cgi,$frontpage,$cpmod,$maxftp,$maxsql,$maxpop,$maxlst,$maxsub,$maxpark,$maxaddon) = @_;
   my($response);
   my ($requrl) = '/scripts/addpkg?';
   $requrl .= "name=".$self->url($name)."&";
   $requrl .= "ip=".$self->url($ip)."&";
   $requrl .= "cgi=".$self->url($cgi)."&";
   $requrl .= "frontpage=".$self->url($frontpage)."&";
   $requrl .= "cpmod=".$self->url($cpmod)."&";
   $requrl .= "maxftp=".$self->url($maxftp)."&";
   $requrl .= "maxsql=".$self->url($maxsql)."&";
   $requrl .= "maxpop=".$self->url($maxpop)."&";
   $requrl .= "maxlst=".$self->url($maxlst)."&";
   $requrl .= "maxsub=".$self->url($maxsub)."&";
   $requrl .= "maxpark=".$self->url($maxpark)."&";
   $requrl .= "maxaddon=".$self->url($maxaddon)."&";
   $requrl .= "hasshell=".$self->url($hasshell)."&";
   $requrl .= "bwlimit=".$self->url($bwlimit)."&";
   $requrl .= "quota=".$self->url($quota)."";
   $requrl .= "&nohtml=1";

   my (@PAGE) = $self->whmreq($requrl);

   if ($self->{error} ne "") { return(); }

   foreach $_ (@PAGE) {
	s/\n//g;
      $response .= $_ . "\n";
   }	
   return($response);
}

sub editpkg {
   my($self,$name,$hasshell,$bwlimit,$quota,$ip,$cgi,$frontpage,$cpmod,$maxftp,$maxsql,$maxpop,$maxlst,$maxsub,$maxpark,$maxaddon) = @_;
   my($response);
   my ($requrl) = '/scripts/addpkg?';
   $requrl .= "name=".$self->url($name)."&";
   $requrl .= "ip=".$self->url($ip)."&";
   $requrl .= "cgi=".$self->url($cgi)."&";
   $requrl .= "frontpage=".$self->url($frontpage)."&";
   $requrl .= "cpmod=".$self->url($cpmod)."&";
   $requrl .= "maxftp=".$self->url($maxftp)."&";
   $requrl .= "maxsql=".$self->url($maxsql)."&";
   $requrl .= "maxpop=".$self->url($maxpop)."&";
   $requrl .= "maxlst=".$self->url($maxlst)."&";
   $requrl .= "maxsub=".$self->url($maxsub)."&";
   $requrl .= "maxpark=".$self->url($maxpark)."&";
   $requrl .= "maxaddon=".$self->url($maxaddon)."&";
   $requrl .= "hasshell=".$self->url($hasshell)."&";
   $requrl .= "bwlimit=".$self->url($bwlimit)."&";
   $requrl .= "quota=".$self->url($quota)."";
   $requrl .= "&edit=yes&nohtml=1";

   my (@PAGE) = $self->whmreq($requrl);

   if ($self->{error} ne "") { return(); }

   foreach $_ (@PAGE) {
	s/\n//g;
      $response .= $_ . "\n";
   }	
   return($response);
}

sub suspend_c {
	my($self,$user,$reseller) = @_;

	$user = $self->url($user);
	do { $self->{error} = 'Nenhum usuário especificado, verifique o useracc do serviço'; return undef; } unless $user;
		
	my (@PAGE) = $self->whmreq("/scripts/remote_suspend?user=${user}&nohtml=1");
	if ($reseller){ 
		push(@PAGE,$self->whmreq("/scripts/suspendreseller?reseller=${user}&nohtml=1")); 
	}
   
	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub unsuspend_c {
	my($self,$user,$revenda) = @_;

	$user = $self->url($user);
	do { $self->{error} = 'Nenhum usuário especificado, verifique o useracc do serviço'; return undef; } unless $user;
		
	my (@PAGE) = $self->whmreq("/scripts/remote_unsuspend?user=${user}&nohtml=1");
	if ($revenda eq 1){ 
		push(@PAGE,$self->whmreq("/scripts/suspendreseller?reseller=${user}&un=1&nohtml=1"));
	}
		
	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub killacct {
	my($self,$user,$reseller) = @_;

	$user = $self->url($user);
	do { $self->{error} = 'Nenhum usuário especificado, verifique o useracc do serviço'; return undef; } unless $user;

	my (@PAGE) = $self->whmreq("/scripts/killacct?user=${user}&nohtml=1");
	if ($reseller){ 
		push(@PAGE,$self->whmreq("/scripts2/killreseller?reseller=${user}&verify=I%20understand%20this%20will%20irrevocably%20remove%20all%20the%20accounts%20owned%20by%20the%20reseller%20${user}&nohtml=1")); 
	}

	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub updown {
	my($self,$user,$auto) = @_;

	do { $self->{error} = 'Nenhum usuário especificado, verifique o useracc do serviço'; return undef; } unless $user;	
	my $url = "/scripts2/upacct?nohtml=1&user=".$self->url($user)."&pkg=".$self->url($auto).""; 
	my (@PAGE) = $self->whmreq($url);

	if ($self->{error} ne "") { return(); }

	return(@PAGE);
}

sub updown_res {
	my($self,$user,$disk,$bw,$domain) = @_;
	my($response);

	do { $self->{error} = 'Nenhum usuário especificado, verifique o useracc do serviço'; return undef; } unless $user;	
	my $url = "/scripts2/editressv?remote=1&nohtml=1&resreslimit=1&rslimit-disk=".$self->url($disk)."&rslimit-bw=".$self->url($bw)."&rsolimit-disk=1&rsolimit-bw=1&res=".$self->url($user)."&acl-list-accts=1&acl-show-bandwidth=1&acl-create-acct=1&acl-suspend-acct=1&acl-kill-acct=1&acl-upgrade-account=1&acl-edit-mx=1&acl-frontpage=1&acl-mod-subdomains=1&acl-passwd=1&acl-res-cart=1&acl-create-dns=1&acl-edit-dns=1&acl-park-dns=1&acl-kill-dns=1&acl-add-pkg=1&acl-edit-pkg=1&acl-allow-unlimited-pkgs=1&acl-allow-addoncreate=1&acl-allow-parkedcreate=1&acl-onlyselfandglobalpkgs=1&acl-disallow-shell=1&acl-stats=1&acl-status=1&acl-mailcheck=1&acl-news=1&ns1=ns1.".$self->url($domain)."&ns2=ns2.".$self->url($domain)."&limits_resources=1";
	my (@PAGE) = $self->whmreq($url);

	if ($self->{error} ne "") { return(); }

	foreach $_ (@PAGE) {
		s/\n//g;
		$response .= $_ . "\n";
	}	
	
	return($response);
}

sub version {
   my($self) = @_;
   return($self->showversion);
}

sub showversion {
   my($self,$user) = @_;
   my($response);
   my (@PAGE) = $self->whmreq("/scripts2/showversion");

   if ($self->{error} ne "") { return(); }

   foreach $_ (@PAGE) {
	s/\n//g;
       $response .= $_ . "\n";
   }	
   return($response);
}

sub showhostname {
   my($self,$user) = @_;
   my($response);
   my (@PAGE) = $self->whmreq("/scripts2/gethostname");

   if ($self->{error} ne "") { return(); }

   foreach $_ (@PAGE) {
	  s/\n//g;
      $response .= $_ . "\n";
   }	
   return($response);
}

sub defineuser {
	my ($self,$user) = @_;
	
    $user =~ s/[^a-zA-Z0-9]//g;
    $user = lc $user;
	$user =~ s/^test/tst/; 
	$user =~ s/^(\d+)//g;	
	$user =~ s/^virtfs$/virtf/;
	$user =~ s/^all$/allctrl/;
	$user =~ s/assword//g;
    $user = substr($user,0,8);
    	
	return $user;
}

sub createacct {
	my($self,$domain,$pass,$plan,$userhosp) = @_;
	my($response);
	my($user,@PAGE,$sb,$i,$t,@userinc,$userinc,$ok);
	$pass = $self->url($pass); 
	$plan = $self->url($plan); 
	$userinc = $self->defineuser($domain);
#	do { $self->{error} = 'Sorry, the password may not contain the username for security reasons'; return() } if $pass =~ m/$userinc/;
	
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$pass = $chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)] if $pass =~ m/$userinc/;	

	$i = 1;
	$t = 0;

	until($ok eq 1) {
		if ($t<5){ 
			$user = substr($userinc,0,8-$t);
		} else { 
			$sb = length($i);
			$user = substr($userinc,0,8-$sb) . $i;
		}
		#RODA COM A VARIÁVEL $user
		@PAGE = $self->whmreq("/scripts/wwwacct?remote=1&nohtml=1&username=".$self->url($user)."&password=".$self->url($pass)."&domain=".$self->url($domain)."&plan=".$self->url($plan));
		

		my ($err) = join("",@PAGE);

		if ($err =~ m/username \(\Q$user\E\) is\staken/i || $err =~ m/\Qname $user already exists/i || $err =~ m/Sorry, a group for that username already exists/i) {
			$t++ if $t<5;
			$i++ if $t>=5;
		} else {
			$ok = 1;
			my (@PAGE2) = $self->whmreq("/scripts/dochangeowner?user=${user}&owner=${userhosp}");
		}
	}

	if ($self->{error} ne "") { return(); }

	return (@PAGE);
}

sub createres {
	my($self,$domain,$pass,$plan,$disk,$bw,$dns1,$dns2) = @_;
	my($response);
	my($user,@PAGE,$sb,$i,$t,@userinc,$userinc,$ok);
	$user = $self->url($user); 
	$pass = $self->url($pass); 
	$plan = $self->url($plan); 
	$userinc = $self->defineuser($domain);
#	do { $self->{error} = 'Sorry, the password may not contain the username for security reasons'; return() }if $pass =~ m/$userinc/;

	my @chars=("A" .. "Z", "a" .. "z", 0 .. 9);
	$pass = $chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)] if $pass =~ m/$userinc/;	

	$i = 1;
	$t = 0;

	until($ok eq 1) {
		if ($t<5){ 
			$user = substr($userinc,0,8-$t);
		} else { 
			$sb = length($i);
			$user = substr($userinc,0,8-$sb) . $i;
		}
		#RODA COM A VARIÁVEL $user
		@PAGE = $self->whmreq("/scripts/wwwacct?remote=1&nohtml=1&username=".$self->url($user)."&password=".$self->url($pass)."&domain=".$self->url($domain)."&plan=".$self->url($plan));

		my ($err) = join("",@PAGE);

		if ($err =~ /username\s(.+)is\staken/) {
			$t++ if $t<5;
			$i++ if $t>=5;
		} else {
			$ok = 1;
			my (@PAGE2) = $self->whmreq("/scripts/addres?remote=1&nohtml=1&res=${user}&cowner=1");
			my (@PAGE3) = $self->whmreq("/scripts2/editressv?remote=1&nohtml=1&resreslimit=1&rslimit-disk=${disk}&rslimit-bw=${bw}&rsolimit-disk=1&rsolimit-bw=1&res=${user}&acl-list-accts=1&acl-show-bandwidth=1&acl-create-acct=1&acl-suspend-acct=1&acl-kill-acct=1&acl-upgrade-account=1&acl-edit-mx=1&acl-frontpage=1&acl-mod-subdomains=1&acl-passwd=1&acl-res-cart=1&acl-create-dns=1&acl-edit-dns=1&acl-park-dns=1&acl-kill-dns=1&acl-add-pkg=1&acl-edit-pkg=1&acl-allow-unlimited-pkgs=1&acl-allow-addoncreate=1&acl-allow-parkedcreate=1&acl-onlyselfandglobalpkgs=1&acl-disallow-shell=1&acl-stats=1&acl-status=1&acl-mailcheck=1&acl-news=1&ns1=ns1.${domain}&ns2=ns2.${domain}&limits_resources=1");
			my (@PAGE4) = $self->whmreq("/scripts2/savezone?remote=1&nohtml=1&zone=${domain}.db&line-0=\;\%20Modified\%20by\%20Web\%20Host\%20Manager&line-1=\;\%20Zone\%20File\%20for\%20${domain}&line-30=\$TTL%2014400&line-100-1=\@&line-100-2=14440&line-100-3=IN&line-100-4=SOA&line-100-5=ns1.$self->{host}.&line-100-6=suporte.$self->{host}.&line-100-7=\(&line-101-6=1&line-102-6=14400&line-103-6=7200&line-104-6=3600000&line-105-6=86400&line-106-6=\)&line-110=&line-120-1=${domain}.&line-120-2=14400&line-120-3=IN&line-120-4=NS&line-120-5=ns1.$self->{host}.&line-130-1=${domain}.&line-130-2=14400&line-130-3=IN&line-130-4=NS&line-130-5=ns2.$self->{host}.&line-140=&line-150-1=${domain}.&line-150-2=14400&line-150-3=IN&line-150-4=A&line-150-5=$self->{ip}&line-160=&line-170-1=localhost.${domain}.&line-170-2=14400&line-170-3=IN&line-170-4=A&line-170-5=127.0.0.1&line-180=&line-190-1=${domain}.&line-190-2=14400&line-190-3=IN&line-190-4=MX&line-190-5=0&line-190-6=${domain}.&line-200=&line-210-1=mail&line-210-2=14400&line-210-3=IN&line-210-4=CNAME&line-210-5=${domain}.&line-220-1=www&line-220-2=14400&line-220-3=IN&line-220-4=CNAME&line-220-5=${domain}.&line-230-1=ftp&line-230-2=14400&line-230-3=IN&line-230-4=CNAME&line-230-5=${domain}.&line-240=&line-250-1=ns1.${domain}.&line-250-2=14400&line-250-3=IN&line-250-4=A&line-250-5=$self->{ns1}&line-260=&line-270-1=ns2.${domain}.&line-270-2=14400&line-270-3=IN&line-270-4=A&line-270-5=$self->{ns2}");
		}
	}
 
   if ($self->{error} ne "") { return(); }

   return (@PAGE);
}

sub listpkgs {
   my($self) = @_;
   my(%PKGS);

   my (@PAGE) = $self->whmreq("/scripts/remote_listpkg?nohtml=1");

   if ($self->{error} ne "") { return(); }

   foreach $_ (@PAGE) {
      s/\n//g;
      my($pkg,$contents) = split(/=/, $_);
      my(@CONTENTS)=split(/,/,$contents);			
      $PKGS{$pkg} = @CONTENTS;
   }	
   return(%PKGS);
}	

sub listaccts {
   my($self) = @_;
   my(%ACCTS);

   my (@PAGE) = $self->whmreq("/scripts2/listaccts?nohtml=1&viewall=1");

   if ($self->{error} ne "") { return(); }

   foreach $_ (@PAGE) {
      s/\n//g;
      my($acct,$contents) = split(/=/, $_);
      my(@CONTENTS)=split(/\,/,$contents);			
      @{$ACCTS{$acct}} = @CONTENTS;
   }
	
   return(%ACCTS);
}

sub domainaccts {
   my($self) = @_;
   my(%ACCTS);

   my (@PAGE) = $self->whmreq("/scripts2/listaccts?nohtml=1&viewall=1");

   if ($self->{error} ne "") { return(); }

   foreach $_ (@PAGE) {
      s/\n//g;
      my($domain,$acct) = split(/=/, $_);
      $acct =~ s/\,.+?//;			
      ${ACCTS{$domain}} = $acct;
   }
	
   return(%ACCTS);
}	

sub whmreq {
	#Conteudo deve vir URLEncoded
	my($self,$request,$method,$formdata) = @_;
	$method ||= "GET";
	my(@PAGE);
	$self->{error} = '';
	my $timeout = $self->{timeout} || 300;
	my $cleanaccesshash = $self->{accesshash};
	$cleanaccesshash =~ s/[\r|\n]*//g;
	my $authstr =  encode_base64($self->{user} . ":" . $cleanaccesshash);

	eval {
		local $SIG{'ALRM'} = sub {
			$self->{error} = 'Connection Timed Out';
			close(STDOUT);
			die "Timeout while attaching to WHM";
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
				= Net::SSLeay::get_https($self->{ip}, $self->{port}, $request,
				Net::SSLeay::make_headers('Authorization' => 'WHM ' . $authstr,'Connection' => 'close'));
			} else {
				($page, $result, %headers) 
				= Net::SSLeay::post_https($self->{ip}, $self->{port}, $request,
				Net::SSLeay::make_headers('Authorization' => 'WHM ' . $authstr,'Connection' => 'close'),
				$formdata);
			}	 
			if (! defined($result) ) {
				$self->{error} = "Connection to $self->{ip}:$self->{port} failed.";
				return();
			}		
			if ($result !~ /OK/) {
				$self->{error} = $result;
				return();
			}		
			@PAGE = split(/\n/, $page);
		} else {
			my $proto = getprotobyname('tcp');
			socket(WHM, AF_INET, SOCK_STREAM, $proto);
			my $iaddr = gethostbyname($self->{ip}) || do {
				$self->{error} = "Unable to resolve $self->{ip}";
				return();
			};
			
			my $sin = sockaddr_in($self->{port}, $iaddr);
			connect(WHM, $sin)  || do { 
				$self->{error} = "Unable to connect to $self->{ip} port = '$self->{port}'";
				return();
			};
	
			if ($method ne "POST") {
				send WHM, "GET ${request} HTTP/1.0\n", 0;
				#push @PAGE, "GET ${request} HTTP/1.0\n";
			} else {
				send WHM, "POST ${request} HTTP/1.0\n", 0;
				#push @PAGE, "POST ${request} HTTP/1.0\n";
				send WHM, "Content-Type: application/x-www-form-urlencoded\n", 0;
				#push @PAGE, "Content-Type: application/x-www-form-urlencoded";
				send WHM, "Content-Length: " . length($formdata) . "\n\n", 0;
				send WHM, "$formdata\n\n", 0;
				#push @PAGE, "Content-Length: " . length($formdata) . "\n\n";
				#push @PAGE, "$formdata\n\n";
			}

			send WHM, "Authorization: Basic $authstr\n", 0;
			#push @PAGE, "Authorization: WHM $authstr\n";
			send WHM, "Host: $self->{host}\n", 0;
			send WHM, "Connection: close\n\n", 0;
			#push @PAGE, "Host: $self->{host}\nConnection: close\n\n";

			my $inheaders = 1;
			while(<WHM>) {
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

sub addtocluster {
   my($self,$user,$hostname,$accesshash) = @_;

   my $formdata = "user=".$self->url($user)."&clustermaster=".$self->url($hostname)."&pass=".$self->url($accesshash)."&recurse=0";

   my (@PAGE) = $self->whmreq("/cgi/trustclustermaster.cgi","POST",$formdata);
   my $page = join("\n", @PAGE);

   if ($self->{error} ne "") { return(); }

   if ($page =~ /has been established/i) {
	return(1);	
   } else {
	return();
   }
}	

sub getzone_local {
   my($self,$zone,$dnsuniqid) = @_;

   my $formdata = "zone=".$self->url($zone)."&dnsuniqid=".$self->url($dnsuniqid)."";

   my (@PAGE) = $self->whmreq("/scripts2/getzone_local","POST",$formdata);
   my $page = join("\n", @PAGE);

   if ($self->{error} ne "") { return(); }

   return($page);
}

sub getallzones_local {
   my($self,$dnsuniqid) = @_;

   my $formdata = "dnsuniqid=".$self->url($dnsuniqid)."";

   my (@PAGE) = $self->whmreq("/scripts2/getallzones_local","POST",$formdata);
   my $page = join("\n", @PAGE);

   if ($self->{error} ne "") { return(); }

	return($page);
}

sub cleandns_local {
	my ($self,$dnsuniqid) = @_;

	my $url = "/scripts2/cleandns_local?dnsuniqid=".$self->url($dnsuniqid)."";
	my (@PAGE) = $self->whmreq($url);
	my $page = join("\n", @PAGE);

	if ($self->{error} ne "") { return(); }  

	return($page); 
}

sub getips_local {
	my ($self,$dnsuniqid) = @_;

	my $url = "/scripts2/getips_local?dnsuniqid=".$self->url($dnsuniqid)."";
	my (@PAGE) = $self->whmreq($url);
	my $page = join("\n", @PAGE);

	if ($self->{error} ne "") { return(); }

	return($page);
}

sub getpath_local {
	my($self,$dnsuniqid) = @_;

	my $url = "/scripts2/getpath_local?dnsuniqid=".$self->url($dnsuniqid)."";
	my (@PAGE) = $self->whmreq($url);
	my $page = join("\n", @PAGE);

	if ($self->{error} ne "") { return(); }

	return($page);
}

sub removezone_local {
   my($self,$zone,$dnsuniqid) = @_;

   my $formdata = "zone=".$self->url($zone)."&dnsuniqid=".$self->url($dnsuniqid)."";

   my (@PAGE) = $self->whmreq("/scripts2/removezone_local","POST",$formdata);
   my $page = join("\n", @PAGE);

   if ($self->{error} ne "") { return(); }

   return($page);
}

sub reloadbind_local {
	my($self,$dnsuniqid,$zone) = @_;

	my $url = "/scripts2/reloadbind_local?dnsuniqid=".$self->url($dnsuniqid)."&zone=".$self->url($zone)."";
	my (@PAGE) = $self->whmreq($url);
	my $page = join("\n", @PAGE);

	if ($self->{error} ne "") { return(); }

	return($page);
}

sub reconfigbind_local {
	my($self,$dnsuniqid,$zone) = @_;

	my $url = "/scripts2/reconfigbind_local?dnsuniqid=".$self->url($dnsuniqid)."&zone=".$self->url($zone)."";
	my (@PAGE) = $self->whmreq($url);
	my $page = join("\n", @PAGE);

	if ($self->{error} ne "") { return(); }

	return($page);
}

sub savezone_local {
   my($self,$zone,$zonedata,$dnsuniqid) = @_;

   my $formdata = "zone=".$self->url($zone)."&zonedata=".$self->url($zonedata)."&dnsuniqid=".$self->url($dnsuniqid)."";

   my (@PAGE) = $self->whmreq("/scripts2/savezone_local","POST",$formdata);
   my $page = join("\n", @PAGE);

   if ($self->{error} ne "") { return(); }

   return($page);
}

sub synczones_local {
   my($self,$formdata,$dnsuniqid) = @_;

   #formdata must come pre encoded.
   $formdata =~ s/\&$//g;
   $formdata .= "&dnsuniqid=".$self->url($dnsuniqid)."";

   my (@PAGE) = $self->whmreq("/scripts2/synczones_local","POST",$formdata);
   my $page = join("\n", @PAGE);

   if ($self->{error} ne "") { return(); }

   return($page);
}

sub addzoneconf_local {
   my($self,$zone,$dnsuniqid) = @_;

   my $formdata = "zone=".$self->url($zone)."&dnsuniqid=".$self->url($dnsuniqid)."";

   my (@PAGE) = $self->whmreq("/scripts2/addzoneconf_local","POST",$formdata);
   my $page = join("\n", @PAGE);

   if ($self->{error} ne "") { return(); }

   return($page);
}

sub getzonelist_local {
	my($self,$dnsuniqid) = @_;

	my $url = "/scripts2/getzonelist_local?dnsuniqid=".$self->url($dnsuniqid)."";
	my (@PAGE) = $self->whmreq($url);

	if ($self->{error} ne "") { return(); }

	return(@PAGE);
}

sub zoneexists_local {
   my($self,$zone,$dnsuniqid) = @_;

   my $formdata = "zone=".$self->url($zone)."&dnsuniqid=".$self->url($dnsuniqid)."";

   my (@PAGE) = $self->whmreq("/scripts2/zoneexists_local","POST",$formdata);
   my $page = join("\n", @PAGE);

   if ($self->{error} ne "") { return(); }

   return($page);
}

sub url {
	my($self,$url) = @_;
	$url =~ s/([^\w\-\.\@])/sprintf("%%%2.2x",ord($1))/eg;
	return $url;
}
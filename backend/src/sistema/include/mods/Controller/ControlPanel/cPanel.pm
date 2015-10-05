#!/usr/bin/perl
# Use: Module
# Controller - is4web.com.br
# 2008
#
# Cpanel WHM 11.30.5
#
package Controller::ControlPanel::cPanel;

require 5.008;
require Exporter;

use Socket;
use MIME::Base64 qw(encode_base64);
use Controller::ControlPanel; 
use cPanel::PublicAPI;

use vars qw(@ISA $VERSION $DEBUG);

@ISA = qw(Controller::ControlPanel);
$VERSION = '0.1';

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    
	my $self = new Controller::ControlPanel( @_ );
	%$self = (
		%$self,
		'_timeout' => 180,
		'ERR' => undef,
		'cp' => undef,
	);

	bless($self, $class);
	
	$self->{'cp'} = cPanel::PublicAPI->new( 
									'user' => $self->server('username'), 
									'pass' => $self->server('key'),
									'ip' => $self->server('ip'),
									'ssl' => $self->server('ssl'),
									'timeout' => $self->{_timeout} || 300  ) if $self->server('key');
	return $self;
}

sub whmreq {
	#Conteudo deve vir URLEncoded
	my($self,$request,$method,$formdata) = @_;
	$method ||= "GET";
	my(@PAGE);
	return () if $self->error;

	my $timeout = $self->{_timeout} || 300;
	my $cleanaccesshash = $self->server('key');
	$cleanaccesshash =~ s/[\r|\n]*//g;
	my $authstr =  encode_base64($self->server('username') . ":" . $cleanaccesshash);

	eval {
		local $SIG{'ALRM'} = sub {
			$self->set_error('Connection Timed Out');
			close(STDOUT);
			die "Timeout while attaching to WHM";
		};  
		local $SIG{'PIPE'} = sub {
			$self->set_error('Connection is broken (broken pipe)');
			close(STDOUT);
			die "Connection is broken (broken pipe)";
		};
		alarm($timeout);
		if ($self->server('ssl')) {
			eval { 
				require Net::SSLeay;
		 	};
			if ($@) {
				$self->server('ssl',0);
			}     
		}
     
		if ($self->server('ssl')) {
			my($page, $result, %headers);
			if ($method ne "POST") {
				($page, $result, %headers) = Net::SSLeay::get_https(
														$self->server('ip'), 
														$self->server('port'), 
														$request,
														Net::SSLeay::make_headers('Authorization' => 'WHM ' . $authstr,'Connection' => 'close'));
			} else {
				($page, $result, %headers) = Net::SSLeay::post_https(
														$self->server('ip'), 
														$self->server('port'), 
														$request,
														Net::SSLeay::make_headers('Authorization' => 'WHM ' . $authstr,'Connection' => 'close'),
														$formdata);
			}
			if (! defined($result) ) {
				$self->set_error('Connection to '.$self->server('ip').':'.$self->server('port').' failed.');
				return();
			}		
			if ($result !~ /OK/) {
				$self->set_error($result);
				return();
			}		
			@PAGE = split(/\n/, $page);
		} else {
			my $proto = getprotobyname('tcp');
			socket(WHM, AF_INET, SOCK_STREAM, $proto);
			my $iaddr = gethostbyname($self->server('ip')) || do {
				$self->set_error('Unable to resolve '.$self->server('ip'));
				return();
			};
			
			my $sin = sockaddr_in($self->server('port'), $iaddr);
			connect(WHM, $sin)  || do { 
				$self->set_error('Unable to connect to '.$self->server('ip').' port = '.$self->server('port'));
				return();
			};
	
			if ($method ne "POST") {
				send WHM, "GET ${request} HTTP/1.0\n", 0;
			} else {
				send WHM, "POST ${request} HTTP/1.0\n", 0;
				send WHM, "Content-Type: application/x-www-form-urlencoded\n", 0;
				send WHM, "Content-Length: " . length($formdata) . "\n\n", 0;
				send WHM, "$formdata\n\n", 0;
			}

			send WHM, "Authorization: Basic $authstr\n", 0;
			send WHM, "Host: ".$self->server('host')."\n", 0;
			send WHM, "Connection: close\n\n", 0;

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
				} else { #Try to get invalid login error
					if (m=HTTP/1.1 401 Access Denied=) {
						$self->set_error('Login inválido. Verifique as configurações do servidor!');						
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

sub cpget_list {
	my $self = shift;
	%PKGS = $self->Controller::ControlPanel::cPanel::listpkgs();
	
	my $planos;
	foreach $package (sort keys %PKGS) {
		$planos .= qq|<option value=$package>$package</option>
		   							|;
	} 
	$self->template('planos',$planos);
}

sub listpkgs {
	my($self) = @_;
	my(%PKGS);

	my (@PAGE) = $self->Controller::ControlPanel::cPanel::whmreq("/scripts/remote_listpkg?nohtml=1");

   if ($self->error) { return(); }

	foreach (@PAGE) {
		s/\n//g;
		my($pkg,$contents) = split(/=/, $_);
		my(@CONTENTS)=split(/,/,$contents);			
		@{ $PKGS{$pkg} } = @CONTENTS;
	}	
	return(%PKGS);
}

sub suspend_cpanel {  
	my ($self,$reseller) = @_;

	my @response = $self->Controller::ControlPanel::cPanel::suspend_c($reseller);
	 
	if ($self->error) { die("There was an error while processing your request: '".$self->service('useracc')."' ".$self->error."\n"); }       
	
	return (@response);
}

sub suspend_c {
	my($self,$reseller) = @_;

	my $user = url($self->service('useracc'));
	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $user;
		
	my (@PAGE); 
	if ($reseller){ 
		(@PAGE) = $self->Controller::ControlPanel::cPanel::whmreq("/scripts/suspendreseller?resalso=1&reseller=${user}");
	} else {		
		(@PAGE) = $self->Controller::ControlPanel::cPanel::whmreq("/scripts/remote_suspend?user=${user}&nohtml=1");
	}
	
	if ($self->error) { return(); }

	return (@PAGE);
}

sub unsuspend_cpanel {
	my ($self,$revenda) = @_;

	my @response = $self->Controller::ControlPanel::cPanel::unsuspend_c($revenda);
	if ($self->error) { die("There was an error while processing your request: '".$self->service('useracc')."' ".$self->error."\n"); }       

	return (@response);
}

sub unsuspend_c {
	my($self,$revenda) = @_;

	my $user = url($self->service('useracc'));
	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $user;
		
	my (@PAGE) = $self->whmreq("/scripts/remote_unsuspend?user=${user}&nohtml=1");
	if ($revenda eq 1){ 
		push(@PAGE,$self->whmreq("/scripts/suspendreseller?reseller=${user}&un=1&nohtml=1"));
	}
	
	if (grep {m/fully suspended/si} @PAGE and grep {m/The user '${user}' is not suspended/si} @PAGE) {
		$self->Controller::ControlPanel::cPanel::suspend_c($revenda);		
		(@PAGE) = $self->Controller::ControlPanel::cPanel::unsuspend_c($revenda);
	}
	if ($self->error ne "") { return(); }

	return (@PAGE);
}

sub kill_cpanel {  
	my ($self,$reseller) = @_;

	my @response = $self->Controller::ControlPanel::cPanel::killacct($reseller);

    if ($self->error) { die("There was an error while processing your request: '".$self->service('useracc')."' ".$self->error."\n"); }      

	return (@response);
}

sub killacct {
	my($self,$reseller) = @_;

	my $user = url($self->service('useracc'));
	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $user;

	my (@PAGE); 
	if ($reseller){ 
		(@PAGE) = $self->Controller::ControlPanel::cPanel::whmreq("/scripts2/killreseller?reseller=${user}&verify=I%20understand%20this%20will%20irrevocably%20remove%20all%20the%20accounts%20owned%20by%20the%20reseller%20${user}&resalso=1&nohtml=1");
	} else { 
		(@PAGE) = $self->Controller::ControlPanel::cPanel::whmreq("/scripts/killacct?user=${user}&nohtml=1");
	}
	
	if ($self->error) { return(); }

	return (@PAGE);
}

sub updowngrade {
	return 0;
}

sub updown_cpanel {
    my ($self,%cp_details) = @_;
	my %PKGS = $self->Controller::ControlPanel::cPanel::listpkgs();
 
	my $planoid = $PKGS{$self->plan('auto')};
	die("Plano ".$self->plan('auto')." inexistente! Host: ".$self->server('host')) unless exists $PKGS{$self->plan('auto')};
    my @response = $self->Controller::ControlPanel::cPanel::updown();
    if ($self->error) { die("There was an error while processing your request: '".$self->service('useracc')."' ".$self->error."\n"); }  

	return (@response);     
}

sub updown {
	my($self) = @_;

	my $user = url($self->service('useracc'));
	$auto = url($self->plan('auto')); 
	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $user;	
	my $url = "/scripts2/upacct?nohtml=1&user=${user}&pkg=${auto}"; 
	my (@PAGE) = $self->Controller::ControlPanel::cPanel::($url);

	if ($self->error) { return(); }

	return(@PAGE);
}

sub updown_cpanel_res {
    my ($self,%cp_details) = @_;

	my @response = $self->Controller::ControlPanel::cPanel::updown_res();

	if ($self->error) { die("There was an error while processing your request: '".$self->service('useracc')."' ".$self->error."\n"); }
	
	return (@response);
}

sub updown_res {
	my($self) = @_;
	my($response);

	my $user = url($self->service('useracc'));
	my ($disk,$bw) = split(" ",$self->plan('auto'));
	my $domain = url(Controller::iso2puny($self->service('dominio')));
	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $user;
	
	my $url = "/scripts2/editressv?remote=1&nohtml=1&resreslimit=1&rslimit-disk=".url($disk)."&rslimit-bw=".url($bw)."&rsolimit-disk=1&rsolimit-bw=1&res=${user}&acl-list-accts=1&acl-show-bandwidth=1&acl-create-acct=1&acl-suspend-acct=1&acl-kill-acct=1&acl-upgrade-account=1&acl-edit-mx=1&acl-frontpage=1&acl-mod-subdomains=1&acl-passwd=1&acl-res-cart=1&acl-create-dns=1&acl-edit-dns=1&acl-park-dns=1&acl-kill-dns=1&acl-add-pkg=1&acl-edit-pkg=1&acl-allow-unlimited-pkgs=1&acl-allow-addoncreate=1&acl-allow-parkedcreate=1&acl-onlyselfandglobalpkgs=1&acl-disallow-shell=1&acl-stats=1&acl-status=1&acl-mailcheck=1&acl-news=1&ns1=ns1.${domain}&ns2=ns2.${domain}&limits_resources=1";
	my (@PAGE) = $self->Controller::ControlPanel::cPanel::whmreq($url);

	if ($self->error) { return(); }

	foreach $_ (@PAGE) {
		s/\n//g;
		$response .= $_ . "\n";
	}	
	
	return($response);
}

sub create_cpanel_acc {
    my ($self,%cp_details) = @_;
	my %PKGS = $self->Controller::ControlPanel::cPanel::listpkgs();
 
 	$self->set_error('Não foi possível consultar os pacotes!') unless keys %PKGS;
	$self->set_error("Plano ".$self->plan('auto')." inexistente! Host: ".$self->server('host')) unless exists $PKGS{$self->plan('auto')};
	return () if ($self->error);
	my @response = $self->Controller::ControlPanel::cPanel::createacct();
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
		$self->service('useracc',$dados{'UserName'});
		$self->create_service;
		return %dados;
	} else {
		$self->set_error($plaintext);
	}
	
	return ();
}

sub createacct {
	my($self) = @_;
	my($response);
	my($user,@PAGE,$sb,$i,$t,@userinc,$userinc,$ok);
	
	my $plan = url($self->plan('auto'));
	$userinc = $self->Controller::ControlPanel::cPanel::defineuser();
	my $domain = url(Controller::iso2puny($self->service('dominio')));
	my $email = url(${$self->user('email')}[0]) if $self->user('email');
	
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$self->service('dados','Senha', $chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)]) if $self->service('dados','Senha') =~ m/\Q$userinc/;	
	my $pass = url($self->service('dados','Senha'));

	my $i = 1; my $t = 0;
	until($ok == 1) {
		if ($t<5){ 
			$user = substr($userinc,0,8-$t);
		} else { 
			$sb = length($i);
			$user = substr($userinc,0,8-$sb) . $i;
		}		
		
		@PAGE = $self->Controller::ControlPanel::cPanel::whmreq("/scripts/wwwacct?remote=1&nohtml=1&username=${user}&password=${pass}&domain=${domain}&plan=${plan}&contactemail=${email}");

		my ($err) = join("",@PAGE);
		if ($err =~ m/username \(\Q$user\E\) is\staken/i || $err =~ m/\Qname $user already exists/i || $err =~ m/Sorry, a group for that username already exists/i || $err =~ m/Sorry, a passwd entry for that username already exists/i) {
			$t++ if $t<5;
			$i++ if $t>=5;
		} else {
			my $response = $self->{'cp'}->whm_api('modifyacct', {'user' => $user, 'owner' => $self->setting('user_host_lin') } );
			if($response->{'result'}[0]{'status'} == 1 && $response->{'result'}[0]{'statusmsg'} eq 'Account Modified' && $response->{'result'}[0]{'newcfg'}{'cpuser'}{'OWNER'} eq $self->setting('user_host_lin')) {
				$ok = 1;
				$self->service('useracc',$user);				
			} else {						
				$self->clear_error; 
				$self->killacct;
				use Data::Dumper;								 				
				die 'Erro ao alterar o owner!'.'Creating: '.$err.' Debug:'.(Dumper \$response); 
			}
		}
	}
	
	if ($self->error) { return(); }

	return (@PAGE);
}

sub create_cpanel_res {
	my($self) = @_;
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
		my $user = url($self->service('useracc'));
		my ($disk,$bw) = split(" ",$self->plan('auto'));
		my $domain = url(Controller::iso2puny($self->service('dominio')));
		my ($host,$ip,$ns1,$ns2) = ($self->server('host'),$self->server('ip'),$self->server('ns1'),$self->server('ns2'));
		my (@PAGE2) = $self->whmreq("/scripts/addres?remote=1&nohtml=1&res=${user}&cowner=1");
		my (@PAGE3) = $self->whmreq("/scripts2/editressv?remote=1&nohtml=1&resreslimit=1&rslimit-disk=${disk}&rslimit-bw=${bw}&rsolimit-disk=1&rsolimit-bw=1&res=${user}&acl-list-accts=1&acl-show-bandwidth=1&acl-create-acct=1&acl-suspend-acct=1&acl-kill-acct=1&acl-upgrade-account=1&acl-edit-mx=1&acl-frontpage=1&acl-mod-subdomains=1&acl-passwd=1&acl-res-cart=1&acl-create-dns=1&acl-edit-dns=1&acl-park-dns=1&acl-kill-dns=1&acl-add-pkg=1&acl-edit-pkg=1&acl-allow-unlimited-pkgs=1&acl-allow-addoncreate=1&acl-allow-parkedcreate=1&acl-onlyselfandglobalpkgs=1&acl-disallow-shell=1&acl-stats=1&acl-status=1&acl-mailcheck=1&acl-news=1&ns1=ns1.${domain}&ns2=ns2.${domain}&limits_resources=1");
		my (@PAGE4) = $self->whmreq("/cgi/zoneeditor.cgi?remote=1&nohtml=1&prog=savezone&zone=${domain}.db&line-1-1=\;\%20Modified\%20by\%20Web\%20Host\%20Manager&line-2-1=\;\%20Zone\%20File\%20for\%20${domain}&line-3-1=\$TTL%2014400&line-4-1=@&line-4-2=14440&line-4-3=IN&line-4-4=SOA&line-4-5=ns1.${host}.&line-4-6=suporte.${host}.&line-4-7=\(&line-4-8=1&line-4-9=14400&line-4-10=7200&line-4-11=3600000&line-4-12=86400&line-4-13=\)&line-5-1=&line-6-1=${domain}.&line-6-2=14400&line-6-3=IN&line-6-4=NS&line-6-5=ns1.${host}.&line-7-1=${domain}.&line-7-2=14400&line-7-3=IN&line-7-4=NS&line-7-5=ns2.${host}.&line-8-1=&line-9-1=${domain}.&line-9-2=14400&line-9-3=IN&line-9-4=A&line-9-5=${ip}&line-10-1=&line-11-1=localhost.${domain}.&line-11-2=14400&line-11-3=IN&line-11-4=A&line-11-5=127.0.0.1&line-12-1=&line-13-1=${domain}.&line-13-2=14400&line-13-3=IN&line-13-4=MX&line-13-5=0&line-13-6=${domain}.&line-14-1=&line-15-1=mail&line-15-2=14400&line-15-3=IN&line-15-4=CNAME&line-15-5=${domain}.&line-16-1=www&line-16-2=14400&line-16-3=IN&line-16-4=CNAME&line-16-5=${domain}.&line-17-1=ftp&line-17-2=14400&line-17-3=IN&line-17-4=CNAME&line-17-5=${domain}.&line-18-1=&line-19-1=ns1.${domain}.&line-19-2=14400&line-19-3=IN&line-19-4=A&line-19-5=${ns1}&line-20-1=&line-21-1=ns2.${domain}.&line-21-2=14400&line-21-3=IN&line-21-4=A&line-21-5=${ns2}&line-22-1=whm.${domain}.&line-22-2=14400&line-22-3=IN&line-22-4=A&line-22-5=${ip}&line-23-1=cpanel.${domain}.&line-23-2=14400&line-23-3=IN&line-23-4=A&line-23-5=${ip}&line-24-1=webmail.${domain}.&line-24-2=14400&line-24-3=IN&line-24-4=A&line-24-5=${ip}");
	
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
	my $domain = url(Controller::iso2puny($self->service('dominio')));

	my $plan = url('Plano Revenda');
	$userinc = $self->Controller::ControlPanel::cPanel::defineuser();
	my $email = url(${$self->user('email')}[0]) if $self->user('email');

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
		
		@PAGE = $self->whmreq("/scripts/wwwacct?remote=1&nohtml=1&username=${user}&password=${pass}&domain=${domain}&plan=${plan}&contactemail=${email}");

		my ($err) = join("",@PAGE);

		if ($err =~ m/username \(\Q$user\E\) is\staken/i || $err =~ m/\Qname $user already exists/i || $err =~ m/Sorry, a group for that username already exists/i || $err =~ m/Sorry, a passwd entry for that username already exists/i) {
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

sub cp_modifyip {
    my ($self) = shift; 

	my @response = $self->Controller::ControlPanel::cPanel::dochangeip(@_);

	if ($self->error) { die("There was an error while processing your request: '".Controller::iso2puny($self->service('dominio'))."' ".$self->error."\n"); }
	
	my $plaintext = join("\n",@response);	
	if ($plaintext =~ "Account modified. New ip is: $_[1].") {
		return 1;
	} else {
		$self->set_error($plaintext);
	}
	
	return 0;
}

sub dochangeip {
	my($self,$ipold,$ipnew) = @_;
	my($response);
	
	my $user = url($self->service('useracc'));
	@PAGE = $self->Controller::ControlPanel::cPanel::whmreq("/scripts2/dochangeip?nohtml=1&oldip=${ipold}&user=${user}&customip=${ipnew}");
	
	if ($self->error) { return(); }

	return (@PAGE);
}

sub cp_park {
    my ($self) = shift; 

	my @response = $self->Controller::ControlPanel::cPanel::parkdomain(@_);

	if ($self->error) { $self->set_error("There was an error while processing your request: '".$_[0]."' ".$self->error."\n"); }
	
	my $plaintext = join("\n",@response);	
	my $dom = Controller::iso2puny($self->service('dominio'));
	if ($plaintext =~ "successfully parked on top of $dom") {
		return 1;
	} else {
		$self->set_error($plaintext);
	}
	
	return 0;
}

sub parkdomain {
	my($self) = shift;
	my($response);
	
	my $user = url($self->service('useracc'));
	@PAGE = $self->Controller::ControlPanel::cPanel::whmreq("/scripts/park?nohtml=1&domain=".Controller::iso2puny($self->service('dominio'))."&ndomain=$_[0]");
	
	if ($self->error) { return(); }

	return (@PAGE);
}

sub cp_addzone {
    my ($self) = shift; 

	my @response = $self->Controller::ControlPanel::cPanel::addzone(@_);

	if ($self->error) { die("There was an error while processing your request: '".$_[1]."' ".$self->error."\n"); }
	
	my $plaintext = join("\n",@response);	
	if ($plaintext =~ "Zone created successfully for IP $_[0]") {
		return 1;
	} else {
		$self->set_error($plaintext);
	}
	
	return 0;
}

sub addzone {
	my($self) = shift;
	my($response);
	
	@PAGE = $self->Controller::ControlPanel::cPanel::whmreq("/scripts/adddns?nohtml=1&ip=$_[0]&zone=".Controller::iso2puny($_[1]));
	
	if ($self->error) { return(); }

	return (@PAGE);
}

sub cp_delzone {
    my ($self) = shift; 

	my @response = $self->Controller::ControlPanel::cPanel::delzone(@_);

	if ($self->error) { die("There was an error while processing your request: '".$_[0]."' ".$self->error."\n"); }
	
	my $plaintext = join("\n",@response);	
	if ($plaintext =~ "Zones Removed: $_[0]") {
		return 1;
	} else {
		$self->set_error($plaintext);
	}
	
	return 0;
}

sub delzone {
	my($self) = shift;
	my($response);
	
	@PAGE = $self->Controller::ControlPanel::cPanel::whmreq("/scripts/killdns?nohtml=1&killdns=".Controller::iso2puny($_[0]));
	
	if ($self->error) { return(); }

	return (@PAGE);
}

sub defineuser {
	my ($self) = @_;
	
    $user = lc Controller::iso2puny($self->service('dominio'));
    $user =~ s/[^a-zA-Z0-9]//g;
	$user =~ s/^test/tst/; 
	$user =~ s/^(\d+)//g;	
	$user =~ s/^virtfs$/virtf/;
	$user =~ s/^all$/allctrl/;
	$user =~ s/assword//g;
    $user = substr($user,0,8);
    	
	return $user;
}

sub url {
   my $theURL = Controller::trim(shift);
   $theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;
   return $theURL;
}

sub teste {
	return shift->Controller::ControlPanel::cPanel::defineuser();
}
1;
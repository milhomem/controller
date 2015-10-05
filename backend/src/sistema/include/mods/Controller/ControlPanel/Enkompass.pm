#!/usr/bin/perl
# Use: Module
# Controller - is4web.com.br
# 2011
package Controller::ControlPanel::Enkompass;

require 5.008;
require Exporter;

use Controller::Services;
use Controller::XML;
use LWP::UserAgent;

use vars qw(@ISA $VERSION $DEBUG $SOAP_URI $SCHEMA_URI $SCHEMAXDS_URI $NAMESPACE $LANG $emailtxt);

@ISA = qw(Controller::Services Controller::XML Exporter);
$VERSION = '0.1';
$SOAP_URI = 'http://schemas.xmlsoap.org/soap/envelope/';
$SCHEMA_URI	= 'http://www.w3.org/2001/XMLSchema-instance';
$SCHEMAXDS_URI = 'http://www.w3.org/2001/XMLSchema';
$NAMESPACE = 'http://tempuri.org/';
$DEBUG = 0;

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    
	my $self = new Controller::Services( @_ );
	%$self = (
		%$self,
		'_page' => 1,
		'ERR' => undef,
	);

	bless($self, $class);

	return $self;
}

sub email_txt { return $emailtxt; }

sub result {
	my $self = shift;
	
	return $self->{_enkom}{$_[0]};
}

#====== API ======#
sub baseurl_api {
	my ($self) = shift;
	return $self->{_enkom}{$self->srvid}{baseurl_api} if $self->{_enkom}{$self->srvid}{baseurl_api};
	
	my $protocol = $self->server('ssl') ? 'https' : 'http';
	my $port = $self->server('port'); 
	$self->{_enkom}{$self->srvid}{baseurl_api} = sprintf('%s://%s:%d',$protocol,$self->server('ip'),$port) . '/API/xml-api/xml-api.asmx/';
	
	return $self->{_enkom}{$self->srvid}{baseurl_api};
}

sub version {
	my ($self) = shift;
	return if $self->error;
		
	$self->command('version', { 'api.version' => 1 });
	
	#Process Response
	my %result = $self->process_response('version');

	return ($result{reason});
}

sub command {
	my ($self) = shift;
	return if $self->error;
	
	my $query = $self->Hash2Query($_[1]);

	my $userAgent = LWP::UserAgent->new(timeout => 4*60);
	my $request = HTTP::Request->new('GET' => $self->baseurl_api . "$_[0]?" . $query );
	my $response = $userAgent->request($request);	
	my $cleanaccesshash = $self->server('key');
	$cleanaccesshash =~ s/[\r|\n]*//g;
	my $auth = 'WHM '.$self->server('username'). ':' . $cleanaccesshash;
	$request->header( Authorization => $auth );	
	my $response = $userAgent->request($request);

	warn $request->as_string if $DEBUG;
	if($response->code == 200) {
		if ($response->content !~ m/^<\?xml/i) {
			$self->set_error($self->lang(251,"Command $_[0]",$response->content));
		}
		if (length($response->content) == 40) { #XML vazio
			$self->{_lastresponse} = 1; #Sucesso vazio
		} else {
			$self->{_lastresponse} = $self->get_return_value($response->content);
		}
	} elsif ($response->code == 500 && $response->content =~ m/^<\?xml/i) {
		my $response = $self->get_return_value($response->content);
		my $result = $self->xml2perl($response->toString(0),0,0);		
		$self->set_error($self->lang(251,"Command $_[0]",$result->{'soap:Body'}{'soap:Fault'}{'faultstring'}));
	} else {
		$self->set_error($self->lang(251,"Command $_[0]",$response->error_as_HTML));
	}
	
	return $self->error ? 0 : 1;
}

sub response { $_[0]->{_lastresponse}; }

sub process_response {
	my ($self) = shift;
	return if $self->error; 
		
	my $response = $self->response;

	my %result = %{$self->xml2perl(($response->getElementsByTagName("metadata"))[0]->toString(0),0,0)} unless $self->error;
    if ($result{'result'} == 1) { #Sucesso
		return wantarray ? %result : $result{'reason'};
    } else { 
		warn "$_[0] failed: ".$response->toString(1) if $DEBUG;
		$self->set_error( defined $result{'statuscode'} ? $self->lang(251,"Process_response $_[0]",$result{'reason'}) : $response->toString(1));
		return undef;
	}	
}

sub process_response_v0 {
	my ($self) = shift;
	return if $self->error;
		
	my $response = $self->response;
	my %result = %{$self->xml2perl(($response->getElementsByTagName($_[0]))[0]->toString(0),0,1)} unless $self->error;
	%result = %{$result{'result'}[0]} if exists $result{'result'};
    if ($result{'status'}[0] == 1) { #Sucesso
		return wantarray ? %result : $result{'statusmsg'}[0];
    } else { 
		warn "$_[0] failed: ".$response->toString(1) if $DEBUG;
		$self->set_error( defined $result{'statuscode'}[0] ? $self->lang(251,"Process_response $_[0]",$result{'statusmsg'}[0]) : $response->toString(1));
		return wantarray ? %result : undef;
	}	
}

sub quicksearch {#verifica se já existe
	my ($self) = shift;
	return if $self->error;

	my $quest = $_[0] eq 'DOMAINS' ? $self->service('dominio') : $self->service('useracc');
	my $type = $_[0] eq 'DOMAINS' ? 'PrimaryDomain' : 'AccountName';
	$self->command('listaccts', { 
		'api.version' => 0,
		'all' => 1,
		'searchtype' => $type,
		'search' => $quest,
	});
	
	my %result = $self->process_response_v0('listaccts');
	
	my $matches = scalar @{$result{'accts'}};
	$self->set_error($self->lang(203,$quest)) unless $matches == 0 || exists $_[1]; #Procurando inversamente se nao tiver 1
	$self->set_error($self->lang(9,'quicksearch')) unless $quest;
	
	return $self->error ? 0 : $matches;
}

sub chooseuser {
	my ($self) = shift;
	return if $self->error;
	
	my $user = $self->service('dominio');
    $user =~ s/[^a-zA-Z0-9]//g;
    $user = lc $user;
	$user =~ s/^test/tst/; 
	$user =~ s/^(\d+)//g;	
	$user =~ s/^virtfs$/virtf/;
	$user =~ s/^all$/allctrl/;
	$user =~ s/assword//g;
    $user = substr($user,0,8);
    $self->service('useracc',$user);

    my $i;
	while ($self->quicksearch(undef,1)) {
		$user = substr($user,0,8-length($i++)) . $i;
		$self->service('useracc',$user);
		$self->set_error($self->lang(250,'chooseuser')) and return if length($i) > 7;
	}
	$self->set_error($self->lang(9,'chooseuser')) unless $user;
	
	return $self->error ? 0 : 1;
}

sub list_customers {
	my ($self) = shift;
	return if $self->error;

	$self->{_enkom}{$self->srvid}{customers} = undef unless $_[0];
	$self->command('listaccts', { 
		'api.version' => 0,
		'all' => 1,
		'searchtype' => 'AccountName',
		'search' => '*',				 
	});
			
	my %result = $self->process_response_v0('listaccts');
	unless ($self->error) {
   		$self->{_enkom}{$self->srvid}{customers}{$_->{'user'}[0]} = 1 foreach ( @{ $result{'accts'} } );
	}
		
	return $self->error ? 0 : 1;
}

sub get_mysqlserver {
	my ($self) = shift;
	return if $self->error;

	$self->command('getdatbaseservers', { 
		'api.version' => 0,
	});
	
	#Process Response
	my %result = $self->process_response_v0('getdatbaseservers');
	
	foreach my $serv ( @{ $result{'servers'}[0]{'server'} }) {
		next unless $serv->{'name'}[0] eq 'mysql';
		return $serv->{'id'} if $serv->{'type'}[0] eq 'MySql';
	} 	
		
	return $self->error ? 0 : 1;			
}

sub get_mailserver {
	my ($self) = shift;
	return if $self->error; 

	$self->command('getmailservers', { 
		'api.version' => 0,
	});
	
	my %result = $self->process_response_v0('getmailservers');
	
	foreach my $serv (@{ $result{'servers'}[0]{'server'} }) {
		next unless $serv->{'name'}[0] eq 'SmarterMail';
		return $serv->{'id'} if $serv->{'type'}[0] eq 'SmarterMail';
	} 		
	return $self->error ? 0 : 1;			
}

sub create_domain {
	@_=@_;
	my ($self) = shift;
	return if $self->error; 
	
	my $basedomain = lc Controller::iso2puny($self->service('dominio'));  
	
	use Data::Dumper; 
	
	my (%result, $retry);
	do {
		$self->command('createacct', { 
			'api.version' => 0,
			'contactemail' => $self->user('emails'),
			'customip' => '0.0.0.0',
			'domain' => $self->service('dominio'),
			'password' => $self->service('dados','Senha'),
			'username' => $self->service('useracc'),
			'server-mysql-id' => $self->get_mysqlserver,
			'server-mail-id' => $self->get_mailserver,
			'featurelist' => $_[2],
			'owner' => $_[0],
			'plan' => $_[1],
			'reseller' => $_[3] || 0,
		});
		
		%result = $self->process_response_v0('createacct');
		if ($result{'statuscode'}[0] == 108 || $result{'statuscode'}[0] == 127) { #Senha inválida #108 é falha ao criar a conta
			$self->service('dados','Senha',$self->randthis(2,("a" .. "z")).$self->randthis(2,("A" .. "Z")).$self->randthis(3,(0 .. 9)).'!');
			$self->clear_error;
			die Dumper \%result if ++$retry > 1; #2x
		}		
	} while ($result{'statuscode'}[0] == 108 || $result{'statuscode'}[0] == 127); #Senha inválida
	
	my %dados = (
				'UserName' => $self->service('useracc'),
				'PassWord' => $self->service('dados','Senha'),
				'FtpUser' => "$basedomain|".$self->service('useracc'),
	);
	$self->{_enkom} = \%dados;
	
	return $self->error ? 0 : 1;	
}

sub reseller_limits {
	my ($self) = shift;
	return if $self->error;
		
	$self->command('setresellerlimits', { 
		'api.version' => 0,
		
		'enable_account_limit' => $_[0] > 0,
		'account_limit' => $_[0],
		
		'enable_resource_limits' => $_[1] > 0 || $_[2] > 0,
		'bandwidth_limit' => $_[1],
		'diskspace_limit' => $_[2],
		
		'enable_overselling_bandwidth' => $_[3],
		'enable_overselling_diskspace' => $_[4],		
		'enable_overselling' => $_[3] > 0 || $_[4] > 0,		
		#'enable_package_limits' => 0,
		#'enable_package_limit_numbers' => 0,
		'user' => $self->service('useracc'),
	});
	
	$self->process_response_v0('setresellerlimits');	
	
	return $self->error ? 0 : 1;	
}

sub reseller_acl { #Reseller Role
	my ($self) = shift;
	return if $self->error; 

	$self->command('setacls', { 
		'api.version' => 0,
		
		'acllist' => $_[0],
		'reseller' => $self->service('useracc'),
	});
	
	$self->process_response_v0('setacls');	
	
	return $self->error ? 0 : 1;	
}

sub chosting {
	my ($self) = shift;
	our $emailtxt = '_ek';
		
	$self->quicksearch('DOMAINS');
	$self->chooseuser;
	$self->{_undo}{domain} = $self->create_domain($self->setting('user_host_lin'),$self->plan('auto'),'Hospedagem',0);
	$self->undo;
	$self->create_service;
		
	return $self->error ? 0 : 1;
}

sub creseller {
	my $self = shift;
	our $emailtxt = '_ek';

	my $plan = 'Revenda';
	$self->quicksearch('DOMAINS');
	$self->chooseuser;
	$self->{_undo}{domain} = $self->create_domain(undef,$plan,'ALLWSO',1);
	my ($disk,$bw) = split(" ",$self->plan('auto'));
	$self->reseller_limits(0,$bw,$disk,1,1);
	$self->reseller_acl('Revendedor');
	$self->undo;
	$self->create_service;
	
	return $self->error ? 0 : 1;
}

sub undo {
	my ($self) = shift;
	return unless $self->error;
	
	my $err = $self->clear_error;
	$self->remove_domain if $self->{_undo}{domain} == 1;
	#$self->remove_customer if $self->{_undo}{customer} == 1;
	#$self->remove_nameserver if $self->{_undo}{nameserver} == 1;
	
	$self->set_error($err) and $self->{_undo} = undef;
	return 1;
}

sub remove_domain {
	return 1; #TODO Implement
}

sub suspend {
	my $self = shift;
	
	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $self->service('useracc');	

	
	$self->set_error($self->lang(202,'quicksearch')) if $self->quicksearch(undef,1) > 1;
	my $include = $_[0] ? 1 : 0;

	$self->command('suspendacct', { 
		'api.version' => 0,		
		'all' => $include,
		'reason' => 'Suspended by Controller', 
		'user' => $self->service('useracc'),
	});		
	
	my %result = $self->process_response_v0('suspendacct');
	
	if ($result{'statuscode'}[0] == 101) { #already suspended
		$self->clear_error;
	}
	
	$self->suspend_service($include == 0 && $self->plan('tipo') eq 'Revenda');
	
	return $self->error ? 0 : 1;
}

sub unsuspend {
	my $self = shift;

	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $self->service('useracc');
	
	$self->set_error($self->lang(202,'quicksearch')) if $self->quicksearch(undef,1) > 1;

	$self->command('unsuspendacct', { 
		'api.version' => 0,		
		'all' => 1, 
		'user' => $self->service('useracc'),
	});		
	
	my %result = $self->process_response_v0('unsuspendacct');
	
	if ($result{'statuscode'}[0] == 101) { #already suspended
		$self->clear_error;
	}
		
	$self->activate_service;
	
	return $self->error ? 0 : 1;
}

sub rhosting {
	my $self = shift;

	do { $self->set_error('Nenhum usuário especificado, verifique o useracc do serviço'); return undef; } unless $self->service('useracc');
	
	$self->set_error($self->lang(202,'quicksearch')) if $self->quicksearch(undef,1) > 1;

	$self->command('removeacct', { 
		'api.version' => 0,		
		'keepdns' => 0,
		'reassign-sub-accounts' => 0, 
		'user' => $self->service('useracc'),
	});		
	
	$self->process_response_v0('removeacct');
	
	$self->remove_service;
	
	return $self->error ? 0 : 1;
}

sub rreseller {
	my $self = shift;
	
	return $self->rhosting;
}

sub updowngrade {
	my $self = shift;
	#TODO
	return 0;
}
1;
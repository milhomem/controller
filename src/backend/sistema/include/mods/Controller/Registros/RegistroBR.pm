#!/usr/bin/perl
# Use: Module
# Controller - is4web.com.br
# 2008 - 2013
package Controller::Registros::RegistroBR;

require 5.008;
require Exporter;

use Net::EPP::Client;
use Controller::Registros;
use Controller::Registros::RegistroBR::Epp;

use vars qw(@ISA $VERSION $DEBUG $ERR $ERR2 $dir);

@ISA = qw(Controller::Registros Controller::Registros::RegistroBR::Epp);

#TODO A lista de erros pode ser encontrada no documento "Política e restrições do serviço EPP no Registro.BR" [1].
#[1] http://registro.br/provedor/epp/pt-policy-restrictions-espec.html#anchor30

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    
	my $self = new Controller::Registros( @_ );
	%$self = (
		%$self,
		'_registrobr' => undef,
		'modulo' => undef,
		'timeout' => 60,
		'ERR' => undef,
		'disponivel' => undef,
		'_nameservers' => undef,
	);

	bless($self, $class);

	return $self;
}

sub requirements {
	my $self = shift;
		
	my $ext = Controller::Registros::TLD($self->service('dominio'),'');

	#.BR exige documentacao e cnpj
	if ($ext =~ m/^(?:ARG|AM|ART|B|COOP|EDU|ESP|FAR|FM|G12|GOV|IMB|IND|INF|JUS|LEG|MIL|ORG|PSI|RADIO|REC|SRV|TMP|TUR|TV|ETC)\.BR$/i) { #Pessoas jurídicas
		$self->service('_registrobr_orgid', $self->service('dados','registrobr_cnpj') || $self->user('cnpj'));
		$self->service('_registrobr_orgname', $self->service('dados','registrobr_org') || $self->user('empresa'));
	} elsif ($ext =~ m/^(?:COM|NET|EMP|ECO)\.BR$/i) { #Pessoas jurídicas ou físicas
		$self->service('_registrobr_orgid', $self->service('dados','registrobr_cnpj') || $self->service('dados','registrobr_cpf') || $self->user('cnpj') || $self->user('cpf'));
		if ($self->service('dados','registrobr_cnpj') || $self->service('dados','registrobr_cpf')) {
			$self->service('_registrobr_orgname', $self->service('dados','registrobr_org') || $self->service('dados','registrobr_name'));
		} else {
			$self->service('_registrobr_orgname', $self->user('cnpj') ?  $self->user('empresa') : $self->user('name'));
		}
	} elsif ($ext =~ m/^(?:ADM|ADV|ARQ|ATO|BIO|BMD|CIM|CNG|CNT|ECN|ENG|ETI|FND|FOT|FST|GGF|JOR|LEL|MAT|MED|MUS|NOT|NTR|ODO|PPG|PRO|PSC|QSL|SLG|TAXI|TEO|TRD|VET|ZLG|BLOG|FLOG|NOM|VLOG|WIKI)\.BR$/i) { #Pessoas físicas
		$self->service('_registrobr_orgid', $self->service('dados','registrobr_cpf') || $self->user('cpf'));
		$self->service('_registrobr_orgname', $self->service('dados','registrobr_name') || $self->user('name'));
	} else {
		#Error
		$self->set_error($self->lang(801,$self->service('dominio')));
	}
	$self->set_error($self->lang(818)) unless $self->service('_registrobr_orgid');	
	return 1;	
}

sub registrar {
	my ($self) = @_;
	return if $self->error;

	my $result = availdomain($self);
	if ($result == 1) { #Não existe, remove o ticket
		if (my $ticket = $self->service('dados','Ticket')) {
			$self->service('dados','Ticket', undef);
			$result = availdomain($self);
			$self->service('dados','Ticket', $ticket);
		} 
	}
	
	if ($result == 0) { #Existe
		if ($self->service('dados','Ticket')) {
			if ($self->service('dados','MsgPoll') == 1) {#Registro pendente criado com sucesso
				return _registrar($self);
			} else {
				$self->set_error($self->lang(816));
				return undef;
			}		
		} else {
			$self->set_error($self->lang(810, $self->service('dominio')));
			return undef;
		}
	}

	my $cidbr = addcontact($self) unless availcontact($self)->{'avail'} == 0;
	$self->service('dados','CIDBR', $cidbr) if $cidbr;
	$self->Controller::Services::save if $cidbr;
	if (availcontact($self)->{'avail'} == 1) {
		$self->set_error($self->lang(817, $self->clear_error));
		return undef;
	}
	
	$self->requirements;
	return if $self->error;
	unless (availorg($self)->{'avail'} == 0) {
		unless (addorg($self)) {
			$self->set_error($self->lang(815, Controller::frmtCPFCNPJ($self->service('_registrobr_orgid'))));
			return undef;
		}	
	}
	
	my $adddomain = adddomain($self);
	return undef unless ref $adddomain eq 'HASH';

	if ($adddomain->{'pending'}) {
		$self->service('dados','Ticket',$adddomain->{'ticket'});
		#send message to cron lock
		$self->logcron($self->lang(816,$adddomain->{'pending'}));
	}

	$self->Controller::Services::save;
	
	return undef if $adddomain->{'pending'};
	return _registrar($self);
}

sub _registrar {
	my ($self) = shift;

	unless ($self->error) {
		$self->log(
			'cmd' => "REGISTRO",
			'table' => 'registrar',
			'value' => $self->service('dominio'),
			'byuser' => $self->{cookname},
			'debug' => Controller::tostring({ nameserver_list => [$self->nameservers],
							'org' => $self->service('_registrobr_orgid'),
							'contact_add' => $self->service('dados','CIDBR'),
							'ticket' => $self->service('dados','Ticket'),
						}) );
		
		return 1;
	}
	return undef;
}

sub renew {
	my ($self) = @_;
	return if $self->error;
	
	my $result = domain_renew($self);
	return undef unless ref $result eq 'HASH';

	_renovar($self,$result->{'expiration'});
	return $self->datefromISO8601($result->{'expiration'}) unless $self->error;  
}

sub _renovar {
	my ($self) = shift;

	unless ($self->error) {
		$self->log(
			'cmd' => "REGISTRO",
			'table' => 'renovar',
			'value' => $self->service('dominio'),
			'byuser' => $self->{cookname},
			'debug' => Controller::tostring({ 
							'exp' => $_[0],
						}) );
		
		return 1;
	}
	return undef;
}

sub _domain {
	my ($self) = shift; 
	my $fakedomain = shift;
	
	$self->sid(9999999999999) if $fakedomain && !$self->sid;
	$self->service('dominio',$fakedomain) if $fakedomain && $self->sid;
	
	my $domain = $self->service('dominio');
	$domain =~ s/^www\.//g;
	my $dlen = length substr($domain, 0, index($domain,'.')); 
	if ($domain =~ m/\.(?:COM|NET|EMP|ECO|ARG|AM|ART|B|COOP|EDU|ESP|FAR|FM|G12|GOV|IMB|IND|INF|JUS|LEG|MIL|ORG|PSI|RADIO|REC|SRV|TMP|TUR|TV|ETC|ADM|ADV|ARQ|ATO|BIO|BMD|CIM|CNG|CNT|ECN|ENG|ETI|FND|FOT|FST|GGF|JOR|LEL|MAT|MED|MUS|NOT|NTR|ODO|PPG|PRO|PSC|QSL|SLG|TAXI|TEO|TRD|VET|ZLG|BLOG|FLOG|NOM|VLOG|WIKI)\.br$/i &&
		$domain !~ m/[^0-9A-ZÀÁÂÃÉÊÍÓÔÕÚÜÇ-]+(\.|$)/gi && ($dlen >= 2 && $dlen <= 26) &&
		$domain =~ tr/\.// < 4
		) {
		$self->service('dominio',$domain); 
	} else {
		$self->set_error($self->lang(802,$self->service('dominio')));
	}
	
	return $self->error ? 0 : 1;
}

sub connection {
	my ($self) = shift;
	return 0 if $self->error;

	conecta($self) unless $self->{_registrobr}{handle};

	$self->set_error($self->lang(813)) , #TODO add lang
	die	unless $self->{_registrobr}{handle};
	
	return $self->{_registrobr}{handle};
}

sub conecta {
	my ($self) = @_;
	return 0 if $self->error;

	$self->{_registrobr}{handle} = Net::EPP::Client->new(
				host    => $self->setting('registrobr_host'),
				port    => $self->setting('registrobr_port'), 
				ssl     => 1,
				dom  => 1,
				);

    if (my $greeting = $self->{_registrobr}{handle}->connect(
					SSL_version => 'tlsv1',
					SSL_use_cert => 1,
					SSL_verify_mode => 0x00,
					SSL_cert_file => $self->setting('app').'/certs/registrobr.pem',
					SSL_key_file => $self->setting('app').'/certs/registrobr.pem',
					SSL_passwd_cb => sub { return $self->setting('registrobr_certpass') },
					)) { 
		#check greeting
		warn "Connected to $self->{_registrobr}{handle}{host}:$self->{_registrobr}{handle}{port}\n Response: ".$greeting->toString(1)."\n" if $DEBUG;
	} else {
		warn "Could not connect\nError: &IO::Socket::SSL::errstr\n" if $DEBUG;
		$self->set_error(&IO::Socket::SSL::errstr); 	
	}
	
	login($self);

	return $self->error ? 0 : 1;
}

sub login {
	my ($self) = shift;
	return undef if $self->error;
	
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Login);
	my $response = response($self);

	#check sucessfull
	my $result = ($response->getElementsByTagName('result'))[0];
	if ($result->getAttribute('code') == 1000) {
		warn "Login success\n".$response->toString(1) if $DEBUG;
		warn "===command:$self->{'ERR2'}====<br>====response:".$response->toString(1)."======<br>" if $DEBUG == 3;
		return 1;
	} else { 
		warn "Login failed: ".$response->toString(1) if $DEBUG;
		$self->set_error('login: '.$result->textContent("msg"));
		return 0;
	}
}

sub hello {
	my ($self) = shift;
	return undef if $self->error;
	
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Hello);
	my $response = response($self);
	
	return $response->toString(1);
}

*availdomain = \&domain_check; #alias
sub domain_check {
	my ($self) = shift;
	return domain_info($self) == 0 ? 1 : 0; #Disponivel, verdadeiro
}

*adddomain = \&domain_create; #alias
sub domain_create {
	my ($self) = shift;
	#Necessário que os nameservers tenham autoridade sobre o dominio
	my $rex = '^.+\.'.$self->service('dominio').'$';
	my @ns = map { $_->{'name'} =~ m/$rex/i ? ($_->{'ipv6'} || $_->{'ipv4'}) : $_->{'name'} } $self->nameservers;

	#Cron Workaround
	if (!$self->DNS_authority(@ns) && $self->setting('registro_ns1') && $self->setting('registro_ns2') && $self->setting('registro_ns1') ne $self->setting('registro_ns2')) {
$self->email (To => $self->setting('controller_mail'), From => $self->setting('adminemail'), Subject => 'Erro de autoridade DNS', Body => sprintf("Dominio: %s <br>Ns: %s, %s <br>Erro: %s",$self->service('dominio'),$ns[0],$ns[1],$self->clear_error() ) );		
		@ns = ($self->setting('registro_ns1'),$self->setting('registro_ns2'));
		$self->nameservers([{ 'name' => $self->setting('registro_ns1') },{ 'name' => $self->setting('registro_ns2') }]);  	
	}
	$self->set_error($self->lang(819,join(',',@ns),$self->service('dominio'))) unless $self->DNS_authority(@ns);
		
	return undef if $self->error;	
	
	$self->requirements;
	return if $self->error;
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Domain_Create);

	my %response = %{ $self->xml2perl(response($self)->toString(0)) };
	#check successful
    if ($response{'response'}[0]{'result'}[0]{'code'} == 1000) {
		my $ticket = $response{'response'}[0]{'extension'}[0]{'brdomain:creData'}[0]{'brdomain:ticketNumber'}[0]{'content'};
		return {'ticket' => $ticket};
    } elsif ($response{'response'}[0]{'result'}[0]{'code'} == 1001) {
		my $ticket = $response{'response'}[0]{'extension'}[0]{'brdomain:creData'}[0]{'brdomain:ticketNumber'}[0]{'content'};
		my $pending = $response{'response'}[0]{'extension'}[0]{'brdomain:creData'}[0]{'brdomain:pending'}[0];

		my @reason;
		push @reason, $response{'response'}[0]{'result'}[0]{'msg'}[0]{'content'};
		foreach (keys %$pending) {
			my ($root, $ext) = split(':', $_);
			if ($ext eq 'doc') {
				my @docs = ref( $pending->{$_} ) eq 'ARRAY' ? @{ $pending->{$_} } : ($pending->{$_});
				foreach my $doc (@docs) {
					push @reason, $self->lang('docType', $doc->{'brdomain:docType'}[0]{'content'});
					push @reason, $self->lang('reason', $doc->{'brdomain:description'}[0]{'content'});
					push @reason, $self->lang('limitexp', $doc->{'brdomain:limit'}[0]{'content'});
				}
			} elsif ($ext eq 'dns') {
				my @dnss = ref( $pending->{$_} ) eq 'ARRAY' ? @{ $pending->{$_} } : ($pending->{$_});
				foreach my $dns (@dnss) {
					push @reason, $self->lang('dnsBR', $dns->{'brdomain:hostName'}[0]{'content'}, $dns->{'status'});
					push @reason, $self->lang('limitexp', $dns->{'brdomain:limit'}[0]{'content'});
				}
			}
		}
		
		return {'ticket' => $ticket, 'pending' => join ', ', @reason};    		
    } else { 
		$self->set_error( $response{'response'}[0]{'result'}[0]{'msg'}[0]{'content'} . ': ' .$response{'response'}[0]{'result'}[0]{'extValue'}[0]{'reason'}[0]{'content'} );
		return undef;
	}
}

sub domain_info {
	my ($self) = shift;
	return undef if $self->error;
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Domain_Info);
		
	my %response = %{ $self->xml2perl(response($self)->toString(0)) };
	#check sucessfull
    if ($response{'response'}[0]{'result'}[0]{'code'} == 1000) {
		my %resp = %{ $response{'response'}[0]{'resData'}[0]{'domain:infData'}[0] };
		my %ext = %{ $response{'response'}[0]{'extension'}[0]{'brdomain:infData'}[0] };
		my (%contacts,$nameservers,$i);
		my @cts = ref( $resp{'domain:contact'} ) eq 'ARRAY' ? @{ $resp{'domain:contact'} } : ($resp{'domain:contact'});
		$contacts{ $_->{'type'} } = $_->{'content'} foreach @cts;
		my @nss = ref( $resp{'domain:ns'}[0]{'domain:hostAttr'} ) eq 'ARRAY' ? @{ $resp{'domain:ns'}[0]{'domain:hostAttr'} } : ($resp{'domain:ns'}[0]{'domain:hostAttr'});
		foreach (@nss) {
			$nameservers{'ns'.++$i}{'host'} = $_->{'domain:hostName'}[0]{'content'};
			my @ips = ref( $_->{'domain:hostAddr'} ) eq 'ARRAY' ? @{ $_->{'domain:hostAddr'} } : ($_->{'domain:hostAddr'}); 
			foreach my $ip (@ips) {
				$nameservers{'ns'.$i}{'ip'}{$ip->{'ip'}} = $ip->{'content'} if $ip->{'content'};
			}
		}

		return {
				'domain' => $resp{'domain:name'}[0]{'content'},
				'admin' => $contacts{'admin'},
				'billing' => $contacts{'billing'},
				'tech' => $contacts{'tech'},
				'status' => $resp{'domain:status'}[0]{'s'},
				'created' => $resp{'domain:crDate'}[0]{'content'},
				'lastupdate' =>  $resp{'domain:upDate'}[0]{'content'},
				'expiration' => $resp{'domain:exDate'}[0]{'content'},
				'nameserver_list' => { %nameservers },
				%contacts,
				'ticket' => $ext{'brdomain:ticketNumber'}[0]{'content'},
				'org' => $ext{'brdomain:organization'}[0]{'content'},
#				'autorenew' => $ext{'brdomain:autoRenew'},
#				'publication' => $ext{'brdomain:publicationStatus'}{'publicationFlag'},				
		};
    } elsif ($response{'response'}[0]{'result'}[0]{'code'} == 2303) {
    	return 0; #Não existe
    } else { 
		$self->set_error( $response{'response'}[0]{'result'}[0]{'msg'}[0]{'content'} );
		return undef;
	}
}

sub whois {
	my ($self) = @_;
	return if $self->error;
	
	my ($response) = $self->domain_info();

	use Data::Dumper;
	return Dumper \$response;
}

sub domain_update {
	my ($self) = shift;
	return undef if $self->error;
	
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Domain_Update);
	my $response = response($self);		
	
	#check sucessfull
	my $result = ($response->getElementsByTagName("result"))[0] if $response;
    if ($result && $result->getAttribute('code') == 1000) {
		my $msg;
		unless (defined $result) {
			$self->set_error($response->toString(1));			
		} else {
			$msg = ($result->getChildrenByTagName('msg'))[0]->textContent;
		}

		return {'response' => $msg};
    } else { 
    	my $node = ($result->getChildrenByTagName('extValue'))[0] if $response;
    	if ($node) {
    		my $node2 = ($node->getChildrenByTagName('reason'))[0] if $node;
    		$self->set_error( $node->textContent ) if $node2;
    	} else {
			$self->set_error( ($result->getChildrenByTagName('msg'))[0]->textContent ) if $result;
    	}
		return undef;
	}
}

sub domain_renew {
	my ($self) = shift;
	return undef if $self->error;

	$self->service('dados','Ticket', undef);
	my $preresult = $self->domain_info;
	my ($expTime) = $preresult->{'expiration'} =~ m/T(.+?)Z/;
				
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Domain_Renew($expTime));
	my $response = response($self);		
	
	#check successful
	my $result = ($response->getElementsByTagName("result"))[0];
    if ($result->getAttribute('code') == 1000) {
    	my $result = ($response->getElementsByTagName('resData'))[0];
		$result = ($result->getChildrenByTagName('domain:renData'))[0];
		$result = ($result->getChildrenByTagName('domain:exDate'))[0];
		my $exp = $result->textContent;
		$result = ($response->getElementsByTagName('extension'))[0];
		$result = ($result->getChildrenByTagName('brdomain:renData'))[0];
		$result = ($result->getChildrenByTagName('brdomain:publicationStatus'))[0];
		my $msg = $result->getAttribute('publicationFlag');

		return {'response' => $msg, 'expiration' => $exp};
    } else { 
    	my $node = ($result->getChildrenByTagName('extValue'))[0];
    	if ($node) {
    		my $node2 = ($node->getChildrenByTagName('reason'))[0];
    		$self->set_error( $node->textContent ) if $node2;
    	} else {
			$self->set_error( ($result->getChildrenByTagName('msg'))[0]->textContent );
    	}
		return undef;
	}
}

sub domain_delete {
	my ($self) = shift;
	return undef if $self->error;
	
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Domain_Delete);		
	
	#check sucessfull
	my %response = %{ $self->xml2perl(response($self)->toString(0)) }; 
	if ($response{'response'}[0]{'result'}[0]{'code'} == 1000) {
		#deleted
		return $response{'response'}[0]{'result'}[0]{'msg'}[0]{'content'};
	} else { 
		$self->set_error($response{'response'}[0]{'result'}[0]{'msg'}[0]{'content'});
		return undef;
	}
}

sub nameservers {
	my ($self) = shift;
	
	$self->{_nameservers} = $_[0] if ref $_[0] eq 'ARRAY'; #Replace
	push @{ $self->{_nameservers} }, $_[0] if ref $_[0] eq 'HASH'; #Append

	return @{ $self->{_nameservers} }; 
}

*availcontact = \&contact_check;
sub contact_check {
	my ($self) = shift;
	
	$self->requirements;
	die $self->error if $self->error;
	return contact_info($self) == 0 ?  {'avail' => 1} : {'avail' => 0}; #Disponivel, verdadeiro
}

sub contact_info {
	my ($self) = shift;
	return undef if $self->error;
	
	$self->requirements;
	return if $self->error;
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Contact_Info);
	
	my %response = %{ $self->xml2perl(response($self)->toString(0)) }; 
	if ($response{'response'}[0]{'result'}[0]{'code'} == 1000) {
		#unavailable
		return $response{'response'}[0]{'resData'}[0]{'contact:infData'}[0];
	} elsif ($response{'response'}[0]{'result'}[0]{'code'} == 2303) {
		#avail
		return 0;
    } else { 
		$self->set_error($response{'response'}[0]{'result'}[0]{'msg'}[0]{'content'});
		return undef;
	}
}

*addcontact = \&contact_create;
sub contact_create {
	my ($self) = shift;
	return undef if $self->error;
	
	$self->requirements;
	return if $self->error;
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Contact_Create);
	my $response = response($self);

	#check sucessfull
	my $result = ($response->getElementsByTagName("result"))[0];
	if ($result->getAttribute('code') == 1000) {
		$result = ($response->getElementsByTagName("resData"))[0];
		$result = ($result->getChildrenByTagName("contact:creData"))[0];
		$id = $result->findvalue("contact:id");
		return $id;
	} else { 
		$self->set_error( 'contact_create: '.$result->textContent("msg") ); 
		return undef;
	}
}

*availorg = \&org_check; #alias
sub org_check {
	my ($self) = shift;
	
	$self->requirements;
	return if $self->error;
	return org_info($self) == 0 ?  {'avail' => 1} : {'avail' => 0}; #Disponivel, verdadeiro
}

sub org_info {
	my ($self) = shift;
	return undef if $self->error;
	
	$self->requirements;
	return if $self->error;
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Org_Info);
		
	my %response = %{ $self->xml2perl(response($self)->toString(0)) };
	#check sucessfull
    if ($response{'response'}[0]{'result'}[0]{'code'} == 1000) {
		my %resp = %{ $response{'response'}[0]{'resData'}[0]{'contact:infData'}[0] };
		my %ext = %{ $response{'response'}[0]{'extension'}[0]{'brorg:infData'}[0] };

		my (%contacts,%nameservers,$i);
		my @stats = ref( $resp{'contact:status'} ) eq 'ARRAY' ? @{ $resp{'contact:status'} } : ($resp{'contact:status'});
		my @addr = ref($resp{'contact:postalInfo'}[0]{'contact:addr'}[0]{'contact:street'}) eq 'ARRAY' ? @{ $resp{'contact:postalInfo'}[0]{'contact:addr'}[0]{'contact:street'} } : ($resp{'contact:postalInfo'}[0]{'contact:addr'}[0]{'contact:street'});
		
		return {
				'org_resp' => $ext{'brorg:responsible'}[0]{'content'},
				'org' => $resp{'contact:id'}[0]{'content'},
				'org_name' => $resp{'contact:postalInfo'}[0]{'contact:name'}[0]{'content'},
				'org_cep' => $resp{'contact:postalInfo'}[0]{'contact:addr'}[0]{'contact:pc'}[0]{'content'},
				'org_cidade' => $resp{'contact:postalInfo'}[0]{'contact:addr'}[0]{'contact:city'}[0]{'content'},
				'org_estado' => $resp{'contact:postalInfo'}[0]{'contact:addr'}[0]{'contact:sp'}[0]{'content'},
				'org_tel' => $resp{'contact:voice'}[0]{'content'} || $resp{'contact:voice'}[0]{'content'},
				'org_ramal' => $resp{'contact:voice'}[0]{'x'},				
				'org_email' => $resp{'contact:email'}[0]{'content'},
				'org_address' => join(', ', map {$_->{'content'}} @addr),
				'org_status' => $stats[0]->{'s'} ,
		};
	} elsif ($response{'response'}[0]{'result'}[0]{'code'} == 2303) {
		#avail
		return 0;
    } else { 
		$self->set_error( $response{'response'}[0]{'result'}[0]{'msg'}[0]{'content'} );
		return undef;
	}
}

*addorg = \&org_create;
sub org_create {
	my ($self) = shift;
	return undef if $self->error;
	
	$self->requirements;
	return if $self->error;
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Org_Create);
	my $response = response($self);

	#check sucessfull
	my $result = ($response->getElementsByTagName("result"))[0];
    if ($result->getAttribute('code') == 1001) {#acao pendente
		return 1;
    } else { 
		$self->set_error( 'org_create: '.$result->textContent("msg") ); 
		return undef;
	}
}

sub poll_get {
	my ($self) = shift;
	return undef if $self->error;
	
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Poll('req'));
	my $response = response($self);

	#check sucessfull
	my $result = ($response->getElementsByTagName("result"))[0];
    if ($result->getAttribute('code') == 1301) {#1301    "Command completed successfully; ack to dequeue"
		$result = ($response->getElementsByTagName("msgQ"))[0];
		my $id = $result->getAttribute('id');
		my $count = $result->getAttribute('count');
		$result = ($result->getChildrenByTagName("msg"))[0];
		my (@text,$code,$objectid);
		if ($result) {
			foreach my $node ($result->getChildrenByTagName('*')) {
				$code = $node->textContent if $node->nodeName eq 'code';
				$objectid = $node->textContent if $node->nodeName eq 'objectId';
				push @text, $node->nodeName.': '.$node->textContent;
			}
		}
		
		#Extension possui o reason caso falhe ou crie tbm
		$result = ($response->getElementsByTagName("extension"))[0];
		$result = ($result->getChildrenByTagName("brdomain:panData"))[0] if $result;
		my ($ticket);
		if ($result) {
			foreach my $node ($result->getChildrenByTagName('*')) {
				$ticket = $node->textContent if $node->nodeName eq 'brdomain:ticketNumber';
				push @text, $node->nodeName.': '.$node->textContent;
			}		
		}
		my $success;
		if ($code == 1) {
			$result = ($response->getElementsByTagName("resData"))[0];
			$result = ($result->getChildrenByTagName("domain:panData"))[0] if $result;;
			$result = ($result->getChildrenByTagName("domain:name"))[0] if $result;;
			$success = $result->getAttribute('paResult') || -1 if $result;#-1 => cancelado
		}
		
		return { 'id' => $id, 'text' => [@text], 'count' => $count, 'created' => $success, 'objectid' => $objectid, 'ticket' => $ticket };
    } elsif ($result->getAttribute('code') == 1300) { #1300    "Command completed successfully; no messages"
    	return { 'count' => 0 };
    } else { 
		$self->set_error( 'poll_get: '.$result->textContent("msg") ); 
		return undef;
	}		
}

sub poll_ack {
	my ($self) = shift;
	return undef if $self->error;
	return 1 if !$_[0];
	
	#send command
	command($self,$self->Controller::Registros::RegistroBR::Epp::Poll('ack',$_[0]));
	my $response = response($self);
	
	#check sucessfull
	my $result = ($response->getElementsByTagName("result"))[0];
    if ($result->getAttribute('code') == 1000) {    	
		return 1; #return count
    } else { 	
		$self->set_error( 'poll_ack: '.$result->textContent("msg") ); 
		return undef;
	}	
}

sub expdate {
	my ($self) = shift;
	return undef if $self->error;
		
	$self->service('dados','Ticket', undef);
	my $result = $self->domain_info;
		
	return $self->datefromISO8601($result->{'expiration'}) unless $self->error || !$result->{'expiration'};
	return undef;
}

sub expire {
	my ($self) = shift;
	return undef if $self->error;
	return 1; #Just let expire
}

sub user_login {
	my ($self) = shift;
	return undef if $self->error;
}

sub command {
	my ($self) = shift;
	my $cmd = shift;
	return undef if $self->error;
	
	#make commands
	unless ($cmd ne "") {
		$self->set_error($self->lang(814)); #TODO add lang
	} else {
		$self->{ERR2} .= "$cmd" if $DEBUG;
		connection($self)->send_frame($cmd);

		eval {
			local $SIG{ALRM} = sub { die "RegistroBR Timed out\n" };
			alarm($self->{timeout});
			$self->{_lastresponse} = connection($self)->get_frame();
			alarm(0);
		};
	}
}

sub response { return undef unless $_[0]; $_[0]->{_lastresponse}->setEncoding('ISO-8859-1') if $_[0]->{_lastresponse}; return $_[0]->{_lastresponse}; }

sub DNS_authority {
	my ($self) = shift; 
	
	use Net::DNS;
	my $res = new Net::DNS::Resolver;
	$res->defnames(0);
	$res->retry(2);
	$res->tcp_timeout(5);
	$res->udp_timeout(5);

	my @nameservers = @_;
	# Check the SOA record on each nameserver.
	$| = 1;
	$res->recurse(0);#Non recursive query
	my $soa_req;
	foreach $nsrr (@nameservers) {
		# Set the resolver to query this nameserver.
		unless ($res->nameserver($nsrr)) {
			$self->set_error("Can't find address: ".$res->errorstring."\n");
			return 0;
		}
		# Get the SOA record.
		$soa_req = $res->send($self->service('dominio'), "SOA");
		unless (defined($soa_req)) {
			return 0;
		}
		# Is this nameserver authoritative for the domain?
		return 0 unless ($soa_req->header->aa);
		# We should have received exactly one answer.
		unless ($soa_req->header->ancount == 1) {
			return 0;
		}
		# Did we receive an SOA record?
		unless (($soa_req->answer)[0]->type eq "SOA") {
			return 0;
		}
	}
	
	return 1 if $soa_req->header->aa; #O último deve responder com autoridade, caso nao entre no loop
}

sub _menu {
	my $self = shift;
	my $id = $self->sid;
	$self->template('menu',qq~<table width="100%" border="0" cellpadding="0" cellspacing="0">
               <!--DWLayoutTable-->
               <tr valign="middle">
                 <td valign="middle"><div align="center">[ <a href="?do=view_services&mode=adm&id=$id"><font size="1" color="#0000FF">EDITAR PERFIL</font></a> | <a href="?do=logout"><font size="1" color="#0000FF">SAIR</font></a> ]</div></td>                  
               </tr>
             </table>~);	
}
#######################################
# Implementa a interface de Registros #
#######################################
sub Controller::Interface::Users::Registros {
	my $self = shift;

	$self->template('id',$self->sid);
	use Controller::Services;
	my $services = new Controller::Services;
	    			
	$self->template('error', $self->lang(10)) if $self->service('lock') != 0;#Bloqueia edição de arquivos
	if ($self->param('update') eq "nameserver" && $self->service('lock') == 0) {
		#add $_ and remove old_
		sub Controller::Registros::RegistroBR::Epp::Domain_Update_NSADD {
			foreach my $param ($self->params) {
				$param = Controller::trim($param);
				if ($param =~ m/^ns\d+$/ && $self->param($param) && (
					$self->param($param) ne Controller::trim($self->param('old_'.$param)) ||
					Controller::trim($self->param($param.'_ipv4')) ne Controller::trim($self->param('old_'.$param.'_ipv4')) || 
					Controller::trim($self->param($param.'_ipv6')) ne Controller::trim($self->param('old_'.$param.'_ipv6')) )) {
						
					my $ns_attr = $_[0]->createElement('domain:hostAttr', $_[1]);
					$_[0]->createElement('domain:hostName', $ns_attr, $self->param($param));
					my $ns_ipv4 = $_[0]->createElement('domain:hostAddr', $ns_attr, Controller::trim($self->param($param.'_ipv4')));
					$ns_ipv4->setAttribute('ip','v4');
					my $ns_ipv6 = $_[0]->createElement('domain:hostAddr', $ns_attr, Controller::trim($self->param($param.'_ipv6')));
					$ns_ipv6->setAttribute('ip','v6');
				}
			}
		}
		
		sub Controller::Registros::RegistroBR::Epp::Domain_Update_NSREM {
			foreach my $param ($self->params) {
				$param = Controller::trim($param);
				if ($param =~ m/^ns\d+$/ && Controller::trim($self->param('old_'.$param)) && (
					$self->param($param) ne Controller::trim($self->param('old_'.$param)) ||
					Controller::trim($self->param($param.'_ipv4')) ne Controller::trim($self->param('old_'.$param.'_ipv4')) || 
					Controller::trim($self->param($param.'_ipv6')) ne Controller::trim($self->param('old_'.$param.'_ipv6')) )) {

					my $ns_attr = $_[0]->createElement('domain:hostAttr', $_[1]);
					$_[0]->createElement('domain:hostName', $ns_attr, Controller::trim($self->param('old_'.$param)));
					my $ns_ipv4 = $_[0]->createElement('domain:hostAddr', $ns_attr, Controller::trim($self->param('old_'.$param.'_ipv4')));
					$ns_ipv4->setAttribute('ip','v4');
					my $ns_ipv6 = $_[0]->createElement('domain:hostAddr', $ns_attr, Controller::trim($self->param('old_'.$param.'_ipv6')));
					$ns_ipv6->setAttribute('ip','v6');
				}
			}
		}						
		#Contacts
		sub Controller::Registros::RegistroBR::Epp::Domain_Update_ContactsADD {
			foreach ('admin','tech','billing') {
				if ($self->param($_) ne $self->param('old_'.$_)) {
					my $el = $_[0]->createElement('domain:contact', $_[1], $self->param($_));
					$el->setAttribute('type', Controller::trim($_));
				}
			}
		}
		sub Controller::Registros::RegistroBR::Epp::Domain_Update_ContactsREM {
			foreach ('admin','tech','billing') {
				if ($self->param($_) ne $self->param('old_'.$_)) {
					my $el = $_[0]->createElement('domain:contact', $_[1], $self->param('old_'.$_));
					$el->setAttribute('type', Controller::trim($_));
				}
			}
		}							
		
		my $result = $self->domain_update;
		$self->template('error', $result->{'response'} || $self->clear_error || $self->lang($result->{'response'}));
	}
	$self->{_epp}{ERR} = $self->{ERR} = undef;
	
	$self->template('dominio', Controller::iso2puny($self->service('dominio')));
	my $result = $self->Controller::Registros::RegistroBR::domain_info;
	if ($result == 0 && $self->service('dados','Ticket')) {
		$self->service('dados','Ticket',undef);
		$result = $self->Controller::Registros::RegistroBR::domain_info;
		$self->Controller::Services::save if $result->{'org'};
	}
	$self->template('error',$self->lang(822)) unless $result->{'org'};
	$self->user('cnpj',$self->num($result->{'org'}));#CNPJ temporario
	my $rorg = $self->Controller::Registros::RegistroBR::org_info;
	$self->user('cnpj',undef);#CNPJ temporario
	
	$self->template('admin', $result->{'admin'});
	$self->template('tech', $result->{'tech'});
	$self->template('billing', $result->{'billing'});
	$self->template('org_email', $rorg->{'org_email'});
	$self->template('org', Controller::frmtCPFCNPJ($rorg->{'org'}));
	$self->template('org_cep', $rorg->{'org_cep'});
	$self->template('org_name', $rorg->{'org_name'});
	$self->template('org_estado', $rorg->{'org_estado'});
	$self->template('org_status', $self->lang($rorg->{'org_status'}));
	$self->template('org_address', $rorg->{'org_address'});
	$self->template('org_tel', Controller::frmt($rorg->{'org_tel'},'phone'));
	$self->template('org_ramal', $rorg->{'org_ramal'});
	$self->template('org_cidade', $rorg->{'org_cidade'});
	$self->template('org_resp', $rorg->{'org_resp'} || $rorg->{'org_name'});
	
	my @nslist = sort keys %{ $result->{'nameserver_list'} };
	push @nslist, ('','','',''); #Gerar campos em branco
	foreach ( @nslist ) {
		last if ++$limit > 4; 
		$self->template('nsnumber', $limit);
		$self->template('nsname', $self->lang('NS'.$limit));
		$self->template('ns', $result->{'nameserver_list'}{$_}{'host'});
		$self->template('ipv4', $result->{'nameserver_list'}{$_}{'ip'}{'v4'});
		$self->template('ipv6', $result->{'nameserver_list'}{$_}{'ip'}{'v6'});
		$self->parse_var('rows','/registro_admBR_row');
	}
	
	#Apagar DNS fora do range
	$self->template('ns5', $result->{'nameserver_list'}{$nslist[4]}{'host'});
	$self->template('ns6', $result->{'nameserver_list'}{$nslist[5]}{'host'});	
	
	$self->parse('/registro_admBR');   
}

1;
__END__;
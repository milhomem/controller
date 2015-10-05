#!/usr/bin/perl
# Use: Module
# Controller - is4web.com.br
# 2007
package Controller::Registros::ResellOne;

require 5.008;
require Exporter;

use Controller;
use Controller::Registros::ResellOne::Epp;

@ISA = qw(Controller Exporter);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    
	my $self = new Controller( @_ );
	%$self = (
		%$self,
		'domain' => undef,
		'modulo' => undef,
		'ERR' => undef,
		'disponivel' => undef,
	);

	bless($self, $class);

	return $self;
}

sub registrar {
	my ($self) = @_;
	return if $self->error; 

	$self->{_epp}{'reg_type'} eq 'transfer' ? $self->transferrable : $self->availdomain;
	#$self->availorg;
	#$self->availcontact;
	$self->contacts;
	#$self->addorg;
	$self->nameservers;
	$self->adddomain;
	$self->addnameserver if $self->{_epp}{'ns1'} =~  /\.$self->{'domain'}$/i;	
	$self->addnameserver2 if $self->{_epp}{'ns2'} =~  /\.$self->{'domain'}$/i;
			
	$self->log( 
			'cmd' => "REGISTRO",
			'table' => 'registrar',
			'value' => $self->{'domain'},
			'byuser' => $self->{cookname},
			'debug' =>	Controller::tostring({ nameserver_list => $self->{_epp}{'ns_list'},
						   contact_set => $self->{_epp}{'contact_list'} })) unless $self->error;
	
	return 1 unless $self->error;
	return undef;
}

sub expdate_old {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar

	use Net::DRI;
	
	my $dri=Net::DRI->new(10);
	my $expdate;
	eval {		
		local $SIG{'__DIE__'} = undef;	
		$dri->add_registry('VNDS',{}); #COM, NET
		$dri->add_registry('ORG',{});
		$dri->add_registry('INFO',{});
		$dri->add_registry('BIZ',{});
		$dri->add_registry('US',{});
		my $rc=$dri->target($self->{domain})->add_current_profile('profile1','whois');
		die($rc) unless $rc->is_success();
		$dri->domain_info($self->{domain});
		
		if ($dri->result_is_success()) {
			my $e=$dri->get_info('exist');
			$expdate = $dri->get_info('exDate');
		} 
	};

	if ($@)	{ 
	 print "\n\nAn EXCEPTION happened !\n";
	 if (ref($@)) {
	  die $@->as_string();
	 } else {
	  die $@;
	 }
	}

	#200 ok
	$self->{'expdate'} = $dri->result_is_success() ? $expdate : 0;
	$self->{'expdate'} =~ s/ /T/; #To ISO
	
	$self->set_error($dri->result_message." code: ".$dri->result_code) unless $expdate;
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	my $retry = $dri->result_code == 2500 ? 1 : 0;
	$dri->end();
	if ($retry == 1) { #Unable to read answer (connection closed by registry ?) code: 2500
		sleep 15;
		$self->clear_error;
		return $self->expdate;
	}
		
	return $self->datefromISO8601($self->{'expdate'}) unless $self->error;
	return undef;
}

sub expdate {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	$self->{_epp}{'type'} = 'all_info';
	my $retry=0; my $response;
	do {
		($response) = $self->{_epp}->domain_get(); 
	} while ($retry++ < 3 && $response->{'response_code'} == 0 && $self->clear_error && sleep 5);

	#code 200 - OK
	$self->set_error($response->{'response_text'}) if $response->{'response_code'} != 200;
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'};

	$response->{'attributes'}{'expiredate'} =~ s/ .*//; #To ISO

	return $self->datefromISO8601($response->{'attributes'}{'expiredate'}) unless $self->error || !$response->{'attributes'}{'expiredate'};
	return undef;	
}

sub expire {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	return 1; #just let expire, has no charge
	
	my ($code,$reason) = $self->{_epp}->revoke();

	#200 ok
	$self->{'expire'} = $code == 200 ? 1 : 0;
	
	$self->set_error("$reason code: $code") unless $self->{'expire'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	return 1 unless $self->error;
	return undef;
}

sub availdomain {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($free,$reason) = $self->{_epp}->domain_check();

	#free 210 - Disponivel, 211 - Registrado
	$self->{'disponivel'} = $free == 210 ? 1 : 0;

	$self->set_error("Domínio não disponível: '$reason'") unless $self->{'disponivel'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	return $self->{'disponivel'};
}

sub transferrable {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($code,$cantranfer,$reason) = $self->{_epp}->domain_transferrable();

	#free 210 - Disponivel, 211 - Registrado
	$self->{'transferrable'} = $code == 200 ? $cantranfer : 0;

	$self->set_error("Domínio não transferível: '$reason'") unless $self->{'transferrable'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	return $self->{'transferrable'};
}

sub adddomain {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($code,$reason) = $self->{_epp}->domain_create();

	#code 200 - OK
	$self->{'adddomain'} = $code == 200 ? $self->{_epp}->{'order_id'} : 0;
	
	$self->set_error($self->lang(816,$reason)) if $self->{_epp}->{'order_queue'};
	$self->set_error($self->lang(821,$reason)) unless $self->{'adddomain'};
	$self->set_error($self->lang(809,$self->{_epp}->{'ERR'})) if $self->{_epp}->{'ERR'}; 
	
	return $self->{'adddomain'};	
}

sub renew {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($code,$reason,$expdate) = $self->{_epp}->renew();

	#code 200 - OK
	$self->set_error($response->{'response_text'}) if $response->{'response_code'} != 200;
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'};	
	
	$expdate =~ s/ /T/; #To ISO
	
	$self->log( 
			'cmd' => "REGISTRO",
			'table' => 'renovar',
			'value' => $self->{'domain'},
			'byuser' => $self->{cookname},
			'debug' =>	Controller::tostring({ 'exp' => $expdate })) unless $self->error;
						   	
	return $self->Controller::datefromISO8601($expdate) unless $self->error;
}

sub getdomain {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($response) = $self->{_epp}->domain_get();

	#code 200 - OK
	$self->set_error($response->{'response_text'}) if $response->{'response_code'} != 200;
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'};
	
	$self->{'getdomain'} = $response;
	
	return 1;	
}

sub whois {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($response) = $self->getdomain();

	use Data::Dumper;
	return Dumper \$response;
}

sub getnameservers {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	$self->{_epp}->{type} = 'nameservers';
	my ($response) = $self->{_epp}->domain_get();

	#code 200 - OK
	$self->set_error($response->{'response_text'}) if $response->{'response_code'} != 200;
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'};
	
	$self->{'getnameservers'} = $response;
	
	return 1;	
}

sub getownnameservers {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	$self->{_epp}->{type} = 'nameservers';
	my ($response) = $self->{_epp}->nameserver_get();

	#code 200 - OK
	$self->set_error($response->{'response_text'}) if $response->{'response_code'} != 200;
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'};
	
	$self->{'getownnameservers'} = $response;
	
	return 1;	
}

sub addnameserver {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($code,$reason) = $self->{_epp}->nameserver_create();

	#code 200 - OK
	$self->{'addnameserver'} = $code == 200 ? 1 : 0;

	$self->set_error("Erro ao adicionar nameserver: '$reason'") unless $self->{'addnameserver'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	return $self->{'addnameserver'};	
}

sub addnameserver2 {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($code,$reason) = $self->{_epp}->nameserver2_create();

	#code 200 - OK
	$self->{'addnameserver2'} = $code == 200 ? 1 : 0;

	$self->set_error("Erro ao adicionar nameserver: '$reason'") unless $self->{'addnameserver2'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	return $self->{'addnameserver2'};	
}

sub update_domainnameserver {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($code,$reason) = $self->{_epp}->domain_update_nameservers;

	#code 200 - OK
	$self->{'update_domainnameserver'} = $code == 200 ? 1 : 0;

	$self->set_error("Erro ao alterar nameservers: '$reason'") unless $self->{'update_domainnameserver'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'};
	$self->log(
			'cmd' => "REGISTRO",
			'table' => 'domain_dns',
			'value' => $self->{'domain'},
			'byuser' => $self->{cookname},
			'debug' => Controller::tostring({ assign_ns => $self->{_epp}{assign_list},
						 add_ns => $self->{_epp}{add_list},
						 remove_ns => $self->{_epp}{remove_list} }) ) unless $self->error;
	
	return $self->{'update_domainnameserver'};	
}

sub update_nameserver {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($code,$reason) = $self->{_epp}->nameserver_modify;

	#code 200 - OK
	$self->{'update_nameserver'} = $code == 200 ? 1 : 0;

	$self->set_error("Erro ao alterar nameservers: '$reason'") unless $self->{'update_nameserver'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	$self->log(
			'cmd' => "REGISTRO",
			'table' => 'ns_update',
			'value' => $self->{'domain'},
			'byuser' => $self->{cookname},
			'debug' => Controller::tostring({ name => $self->{_epp}{old_ns1},
						   new_name => $self->{_epp}{ns1},
						   ipaddress => $self->{_epp}{ip1} }) )  unless $self->error;
		
	return $self->{'update_nameserver'};	
}

sub remove_nameserver {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my ($code,$reason) = $self->{_epp}->nameserver_delete;

	#code 200 - OK
	$self->{'remove_nameserver'} = $code == 200 ? 1 : 0;

	$self->set_error("Erro ao remover nameservers: '$reason'") unless $self->{'remove_nameserver'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	$self->log(
			'cmd' => "REGISTRO",
			'table' => 'ns_remove',
			'value' => $self->{'domain'},
			'byuser' => $self->{cookname},
			'debug' => Controller::tostring({ name => $self->{_epp}{ns1} }) ) unless $self->error;
						   	
	return $self->{'remove_nameserver'};	
}

sub contacts {
	my ($self) = @_;
	return if $self->error; #verifica erro antes de continuar
	
	my $ref = $self->select_sql(qq|SELECT * FROM `users` WHERE `username` = ? LIMIT 1|,$self->uid)->fetchrow_hashref();
	$self->finish;

	$self->{_epp}->{'country_codes'} = $self->{'country_codes'};#copy
	my ($name,$lastname) = split(" ",$ref->{'name'},2);
	my $email = (split(',',$ref->{'email'}))[0];
	my $empresa = $ref->{'empresa'} || "$name $lastname";

	my $user = {
				'first_name' => Controller::sem_acentos("$name"),
				'last_name' => Controller::sem_acentos("$lastname"),
				'state' => Controller::sem_acentos("$ref->{'estado'}"),
				'city' => Controller::sem_acentos("$ref->{'cidade'}"),
				'country' => Controller::sem_acentos("$ref->{'cc'}"),
				'address1' => Controller::sem_acentos("$ref->{'endereco'}"),
				'address2' => Controller::sem_acentos("$ref->{'numero'}"),
				'address3' => undef,
				'fax' => undef,
				'phone' => Controller::frmt("$ref->{'telefone'}",'phone'),
				'postal_code' => "$ref->{'cep'}",
				'email' => Controller::sem_acentos("$email"),
				'org_name' => Controller::sem_acentos("$empresa"),
				};

	my $tech = eval $self->setting('registro_tech') || $user;
	my $owner = eval $self->setting('registro_owner') || $user;
	my $admin = eval $self->setting('registro_admin') || $user;
	my $billing = eval $self->setting('registro_billing') || $user;
	
	$self->{_epp}{'hide_reseller'} == 1
		? $self->{_epp}->_setcontacts($user,$user,$user,$user)	
		: $self->{_epp}->_setcontacts($admin,$billing,$owner,$tech);
	
	return if $self->{'modulo'} eq "resellone";
	
	return 1;
}

sub update_contacts {
	my ($self) = shift;
	return if $self->error; #verifica erro antes de continuar
	
	my %user = @_;#hash
	$self->{_epp}{data} = 'contact_info';
	$self->{_epp}{affect} = 0;
	
	my $tech = $user{'tech'};
	my $owner = $user{'owner'};
	my $admin = $user{'admin'};
	my $billing = $user{'billing'};
	
	$self->{_epp}->_setcontacts($admin,$billing,$owner,$tech);
	my ($code,$reason) = $self->{_epp}->domain_modify;

	#code 200 - OK
	$self->{'update_contacts'} = $code == 200 ? 1 : 0;

	$self->set_error("Erro ao alterar contatos: '$reason'") unless $self->{'update_contacts'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	return $self->{'update_contacts'};	
}

sub contactfields {
	my ($self) = @_;
	
	return ('first_name','last_name','state','city','country','address1',
				'address2','address3','fax','phone','postal_code','email','org_name');	
}

sub nameservers {
	my ($self) = shift;

	push @{ $self->{_epp}->{_nameservers} }, $_[0] if ref $_[0] eq 'HASH';

	$self->{_epp}->_setns unless exists $_[0];

	return 1;
}

sub nameservers_test {
	my ($self) = @_;
	return if $self->error;
		
	foreach ($self->{ns1},$self->{ns2}) {
		if ($_) {
			my ($code,$response) = $self->{_epp}->nameserver_check($_);
			if ($code != 200) {
				$self->set_error($response); 
				return undef;
			}
		};
	}
	
	return 1;
}

sub change_ownership {
	my ($self) = shift;
	return if $self->error;

	my %user = @_;
	$self->{_epp}{move_all} = 0;
	
	$self->{_epp}{cookie_user} = $user{'user'};
	$self->{_epp}{cookie_pass} = $user{'pass'};
	$self->{_epp}{change_user} = $user{'new_user'};
	$self->{_epp}{change_pass} = $user{'new_pass'};
	my ($code,$reason) = $self->{_epp}->change_ownership;

	#code 200 - OK
	$self->{'change_ownership'} = $code == 200 ? 1 : 0;

	$self->set_error("Erro ao alterar o owner do dominio: '$reason'") unless $self->{'change_ownership'};
	$self->set_error($self->{_epp}->{'ERR'}) if $self->{_epp}->{'ERR'}; 
	
	return $self->{'change_ownership'};	
}

sub _domain {
	my ($self,$domain) = @_; 
	
	$self->{'domain'} = $domain;
	$self->{'domain'} =~ s/^www\.//g;
	if ($self->{'domain'} =~ m/\.(?:com|net|org|biz|info|us)$/i) { #Busca se for internacional para usar ResellOne
		$self->_resellone;
	} else {
		$self->set_error($self->lang(802,$self->{'domain'}));
	}
	$self->{_epp}->{'domain'} = $self->{'domain'};
	
	return $self->error ? 0 : 1;
}

sub _resellone {
	my ($self) = @_;

	$self->{'modulo'} = "resellone";
	$self->{_epp} = undef;
	$self->{_epp} = Controller::Registros::ResellOne::Epp->new($self);	
	$self->{_epp}{host} = $self->setting('resellone_host');
	$self->{_epp}{port} = $self->setting('resellone_port'); #HTTP: 55000 HTTPS: 52443
	$self->{_epp}{username} = $self->setting('resellone_user');
	$self->{_epp}{password} = $self->setting('resellone_pass'); 
	$self->{_epp}{private_key} = $self->setting('resellone_pkey');
	$self->{_epp}{link_domain} = $self->setting('resellone_domain');
	$self->set_error("Erro ao gerar o pacote") unless $self->{_epp};
	$self->{_epp}{Controller} = $self;	

	return 1;
}

sub _menu {
	my $self = shift;
	my $id = $self->sid;
	$self->template('menu',qq~<table width="100%" border="0" cellpadding="0" cellspacing="0">
               <!--DWLayoutTable-->
               <tr valign="middle">
                 <td valign="middle"><div align="center">[ <a href="?do=view_services&mode=adm&id=$id"><font size="1" color="#0000FF">EDITAR PERFIL</font></a> | <a href="?do=view_services&mode=adm&nameserver=NameServers&id=$id"><font size="1" color="#0000FF">MODIFICAR DNS</font></a> | <a href="?do=logout"><font size="1" color="#0000FF">SAIR</font></a> ]</div></td>                  
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
	
	if ($self->param('nameserver') eq 'NameServers') {
		$self->template('error', $self->lang(10)) if $self->service('lock') != 0;#Bloqueia edição de arquivos
		if ($self->param('update') eq "nameserver" && $self->service('lock') == 0) {
			if ($self->param('ns1') && $self->param('ns2')) {
				$self->{_epp}{type} = 'assign';
				push @{ $self->{_epp}{assign_list} }, $self->param('ns1') if $self->param('ns1');
				push @{ $self->{_epp}{assign_list} }, $self->param('ns2') if $self->param('ns2');					
			} elsif ($self->param('ns1') ne $self->param('old_ns1') || $self->param('ns2') ne $self->param('old_ns2')) {
				$self->{_epp}{type} = 'add_remove';
				if ($self->param('ns1') ne $self->param('old_ns1')) {
					push @{ $self->{_epp}{remove_list} }, $self->param('old_ns1') if $self->param('old_ns1');
					push @{ $self->{_epp}{add_list} }, $self->param('ns1') if $self->param('ns1');
				}
				if ($self->param('ns2') ne $self->param('old_ns2')) {
					push @{ $self->{_epp}{remove_list} }, $self->param('old_ns2') if $self->param('old_ns2');					
					push @{ $self->{_epp}{add_list} }, $self->param('ns2') if $self->param('ns2');
				}
			}
			if (@{ $self->{_epp}{remove_list} } || @{ $self->{_epp}{add_list} } || @{ $self->{_epp}{assign_list} }) {
				$self->update_domainnameserver;
				$services->service('dados','NS1',$self->param('ns1'));
				$services->service('dados','NS2',$self->param('ns2'));											
				$services->service('dados','NS1',' ') unless $self->param('ns1');
				$services->service('dados','NS2',' ') unless $self->param('ns2');					
				$services->save;
			}
			$self->template('error', $self->clear_error);
		} elsif ($self->param('update') eq "update_nameserver") {
			if ($self->param('modify')) {
				$self->{_epp}{old_ns1} = $self->param('oldns');
				$self->{_epp}{ns1} = $self->param('ns') if $self->param('oldns') ne $self->param('ns');
				$self->{_epp}{ip1} = $self->param('ns_ip');
				$self->update_nameserver;
			} elsif ($self->param('delete')) {
				$self->{_epp}{ns1} = $self->param('oldns');
				$self->remove_nameserver;
			}
			$self->template('error2', $self->clear_error);
		} elsif ($self->param('update') eq "create_nameserver") {
			$self->{_epp}{'ns1'} = $self->param('hostname').".".$self->service('dominio');
			$self->{_epp}{'ip1'} = $self->param('ip');
			if ($self->addnameserver) {
				$self->template('add', $self->lang('added'));
			} else {
				$self->template('add', $self->error);
			}
		}
		$self->{_epp}{ERR} = $self->{ERR} = undef;

		$self->template('dominio', $self->service('dominio'));
		$self->getnameservers;
		foreach ( @{ $self->{'getnameservers'}{'attributes'}{'nameserver_list'} } ) {
			$self->template('ns'.$_->{'sortorder'}, $_->{'name'});
		}
            	
		$self->getownnameservers; my $limit;
		foreach ( @{ $self->{'getownnameservers'}{'attributes'}{'nameserver_list'} } ) {
			last if ++$limit > 10;
			$self->template('nameserver', $_->{'name'});
			$self->template('nameserver_ip', $_->{'ipaddress'});
			$self->template('delete', $_->{'can_delete'} ? '' : 'disable' );
			$self->parse_var('rows','/registro_adm2_row');
		}
            	
		$self->parse('/registro_adm2');
	} elsif ($self->param('nameserver') eq 'AuthCode') {
		$self->{_epp}{'type'} = 'domain_auth_info';
		
		$self->getdomain;
		$self->template('authcode', Controller::html($self->{'getdomain'}{'attributes'}{'domain_auth_info'}));
		
		$self->parse('/registro_admauth');
	} else {         	
		my $type = $self->param('type') || "owner";
		$self->template('selbill', "selected") if $type =~ /^billing$/;
		$self->template('seladm', "selected") if $type =~ /^admin$/;
		$self->template('selown', "selected") if $type =~ /^owner$/;            
		$self->template('seltech', "selected") if $type =~ /^tech$/;
		$self->{_epp}{'type'} = $type;
		$self->die_nice('acesso negado') if $type !~ /^(admin|owner|billing|tech)$/;

		if ($self->param('update') == 1) {
			my %userdetails;
			foreach ($self->contactfields) {
				$userdetails{$_} = Controller::sem_acentos($self->param($_));
			}
			$self->update_contacts( $type => { %userdetails });
			$self->template('error', $self->clear_error);
			$self->{_epp}{ERR} = $self->{ERR} = undef;
		}
	                      				
		$self->getdomain; #owner
		unless ($self->error) {
            foreach ($self->contactfields) {
            	$self->template('column', $self->lang($_));
            	$self->template('columnid', $_);
            	my $val = $self->{'getdomain'}{'attributes'}{'contact_set'}{$type}{$_};
            	$val =~ s/^\+\d+?\.// if $_ =~ m/^(?:phone|fax)$/;#remove +55.
            	$self->template('value',$val);
            	$self->parse_var('rows','/registro_adm_row');
            }
		} else {
			$self->template('response', $self->clear_error);
			$self->parse('/general');
		}
		$self->parse('/registro_adm');
	}    
}

1;
__END__;
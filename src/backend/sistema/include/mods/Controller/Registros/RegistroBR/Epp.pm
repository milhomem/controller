#!/usr/bin/perl
# registro.br - Epp.pm              
#
# Controller - Is4web.com.br
# 2008
package Controller::Registros::RegistroBR::Epp;

require 5.004;
require Exporter;
#use strict;
use Controller::XML;

use vars qw(@ISA $VERSION $DEBUG $EPP_URN $SCHEMA_URI $LANG);

$VERSION = '1.0';
$LANG = 'pt';
@ISA = qw(Controller::XML);

$EPP_URN = 'urn:ietf:params:xml:ns';
$SCHEMA_URI	= 'http://www.w3.org/2001/XMLSchema-instance';

sub newDocument {
    my $class = ref($_[0]) || $_[0];

    my $self = Controller::XML->newDocument('1.0','UTF-8');
	$self->setStandalone(1);
	my $epp = $self->createElementRootNS("$EPP_URN:epp-1.0", 'epp');
	$epp->setNamespace($SCHEMA_URI, 'xsi', 0);
	$epp->setAttributeNS($SCHEMA_URI, 'schemaLocation', "$EPP_URN:epp-1.0 epp-1.0.xsd");
	my $cmd = $self->createElement('command', $epp);
	my @chars =  (0 .. 9);
	my $id = "CONTROLLER_".$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)];
	$self->createElement('clTRID', $cmd, $id); #ID de controle

	bless($self, $class);
	
	return $self;
}

sub Hello {
	my ($self) = shift;
	my $doc = Controller::Registros::RegistroBR::Epp->newDocument;

	$doc->createElement('hello', 'command');

	return $doc->serialize(0);	
}

sub Login {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $login = $doc->createElement('login', 'command');
	$doc->createElement('clID', $login, $self->setting('registrobr_user'));
	$doc->createElement('pw', $login, $self->setting('registrobr_pass'));
	
	my $options = $doc->createElement('options', $login);
	$doc->createElement('version', $options, $VERSION);
	$doc->createElement('lang', $options, $LANG); #Error language
	
	my $svcs = $doc->createElement('svcs', $login);
	$doc->createElement('objURI', $svcs, "$EPP_URN:domain-1.0");
	$doc->createElement('objURI', $svcs, "$EPP_URN:contact-1.0");
	
	my $svcsext = $doc->createElement('svcExtension', $svcs);
	$doc->createElement('extURI', $svcsext, "$EPP_URN:brdomain-1.0");
	$doc->createElement('extURI', $svcsext, "$EPP_URN:brorg-1.0");
	
	return $doc->serialize(0);		
}

sub Domain_Check {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $check = $doc->createElement('check', 'command');
	my $extension = $doc->createElement('extension', 'command');
	
	my $d_check = $doc->createElementNS('domain:check', $check);
	my $br_check = $doc->createElementNS('brdomain:check', $extension);
		
	$doc->createElement('domain:name', $d_check, Controller::iso2puny(lc $self->service('dominio')));
		
	return $doc->serialize(0);
}

sub Domain_Create {
	my ($self) = shift;
	
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $create = $doc->createElement('create', 'command');
	my $extension = $doc->createElement('extension', 'command');
			
	my $d_create = $doc->createElementNS('domain:create', $create);
	my $br_create = $doc->createElementNS('brdomain:create', $extension);
		
	#Data Elements
	$doc->createElement('domain:name', $d_create, Controller::iso2puny(lc $self->service('dominio')));
	
	my $years = int ($self->payment('intervalo')/360) < 1 ? 1 : int ($self->payment('intervalo')/360);
	my $d_period = $doc->createElement('domain:period', $d_create, $years );
	$d_period->setAttribute('unit', 'y');

	my $d_ns = $doc->createElement('domain:ns', $d_create);
	foreach my $host ( $self->nameservers ) {
		my $d_hostAttr = $doc->createElement('domain:hostAttr', $d_ns);
		$doc->createElement('domain:hostName', $d_hostAttr, Controller::iso2puny($host->{'name'}));
		if ($host->{'ipv4'}) {
			my $ipv4 = $doc->createElement('domain:hostAddr', $d_hostAttr, $host->{'ipv4'});
			$ipv4->setAttribute('ip', 'v4');
		}
		if ($host->{'ipv6'}) {
			my $ipv6 = $doc->createElement('domain:hostAddr', $d_hostAttr, $host->{'ipv6'});
			$ipv6->setAttribute('ip', 'v6');
		}
	}
	
	$doc->createElement('brdomain:organization', $br_create, Controller::frmtCPFCNPJ($self->service('_registrobr_orgid')));
	
	my $renew = $doc->createElement('brdomain:autoRenew', $br_create);
	$renew->setAttribute('active', 0);#renovar automatico atraves do sistema

	return $doc->serialize(0);#1 for debug	
}

sub Domain_Info {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $info = $doc->createElement('info', 'command');
	my $extension = $doc->createElement('extension', 'command');
	
	my $d_info = $doc->createElementNS('domain:info', $info);
	my $br_info = $doc->createElementNS('brdomain:info', $extension);
	
	my $d_name = $doc->createElement('domain:name', $d_info, Controller::iso2puny(lc $self->service('dominio')));
	$d_name->setAttribute('hosts', 'all');
	
	$doc->createElement('brdomain:ticketNumber', $br_info, $self->service('dados','Ticket'));
	
	return $doc->serialize(0);#1 for debug
}

sub Domain_Update {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $update = $doc->createElement('update', 'command');
	my $extension = $doc->createElement('extension', 'command');
	
	my $d_update = $doc->createElementNS('domain:update', $update);
	my $br_update = $doc->createElementNS('brdomain:update', $extension);
	
	$doc->createElement('domain:name', $d_update, Controller::iso2puny(lc $self->service('dominio'))); #Domain wont change
	
	my $d_add = $doc->createElement('domain:add', $d_update);
	my $d_rem = $doc->createElement('domain:rem', $d_update);
	
	Controller::Registros::RegistroBR::Epp::Domain_Update_ContactsADD($doc,$d_add);
	#Nameservers
	my $ns_add = $doc->createElement('domain:ns', $d_add);
	Controller::Registros::RegistroBR::Epp::Domain_Update_NSADD($doc,$ns_add);
	
	Controller::Registros::RegistroBR::Epp::Domain_Update_ContactsREM($doc,$d_rem);
	#Nameservers
	my $ns_rem = $doc->createElement('domain:ns', $d_rem);
	Controller::Registros::RegistroBR::Epp::Domain_Update_NSREM($doc,$ns_rem);
		
	$doc->createElement('brdomain:ticketNumber', $br_update, $self->service('dados','Ticket'));

	return $doc->serialize(0);#1 for debug
}

sub Domain_Delete {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $delete = $doc->createElement('delete', 'command');
	my $d_delete = $doc->createElementNS('domain:delete', $delete);
	my $d_name = $doc->createElement('domain:name', $d_delete, Controller::iso2puny(lc $self->service('dominio')));
	
	return $doc->serialize(0);#1 for debug
}

sub Domain_Renew {
	my ($self,$time) = @_;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $renew = $doc->createElement('renew', 'command');
	my $d_renew = $doc->createElementNS('domain:renew', $renew);
	my $d_name = $doc->createElement('domain:name', $d_renew, Controller::iso2puny(lc $self->service('dominio')));

	my $years = int ($self->payment('intervalo')/360) < 1 ? 1 : int ($self->payment('intervalo')/360);
	my $d_period = $doc->createElement('domain:period', $d_renew, $years);
	$d_period->setAttribute('unit', 'y');

	my $venc = $self->date($self->service('vencimento')->year - $years, $self->service('vencimento')->month, $self->service('vencimento')->day); #Já está quitado e com vencimento novo
	my $expDate = $venc . "T${time}Z"; #'T19:47:12.0Z' Mix para não renovar por engano.
	
	$doc->createElement('domain:curExpDate', $d_renew, $expDate);
	
	return $doc->serialize(0);#1 for debug
}

sub Domain_Update_ContactsADD {} #proto
sub Domain_Update_ContactsREM {} #proto
sub Domain_Update_NSADD {} #proto
sub Domain_Update_NSREM {} #proto

#Org
sub Org_Check {
	my ($self) = shift;
	
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $extension = $doc->createElement('extension', 'command');
	
	my $br_check = $doc->createElementNS('brorg:check', $extension);
	my $br_cd = $doc->createElement('brorg:cd', $br_check);
	$doc->createElement('brorg:id', $br_cd, $self->num($self->service('_registrobr_orgid')));
	$doc->createElement('brorg:organization', $br_cd, Controller::frmtCPFCNPJ($self->service('_registrobr_orgid')));	
	
	return $doc->serialize(0);#1 for debug	
}

sub Org_Create {
	my ($self) = shift;
	
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $create = $doc->createElement('create', 'command');
	my $extension = $doc->createElement('extension', 'command');
	
	my $c_create = $doc->createElementNS('contact:create', $create);
	my $br_create = $doc->createElementNS('brorg:create', $extension);
	
	my $postal = $doc->createElement('contact:postalInfo', $c_create);
	$postal->setAttribute('type', 'loc');
	$doc->createElement('contact:name', $postal, $self->service('_registrobr_orgname'));	
	
	my $addr = $doc->createElement('contact:addr', $postal);
	$doc->createElement('contact:street', $addr, $self->service('dados','registrobr_address') || $self->user('endereco'));
	$doc->createElement('contact:street', $addr, $self->service('dados','registrobr_number') || $self->user('numero'));
	$doc->createElement('contact:city', $addr, $self->service('dados','registrobr_city') || $self->user('cidade'));
	$doc->createElement('contact:sp', $addr, $self->service('dados','registrobr_state') || $self->user('estado'));
	my $cep = $self->service('dados','registrobr_CEP') || $self->user('cep');
	$cep =~ s/^(\d{5})(\d{3})$/$1-$2/ if $self->service('dados','registrobr_cc') eq 'BR' || $self->user('cc') eq 'BR';	
	$doc->createElement('contact:pc', $addr, $cep);
	$doc->createElement('contact:cc', $addr, $self->service('dados','registrobr_cc') || $self->user('cc'));
	
	my $voice = $doc->createElement('contact:voice', $c_create, Controller::frmt($self->service('dados','registrobr_telefone') || $self->user('telefone'),"epp_phone",cc => $self->country_code($self->service('dados','registrobr_cc') || $self->user('cc'))->{'code'}));
	$doc->createElement('contact:email', $c_create, $self->service('dados','registrobr_email') || ${ $self->user('email') }[0]);

	$doc->createElement('brorg:organization', $br_create, Controller::frmtCPFCNPJ($self->service('_registrobr_orgid')));
	my $br_contact = $doc->createElement('brorg:contact', $br_create, uc $self->service('dados','CIDBR'));
	$br_contact->setAttribute('type', 'admin');
	$doc->createElement('brorg:responsible', $br_create, $self->service('dados','registrobr_name') || $self->user('name'));

	return $doc->serialize(0);#1 for debug	
}

sub Org_Info {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $info = $doc->createElement('info', 'command');
	my $extension = $doc->createElement('extension', 'command');
	
	my $c_info = $doc->createElementNS('contact:info', $info);
	my $br_info = $doc->createElementNS('brorg:info', $extension);
	
	$doc->createElement('contact:id', $c_info, $self->num($self->service('_registrobr_orgid')));
	$doc->createElement('brorg:organization', $br_info, Controller::frmtCPFCNPJ($self->service('_registrobr_orgid')));

	return $doc->serialize(0);#1 for debug
}

#Contacts
sub Contact_Check {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $check = $doc->createElement('check', 'command');
	
	my $c_check = $doc->createElementNS('contact:check', $check);
	$doc->createElement('contact:id', $c_check, uc $self->service('dados','CIDBR'));
	
	return $doc->serialize(0);#1 for debug
}

sub Contact_Create {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $create = $doc->createElement('create', 'command');
		
	my $c_create = $doc->createElementNS('contact:create', $create);
	$doc->createElement('contact:id', $c_create, 'CTRL'); #Nao aplicavel a registro.br
	
	my $postal = $doc->createElement('contact:postalInfo', $c_create);
	$postal->setAttribute('type', 'loc');
	$doc->createElement('contact:name', $postal, $self->service('dados','registrobr_name') || $self->user('name'));
	
	my $addr = $doc->createElement('contact:addr', $postal);
	$doc->createElement('contact:street', $addr, $self->service('dados','registrobr_address') || $self->user('endereco'));
	$doc->createElement('contact:street', $addr, $self->service('dados','registrobr_number') || $self->user('numero'));
	$doc->createElement('contact:city', $addr, $self->service('dados','registrobr_city') || $self->user('cidade'));
	$doc->createElement('contact:sp', $addr, $self->service('dados','registrobr_state') || $self->user('estado'));
	my $cep = $self->service('dados','registrobr_CEP') || $self->user('cep');
	$cep =~ s/^(\d{5})(\d{3})$/$1-$2/ if $self->service('dados','registrobr_cc') eq 'BR' || $self->user('cc') eq 'BR';
	$doc->createElement('contact:pc', $addr, $cep);
	$doc->createElement('contact:cc', $addr, $self->service('dados','registrobr_cc') || $self->user('cc'));

	my $voice = $doc->createElement('contact:voice', $c_create, Controller::frmt($self->service('dados','registrobr_telefone') || $self->user('telefone'),"epp_phone",cc => $self->country_code($self->service('dados','registrobr_cc') || $self->user('cc'))->{'code'}));
	$doc->createElement('contact:email', $c_create, $self->service('dados','registrobr_email') || ${ $self->user('email') }[0]);

	return $doc->serialize(0);#1 for debug	
}

sub Contact_Info {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $info = $doc->createElement('info', 'command');
	
	my $c_info = $doc->createElementNS('contact:info', $info);
	$doc->createElement('contact:id', $c_info, uc $self->service('dados','CIDBR'));

	return $doc->serialize(0);#1 for debug
}

sub Poll {
	my ($self) = shift;
	my $doc = newDocument Controller::Registros::RegistroBR::Epp;
	
	my $poll = $doc->createElement('poll', 'command');
	$poll->setAttribute('op', $_[0]); #req || ack
	$poll->setAttribute('msgID', $_[1]) if $_[0] eq 'ack';
	
	return $doc->serialize(0);#1 for debug
}

#overwrite
sub createElementNS {
	my ($self) = shift;
	my ($root,$ext) = split(':', $_[0]);
	
	my $created = $self->createElement("$root:$ext", $_[1]);	
	$created->setNamespace("$EPP_URN:$root-1.0", $root);
	$created->setAttributeNS($SCHEMA_URI, 'schemaLocation', "$EPP_URN:$root-1.0 $root-1.0.xsd");
	
	return $created;
}

sub createElement {
	my ($self) = shift;
	
	my @args = ($_[0], $_[1]);
	$args[2] = Controller::iso2utf8($_[2]) if defined $_[2];
	return $self->SUPER::createElement(@args);
}
1;
#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2013
package Controller::_HelpDesk;

require 5.008;
require Exporter;

use base Controller; #Exemplo de inherit

use vars qw(@ISA $VERSION);

$VERSION = "0.1";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	#Depende do Controller
	my $self = new Controller( @_ );
	%$self = (
		%$self,
		'ERR' => undef,
	);
	
	bless($self, $class);
	
	return $self;
}

#TODO Refactor
*ticket_new = \&newTicket; #Compat old way
sub newTicket {
	@_=@_;
	my ($self) = shift;
	my ($method,$owner,$email,$depname,$subject,$text,$notes,$visible,$nivel,$author);
	my %params;
	
	if (ref $_[0] eq 'HASH') {
		%params = $_[0];
	} else {
		($method,$owner,$email,$depname,$subject,$text,$notes,$visible,$nivel,$author) = @_;
		$params{'Method'} = $method;
		$params{'Owner'} = $owner;
		$params{'Email'} = $email;
		$params{'Department'} = $depname;
		$params{'Subject'} = $subject;
		$params{'Body'} = $text;
		$params{'Notes'} = $notes;
		$params{'VisibleNote'} = $visible;
		$params{'Priority'} = $nivel;
		$params{'Author'} = $author;		
	}
	
	#Defaults
	$params{'AwaitingStaff'} ||= 1;
	
	#owner 0 - user 1 - staff 2 - system 3 - staff action
	#visible 1 - visible 0 - hidden 
	Controller::html2text(\$params{'Subject'});
	Controller::html2text(\$params{'Body'});
	Controller::html2text(\$params{'Notes'});
	
    my @chars =   ("A" .. "Z", "a" .. "z", 0 .. 9);          
	my $key   =  $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)];          			
	$params{'Email'} = $self->user('emails') unless $params{'Email'};

	my $curtime = $self->calendar('timestamp');	
	my ($dep) = $self->escolhedep($params{'Department'});
	my $cid = $self->execute_sql(344,'A',$self->uid,$params{'Email'},$params{'Priority'},$self->sid,$dep,$params{'Subject'},$params{'Body'},$self->calendar('hdtime'), undef, undef, $params{'Method'}, $curtime, $curtime, $params{'AwaitingStaff'}, "0", "0", "0");
	$self->execute_sql(382,$params{'Owner'},$params{'VisibleNote'},'A',$cid,$params{'Author'},$self->calendar('hdtime'),$key,$params{'Notes'},$ENV{'REMOTE_ADDR'}) if $cid && $params{'Notes'};
	
	return $cid;
}

sub escolhedep {
	my ($self,$nomedep) = @_;
	my $dep;

	my $sth = $self->select_sql(265,$nomedep);
	while (my $ref = $sth->fetchrow_hashref) {
		next if $self->user('level') !~ m/(^|::)$ref->{'level'}(::|$)/; #Usuario deve ter acesso a empresa
		$dep = $ref->{'id'} if $self->setting('ddep'.lc $self->plan('tipo')) =~ m/(^|::)$ref->{'level'}(::|$)/;#Empresa que vai responder por padrao caso nao tenha nenhum dep
		$dep = $ref->{'id'} if $self->user('level') =~ m/(^|::)$ref->{'level'}(::|$)/; #Pegar primeiro por usuario
		$dep = $ref->{'id'} if $self->plan('level') =~ m/(^|::)$ref->{'level'}(::|$)/; #Plano deve ter acesso a empresa 
	}
	
	return $dep;
} 

1;
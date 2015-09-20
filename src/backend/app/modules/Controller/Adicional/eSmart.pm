#!/usr/bin/perl
# Use: Module
# Controller - is4web.com.br
# 2013
#Pacote personalizado para automatizar serviços de terceiros
package Controller::Adicional::eSmart;

require 5.008;
require Exporter;

use base Controller::Adicional;

use vars qw(@ISA $VERSION $DEBUG $ERR $emailtxt);

$VERSION = "0.1";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	my $self = new Controller::Adicional( @_ );	
	%$self = (
		%$self,
		'ERR' => undef,
	);
	
	bless($self, $class);

	return $self;
}

sub cronAction {
	my $self = shift;
	return 0 if $self->error;
		
	#definir data de inicio hoje se estiver criando
	if ($self->service('action') eq $self->SERVICE_ACTION_CREATE) {
		$self->execute_sql(760, $self->today, $self->sid);
		$self->activate_service;
	}	
	
	#Define que não sabe o que fazer
	return undef;	
}

sub manual_action {
	my $self = shift;
	return 0 if $self->error;

	$self->template('tarefa', $self->action($self->service('action'))); 
	$self->template('referencia', $self->sid);
	$self->template('dominio', $self->service('dominio'));
	$self->template('plano', $self->plan('nome'));
	$self->template('servidor', $self->server('nome'));
									
	$self->messages(User => $self->uid, To => 'test@top.level.domain', From => $self->setting('adminemail'), Subject => ['sbj_manual_action', $self->template('tarefa')] , txt => "cron/action");
	$self->execute_sql(qq|UPDATE `servicos` SET `action` = "N" WHERE `id` = ?|,$self->sid) unless $self->error;
	
	$self->set_error($self->lang(7)) unless $self->error;
	return 0;#pra não executar as ações de como se tivesse feito
}
1;
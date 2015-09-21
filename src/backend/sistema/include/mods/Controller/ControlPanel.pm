#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008
package Controller::ControlPanel;

require 5.008;
require Exporter;
#use strict;
use base Controller::Services; #Exemplo de inherit

use vars qw(@ISA $VERSION);

#@ISA = qw(Controller);
#@EXPORT = qw();
#@EXPORT_OK = qw();

$VERSION = "0.1";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	#Depende do Controller
	my $self = new Controller::Services( @_ );
	%$self = (
		%$self,
		'ERR' => undef,
	);
	
	bless($self, $class);
	
	return $self;
}

sub manual_action {
	my $self = shift;
	return 0 if $self->error;

	$self->template('tarefa', $self->action($self->service('action'))); 
	$self->template('referencia', $self->sid);
	$self->template('dominio', $self->service('dominio'));
	$self->template('plano', $self->plan('nome'));
	$self->template('servidor', $self->server('nome'));
									
	$self->messages(User => $self->uid, To => $self->setting("contas"), From => $self->setting('adminemail'), Subject => ['sbj_manual_action', $self->template('tarefa')] , txt => "cron/action");
	#TODO $self->sms;#sms ( User => "$iuef->{'username'}", Txt => "/cron/action");	
	$self->execute_sql(qq|UPDATE `servicos` SET `action` = "N" WHERE `id` = ?|,$self->sid) unless $self->error;
	
	#return $self->error ? 0 : 1;
	$self->set_error($self->lang(7)) unless $self->error;
	return 0;#pra não executar as ações de como se tivesse feito
}

sub email_txt {
	return '';
}

sub AUTOLOAD { #Holds all undef methods
	my $self = $_[0];
	my $type = ref($self) or die "$self is not an object";

	return undef;#Simular erro
}
1;
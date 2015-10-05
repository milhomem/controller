#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2013
package Controller::_Adicional;

require 5.008;
require Exporter;
use base Controller::Services;

use vars qw(@ISA $VERSION);

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
	
	my $status = $self->Action2Status($self->service('action')); 

	$self->execute_sql(763,$status,$self->sid) if $status && $self->setting('auto_manual'); 
	$self->execute_sql(745,$self->SERVICE_ACTION_NOTHINGTODO,$self->sid);

	my $from = $self->return_sender('User');    
	$self->messages(User => $self->uid, To => $self->setting('contas'), From => $from, Subject => ['sbj_manual_action', $self->template('tarefa')], txt => 'cron/action');
	
	$self->set_error($self->lang(7));
	$self->logcron($self->error);
	return 0;
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
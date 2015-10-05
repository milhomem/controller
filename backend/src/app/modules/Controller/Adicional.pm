#!/usr/bin/perl
#
# M�dulo personalizado
# Controller - is4web.com.br
# 2013
# Modulo personalizado que automatiza o
# processo de servi�os que n�o tem automa��o
# enviando um email para a��o manual de um respons�vel
# substituindo o comportamento padr�o
package Controller::Adicional;
use base Controller::_Adicional;

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

	my $from = $self->return_sender('User');    
	$self->messages(User => $self->uid, To => $self->setting('contas'), From => $from, Subject => ['sbj_manual_action', $self->template('tarefa')], txt => 'cron/action');
	
	$self->set_error($self->lang(7));
	$self->logcron($self->error);
	return 0;
}
1;
#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008
package Controller::Registros;

require 5.008;
require Exporter;
use base Controller;

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

sub _domain {
	my ($self,$domain) = @_; 

	$self->{'domain'} = $domain;
	$self->{'domain'} =~ s/^www\.//g;

	return $self->error ? 0 : 1;
}

sub TLD {
	my ($name,$dot) = @_;
	
	#$name =~ m/\.(com|net|org|biz|info|us)$/; #supported tlds
	$name =~ m/\.(com|net|edu|mil|gov|pro|aero|coop|name|int|museum|org|biz|info|(?#	#internacionais
			 )[ac-z]{2}|b[a-qs-z]{2}|(?#												#gerais
			 )(a[grdt][rtmvqo]|am|b[iml][od]g?|c[ino][mgto]p?|e[cntdsm][ngiupco]|f[nosal][dtro]g?|(?#	#brasileiros excluindo .br
			 )fm|g[1og][2vf]|i[mn][bdf]|j[ou][rs]|l[e][l]|m[aieu][ltds]|n[eot][trm]|o[rd][go]|(?#	#brasileiros excluindo .br
			 )p[spr][ifocg]|q[s][l]|r[e][c]|s[lr][gv]|t[mur][prd]|tv|v[el][to]g?|z[l][g]|wiki)\.br(?#	#brasileiros excluindo .br
			 ))$/i;

	return $dot.$1;	
}

sub nameservers { return undef; };

sub manual_action {
	my $self = shift;
	return 0 if $self->error;

	$self->template('tarefa', $self->service('action'));
	$self->template('referencia', $self->sid);
	$self->template('dominio', $self->service('dominio'));
	$self->template('plano', $self->plan('nome'));
	$self->template('servidor', $self->server('nome'));
									
	$self->messages(User => $self->uid, To => $self->setting("contas"), From => $self->setting('adminemail'), Subject => ['sbj_manual_action', $self->service('action')] , txt => "cron/action");
	$self->execute_sql(qq|UPDATE `servicos` SET `action` = "N" WHERE `id` = ?|,$self->sid) unless $self->error;
	
	#return $self->error ? 0 : 1;
	$self->set_error($self->lang(7));
	return 0;
}

sub user_login {
	my $self = shift;
	my $logged;
	return $logged ? 1 : $self->error;
}

1;
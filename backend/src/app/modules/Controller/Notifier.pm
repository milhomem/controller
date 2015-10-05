#!/usr/bin/perl
# Use: Internal
# Controller - is4web.com.br
# 2011
#Pacote personalizado
package Controller::Notifier;

require 5.008;
require Exporter;

use vars qw(@ISA $VERSION $DEBUG $ERR);

@ISA = qw(Controller);
#our @EXPORT = qw();
#our @EXPORT_OK = qw();

$VERSION = "1.0";

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

#######################################
# Implementa as Notificações		  #
#######################################
sub fire {
	my ($self) = shift;
	
	#call
	eval $_[0].'($self);';
	die $@ if $@;
}

sub event {
	my ($self) = shift;
	
	$self->{_notifier} = shift;
	
	return if $self->error;
	fire($self,$self->{_notifier}{'name'});
	$self->clear_error;			
}
sub notifier { return $_[0]->{_notifier}; }

sub email_arrive {
	my ($self) = shift;
	my %opts = %{ notifier($self) };
	
	if ($opts{'object'} eq 'call') {
		$self->callid($opts{'identifier'});	
		$self->template('callid',$self->callid);	
		#New call
		if ($opts{'typeof'} eq 'new') {
			$self->sid($self->call('service'));
			unless ($self->sid) { #try to find if have any service
				$self->sid(search_sid($self,'dados','Segmentado','%'));
			}			
			if ($self->sid > 0) {
				$emailSegmento = 'segmentoX@domain.tld' if $self->service('dados','Segmentado') =~ m/Segmento X/i;
				my @tos = ($emailSegmento, 'semprecopiado@domain.tld');
				my $to = join ',', grep { $self->is_valid_email($_) } @tos; 
				if ($to) {
					$self->template('tarefa','Ticket');
					$self->template('referencia',$self->callid);
					$self->template('tid',$self->callid);
					$self->template('tassunto',$opts{'email'}{'subject'});
					$self->template('response',$opts{'email'}{'body'});
					$self->template('url',$self->setting('baseurl').'/staff.cgi?do=ticket&cid='.$self->callid);
					
					$self->messages(To => $to, From => $self->setting('adminemail'), Subject => ['sbj_alert_newticket', $self->service('dominio')] , txt => 'newtickets');
				} 
			}
		} elsif ($opts{'typeof'} eq 'answer') {
			foreach my $staffid ($self->followers) {
				$self->staffid($staffid);
				$self->template('tarefa','Ticket');
				$self->template('referencia',$opts{'email'}{'body'});
				$self->template('url',$self->setting('baseurl').'/staff.cgi?do=ticket&cid='.$self->callid);				
				$self->messages(To => $self->staff('email'), From => $self->setting('adminemail'), Subject => ['sbj_alert_response', $self->callid] , txt => 'notify');	
				$self->nice_error() if $self->error; #Boa prática para loops			
			}
		}
	}
}

sub helpdesk {
	my ($self) = shift;
	my %opts = %{ notifier($self) };
	
	if ($opts{'object'} eq 'call') {
		$self->callid($opts{'identifier'});
		$self->template('callid',$self->callid);
		#New call
		if ($opts{'typeof'} eq 'new') {
			#Servico associado a um gerente de contas
			$self->sid($self->call('service'));
			unless ($self->sid) { #try to find if have any service
				$self->sid(search_sid($self,'dados','Gerente','%'));
			}			
			if ($self->sid > 0) {
				my @tos = split ',', gerentes_email($self);
				my $to = join ',', grep { $self->is_valid_email($_) } @tos; 
				if ($to) {
					$self->template('tarefa','Ticket');
					$self->template('referencia',$self->callid);
					$self->template('tid',$self->callid);
					$self->template('tassunto',$opts{'message'}{'subject'});
					$self->template('response',$opts{'message'}{'body'});
					$self->template('url',$self->setting('baseurl').'/staff.cgi?do=ticket&cid='.$self->callid);
					
					$self->messages(To => $to, From => $self->setting('adminemail'), Subject => ['sbj_alert_newticket', $self->service('dominio')] , txt => 'newtickets');
				} 
			}
		} elsif ($opts{'typeof'} eq 'answer') {
			foreach my $staffid ($self->followers) {
				$self->staffid($staffid);
				$self->template('tarefa','Ticket');
				$self->template('referencia',$opts{'message'}{'body'});	
				$self->template('url',$self->setting('baseurl').'/staff.cgi?do=ticket&cid='.$self->callid);		
				$self->messages(To => $self->staff('email'), From => $self->setting('adminemail'), Subject => ['sbj_alert_response', $self->callid] , txt => 'notify');
				$self->nice_error() if $self->error; #Boa prática para loops				
			}
		}
	}
}

sub alerts {
	my ($self) = shift;
		
	my %opts = %{ notifier($self) };
	
	if ($opts{'object'} eq 'service') {
		$self->sid($opts{'identifier'});
		$self->template('sid',$self->sid);
        
        #Copia de avisos de bloqueio
        if ($opts{'action'} eq 'B') {
            if($self->service('tipo') eq 'Dedicado') {
                my ($pdate,$bdate,$rdate) = $self->exec_dates;
                if (($bdate - $self->today()) == 1) {
                    my $dominio = $self->service('dominio');
                    $self->messages( To => 'copiado@domain.tld', From => $self->setting('adminemail'), Subject => "Alerta de bloqueio de Dedicado 24h ($opts{'identifier'})", Body => "Servico $opts{'identifier'} ($dominio) sera bloqueado em 24h!");
                }
            }
        } 

		if ($opts{'typeof'} eq 'exec') {
			return undef;
		} elsif ($opts{'typeof'} eq 'warn') {
			return undef;
		}
	}
}

#######################################
# Interface de configuração			  #
#######################################
sub search_sid {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'search_service')) and return unless $_[0] || $_[1];
	my $op = '=';
	my $value = $_[1];
	if ($_[0] eq 'dados') {
		$op = 'LIKE';
		$value = '%'."$_[1] : $_[2]".'::%';
	}	 
	
	my $sth = $self->select_sql(qq|SELECT `id` FROM `servicos` WHERE `username` = ? AND `$_[0]` $op ?|,$self->uid,$value);
	return 0 if $sth->rows < 1;
	
	my ($id) = $sth->fetchrow_array if $sth;
    $self->finish;
    
	return $self->error ? 0 : $id;
}

1;
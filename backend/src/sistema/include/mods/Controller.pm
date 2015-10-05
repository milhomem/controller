#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2007 - 2011
package Controller;

require 5.008;
require Exporter;
#use strict;

use vars qw(@ISA $VERSION $INSTANCE %SWITCH);

#CONTROLLER
use Controller::DBConnector;
use Controller::SQL;
use Controller::LOG;
use Controller::Date;
use Controller::iUtils;
use Controller::Is;
use Controller::Mail;
#use Controller::Financeiro;
use Error; #TODO ver pra q e usar neh
use File::Find;
use Scalar::Util qw(looks_like_number);
#use open ':utf8', ':std';

#Desta forma eu abro o Controller e tenho todos os modulos, é melhor escolher o modulo e ele conter o controller: @ISA = qw( Controller::Date Controller::DBConnector Controller::LOG Controller::Date Controller::iUtils Controller::Registros Controller::Financeiro Exporter);
@ISA = qw( Controller::Date Controller::DBConnector Controller::SQL Controller::LOG Controller::iUtils Controller::Is Controller::Mail Exporter); #modulos básicos
#@EXPORT = qw();
#@EXPORT_OK = qw();

$VERSION = "2.0";
=pod
########### ChangeLog #######################################################  VERSION  #
=item variable																#			#
- Added										                                #   1.6     #
=item constant																#			#
- Added	accurancy							                                #   1.7     #
=item staffGroups															#			#
- Added	staffGroups							                                #   1.9     #
=item constant																#			#
- Added	constants 							                                #   2.0     #
#############################################################################           #
=cut
##CONSTANTS##
use constant {
	TICKETS_OWNER_USER => 0,
	TICKETS_OWNER_STAFF => 1,
	TICKETS_OWNER_SYSTEM => 2,
	TICKETS_OWNER_ACTION => 3,
	TICKETS_METHOD_SYSTEM => 'ss',
	TICKETS_METHOD_HD => 'hd',
	TICKETS_METHOD_EMAIL => 'em',
	TICKETS_METHOD_CALL => 'cc',
	VISIBLE => 1,
	HIDDEN => 0,
	SERVICE_STATUS_BLOQUEADO => 'B',
	SERVICE_STATUS_CONGELADO => 'P',
	SERVICE_STATUS_CANCELADO => 'C',
	SERVICE_STATUS_FINALIZADO => 'F',
	SERVICE_STATUS_TRAFEGO => 'T',
	SERVICE_STATUS_ESPACO => 'E',
 	SERVICE_STATUS_ATIVO => 'A',
	SERVICE_STATUS_SOLICITADO => 'S',
	SERVICE_ACTION_CREATE => 'C',
	SERVICE_ACTION_MODIFY => 'M',
	SERVICE_ACTION_SUSPEND => 'B',
	SERVICE_ACTION_SUSPENDRES => 'P',
	SERVICE_ACTION_REMOVE => 'R',
	SERVICE_ACTION_ACTIVATE => 'A',
	SERVICE_ACTION_RENEW => 'A',
	SERVICE_ACTION_NOTHINGTODO => 'N',	
	SERVICE_ACTION_TRAFEGO => 'T',
	SERVICE_ACTION_ESPACO => 'E',	
	INVOICE_STATUS_PENDENTE => 'P',
	INVOICE_STATUS_QUITADO => 'Q',
	INVOICE_STATUS_CANCELED => 'D',
	INVOICE_STATUS_CONFIRMATION => 'C',
	TABLE_STAFFS => 'staff',
	TABLE_USERS => 'users',
	TABLE_SERVICES => 'servicos',
	TABLE_INVOICES => 'invoices', #TODO COLOCAR NOME DE TABELAS COM CONSTANTES
	TABLE_ACCOUNTS => 'cc',
	TABLE_BALANCES => 'saldos',
	TABLE_CREDITS => 'creditos',
	TABLE_CALLS => 'calls',
	TABLE_NOTES => 'notes',
	TABLE_CREDITCARDS => 'cc_info',
	TABLE_PLANS => 'planos',
	TABLE_PAYMENTS => 'pagamento',
	TABLE_FORMS => 'formularios',
	TABLE_STATS => 'stats',	
	TABLE_PERMS => 'security',
	TABLE_PERMSGROUP => 'securitygroups',
	TABLE_SERVERS => 'servidores',
	TABLE_SETTINGS => 'settings',
	TABLE_USERS_CONFIG=> 'users_config',
	VALOR_M => 30,
	VALOR_A => 360,
	VALOR_D => 1,
	VALOR_U => -1,
	accuracy => '%.5f',
};

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;

	#Provide a unique instance
	$INSTANCE and return($INSTANCE);
	
	my $self = { @_ };
	%{ $self->{configs} } = @_; 
	my $log = Controller::LOG->new(@_); 
	%$self = (
		%$self,
		%$log,
	);
	bless($self, $class);
	$INSTANCE = $self; #cache instance

	$SIG{'__DIE__'} = sub { $self->traceback($_[0]); };	
	$self->connect() || return $self;	
	$self->_setswitchs;
	$self->_settings;#Init settings
	$self->_setlang($self->setting('language')); #set default language;
	$self->_setskin($self->setting('skin'));#Init default interface settings
	$self->_setCGI;
	$self->_setqueries;
	$self->_country_codes;
	$self->_feriados;
	$self->_templates;
	$self->get_time;#Init time

	return $self;
}

sub reDie {
	my $self = shift;
	$SIG{'__DIE__'} = sub { $self->traceback($_[0]); };
}

sub configs {
	my $self = shift;
	return %{ $self->{configs} };
}

# Abolir esse uso
#sub _username {
#	my ($self) = shift;
#
#	$self->{'username'} = shift;
#
#	return 1;
#}

sub error_code {
	my $self = shift;
	return $self->{'errorCode'}=undef unless $self->error;
	$self->{'errorCode'} = $_[0] if $_[0] >= 0 && !$self->{'errorCode'} && $self->error && $Controller::SWITCH{skip_error} != 1;
	return $self->{'errorCode'};
}

sub set_error {
	my $self = shift;
	$self->{ERR} = "@_" if "@_" ne "" && !$self->error && $Controller::SWITCH{skip_error} != 1;
	return 0; #para poder utilizar com o return $self->set_error, assim se está retornando erro deve voltar 0
}

#TODO fazer todo {ERR} virar error e {ERR} = virar set_error
sub error { #TODO modificar o erro pra ser o cara q so mostra o erro e nao apaga
	my $self = shift;
	return $self->{ERR};
}

sub clear_error {
	my $self = shift;
	my $handle = $self->{ERR};
	$self->{ERR} = undef; #Error Acknowledge
	return $handle;
}

sub nice_error {
	my $self = shift;
	return undef unless $self->error;

	local $Controller::SWITCH{skip_error} = 1;
    # Skip the first frame [0], because it's the call to dotb.
    # Skip the second frame [1], because it's the call to die, with redirection
    my $frame = 0;
    my $tab = 1;
    while (my ($package, $filename, $line, $sub) = caller($frame++)) {
        if ($package eq 'main') {
            $sub =~ s/main:://;
            push(@trace, trim("$sub() called from $filename on line $line"));
        } else {
        	return undef if $sub eq '(eval)'; #O Pacote tem direito de chamar um eval para fazer seu próprio handle de erro #CASO: cPanel::PublicAPI.pm  eval { require $module; } if ( !$@ ) { }; 
            push(@trace, trim("$package::$sub() called from $filename on line $line\n"));
        }
    }

	my $mess = "Traceback (most recent call last):\n";
	$mess .= join("\n", map { "  "x$tab++ . $_ } reverse(@trace) )."\n";
	$mess .= "Package error: ".$self->clear_error."\n";
		
	$self->logevent($mess);
	$self->email (To => $self->setting('controller_mail'), From => $self->setting('adminemail'), Subject => $self->lang('sbj_nice_error'), Body => "Error: $mess" );
	
	return $self->lang(1);
}

sub soft_reset {
	my $self = shift;  
	foreach (keys %$self) {
		delete $self->{$_} if $_ =~ m/^_current/;
	}
}

sub hard_reset {
	my $self = shift;  
	my $class = ref($self);
	my %configs = $self->configs;
	$INSTANCE = undef;
	$self = undef;
	$self = new Controller ( %configs ); 
#	bless($self, $class);
	return $self;
}
#save itens info
sub save {
	@_ = @_;
	my $self = shift;
	return if $self->error;
	return unless @{$_[2]};
	
	do { $self->set_error($self->lang(51,'save')); return undef; } unless @{$_[1]} == @{$_[2]} && @{$_[3]} == @{$_[4]};
	$self->execute_sql(qq|UPDATE `$_[0]` SET |.Controller::iSQLjoin($_[1],1,",")
					.qq| WHERE |.Controller::iSQLjoin($_[3],1,","), @{$_[2]}, @{$_[4]});
	
	return $self->error ? 0 : 1;
}

#Itens info
sub sid { #independente
	my $self = shift;
	$self->{_currentsid} = $self->num($_[0]) if exists $_[0];
	#nao tem logica verificar isso $self->set_error($self->lang(3,'sid')) if exists $_[0] && $_[0] ne $self->service('id');
	return $self->{_currentsid};
}

sub pid {#pode depender
	my $self = shift;
	if (exists $_[0]) { #Forçando um pid então não está cuidando de um serviço
		$self->{_currentpid} = $self->num($_[0]) ;
		$self->sid(0);#Liberando dependencia
	} else {
		#return $self->{_currentpid} = $self->service('servicos') if !$self->{_currentpid} && $self->sid;
		$self->{_currentpid} = $self->service('servicos') if $self->sid > 0;
		$self->set_error($self->lang(3,'pid')) if $self->{_currentpid} <= 0 && ($self->sid > 0);
	}
	return $self->{_currentpid};
}

sub uid { #Nao eh mais #uid(0) é o real username do servico
	my $self = shift;
	if (exists $_[0]) { #Forçando um uid então não está cuidando de um usuario
		$self->{_currentuid} = $self->num($_[0]);
		$self->sid(0);#Liberando dependencia
		$self->balanceid(0);
		$self->invid(0);
		$self->callid(0);		
	} else {
		$self->{_currentuid} = $self->service('username') if $self->sid > 0;
		$self->{_currentuid} = $self->balance('username') if $self->balanceid > 0;
		$self->{_currentuid} = $self->invoice('username') if $self->invid > 0;
		$self->{_currentuid} = $self->call('username') if $self->callid > 0 && $self->call('username') > 0;
		$self->set_error($self->lang(3,'uid')) if $self->{_currentuid} <= 0 && ($self->sid > 0 || $self->balanceid > 0 || $self->invid > 0 || ($self->callid > 0 && $self->call('username') > 0) );
	}
	return $self->{_currentuid};
}

sub srvid {#pode depender
	@_=@_;
	my $self = shift;
	if (exists $_[0]) {
		$self->{_currentsrvid} = $self->num($_[0]) ;
		$self->sid(0);#Liberando dependencia
	} else {
		$self->{_currentsrvid} = $self->service('servidor') if $self->sid > 0;
		$self->set_error($self->lang(3,'srvid')) if $self->{_currentsrvid} <= 0 && ($self->sid > 0);
	}	
	return $self->{_currentsrvid};
}

sub payid {#pode depender
	my $self = shift;
	if (exists $_[0]) {
		$self->{_currentpayid} = $self->num($_[0]) ;
		$self->sid(0);#Liberando dependencia
	} else {
		$self->{_currentpayid} = $self->service('pg') if $self->sid > 0;
		$self->set_error($self->lang(3,'payid')) if $self->{_currentpayid} <= 0 && ($self->sid > 0);
	}
	return $self->{_currentpayid};
}

sub callid {
	my $self = shift;
	$self->{_currentcallid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentcallid};
}

sub creditid {
	my $self = shift;
	$self->{_currentcreditid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentcreditid};
}

sub balanceid {
	my $self = shift;
	$self->{_currentbalanceid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentbalanceid};
}

sub actid {
	my $self = shift;
	$self->{_currentaccountid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentaccountid};
}

sub invid {
	my $self = shift;
	$self->{_currentinvoiceid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentinvoiceid};
}

sub ccid {
	my $self = shift;
	$self->{_currentccid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentccid};
}

sub tid {
	my $self = shift;
	$self->{_currenttid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currenttid};
}

sub staffid {
	my $self = shift;
	$self->{_currentstaffid} = $_[0] if exists $_[0];
	return $self->{_currentstaffid};
}

sub entid {
	my $self = shift;
	$self->{_currententid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currententid};
}

sub deptid {
	my $self = shift;
	$self->{_currentdeptid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentdeptid};
}

sub did {
	my $self = shift;
	$self->{_currentdid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentdid};
}

sub logmailid {
	my $self = shift;
	$self->{_currentlogmailid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentlogmailid};
}

sub bankid {
	my $self = shift;
	$self->{_currentbankid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentbankid};
}
sub formtypeid {
	my $self = shift;
	$self->{_currentformtypeid} = $self->num($_[0]) if exists $_[0];
	return $self->{_currentformtypeid};
}
##########################################
sub payment {
	my $self = shift;
	
	$self->get_payment unless exists $self->{payments}{$self->payid}{$_[0]} || exists $_[1];	
	$self->{payments}{$self->payid}{$_[0]} = $_[1] if exists $_[1];	
	return $self->{payments}{$self->payid}{$_[0]};
}

sub payments {
	my ($self) = shift;
	
	return $self->get_payments(1034);
}

sub service {
	@_ = @_;#See Pel Bug http://rt.perl.org/rt3/Public/Bug/Display.html?id=7508
	my $self = shift;
	return \%{$self->{services}{$self->sid}} unless exists $_[0]; #copy
	%{ $self->{services}{$self->sid}{changed} } = %{ $_[1] } if $_[0] eq 'changed' && exists $_[1];	
	return keys %{ $self->{services}{$self->sid}{changed} } if $_[0] eq 'changed';
	$self->get_service unless exists $self->{services}{$self->sid}{$_[0]} || $_[0] =~ m/^_/;	#Create data hash if not exist
	my $atual = $_[0] eq 'dados' ? $self->{services}{$self->sid}{$_[0]}{$_[1]} : $self->{services}{$self->sid}{$_[0]};
 	$self->{services}{$self->sid}{$_[0]}{$_[1]} = $_[2] if $_[0] eq 'dados' && exists $_[1] && exists $_[2];#special field		
	$self->{services}{$self->sid}{$_[0]} = $_[1] if exists $_[1] && $_[0] ne 'dados';
	if (looks_like_number($atual)) { # ==
		$self->{services}{$self->sid}{changed}{ $_[0] } = 1 if (exists $_[1] && $_[0] ne 'dados' && $atual != $_[1]) || (exists $_[2] && $_[0] eq 'dados' && $atual != $_[2]);
	} else { # eq
		$self->{services}{$self->sid}{changed}{ $_[0] } = 1 if (exists $_[1] && $_[0] ne 'dados' && $atual ne $_[1]) || (exists $_[2] && $_[0] eq 'dados' && $atual ne $_[2]);
	}	
#$self->logevent("\nDados:  ".join ',', keys %{ $self->{services}{$self->sid}{'dados'} });		
	#puta faz isso depois nao aki, return $self->action($self->{services}{$self->sid}{$_[0]}) if $_[0] eq 'action';  #special field 
	return $self->{services}{$self->sid}{$_[0]}{$_[1]} if $_[0] eq 'dados' && exists $_[1]; # "$_[1]" BUG de charset no campo de dados
	return $self->{services}{$self->sid}{$_[0]};
}

sub services {
	my ($self) = shift;
	$self->set_error($self->lang(3,'services')) and return unless $self->uid;
	
	return $self->get_services(781,$self->uid); #select * sobrescrevia alteracoes de runtime, se definisse um proximo, ele lia denovo e sobrescrevia pelo antigo
	
	#return grep {$self->{services}{$_}{'username'} == $self->uid} keys %{ $self->{services} };

}

sub serviceprop {
	my ($self) = shift;
	
	$self->get_serviceprop unless exists $self->{services}{$self->sid}{'properties'}{$_[0]} || exists $_[1];	#Create data hash if not exist
 	$self->{services}{$self->sid}{'properties'}{$_[0]}{$_[1]}{$_[2]} = $_[3] if $_[0] == 3 && exists $_[1] && exists $_[2] && exists $_[3];#special field
	$self->{services}{$self->sid}{'properties'}{$_[0]} = $_[1] if exists $_[1] && $_[0] != 3;
	return $self->{services}{$self->sid}{'properties'}{$_[0]}{$_[1]} if $_[0] == 3 && exists $_[1];
	return $self->{services}{$self->sid}{'properties'}{$_[0]};
}

sub servicesprop {
	my ($self,@sids) = @_;
	$self->set_error($self->lang(3,'servicesprop')) and return unless @sids;
	
	$self->get_servicesprop(824,join ',',@sids);
}

sub plan {
	my $self = shift;
	$self->get_plan unless exists $self->{plans}{$self->pid}{$_[0]} || exists $_[1];
	$self->{plans}{$self->pid}{$_[0]}{$_[1]} = $_[2] if $_[0] eq 'descontos' && exists $_[1]; 
	$self->{plans}{$self->pid}{$_[0]} = $_[1] if $_[0] ne 'descontos' && exists $_[1];
	return $self->{plans}{$self->pid}{$_[0]}{$self->service('pg')} if $_[0] eq 'descontos' && exists $_[1]; 
	return $self->{plans}{$self->pid}{$_[0]};
}

sub plans {
	my ($self) = @_;
	$self->set_error($self->lang(3,'plans')) and return unless $self->uid;

	return $self->get_plans(608,'%',$self->uid);	
}

sub server {
	my $self = shift;
	$self->get_server unless exists $self->{servers}{$self->srvid}{$_[0]} || exists $_[1];
	$self->{servers}{$self->srvid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{servers}{$self->srvid}{$_[0]};	
}

sub servers { #TODO REDO
	my ($self,@srvids) = @_;
	$self->set_error($self->lang(3,'servers')) and return unless @srvids;
	
	return $self->get_servers(45,join ',', map { $self->{servers}{$_}{'id'} } @srvids);
}

sub user {
	my $self = shift;
	my @__ = @_; #Protect from split and grep

	return \%{$self->{users}{$self->uid}} unless exists $__[0]; #copy
	%{ $self->{users}{$self->uid}{changed} } = %{ $__[1] } if $__[0] eq 'changed' && exists $__[1];
	return keys %{ $self->{users}{$self->uid}{changed} } if $__[0] eq 'changed';
	$self->get_user unless exists $self->{users}{$self->uid}{$__[0]} || $__[0] eq 'emails' || $__[0] =~ m/^_/;
	my $getter = $__[0] eq 'email' ? join(',', @{ $self->{users}{$self->uid}{$__[0]} }) : $self->{users}{$self->uid}{$__[0]};
	if (exists $__[1]) { #Setter
		my $setter = $__[0] eq 'email' ? join(',', grep { $self->is_valid_email($_) } split(/\s*?[,;]\s*?/,trim($__[1])) ) : $__[1];
		if (looks_like_number($getter)) { # ==
			$self->{users}{$self->uid}{changed}{ $__[0] } = 1 if $self->num($getter) != $self->num($setter);
		} else { # eq
			$self->{users}{$self->uid}{changed}{ $__[0] } = 1 if $getter ne $setter;
		}
		$self->{users}{$self->uid}{$__[0]} = $__[0] eq 'email' ? [ split(',',trim($setter)) ] : $setter;
	}	

	return join ',', @{ $self->user('email') } if $__[0] eq 'emails';
	#use Data::Dumper;
	#die Dumper \%{$self->{users}{$self->uid}} unless exists $__[1];
	return $self->{users}{$self->uid}{$__[0]};
}

sub user_config {
	my $self = shift;
	my @__ = @_; #Protect from split and grep

	return \%{$self->{users_config}{$self->uid}} unless exists $__[0]; #copy

	return keys %{ $self->{users_config}{$self->uid}{changed} } if $__[0] eq 'changed';
	$self->get_user_config unless exists $self->{users_config}{$self->uid}{$__[0]} || $__[0] =~ m/^_/;
	my $getter = $self->{users_config}{$self->uid}{$__[0]};
	if (exists $__[1]) { #Setter
		my $setter = $__[1];
		$self->{users_config}{$self->uid}{changed}{ $__[0] } = 1 if $getter ne $setter && $getter != $setter;
		$self->{users_config}{$self->uid}{$__[0]} = $__[1];
	}

	return $self->{users_config}{$self->uid}{$__[0]};
}

sub invoice {
	@_=@_;
	my $self = shift;
	return \%{$self->{invoices}{$self->invid}} unless exists $_[0]; #copy
	$self->get_invoice unless exists $self->{invoices}{$self->invid}{$_[0]} || exists $_[1];		
	$self->{invoices}{$self->invid}{$_[0]}{$_[1]} = $_[2] if $_[0] eq 'services' && exists $_[1] && exists $_[2];#special field
	$self->{invoices}{$self->invid}{$_[0]} = $_[1] if exists $_[1] && $_[0] ne 'services';
	return $self->{invoices}{$self->invid}{$_[0]}{$_[1]} if $_[0] eq 'services' && exists $_[1];
	return $self->{invoices}{$self->invid}{$_[0]};
}

sub invoices {
	my ($self) = shift;
	$self->set_error($self->lang(3,'invoices')) and return unless $self->uid;
	
	return $self->get_invoices(439,'%',$self->uid);
	#return grep {$self->{balances}{$_}{'username'} == $self->uid} keys %{ $self->{balances} };
}

sub account {
	my $self = shift;
	$self->get_account unless exists $self->{accounts}{$self->actid}{$_[0]} || exists $_[1];		
	$self->{accounts}{$self->actid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{accounts}{$self->actid}{$_[0]};
}

sub accounts {
	my $self = shift;
#	$self->set_error($self->lang(3,'accounts')) and return unless $self->uid;
		
	$self->get_accounts(424);
	
	return keys %{ $self->{accounts} };
}

sub credit {
	my $self = shift;
	$self->get_credit unless exists $self->{credits}{$self->creditid}{$_[0]} || exists $_[1];		
	$self->{credits}{$self->creditid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{credits}{$self->creditid}{$_[0]};
}

sub credits {
	my ($self) = shift;
	$self->set_error($self->lang(3,'credits')) and return unless $self->uid;
	
	return $self->get_credits(482,$self->uid);
}

sub balance {
	my $self = shift;
	$self->get_balance unless exists $self->{balances}{$self->balanceid}{$_[0]} || exists $_[1];		
	$self->{balances}{$self->balanceid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{balances}{$self->balanceid}{$_[0]};
}

sub balances {
	my ($self) = shift;
	$self->set_error($self->lang(3,'balances')) and return unless $self->uid;
	
	return $self->get_balances(450,'O',$self->uid);
	#return grep {$self->{balances}{$_}{'username'} == $self->uid} keys %{ $self->{balances} };
}

sub servicebalances {
	my ($self) = shift;
	$self->set_error($self->lang(3,'servicebalances')) and return unless $self->sid;
	
	return $self->get_balances(454,'O',$self->sid);
}

sub call {
	my $self = shift;
	$self->get_call unless exists $self->{calls}{$self->callid}{$_[0]} || exists $_[1];		
	$self->{calls}{$self->callid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{calls}{$self->callid}{$_[0]};
}

sub calls {
	my ($self) = shift;
	$self->set_error($self->lang(3,'calls')) and return unless $self->uid; #se tem sid vai ter uid
	
	return $self->get_calls(367,$self->sid) if $self->sid;
	return $self->get_calls(366,$self->uid) if $self->uid;
	return ();
}

sub followers {
	my $self = shift;
	$self->set_error($self->lang(3,'followers')) and return unless $self->callid;

	my $sth = $self->select_sql(380,$self->callid);	
	my @followers = map {@{$_}} @{ $sth->fetchall_arrayref() }; 
	$self->finish;
	
	return @followers;
}

sub following {
	my $self = shift;
	$self->set_error($self->lang(3,'following')) and return unless $self->staffid;

	my $sth = $self->select_sql(379,$self->staffid);
	my @following = map {@{$_}} @{ $sth->fetchall_arrayref() }; 
	$self->finish;
	
	return @following;
}

sub creditcard {
	my $self = shift;
	$self->get_creditcard unless exists $self->{creditcards}{$self->ccid}{$_[0]} || exists $_[1];		
	$self->{creditcards}{$self->ccid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{creditcards}{$self->ccid}{$_[0]};
}

sub creditcards {
	my $self = shift;
	$self->set_error($self->lang(3,'creditcards')) and return unless $self->uid;
	
	return $self->get_creditcards(855,$self->uid);
	
	#return keys %{ $self->{creditcards} };
}

sub creditcard_active {
	my $self = shift;
	$self->set_error($self->lang(3,'creditcard_active')) and return unless $self->uid;

	$self->get_creditcards(852,$self->tid,1,$self->uid);
	my ($ccid) = grep { $self->{creditcards}{$_}{'active'} == 1 && $self->{creditcards}{$_}{'tarifa'} == $self->tid && $self->{creditcards}{$_}{'username'} == $self->uid} keys %{ $self->{creditcards} };
	return $ccid;
}

sub tax {
	my $self = shift;
	$self->get_tax unless exists $self->{taxs}{$self->tid}{$_[0]} || exists $_[1];		
	$self->{taxs}{$self->tid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{taxs}{$self->tid}{$_[0]};
}

sub taxs {
	my $self = shift;
#	$self->set_error($self->lang(3,'taxs')) and return unless $self->uid;
		
	return $self->get_taxs(872);
	
	#return keys %{ $self->{taxs} };
}

sub enterprise {
	my $self = shift;
	$self->get_enterprise unless exists $self->{enterprises}{$self->entid}{$_[0]} || exists $_[1];		
	$self->{enterprises}{$self->entid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{enterprises}{$self->entid}{$_[0]};
}

sub enterprises {
	my $self = shift;
		
	return $self->get_enterprises(303);
	
	#return keys %{ $self->{enterprises} };
}

sub department {
	my $self = shift;
	$self->get_department unless exists $self->{departments}{$self->deptid}{$_[0]} || exists $_[1];		
	$self->{departments}{$self->deptid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{departments}{$self->deptid}{$_[0]};
}

sub departments {
	my $self = shift;
		
	return $self->get_departments(266);
	
	#return keys %{ $self->{departments} };
}

sub formtype {
	my $self = shift;
	$self->get_formtype unless exists $self->{formtypes}{$self->formtypeid}{$_[0]} || exists $_[1];		
	$self->{formtypes}{$self->formtypeid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{formtypes}{$self->formtypeid}{$_[0]};
}

sub staff {
	my $self = shift;
	$self->get_staff unless exists $self->{staffs}{$self->staffid}{$_[0]} || exists $_[1];		
	$self->{staffs}{$self->staffid}{$_[0]} = $_[1] if exists $_[1];
	return join ',', @{ $self->{staffs}{$self->staffid}{'email'} } if $_[0] eq 'emails';
	return $self->{staffs}{$self->staffid}{$_[0]};
}

sub staffGroups {
	my $self = shift;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_staffGroups')) and return unless $self->staffid;
	
 	my $sth = $self->select_sql(1083, $self->staffid);
	my @gids = map {@{$_}} @{ $sth->fetchall_arrayref() }; 
	$self->finish;
	
	return @gids;
}

sub groups {
	my $self = shift;
	return undef if $self->error;
		
 	my $sth = $self->select_sql(1084);
	my @gids = map {@{$_}} @{ $sth->fetchall_arrayref() }; 
	$self->finish;
	
	return @gids;
}

sub logmail {
	my $self = shift;
	$self->get_logmail unless exists $self->{logmails}{$self->logmailid}{$_[0]} || exists $_[1];		
	$self->{logmails}{$self->logmailid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{logmails}{$self->logmailid}{$_[0]};
}

sub logmails {
	my $self = shift;		
	return $self->get_logmails(163);
}

sub bank {
	my $self = shift;
	$self->get_bank unless exists $self->{banks}{$self->bankid}{$_[0]} || exists $_[1];		
	$self->{banks}{$self->bankid}{$_[0]} = $_[1] if exists $_[1];
	return $self->{banks}{$self->bankid}{$_[0]};
}

sub banks {
	my $self = shift;		
	return $self->get_banks(427);
}

sub perm {
	my $self = shift;
	
	my $id = $self->uid || $self->staffid;
	$self->set_error($self->lang(3,'perm')) and return unless $id;
	
	$self->get_perm unless exists $self->{perms}{$id};
	return $self->{perms}{$id}{$_[0]}{$_[1]}{$_[2]} || $self->{perms}{$id}{$_[0]}{'all'}{$_[2]} if exists $_[2];
	return \%{ $self->{perms}{$id}{$_[0]}{$_[1]} } if exists $_[1]; #copy
	return \%{ $self->{perms}{$id}{$_[0]} } if exists $_[0]; #copy
	return \%{ $self->{perms}{$id} }; #copy
}

sub perms {
	#my $self = shift;
	#my $id = $self->uid || $self->staffid;
	#$self->set_error($self->lang(3,'perms')) and return unless $id;
		
	#return keys %{$self->perm};
}
############################################
#Copy data
sub copy_service {
	my ($self,$source,$target) = @_;
	
	$self->sid($source);
	my $ref = $self->service;
	$self->sid($target);
	my $ref2 = $self->service;

	%$ref2 = %$ref;
	return $self->sid($source);
}

sub shadow_copy {
	my $self = shift;
	
	if ($_[0] eq 'services') {
		my $ref = $self->service;
		%{ $self->{'shadow'}{$_[0]}{$self->sid} } = %$ref;
	}

	return 1;
}

sub AUTOLOAD { #Holds all undef methods
	my $self = $_[0];
	my $type = ref($self) or die "$AUTOLOAD is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion
	
	#Determinar qual modulo usar e importar
	#use Modulo e chama a funcao, é melhor determinar pelos modulos dos planos, serve para caso
	#nao tenha buscar os padroes	
	if ($name =~ s/_shadow$//i) {
		use B::RecDeparse;
		my $deparse = B::RecDeparse->new;
	
		my $newsub = $deparse->coderef2text( eval "\\&Controller::$name" );
		$newsub =~ s/\$\$self{(.+?)}/\$self->{'shadow'}{$1}/g;
		#$newsub =~ s/\$\$self{(.+?)}/\$\$self{'shadow'}{$1}/g;
		$newsub =~ s/package.*//;

    	eval "sub func $newsub"; # the inverse operation

		return func(@_);		
	}
	
	if ($name =~ /registrar|renew|expire/i) {
		$self->manual_action;
		return $self->error ? 0 : 1;		
	}
	
	if ($name =~ /availdomain/i) { 
		return 1; #sempre disponivel, já que nao foi consultado
	}
	
	$self->set_error("$name not implemented");
	return undef;#Simular erro
}
############################################
sub lock_billing {
	my ($self) = shift;
	
	local $Controller::SWITCH{skip_log} = 1;
	my $date = exists $_[1] ? $_[1] : $self->today();
	my $time = exists $_[2] ? $_[2] : undef;
	$self->execute_sql(21,$self->uid,$date,$time) if $self->uid;
	
	return 1;
}

sub unlock_billing {
	my ($self) = shift;
	
	local $Controller::SWITCH{skip_log} = 1;
	$self->execute_sql(22,$self->uid) if $self->uid;
	
	return 1;
}

sub action {
	my $self = shift;
	my %act = ( 'C' => $self->lang("CREATE"),
				'M' => $self->lang("MODIFY"),
				'B' => $self->lang("SUSPEND"),
				'P' => $self->lang("SUSPENDRES"),
				'R' => $self->lang("REMOVE"),
				'A' => $self->lang("ACTIVATE"),
				'N' => $self->lang("NOTHINGTODO") );	
	
	return $act{uc shift};
}

sub valor {
	my ($self,$opt) = @_;
	if ($opt == 1) {
		return $self->VALOR_M if $self->plan('valor_tipo') eq 'M';			
		return $self->VALOR_A if $self->plan('valor_tipo') eq 'A';	
		return $self->VALOR_D if $self->plan('valor_tipo') eq 'D';
		return $self->VALOR_U if $self->plan('valor_tipo') eq 'U';
	} else {
		return $self->lang('Month') if $self->plan('valor_tipo') eq 'M';	
		return $self->lang('Year') if $self->plan('valor_tipo') eq 'A';	
		return $self->lang('Day') if $self->plan('valor_tipo') eq 'D';
		return $self->lang('Unique') if $self->plan('valor_tipo') eq 'U';
	}
	$self->set_error($self->lang(1003));
	die $self->lang(1003); #Valor tipo não reconhecido
}

sub installment {
	my $self = shift;
	my %inst = ( 'S' => $self->lang("INSTALLMENT_S"),
				'O' => $self->lang("INSTALLMENT_O"),
				'L' => $self->lang("INSTALLMENT_L"),
				'D' => $self->lang("INSTALLMENT_D") );	
	
	return $inst{uc shift};
}
#######################################
#data mount
sub mount_service {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		#precisa sim #next if $ref->{"servidor"} == 1; # Não há informações sobre o servidor nenhum
		my $sid = $ref->{'id'};
		push @ids_matched, $sid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			#next if $q eq 'id'; TODO deixar o id pra verificar consistencia, ver sub sid()
			if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
				$self->{'services'}{$sid}{lc $q} = $self->date($ref->{$q});
			} elsif ($q eq 'dados') {				
				$self->{'services'}{$sid}{lc $q} = undef;
				foreach (split("::",$ref->{$q})) {
					my ($col,$val) = split(" : ",$_);
					$self->{'services'}{$sid}{lc $q}{trim($col)} = trim($val);
				}
			} else {
				$self->{'services'}{$sid}{lc $q} = $ref->{$q};
			}
		}
	}
	return @ids_matched;
}

sub get_service {
	my ($self) = shift;
	return 0 if $self->error;
	
	$self->set_error($self->lang(3,'get_service')) and return unless $self->sid; 
	$self->select_sql(780,$self->sid);
	$self->mount_service;
	$self->finish;
#$self->logevent("Get DB: ".join ',', keys %{ $self->{services}{$self->sid}{'dados'} });    
	return $self->error ? 0 : 1;
}

sub get_services {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_services')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @services = $self->mount_service;
	$self->finish;
	
	return $self->error ? undef : @services;
}

sub mount_serviceprop {
	my ($self) = shift;

	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $sid = $ref->{'servico'};
		push @ids_matched, $sid;
		if ($ref->{'type'} == 3) {
			#4.90::3,4,5,6::2008|6.65::1,8::2009
			foreach ( split('\|',$ref->{'value'}) ) {
				my($val,$months,$year) = split('::',$_,3);
				#TODO Ajustar isso para ter valores diferente para cada mês. Valores em porcentagem também serem aceitos para variarem junto com o valor do plano.
				#Adicionado tipo 7				
				$self->{services}{$sid}{'properties'}{$ref->{'type'}}{$year} = {
					'value' => $val,
					'months' => [split ',', $months],
				}
			}
		} elsif ($ref->{'type'} == 7) {
			#{} hash dump
			$self->{services}{$sid}{'properties'}{$ref->{'type'}} = eval $ref->{'value'};
		} else {
			my $value = $self->num($ref->{'value'}) < 0 ? 0 : $self->num($ref->{'value'});
			$self->{services}{$sid}{'properties'}{$ref->{'type'}} = $value;
		}
	}
	
	return @ids_matched;
}

sub get_serviceprop {
	my ($self) = shift;
	return 0 if $self->error;	

	#types 1 - dias gratis 2 - Sem taxa de setup 3 - Descontos em meses 
	#4 - Nao se orientar pelo vc do usuario 5 - dias para finalizar 6 - fatura exclusiva	
	#7 - Valores +- por mes/ano % ou $
	$self->set_error($self->lang(3,'get_serviceprop')) and return unless $self->sid;
	
	$self->select_sql(824,$self->sid);
	$self->mount_serviceprop;
	$self->finish;
    
	return $self->error ? 0 : 1;	
}

sub get_servicesprop {
	my ($self,$sql,@params) = @_;
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'get_serviceprop')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @props = $self->mount_serviceprop;
	$self->finish;
	
	return $self->error ? undef : @props;
}

sub mount_plan {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $pid = $ref->{'servicos'};
		push @ids_matched, $pid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq 'servicos';
			$self->{'plans'}{$pid}{lc $q} = $ref->{$q};
		}
#isso nao existe, nao tem como acontecer		$self->{'plans'}{$pid}{'descontos'}{$ref->{'pg'}} = $ref->{'desconto'};
	}
	return @ids_matched;
}

sub get_plan {
	my ($self) = shift;
	return 0 if $self->error;
		
	$self->set_error($self->lang(3,'get_plan')) and return unless $self->pid;
	
	$self->select_sql(604,$self->pid);
	$self->mount_plan;
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_plans {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_plans')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @plans = $self->mount_plan;
	$self->finish;
	
	return $self->error ? 0 : @plans;
}

sub mount_tax {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $tid = $ref->{'id'};
		push @ids_matched, $tid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq 'id';
			$self->{'taxs'}{$tid}{lc $q} = $ref->{$q};
		}
	}
	return @ids_matched;
}

sub get_tax {
	my ($self) = shift;
	return 0 if $self->error;	

	#	
	$self->set_error($self->lang(3,'get_tax')) and return unless $self->tid;
	
	$self->select_sql(871,$self->tid);
	$self->mount_tax;
	$self->finish;
    
	return $self->error ? 0 : 1;	
}

sub get_taxs {
	my ($self,$sql,@params) = @_;
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'get_taxs')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @taxs = $self->mount_tax;
	$self->finish;
    
	return $self->error ? 0 : @taxs;	
}

sub mount_server {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $srvid = $ref->{'id'};
		push @ids_matched, $srvid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			$self->{'servers'}{$srvid}{lc $q} = $ref->{$q};
		}
	}
	return @ids_matched;
}

sub get_server {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_server')) and return unless $self->srvid;
	
	$self->select_sql(45,$self->srvid);
	$self->mount_server;
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_servers {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_servers')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @servers = $self->mount_server;
	$self->finish;
	
	return $self->error ? 0 : @servers;
}

sub mount_payment {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $payid = $ref->{'id'};
		push @ids_matched, $payid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			$self->{'payments'}{$payid}{lc $q} = $ref->{$q};
		}
	}	
	return @ids_matched;
}

sub get_payment {
	my ($self) = shift;
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'get_payment')) and return unless $self->payid;
	
	$self->select_sql(1030,$self->payid);
	my @payments = $self->mount_payment;
	$self->finish;
	
	return $self->error ? 0 : @payments;
}

sub get_payments {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_payments')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @payments = $self->mount_payment;
	$self->finish;
	
	return $self->error ? undef : @payments;
}

sub mount_user {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $uid = $ref->{'username'};
		push @ids_matched, $uid;
		
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "username";
			if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
				$self->{'users'}{$uid}{lc $q} = $self->date($ref->{$q});
			} elsif ($q eq 'email') {
				$self->{'users'}{$uid}{lc $q} = [ grep { $self->is_valid_email($_) } split(/\s*?[,;]\s*?/,trim($ref->{$q})) ];			
			} else {				
				$self->{'users'}{$uid}{lc $q} = $ref->{$q};
			}
		}
	}
	return @ids_matched;
}

sub mount_user_config {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while($sth and (my $ref = $sth->fetchrow_hashref())) {
		my $set = lc $ref->{'setting'};
		push @ids_matched, $set;
		
		$self->{'users_config'}{$ref->{'username'}}{$set} = $ref->{'value'};
	}
	return @ids_matched;
}

sub get_user {
	my ($self) = shift;
	return 0 if $self->error;
	
	$self->set_error($self->lang(3,'get_user')) and return unless $self->uid;

	$self->select_sql(680,$self->uid);
	my @users = $self->mount_user;
	$self->finish;
    
	return $self->error ? 0 : @users;
}

sub get_user_config {
	my ($self) = shift;
	return 0 if $self->error;
	
	$self->set_error($self->lang(3,'get_user_config')) and return unless $self->uid;

	$self->select_sql(681,$self->uid);
	my @configs = $self->mount_user_config;
	$self->finish;
    
	return $self->error ? 0 : @configs;
}

sub get_users {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_users')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @users = $self->mount_user;
	$self->finish;
	
	return $self->error ? undef : @users;
}

sub mount_invoice {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $invid = $ref->{'id'};
		push @ids_matched, $invid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
				$self->{'invoices'}{$invid}{lc $q} = $self->date($ref->{$q});
			} elsif ($q eq 'services') {
				$self->{'invoices'}{$invid}{lc $q} = {}; #Inicializando
				$self->{'invoices'}{$invid}{lc $q}{$2} = $1 while $ref->{$q} =~ m/(\d+?)x(\d+?) -\s?/g;
			} else {
				$self->{'invoices'}{$invid}{lc $q} = $ref->{$q};
			}
		}
	}
	return @ids_matched;
}

sub get_invoice {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_invoice')) and return unless $self->invid;
	
	$self->select_sql(437,$self->invid);
	$self->mount_invoice;
	$self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_invoices {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_invoices')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @invoices = $self->mount_invoice;
	$self->finish;
	
	return $self->error ? undef : @invoices;
}

sub mount_account {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $actid = $ref->{'id'};
		push @ids_matched, $actid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			if ($q eq 'agencia') {
				my ($pre,$pos) = split('-',$ref->{$q});
				$self->{'accounts'}{$actid}{lc ($q.'dv')} = $pos;
				$self->{'accounts'}{$actid}{lc $q} = $pre;
			} elsif ($q eq 'conta') {	
				my ($pre,$pos) = split('-',$ref->{$q});
				$self->{'accounts'}{$actid}{lc ($q.'dv')} =$pos;
				$self->{'accounts'}{$actid}{lc $q} =$pre;				
			} else {
				$self->{'accounts'}{$actid}{lc $q} = $ref->{$q};
			}
		}
	}
	return @ids_matched;
}

sub get_account {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_acccount')) and return unless $self->actid;
	
	my $sth = $self->select_sql(423,$self->actid);
	$self->mount_account;
	$self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_accounts {
	my ($self,$sql,@params) = @_;
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'get_accounts')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @accounts = $self->mount_account;
	$self->finish;
    
	return $self->error ? undef : @accounts;
}

sub mount_balance {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $bid = $ref->{'id'};
		push @ids_matched, $bid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			$self->{'balances'}{$bid}{lc $q} = $ref->{$q};
		}
	}
	return @ids_matched;
}

sub get_balance {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_balance')) and return unless $self->balanceid;
	
	$self->select_sql(449,$self->balanceid);
	$self->mount_balance;
	$self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_balances {
	my ($self,$sql,@params) = @_;
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'get_balances')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @balances = $self->mount_balance;
	$self->finish;
    
	return $self->error ? undef : @balances;
}

sub mount_credit {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $creditid = $ref->{'id'};
		push @ids_matched, $creditid;		
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			$self->{'credits'}{$creditid}{lc $q} = $ref->{$q};
		}
	}	
	return @ids_matched;
}

sub get_credit {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_credit')) and return unless $self->creditid;

	$self->select_sql(481,$self->creditid);
	$self->mount_credit;
	$self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_credits {
	my ($self,$sql,@params) = @_;
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'get_credits')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @credits = $self->mount_credit;
	$self->finish;
    
	return $self->error ? undef : @credits;
}

sub mount_call {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;

	while(my $ref = $sth->fetchrow_hashref()) {
		my $callid = $ref->{'id'};
		push @ids_matched, $callid;		
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			$self->{'calls'}{$self->callid}{lc $q} = $ref->{$q};
		}
	}	
	return @ids_matched;
}

sub get_call {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_call')) and return unless $self->callid;
    
	$self->select_sql(365,$self->callid);
	$self->mount_call;
	$self->finish;
	    
	return $self->error ? 0 : 1;
}

sub get_calls {
	my ($self,$sql,@params) = @_;
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'get_calls')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @calls = $self->mount_call;
	$self->finish;
    
	return $self->error ? undef : @calls;
}

sub mount_creditcard {
	my ($self) = shift;

	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $ccid = $ref->{'id'};
		push @ids_matched, $ccid;
		#preciso listar mesmo que esteja recusado next if $ref->{'active'} == -1; #recusado
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			if ($q =~ m/^(?:ccn|cvv2)$/) { #campos criptografados
				$self->{'creditcards'}{$ccid}{lc $q} = Controller::decrypt_mm($ref->{$q});
			} else {
				$self->{'creditcards'}{$ccid}{lc $q} = $ref->{$q};
			}
		}
		#TODO ajustar isso, esses langs nem eram pra existir
		# Vou mudar pra ficar um só cartão de cada tipo		
		my $status = $self->lang('Active') if $ref->{'active'} == 1;
		$status = $self->lang('Activating') if $ref->{'active'} == 2;
		$status = $self->lang('Deactivated') if $ref->{'active'} == 0;
		$status = $self->lang('Refused') if $ref->{'active'} == -1;
		$self->{'creditcards'}{$ccid}{'status'} = $status;
		#last if $ref->{'active'} == 1;#1= Ativo  -1= Recusado  0= Desativado  2= Ativando
	}
	return @ids_matched;
}

sub get_creditcard {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_creditcard')) and return unless $self->ccid;
	
	$self->select_sql(851,$self->ccid);
	$self->mount_creditcard;
	$self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_creditcards {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;

	$self->set_error($self->lang(3,'get_creditcards')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @creditcards = $self->mount_creditcard;
	$self->finish;
	
	return $self->error ? undef : @creditcards;
}

sub mount_formtype {
	my ($self) = shift;
	
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $id = $ref->{'id'};
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			if ($q eq 'properties') {
				#[1=30][3=4.90::3,4,5,6::2008|6.65::1,8::2009]
				foreach my $propertie ($ref->{$q} =~ /\[(.+?)\]/g) {
					my ($type,$value) = split('=',$propertie);
					$self->{'formtypes'}{$id}{'properties'}{$type} = $value;
					#repassar as info pra salvar, elas processada de nada ainda servem
#					if ($type == 3) {						
#						foreach ( split('\|',$value) ) {
#							my($val,$months,$year) = split('::',$_,3);
#							$self->{'formtypes'}{$id}{'properties'}{$type}{$year} = {
#								'value' => $val,
#								'months' => [split ',', $months],
#							}
#						}
#					} else {
#						my $value = $self->num($value) < 0 ? 0 : $self->num($value);
#						$self->{'formtypes'}{$id}{'properties'}{$type} = $value;
#					}
				}
			} elsif ($q eq 'planos') {
				$self->{'formtypes'}{$id}{lc $q} = [ split ',', $ref->{$q} ];
			} else {
				$self->{'formtypes'}{$id}{lc $q} = $ref->{$q};
			}			
		}
		
	}
}

sub get_formtype {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_formtype')) and return unless $self->formtypeid;
	
	$self->select_sql(1050,$self->formtypeid);
	$self->mount_formtype;
	$self->finish;
    
	return $self->error ? 0 : 1;
}

sub mount_staff {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $staffid = $ref->{'username'};
		push @ids_matched, $staffid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq 'username';
			$self->{'staffs'}{$staffid}{lc $q} = $ref->{$q};
		}
	}
	return @ids_matched;
}

sub get_staff {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_staff')) and return unless $self->staffid;
	
	$self->select_sql(331,$self->staffid);
	$self->mount_staff;
	$self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_staffs {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;

	$self->set_error($self->lang(3,'get_staffs')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @staffs = $self->mount_staff;
	$self->finish;
	
	return $self->error ? undef : @staffs;
}

sub mount_enterprise {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $entid = $ref->{'id'};
		push @ids_matched, $entid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			$self->{'enterprises'}{$entid}{lc $q} = $ref->{$q};
		}
	}
	return @ids_matched;
}

sub get_enterprise {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_enterprise')) and return unless $self->entid;
	
	$self->select_sql(304,$self->entid);
	$self->mount_enterprise;
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_enterprises {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_enterprises')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @enterprises = $self->mount_enterprise;
	$self->finish;
	
	return $self->error ? 0 : @enterprises;
}

sub mount_department {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $deptid = $ref->{'id'};
		push @ids_matched, $deptid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			$self->{'departments'}{$deptid}{lc $q} = $ref->{$q};
		}
	}
	return @ids_matched;
}

sub get_department {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_department')) and return unless $self->deptid;
	
	$self->select_sql(267,$self->deptid);
	$self->mount_department;
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_departments {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_departments')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @departments = $self->mount_department;
	$self->finish;
	
	return $self->error ? undef : @departments;
}

sub mount_discount {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $did = $ref->{'id'};
		push @ids_matched, $did;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
			$self->{'enterprises'}{$entid}{lc $q} = $ref->{$q};
		}
	}
	return @ids_matched;
}

sub get_discount {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_enterprise')) and return unless $self->entid;
	
	$self->select_sql(304,$self->entid);
	$self->mount_enterprise;
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_discounts {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_enterprises')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @enterprises = $self->mount_enterprise;
	$self->finish;
	
	return $self->error ? 0 : @enterprises;
}

sub mount_logmail {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $logmailid = $ref->{'id'};
		push @ids_matched, $logmailid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "id";
				if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
					$self->{'logmails'}{$logmailid}{lc $q} = $self->date($ref->{$q});
				} elsif ($q eq 'body') {
					$self->{'logmails'}{$logmailid}{lc $q} = $ref->{$q};
					$self->{'logmails'}{$logmailid}{lc $q} =~ s/\\(\W)/$1/g; #Emails antigos
				} else {			
					$self->{'logmails'}{$logmailid}{lc $q} = $ref->{$q};
				}
		}
	}
	return @ids_matched;
}

sub get_logmail {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_logmail')) and return unless $self->logmailid;
	
	$self->select_sql(164,$self->logmailid);
	$self->mount_logmail;
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_logmails {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_logmails')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @logmails = $self->mount_logmail;
	$self->finish;
	
	return $self->error ? 0 : @logmails;
}

sub mount_bank {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $bankid = $ref->{'codigo'};
		push @ids_matched, $bankid;
		foreach my $q (keys %{$sth->{NAME_hash}}) {
			next if $q eq "codigo";
			$self->{'banks'}{$bankid}{lc $q} = $ref->{$q};
		}
	}
	return @ids_matched;
}

sub get_bank {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'get_bank')) and return unless $self->bankid;
	
	$self->select_sql(426,$self->bankid);
	$self->mount_bank;
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_banks {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_banks')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @banks = $self->mount_bank;
	$self->finish;
	
	return $self->error ? 0 : @banks;
}

sub mount_perm {
	my ($self) = shift;
	
	my @ids_matched;
	my $sth = $self->last_select;
	while(my $ref = $sth->fetchrow_hashref()) {
		my $permid = $ref->{'username'};
		push @ids_matched, $permid;
		#foreach my $q (keys %{$sth->{NAME_hash}}) {
		#	next if $q eq "username";
			my ($module,$type,$name) = split(/:/, $ref->{'right'}, 3);
			$self->{'perms'}{$permid}{lc $module}{lc $type}{lc $name} = $ref->{'value'} if $module && $type && $name;
		#}
	}
	return @ids_matched;
}

sub get_perm {
	my ($self) = shift;
	return 0 if $self->error;	
	
	my $id = $self->uid || $self->staffid;
	$self->set_error($self->lang(3,'get_perm')) and return unless $id;
	
	if ($self->staffid && $self->staffGroups) { #Staff groups
		my $sql_1082 = $self->{queries}{1082};
		my @gids = $self->staffGroups;
		$sql_1082 .= qq| `groupname` IN ('|.join('\',\'', @gids).qq|')| if @gids; 
		$sql_1082 .= qq| ORDER BY (`username` = ?)|; #Permissao individual preferencial
		$self->select_sql($sql_1082,$id,$id,$id);
	} else {
		$self->select_sql(1081,$id);
	}
		
	$self->mount_perm;
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub get_perms {
	my ($self,$sql,@params) = @_;
	return undef if $self->error;
	
	$self->set_error($self->lang(3,'get_perms')) and return unless $sql;
	
	$self->select_sql($sql,@params);
	my @perms = $self->mount_perm;
	$self->finish;
	
	return $self->error ? 0 : @perms;
}

##########################################
#Search items
sub return_username {
	my ($self) = shift;
	
	#TODO sempre atualizar para novas tabelas
	#MUITO CUIDADO COM O UID ou SID ou OUTRO, POIS PERDE A REFERENCIA
	$self->invid($_[0]) and return $self->invoice('username') if ($self->TABLE_INVOICES && $_[1] =~ /(?:${\$self->TABLE_INVOICES})(?:,|$)/i);
	$self->callid($_[0]) and return $self->call('username') if ($self->TABLE_CALLS && $_[1] =~ /(?:${\$self->TABLE_CALLS})(?:,|$)/i);
	$self->callid($_[0]) and return $self->call('username') if ($self->TABLE_NOTES && $_[1] =~ /(?:${\$self->TABLE_NOTES})(?:,|$)/i);
	$self->balanceid($_[0]) and return $self->balance('username') if ($self->TABLE_BALANCES && $_[1] =~ /(?:${\$self->TABLE_BALANCES})(?:,|$)/i);
	$self->creditid($_[0]) and return $self->credit('username') if ($self->TABLE_CREDITS && $_[1] =~ /(?:${\$self->TABLE_CREDITS})(?:,|$)/i);
	$self->ccid($_[0]) and return $self->creditcard('username') if ($self->TABLE_CREDITCARDS && $_[1] =~ /(?:${\$self->TABLE_CREDITCARDS})(?:,|$)/i);
}

sub return_sender {
	my ($self) = shift;
	
	if ($_[0] eq 'User' && $self->uid) {
		my $level = $self->user('level');
		#default will be the first
		$level =~ s/^[:]+//;
		my $entid = (split('::',$level))[0];
		$self->entid($self->num($entid));
		$sender = $self->enterprise('mail_account') if $self->entid;		
	}
	
	if ($_[0] eq 'Billing' && $self->uid) {
		my $level = $self->user('level');
		#default will be the first
		$level =~ s/^[:]+//;
		my $entid = (split('::',$level))[0];
		$self->entid($self->num($entid));
		$sender = $self->enterprise('mail_billing') if $self->entid;		
	}
	
	return $sender || $self->setting('adminemail');
}

sub search_srvid {
	my ($self) = shift;
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'search_server')) and return unless $_[0] || $_[1];
	
	my $sth = $self->select_sql(qq|SELECT `id` FROM `servidores` WHERE `$_[0]` = ?|,$_[1]);
	my ($id) = $sth->fetchrow_array if $sth;
    $self->finish;
    
	return $self->error ? '' : $id;
}

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
	 
	
	my $sth = $self->select_sql(qq|SELECT `id` FROM `servicos` WHERE `$_[0]` $op ?|,$value);
	return 0 if $sth->rows != 1;
	my ($id) = $sth->fetchrow_array if $sth;
    $self->finish;
    
	return $self->error ? 0 : $id;
}

#Template System
sub template {
	@_=@_;
	my $self = shift;

	return \%{$self->{templates}} unless exists $_[0]; #copy
	
	$self->{templates}{$_[0]} = $_[1] if exists $_[1];
	
	return $self->{templates}{$_[0]};
}

sub template_html {
	@_=@_;
	my $self = shift;

	return \%{$self->{templates}} unless exists $_[0]; #copy
	
	$self->{templates}{$_[0]} = $_[1] if exists $_[1];
	
	$self->{templates}{$_[0]} =~ s/\n/<br>/g;
	 
	return $self->{templates}{$_[0]};		
}

sub template_parse {
	my ($self,$ctype) = @_;	
	
	if ($ctype eq 'text/plain')	{
		$_ =~ s/\{(\S+?)\}/$self->template($1)/egi;
	} else {
		$_ =~ s/\{(\S+?)\}/$self->template_html($1)/egi;
	}
}

#Lang System
sub lang_parse {
	my ($self) = @_;
	$_ =~ s/(\%(\S*?)\%)/$self->{lang}{$2} ? $self->{lang}{$2} : ( $2 ? "missing_$2": "%")/ge;
}

sub _setlang {
	my ($self,$language) = @_;
	return 0 if !$language;
	
	#protect ourself
	escape(\$language);

	if (-e $self->setting('app')."/lang/$language/lang.inc") {
		$self->{_setlang} = $language;
		our %LANG = ();
		
		my $ret = do($self->setting('app')."/lang/$language/lang.inc");
		#Problemas com UTF-8, o arquivo tem que estar nesse formato para não deformar os caracteres do sistema

	    die "couldn't parse lang file: $@" if $@;
	    die "couldn't do lang file: $!" unless defined $ret;
	    die "couldn't run lang file" unless $ret;

		$self->{'lang'} = { %LANG };
		
		return 1;
	} else {
		$self->set_error('Lang not found at '.$self->setting('app')."/lang/$language/lang.inc");
		return 0;
	}
}

sub lang {
	my ($self,$no,@values) = @_;
	($no,@values) = @$no if (ref $no eq "ARRAY");

#	return "missing_$no_" unless exists $self->{lang}{$no};
	return $no unless exists $self->{lang}{$no}; #Broke non-translations, who needs must override  
	return sprintf("$self->{lang}{$no}",@values);
}



sub servicos {
	my ($self) = shift;
	my @q = split(" ","@_");
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'servicos')) and return unless $self->num($self->{'service'}{'id'});
	
	my $sth = $self->select_sql(qq|SELECT * FROM `servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` WHERE `id` = ?|,$self->num($self->{'service'}{'id'}));
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach my $q (@q) {
#				next if $q eq "servidor" && $ref->{$q} eq 1;#pensar em utilizar isso
				if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
					$self->{'service'}{lc $q} = $self->date($ref->{$q});
				} else {
					$self->{'service'}{lc $q} = $ref->{$q};
				}
			}
	   }
    $self->finish;
    
	return $self->error ? 0 : 1;
}

#sub invoices {
#	my ($self) = shift;
#	my @q = split(" ","@_");
#	return 0 if $self->error;	
#	
#	$self->set_error($self->lang(3,'invoices')) and return unless $self->num($self->{'invoice'}{'id'});
#
#	my $sth = $self->select_sql(qq|SELECT `invoices`.*, `users`.`vencimento` FROM `invoices` INNER JOIN `users` ON `invoices`.`username`=`users`.`username` WHERE `id` = ?|,$self->num($self->{'invoice'}{'id'}));
#	   while(my $ref = $sth->fetchrow_hashref()) {
#			foreach my $q (@q) {
#				if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
#					$self->{'invoice'}{lc $q} = $self->date($ref->{$q});
#				} else {
#					$self->{'invoice'}{lc $q} = $ref->{$q};
#				}				
#			}
#	   }
#    $self->finish;
#    
#	return $self->error ? 0 : 1;
#}

sub users {
	my ($self) = shift;
	my @q = split(" ","@_");
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'users')) and return unless $self->num($self->{'user'}{'id'});

	my $sth = $self->select_sql(qq|SELECT * FROM `users` WHERE `username` = ?|,$self->num($self->{'user'}{'id'}));
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach my $q (@q) {
				if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
					$self->{'user'}{lc $q} = $self->date($ref->{$q});
				} else {
					$self->{'user'}{lc $q} = $ref->{$q};
				}				
			}
	   }
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub pagamentos {
	my ($self) = shift;
	my @q = split(" ","@_");
	return 0 if $self->error;	

	$self->set_error($self->lang(3,'pagamentos')) and return unless $self->num($self->{'pagamento'}{'id'});
	
	my $sth = $self->select_sql(qq|SELECT * FROM `pagamento` WHERE `id` = ?|,$self->num($self->{'pagamento'}{'id'}));
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach my $q (@q) {
				if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
					$self->{'pagamento'}{lc $q} = $self->date($ref->{$q});
				} else {
					$self->{'pagamento'}{lc $q} = $ref->{$q};
				}				
			}
	   }
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub planos {
	my ($self) = shift;
	my @q = split(" ","@_");
	return 0 if $self->error;	
	
	$self->set_error($self->lang(3,'planos')) && return unless $self->num($self->{'plano'}{'id'});
	
	my $sth = $self->select_sql(qq|SELECT * FROM `planos` LEFT JOIN `planos_modules` ON `planos`.`servicos`=`planos_modules`.`plano` WHERE `servicos` = ?|,$self->num($self->{'plano'}{'id'}));
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach my $q (@q) {
				if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
					$self->{'plano'}{lc $q} = $self->date($ref->{$q});
				} else {
					$self->{'plano'}{lc $q} = $ref->{$q};
				}				
			}
	   }
    $self->finish;
    
	return $self->error ? 0 : 1;
}

sub promo {
	my ($self,$type) = @_;
	return 0 if $self->error;
		
#types 1 - dias gratis 2 - Sem taxa de setup 3 - Descontos em meses 4 - Nao se orientar pelo vc do usuario 5 - dias para finalizar 6 - fatura exclusiva
	$self->set_error($self->lang(3,'promocao')) and return unless $self->num($self->sid);
	$self->set_error($self->lang(3,'promocao')) and return unless $self->num($type);
 
 	unless (defined $self->service('_promo'.$type)) {
		my $sth = $self->select_sql(qq|SELECT * FROM `promocao` WHERE `servico` = ?|,$self->sid);
		while (my $ref = $sth->fetchrow_hashref()) {
			my $r = $ref->{'value'};
			$r = 0 if $r < 0 && $ref->{'type'} != 3;
			$self->service('_promo'.$ref->{'type'}, $r);
		}
 	}
 	
	if ($type == 1 || $type == 2 || $type == 4 || $type == 5 || $type == 6) {
		my $r = $self->num($self->service('_promo'.$type));
		$r = 0 if $r < 0;
		return $r
	}
	return split("::",$self->service('_promo'.$type),3) if $type == 3;
	return undef;
}

sub _feriados { #put in memory for fast access
	my ($self) = @_;
 
 	my $sth = $self->select_sql(qq|SELECT * FROM `feriados`|);
	while(my $ref = $sth->fetchrow_hashref()) {	 
		$self->{'feriados'}{$ref->{'mes'}}{$ref->{'dia'}} = $ref->{'desc'};
	}  
	$self->finish;

	return $self->error ? 0 : 1;
}

sub _settings { #put in memory for fast access
	my ($self) = @_;
 
 	my $sth = $self->select_sql(qq|SELECT * FROM `settings`|);
	while(my $ref = $sth->fetchrow_hashref()) {
	 my $setting = $ref->{'setting'};
		$self->{settings}{$setting} = $ref->{'value'};
	}  
	$self->finish;

	return $self->error ? 0 : 1;
}

sub _setskin {
	my ($self,$skin) = @_;
	return 0 if !$skin;
	
 	my $sth = $self->select_sql(qq|SELECT * FROM `skins` WHERE `name` = ?|,$skin);
	while(my $ref = $sth->fetchrow_hashref()) {
	 my $setting = $ref->{'setting'};
		$self->{skin}{$setting} = $ref->{'value'};
	}  
	$self->finish;
	#set name
	$self->{skin}{name} = $skin;

	return $self->error ? 0 : 1;
}
sub _templates {
	my ($self) = shift;
	
	$self->template('lang',$self->{_setlang});
	$self->template('data',$self->setting('data'));
	$self->template('title',$self->setting('title'));
	$self->template('baseurl',$self->setting('baseurl'));
	$self->template('timen',$self->calendar('timenow'));  
	$self->template('data_tpl',$self->skin('data_tpl'));
	$self->template('url_tpl',$self->skin('url_tpl'));
	$self->template('imgbase',$self->skin('imgbase'));
	$self->template('logo',$self->skin('logo_url'));

	return 1;
}

sub _country_codes { #put in memory for fast access
	my ($self) = @_;

	my $sth = $self->select_sql(qq|SELECT * FROM `countrycode`|);
	while(my $ref = $sth->fetchrow_hashref()) {
	 my $country = $ref->{'id'};
		$self->{country_codes}{uc $country} = { code => $ref->{'call'},
											 name => $ref->{'nome'}  };
	}  
	$self->finish;

	return $self->error ? 0 : 1;
} 

sub _setswitchs {
	our %SWITCH;
	#Defaults switchs
	$SWITCH{skip_sql} = 0;
	$SWITCH{skip_log} = 0;
	$SWITCH{skip_mail} = 0;
	$SWITCH{skip_logmail} = 0;
	$SWITCH{skip_error} = 0;
	
	return 1;
}

sub _setCGI {
	my ($self) = shift;

	require CGI;
	my $q = CGI->new();
	my @pairs = split(/;/, $q->query_string());
	foreach my $pair (@pairs) {
	    my ($name, $value) = split(/=/, $pair);
		#Problema de charset era o binmode utf8 que escrevia no arquivo errado e a tela do terminal tbm, mudei pra UTF8
	    $self->param($name,Controller::URLDecode($value));
	}
	
	foreach my $name ($q->cookie()) {
		$self->cookie($name,$q->cookie($name));
	}
	
	return 1;
}

sub variable {
	@_=@_;
	my ($self) = shift;
	$self->{_variables}{$_[0]} = $_[1] if exists $_[1];
	return $self->{_variables}{$_[0]};
}

sub variables {
	my ($self) = shift;
	return keys %{$self->{_variables}};
}

sub param {
	@_=@_;
	my ($self) = shift;
	$self->{_params}{$_[0]} = trim($_[1]) if exists $_[1];
	return $self->{_params}{$_[0]};
}

sub params {
	my ($self) = shift;
	return keys %{$self->{_params}};
}

sub cookie {
	@_=@_;	
	my ($self) = shift;
	$self->{_cookies}{$_[0]} = $_[1] if exists $_[1];
	return $self->{_cookies}{$_[0]};
}

sub cookies {
	my ($self) = shift;
	return keys %{$self->{_cookies}};
}

sub country_code {
	my ($self, $key, $value) = @_;

	$self->{country_codes}{$key} = $value if $value;
	if (exists $self->{country_codes}{$key}) {
		return $self->{country_codes}{$key};
	}
	
	$self->set_error($self->lang(14, $key));
	die; #break, uma configuracao é essencial para o sistema
}

sub country_codes {
	my ($self) = shift;
	return sort keys %{$self->{country_codes}};
}

sub setting {
	my ($self, $key, $value) = @_;
	
	$self->{settings}{$key} = $value if defined $value;
	if (exists $self->{settings}{$key}) {
		return $self->{settings}{$key};
	}
	
	$self->set_error($self->lang(2, $key));
	die $key if $self->connected; #break, uma configuracao é essencial para o sistema
}

sub settings {
	my ($self) = @_;
	return keys %{$self->{settings}};
}

sub skin {
	my ($self, $key) = @_;
	
	if (exists $self->{'skin'}{$key}) {
		return $self->{'skin'}{$key};
	}
	
	$self->set_error($self->lang(4, $key, $self->{'skin'}{'name'}));
	die; #break, uma configuracao é essencial para o sistema
}

sub skins {
	my $self = shift;
	
 	my $sth = $self->select_sql(qq|SELECT DISTINCT `name` FROM `skins`|);
	my @skins = map {@{$_}} @{ $sth->fetchall_arrayref() }; 
	$self->finish;
	
	return @skins;
}

sub gonext {
	my $self = @_;
	$self->{'_next'} = 1;
	return 1;
}

sub golast {
	my $self = @_;
	$self->{'_last'} = 1;
	return 1;
}

sub next {
	my $self = @_;
	if ($self->{'_next'} == 1) {
		$self->{'_next'} = undef;
		next;
	} 
	if ($self->{'_last'} == 1) {
		$self->{'_last'} = undef;
		last;
	} 	
}

sub list_langs {
	my $self = shift;
	my @mods;
	my $base = $self->setting('app') .'/lang/';
	
	opendir(F, $base ) || return undef;
	my @list = readdir(F);
	closedir F;
	foreach my $item (@list) {
		if (-d $base.$item) { 
			push (@dirs, $item) if (-e $base.$item.'/lang.inc');
		}
	}
	@{ $self->{list_langs} } = sort {lc($a) cmp lc($b)} @dirs;
	iUnique( $self->{list_langs} );
	
	return @{ $self->{list_langs} };
}

sub list_modules {
	my $self = shift;
	my @mods;
	
	my $match = sub {
			if ($File::Find::name =~ /\.pm$/) {
				open(F, $File::Find::name) || return undef;
				my $is_module;
				while(<F>) {
					$is_module = 1 if /^# Use: Module/;
					if ($is_module == 1 && /^ *package +(([^\s:]+(::)?){4}([^\s:]+){0,1});/) {
						push (@mods, $1);
						last;
					}
				}
				close(F);
			}
		};
	find( $match, $self->setting('data').'/sistema/'.$self->setting('modules'), $self->setting('app').'/modules');
	@{ $self->{list_modules} } = sort {lc($a) cmp lc($b)} @mods;
	iUnique( $self->{list_modules} );
	
	return @{ $self->{list_modules} };
}

sub DESTROY {
	my $self = @_;
	#warn 'Controller was closed';
}

sub traceback { #TODO enviar trace pra admin e die_nice pro usuário
	my $self = shift;
    my $err = shift;
    my @trace; #FIXME: empty list?
	
    # Skip the first frame [0], because it's the call to dotb.
    # Skip the second frame [1], because it's the call to die, with redirection
    my $frame = 2;
    my $tab = 1;
    while (my ($package, $filename, $line, $sub) = caller($frame++)) {
        if ($package eq 'main') {
            $sub =~ s/main:://;
            push(@trace, trim("$sub() called from $filename on line $line"));
        } else {
        	return undef if $sub eq '(eval)'; #O Pacote tem direito de chamar um eval para fazer seu próprio handle de erro #CASO: cPanel::PublicAPI.pm  eval { require $module; } if ( !$@ ) { }; 
            push(@trace, trim("$package::$sub() called from $filename on line $line\n"));
        }
    }
       
    #print STDERR "Content-type: text/plain\n\n" unless $mod_perl;
	my $mess .= "Traceback (most recent call last):\n";
	$mess .= join("\n", map { "  "x$tab++ . $_ } reverse(@trace) )."\n";
	$mess .= "Package error: ".$self->error()."\n";
	$mess .= "Error: $err"; #already has \n at end
    
    my $mod_perl = exists $ENV{MOD_PERL};    
    if ($mod_perl) {
    	my $r;
    	if ($ENV{MOD_PERL_API_VERSION} && $ENV{MOD_PERL_API_VERSION} == 2) {
      		$mod_perl = 2;
			require Apache2::RequestRec;
			require Apache2::RequestIO;
			require Apache2::RequestUtil;
			require APR::Pool;
			require ModPerl::Util;
			require Apache2::Response;
			$r = Apache2::RequestUtil->request;
    	} else {
			$r = Apache->request;
    	}
	    # If bytes have already been sent, then
	    # we print the message out directly.
	    # Otherwise we make a custom error
	    # handler to produce the doc for us.
	    if ($r->bytes_sent) {
	      $r->print($mess);
	      $mod_perl == 2 ? ModPerl::Util::exit(0) : $r->exit;
	    } else {
	      # MSIE won't display a custom 500 response unless it is >512 bytes!
	      if ($ENV{HTTP_USER_AGENT} =~ /MSIE/) {
	        $mess = "<!-- " . (' ' x 513) . " -->\n$mess";
	      }
	      $r->custom_response(500,$mess);
	    }
	} else {
#	    my $bytes_written = eval{tell STDERR};
#	    if (defined $bytes_written && $bytes_written > 0) {
#	        print STDERR $mess;
#	    }
#	    else {
#	        print STDERR "Status: 500\n";
#	        print STDERR "Content-type: text/plain\n\n";
#	        print STDERR $mess;
#	    }    	
	}
	$self->logevent($mess);
	#send message to cron lock
	$self->logcron($err) if $self->connected;
	#send a nice message to user
	$self->script_error($err);
}

sub script_error {
	my ($self) = shift;
	my $error = "@_";
	$error ||= $self->error;
	
	#TODO estudar se o script_error pode ficar em um arquivo html
	print "Content-type: text/html\n\n";
	print qq~<html><head><title>Erro</title>
			<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
			</head><body bgcolor="#FFFFFF"><p>&nbsp;</p><table width="600" border="0" cellspacing="0" cellpadding="0" align="center"><tr><td colspan="3"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Controller: 
			<font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b><font color="#990000">Erro de </font></b></font><font color="#990000">Script </font></b></font></td></tr><tr> <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr><tr> 
			<td colspan="3"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Controller n&atilde;o pode ser rodado pelos seguintes erros:</font></td>
			</tr><tr><td colspan="3" height="40"><font face="Courier New, Courier, mono" size="2"><br>$error<br></td></tr></table><p align="center">&nbsp;</p></body></html>
			~;
	exit(1);
}
__END__;

Diagnostics

Find @ISA:
use Class::ISA;
print "Food::Fishstick path is:\n ",
       join(", ", Class::ISA::super_path($class)),
    "\n";


1;
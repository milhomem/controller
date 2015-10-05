#!/usr/bin/perl         
# 
# Controller - is4web.com.br
# 2014
#Pacote personalizado que usa uma implementação em python
#com a Cielo e importa o python para dentro do Perl
package Controller::Financeiro::CreditCard::Cielo;

require 5.008;
require Exporter;

use Controller::Financeiro;
use Cwd;

use vars qw(@ISA $VERSION $tidproximo $LANG);
@ISA = qw(Controller::Financeiro Controller::Financeiro::CreditCard Controller::XML Exporter);

$VERSION = "1.0";
$LANG = 'pt';

BEGIN { $ENV{'PYTHONPATH'} = '/home/path/app/modules/Controller/Financeiro/CreditCard/Cielo'; }

use Inline Python => <<'END';
import os; 
from gateway import pay;
END

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	#Depende do Controller
	my $self = new Controller::Financeiro( @_ );
	push @ISA, @Controller::Financeiro::ISA; #Inherit ISA
	
	%$self = (
		%$self,
		'ERR' => undef,
		'invoice' => undef,
	);
	
	bless($self, $class);
	
	return $self;
}

sub cc_capture {
	$_[0]->set_error($_[0]->lang(3,'cc_capture')) and return undef unless $_[0]->ccid;
	return $_[0]->visa_capture;
}

sub cc_verify { 
    return 1; 
}

sub visa_capture {
	my $self = shift;
	return if $self->error;
		
	my $card_type = Controller::getCreditCardType($self->creditcard('ccn'));
    my $total = Controller::num2valor($self->invoice('valor'));
    my $order_id = $self->invid;
    my $card_number = $self->creditcard('ccn');
    my $exp_date = $self->creditcard('exp');
    my $transaction_type = $self->invoice('parcelado');
    my $card_holders_name = $self->creditcard('name');
    my $installments = $self->invoice('parcelas') || 1;
    my $cvv = $self->creditcard('cvv2') ? $self->creditcard('cvv2') : '';
    my $sandbox = 0;

    $result = pay($card_type, $total, $order_id, $card_number, $exp_date, $transaction_type, $card_holders_name, $installments, $cvv, $sandbox);
    $msg = $result->{msg};
    utf8::encode($msg);

    $self->invoice('nossonumero', $result->{tid}) unless $self->invoice('nossonumero');
    $self->execute_sql(479, $self->invoice('nossonumero'), $self->invid) unless $self->invid =~ m/^TEST/;

    return ('authorized' => $result->{success}, 'valor' => Controller::valor2num($total), 'response' => $msg);		
}

1;
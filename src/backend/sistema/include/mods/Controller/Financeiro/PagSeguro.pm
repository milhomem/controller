#!/usr/bin/perl         
# Use: FinanceiroModule
# Controller - is4web.com.br
# 2012
package Controller::Financeiro::PagSeguro;

require 5.008;
require Exporter;

use Controller::Financeiro;
use Controller::Interface;
use Controller::XML;
use LWP::UserAgent 6;

use vars qw(@ISA $VERSION);

@ISA = qw(Controller::Financeiro Controller::XML Controller::Interface Exporter);
$VERSION = "0.1";

use vars qw($SOAP_URI $SCHEMA_URI $SCHEMAXDS_URI $SOAP_ENC $doc);
$SOAP_URI = 'http://schemas.xmlsoap.org/soap/envelope/';
$SOAP_ENC = 'http://schemas.xmlsoap.org/soap/encoding/';
$SCHEMA_URI	= 'http://www.w3.org/2001/XMLSchema-instance';
$SCHEMAXDS_URI = 'http://www.w3.org/2001/XMLSchema';

sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
		
        #Depende do Controller
        my $inherit = new Controller::Financeiro( @_ );
        push @ISA, @Controller::Financeiro::ISA; #Inherit ISA

        my $self = {
            %$inherit,	
        };
		
        bless($self, $class);

        return $self;
}

sub newDocument {
    my $doc = Controller::XML->newDocument('1.0','ISO-8859-1');

	return $doc;
}

sub prepare_request {
	my ($self) = shift;
	
	our $doc = newDocument;
   
	return $doc;
}

sub returnURL {
	my $self = shift;
	$self->{'_returnURL'} = $_[0] if exists $_[0];
	return $self->{'_returnURL'};
}

sub redirectLogin {
	return 'https://pagseguro.uol.com.br/v2/checkout/payment.html?code='
}

sub registerCheckout {
	my $self = shift;
	return 0 if $self->invoice('nossonumero');
	$self->set_error($self->lang(2360)) unless $self->invoice('data_vencimento') >= $self->today;
	
	$self->endpoint('https://ws.pagseguro.uol.com.br/v2/registerCheckout');
	
	$self->prepare_request;
	
	my $root = $doc->createElementRoot('checkout');
	$doc->createElement('currency', $root, 'BRL');
	my $items = $doc->createElement('items', $root);
	
	my $item = $doc->createElement('item', $items);
	$doc->createElement('id', $item, $self->invid);
	my $desc = Controller::cut_string( $self->invoice('referencia'),$self->lang('dots'),100);
	utf8::upgrade($desc);	
	$doc->createElement('description', $item, $desc); #Formato: Livre, com limite de 100 caracteres. 
	$doc->createElement('amount', $item, $self->round($self->invoice('valor')));		
	$doc->createElement('quantity', $item, '1');
	
	$doc->createElement('reference', $root, $self->invid);
	
	$doc->createElement('maxUses', $root, '20'); #Eles nao sabem quando o pagamento foi concluido e sim quando o link foi acessado
	
	my @time = $self->timenow;
	my @ndu = split ',', $self->setting('nonweekdays');
	my $venc = $self->invoice('data_vencimento');
	my $du = 0;
	do {
		$du = $venc->day_of_week;
		$venc += 1;		
		$du = 0 if grep {$du == $_} @ndu;
		$du = 0 if $self->feriado($venc->as_ymd);
		$du = $du == 0 ? 1 : 0;
	}
	while ($du == 0);
	$doc->createElement('maxAge', $root, ($venc - $self->today)*24*3600 - ($time[0]*3600+$time[1]*60+$time[2]));
	
	my $response = $self->request();
	return $self->error() unless $response;
	
	if ($response->{'code'}[0]{'content'}) {
		$self->invoice('nossonumero',$response->{'code'}[0]{'content'});
		$self->execute_sql(479,$response->{'code'}[0]{'content'},$self->invid);
	} else {
		use Data::Dumper;
		$self->set_error($self->lang(251,"PagSeguro registerCheckout without code: ", Dumper(\$response));
	}
	
	return $response->{'code'}[0]{'content'};	
}

sub checkPayment {
	my $self = shift;
	return 0 unless $self->invoice('nossonumero');
	
	$self->endpoint('https://ws.pagseguro.uol.com.br/v2/transactions/'.$self->invoice('nossonumero'));
	
	my $response = $self->request_get();
	return $self->error() unless $response;

	if ($response->{'status'}[0]{'content'} == 3) {
		$self->set_error($self->lang(2004,$response->{'reference'}[0]{'content'})) if $response->{'reference'}[0]{'content'} != $self->invid;
		$self->user_config('pagseguroNAME',$response->{'sender'}[0]{'name'}[0]{'content'});
		$self->user_config('pagseguroEMAIL',$response->{'sender'}[0]{'email'}[0]{'content'});
		$self->user_config('pagseguroPHONE',join(' ',$response->{'sender'}[0]{'phone'}[0]{'areaCode'}[0]{'content'},$response->{'sender'}[0]{'phone'}[0]{'number'}[0]{'content'}));	
		use Controller::Users;
		$self->Controller::Users::save_config;		
		return $response;
	}
	
	return $response->{'code'}[0]{'content'};	
}

sub endpoint {
	my $self = shift;
	$self->{'_endpoint'} = $_[0] if exists $_[0];
	return $self->{'_endpoint'};
}

sub login {
	my $self = shift;
	
	return $self->Hash2Query( {'email' => $self->setting('pagseguro_user'), 'token' => $self->setting('pagseguro_pass') } );		
}

sub request {
	my ($self) = shift;
	return if $self->error;
		
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(POST => $self->endpoint().'?'.$self->login());
	$request->content( $doc->serialize(0));
	$request->content_type("application/xml; charset=ISO-8859-1");
	my $response = $userAgent->request($request);

	my $result = $self->get_return_value($response->content) if $response->content =~ m/^<\?xml/i;
	if($response->code == 200 && ref $result eq 'XML::LibXML::Document') {
		return \%{$self->xml2perl(($result->toString(0)))} unless $self->error;
	} elsif($response->code == 400 && ref $result eq 'XML::LibXML::Document') {		
		my %resultPerl = %{$self->xml2perl(($result->toString(0)))} unless $self->error;
		$self->set_error($self->lang(251,"PagSeguro Request",$resultPerl{'error'}[0]{'message'}[0]{'content'}));
	} else {
		$self->set_error($self->lang(251,"PagSeguro Request",$response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub request_get {
	my ($self) = shift;
	return if $self->error;
		
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(GET => $self->endpoint().'?'.$self->login());
	my $response = $userAgent->request($request);
	
	my $result = $self->get_return_value($response->content) if $response->content =~ m/^<\?xml/i;
	if($response->code == 200 && ref $result eq 'XML::LibXML::Document') {
		return \%{$self->xml2perl(($result->toString(0)))} unless $self->error;
	} elsif($response->code == 400 && ref $result eq 'XML::LibXML::Document') {		
		my %return = %{$self->xml2perl(($result->toString(0)))} unless $self->error;
		$self->set_error($self->lang(251,"PagSeguro Request",$return{'error'}[0]{'message'}[0]{'content'}));
	} else {
		$self->set_error($self->lang(251,"PagSeguro Request",$response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub payButton {
	my $self = shift;
	
	return <<END
<!-- INICIO FORMULARIO BOTAO PAGSEGURO -->
<form target="pagseguro" action="https://pagseguro.uol.com.br/checkout/v2/payment.html?code=$_[0]" method="get">
<input type="image" src="https://p.simg.uol.com.br/out/pagseguro/i/botoes/pagamentos/120x53-pagar-preto.gif" name="submit" alt="Pague com PagSeguro - é rápido, grátis e seguro!" />
</form>
<!-- FINAL FORMULARIO BOTAO PAGSEGURO -->
END
}

#######################################
# Cron Calls						  #
#######################################
sub doBilling {
	my $self = shift;
	
	$self->registerCheckout;
	$self->template('link',$self->redirectLogin().$self->invoice('nossonumero')) if $self->invoice('nossonumero');

	return $self->error ? 0 : 1;
}

sub posBilling {
	my $self = shift;
	#Ignorar esses erros quando rodado no Agendador de tarefas
	$self->logcronRemove if $self->invoice('nossonumero') > 0 || $self->invoice('data_vencimento') < $self->today;
	return 1;
}

sub payDay {
	my $self = shift;

	$self->logcronRemove;
	return 0;
	#O codigo do pagamento nao eh o mesmo da transacao entao deve ser feito um listener para ouvir o APN
	#https://pagseguro.uol.com.br/v2/guia-de-integracao/api-de-notificacoes.html#main-header
}

1;

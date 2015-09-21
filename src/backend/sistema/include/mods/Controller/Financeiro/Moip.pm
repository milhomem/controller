#!/usr/bin/perl         
# Use: FinanceiroModule
# Controller - is4web.com.br
# 2012
package Controller::Financeiro::Moip;

require 5.008;
require Exporter;

use Controller::Financeiro;
use Controller::Interface;
use Controller::XML;
use LWP::UserAgent 6;
use MIME::Base64 qw(encode_base64);

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
            '_sandbox' => 1, #0=production 1=test
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
	return 'https://desenvolvedor.moip.com.br/sandbox/Instrucao.do?token='
}

sub registerCheckout {
	my $self = shift;
	return 0 if $self->invoice('nossonumero') > 0;
	$self->set_error($self->lang(2360)) unless $self->invoice('data_vencimento') >= $self->today;
	
	$self->endpoint('/ws/alpha/EnviarInstrucao/Unica');
	
	$self->prepare_request;
	
	my $root = $doc->createElementRoot('EnviarInstrucao');
	my $body = $doc->createElement('InstrucaoUnica',$root);
	my $desc = Controller::cut_string( $self->invoice('referencia'),$self->lang('dots'),256); #alfanumárico(256)	
	utf8::upgrade($desc);	
	$doc->createElement('Razao', $body, $desc); 
	my $valores = $doc->createElement('Valores', $body);
	
	my $valor = $doc->createElement('Valor', $valores, $self->round($self->invoice('valor')));
	$valor->setAttribute('moeda', 'BRL');
	
	$doc->createElement('IdProprio', $root, $self->invid);
	
	my $response = $self->request();
	if ($response->{'Resposta'}[0]{'Status'}[0]{'content'} eq 'Sucesso') {
		$self->invoice('nossonumero',$response->{'Resposta'}[0]{'Token'}[0]{'content'});
		$self->execute_sql(479,$response->{'Resposta'}[0]{'Token'}[0]{'content'},$self->invid);
	}
	
	return $response->{'Resposta'}[0]{'Token'}[0]{'content'};	
}

sub checkPayment {
	my $self = shift;
	return 0 unless $self->invoice('nossonumero');
	
	$self->endpoint('/ws/alpha/ConsultarInstrucao/'.$self->invoice('nossonumero'));
	
	my $response = $self->request_get();
	use Data::Dumper; die Dumper \$response;
	my $pagamento; 
	foreach ($response->{'RespostaConsultar'}[0]{'Autorizacao'}[0]{'Pagamento'}) {
		if ($_->{'Status'}[0]{'content'} eq 'Concluido') {
			$pagamento = $_;
			last;			
		}
	};
	if ($pagamento->{'Status'}[0]{'content'} eq 'Concluido') {
		$self->set_error($self->lang(2004,$response->{'external_reference'})) if $response->{'external_reference'} != $self->invid;
		return $pagamento;
	}
	
	return $response->{'code'}[0]{'content'};	
}

sub endpoint {
	my $self = shift;
	my $ambiente = $self->{_sandbox} == 0 
			? 'https://www.moip.com.br'
			: 'https://desenvolvedor.moip.com.br/sandbox';
	$self->{'_endpoint'} = $ambiente.$_[0] if exists $_[0];
	return $self->{'_endpoint'};
}

sub login {
	my $self = shift;
	my $request = shift;
	
	my $authstr = encode_base64($self->setting('moip_token') . ":" . $self->setting('moip_pass'));
	$request->header('Authorization' => "Basic $authstr");		
}

sub request {
	my ($self) = shift;
	return if $self->error;
		
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(POST => $self->endpoint());
	$self->login($request);

	$request->content($doc->serialize(0));
	$request->content_type("application/xml; charset=ISO-8859-1");
	my $response = $userAgent->request($request);
	
	my $result = $self->get_return_value($response->content) if $response->content =~ m/^</i;
	if($response->code == 200 && ref $result eq 'XML::LibXML::Document') {
		return \%{$self->xml2perl(($result->toString(0)))} unless $self->error;
	} elsif($response->code == 400 && ref $result eq 'XML::LibXML::Document') {		
		my %return = %{$self->xml2perl(($result->toString(0)))} unless $self->error;
		$self->set_error($self->lang(251,"Moip Request",$return{'Resposta'}[0]{'Erro'}[0]{'content'}));
	} else {
		$self->set_error($self->lang(251,"Moip Request",$response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub request_get {
	my ($self) = shift;
	return if $self->error;

	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(GET => $self->endpoint());
	$self->login($request);
	my $response = $userAgent->request($request);
	
	my $result = $self->get_return_value($response->content) if $response->content =~ m/^</i;
	if($response->code == 200 && ref $result eq 'XML::LibXML::Document') {
		return \%{$self->xml2perl(($result->toString(0)))} unless $self->error;
	} elsif($response->code == 400 && ref $result eq 'XML::LibXML::Document') {		
		my %return = %{$self->xml2perl(($result->toString(0)))} unless $self->error;
		$self->set_error($self->lang(251,"Moip Request",$return{'Resposta'}[0]{'Erro'}[0]{'content'}));
	} else {
		$self->set_error($self->lang(251,"Moip Request",$response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub payButton {
	my $self = shift;
	
	return <<END
	<a href="$_[0]"><img 
	src="https://www.moip.com.br/imgs/buttons/bt_comprar_c01_e04.png" 
	alt="Pagar" 
	border="0" /></a>
END
}

#######################################
# Cron Calls						  #
#######################################
sub doBilling {
	my $self = shift;
	
	$self->template('link',$self->payButton($self->redirectLogin().$self->invoice('nossonumero'))) if $self->registerCheckout;
	return $self->redirectLogin().$self->invoice('nossonumero');
}

sub posBilling {
	my $self = shift;
	#Ignorar esses erros quando rodado no Agendador de tarefas
	$self->unlock_billing if $self->invoice('nossonumero') > 0 || $self->invoice('data_vencimento') < $self->today;
	return 1;
}

sub payDay {
	my $self = shift;
	
	my $response = $self->checkPayment;
	if ($response->{'Status'}[0]{'content'} eq 'Concluido') {		
		$self->invoice('valor_pago',$response->{'ValorLiquido'}[0]{'content'});
		$self->invoice('data_quitado',$self->datefromISO8601($response->{'Data'}[0]{'content'}));
		$self->variable('threshold',$response->{'TotalPago'}[0]{'content'});
	}
	$self->unlock_billing unless $self->error;
	
	return $self->error ? 0 : 1;
}
1;
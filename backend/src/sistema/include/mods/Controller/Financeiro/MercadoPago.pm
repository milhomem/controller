#!/usr/bin/perl         
# Use: FinanceiroModule
# Controller - is4web.com.br
# 2012
package Controller::Financeiro::MercadoPago;

require 5.008;
require Exporter;

use Controller::Financeiro;
use Controller::Interface;
use JSON;
use LWP::UserAgent 6;
use MIME::Base64 qw(encode_base64);

use vars qw(@ISA $VERSION);

@ISA = qw(Controller::Financeiro Controller::Interface Exporter);
$VERSION = "0.1";

sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
		
        #Depende do Controller
        my $inherit = new Controller::Financeiro( @_ );
        push @ISA, @Controller::Financeiro::ISA; #Inherit ISA

        my $self = {
            %$inherit,
			 '_JSON' => new JSON->utf8, 
        };
		
        bless($self, $class);

        return $self;
}

sub JSON {
	return $_[0]->{'_JSON'};
}

sub registerCheckout {
	my $self = shift;
	return 0 if $self->invoice('nossonumero') > 0;
	$self->set_error($self->lang(2360)) unless $self->invoice('data_vencimento') >= $self->today;
	
	$self->endpoint('https://api.mercadolibre.com/checkout/preferences?access_token=');
	
	my $params = {
            'external_reference' => $self->invid,
            'payment_methods' => {
               'installments' => $self->invoice('parcelado') eq 'S' ? 1 : $self->invoice('parcelas') || 1
             },
            'items' => [
                         {
                           'currency_id' => $self->setting('currency'),
                           'quantity' => 1,
                           'title' => $self->lang(2370,$self->invoice('nome'), $self->invid),
                           'id' => $self->invid,
                           'description' => Controller::cut_string( $self->invoice('referencia'),$self->lang('dots'),256),
                           'picture_url' => 'https://www.mercadopago.com/org-img/MP3/home/logomp3.gif',
                           'unit_price' => $self->round($self->invoice('valor')) * 1 #JSON number force
                         }
                       ]
          };
	my $response = $self->request(POST => $params);
	
	return $response->{'init_point'};	
}

sub infoPayment {
	my $self = shift;
	return 0 unless $_[0];
	
	$self->endpoint('https://api.mercadolibre.com/collections/'.$_[0].'?access_token=');
	
	my $response = $self->request_get();

	return $response;	
}

sub checkPayment {
	my $self = shift;
	return 0 unless $self->invoice('nossonumero');
	
	$self->endpoint('https://api.mercadolibre.com/collections/'.$self->invoice('nossonumero').'?access_token=');
	
	my $response = $self->request_get();
	if ($response->{'status'} eq 'approved') {
		$self->set_error($self->lang(2004,$response->{'external_reference'})) if $response->{'external_reference'} != $self->invid;
		$self->user_config('mercadopagoNAME',join(' ',$response->{'payer'}{'first_name'},$response->{'payer'}{'last_name'}));
		$self->user_config('mercadopagoEMAIL',$response->{'payer'}{'email'});
		$self->user_config('mercadopagoPAYERID',$response->{'payer'}{'id'});
		$self->user_config('mercadopagoPHONE',join(' ',($response->{'payer'}{'area_code'},$response->{'payer'}{'number'},$response->{'payer'}{'extension'})));	
		use Controller::Users;
		$self->Controller::Users::save_config;
		return $response;						
	}
	
	return $response->{'status'};
}

sub endpoint {
	my $self = shift;
	$self->{'_endpoint'} = $_[0] if exists $_[0];
	return $self->{'_endpoint'};
}

sub login {
	my $self = shift;
	
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(POST => 'https://api.mercadolibre.com/oauth/token');
	
	$request->header('Accept' => 'application/json');
	$request->content('grant_type=client_credentials&client_id='.$self->setting('marcadopago_id').'&client_secret='.$self->setting('marcadopago_pass'));
	$request->content_type("application/x-www-form-urlencoded");
	my $response = $userAgent->request($request);
	if($response->code == 200) {		
		my $result = $self->JSON->decode( $response->content );
		$self->{'_mercadopagoToken'} = $result->{'access_token'};		
	} else {
		$self->set_error($self->lang(251,"MercadoPago Login",$response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub request {
	my ($self) = shift;
	return if $self->error;
	
	$self->login() unless $self->{'_mercadopagoToken'};
	
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new($_[0] => $self->endpoint().$self->{'_mercadopagoToken'});
	$request->header('Accept' => 'application/json');		
	$request->content($self->JSON->encode($_[1]));	
	$request->content_type("application/json");
	my $response = $userAgent->request($request);
	
	my $result = $self->JSON->decode( $response->content ) if $response->content =~ m/^{/;
	if($response->code == 200 || $response->code == 201) {
		return $result unless $self->error || !defined $result;
	} else {
		$self->set_error($self->lang(251,"MercadoPago Request",$result->{'message'} || $result->{'error'}{'message'} || $response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub request_get {
	my ($self) = shift;
	return if $self->error;	

	$self->login() unless $self->{'_mercadopagoToken'};
		
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(GET => $self->endpoint().$self->{'_mercadopagoToken'});
	$request->header('Accept' => 'application/json');
	my $response = $userAgent->request($request);
	
	my $result = $self->JSON->decode( $response->content ) if $response->content =~ m/^{/;
	if($response->code == 200 || $response->code == 201) {
		return $result unless $self->error || !defined $result;
	} else {
		$self->set_error($self->lang(251,"MercadoPago Request",$result->{'message'} || $result->{'error'}{'message'}  || $response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub refundPayment {
	my $self = shift;
	return 0 unless $self->invoice('nossonumero') > 0;
	
	$self->endpoint('https://api.mercadolibre.com/collections/'.$self->invoice('nossonumero').'?access_token=');
	
	my $params = { status => 'refunded' };	
	$self->request(PUT => $params);
	
	unless ($self->error) {
		#TODO
	}	 
	return $self->error ? 0 : 1;
}

sub cancelPayment {
	my $self = shift;
	return 0 unless $self->invoice('nossonumero') > 0;	
	
	$self->endpoint('https://api.mercadolibre.com/collections/'.$self->invoice('nossonumero').'?access_token=');
	
	my $params = { status => 'cancelled' };
	$self->request(PUT => $params);
	
	unless ($self->error) {
		#TODO
	}
	return $self->error ? 0 : 1;	 
}

sub createTUser {
	my $self = shift;
	return 0 if $self->invoice('nossonumero') > 0;	
	
	$self->endpoint('https://api.mercadolibre.com/users/test_user?access_token=');
	
	my $params = { site_id => 'MLB' }; #Argentina: MLA, Brasil: MLB, México: MLM e Venezuela: MLV.
	my $result = $self->request(POST => $params);
	
	unless ($self->error) {
		return (
				email => $result->{'email'},
				pass =>  $result->{'password'}
				);
	}
	return undef;	 
}

sub payButton {
	my $self = shift;
	
	return <<END
	<a href="$_[0]">$_[0]</a>
END
}

#######################################
# Cron Calls						  #
#######################################
sub doBilling {
	my $self = shift;
	
	my $url = $self->registerCheckout;
	$self->template('link',$self->payButton($url)) if ($url);
	return $url;
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
	if ($response->{'status'} eq 'approved') {		
		$self->invoice('valor_pago',$response->{'net_received_amount'});
		$self->invoice('data_quitado',$self->datefromISO8601($response->{'date_approved'}));
		$self->variable('threshold',$response->{'total_paid_amount'});
	}
	$self->unlock_billing unless $self->error;
	
	return $self->error ? 0 : 1;
}
1;
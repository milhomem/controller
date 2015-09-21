#!/usr/bin/perl         
# Use: FinanceiroModule
# Controller - is4web.com.br
# 2012
package Controller::Financeiro::PayPal;

require 5.008;
require Exporter;

use Controller::Financeiro;
use Controller::Interface;
use Controller::XML;
use LWP::UserAgent 6;

use Digest::SHA qw(hmac_sha1_base64);

use vars qw(@ISA $VERSION $tidproximo);

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
                '_AppID' => undef,
                '_httpMethod' => 'POST',
                '_sandbox' => 0, #0=production 1=test
                '_nvpParam' => {}
        };
		
        bless($self, $class);		
		
        return $self;
}

sub newDocument {
    my $doc = Controller::XML->newDocument('1.0','UTF-8');
	my $soap = $doc->createElementRootNS('', 'SOAP-ENV:Envelope');
	$soap->setNamespace($SOAP_URI, 'SOAP-ENV', 0);
	$soap->setAttribute('SOAP-ENV:encondingStyle', $SOAP_ENC);
	$doc->createElement('SOAP-ENV:Header', $soap);
	$doc->createElement('SOAP-ENV:Body', $soap);
	
	return $doc;
}

sub prepare_request {
	my ($self) = shift;
	
	our $doc = newDocument;
	my $header = ( $doc->getElementsByTagName('SOAP-ENV:Header') )[0];
    
	return $doc;
}

sub endpoint {
	my $self = shift;
	$self->{'_endpoint'} = $_[0] if exists $_[0];
	return $self->{'_endpoint'};
}

sub nvpEndpoint {
	my $self = shift;
	$self->endpoint(
			$self->{_sandbox} == 0 
			? 'https://api-3t.paypal.com/nvp'
			: 'https://api-3t.sandbox.paypal.com/nvp'
		);	
}

sub returnURL {
	my $self = shift;
	$self->{'_returnURL'} = $_[0] if exists $_[0];
	return $self->{'_returnURL'};
}

sub cancelURL {
	my $self = shift;
	$self->{'_cancelURL'} = $_[0] if exists $_[0];
	return $self->{'_cancelURL'};
}

sub login {
	my $self = shift;
	my $request = shift;
	 
	$request->header('X-PAYPAL-SECURITY-USERID' => $self->setting('paypal_user'));
	$request->header('X-PAYPAL-SECURITY-PASSWORD' => $self->setting('paypal_pass'));
	$request->header('X-PAYPAL-SECURITY-SIGNATURE' => $self->setting('paypal_sign'));
	$request->header('X-PAYPAL-APPLICATION-ID' => $self->{_sandbox} == 0 
				? 'ACCOUNT HERE'
				: 'APP-80W284485'  #Development login
		); #Calls that use the PayPal Adaptive APIs require an AppID. The AppID value for the Sandbox is constant
	$request->header('X-PAYPAL-AUTHORIZATION' => $self->authorizationHeader()) if $self->authorizationHeader();
		
}

sub requestPermissions {
	my $self = shift;
	die 'No return URL' unless $self->returnURL;
	
	$self->prepare_request;
	
	my $SOAP_CALL = 'RequestPermissions';
	my $El = $doc->createElement($SOAP_CALL,  'SOAP-ENV:Body'); 
	
	$self->endpoint(
			$self->{_sandbox} == 0 
			? 'https://svcs.paypal.com/Permissions'
			: 'https://svcs.sandbox.paypal.com/Permissions'
		);

	$doc->createElement('requestEnvelope', $El, 'en_US'); 
	$doc->createElement('scope', $El, 'EXPRESS_CHECKOUT'); 
	$doc->createElement('callback', $El, $self->returnURL()); 

	if ($self->request($SOAP_CALL)) {
		my $response = $self->response();
		my %result = %{$self->xml2perl(($response->toString(0)))} unless $self->error;
		if ($result{'soapenv:Body'}[0]{'ns2:RequestPermissionsResponse'}[0]{'responseEnvelope'}[0]{'ack'}[0]{'content'} eq 'Success') {
			return $result{'soapenv:Body'}[0]{'ns2:RequestPermissionsResponse'}[0]{'token'}[0]{'content'};
		} else {
			$self->set_error($self->lang('2350',$result{'soapenv:Body'}[0]{'soapenv:Fault'}[0]{'faultstring'}[0]{'content'}));
		}
	} else {
		return undef;
	}	
}

sub getAccessToken {
	my $self = shift;
	#needs verification code 
	#The verification code expires in about 15 minutes.
	#save token and secret
	#You use the access token and associated secret to create an authentication header, X-PAYPALAUTHORIZATION.
	$self->prepare_request;
	
	my $SOAP_CALL = 'GetAccessToken';
	my $El = $doc->createElement($SOAP_CALL,  'SOAP-ENV:Body'); 
	
	$self->endpoint(
			$self->{_sandbox} == 0 
			? 'https://svcs.paypal.com/Permissions'
			: 'https://svcs.sandbox.paypal.com/Permissions'
		);

	$doc->createElement('requestEnvelope', $El, 'en_US'); 
	$doc->createElement('token', $El, $_[0]); 
	$doc->createElement('verifier', $El, $_[1]); 

	if ($self->request($SOAP_CALL)) {
		my $response = $self->response();
		my %result = %{$self->xml2perl(($response->toString(0)))} unless $self->error;		
		if ($result{'soapenv:Body'}[0]{'ns2:GetAccessTokenResponse'}[0]{'responseEnvelope'}[0]{'ack'}[0]{'content'} eq 'Success') {
			$self->user_config('paypalToken',$result{'soapenv:Body'}[0]{'ns2:GetAccessTokenResponse'}[0]{'token'}[0]{'content'});
			$self->user_config('paypalTokenSecret',$result{'soapenv:Body'}[0]{'ns2:GetAccessTokenResponse'}[0]{'tokenSecret'}[0]{'content'});
			use Controller::Users;
			$self->Controller::Users::save_config;
			return 1;
		} else {
			$self->set_error($self->lang('2350',$result{'soapenv:Body'}[0]{'soapenv:Fault'}[0]{'faultstring'}[0]{'content'}));#Invalid token
			return 0;
		}
	} else {
		$self->set_error($self->lang('2350',$self->clear_error));#Invalid call
		return 0;
	}
}

sub authorizationHeader {
	my $self = shift;
	
	my $time = time;
	my $key = lc join('&',
				Controller::URLEncode($self->setting('paypal_pass')),
				Controller::URLEncode($self->user_config('paypalTokenSecret'))
			);
	my $base = lc join('&',
			$self->{'_httpMethod'},
			Controller::URLEncode($self->endpoint.'/'.$_[0]),
			'oauth_version=1.0',
			'oauth_signature_method=HMAC-SHA1',
			"oauth_timestamp=$time",
			'oauth_token='.Controller::URLEncode($self->user_config('paypalToken')),
			'oauth_consumer_key='.Controller::URLEncode($self->setting('paypal_user'))
			);

	my $sig = hmac_sha1_base64($base,$key);

	return 'time='.$time.',token='.$self->user_config('paypalToken').',signature='.$sig;	
}

sub queryParam {
	my $self = shift;
	return $self->{_nvpParam} unless exists $_[0]; #Hash ref
	$self->{_nvpParam}{$_[0]} = $_[1]  if exists $_[1];
	return $self->{_nvpParam}{$_[0]};
}

sub nvpLogin {
	my $self = shift;
	
	if ($self->{_sandbox} == 0 || $self->{_myLogin}) {
		$self->queryParam('USER',$self->setting('paypal_user'));
		$self->queryParam('PWD',$self->setting('paypal_pass'));
		$self->queryParam('SIGNATURE',$self->setting('paypal_sign'));
	} else { #In the Sandbox, you can always use the following signature:
		$self->queryParam('USER','sdk-three_api1.sdk.com');
		$self->queryParam('PWD','QFZCWN');
		$self->queryParam('SIGNATURE','A-IzJhZZjhg29XQ2qnhapuw');
	}
}


sub setExpressCheckoutBA {
	my $self = shift;
	
	$self->queryParam('METHOD','SetExpressCheckout');
			
	$self->nvpEndpoint;
	 
	$self->queryParam('PAYMENTREQUEST_0_PAYMENTACTION','Authorization');
	$self->queryParam('PAYMENTREQUEST_0_AMT','0.00');
	$self->queryParam('L_BILLINGTYPE0','MerchantInitiatedBillingSingleAgreement'); #MerchantInitiatedBillingSingleAgreement if you need only one billing agreement between you and the buyer. Use MerchantInitiatedBilling to create a billing agreement between you and the buyer each time you call DoExpressCheckoutPayment.
	$self->queryParam('L_PAYMENTTYPE0','instantonly');
	$self->queryParam('L_BILLINGAGREEMENTDESCRIPTION0',#'BA_DESC',
					$self->DefaultEnterprise
					?	$self->lang(2352,$self->enterprise('nome'))
					:	$self->lang(2353)
					); #? purchase Time Magazine
	$self->queryParam('L_BILLINGAGREEMENTCUSTOM0','Agreement time: '.$self->calendar_local('timedate')); #?add magazine subscription	
	$self->queryParam('RETURNURL',$self->returnURL());	 
	$self->queryParam('CANCELURL',$self->cancelURL());
	$self->queryParam('PAYMENTREQUEST_0_CURRENCYCODE',$self->setting('currency'));
	
	if ($self->nvpRequest()) { 
		my $response = $self->response();
		if ($response->{'ACK'} eq 'Success') {
			return $response->{'TOKEN'};
		} else {
			$self->set_error($self->lang('2350',$response->{'L_LONGMESSAGE0'}));
			return undef;
		}			
	} else {
		return undef;
	}
}

sub getExpressCheckoutDetails {
	my $self = shift;

	$self->queryParam('METHOD','GetExpressCheckoutDetails');
			
	$self->nvpEndpoint;
	
	$self->queryParam('TOKEN',$_[0]);
	
	if ($self->nvpRequest()) { 
		my $response = $self->response();
		if ($response->{'ACK'} eq 'Success') {	
			$self->user_config('paypalEMAIL',$response->{'EMAIL'});
			$self->user_config('paypalPAYERID',$response->{'PAYERID'});
			$self->user_config('paypalSHIPTOCOUNTRYNAME',$response->{'SHIPTOCOUNTRYNAME'});
			$self->user_config('paypalSHIPTONAME',$response->{'SHIPTONAME'});
			$self->user_config('paypalSHIPTOSTATE',$response->{'SHIPTOSTATE'});
			$self->user_config('paypalSHIPTOZIP',$response->{'SHIPTOZIP'});
			$self->user_config('paypalSHIPTOCITY',$response->{'SHIPTOCITY'});
			$self->user_config('paypalPAYERSTATUS',$response->{'PAYERSTATUS'});	
			use Controller::Users;
			$self->Controller::Users::save_config;					
			return 1;
		} else {
			$self->set_error($self->lang('2350',$response->{'L_LONGMESSAGE0'}));
			return 0;
		}			
	} else {
		return 0;
	}
}

sub createBillingAgreement {
	my $self = shift;
	
	$self->queryParam('METHOD','CreateBillingAgreement');
			
	$self->nvpEndpoint;
	
	$self->queryParam('TOKEN',$_[0]);	
	
	if ($self->nvpRequest()) { 
		my $response = $self->response();
		if ($response->{'ACK'} eq 'Success') {	
			$self->user_config('paypalBAID',$response->{'BILLINGAGREEMENTID'});
			$self->user_config('paypalCORRELATIONID',$response->{'CORRELATIONID'});
			use Controller::Users;
			$self->Controller::Users::save_config;						
			return 1;
		} else {
			$self->set_error($self->lang('2350',$response->{'L_LONGMESSAGE0'}));
			return 0;
		}			
	} else {
		return 0;
	}
}

sub doReferenceTransaction { #Não garante que o pagamento foi realmente efetuado
	my $self = shift;
	return 0 if $self->invoice('nossonumero') > 0;
	unless ($self->user_config('paypalBAID')) {
		$self->set_error($self->lang(2354));
		return 0;
	}
	
	$self->queryParam('METHOD','DoReferenceTransaction');
			
	$self->nvpEndpoint;
	
	$self->queryParam('REFERENCEID',$self->user_config('paypalBAID'));
	$self->queryParam('PAYMENTACTION','Sale');
	$self->queryParam('PAYMENTTYPE','instantonly');	
	$self->queryParam('AMT',$self->round($self->invoice('valor')));
	$self->queryParam('CURRENCYCODE',$self->setting('currency'));
	$self->queryParam('INVNUM',$self->invid);	
	$self->queryParam('MSGSUBID',$self->invid);
	$self->queryParam('DESC',$self->invoice('referencia'));
	
	if ($self->nvpRequest()) { 
		my $response = $self->response();
		if ($response->{'ACK'} eq 'Success') {	
			$self->invoice('nossonumero',$response->{'TRANSACTIONID'});
			$self->execute_sql(479,$response->{'TRANSACTIONID'},$self->invid);
			return wantarray 
				? (
					'TRANSACTIONID' => $response->{'TRANSACTIONID'},
					'AMT' => Controller::valor2num($response->{'AMT'}),
					'FEEAMT' => Controller::valor2num($response->{'FEEAMT'}),
					'PAYMENTSTATUS' => $response->{'PAYMENTSTATUS'},
					'CURRENCYCODE' => $response->{'CURRENCYCODE'},
					'EXCHANGERATE' => Controller::valor2num($response->{'EXCHANGERATE'}),
					'SETTLEAMT' => Controller::valor2num($response->{'SETTLEAMT'}),
				 ) 
				 : 1;
		} else {
			$self->set_error($self->lang('2350',$response->{'L_LONGMESSAGE0'}));
			return wantarray ? {}: 0;
		}	
		
	} else {
		return 0;
	}
}

sub getTransactionDetails { #Verifica se uma transação foi realmente efetuada
	my $self = shift;
	
	$self->queryParam('METHOD','GetTransactionDetails');
			
	$self->nvpEndpoint;

	$self->queryParam('TRANSACTIONID',$self->invoice('nossonumero'));
	
	if ($self->nvpRequest()) { 
		my $response = $self->response();
		if ($response->{'ACK'} eq 'Success' && $response->{'PAYMENTSTATUS'} eq 'Completed') {	
			$self->set_error($self->lang(2004,$response->{'INVNUM'})) if $response->{'INVNUM'} != $self->invid;
			return wantarray 
				? (
					'TRANSACTIONID' => $response->{'TRANSACTIONID'},
					'AMT' => $response->{'AMT'},
					'FEEAMT' => Controller::valor2num($response->{'FEEAMT'}),
					'PAYMENTSTATUS' => $response->{'PAYMENTSTATUS'},
					'CURRENCYCODE' => $response->{'CURRENCYCODE'},
					'EXCHANGERATE' => Controller::valor2num($response->{'EXCHANGERATE'}),
					'SETTLEAMT' => Controller::valor2num($response->{'SETTLEAMT'}),
				 )
				 : 1;
		} else {
			return wantarray ? {} : 0;
		}	
		
	} else {
		return 0;
	}
}

sub refundTransaction {
	my $self = shift;
	
	$self->queryParam('METHOD','RefundTransaction');
			
	$self->nvpEndpoint;
	
	$self->queryParam('TRANSACTIONID',$self->invoice('nossonumero'));
	$self->queryParam('PAYERID',$self->user_config('paypalPAYERID'));
	$self->queryParam('REFUNDTYPE','Full');
	
	if ($self->nvpRequest()) { 
		my $response = $self->response();
		if ($response->{'ACK'} eq 'Success') {	
			return $response->{'REFUNDTRANSACTIONID'};
		} else {
			return 0;
		}			
	} else {
		return 0;
	}
}

sub request {
	my ($self) = shift;
	return if $self->error;
		
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(POST => $self->endpoint().'/'.$_[0]);
	$self->login($request);
	$request->header('X-PAYPAL-MESSAGE-PROTOCOL' => 'SOAP11');
	$request->content($doc->serialize(0));
	my $response = $userAgent->request($request);

	if($response->code == 200) {
		$self->{_lastresponse} = $response->content =~ m/^<\?xml/i 
			? $self->get_return_value($response->content) : $self->set_error($response->content);
	} else {
		$self->set_error($self->lang(251,"Paypal Request $_[0]",$response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub response { $_[0]->{_lastresponse}; }

sub redirectLogin {
	my $self = shift;
	
	if ($_[0] eq '_grant-permission') {
		return $self->{_sandbox} == 0 
			? 'https://www.paypal.com/cgi-bin/webscr?cmd='.$_[0].'&request_token=' 
			: 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd='.$_[0].'&request_token=';
	} elsif ($_[0] eq '_express-checkout') {
		return $self->{_sandbox} == 0 
			? 'https://www.paypal.com/cgi-bin/webscr?cmd='.$_[0].'&token='
			: 'https://www.sandbox.paypal.com/cgi-bin/webscr?cmd='.$_[0].'&token=';
	}
}

sub nvpRequest {
	my ($self) = shift;
	return if $self->error;	
		
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);	
	my $request = HTTP::Request->new(POST => $self->endpoint());
	$self->nvpLogin;
	$self->queryParam('VERSION','94.0');	

	$request->content($self->Hash2Query($self->queryParam()));
	$request->content_type("application/x-www-form-urlencoded");	
	my $response = $userAgent->request($request);
	
	if($response->code == 200) {		
		$self->{_lastresponse} = $self->Query2Hash($response->content);
	} else {
		$self->set_error($self->lang(251,"Paypal nvpRequest $_[0]",$response->content));
	}
				
	return $self->error ? 0 : 1;
}

#######################################
# Cron Calls						  #
#######################################
sub doBilling {
	return 0;
}

sub posBilling {
	my $self = shift;
	#Ignorar esses erros quando rodado no Agendador de tarefas
	$self->logcronRemove;
	return 1;
}

sub payDay {
	my $self = shift;
	
	my $response = $self->invoice('nossonumero') > 0 ? $self->getTransactionDetails : $self->doReferenceTransaction;
	if ($response->{'PAYMENTSTATUS'} eq 'Completed') {		
		$self->invoice('valor_pago',$response->{'SETTLEAMT'});
		$self->invoice('data_quitado',$self->today());
		$self->variable('threshold',$response->{'AMT'});
	} else {
		return 0;
	}
	
	return $self->error ? 0 : 1;
}

#######################################
# Implementa a interface de Pagamento #
#######################################
sub Controller::Interface::Users::chooseIt {
	my $self = shift;
	my $q = shift;

	unless ($q->url_param('token')) {
		$self->cancelURL($self->setting('baseurl') . '/' . $self->template('__FILE__') . '?do=forma');
		$self->returnURL($self->setting('baseurl') . '/' . $self->template('__FILE__') . '?do=forma&forma='.$self->tid);
		
		my $token = $self->setExpressCheckoutBA;
		print $q->redirect($self->redirectLogin('_express-checkout').$token);		
		exit(0); #Success
	} else { 
		my $token = $q->url_param('token');
		
		$self->getExpressCheckoutDetails($token) ?
			$self->createBillingAgreement($token) ?
				$self->execute_sql(671,$self->tid,$self->uid)
			: return 0		
		: return 0;					

		return 1;
	}
}

1;
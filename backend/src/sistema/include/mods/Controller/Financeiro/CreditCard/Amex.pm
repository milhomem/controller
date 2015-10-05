#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008
package Controller::Financeiro::CreditCard::Amex;

require 5.008;
require Exporter;

use Controller::Financeiro;
use LWP::UserAgent;

use vars qw(@ISA $VERSION $tidproximo);
@ISA = qw(Controller::Financeiro Controller::Financeiro::CreditCard Controller::XML Exporter);

$VERSION = "0.1";

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
	my %result = $_[0]->amex_authorize;
	return $result{'authorized'} == 1 ? $_[0]->amex_capture : %result;
}
sub cc_refund { return undef unless $_[0]->invid; return $_[0]->amex_refund; }
sub cc_verify { 
	$_[0]->set_error($_[0]->lang(3,'cc_capture')) and return undef unless $_[0]->ccid;
	my $rand = 'TEST'.$_[0]->randthis(4,0 .. 9);
	local *invid = sub { return $rand };#Teste
	$_[0]->invoice('valor',$_[1]);
	my %result = $_[0]->amex_authorize;
	$_[0]->set_error($result{'response'}) unless $result{'authorized'} == 1;
	return $result{'authorized'}; 
} #need tid before

sub amex_authorize { 
	my $self = shift;
	return if $self->error;

	my $num = $self->invoice('parcelas') || 1; #Mínimo uma
	my $tipo = $self->invoice('parcelado');
	
	VPCConnection::reset();
	
	VPCConnection::addCommandField("vpc_Version", 1);
	VPCConnection::addCommandField("vpc_Command", 'pay');
	VPCConnection::addCommandField("vpc_AccessCode", $self->setting('amex_accesscode'));
	VPCConnection::addCommandField("vpc_MerchTxnRef", $self->invid.'-A');
	VPCConnection::addCommandField("vpc_Merchant", $self->setting('amex_merchantid'));
	VPCConnection::addCommandField("vpc_OrderInfo", $self->invid);#Para procurar no site de administracao
	VPCConnection::addCommandField("vpc_Amount", Controller::num2valor($self->invoice('valor')));

	#Parcelamento
	if ($tipo eq 'O' && $num > 1) {
		VPCConnection::addCommandField("vpc_PlanAmex", 'PlanAmex');
		VPCConnection::addCommandField("vpc_numPayments", $num); #1 - 24		
	} elsif ($tipo eq 'L' && $num > 1) {
		VPCConnection::addCommandField("vpc_planN", 'PlanN');
		VPCConnection::addCommandField("vpc_numPayments", $num);
	} #Else a vista

	# add Card Details
	VPCConnection::addCommandField("vpc_CardNum", $self->creditcard('ccn'));
	my $exp = substr($self->creditcard('exp'),2,2).substr($self->creditcard('exp'),0,2);
	VPCConnection::addCommandField("vpc_CardExp", $exp);
	 
	VPCConnection::addCommandField("vpc_CardSecurityCode", $self->creditcard('cvv2')) if $self->creditcard('cvv2');

	$self->amex_command('authorize', VPCConnection::getPostData());
	my $code = VPCConnection::getResultField("vpc_TxnResponseCode","Desconhecido");
	my $error = $self->getResponseDescription($code);
	my $auth = $code eq '0' ? 1 : 0;

	if ($auth == 1) {
		my $vpc_TransactionNo = VPCConnection::getResultField("vpc_TransactionNo","Desconhecido");
		$self->invoice('nossonumero',$vpc_TransactionNo); #TID
		$self->execute_sql(479,$vpc_TransactionNo,$self->invid) unless $self->invid =~ m/^TEST/;
	}
		
	return ('authorized' => $auth, 'response' => $error);
}

sub amex_capture {
	my $self = shift;
	return if $self->error;
	
	my $vpc_Amount = VPCConnection::getResultField("vpc_Amount","Desconhecido");
	my $vpc_Version = VPCConnection::getResultField("vpc_Version","Desconhecido");
	my $vpc_Merchant = VPCConnection::getResultField("vpc_Merchant","Desconhecido");
	my $vpc_TransactionNo = VPCConnection::getResultField("vpc_TransactionNo","Desconhecido");
	$self->invoice('nossonumero', $vpc_TransactionNo);	

	#Capture only if no duplicates
	return !VPCConnection::reset() if $self->amex_querydr;

	# Add the core MerchTxnRef field. Note: Adds "-C" to the end to keep the
	# MerchTxnRef unique for both the Auth and Capture.
	VPCConnection::addCommandField("vpc_MerchTxnRef", $self->invid.'-C');
	# Add the rest of the Command request data
	VPCConnection::addCommandField("vpc_Version", $vpc_Version);
	VPCConnection::addCommandField("vpc_Command", 'capture');
	VPCConnection::addCommandField("vpc_AccessCode", $self->setting('amex_accesscode'));
	VPCConnection::addCommandField("vpc_Merchant", $vpc_Merchant);
	VPCConnection::addCommandField("vpc_TransNo", $vpc_TransactionNo);
	VPCConnection::addCommandField("vpc_Amount", $vpc_Amount);
	VPCConnection::addCommandField("vpc_User", $self->setting('amex_capuser')); #usuario de captura
	VPCConnection::addCommandField("vpc_Password", $self->setting('amex_cappass'));
	
	$self->amex_command('capture', VPCConnection::getPostData());

	# Standard Response Fields
	my $Capture_TxnResponseCode = VPCConnection::getResultField("vpc_TxnResponseCode","Desconhecido");
	my $vpc_CapturedAmount = VPCConnection::getResultField("vpc_CapturedAmount","Desconhecido");

	$Capture_TxnResponseCode ne '0'
		? $self->set_error($self->getResponseDescription($Capture_TxnResponseCode))
		: return ('authorized' => 1, 'valor' => Controller::valor2num($vpc_CapturedAmount), 'response' => $self->getResponseDescription($Capture_TxnResponseCode));
}

sub amex_querydr {#True is fail
	my ($self) = shift;
	return 1 if $self->error;
	
	VPCConnection::reset();
	
	VPCConnection::addCommandField("vpc_Version", 1);
	VPCConnection::addCommandField("vpc_Command", 'queryDR');
	VPCConnection::addCommandField("vpc_AccessCode", $self->setting('amex_accesscode'));
	VPCConnection::addCommandField("vpc_MerchTxnRef", $self->invid.'-C');
	VPCConnection::addCommandField("vpc_Merchant", $self->setting('amex_merchantid'));
	VPCConnection::addCommandField("vpc_User", $self->setting('amex_capuser')); #usuario de captura
	VPCConnection::addCommandField("vpc_Password", $self->setting('amex_cappass'));
	
	$self->amex_command('querydr', VPCConnection::getPostData());
	
	# QueryDR Response Fields
	my $vpc_DRExists = VPCConnection::getResultField("vpc_DRExists","Desconhecido");
	my $vpc_FoundMultipleDRs = VPCConnection::getResultField("vpc_FoundMultipleDRs","Desconhecido");
	return 0 if ($vpc_DRExists eq 'N') || ($vpc_DRExists eq 'Y' && $vpc_FoundMultipleDRs eq 'N');
	$self->set_error($self->lang(2200));#Duplicated
	return 1;
}

sub amex_refund {
	my ($self) = shift;
	return if $self->error;
	
	#my $VERSION = '2.0.2';
	VPCConnection::reset();	
	$self->actid($self->invoice('conta'));
	VPCConnection::addCommandField("vpc_Version", 1);
	VPCConnection::addCommandField("vpc_Command", 'refund');
	VPCConnection::addCommandField("vpc_AccessCode", $self->setting('amex_accesscode'));
	VPCConnection::addCommandField("vpc_MerchTxnRef", $self->invid.'-C');
	VPCConnection::addCommandField("vpc_Merchant", $self->setting('amex_merchantid'));
	VPCConnection::addCommandField("vpc_Amount", Controller::num2valor($self->invoice('valor')));
	VPCConnection::addCommandField("vpc_TransNo", $self->invoice('nossonumero') );
	VPCConnection::addCommandField("vpc_User", $self->setting('amex_capuser')); #usuario de captura
	VPCConnection::addCommandField("vpc_Password", $self->setting('amex_cappass'));
	
	$self->amex_command('refund', VPCConnection::getPostData());
	
	my $vpc_TxnResponseCode = VPCConnection::getResultField("vpc_TxnResponseCode","Desconhecido");
	# Capture Response Fields
	my $vpc_CapturedAmount = VPCConnection::getResultField("vpc_CapturedAmount","Desconhecido");

	return (
				'valor' => $vpc_CapturedAmount,
				'response' => $self->getResponseDescription($vpc_TxnResponseCode),
				'TID' => $self->invoice('nossonumero'),
				'code' => $vpc_TxnResponseCode
		   	);
}

sub amex_command {
	my ($self) = shift;
	return if $self->error;

	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(POST => $self->setting('gateway_amex'));

	$request->content(Controller::trim($_[1]));
	$request->content_type("application/x-www-form-urlencoded");
	my $response = $userAgent->request($request);

	if($response->code == 200) { 
		VPCConnection::processCommandResponseText($response->content);
		return $response;
	} else {
		$self->set_error($self->lang(251,"Command $_[0]",$response->error_as_HTML));
	}
				
	return $self->error ? 0 : 1;
}

# This method uses the CSC Response code retrieved from the Digital
# Receipt and returns an appropriate description for the CSC Response Code
sub getCSCDescription ($)
{
	shift;
	my ($resultCode) = @_;
	my %cscResult = (
		Unsupported => "CSC not supported or there was no CSC data provided",
		M           => "Exact code match",
		S           => "Merchant has indicated that CSC is not present on the card (MOTO situation)",
		P           => "Code not processed",
		U           => "Card issuer is not registered and/or certified",
		N           => "Code invalid or not matched"
	);

	if ( defined($resultCode) and exists $cscResult{$resultCode} ) {
		return $cscResult{$resultCode};
	}
	else
	{
		return "Unable to be determined";
	}
}
# This method uses the AVSResultCode retrieved from the Digital Receipt
# and returns an appropriate description
sub getAVSDescription ($)
{
	shift;
	my ($resultCode) = @_;
	my %avsResult =
	(
		Unsupported => "AVS not supported or there was no AVS data provided",
		X => "Exact match - address and 9 digit ZIP/postal code",
		Y => "Exact match - address and 5 digit ZIP/postal code",
		S => "Service not supported or address not verified (international transaction)",
		G => "Issuer does not participate in AVS (international transaction)",
		A => "Address match only.",
		W => "9 digit ZIP/postal code matched, Address not Matched",
		Z => "5 digit ZIP/postal code matched, Address not Matched",
		R => "Issuer system is unavailable",
		U => "Address unavailable or not verified",
		E => "Address and ZIP/postal code not provided",
		N => "Address and ZIP/postal code not matched",
		0 => "AVS not requested"
	);

	if ( defined($resultCode) and exists $avsResult{$resultCode} ) {
		return $avsResult{$resultCode};
	}
	else
	{
		return "Unable to be determined";
	}
}
# This method uses the QSIResponseCode retrieved from the Digital Receipt
# and returns an appropriate description
sub getResponseDescription ($)
{
	my $self = shift;
	my ($responseCode) = @_;
	my %qsiResponse = 
	(
		Desconhecido => $self->lang(2201),
		0   => $self->lang(2202),
		'?' => $self->lang(2203),
		1   => $self->lang(2204),
		2   => $self->lang(2205),
		3   => $self->lang(2206),
		4   => $self->lang(2207),
		5   => $self->lang(2208),
		6   => $self->lang(2209),
		7   => $self->lang(2210),
		8   => $self->lang(2211),
		9   => $self->lang(2212),
		A   => $self->lang(2213),
		B   => $self->lang(2214),
		C   => $self->lang(2215),
		D   => $self->lang(2216),
		F   => $self->lang(2217),
		I   => $self->lang(2218),
		L   => $self->lang(2219),
		N   => $self->lang(2220),
		P   => $self->lang(2221),
		R   => $self->lang(2222),
		S   => $self->lang(2223),
		T   => $self->lang(2224),
		U   => $self->lang(2225),
		V   => $self->lang(2226)
	);

	if ( defined($responseCode) and exists $qsiResponse{$responseCode} ) {
		return $qsiResponse{$responseCode} . ": " . Controller::URLDecode(VPCConnection::getResultField("vpc_Message","Desconhecido"));
	}
	else
	{
		return "Erro desconhecido";
	}
}

sub brandlogo {
	return 'amex.png';
}

sub brandname {
	return 'Amex';
}
1;
#####Original Package###########
package VPCConnection;

# Initialisation
# ==============
# Use the required Perl Libraries
# -------------------------------
use strict;
use CGI;
use Digest::MD5 qw (md5_hex);

#use diagnostics;

my $VERSION = '2.0.2';

# This variable defines if the code is going to opperate in debug mode.
# Debug mode writes all socket communications to standard error so that
# errors with communications can be debugged.
my $DEBUG = 0;

my %ORDER_FIELDS;
my %RESPONSE_FIELDS;

# This sub allows an external application to determine the version of this
# package
sub getPackageVersion ()
{
	return $VERSION;
};

# This sub allows an external application to set the debug parameter in this package
sub setDebug($)
{
	my ( $debugvalue) = @_;
	$DEBUG=$debugvalue;
	return 1;
};

# This sub clears all the command data so that a new command can be performed
sub reset ()
{
	%ORDER_FIELDS=undef;
	%RESPONSE_FIELDS=undef;
	return 1;
};

# Utility function for URL Decode
my $urldecode = sub ($)
{
	my ( $value ) = @_;
	
	return CGI::unescapeHTML($value);
};

# Utility function for URL Encode
my $urlencode = sub ($)
{
	my ( $value ) = @_;
	
	return CGI::escapeHTML($value);
};

# This is a utility sub that formats a date correctly to be added to the
# Digital Order, i.e. YYMM
sub formatExpiryDate($$)
{
	my ( $month, $year ) = @_;
	
	if (length($month) < 2)
	{
		$month = sprintf("%02d",$month);
	}
	
	if (length($month) > 2)
	{
		$month = substr($month,-2);
	}

	if (length($year) < 2)
	{
		$year = sprintf("%02d",$year);
	}
	
	if (length($year) > 2)
	{
		$year = substr($year,-2);
	}
	
	return $year . $month;
};

# This sub performs retireves the value of the specified field from the Command's response
sub getResultField($$)
{
	my ( $fieldName, $defaultValue ) = @_;

	if ( exists($RESPONSE_FIELDS{$fieldName}) )
	{
		return $RESPONSE_FIELDS{$fieldName};
	} else {
		if ( defined($defaultValue) )
		{
			return $defaultValue;
		} else {
			return undef;
		}
	}
};

# This sub retrieves the QSI Response Code (if it is available)
sub getQSICode()
{
	my $qsiCode = getResultField('vpc_TxnResponseCode',"");
	if ( defined($qsiCode) )
	{
		return $qsiCode;
	} else {
		return undef;
	}
};

# This sub performs adds a field to the data that will be used to execute the command
sub addCommandField($$)
{
	my ( $fieldName, $fieldValue ) = @_;
	return 0 unless $fieldName;
	
	if ( !defined($fieldValue) )
	{
		$fieldValue="";
	}
	
	$ORDER_FIELDS{&$urlencode($fieldName)} = &$urlencode($fieldValue);
	return 1;
};

# This sub executes the command using a syncronous method (2 Party via HTTP POST)
sub getPostData()
{
	my $postData="";
	my $key="";
	my $value="";
	my $separator="";
	foreach $key (keys %ORDER_FIELDS)
	{
		$value=$ORDER_FIELDS{$key};
		
		# HTTP encode key and value
		$key=&$urlencode($key);
		$value=&$urlencode($value);
		
		# Add the HTTP encoded data to the POST data
		$postData .= $separator.$key."=".$value;
		$separator="&";
	}
	return $postData;
};

# This sub constructs a URL with the command parameters encoded in the QueryString (HTTP GET)
sub getCommandURL($)
{
	my ( $vpcURL ) = @_;
	
	my $key="";
	my $value="";
	my $separator="?";
	foreach $key ( keys %ORDER_FIELDS )
	{
		$value=$ORDER_FIELDS{$key};
		
		# HTTP encode key and value
		$key=&$urlencode($key);
		$value=&$urlencode($value);
		
		# Add the HTTP encoded data to the POST data
		$vpcURL .= $separator.$key."=".$value;
		$separator="&";
	}
	return $vpcURL;
};

# This sub creates the secure hash that is used to sign the command fields.
# This signature is used to protect the data from modfication in transit to the
# Payment Gateway.
sub signCommandData($) 
{
	my ( $secureSecret ) = @_;
	
	if ( !defined($secureSecret) ) 
	{
		$secureSecret = "";
	}

	if ( exists($ORDER_FIELDS{'vpc_SecureHash'}) )
	{
		delete($ORDER_FIELDS{'vpc_SecureHash'});
	}

	my $singatureDataString = $secureSecret;
	foreach my $key (sort keys %ORDER_FIELDS)
	{
		$singatureDataString .= $ORDER_FIELDS{$key};
	}

	$ORDER_FIELDS{'vpc_SecureHash'} = md5_hex($singatureDataString);
	return 1;
};

# This sub checks the secure hash that is has been returned in the command respose
# to ensure the data has not been modified in transit from the Payment Gateway.
sub checkResponseSignature($) 
{
	my ( $secureSecret ) = @_;
	
	my %ResponseFieldsLocal = %RESPONSE_FIELDS;
	
	if ( !defined($secureSecret) ) 
	{
		$secureSecret = "";
	}

	if ( exists($ResponseFieldsLocal{'vpc_SecureHash'}) )
	{
		delete($ResponseFieldsLocal{'vpc_SecureHash'});
	}

	my $singatureDataString = $secureSecret;
	foreach my $key (sort keys %ResponseFieldsLocal)
	{
		$singatureDataString .= $ResponseFieldsLocal{$key};
	}

	my $signature = md5_hex($singatureDataString);
	
	if ( uc $signature eq uc $RESPONSE_FIELDS{'vpc_SecureHash'} )
	{
		return 1;
	} else {
		return 0;
	}
};

# This sub processess the QueryString reposnse from an Asyncronous Command (3 Party)
sub processCommandResponseHash(%)
{
	my ( %CommandResponse ) = @_;
	
	foreach my $key (sort keys %CommandResponse)
	{
		$RESPONSE_FIELDS{&$urldecode($key)} = &$urldecode($CommandResponse{$key});
	}

	return 1;
};

# This sub processes the content text from a HTTP POST syncronous Command (2 Party)
sub processCommandResponseText($)
{
	my ( $CommandResponse ) = @_;
	
	if ( !defined($CommandResponse) )
	{
		return 0;
	}
	
	my @tuplesArray = split(/&/,$CommandResponse);
	
	foreach my $tuple (@tuplesArray)
	{
		(my $fieldName, my $fieldValue) = split(/=/, $tuple, 2);
		$RESPONSE_FIELDS{&$urldecode($fieldName)} = &$urldecode($fieldValue);
	}

	return 1;
};
1;
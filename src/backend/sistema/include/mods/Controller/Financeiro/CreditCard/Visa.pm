#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008
package Controller::Financeiro::CreditCard::Visa;

require 5.008;
require Exporter;

use Controller::Financeiro;
use Controller::XML;
use LWP::UserAgent;

use vars qw(@ISA $VERSION $tidproximo $LANG);
@ISA = qw(Controller::Financeiro Controller::Financeiro::CreditCard Controller::XML Exporter);

$VERSION = "0.1";
$LANG = 'pt';

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
	my %result = $_[0]->visa_authorize;
	return $result{'authorized'} == 1 ? $_[0]->visa_capture : %result;
}
sub cc_refund { 
	return undef unless $_[0]->invid; 
	my %result = $_[0]->visa_cancel;
	return ( 
			'valor' => $result{'CANCEL_AMOUNT'}[0]{'content'},
			'response' => $result{'response'},
			'TID' => $result{'TID'}[0]{'content'},
			'codigo' => $result{'LR'}[0]{'content'}
		   );
	 }
sub cc_verify { 
	$_[0]->set_error($_[0]->lang(3,'cc_capture')) and return undef unless $_[0]->ccid;
	my $rand = 'TEST'.$_[0]->randthis(4,0 .. 9);
	local *invid = sub { return $rand };#Teste
	$_[0]->invoice('valor',$_[1]);
	$_[0]->invoice('parcelado','S');
	my %result = $_[0]->visa_authorize;
	$_[0]->set_error($result{'response'}) unless $result{'authorized'} == 1;
	return $result{'authorized'}; 
} #need tid before

sub TID {
	my ($self, $parc)= @_;
	return if $self->error; #verifica erro antes de continuar
		
	#visa
	my $shopid = $self->setting('visa_merchantid');
	my $pagamento = $parc; #sempre a vista no credito

	$self->set_error($self->lang(2100)) if length($shopid) != 10;
	$self->set_error($self->lang(2101)) unless $self->num($shopid);
	$shopid = substr($shopid,4,5);
	
	sleep 1, $tidproximo = 0 if $tidproximo > 9;
	#Hora Minuto Segundo e Décimo de Segundo
	my ($hora,$minuto,$segundo) = $self->timenow;
	#Na falta do décimo de segundo "d", utilizar função "proximo"
	my $hhmmssd = substr('00'.$hora,-2).substr('00'.$minuto,-2).substr('00'.$segundo,-2).$tidproximo++;
	#Obter Data Juliana
	my $datajuliana = substr("000" . $self->julianday(), -3);
	#obter último dígito do ano
	my $ano = substr($self->year,-1);
	#Formatar Tid
	my $tid = $shopid.$ano.$datajuliana.$hhmmssd.$pagamento;
	$self->set_error($self->lang(2117, $tid)) if length($tid) != 20;

	return $tid;
}

sub response { $_[0]->{_lastresponse}; }

#("TID") 'Cod. da Transação
#("LR")'Codigo de Retorno
#("ARP")' Código de Autorização
#("ARS") 'Descricao do Erro
#("PRICE")'valor da compra 100 = 1,00
#("FREE")'Campo livre
#("ORDERID")'Número do Pedido interno da Loja
#("BANK")'Código do banco emissor do cartão
sub process_response {
	my ($self) = shift;
	return if $self->error; #verifica erro antes de continuar
		
	my $response = $self->response;
	my %result = %{$self->xml2perl(($response->toString(0)))} unless $self->error;

    if ($result{'LR'}[0]{'content'} =~ m/^(?:0|00|11)$/) {
    	if ($result{'ORDERID'}[0]{'content'}) {
    		$self->set_error($self->lang(2115,$self->invid, $result{'ORDERID'}[0]{'content'})) if $self->invid != $result{'ORDERID'}[0]{'content'};
    		$self->set_error($self->lang(2116,$self->num2valor($self->invoice('valor')),$result{'PRICE'}[0]{'content'})) if Controller::num2valor($self->invoice('valor')) != $result{'PRICE'}[0]{'content'};
    	}
		return wantarray ? %result : $result{'ARS'}[0]{'content'};
    } elsif ($result{'LR'}[0]{'content'} =~ m/^(?:201|255)$/) { #consultar status com inquire
    	sleep 5;
    	my ($package, $filename, $line, $subroutine) = caller(1);
    	$self->invoice('nossonumero',$result{'TID'}[0]{'content'}) unless $self->invoice('nossonumero'); #Mater TID
    	$self->set_error($result{'ARS'}[0]{'content'}) && return if $subroutine =~ m/inquire/gi;
    	return $self->visa_inquire if $self->invoice('nossonumero');
    } elsif ($result{'LR'}[0]{'content'} =~ m/^(?:6|19|55|81|82|83|86|15|91|98|99|108|112|203)$/) { #tentar mais tarde
		return wantarray ? %result : $result{ARS}[0]{'content'};
    } else { #nao tentar até resolver o problema.
    	my $err = $self->visa_error($result{'LR'}[0]{'content'}) || $result{'ARS'}[0]{'content'};
		$self->set_error( defined $result{'LR'}[0]{'content'} ? $err : $response->toString(1));
		return undef;
	}	
}

sub visa_transaction {
	my $self = shift;
	return if $self->error;
	
	my $post = "tid=".$self->invoice('nossonumero');
	$post .= '&price='.Controller::num2valor($self->invoice('valor'));
	
	$self->visa_command('transaction.asp', $post);
}

sub visa_tipo {
	my $self = shift;
	
	return '1001' if $_[0] eq 'S' || $_[1] < 2; #1001 A Vista
	return '2' if $_[0] eq 'L';	#2xxx Parcelado Loja 2x+
	return '3' if $_[0] eq 'O';	#3xxx Parcelado Administradora 2x+
	return 'A001' if $_[0] eq 'D'; #A001 Visa Electron
	die $self->lang(3,'visa_tipo');
}

sub visa_authorize { #Tipo Moset, pagamento recorrente, não é vbv
	my $self = shift;
	return if $self->error;
	
	if ($self->invoice('nossonumero')) { #testar para saber se foi aprovada
		my %result = $self->visa_inquire;
		my $auth = $result{'LR'}[0]{'content'} =~ m/^(?:0|00|11)$/ ? 1 : 0;
		my $error = $self->visa_error($result{'LR'}[0]{'content'}) || $result{'LR'}[0]{'content'};
		return ('authorized' => $auth, 'valor' => Controller::valor2num($result{'PRICE'}[0]{'content'}), 'response' => $error);
	}
	
	my $num = $self->invoice('parcelas') || 1; #Mínimo uma
	my $tipo = $self->invoice('parcelado');
	
	my $parc = $self->visa_tipo($tipo,$num) . substr('000'.$num, -3);
	my $tid = $self->TID(substr($parc,0,4)); #Não importa as parcelas se o tipo for S ou D
	my $post = 'tid=' . $tid ; #tid precisa do acctid
	$post .= '&tidmaster=' . $self->invoice('nossonumero') if $self->invoice('nossonumero'); 
	$post .= '&merchid=' . $self->setting('visa_merchantid');
	$post .= '&order=' . $self->invid;
	$post .= '&orderid=' . $self->invid;
	$post .= '&free=';
	my $exp = substr($self->creditcard('exp'),2,2).substr($self->creditcard('exp'),0,2); #Visa é invertido: aamm
	$post .= '&ccn='.$self->creditcard('ccn').'&exp='.$exp;
	$post .= '&cvv2='.$self->creditcard('cvv2') if $self->creditcard('cvv2');
	$post .= '&price='.Controller::num2valor($self->invoice('valor'));

	$self->visa_command('authorize.exe', $post);
	my %result = $self->process_response;

	if ($result{'TID'}[0]{'content'} && !$self->error) {
		$self->invoice('nossonumero',$result{'TID'}[0]{'content'}); #Mater TID
		$self->execute_sql(479,$result{'TID'}[0]{'content'},$self->invid) unless $self->invid =~ m/^TEST/;
		my $auth = $result{'LR'}[0]{'content'} =~ m/^(?:0|00|11)$/ ? 1 : 0;
		my $error = $self->visa_error($result{'LR'}[0]{'content'}) || $result{'LR'}[0]{'content'};
		return ('authorized' => $auth, 'valor' => Controller::valor2num($result{'PRICE'}[0]{'content'}), 'response' => $error);
	}
	
	return ('authorized' => 0);
}

sub visa_inquire {
	my $self = shift;
	return if $self->error;
	
	my $post = 'tid=' . $self->invoice('nossonumero');
	$post .= '&merchid=' . $self->setting('visa_merchantid');
	$post .= '&free=';
	$post .= '&price='.Controller::num2valor($self->invoice('valor'));
	
	$self->visa_command('private/inquire.exe', $post);	
	
	my %result = $self->process_response;

	return $self->error ? undef : %result;
}

sub visa_capture {
	my $self = shift;
	return if $self->error;

	if ($self->invoice('nossonumero')) { #testar para saber se foi aprovada
		my %result = $self->visa_inquire;
		my $auth = $result{'LR'}[0]{'content'} =~ m/^(?:0|00|11)$/ ? 1 : 0;
		my $error = $self->visa_error($result{'LR'}[0]{'content'}) || $result{'LR'}[0]{'content'};
		return ('authorized' => $auth, 'valor' => Controller::valor2num($result{'PRICE'}[0]{'content'}), 'response' => $error) if $result{'ARS'}[0]{'content'} eq $self->lang(2118); 
	}
		
	my $post = 'tid=' . $self->invoice('nossonumero'); #Master TID
	$post .= '&merchid=' . $self->setting('visa_merchantid');
	$post .= '&price='.Controller::num2valor($self->invoice('valor'));
	
	$self->visa_command('private/capture.exe', $post);	
	
	my %result = $self->process_response;

	my @cap = split ',', $result{'CAP'}[0]{'content'};
	my $auth = $result{'LR'}[0]{'content'} =~ m/^(?:0|00|11)$/ ? 1 : 0;
	my $error = $self->visa_error($result{'LR'}[0]{'content'}) || $result{'LR'}[0]{'content'};	
	return ('authorized' => $auth, 'valor' => Controller::valor2num($cap[1]), 'response' => $error);
}

sub visa_cancel {
	my $self = shift;
	return if $self->error;
	
	my $post = 'tid=' . $self->invoice('nossonumero');
	$post .= '&merchid=' . $self->setting('visa_merchantid');
	$post .= '&price='.Controller::num2valor($self->invoice('valor'));
	$self->visa_command('private/cancel.exe', $post);
	
	my %result = $self->process_response;
	my $error = $self->visa_error($result{'LR'}[0]{'content'}) || $result{'ARS'}[0]{'content'};
	$result{'response'} = $error;
	
	return $self->error ? undef : %result;
}

sub visa_command {
	my ($self) = shift;
	return if $self->error; #verifica erro antes de continuar	
		
	my $userAgent = LWP::UserAgent->new(timeout => 3*60);
	my $request = HTTP::Request->new(POST => $self->setting('gateway_vbv').'/'.$_[0]);
#	$request->header(SOAPAction => "\"$NAMESPACE$_[1]\"");
	$request->content(Controller::trim($_[1].'&language='.$LANG));
	$request->content_type("application/x-www-form-urlencoded");
	my $response = $userAgent->request($request);

	if($response->code == 200) {
		$self->{_lastresponse} = $response->content =~ m/^<\?xml/i 
			? $self->get_return_value($response->content) : $self->set_error($response->content);
	} else {
		$self->set_error($self->lang(251,"Command $_[0]",$response->content));
	}
				
	return $self->error ? 0 : 1;
}

sub visa_error {
	my $self = shift;
	
	my %Lr = (
		'0' => $self->lang(2102),
		'00' => $self->lang(2102),
		'11' => $self->lang(2102),
		#codigos para nao tentar mais
		'14' => $self->lang(2103),
		'610' => $self->lang(2103),
		'1' => $self->lang(2104),
		'2' => $self->lang(2104),
		'3' => $self->lang(2104),
		'12' => $self->lang(2104),
		'13' => $self->lang(2104),
		'21' => $self->lang(2104),
		'22' => $self->lang(2104),
		'25' => $self->lang(2104),
		'28' => $self->lang(2104),
		'57' => $self->lang(2104),
		'62' => $self->lang(2104),
		'63' => $self->lang(2104),
		'76' => $self->lang(2104),
		'77' => $self->lang(2104),
		'78' => $self->lang(2119),
		'80' => $self->lang(2104),
		'93' => $self->lang(2104),
		'4' => $self->lang(2105),
		'5' => $self->lang(2105),
		'7' => $self->lang(2105),
		'41' => $self->lang(2105),
		'43' => $self->lang(2105),
		'52' => $self->lang(2105),
		'65' => $self->lang(2105),
		'53' => $self->lang(2106),
		'54' => $self->lang(2107),
		'51' => $self->lang(2108),
		#Codigos para tentar mais tarde
		'6' => $self->lang(2109),
		'19' => $self->lang(2109),
		'55' => $self->lang(2109),
		'81' => $self->lang(2109),
		'82' => $self->lang(2109),
		'83' => $self->lang(2109),
		'86' => $self->lang(2109),
		'15' => $self->lang(2110),
		'91' => $self->lang(2110),
		'98' => $self->lang(2110),
		'99' => $self->lang(2110),
		'108' => $self->lang(2111),
		'112' => $self->lang(2112),
		'203' => $self->lang(2113),
		#Codigos para consultar
		'201' => $self->lang(2114),
		'255' => $self->lang(2114),
	);
	
	return $Lr{$_[0]};
}

sub brandlogo {
	return 'visa.png';
}

sub brandname {
	return 'Visa';
}
1;
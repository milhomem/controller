#!/usr/bin/perl
#MercadoPago IPN

#Alterando o pacote
use Controller::Financeiro::MercadoPago;
$system = new Controller::Financeiro::MercadoPago;

if ($q->url_param('topic') eq 'payment') {
	my $info = $system->infoPayment($q->url_param('id'));  
	if ($system->is_valid_invoice($info->{'external_reference'}) && $system->invoice('status') ne $system->INVOICE_STATUS_QUITADO && $self->invoice('status') ne $system->INVOICE_STATUS_CANCELED && !$system->invoice('nossonumero')) {
		#$system->invoice('nossonumero',$info->{'id'});
		$system->execute_sql(479,$info->{'id'},$self->invid);
	} else {
		$system->email( To => $system->setting('MercadoPagoIPN'), From => $system->setting('adminemail'), Subject => 'Mensagens de IPN [DUPLICADA] não registrada' , Body => $info->Controller::tostring(), ctype => 'text/plain');  
	}
} else {
	$system->email( To => $system->setting('MercadoPagoIPN'), From => $system->setting('adminemail'), Subject => 'Mensagens de IPN não registrada' , Body => $q->Dump, ctype => 'text/plain');
}

print "content-type: text/plain\n\n";
print "OK";
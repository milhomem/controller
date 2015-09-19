#Alterando o pacote
use Controller::Financeiro::MercadoPago;
$system = new Controller::Financeiro::MercadoPago;

use Data::Dumper;

sub Controller::get_account {return};
sub Controller::get_payment {return};
sub Controller::get_user {return};
sub Controller::get_service {return};
sub Controller::get_services {return};
sub Controller::get_serviceprop {return};
sub Controller::get_servicesprop {return};
sub Controller::get_plan {return};
sub Controller::get_plans {return};
sub Controller::get_balance {return};
sub Controller::get_balances {return};
sub Controller::get_invoice {return};
sub Controller::get_creditcard {return};
sub Controller::get_account {return};
sub Controller::Services::save {return};
sub Controller::SQL::select_sql {return};
sub Controller::SQL::execute_sql {
	diag("execute_sql for values @_") if $DEBUG == 1;
	return};

$system->setting('marcadopago_id', '194051926894');
$system->setting('marcadopago_pass', 'a8PJV6q8wrHGhHOL9bIYGgNO');
#User
$system->uid(999999);
$system->user('vencimento','00');
$system->user('email','milhomem at is4web.com.br');
$system->user('status','CA');
$system->user('pending',0);
$system->user('conta',999999);
$system->user('forma',999999);
$system->user('alert',1);

#Fatura
$system->invid(999999);
$system->invoice('valor',0.01);
$system->invoice('username',999999);
$system->invoice('nome','Teste/2013');
$system->invoice('parcelas',1);
#$system->invoice('conta',999999);
$system->invoice('nossonumero',0);
$system->invoice('data_vencido',$system->today());
$system->invoice('data_vencimento',$system->today()+2);
$system->invoice('referencia', "(c) Hospedagem Windows Teste HW (primeirosdias) => R\$ 126,24\n* (c) crédito (d) débito");

#Pagamentos (Forma)
$system->payid(999999); #Mensal
$system->payment('nome','Mensal');
$system->payment('primeira',0);
$system->payment('intervalo',30);
$system->payment('parcelas',0);
$system->payment('pintervalo',30);
$system->payment('tipo','S');#Tipo de parcelamento O-'Operadora' L-'Loja' S-'Sistema' D-'Debito'
$system->payment('repetir',1);

if ($q->url_param('IPN') eq 'true') {
	open(IPN, '>/tmp/MercadoPago.t');
	print IPN $q->url_param('id');
	close(IPN);
} elsif (!$q->url_param('token')) {
	my $url = $system->registerCheckout;
	ok($url ne '','t/Registering checkout') or diag($system->error);
	diag("Acesse: $url");
	diag("User: $user{email} Pass: $user{pass}");
	diag('Configure o IPN para: http://debugger.is4web.com.br/sistema/TESTE_SUITE.cgi?module=MercadoPago&IPN=true');
	diag('Acesse: http://debugger.is4web.com.br/sistema/TESTE_SUITE.cgi?module=MercadoPago&token=get');	
} else {
	open(IPN, '</tmp/MercadoPago.t');
	my @id = <IPN>;
	close(IPN);	
	open(IPN, '>/tmp/MercadoPago.t');
	close(IPN);
	$system->invoice('nossonumero',$id[0]);	
	is($system->checkPayment, 'pending', 't/Verify Payment') or diag($system->clear_error);
	is($system->cancelPayment, 1, 't/Cancel Payment') or diag($system->clear_error);
	is($system->refundPayment, 0, 't/Refund Payment') or diag($system->clear_error);
}

1;
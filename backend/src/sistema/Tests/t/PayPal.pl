#Alterando o pacote
use Controller::Financeiro::PayPal;
$system = new Controller::Financeiro::PayPal;

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
$system->invid(999990);
$system->invoice('valor',1.00);
$system->invoice('username',999999);
$system->invoice('nossonumero',0);
$system->invoice('data_vencido',$system->today());

#Pagamentos (Forma)
$system->payid(999999); #Mensal
$system->payment('nome','Mensal');
$system->payment('primeira',0);
$system->payment('intervalo',30);
$system->payment('parcelas',0);
$system->payment('pintervalo',30);
$system->payment('tipo','S');#Tipo de parcelamento O-'Operadora' L-'Loja' S-'Sistema' D-'Debito'
$system->payment('repetir',1);

$system->cancelURL('http://is4web.com.br');
$system->returnURL('http://debugger.is4web.com.br/sistema/TESTE_SUITE.cgi?module=PayPal');
#Using ExpressCheckout API
unless ($q->param('token') || $q->param('BAID')) {
	my $token = $system->setExpressCheckoutBA;
	diag("Acesse: ".$system->redirectLogin('_express-checkout').$token);
	diag('Login: buy_1345213106_per at is4web.com.br Senha: 333333');
	ok( $token ne '','t/Create an Billing Agreement Step 1') or diag($system->error);
} elsif ($q->param('BAID')) {
	$system->user_config('paypalBAID',$q->param('BAID'));
	my %result = $system->doReferenceTransaction;
	is($result{'PAYMENTSTATUS'}, 'Completed', 't/Payment') or diag($system->error);
	%result = $system->getTransactionDetails;
	is($result{'AMT'}, $system->invoice('valor'), 't/Amount received') or diag($system->error);
	ok($system->refundTransaction ne '','t/Refund') or diag($system->error);
} else {
	my $token = $q->param('token');
	is($system->getExpressCheckoutDetails($token), '1', 't/Create an Billing Agreement Step 2') or diag($system->error);
	ok($system->user_config('paypalEMAIL') ne '', 't/Payer identified'); 
	is($system->createBillingAgreement($token), '1', 't/Billing Agreement Created') or diag($system->error);
	ok($system->user_config('paypalBAID') ne '', 't/Billing Agreement Recorded');	
	diag("Acesse: ".$system->returnURL().'&BAID='.$system->user_config('paypalBAID'));	
}

1;
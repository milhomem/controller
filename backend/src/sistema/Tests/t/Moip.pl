#Alterando o pacote
use Controller::Financeiro::Moip;
$system = new Controller::Financeiro::Moip;

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

$system->setting('moip_user','milhomem at is4web.com.br');
$system->setting('moip_token','0P854KL0ZTWD18M7N');
$system->setting('moip_pass','0V4SHSFDMTYZHE7IQATOM'); 

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
$system->invoice('valor',14.00);
$system->invoice('username',999999);
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

#$system->cancelURL('http://is4web.com.br');
$system->returnURL('http://debugger.is4web.com.br/sistema/TESTE_SUITE.cgi?module=Moip');

unless ($q->param('token')) {
    ok($system->registerCheckout ne '','t/Registering checkout') or diag($system->error);
    diag("Acesse: ".$system->redirectLogin().$system->invoice('nossonumero'));
    ok( $system->invoice('nossonumero') ne '','t/Register Invoice') or diag($system->error);
    diag("Acesse: ".$system->returnURL.'&token='.$system->invoice('nossonumero'));  
} else {
    $system->invoice('nossonumero',$q->param('token')); 
    is($system->checkPayment,'t/Verify Payment') or diag($system->error);
}
#TODO CANCEL invoice, nao tem opcao ele so faz pelo proprio site
1;
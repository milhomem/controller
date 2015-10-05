#Alterando o pacote
use Controller::Financeiro::CreditCard::Visa;
$system = new Controller::Financeiro::CreditCard::Visa;

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
sub Controller::SQL::execute_sql {return};

$system->setting('gateway_vbv','https://vbv.gatewayurl.tld/vbv');
$system->setting('visa_merchantid','1001734898'); #loja moset test

#User
$system->uid(999999); #antes que mate os ids
$system->user('vencimento','00');
$system->user('email','milhomem at is4web.com.br');
$system->user('status','CA');
$system->user('pending',0);
$system->user('conta',999999);
$system->user('forma',999999);
$system->user('alert',1);

#Fatura
$system->invid(999999);
$system->invoice('valor',1.00);
$system->invoice('username',999999);
$system->invoice('nossonumero',0);

#Pagamentos (Forma)
$system->payid(999999); #Mensal
$system->payment('nome','Mensal');
$system->payment('primeira',0);
$system->payment('intervalo',30);
$system->payment('parcelas',0);
$system->payment('pintervalo',30);
$system->payment('tipo','S');#Tipo de parcelamento O-'Operadora' L-'Loja' S-'Sistema' D-'Debito'
$system->payment('repetir',1);

#Cartao de teste
$system->ccid(999999);
$system->creditcard('ccn','4987654321098769');
$system->creditcard('exp','1208');
#$system->creditcard('cvv2','');
$system->creditcard('username',999999);

#Já pago
#$system->invoice('nossonumero','73489829906482601001');
#$system->invoice('nossonumero','73489829906514001001');
#$system->invoice('nossonumero','73489829907004301001');

#die Dumper $system->visa_authorize;

is($system->cc_verify(1.00), 1, 't/1') or diag($system->error);
$system->clear_error;
my %result = $system->cc_capture;
is($result{'authorized'}, 1, 't/2') or diag($system->error);
is($result{'valor'}, '1.00', 't/3') or diag($system->error || $result{'response'});
my %result = $system->cc_refund;
is($result{'CANCEL_AMOUNT'}, '100', 't/4') or diag($system->error || $result{'response'});
$system->invoice('nossonumero',0);
$system->invoice('valor',12.00); #Valor total que vai ser parcelado automaticamente pelo VISA
$system->payment('nome','Mensal Parcelado 12x');
$system->payment('parcelas',12);
$system->payment('tipo','O');
#Parcelado
my %result = $system->cc_capture;
is($result{'authorized'}, 1, 't/5-1') or diag($system->error);
is($result{'valor'}, '12.00', 't/5-2') or diag($system->error || $result{'response'});
1;
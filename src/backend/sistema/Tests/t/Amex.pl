#Alterando o pacote
use Controller::Financeiro::CreditCard::Amex;
$system = new Controller::Financeiro::CreditCard::Amex;

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

$system->setting('gateway_vbv','https://vpos.amxvpos.com/vpcdps');
#Prod
$system->setting('amex_accesscode','099FC18C');
$system->setting('amex_merchantid','9912646320');
#Dev
#$system->setting('amex_accesscode','2CECCB2A');
#$system->setting('amex_merchantid','TEST9912646320');
$system->setting('amex_capuser','CTRL');
$system->setting('amex_cappass','mfcm1984');

#Fatura
$system->invid(999993);
$system->invoice('valor',1.00);

#Cartao de teste
$system->ccid(999999);
$system->creditcard('ccn','345678901234564');
$system->creditcard('exp','1208');
$system->creditcard('cvv2','1234');

is($system->cc_verify(2.00), 1, 't/1') or diag($system->error);

1;
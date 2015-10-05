sub Controller::Date::today {
	@_=@_;
	my $self = shift;
	@{ $self->{_today} } = @_ if exists $_[0];
	return Date::Simple->new(@{ $self->{_today} });
} 

my $DEBUG = 0;

#Overwrite
#Evitar consulta no Banco de Dados
sub Controller::get_account {diag('[get_account] '."@_") if $DEBUG == 1; return};
sub Controller::get_payment {diag('[get_payment] '."@_") if $DEBUG == 1; return};
sub Controller::get_user {diag('[get_user] '."@_") if $DEBUG == 1; return};
sub Controller::get_service {diag('[get_service] '."@_") if $DEBUG == 1; return};
sub Controller::get_services {diag('[get_services] '."@_") if $DEBUG == 1; my $self = shift; return grep {$self->{services}{$_}{'username'} == $self->uid} keys %{ $self->{services} };};
sub Controller::get_serviceprop {diag('[get_serviceprop] '."@_") if $DEBUG == 1; return};
sub Controller::get_servicesprop {diag('[get_servicesprop] '."@_") if $DEBUG == 1; return};
sub Controller::get_plan {diag('[get_plan] '."@_") if $DEBUG == 1; return};
sub Controller::get_plans {diag('[get_plans] '."@_") if $DEBUG == 1; return};
sub Controller::get_balance {diag('[get_balance] '."@_") if $DEBUG == 1; return};
sub Controller::get_balances {diag('[get_balances] '."@_") if $DEBUG == 1; return};
sub Controller::get_invoice {diag('[get_invoice] '."@_") if $DEBUG == 1; return};
sub Controller::get_tax {diag('[get_tax] '."@_") if $DEBUG == 1; return};
sub Controller::Services::save {diag('[save] '."@_") if $DEBUG == 1; return};
sub Controller::SQL::select_sql {diag('[select_sql] '."@_") if $DEBUG == 1; return};
sub Controller::SQL::execute_sql {diag('[execute_sql] '."@_ ".$_[0]->{queries}{$_[1]}) if $DEBUG == 1; return};
sub Controller::Mail::messages {diag('[messages] '."@_") if $DEBUG == 1; return};
sub Controller::Mail::email {diag('[email] '."@_") if $DEBUG == 1; return};
sub Controller::parse {diag('[parse] '."@_") if $DEBUG == 1; return};
sub Controller::Financeiro::create_invoice{
	my $self = shift;
	diag('[create_invoice] '."@_") if $DEBUG == 1;
	$self->invid(999999);
	$self->invoice('username',$self->uid);
	$self->invoice('status',$_[0]);
	$self->invoice('nome',$_[1]);
	$self->invoice('data_envio',$self->calendar('datemysql'));
	$self->invoice('data_vencido',$_[2]);
	$self->invoice('data_vencimento',$_[2]);
	$self->invoice('data_quitado',$_[3]);
	$self->invoice('envios',0);
	$self->invoice('referencia',$_[4]);
	foreach $serv (split(/ -\s?/,$_[5])) {
		my ($meses, $servico) = split(/x/, $serv);
		$self->invoice('services',$servico,$meses);
	}
	$self->invoice('valor',$_[6]);
	$self->invoice('valor_pago',$_[7]);
	$self->invoice('imp',0);
	$self->invoice('conta',$_[8]);
	return 999999 };
sub Controller::Financeiro::create_balance{ warn '[create_balance]'; return 999999 };
sub Controller::LOG::logcron {
	my ($package, $filename, $line, $sub) = caller(0);
	my $mess = Controller::URLDecode($_[1]);
	die("[CRON LOG] $mess at $filename line $line") if defined $mess and $DEBUG == 1;
	return 1;
};

#User teste
$system->uid(999999);
$system->user('vencimento','00');
$system->user('email','milhomem at is4web.com.br');
$system->user('status','CA');
$system->user('pending',0);
$system->user('conta',999999);
$system->user('forma',999999);
$system->user('alert',1);

#Alterando o pacote
use Controller::Financeiro::Boleto;
$system = new Controller::Financeiro::Boleto;

#Tarifa Boleto
$system->tid(999999);
$system->tax('valor',2.90);
$system->tax('modulo','Controller::Financeiro::Boleto');

#Testes Banco do Brasil
#Contas
$system->actid(999999);
$system->account('nome','Banco BB Teste');
$system->account('banco','001');
$system->account('agencia','1018');
$system->account('conta','0016324');
$system->account('carteira','18');
$system->account('convenio','1234567');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Fatura
$system->invid(5020);#NOSSO NUMERO
$system->invoice('data_vencimento',$system->date('2011-12-10'));
$system->invoice('valor',150.00);
$system->invoice('tarifa',999999);
$system->invoice('conta',999999);
$system->invoice('username',999999);

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '12/345670000005020', 't/1-bb') or diag($system->error);
is($system->codbar, '00199517700000152900000001234567000000502018', 't/2-bb') or diag($system->error);
is($system->linhadigitavel, '00190.00009 01234.567004 00005.020185 9 51770000015290', 't/3-bb') or diag($system->error);
is($system->template('dvnosso'), '7', 't/4-bb') or diag($system->error);
is($system->template('agencia').'-'.$system->template('dvagencia'), '1018-9', 't/5-bb') or diag($system->error);
is($system->template('conta').'-'.$system->template('dvconta'), '0016324-4', 't/6-bb') or diag($system->error);

#Testes Itau
#Contas
$system->actid(999999);
$system->account('nome','Banco Itaú Teste');
$system->account('banco','341');
$system->account('agencia','1547');
$system->account('conta','85547');
$system->account('carteira','175');
$system->account('convenio','');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '00005020', 't/1-itau') or diag($system->error);
is($system->codbar, '34196517700000152901750000502031547855476000', 't/2-itau') or diag($system->error);
is($system->linhadigitavel, '34191.75009 00502.031545 78554.760005 6 51770000015290', 't/3-itau') or diag($system->error);
is($system->template('dvnosso'), '3', 't/4-itau') or diag($system->error);
is($system->template('agencia'), '1547', 't/5-itau') or diag($system->error);
is($system->template('conta').'-'.$system->template('dvconta'), '85547-6', 't/6-itau') or diag($system->error);

#Testes Itau/Unibanco
#Contas
$system->actid(999999);
$system->account('nome','Banco Itaú/Unibanco Teste');
$system->account('banco','409');
$system->account('agencia','1018');
$system->account('conta','016324');
$system->account('carteira','X');
$system->account('convenio','1234561');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '00000000005020', 't/1-unibanco') or diag($system->error);
is($system->codbar, '40991517700000152905123456100000000000050202', 't/2-unibanco') or diag($system->error);
is($system->linhadigitavel, '40995.12347 56100.000001 00000.502021 1 51770000015290', 't/3-unibanco') or diag($system->error);
is($system->template('dvnosso'), '2', 't/4-unibanco') or diag($system->error);
is($system->template('agencia'), '1018', 't/5-unibanco') or diag($system->error);
is($system->template('conta'), '016324', 't/6-unibanco') or diag($system->error);

#Testes Santander/Real
#Contas
$system->actid(999999);
$system->account('nome','Banco Real Teste');
$system->account('banco','356');
$system->account('agencia','1018');
$system->account('conta','0016324');
$system->account('carteira','57');
$system->account('convenio','');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '0000000005020', 't/1-real') or diag($system->error);
is($system->codbar, '35697517700000152901018001632490000000005020', 't/2-real') or diag($system->error);
is($system->linhadigitavel, '35691.01805 01632.490007 00000.050203 7 51770000015290', 't/3-real') or diag($system->error);
is($system->template('dvnosso'), '', 't/4-real') or diag($system->error);
is($system->template('agencia'), '1018', 't/5-real') or diag($system->error);
is($system->template('conta').'-'.$system->template('dvconta'), '0016324-9', 't/6-real') or diag($system->error);

#Testes Santander/Banespa
#Contas
$system->actid(999999);
$system->account('nome','Banco Santander/Banespa Teste');
$system->account('banco','033');
$system->account('agencia','0083');
$system->account('conta','18000636');
$system->account('carteira','102');
$system->account('convenio','1007041');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '000000005020', 't/1-santander') or diag($system->error);
is($system->codbar, '03393517700000152909100704100000000502020102', 't/2-santander') or diag($system->error);
is($system->linhadigitavel, '03399.10077 04100.000001 05020.201025 3 51770000015290', 't/3-santander') or diag($system->error);
is($system->template('dvnosso'), '2', 't/4-santander') or diag($system->error);
is($system->template('agencia'), '0083', 't/5-santander') or diag($system->error);
is($system->template('conta'), '18000636', 't/6-santander') or diag($system->error);

#Testes digito verificador nossonumero
$system->invoice('nossonumero','1'); #Resto 2
$system->parse_boleto;
is($system->template('dvnosso'), '9', 't/7-1-santander') or diag($system->error);
$system->invoice('nossonumero','10'); #Resto 3
$system->parse_boleto;
is($system->template('dvnosso'), '8', 't/7-2-santander') or diag($system->error);
$system->invoice('nossonumero','1011'); #Resto 10
$system->parse_boleto;
is($system->template('dvnosso'), '1', 't/7-3-santander') or diag($system->error);
$system->invoice('nossonumero','10011'); #Resto 0
$system->parse_boleto;
is($system->template('dvnosso'), '0', 't/7-4-santander') or diag($system->error);
$system->invoice('nossonumero','10101'); #Resto 1 
$system->parse_boleto;
is($system->template('dvnosso'), '0', 't/7-5-santander') or diag($system->error);
$system->invoice('nossonumero','');

#Testes CEF SICOB
#Contas
$system->actid(999999);
$system->account('nome','Banco Caixa E.F. Teste');
$system->account('banco','104');
$system->account('dvbanco','0'); #CEF_SICOB
$system->account('agencia','4134');
$system->account('conta','686');
$system->account('carteira','80');
$system->account('convenio','413487000000141');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Sample
$system->invoice('data_vencimento',$system->date('2011-12-10'));
$system->invoice('valor',150);
$system->invoice('nossonumero','5020');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '80/00005020', 't/1-CEF_SICOB') or diag($system->error);
is($system->codbar, '10497517700000152908000005020413487000000141', 't/2-CEF_SICOB') or diag($system->error);
is($system->linhadigitavel, '10498.00004 05020.413489 70000.001415 7 51770000015290', 't/3-CEF_SICOB') or diag($system->error);
is($system->template('dvnosso'), '0', 't/4-CEF_SICOB') or diag($system->error);
is($system->template('agencia'), '4134', 't/5-CEF_SICOB') or diag($system->error);
is($system->template('conta'), '686', 't/6-CEF_SICOB') or diag($system->error);

#Testes CEF SIGCB
#Contas
$system->actid(999999);
$system->account('nome','Banco Caixa E.F. Teste');
$system->account('banco','104');
$system->account('dvbanco','1'); #CEF_SIGCB
$system->account('agencia','4158');
$system->account('conta','1030');
$system->account('carteira','24');
$system->account('convenio','281648');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Sample
$system->invoice('data_vencimento',$system->date('2011-12-10'));
$system->invoice('valor',150);
$system->invoice('nossonumero','5020');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '24/900000000005020', 't/1-CEF_SIGCB') or diag($system->error);
is($system->codbar, '10499517700000152902816482900200040000050206', 't/2-CEF_SIGCB') or diag($system->error);
is($system->linhadigitavel, '10492.81643 82900.200047 00000.502062 9 51770000015290', 't/3-CEF_SIGCB') or diag($system->error);
is($system->template('dvnosso'), '0', 't/4-CEF_SIGCB') or diag($system->error);
is($system->template('agencia'), '4158', 't/5-CEF_SIGCB') or diag($system->error);
is($system->template('codcliente').'-'.$system->template('dvcodcli'), '281648-2', 't/6-CEF_SIGCB') or diag($system->error);

#TESTE REAL ELABORAHOST
$system->actid(999999);
$system->account('nome','Banco Caixa E.F. Teste');
$system->account('banco','104');
$system->account('dvbanco','1'); #CEF_SIGCB
$system->account('agencia','3053');
$system->account('conta','542');
$system->account('carteira','2');
$system->account('convenio','229308');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Sample
$system->invoice('data_vencimento',$system->date('2011-07-05'));
$system->invoice('valor',20-2.9);
$system->invoice('nossonumero','533');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '24/900000000000533', 't/7-CEF_SIGCB') or diag($system->error);
is($system->codbar, '10497501900000020002293080900200040000005335', 't/8-CEF_SIGCB') or diag($system->error);
is($system->linhadigitavel, '10492.29303 80900.200041 00000.053355 7 50190000002000', 't/9-CEF_SIGCB') or diag($system->error);
is($system->template('dvnosso'), '7', 't/10-CEF_SIGCB') or diag($system->error);
is($system->template('agencia'), '3053', 't/11-CEF_SIGCB') or diag($system->error);
is($system->template('codcliente').'-'.$system->template('dvcodcli'), '229308-0', 't/12-CEF_SIGCB') or diag($system->error);

#TESTE AMOSTRAGEM ELABORAHOST
$system->actid(999999);
$system->account('nome','Banco Caixa E.F. Teste');
$system->account('banco','104');
$system->account('dvbanco','1'); #CEF_SIGCB
$system->account('agencia','3149');
$system->account('conta','XXXX');
$system->account('carteira','2');
$system->account('convenio','257789');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Sample
$system->invoice('data_vencimento',$system->date('2012-04-11'));
$system->invoice('valor',570-2.9);
$system->invoice('nossonumero','1477');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '24/900000000001477', 't/13-CEF_SIGCB') or diag($system->error);
is($system->codbar, '10494530000000570002577895900200040000014771', 't/14-CEF_SIGCB') or diag($system->error);
is($system->linhadigitavel, '10492.57783 95900.200049 00000.147710 4 53000000057000', 't/15-CEF_SIGCB') or diag($system->error);
is($system->template('dvnosso'), '8', 't/16-CEF_SIGCB') or diag($system->error);
is($system->template('agencia'), '3149', 't/17-CEF_SIGCB') or diag($system->error);
is($system->template('codcliente').'-'.$system->template('dvcodcli'), '257789-5', 't/18-CEF_SIGCB') or diag($system->error);

#Testes HSBC
#Contas
$system->actid(999999);
$system->account('nome','Banco HSBC Teste');
$system->account('banco','399');
$system->account('agencia','1234');
$system->account('conta','X');
$system->account('carteira','CNR');
$system->account('convenio','0016324');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Sample
$system->invoice('data_vencimento',$system->date('2011-12-10'));
$system->invoice('valor',150);
$system->invoice('nossonumero','5020');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '0000000005020743', 't/1-hsbc') or diag($system->error);
is($system->codbar, '39992517700000152900016324000000000502034412', 't/2-hsbc') or diag($system->error);
is($system->linhadigitavel, '39990.01633 24000.000000 05020.344122 2 51770000015290', 't/3-hsbc') or diag($system->error);
is($system->template('dvnosso'), '2', 't/4-hsbc') or diag($system->error);
is($system->template('agencia'), '1234', 't/5-hsbc') or diag($system->error);
is($system->template('codcliente'), '0016324', 't/6-hsbc') or diag($system->error);

#Testes Bradesco
#Contas
$system->actid(999999);
$system->account('nome','Banco Bradesco Teste');
$system->account('banco','237');
$system->account('agencia','0123');
$system->account('conta','0012345');
$system->account('carteira','06');
$system->account('convenio','');
$system->account('cedente','is4web Sistemas');
$system->account('instrucoes','Teste de intrucoes');

#Gerando boleto
$system->boleto;
$system->parse_boleto;

is($system->template('nossonum'), '06/00000005020', 't/1-bradesco') or diag($system->error);
is($system->codbar, '23794517700000152900123060000000502000123450', 't/2-bradesco') or diag($system->error);
is($system->linhadigitavel, '23790.12301 60000.000509 20001.234507 4 51770000015290', 't/3-bradesco') or diag($system->error);
is($system->template('dvnosso'), '4', 't/4-bradesco') or diag($system->error);
is($system->template('agencia'), '0123', 't/5-bradesco') or diag($system->error);
is($system->template('conta'), '0012345', 't/6-bradesco') or diag($system->error);
1;
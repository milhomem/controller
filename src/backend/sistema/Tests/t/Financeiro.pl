#Alterando o pacote
use Controller::Financeiro;
$system = new Controller::Financeiro;

sub Controller::Date::today {
	@_=@_;
	my $self = shift;
	@{ $self->{_today} } = @_ if exists $_[0];
	return Date::Simple->new(@{ $self->{_today} });
} 

my $DEBUG = 0;

$days_in_month = $this->days_in_month($this->year, 31);

#Setting
$system->setting('DEBUG',0);
#Relevantes ao Financeiro
#$system->setting('');#JUROS DE MORA
#$system->setting('');#MULTA
#$system->setting('');#MOEDA
#$system->setting('');#SEPARADOR DECIMAL 
#$system->setting('');#SEPARADOR MILHAR 
#$system->setting('');#DATA FORMATO
#$system->setting('');#FINANCEIRO EMAIL
#$system->setting('');#CONTAS EMAIL 
#$system->setting('');#DIAS SEM COBRANÇA
#$system->setting('dias_antes','7');#DIAS ANTECEDENTES
#$system->setting('');#VALOR MÍNIMO
#$system->setting('');#INFORMAR USUÁRIO 
#$system->setting('');#COBRANÇA CONSECUTIVA
#$system->setting('alertpg');#ALERTA PAGAMENTO EMAIL
#$system->setting('alertuser');#ALERTA USUARIO SOBRE PAGAMENTO => 1|0
#$system->setting('altcredito');#GERAR CREDITO NA ALTERACAO DO PLANO
#$system->setting('altplan');#TEMPO MAXIMO PARA ALTERAR SEM COBRAR
#$system->setting('altmes');#COBRAR SOMENTE OS MESES DA ALTERAÇÃO
#$system->setting('');#
#$system->setting('')#
#$system->setting('')#

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
sub Controller::get_balances {diag('[get_balances] '."@_") if $DEBUG == 1; my $self = shift; return grep {$self->{balances}{$_}{'username'} == $self->uid} keys %{ $self->{balances} };};
sub Controller::get_invoice {diag('[get_invoice] '."@_") if $DEBUG == 1; return};
sub Controller::get_tax {diag('[get_tax] '."@_") if $DEBUG == 1; return};
sub Controller::Services::save {diag('[save] '."@_") if $DEBUG == 1; return};
sub Controller::SQL::select_sql {diag('[select_sql] '."@_") if $DEBUG == 1; return};
sub Controller::SQL::execute_sql {diag('[execute_sql] '."@_ ".$_[0]->{queries}{$_[1]}) if $DEBUG == 1; return};
sub Controller::Mail::messages {diag('[messages] '."@_") if $DEBUG == 1; return};
sub Controller::Mail::email {diag('[email] '."@_") if $DEBUG == 1; return};
sub Controller::Financeiro::create_invoice{
	my $self = shift;
	diag('[create_invoice] '."@_") if $DEBUG == 1;
	$self->{invoices}{999999} = undef;
	$self->invid(999999);
	$self->invoice('username',999999);
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
	#$self->invoice('nossonumero');
	#use Data::Dumper; die Dumper $self->{invoices}{999999} if $self->{a};
	return 999999 };
sub Controller::Financeiro::create_balance{ 
	my $self = shift;
	diag('[create_balance] '."@_") if $DEBUG == 0;
	$self->{balances}{999999} = undef;
	$self->balanceid(999999);
	$self->balance('username',$self->uid);
	$self->balance('valor',$_[0]);
	$self->balance('descricao',$_[1]);
	$self->balance('servicos',$_[2]);
	$self->balance('invoice',$_[3]);	
	return 999999 };
sub Controller::LOG::logcron {
	my ($package, $filename, $line, $sub) = caller(0);
	my $mess = Controller::URLDecode($_[1]);
	die("[CRON LOG] $mess at $filename line $line") if defined $mess and $DEBUG == 1;
	return 1;
};

#Contas
$system->actid(999999);
$system->account('nome','Banco Itaú Teste');
$system->account('banco','341');
$system->account('agencia','0001');
$system->account('conta','72744');
$system->account('carteira','175');
$system->account('convenio','');
$system->account('cedente','Empresa Ltda');
$system->account('instrucoes','Teste de intrucoes');
	
#Pagamentos (Forma)
$system->payid(999997); #Único
$system->payment('nome','Único');
$system->payment('primeira',7);
$system->payment('intervalo',1);
$system->payment('pintervalo',1);
$system->payment('parcelas',0);
$system->payment('tipo','S');
$system->payment('repetir',0);
$system->payid(999998); #ANUAL
$system->payment('nome','Anual');
$system->payment('primeira',7);
$system->payment('intervalo',360);
$system->payment('pintervalo',360);
$system->payment('parcelas',0);
$system->payment('tipo','S');
$system->payment('repetir',1);
$system->payid(999999); #Mensal
$system->payment('nome','Mensal');
$system->payment('primeira',7);
$system->payment('intervalo',30);
$system->payment('pintervalo',30);
$system->payment('parcelas',0);
$system->payment('tipo','S');
$system->payment('repetir',1);

#Plano
$system->pid(999999); #TIRA A REFERENCIA DO SERVICO
$system->plan('level','');
$system->plan('nome','Teste HW');
$system->plan('plataforma','Windows');
$system->plan('tipo','Hospedagem');
$system->plan('descricao','Só Teste');
$system->plan('campos','Senha::');
$system->plan('setup',0);
$system->plan('valor',1.87);
$system->plan('valor_tipo','M');
#$system->plan('auto','');
$system->plan('pagamentos','');
$system->plan('alert',0);

#Tarifa
#????

#Fatura
$system->invid(999999);
$system->invoice('date_vencimento',undef);
$system->invoice('username',999999);

#User teste
$system->uid(999999);
$system->user('vencimento','00');
$system->user('email','milhomem at is4web.com.br');
$system->user('status','CA');
$system->user('pending',0);
$system->user('conta',999999);
$system->user('forma',999999);
$system->user('alert',1);

#Servico teste
$system->sid(999999); #Tem que estar depois de pid
$system->service('username',999999);
$system->service('dominio','dominioteste.com');
$system->service('servicos',999999);
$system->service('status','F');
$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('servidor',1);
#$system->service('dados','');
#$system->service('useracc','');
$system->service('pg',999999);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',0);
$system->service('lock',0);
$system->service('parcelas',1);
#Mais um serviço para teste
$system->copy_service(999999,999998);
my $data1 = $system->service;
$system->sid(999998);
my $data2 = $system->service;
$system->sid(999999);
###################

#Testes
is_deeply( $data2, $data1, 't/0 Estrutura de dados') or diag($system->error);
is($system->service('vencimento'), undef, 't/0-1') or diag($system->error);
is($system->diames(2008,2,28), '2008-02-28', 't/1 Função diames');
is($system->diames(2008,2,29), '2008-02-29', 't/1-1');
is($system->diames(2008,2,30), '2008-02-29', 't/1-2');
is($system->diames(2008,2,31), '2008-02-29', 't/1-3');
#
is($system->somames(\$system->date('2008-02-29'), 1), '2008-03-29', 't/2 Função somames');
is($system->somames(\$system->date('2008-02-29'), 16), '2009-06-29', 't/2-1');
is($system->somames(\$system->date('2008-01-31'), 1), '2008-02-29', 't/2-2');
is($system->somames(\$system->date('2008-02-29'), 1), '2008-03-29', 't/2-3');
is($system->somames(\$system->date('2008-02-29'), 7 / 30), '2008-03-07', 't/2-4');
is($system->somames(\$system->date('2008-02-29'), 39 / 30), '2008-04-07', 't/2-5');
#
is($system->diaproximo(31,\$system->date('2007-10-01')), '2007-09-30', 't/3 Função diaproximo');
is($system->diaproximo(31,\$system->date('2008-10-16')), '2008-10-31', 't/3-1');
is($system->diaproximo(31,\$system->date('2008-02-29')), '2008-02-29', 't/3-2');
is($system->diaproximo(31,\$system->date('2008-03-29')), '2008-03-31', 't/3-3');
#
#Faturas normais
$system->setting('invoices',0);
#servico zerado
$system->setting('dias_antes',7);
$system->sid(999999);#Reforçando pra facilitar leitura
#provocando erro
$system->service('pagos', 2);
$system->prazo;
is($system->clear_error, 'Fatura não pode ser gerada para serviços cancelados ou finalizados.', 't/4 Erro padrão') or diag($system->error);
$system->service('status','S');
$system->prazo;
is($system->clear_error, 'Erro sem vencimento e com fatura paga. Serviço 999999 já possui 2 pagamentos', 't/4-1 Erro padrão') or diag($system->error);
#corrigindo erro anterior
$system->service('pagos', 0);
#
#Parcelando
#
$system->payment('nome','Anual Parcelado');
$system->payment('primeira',0);
$system->payment('intervalo',90);
$system->payment('pintervalo',30);
$system->payment('parcelas',1);
$system->service('parcelas',3);
$system->payment('repetir',0);
$system->plan('valor',18.7);
$system->plan('valor_tipo','M');
$system->today(2008,10,4); #hoje; 
$system->prazo;
is($system->service('proximo'), '2008-11-04', 't/5 Prazo Parcelado 3x não recorrente') or diag($system->error);
#2x Parcela
$system->service('pagos', 1);
$system->service('vencimento',$system->service('proximo'));
$system->today(2008,10,30);
$system->prazo;
is($system->service('proximo'), '2008-12-04', 't/5-1 2x Parcela') or diag($system->error);
#3x Parcela
$system->service('pagos', 2);
$system->service('vencimento',$system->service('proximo'));
$system->today(2008,11,30);
$system->prazo;
is($system->service('proximo'), '2009-01-04', 't/5-2 3x Parcela') or diag($system->error);
#4x Parcela inexistente
$system->service('pagos', 3);
$system->service('vencimento',$system->service('proximo'));
$system->today(2008,12,30);
is($system->prazo, 0, 't/5-3 4x Parcela não existe') or diag($system->error);
is($system->service('vencimento'), '2009-01-04', 't/5-4') or diag($system->error);
#
#Parcelando para intervalo menor que 30
#
$system->payment('pintervalo',8);
$system->payment('intervalo',36);
$system->service('vencimento',undef);
$system->service('pagos', 0);
$system->today(2008,10,4);
$system->prazo;
is($system->service('proximo'), '2008-10-12', 't/6 Parcelado 3x intevalo menor que 30 não recorrente') or diag($system->error);
#2x Parcela
$system->service('pagos', 1);
$system->service('vencimento',$system->service('proximo'));
$system->today(2008,10,6);
$system->prazo;
is($system->service('proximo'), '2008-10-20', 't/6-1 2x Parcela') or diag($system->error);
#3x Parcela
$system->service('pagos', 2);
$system->service('vencimento',$system->service('proximo'));
$system->today(2008,10,13);
$system->prazo;
is($system->service('proximo'), '2008-11-09', 't/6-2 3x Parcela') or diag($system->error); #Cumprindo os 36 dias
#4x Parcela inexistente
$system->service('pagos', 3);
$system->service('vencimento',$system->service('proximo'));
$system->today(2008,10,22);
is($system->prazo, 0, 't/6-3') or diag($system->error);
is($system->service('vencimento'), '2008-11-09', 't/6-4 4x Parcela não existe') or diag($system->error);
#
#Com primeira parcela
#
$system->payment('primeira',5);
$system->service('vencimento',undef);
$system->service('pagos', 0);
$system->today(2008,10,4);
$system->prazo;
is($system->service('proximo'), '2008-10-09', 't/7 Prazo com primeira parcela') or diag($system->error);
#
#Faturas recorrentes
#
#Antecipado
$system->payment('pintervalo',30);
$system->payment('intervalo',30);
$system->payment('parcelas',0);
$system->payment('service',1);
$system->payment('repetir',1);
$system->payment('primeira',7); #7 dias para pagar
$system->service('vencimento',undef);
$system->service('pagos', 0);
$system->today(2008,10,4);
$system->prazo;
is($system->service('proximo'), '2008-10-11', 't/8 Prazo antecipado') or diag($system->error);
#Ao quitar os dias da primeira influenciam
$system->service('pagos', 1);
$system->service('vencimento',$system->date('2008-10-15')); #simula o quitar ?? tentei quitar mas nao tem invoice
$system->today(2008,11,10);
$system->prazo;
is($system->service('proximo'), '2008-11-15', 't/8-1') or diag($system->error);
#Postecipado
$system->payment('parcelas',1);
$system->service('parcelas',1);
$system->payment('repetir',1);
$system->payment('primeira',0);
$system->service('vencimento',undef);
$system->service('pagos', 0);
$system->today(2008,10,4);
$system->prazo;
is($system->service('proximo'), '2008-11-04', 't/9 Prazo postecipado') or diag($system->error);
#Ao quitar os dias da primeira influenciam?? nao sei
$system->service('pagos', 10);#Simulando o 10 pagamento
$system->service('vencimento',$system->service('proximo'));
$system->today(2008,11,30);
$system->prazo;
is($system->service('proximo'), '2008-12-04', 't/9-1') or diag($system->error);
#Faturas consecutivas
$system->setting('invoices',1);
$system->service('pagos', 0);
$system->service('vencimento',undef);
$system->service('invoice',999999);
$system->today(2008,10,4);
$system->invoice('data_vencimento',$system->today + 1);
$system->prazo;
is($system->service('proximo'), '2008-11-04', 't/10 Faturas consecutivas') or diag($system->error);
# 2 fatura, sem quitar anterior
$system->service('invoice',999999);
$system->invoice('data_vencimento',$system->date('2008-11-04'));
$system->service('vencimento',$system->date('2008-11-04'));
$system->today(2008,11,10); #Fatura vencida mas nao ta na hora de gerar
$system->prazo;
is($system->service('proximo'), $system->invoice('data_vencimento'), 't/10-1') or diag($system->error);
$system->today(2008,12,01); #entre os 7 dias de gerar
$system->prazo;
is($system->service('proximo'), '2008-12-04', 't/10-2') or diag($system->error);
# Nao pode gerar mais enquanto nao vencer a fatura
$system->invoice('data_vencimento',$system->service('proximo'));
$system->service('vencimento',$system->service('proximo'));
$system->service('invoice',999999);
is($system->prazo, 0, 't/10-3') or diag($system->error);
# Prazo nao tem mais parametro, basta redefinir os valores antes de chamar
# Montando a fatura = sub faturar
is($system->services, 2, 't/11 Preparando Faturar') or diag($system->error);
$system->service('username',0); #tirar temporariamente para testar só com 1, depois testar com 2
$system->sid(999998);
$system->service('status','S');
#pagamento
$system->payment('nome','Mensal Antecipado');
$system->payment('primeira',7);
$system->payment('intervalo',30);
$system->payment('pintervalo',30);
$system->payment('parcelas',0);
$system->payment('repetir',1);
$system->today(2008,10,4); #hoje;
is($system->prazo, 1, 't/11-1') or diag($system->error);
my $vcto = $system->vcto_service;
#my $vcti;
is($vcto, '2008-10-11', 't/11-2') or diag($system->error);
#mudou fazer testes melhores is($system->split_invoice($vcto,$vcti), '2008-10-11', 't/11-3') or diag($system->error);
#is($system->{'_next'}, undef, 't/11-4') or diag($system->error);
my $subj = $system->referencia($vcto);
is($subj->{'month'}, 10, 't/11-5') or diag($system->error);
is($subj->{'year'}, 2008, 't/11-6') or diag($system->error);
is($subj->{'monthname'}, 'Outubro', 't/11-7') or diag($system->error);
#$vcti=$vcto;
is($system->servicos_ativos, 0, 't/11-8') or diag($system->error);
is($system->vcto_adjust($vcto), '2008-11-11', 't/11-9') or diag($system->error);
is($system->service('vencimento'), undef, 't/11-10') or diag($system->error);
is($system->service('proximo'), '2008-11-11', 't/11-11') or diag($system->error);
is($system->faturar_service, 999998, 't/11-12') or diag($system->error);
is($system->{_faturar}{referencia}, "(c) Hospedagem Windows Teste HW (dominioteste.com) => R\$ 18,70\n", 't/11-13') or diag($system->error);
is($system->{_faturar}{total}, '18.7', 't/11-14') or diag($system->error);
#testando moeda
is($system->Currency(10015426874.361574), 'R$ 10.015.426.874,36', 't/12-1');
is($system->Currency(10015426874.361574,1), '10.015.426.874,36', 't/12-2');
is($system->Currency(-10015426874.361574), 'R$ -10.015.426.874,36', 't/12-3');
is($system->Currency(-874.361574), 'R$ -874,36', 't/12-4');
is($system->Currency(-874), 'R$ -874,00', 't/12-5');
my $string = 'ad ads sd emqodme => R$ 30,20';
is(Controller::cut_string($string,'... ',13,'R$ 30,20'), 'a... R$ 30,20', 't/12-5');
is(Controller::cut_string($string,'... ',20,'R$ 30,20'), 'ad ads s... R$ 30,20', 't/12-6');
$string = 'ad ads R$ 30,20 sd emqodme';
is(Controller::cut_string($string,'... ',13,'R$ 30,20'), 'R$ 30,20... ', 't/12-7');
is(Controller::cut_string($string,'... ',20,'R$ 30,20'), 'ad ads R$ 30,20 ... ', 't/12-8');
is(Controller::cut_string($string,'... ',70,'R$ 30,20'), 'ad ads R$ 30,20 sd emqodme', 't/12-9');
is(Controller::cut_string($string,'... ',15,' '), 'ad ads R$ 3... ', 't/12-10');
is(Controller::cut_string($string,'... ',70), 'ad ads R$ 30,20 sd emqodme', 't/12-11');
#
# Faturas não multiplas
$system->setting('invoices',0);
$system->setting('minimo',5.00);
# Usuario
$system->uid(999999); #Mata sid, invid, balanceid e callid
$system->today([]);#$system->today(2008,10,4); #hoje;
# Serviço
$system->sid(999999);
$system->service('dominio','dominioteste2.com');
$system->service('username',999999);
$system->service('status','S');
$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',0);
$system->copy_service(999999,999998);
$system->service('dominio','dominioteste.com');
# Plano
$system->plan('setup',0);
$system->plan('valor',11.87);
# Payment Mensal Antecipado com 7 dias
# Faturar
# Serviço sem propriedades, Usuario com vencimento 00, Sem saldo, sem credito
$system->user('vencimento','00');
my $inv = $system->faturar( [999999,999998] );
is($inv, $system->invid, 't/13-1 Faturamento') or diag($system->error);
is($system->service('invoice'), $inv, 't/13-2') or diag($system->error);
is($system->service('vencimento'), undef, 't/13-3') or diag($system->error);#nao é pra ser zero? 
is($system->service('proximo'), 7 + $system->today + $system->payment('pintervalo'), 't/13-4') or diag($system->error);
is($system->invoice('status'), 'P', 't/13-5') or diag($system->error);
is($system->invoice('data_vencimento'), 7 + $system->today, 't/13-6') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (dominioteste.com) => R\$ 11,87\n(c) Hospedagem Windows Teste HW (dominioteste2.com) => R\$ 11,87\n* (c) crédito (d) débito", 't/13-7') or diag($system->error);
is($system->invoice('valor'), '23.74', 't/13-8') or diag($system->error);
is($system->user('vencimento'), '00', 't/13-9') or diag($system->error);
# Pagar essa fatura
#$system->today(2008,10,8); #hoje;
my $res = $system->pay_invoice(11.00,$system->today);
is($res, 1, 't/Quitar') or diag("resposta: $res error: ".$system->clear_error);
is($system->clear_error, 'Pago (R$ 11,00) a menor. Total: R$ 23,74', 't/14-1') or diag($system->error);
is($system->invoice('status'), 'Q', 't/14-2') or diag($system->error);
is($system->invoice('valor_pago'), 11.00, 't/14-3') or diag($system->error);
is($system->invoice('data_quitado'), $system->today, 't/14-4') or diag($system->error);
is($system->service('proximo'), undef, 't/14-5') or diag($system->error);
is($system->service('vencimento') - $system->today(), $system->payment('pintervalo'), 't/14-6') or diag($system->error);
diag('Ativos:'.$system->servicos_ativos);
is($system->user('vencimento'), $system->today->day, 't/14-7') or diag($system->error);
#testar pagamento unico
$system->today(2012,06,10); #hoje;
# Serviço
$system->sid(999999);
$system->service('dominio','único');
$system->service('username',999999);
$system->service('pg',999997);
$system->service('status','S');
$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',0);
# Plano
$system->plan('setup',0);
$system->plan('valor',126.24);
$system->plan('valor_tipo','U');

$system->user('vencimento','00');
$inv = $system->faturar( [999999] );
is($inv, $system->invid, 't/15-1 Pagamento único') or diag($system->error);
is($system->service('invoice'), $inv, 't/15-2') or diag($system->error);
is($system->service('vencimento'), undef, 't/15-3') or diag($system->error);
is($system->service('proximo'), 7 + $system->today + $system->payment('pintervalo'), 't/15-4') or diag($system->error);
is($system->invoice('status'), 'P', 't/15-5') or diag($system->error);
is($system->invoice('data_vencimento'), 7 + $system->today, 't/15-6') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (único) => R\$ 126,24\n* (c) crédito (d) débito", 't/15-7') or diag($system->error);
is($system->invoice('valor'), '126.24', 't/15-8') or diag($system->error);
is($system->user('vencimento'), '00', 't/15-9') or diag($system->error);
# Pagar essa fatura com atraso
#$system->service('vencimento',$system->date('2012-05-25'));
$system->today(2012,06,20); #hoje;
#$system->setting('DEBUG',1);
#$DEBUG=1;
$res = $system->pay_invoice(11.00,$system->today);
is($res, 1, 't/Quitar') or diag("resposta: $res error: ".$system->clear_error);
is($system->clear_error, 'Pago (R$ 11,00) a menor. Total: R$ 126,24', 't/16-1') or diag($system->error);
is($system->invoice('status'), 'Q', 't/16-2') or diag($system->error);
is($system->invoice('valor_pago'), 11.00, 't/16-3') or diag($system->error);
is($system->invoice('data_quitado'), $system->today, 't/16-4') or diag($system->error);
is($system->service('proximo'), undef, 't/16-5') or diag($system->error);
is($system->service('vencimento'), '2012-06-18', 't/16-6') or diag($system->error); #10+7+1, com pagamento em atraso deveria mudar?
is($system->user('vencimento'), $system->today->day, 't/16-7') or diag($system->error);
#$system->balanceid(999999);
#is($system->balance('valor'), 0, 't/16-8') or diag($system->error);

#testar vencimento do usuario
$system->today(2012,06,10); #hoje;
# Serviço
$system->sid(999999);
$system->service('dominio','vencimentousuarioativo');
$system->service('username',999999);
$system->service('pg',999999);
$system->service('status','A');
$system->service('inicio',$system->date('2012-06-01'));
$system->service('fim',undef);
$system->service('vencimento',$system->date('2012-06-15'));
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',0);
# Plano
$system->plan('setup',10);
$system->plan('valor',126.24);
$system->plan('valor_tipo','M');

$system->user('vencimento','30');
#$DEBUG=1;
#$system->setting('DEBUG',1);
$inv = $system->faturar( [999999] );
is($inv, $system->invid, 't/17-1 Vencimento do usuário com serviço importado (ativo e pagos 0)') or diag($system->error);
is($system->service('invoice'), $inv, 't/17-2') or diag($system->error);
is($system->service('vencimento'), '2012-06-15', 't/17-3') or diag($system->error);
is($system->service('proximo'), '2012-07-30', 't/17-4') or diag($system->error);
is($system->invoice('status'), 'P', 't/17-5') or diag($system->error);
is($system->invoice('data_vencimento'), '2012-06-15', 't/17-6') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (vencimentousuarioativo) => R\$ 126,24\n(d) (15 dias) Hospedagem Windows Teste HW (vencimentousuarioat...R\$ 63,12\n* (c) crédito (d) débito", 't/17-7') or diag($system->error);
is($system->invoice('valor'), '189.36', 't/17-8') or diag($system->error);
is($system->user('vencimento'), '30', 't/17-9') or diag($system->error);
# 
$system->today(2012,06,15); #hoje;
$system->setting('DEBUG',1);
#$DEBUG=1;
$res = $system->pay_invoice(11.00,$system->today);
is($res, 1, 't/Quitar') or diag("resposta: $res error: ".$system->clear_error);
is($system->clear_error, 'Pago (R$ 11,00) a menor. Total: R$ 189,36', 't/18-1') or diag($system->error);
is($system->invoice('status'), 'Q', 't/18-2') or diag($system->error);
is($system->invoice('valor_pago'), 11.00, 't/18-3') or diag($system->error);
is($system->invoice('data_quitado'), $system->today, 't/18-4') or diag($system->error);
is($system->service('proximo'), undef, 't/18-5') or diag($system->error);
is($system->service('vencimento'), '2012-07-01', 't/18-6') or diag($system->error);
is($system->user('vencimento'), '30', 't/18-7') or diag($system->error);

#Test invoice description has total value without service's discount
$system->today(2012,06,10); #hoje;
# Service
$system->sid(999999);
$system->service('dominio','serviceWithDiscount');
$system->service('username',999999);
$system->service('pg',999999);
$system->service('status','S');
$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',15.53);
# Plan
$system->plan('setup',0);
$system->plan('valor',126.24);
$system->plan('valor_tipo','M');

$system->user('vencimento','30');

$system->today(2012,07,20); #hoje;
$inv = $system->faturar( [999999] );
is($inv, $system->invid, 't/PlanWithDiscount-1 Vencimento do usuário') or diag($system->error);
is($system->service('invoice'), $inv, 't/PlanWithDiscount-2') or diag($system->error);
is($system->service('vencimento'), undef, 't/PlanWithDiscount-3') or diag($system->error);
is($system->service('proximo'), 7 + $system->today + $system->payment('pintervalo'), 't/PlanWithDiscount-4') or diag($system->error);
is($system->invoice('status'), 'P', 't/PlanWithDiscount-5') or diag($system->error);
is($system->invoice('data_vencimento'), 7 + $system->today, 't/PlanWithDiscount-6') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (serviceWithDiscount) => R\$ 110,71\n* (c) crédito (d) débito", 't/PlanWithDiscount-7') or diag($system->error);
is($system->invoice('valor'), '110.71', 't/PlanWithDiscount-8') or diag($system->error);
is($system->user('vencimento'), '30', 't/PlanWithDiscount-9') or diag($system->error);

#testar vencimento do usuario
$system->today(2012,06,10); #hoje;
# Serviço
$system->sid(999999);
$system->service('dominio','vencimentousuairo');
$system->service('username',999999);
$system->service('pg',999999);
$system->service('status','S');
$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',0);
# Plano
$system->plan('setup',0);
$system->plan('valor',126.24);
$system->plan('valor_tipo','M');

$system->user('vencimento','30');

$inv = $system->faturar( [999999] );
is($inv, $system->invid, 't/19-1 Vencimento do usuário') or diag($system->error);
is($system->service('invoice'), $inv, 't/19-2') or diag($system->error);
is($system->service('vencimento'), undef, 't/19-3') or diag($system->error);
is($system->service('proximo'), 7 + $system->today + $system->payment('pintervalo'), 't/19-4') or diag($system->error);
is($system->invoice('status'), 'P', 't/19-5') or diag($system->error);
is($system->invoice('data_vencimento'), 7 + $system->today, 't/19-6') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (vencimentousuairo) => R\$ 126,24\n* (c) crédito (d) débito", 't/19-7') or diag($system->error);
is($system->invoice('valor'), '126.24', 't/19-8') or diag($system->error);
is($system->user('vencimento'), '30', 't/19-9') or diag($system->error);
# 
$system->today(2012,06,20); #hoje;
#$system->setting('DEBUG',1);
#$DEBUG=1;
$res = $system->pay_invoice(11.00,$system->today);
is($res, 1, 't/Quitar') or diag("resposta: $res error: ".$system->clear_error);
is($system->clear_error, 'Pago (R$ 11,00) a menor. Total: R$ 126,24', 't/20-1') or diag($system->error);
is($system->invoice('status'), 'Q', 't/20-2') or diag($system->error);
is($system->invoice('valor_pago'), 11.00, 't/20-3') or diag($system->error);
is($system->invoice('data_quitado'), $system->today, 't/20-4') or diag($system->error);
is($system->service('proximo'), undef, 't/20-5') or diag($system->error);
is($system->service('vencimento'), '2012-07-20', 't/20-6') or diag($system->error);
is($system->user('vencimento'), '30', 't/20-7') or diag($system->error);

#Gerar a proxima para ver se ajusta
$system->service('inicio',$system->date('2012-06-15')); #Serviço tem que estar ativo para cobrar
$system->today(2012,07,20); #hoje;
$inv = $system->faturar( [999999] );
is($inv, $system->invid, 't/21-1 Ajustando ao Vencimento do usuário') or diag($system->error);
is($system->service('invoice'), $inv, 't/21-2') or diag($system->error);
is($system->service('vencimento'), '2012-07-20', 't/21-3') or diag($system->error);
is($system->service('proximo'), '2012-08-30', 't/21-4') or diag($system->error);
is($system->invoice('status'), 'P', 't/21-5') or diag($system->error);
is($system->invoice('data_vencimento'), '2012-07-20', 't/21-6') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (vencimentousuairo) => R\$ 126,24\n(d) (10 dias) Hospedagem Windows Teste HW (vencimentousuairo) ...R\$ 42,08\n* (c) crédito (d) débito", 't/21-7') or diag($system->error);
is($system->invoice('valor'), '168.32', 't/21-8') or diag($system->error);
is($system->user('vencimento'), '30', 't/21-9') or diag($system->error);

#testar eliminação dos primeiros dias
$system->today(2012,06,10); #hoje;
# Serviço
$system->sid(999999);
$system->service('dominio','primeirosdias');
$system->service('username',999999);
$system->service('pg',999999);
$system->service('status','A'); #Ativou antes te pagar
$system->service('inicio',$system->date('2012-06-10')); #Ativou antes de pagar
$system->service('fim',undef);
$system->service('vencimento',undef); #Ativou antes te pagar
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);  #Ativou antes te pagar
$system->service('desconto',0);
# Plano
$system->plan('setup',0);
$system->plan('valor',126.24);
$system->plan('valor_tipo','M');

$system->user('vencimento','00');

$inv = $system->faturar( [999999] );
is($inv, $system->invid, 't/22-1 Primeira (BUG Dias grátis)') or diag($system->error);
is($system->service('invoice'), $inv, 't/22-2') or diag($system->error);
is($system->service('vencimento'), undef, 't/22-3') or diag($system->error);
is($system->service('proximo'), 7 + $system->today + $system->payment('pintervalo'), 't/22-4') or diag($system->error);
is($system->invoice('status'), 'P', 't/22-5') or diag($system->error);
is($system->invoice('data_vencimento'), '2012-06-17', 't/22-6') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (primeirosdias) => R\$ 126,24\n* (c) crédito (d) débito", 't/22-7') or diag($system->error);
is($system->invoice('valor'), '126.24', 't/22-8') or diag($system->error);
is($system->user('vencimento'), '00', 't/22-9') or diag($system->error);
# 
$system->today(2012,06,15); #hoje; dois dias antes dos 7
#$system->setting('DEBUG',1);
#$DEBUG=1;
$res = $system->pay_invoice(11.00,$system->today);
is($res, 1, 't/Quitar') or diag("resposta: $res error: ".$system->clear_error);
is($system->clear_error, 'Pago (R$ 11,00) a menor. Total: R$ 126,24', 't/23-1') or diag($system->error);
is($system->invoice('status'), 'Q', 't/23-2') or diag($system->error);
is($system->invoice('valor_pago'), 11.00, 't/23-3') or diag($system->error);
is($system->invoice('data_quitado'), '2012-06-15', 't/23-4') or diag($system->error);
is($system->service('proximo'), undef, 't/23-5') or diag($system->error);
is($system->service('vencimento'), '2012-07-10', 't/23-6') or diag($system->error);
is($system->user('vencimento'), '10', 't/23-7') or diag($system->error); #ficou faltando ver se vai igualar ao dia de inicio ou deixar mesmo indefinido
#testar promocao
#promocao de meses nao funciona quando troca de ano, ex: desconto mes 12/08 e mes 01/09
#testar altplan
#upgrade de plano trimestral, troca de plano, na metade ele troca de plano ai calculo errado.
#verificar os valores, se esse valor mensal vai ser o anual dividido, como vai ficar isso/
#parcelado repetitivo.
#parcelamento com operadora.
$system->today([]); #hoje;
# Usuario
$system->uid(999999); #antes que mate o sid
$system->today(2008,10,4); #hoje;
# Serviço
$system->sid(999999);
$system->service('dominio','dominioteste2.com');
$system->service('username',999999);
$system->service('pg',999999);
$system->service('status','S');
$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',0);
$system->copy_service(999999,999998);
$system->service('dominio','dominioteste.com');
# Plano
$system->plan('setup',0);
$system->plan('valor',11.87);
$system->plan('valor_tipo','M');
# Testes
$system->user('vencimento','30');
$system->service('status','A');
$system->service('vencimento',$system->date('2008-10-10')); #Nao vai querer igualar?
#$inv = $system->faturar([999999]);
#is($inv, $system->invid, 't/V1') or diag($system->error);
#verificar o que qur com isso
#is($system->invoice('data_vencimento'), undef, 't/V1-2') or diag($system->error);
#nao existe proximo de invoice is($system->invoice('proximo'), '', 't/V1-2') or diag($system->error);
#$system->sid(999998);
#$system->service('vencimento',$system->date('2008-10-10'));
#$inv = $system->faturar([999999]);
#is($inv, $system->invid, 't/V1') or diag($system->error);
#is($system->invoice('data_vencimento'), '', 't/V1-2') or diag($system->error);
#is($system->invoice('proximo'), '', 't/V1-2') or diag($system->error);
#
$inv = $system->faturar([999999]);
is($inv, $system->invid, 't/BUG') or diag($system->error);
#print $system->invoice('referencia');
$system->today(2008,10,8); #hoje;
$system->pay_invoice(11.00,$system->today);
#Data de ativacao
is($system->service('vencimento'), '2008-10-30', 't/BUG 2');
#Se tiver ativo, tem q ser tbm dia da ativacao
#Se tiver dias gratis, tem q ser mesmo dia do vencimento q ja ta

#$system->user('vencimento','30'); #gerava boleto torto, ver com mais de um serviço ativo
#$system->service('status','A');
#$system->service('inicio','2008-10-01');
#$system->service('vencimento','2008-10-10');
#$inv = $system->faturar([999999]);
#is($inv, $system->invid, 't/BUG') or diag($system->error);
#TEste de proporcionais

$system->clear_error;

#hUMmmm olha esse chamado, acho que já tinha te falado desse erro!! ve logo ai, o cara mal registra o dominio e ja recebe email avisando que vai expirar.
#axo que eh qnd usa a funcao de a confirmar, no boleto.
#Serviço
$system->sid(999999);
$system->service('status','S');
$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('invoice',0);
$system->service('pagos',0);
#ver comportamento quando ta tudo errado
$inv = $system->faturar([999999]);
is($inv, $system->invid, 't/servico gratuito 1') or diag($system->error);

#TODO lembrar q eu tava terminando de testar pra ver os casos dos gratuitos, servicos where vencimento = '0000-00-00' and status = 'A'
#apareceu um caso "Teórico" gratuito, registrou um domínio antes de rodar o financeiro, entrou em uma condição de correção e fudeu
#plano
$system->plan('valor_tipo','A');
$system->plan('tipo','Registro');
$system->today(2011,1,26); #hoje;
$system->sid(999999);
$system->service('pg',999998); #ANUAL
$system->service('status','S');
#$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$inv = $system->faturar([999999]);
is($system->vcto_fatura, '2011-02-02', 't/servico gratuito 2') or diag($system->error);

$system->sid(999999);
$system->service('pg',999998); #ANUAL
$system->service('status','A');
$system->service('inicio',$system->date('2011-01-26'));
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->today(2011,1,28); #hoje;
$inv = $system->faturar([999999]);
is($system->vcto_fatura, '2011-02-04', 't/servico gratuito 3') or diag($system->error);
is($system->service('proximo'), '2012-02-04', 't/servico gratuito 3-1') or diag($system->error); #Vai ser ajustado ao quitar
#Tem que dar tempo para pagar o problema é quando quita e gera a proxima tem que descontar os dias #mas ao quitar ele pega o proximo e coloca pra vencimento, entao na primeira fatura o proximo teria que ter esse desconto
$system->pay_invoice(100.00,$system->date('2011-01-29')) or diag($system->clear_error);
$system->today(2012,1,26); #hoje; 
$inv = $system->faturar([999999]);
is($system->vcto_fatura, '2012-01-26', 't/servico gratuito 3-2') or diag($system->error); 

$system->sid(999999);
$system->service('pg',999998); #ANUAL
$system->service('status','A');
$system->service('inicio',$system->date('2011-01-26'));
$system->service('fim',undef);
$system->service('vencimento',$system->date('2011-01-26')); #Definiu um vencimento [achou que o serviço estava de graça]
$system->service('proximo',undef);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$inv = $system->faturar([999999]);
is($system->vcto_fatura, '2011-01-26', 't/servico gratuito 4') or diag($system->error);

#Explicar melhor o caso tá dificil de entender
#Porque criou uma fatura zerada ???
#$system->sid(999999);
#$system->service('vencimento',$system->date('2011-01-26')); #Definiu um vencimento [achou que o serviço estava de graça]
#$inv = $system->faturar([999999]);
#is($system->service('proximo'), $system->vcto_fatura, 't/servico gratuito 5') or diag($system->error);

#TODO adicionar teste para verificar se a fatura com saldo creditado esta sendo separada individualmente e zerando

#TODO possivel implementacao de cancelamento de fatura quitada
##Cancelamentos de saldos
#$system->balanceid(999997);
#$system->balance('invoice',undef);
#$system->balance('bstatus','Q'); #Simulando quitado
#$system->balance('valor',55.39);
#$system->balance('service',undef);
#$system->balance('username',999999);
#$system->balance('descricao','Teste');
#$system->balanceid(999996);
#$system->balance('invoice',undef);
#$system->balance('bstatus','Q'); #Simulando quitado
#$system->balance('valor',600);
#$system->balance('service',undef);
#$system->balance('username',999999);
#$system->balance('descricao','Convertido em saldo');
#$system->balanceid(999995);
#$system->balance('invoice',undef);
#$system->balance('bstatus','Q'); #Simulando quitado
#$system->balance('valor',12);
#$system->balance('service',undef);
#$system->balance('username',999999);
#$system->balance('descricao','Teste cancela 2');
#
#$system->sid(999999);
#$system->service('pg',999999); #Mensal
#$system->service('status','A');
#$system->service('inicio',$system->date('2011-01-26'));
#$system->service('fim',undef);
#$system->service('vencimento',$system->date('2011-01-26')); #Definiu um vencimento [achou que o serviço estava de graça]
#$system->service('proximo',undef);
#$system->service('action','N');
#$system->service('invoice',0);
#$system->service('pagos',0);
#$inv = $system->faturar([999999]);
#
##Saldo gerado do resultado da fatura
#$system->balanceid(999998);
#$system->balance('invoice',undef);
#$system->balance('valor',666.40);
#$system->balance('service',undef);
#$system->balance('username',999999);
#$system->balance('descricao','Convertido em saldo');
#
#$system->cancel_invoice();
#
#$system->balanceid(999999);
#is($system->balance('invoice'), $inv, 't/Cancelar Saldo') or diag($system->error);
#is($system->balance('valor'), 10, 't/Cancelar Saldo') or diag($system->error);
#$system->balanceid(999997);
#is($system->balance('invoice'), undef, 't/Cancelar Saldo') or diag($system->error);
#$system->balanceid(999996);
#is($system->balance('invoice'), undef, 't/Cancelar Saldo') or diag($system->error);
#$system->balanceid(999995);
#is($system->balance('invoice'), undef, 't/Cancelar Saldo') or diag($system->error);

#Teste de desconto em meses, propriedade 7 dos serviços
$system->today(2012,02,10); #hoje;
# Serviço
$system->sid(999999);
$system->service('dominio','propriedade7');
$system->service('username',999999);
$system->service('pg',999999);
$system->service('status','A');
$system->service('inicio',$system->date('2012-01-01'));
$system->service('fim',undef);
$system->service('vencimento',$system->date('2012-02-15'));
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',1); #se tiver zero o vencimento vai pro inicio
$system->service('desconto',0);
$system->serviceprop(7,{2012 => [undef,{'type' => 0,'price' => '30.00'},{'type' => 0,'price' => '40.00'},{'type' => 1,'price' => '+15.00'},{'type' => 0,'price' => '0.00'},{'type' => 0,'price' => '0.00'},{'type' => 0,'price' => '0.00'},{'type' => 0,'price' => '0.00'},{'type' => 0,'price' => 20},{'type' => 0,'price' => '0.00'},{'type' => 0,'price' => '0.00'},{'type' => 1,'price' => 20},{'type' => 0,'price' => '0.00'}]});
# Plano
$system->plan('setup',10);
$system->plan('valor',126.24);
$system->plan('valor_tipo','M');
$system->plan('tipo','Hospedagem');

$system->user('vencimento','15');
#$DEBUG=1;
#$system->setting('DEBUG',1);
$inv = $system->faturar( [999999] );
is($inv, $system->invid, 't/Propriedade 7 $') or diag($system->error);
is($system->service('invoice'), $inv, 't/Propriedade 7 1') or diag($system->error);
is($system->service('vencimento'), '2012-02-15', 't/Propriedade 7 2') or diag($system->error);
is($system->service('proximo'), '2012-03-15', 't/Propriedade 7 3') or diag($system->error);
is($system->invoice('nome'), 'Fevereiro/2012', 't/Propriedade 7 4') or diag($system->error);
is($system->invoice('data_vencimento'), '2012-02-15', 't/Propriedade 7 5') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (propriedade7) => R\$ 86,24\n* (c) crédito (d) débito", 't/Propriedade 7 6') or diag($system->error);
is($system->invoice('valor'), 126.24-40, 't/Propriedade 7 7') or diag($system->error);
is($system->user('vencimento'), '15', 't/Propriedade 7 8') or diag($system->error);

$system->pay_invoice(86.24,$system->today);
#diag($system->service('vencimento'));
#diag($system->service('invoice'));
#diag($system->sid);
#diag($system->invoice('data_quitado'));
$system->today(2012,03,10); #hoje;
	
$system->setting('DEBUG',1);
$inv = $system->faturar( [999999] );
is($inv, $system->invid, 't/Propriedade 7 %') or diag($system->error);
is($system->service('invoice'), $inv, 't/Propriedade 7 1') or diag($system->error);
is($system->service('vencimento'), '2012-03-15', 't/Propriedade 7 2') or diag($system->error);
is($system->service('proximo'), '2012-04-15', 't/Propriedade 7 3') or diag($system->error);
is($system->invoice('nome'), 'Março/2012', 't/Propriedade 7 4') or diag($system->error);
is($system->invoice('data_vencimento'), '2012-03-15', 't/Propriedade 7 5') or diag($system->error);
is($system->invoice('referencia'), "(c) Hospedagem Windows Teste HW (propriedade7) => R\$ 107,30\n* (c) crédito (d) débito", 't/Propriedade 7 6') or diag($system->error);
is($system->invoice('valor'), 126.24-18.936, 't/Propriedade 7 7') or diag($system->error);
is($system->user('vencimento'), '15', 't/Propriedade 7 8') or diag($system->error);

#Confirmaçao de fatura e dias adiados de ação
# Serviço
$system->sid(999999);
$system->service('dominio','revenda.com');
$system->service('username',999999);
$system->service('pg',999999);
$system->service('status','A');
$system->service('inicio',$system->date('2012-01-01'));
$system->service('fim',undef);
$system->service('vencimento',$system->date('2013-03-23'));
$system->service('proximo',$system->date('2013-04-23'));
$system->service('envios',0);
$system->service('def',72);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',10); #se tiver zero o vencimento vai pro inicio
$system->service('desconto',0);

#Plano
$system->plan('tipo','Revenda');

#O Teste aqui é que mesmo despois de confirmado ele mantenha a quantidade de defs já dada anteriormente.
$system->today(2013,05,07); #hoje;
my ($pdate,$bdate,$rdate) = $system->exec_dates;   
my $date = $pdate || $bdate || $system->today();
my $def = $system->today() - $date;# + $system->service('def');
diag("$pdate $def");	
$system->confirm_invoice();
my ($n_pdate,$n_bdate,$n_rdate) = $system->exec_dates;
diag("$pdate,$bdate,$rdate");
diag("$n_pdate,$n_bdate,$n_rdate");

#
# Adicionar teste da funcao prorate, ver se ta criado o saldo positivo e nagativo corretamente com o texto credito e debito
# e se as datas atual e futura estão corretas
#

#Testar quando passar exatos 1 mes do vencimento , com vencimento para o dia 10, usuario com vencimento no dia 10 e no proximo dia 10 quita uma fatura com dta do dia 06

#Last error
diag($system->error) if $system->error;
1;
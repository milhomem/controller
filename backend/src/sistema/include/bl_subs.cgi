#********************************
# Security
#********************************
$key = $q->param('key');
if ($key) { 
	$dec = decrypt($key);
}else{
	print $q->header(-type => "text/html");
	print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=1 color=#666666><b>ERRO NA CHAVE DE ACESSO. <font size=1 color=#CC0000>CONTATE O SUPORTE.</b></font></b><br><br> </font></p>|;
	exit;
}
@vars = split("/",$dec);
$uusername = num($vars[0]) || 0;
$dtinsc = $vars[1] || 0;
$id = num($vars[2]) || 0;
#die qq|$uusername,$dtinsc,$id|; 
my $sth = select_sql(qq|SELECT * FROM `users` WHERE `username` = ?|,$uusername);
while(my $ref = $sth->fetchrow_hashref()) {   
	$check = $ref->{'inscricao'} || "error";
}
$sth->finish;

my ($invuser,$tarifa) = split('::', Invoice($id,"username tarifa"));
my @result = Tarifa($tarifa);

if ($dtinsc ne $check || !$id || $invuser ne $uusername || !$system->is_boleto_module($result[2])) {
	print $q->header(-type => "text/html");
	print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=1 color=#666666><b>BOLETO NÃO EXISTE. <font size=1 color=#CC0000>CONTATE O SUPORTE.</b></font></b><br><br> </font></p>|;
	exit;
}

#********************************
# BANDO DE DADOS
#********************************
if ($q->param('do') eq 'prorrogar') {	
	use Controller::Financeiro;
	my $self = Controller::Financeiro->new; 
	$self->invid($id);  
	$self->prorrogar(0); #Com multas e juros
	if ($self->error)
	{
		print $q->header(-type => "text/html");
		print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=2 color=#666666><b>|.$self->error.qq| <br><font size=1 color=#CC0000>CONTATE O SUPORTE.</b></font></b><br><br> </font></p>|;
		exit;
	}
}

# USER
($var_empresa,$var_name,$var_cpf,$var_cnpj,$var_endereco,$var_numero,$var_cidade,$var_estado,$var_cep) = split("---",Users($uusername,"empresa name cpf cnpj endereco numero cidade estado cep"));
$var_sacado = $var_empresa eq "" ? $var_name : $var_empresa;

# INVOICE
($status,$var_conta,$vencimento,$services) = split("::",Invoice($id,"status conta data_vencimento services"));
my $prorrogavel=1;
foreach my $serv (split(/ -\s?/,$services)) {
	my ($pg, $servico) = split(/x/, $serv);
	$system->sid($servico);
	local $Controller::SWITCH{skip_error} = 1;
	$prorrogavel=0 if $system->plan('tipo') eq 'Registro';
}

#********************************
# BOLETOS NÃO IMPRIMÍVEIS
#********************************
if ($status eq "Q") {
	print $q->header(-type => "text/html");
	print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=1 color=#666666><b>BOLETO </b></font><font color=#CC0000>PAGO</font>.</b><br><br> </font></p>|;	
	exit;
}
if ($status eq "D") {
	print $q->header(-type => "text/html");
	print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=1 color=#666666><b>BOLETO </b></font><font color=#CC0000>CANCELADO</font>.</b><br><br> </font></p>|;	
	exit;
}
if ($vencimento && $vencimento eq '0000-00-00') {
	print $q->header(-type => "text/html");
	print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=1 color=#666666><b>VENCIMENTO NÃO EXISTE. <font size=1 color=#CC0000>CONTATE O SUPORTE.</b></font></b><br><br> </font></p>|;
	exit;	
}

my $nvenc = date($vencimento);
$nvenc = $nvenc->next while $nvenc->day_of_week == 6 || $nvenc->day_of_week == 0 || Feriado($nvenc);
if ($nvenc < today() && $status ne "C") {
	print $q->header(-type => "text/html");
	print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=1 color=#666666><b>BOLETO </b></font><font color=#CC0000>VENCIDO</font>.|;
	print qq|<br><a href=?do=prorrogar&key=$key>CLIQUE AQUI</a> PARA PRORROGAR COM MULTA E JUROS.</b><br><br> </font></p>| if (!$q->param('noclick') && $prorrogavel == 1);	
	exit if (!$q->param('noclick'));
}	


#********************************
# IMPRESSÕES
#********************************
if (!$q->param('noclick')) {
	$imp = Invoice($id,"imp") + 1;
	execute_sql(qq|UPDATE `invoices` SET `imp` = $imp WHERE `id` = $id|); 
}

#********************************
# CÁLCULO
#********************************
$system->invid($id);
$system->tid($system->invoice('tarifa'));
unless ($system->tax('modulo')) {
	print $q->header(-type => "text/html");
	print qq|<p>&nbsp;</p><p>&nbsp;</p><p align=center><font size=1 color=#666666><b><font size=1 color=#666666><b>BOLETO INVÁLIDO. <font size=1 color=#CC0000>CONTATE O SUPORTE.</b></font></b><br><br> </font></p>|;
	exit;
}
eval "use ".$system->tax('modulo');
my $modulo = eval "new ".$system->tax('modulo');
$modulo->boleto;

#********************************
# PARSE
#********************************
$modulo->parse_boleto;
die $modulo->error;

1;
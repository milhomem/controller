#para gravar em utf-8
$system->{dbh}->do('/*!40101 SET character_set_client = utf8 */;'); #WRITE

#print header(-type => "text/html");
use LWP::UserAgent;
my $ua = LWP::UserAgent->new(timeout => 3*60);
$ua->agent('Controller/1.0'); 
use MIME::Base64;
use Milhomem::iUtils;
  
my $getid = $q->param('ID');
my $uri = $1 if $getid =~ m/https?:\/\/(.+?)\//i;

unless ($q->param('url_fail') && $q->param('url_success') && $system->setting('allowed_uris') =~ m/(?:^|,)$uri(?:,|$)/i) {
	print header(-type => "text/html");
	print "Problemas ao identificar seu formulário entre em contato com o provedor.";
	exit; 
};

#TODO seguranca signup
my $uid = $q->param('UID');
my $response = $ua->get("$getid/uid2.cgi?uid=$uid") if $getid =~ m/^https?:\/\//i;
my ($ruid,$rtvars) = split('-',$response->content) if $response && $response->is_success;
if ($ruid ne encode_base64($uid.$getid)) {
	$errstring = "err_key=Erro ao identificar seu formulário, tente enviá-lo novamente.";
	print "Content-type: text/html\n\n";
	print makeform("auto","post",URLDecode($q->param('url_fail')),URLDecode($ENV{'QUERY_STRING'})."&".$errstring);
	print submitform("auto");
	exit;
}

my $access_ip = $ENV{'REMOTE_ADDR'};
if ($access_ip) {
	my $sth = $system->select_sql(900,$access_ip);
	if ($sth->rows == 1) {
		$errstring = "err_key=Seu IP ($access_ip) foi bloqueado, por favor entre em contato com nossa equipe.";
		print "Content-type: text/html\n\n";
		print makeform("auto","post",URLDecode($q->param('url_fail')),URLDecode($ENV{'QUERY_STRING'})."&".$errstring);
		print submitform("auto");
		exit;
	}
}

#get form vars
#data para usuarios já registrado
my $uname = trim($q->param('username'));
my $passwd = trim($q->param('password'));
#data para usuarios novos
my $name = trim($q->param('name'));
my $email = trim($q->param('email'));
my $razao = trim($q->param('razao'));
my $cnpj = num($q->param('cnpj'));
$cnpj =~ s/^0// if length($cnpj) == 15;
my $cpf = num($q->param('cpf'));
my @endereco = (trim($q->param('endereco')),trim($q->param('complemento')),trim($q->param('bairro')));
my $endereco = URLDecode( join(" - ", @endereco) );
my $endereco2 = URLDecode($q->param('numero'));
my $telefone = num($q->param('DDD')).num($q->param('telefone'));
my $cidade = trim(URLDecode($q->param('cidade')));
my $estado = uc(trim($q->param('estado')));
my $pais = uc(trim($q->param('pais')));
my $cep = num($q->param('cep'));
$cep =~ s/^(\d{5})(\d*)$/$1-$2/ if length $cep >= 8;
my $pass1 = trim($q->param('Senha'));
my $pass2 = trim($q->param('Senha2'));
my $nivel = trim($q->param('nivel'));
my $from = Sender(Level => $nivel);
my $news = defined $q->param('news') ? num($q->param('news')) : 1;
my $cpfRequired = $global{'cpf_required'} == 0 ? 0 : 1;
#my $parcelas = $q->param('parcelas');
#deixado pra trás my $parcelamento = $q->param('parcelamento');
my $ccn = $q->param('ccn');
my $tarifa = $q->param('tarifa');
$tarifa ||= $global{'forma'};
#deixado pra trás my $paynow = $q->param('paynow');
#sistema de incicacoes
my $indicate;
if ($q->param('indicate')) {
	my ($pre,$user) = split(/-/, $q->param('indicate'), 2);
	$indicate = uc $pre eq uc $global{'users_prefix'} ? num($user) : undef;
	if (!$indicate) {
		my $sth  = select_sql(qq|SELECT `username`,`status` FROM `servicos` WHERE `dominio` = ? ORDER BY `username` DESC|,$q->param('indicate'));
		my ($pusers) = $sth->fetchall_arrayref();
		my ($ativos) = grep { $_->[1] eq 'A'} @$pusers;#Retorna somente 1
		$indicate = $ativos->[0] || $pusers->[0][0];#primeiro
		$sth->finish;
	}
}

#se senha de usuario completar ou usar a mesma
$pass1=$pass2=$passwd if $uname;

#TODO chave de protecao das opcoes
my ($sth,$error);

my $debug = qq|
Agent: $ENV{'HTTP_USER_AGENT'}<br> 
------------------------<br>
		user $uname<br>
		name $name <br>
		email $email <br> 
		razao $razao <br>
		cpf $cpf<br>
		cnpj $cnpj <br>
		endereco $endereco <br>
		endereco2  $endereco2 <br> 
		telefone $telefone <br>
		cidade $cidade <br>
		estado $estado <br>
		pais $pais <br> 
		cep $cep <br>
		pass1 $pass1 <br> 
		pass2 $pass2 <br> 


--------------------<br>
		dominio $dominio <br>
		plano $plano <br> 
		plataforma $plataforma <br>
		prazo $prazo <br>
		desconto $desc <br>
------------------------
|;
foreach ($q->param) {
	if ($_ =~ /^extra/) {
		$debug .= $_." = ".trim($q->param($_));
	}
}
#Varios servicos ao mesmo tempo
my @auth_servs;
#Verifica autenticidade
my $trusted_vars = decode_base64($rtvars);
if ($trusted_vars =~ s/$getid$//) {
	foreach (split('&',$trusted_vars)) {	
		$q->param(-name => trim($1), -value => trim($2)) if $_ =~ m/^(.+?)=(.*)$/;#overwrite vars
		push @auth_servs, $1 if m/^serv(\d*)\_/;
	}
	@auth_servs = Controller::iUnique(\@auth_servs);
} else {
	$errstring = "err_key=Erro ao identificar seu formulário, tente enviá-lo novamente.";
	print "Content-type: text/html\n\n";
	print makeform("auto","post",URLDecode($q->param('url_fail')),URLDecode($ENV{'QUERY_STRING'})."&".$errstring);
	print submitform("auto");
	exit;
}

#verifica dados se incorretos goto url_fail
goto CheckService if $uname;

#verifica dados se incorretos goto url_fail
$error = $template{'err_level'} = "err_level=Você deve escolher ao menos um nível de acesso" if !$nivel;
$error = $template{'err_pass'} = "err_pass=As senhas informadas não são iguais" if $pass1 ne $pass2 && !$uname;
$error = $template{'err_pass'} = "err_pass=As senhas não atingem o tamanho mínimo de $global{'pass_chars'} caracteres" if length($pass1) < $global{'pass_chars'} && !$uname;
$error = $template{'err_name'} = "err_name=$LANG{'error5'} $LANG{'name'}" if !$name;
$error = $template{'err_email'} = "err_email=Email inválido" if !$email || $email !~ m/^\w+(?:[\.-]?\w+)*@\w+(?:[\.-]?\w+)*(?:\.\w{2,3})+$/;
$error = $template{'err_cnpj'} = "err_cnpj=CNPJ $cnpj inválido." if $razao && !($cnpj && validaCPFCNPJ($cnpj));
$error = $template{'err_cpf'} = "err_cpf=CPF $cpf inválido." if $cpfRequired && $pais eq "BR" and !validaCPFCNPJ($cpf);
$error = $template{'err_cep'} = "err_cep=CEP inválido." if ($pais eq "BR") and ($cep !~ /\d{5}\-\d*/ || !$cep);
$error = $template{'err_pais'} = "err_pais=País inválido." if length($pais) != 2;
$error = $template{'err_tel'} = "err_tel=Telefone inválido. DDD-Número ex: 1188885555" if ($pais eq "BR") and !$system->is_valid_phone($system->num($telefone));

$error = $template{'err_cidade'} = "err_cidade=Cidade inválida." unless $cidade;		
$error = $template{'err_estado'} = "err_estado=Estado inválido." unless $estado;	

#alertas
if ($cpf || $cnpj) {
	my $sth;
	$sth = select_sql(qq|SELECT `username` FROM `users` WHERE `cnpj` = ?|,$cnpj) if $cnpj;
	$sth = select_sql(qq|SELECT `username` FROM `users` WHERE `cpf` = ?|,$cpf) if !$cnpj;
	if ( $sth->rows > 0 ) {
		my ($u) = $sth->fetchrow_array();
		$template{'alert'} .=  qq|<font size="2">Aviso: CPF / CNPJ <b>$cpf / $cnpj</b> já cadastrado para usuário $u.<BR>|;		
	}
	$sth = select_sql(qq|SELECT `username` FROM `users` WHERE `email` like CONCAT('%',?,'%')|,$email);
	if ( $sth->rows > 0 ) {
		my ($u1) = $sth->fetchall_arrayref();
		$u1 = join(",", map { @{$_} } @$u1);
		$template{'alert'} .= qq|<font size="2">Aviso: E-mail <b>$email</b> já cadastrado para os usuários $u1.<BR>| if ($sth->rows != 0);
	}
	$sth->finish;   
}

CheckService:
#Varios servicos ao mesmo tempo
my @servs;
foreach my $id (@auth_servs) {
	next unless $q->param("serv${id}_dominio");
	next unless $q->param("serv${id}_type");	
	$error = $template{'err_prazo'} = "err_prazo=Escolha um prazo ($id)." unless $q->param("serv${id}_prazo");
	$error = $template{'err_plano'} = "err_plano=Escolha um plano ($id)." unless $q->param("serv${id}_plano");
	push @servs, $id unless $error;
}

foreach my $id (@servs) {
	my $plano = $q->param("serv${id}_plano");
	my $prazo = $q->param("serv${id}_prazo");
	my $dominio = $q->param("serv${id}_dominio");
	$dominio =~ s/^www\.//;
	$sth = select_sql(qq|SELECT * FROM `servicos` WHERE `servicos` = $plano AND `dominio` = "$dominio"|);
	if ($sth->rows != 0) { $error = $template{'err_plano'} = "err_plano=O plano <b>$plano</b> já existe para o domínio <b>$dominio</b>.";}
	$sth->finish;

	$sth = $system->select_sql(q~SELECT `servicos` FROM `planos` WHERE (`pagamentos` REGEXP CONCAT('(^|::)',?,'(::|$)') OR `pagamentos` IS NULL OR `pagamentos` NOT REGEXP '[0-9]') AND `servicos` = ?~,$prazo,$plano);
	if ($sth->rows == 0) { $error = $template{'err_plano'} = "err_plano=O plano <b>$plano</b> não permite o prazo <b>$prazo</b>.";}
	$sth->finish;
}

#Verify username and password
if ($uname) {
	my ($pre,$userr) = split(/-/, $uname, 2);
	$username = $pre eq $global{'users_prefix'} ? num($userr) : undef;
	if (!$username) {
		my $sth  = select_sql(qq|SELECT `username` FROM `servicos` WHERE `dominio` = ?|,$uname); #Username pode ser dominio
		my ($pusers) = $sth->fetchall_arrayref();
		$username = join(",", map { @{$_} } @$pusers);	
		$sth->finish;
	}

	if (!$username && $system->is_valid_email($uname)) {
		my $sth = $system->select_sql(qq|SELECT `username` FROM `users` WHERE `email` LIKE CONCAT('%', ?, '%')|,$uname);
		my ($pusers) = $sth->fetchall_arrayref();
		$username = join(",", map { @{$_} } @$pusers);	
		$sth->finish;
	}
	
	if ($username) {
		my $sth  = select_sql(qq|SELECT `password`,`username` FROM `users` WHERE `username` in ($username)|); 
		while(my $ref = $sth->fetchrow_hashref()) {	
			my $cpass = encrypt_mm($passwd);
			if ($cpass ne $ref->{'password'}) {
				$username = undef;		
			} else {
				$username = $ref->{'username'};
				$system->uid($username);
				last;
			}
		}
		$error = $template{'err_username'} = "err_username=Usuário e senha inválidos." if $sth->rows == 0;
		$sth->finish;
	}
	$error = $template{'err_username'} = "err_username=Usuário e senha inválidos." unless $username;
}

#Verificar cartao de credito
my $ccapp = 0;
my $first = substr($ccn,0,4);
my $last = substr($ccn,-4);
my ($cvv2, $exp);

if ($ccn) {
	$ccn = num($ccn);
	$cvv2 = num($q->param('cvv2'));
	$exp = Controller::monthyear2string($q->param('ccmonth'),$q->param('ccyear'));

	$error = $template{'err_cartao'} = "err_cartao=Código de verificação inválido" unless $cvv2;
	$error = $template{'err_cartao'} = "err_cartao=Número do cartão inválido" unless length($ccn) > 14;
	$error = $template{'err_cartao'} = "err_cartao=Validade do cartão inválida" unless length($exp) == 4;
	
	if (length($ccn) > 14 && !$template{'err_cartao'}) { #TODO Verificar se o cartao é valido direito
		$error = $template{'err_cartao'} = "err_cartao=".$system->lang(2003) unless $system->tax('modulo');
		if ( $system->is_creditcard_module($system->tax('modulo')) && $cvv2 ) {
			my $ccnactive;
			if ($system->uid) {
				$system->ccid($system->creditcard_active);
				$ccnactive = $system->creditcard('ccn') if $system->ccid;
			}
			
			eval "use " . $system->tax('modulo');
			my $creditcard = eval "new " . $system->tax('modulo'); #Deve continuar com os mesmos dados
			$creditcard->ccid(999999); #teste
			$creditcard->creditcard('ccn',$ccn);
			$creditcard->creditcard('cvv2',$cvv2);
			$creditcard->creditcard('exp',$exp);
			
			#testar, so nao testar se for o ativo		
			if (!$system->uid || $ccnactive ne $creditcard->creditcard('ccn')) {
				if (!$system->error and $creditcard->cc_verify(10.00)) {
					#pode cadastrar
					$ccapp = 1;
				} else {
					$error = $template{'err_cartao'} = "err_cartao=".$system->lang(2001,$system->clear_error);
				}
			}
		}
	} elsif ($ccn && !$template{'err_cartao'}) {
		$error = $template{'err_cartao'} = "err_cartao=".$system->lang(2103);
	}
}

$errstring = "$template{'err_prazo'}&$template{'err_plata'}&$template{'err_level'}&";
$errstring .= "$template{'err_pass'}&$template{'err_name'}&$template{'err_email'}&$template{'err_cpf'}&$template{'err_cnpj'}&$template{'err_cep'}&";
$errstring .= "$template{'err_nr'}&$template{'err_pais'}&$template{'err_plano'}&$template{'err_cidade'}&$template{'err_estado'}&$template{'err_tel'}&";
$errstring .= "&$template{'err_username'}&$template{'err_servidor'}&$template{'err_cartao'}";

if ($error) {
	print "Content-type: text/html\n\n";
	print makeform("auto","post",URLDecode($q->param('url_fail')),URLDecode($ENV{'QUERY_STRING'})."&".$errstring);
	print submitform("auto");
	exit;
}

goto OnlyService if $uname;

#dados para email
$template{'IP_SOLICITANTE'} = $access_ip;
#email Data
$template{'nome'} = $name;
$template{'email'} = $email;
$template{'razao'} = $razao;
$template{'cpf'} = $cpf;
$template{'cnpj'} = $cnpj;
$template{'endereco'} = $endereco;
$template{'endereco2'} = $endereco2;
$template{'telefone'} = $telefone;
$template{'cidade'} = $cidade;
$template{'estado'} = $estado;
$template{'pais'} = $pais;
$template{'cep'} = $cep;
$template{'indicate'} = $q->param('indicate');
$template{'password'} = $pass1;
my @arrtmp = $q->param('observacoes');
$template{'obs'} = join("<br>", iDelete(\@arrtmp) );
my @notes;
foreach my $note_name ($q->param) {
	if ($note_name =~ s/^notes_//) {
		push @notes, $note_name.": ".$q->param('notes_'.$note_name) if $q->param('notes_'.$note_name);
	}
}	
my $notes = $template{'notes'} = join("\n", iDelete(\@notes) );

#cria usuario no banco , verifica se ativa ou se fica pendente
$sth = select_sql(qq|SELECT `username` FROM `users_del`|);
while (my $ref = $sth->fetchrow_hashref()) {
	$adduser = $ref->{'username'} if ($adduser > $ref->{'username'} || !$adduser);
}
$sth->finish;

if ($adduser < 1000) {
	$sth = select_sql(qq|SELECT `username` FROM `users` ORDER BY `username` DESC LIMIT 1|); 
	$ref = $sth->fetchrow_hashref();
	$adduser = $ref->{'username'}+1;
	$adduser = 1000 if ($adduser < 1000);
	$sth->finish;
}

my $password = encrypt_mm($pass1);	
my $pending  = $global{'validate'};
$nivel =~ s/::$//;
$nivel .= "::" if $nivel;
$conta = $global{'cc'};
die_nice(qq|Conta padrão inválida|) unless split("---",ContaCorrente($global{'cc'},"nome"));
die_nice(qq|Forma padrão inválida|) unless Tarifa($tarifa);

my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
my $salt = $chars[rand(@chars)] . $chars[rand(@chars)]. $chars[rand(@chars)]. $chars[rand(@chars)];
$username = num($adduser) ? $adduser : undef;		
$username = $system->execute_sql(662,$username, $password, "00", "CA", $name, $email, $razao, $cpf, $cnpj, $telefone, $endereco, $endereco2, $cidade, $estado, $pais, $cep, $nivel, $timemysql, $salt, $pending, "0", undef, "0", $conta, $tarifa,"0",$news,undef, $notes);

#email Data
$template{'user'} =  "$global{'users_prefix'}-$username";
$template{'linkuser'} = "$global{'baseurl'}/admin.cgi?do=viewuser&user=$username";
$template{'linkativ'} = "$global{'baseurl'}/admin.cgi?do=validate";

execute_sql(qq|DELETE FROM `users_del` WHERE `username` = ?|,$username);

#email de aviso ao usuario
my ($oke,$oks);
if ($pending == 1) {
	$oke = email ( User => "$username", To => "$email", From => "$from", Subject => 'sbj_new_user_success', txt => "welcome");		
	$oks = sms ( User => "$username", txt => "welcome");

	#email alerta contas
	$oke = email ( User => "$username", To => "$global{'contas'}", From => "$from", Subject => 'sbj_new_user', txt => "alertnewuser");
 } else {
	$oke = email ( User => "$username", To => "$email", From => "$from", Subject => 'sbj_welcome', txt => "welcome2");		
	#email alerta contas
	$oke = email ( User => "$username", To => "$global{'contas'}", From => "$from", Subject => 'sbj_new_user', txt => "alertnewuser2");
	$oks = sms ( User => "$username", txt => "welcome2");
	
}

OnlyService:
#Cadastro de cartao de credito
unless ($ccapp != 1 || length($ccn) <= 14) {
	my $cid = $system->execute_sql(854,$username,$q->param('ccnome'),$first,$last,Controller::encrypt_mm($ccn),$exp,Controller::encrypt_mm($cvv2),$system->setting('creditcard_status'),$tarifa);
	$system->execute_sql(856,0,$tarifa,$username,$cid) if $cid;

	$system->tid($tarifa);
	$template{'tarifa'} = $system->tax('tipo');
}

#Debug
email ( To => "$global{'controller_mail'}", From => "$from", Subject => "Erro signup", Body => "Erro: No Services<br>Dumper:<br>".$q->Dump ) unless scalar @servs > 0;
goto OnlyUser unless scalar @servs > 0;

my @checkbox;
foreach my $id (@servs) {
	#cria servico como solicitado, verifica se automatico ou nao
	my $dominio = $q->param("serv${id}_dominio");
	$dominio =~ s/^www\.//;
	my $plano = $q->param("serv${id}_plano");
	my $prazo = $q->param("serv${id}_prazo");
	my $sparcelas = $q->param("serv${id}_parcelas") || $parcelas;
	my $sdesc = sprintf('%.2f', $q->param("serv${id}_desconto"));
	$system->formtypeid($q->param("serv${id}_type"));
	my $desc = $system->formtype('desconto') > 0 ? $system->formtype('desconto') : $sdesc;
	my $setup = $system->formtype('setup');
	my $auto_c = $system->formtype('auto');
	my @planos = $system->formtype('planos');
	unless (scalar @planos > 0 || grep{ m/$plano/ } @planos) {
		#Debug
		email ( To => "$global{'controller_mail'}", From => "$from", Subject => "Erro signup", Body => "Erro: Form falso, nao bateu os planos @planos com o plano $plano<br>Dumper:<br>".$q->Dump ) unless @servs > 0;
	};
	my ($campos,$tipo,$plataforma) = split(" - ",Plano($plano,"campos tipo plataforma"));	
	my @campo = split(/::/,$campos);
	my $dados;
	foreach $_ (@campo) {
		$dados .= "$_ : ".trim($q->param("serv${id}_$_"))."::";
	}
	
	my ($ok,$newsid) = serv_add(	'username' => $username,
							'plan' => $plano,
							'domain' => $dominio,
							'dados' => $dados,
							'auto_c' => $auto_c,
							'prazo' => $prazo,
							'desc' => $desc,
							'setup' => $setup,
							'properties' => $system->formtype('properties'),
							'parcelas' => $sparcelas,
							);
	
	unless ($ok == 1) {
		email ( To => "$global{'controller_mail'}", From => "$from", Subject => "Novo Serviço - Erro ao criar", Body => "Erro: $ok<br>Dados: id> $id serv_add(	'username' => $username,'plan' => $plano,'domain' => $dominio,'dados' => $dados,'server' => $servidor,'auto_c' => $auto_c,'prazo' => $prazo,'desc' => $desc,'setup' => $setup,'dias' => $dias)" );
	} 
	
	if ($ok == 1) {#sempre enviar email já que é uma ferramenta fora do sistema
		push @checkbox, $newsid;
		#indicacao
		{
			local $Controller::SWITCH{'skip_log'} = 1;
			$system->execute_sql(qq|call add_indicate(?,?)|,$newsid,$indicate) if $indicate && $newsid;
			#stats
			$system->execute_sql(1065,$username,$newsid,undef,undef,$q->param('extra_conheceu') || $q->param('extra_conheceu_outros') || undef) if ($q->param('extra_conheceu') || $q->param('extra_conheceu_outros'));			
		}
		#email Data
		$template{'user'} = "$global{'users_prefix'}-$username";
		$template{'dominio'} = $dominio;
		$template{'plano'} = "$plano - " . join(" ",split(" - ",Plano($plano,"tipo plataforma nome")));		
		$template{'prazo'} = Pagamento($prazo,"nome");
		$template{'plataforma'} = $plataforma;
		$template{'desconto'} = CurrencyFormatted($desc);
		$template{'dias'} = $dias;
		$template{'setup'} = $setup == 1 ? $LANG{'Yes'} : $LANG{'No'};
		$template{'parcelas'} = $parcelas;
		my @arrtmp;
		foreach ($q->param) {
			if ($_ =~ /^extra_/) {
				push @arrtmp, $_." = ".$q->param($_);
			}
		}	
		$template{'obs'} = join("<br>", iDelete(\@arrtmp) );		
			
		#email alerta contas
		email ( User => "$username", To => "$global{'contas'}", From => "$from", Subject => 'sbj_new_service', txt => "alertnewservice");	
	}
}

if ($q->param('invoicing') && @checkbox) {
	$system->faturar(@checkbox);
}

$system->unlock_billing;
my $syserror = $system->clear_error;
if ($syserror) {#General errors
	email ( To => "$global{'controller_mail'}", From => "$from", Subject => "Erro signup", Body => "Erro: $syserror<br>Dumper:<br>".$q->Dump );
}

OnlyUser:
#retorna para pagina de sucesso definida
print "Content-type: text/html\n\n";
print makeform("auto","post",URLDecode($q->param('url_success')));
print submitform("auto");
exit;

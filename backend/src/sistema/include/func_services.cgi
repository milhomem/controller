#Rotinas de tratamento de dados
#Área: Serviços

sub serv_add {
	return if $system->{'ERR'};
	my %cmd = @_;

	my ($plat,$tipo,$server) = split(" - ",Plano($cmd{plan},"plataforma tipo pservidor")) if $cmd{plan} > 0;
	$cmd{server} = num($server) if num($server) > 1;
	$cmd{server} ||= num($global{$plat.$tipo});
	$cmd{server} = 1 unless num($cmd{server});
	$cmd{parcelas} = 1 unless num($cmd{parcelas});
	return "Plataforma do servidor inválida para o Plano" if $plat ne OS(Servidor($cmd{server},"os")) && $cmd{server} != 1;#exclui-se quando nao se tem servidor 
	return "Username inválido" if !num($cmd{username});
	return "Plano inválido" if !num($cmd{plan});
	return "Dias inválido" if num($cmd{dias}) < 0;
	return "Prazo inválido" if !num($cmd{prazo});	

	$system->execute_sql(21,$cmd{username},$timemysql,undef);

	$cmd{lock} = 0 unless num($cmd{lock});

	#definir escopo das variaveis
	my ($sth,$service,$credito,$valor);

	$sth = select_sql(qq|SELECT `servicos`.`id` FROM `servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` WHERE (`servicos`.`servicos` = $cmd{plan} AND HEX(`servicos`.`dominio`) = HEX(CONVERT("$cmd{domain}" USING latin1)) AND `planos`.`tipo` != "Adicional")|);
	if ($sth->rows != 0) { return "O plano <b>$cmd{plan}</b> já existe para o domínio <b>$cmd{domain}</b>.<br>"; }
	$sth->finish;  
	
	$sth = $system->select_sql(qq|SELECT `username` FROM `users` WHERE `username` = ? UNION ALL SELECT `servicos` FROM `planos` WHERE `servicos` = ?|,$cmd{username},$cmd{plan});
	if ($sth->rows != 2) { return "O usuário <b>$cmd{username}</b> ou o plano <b>$cmd{plan}</b> não existe.<br>"; }
	$sth->finish; 	
	 
	$cmd{domain} = "Independente" if !$cmd{domain};
	$cmd{desc} = 0 if !$cmd{desc};
	
	#auto_create 0-no 1-yes 2-wait 3-free 4-free+wait #retirei pq agora o usuario tem opcao de usar ou nao o credito
	# 40-credito|no  42-credito|wait
	$cmd{auto_c} = num($cmd{auto_c}) if num($cmd{auto_c});
	if ($cmd{credito} == 1) {
		#consulta credito, já não comprometidos *precavendo solicitacoes sucessivas sem credito
		$credito = credito($cmd{username});
		my ($mult) = split(" - ", Pagamento($cmd{prazo},"intervalo"));
		$valor = parcela($cmd{plan},$cmd{prazo},$cmd{desc}); #parcela com descontos
		$valor += Plano($cmd{plan},"setup") if $cmd{setup} eq "yes";
		$cmd{auto_c} = 2 if $credito && $valor > 0;
	}
	
	if ($cmd{auto_c} == 1) {
		$service = $system->execute_sql(qq|INSERT INTO `servicos` (`id`,`username`,`dominio`,`servicos`,`status`,`inicio`,`fim`,`vencimento`,`proximo`,`servidor`,`dados`,`useracc`,`pg`,`envios`,`def`,`action`,`invoice`,`pagos`,`desconto`,`lock`,`parcelas`) 
		VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,$cmd{username},$cmd{domain},$cmd{plan},'S','0000-00-00','0000-00-00','0000-00-00','0000-00-00',$cmd{server},$cmd{dados},undef,$cmd{prazo},0,0,'C',undef,0,$cmd{desc},$cmd{lock},$cmd{parcelas});
	} elsif ($cmd{auto_c} == 0) {
		$service = $system->execute_sql(qq|INSERT INTO `servicos` (`id`,`username`,`dominio`,`servicos`,`status`,`inicio`,`fim`,`vencimento`,`proximo`,`servidor`,`dados`,`useracc`,`pg`,`envios`,`def`,`action`,`invoice`,`pagos`,`desconto`,`lock`,`parcelas`) 
		VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,$cmd{username},$cmd{domain},$cmd{plan},'F','0000-00-00','0000-00-00','0000-00-00','0000-00-00',$cmd{server},$cmd{dados},undef,$cmd{prazo},0,0,'N',undef,0,$cmd{desc},$cmd{lock},$cmd{parcelas});
	} elsif ($cmd{auto_c} == 2) {
		$service = $system->execute_sql(qq|INSERT INTO `servicos` (`id`,`username`,`dominio`,`servicos`,`status`,`inicio`,`fim`,`vencimento`,`proximo`,`servidor`,`dados`,`useracc`,`pg`,`envios`,`def`,`action`,`invoice`,`pagos`,`desconto`,`lock`,`parcelas`) 
		VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,$cmd{username},$cmd{domain},$cmd{plan},'S','0000-00-00','0000-00-00','0000-00-00','0000-00-00',$cmd{server},$cmd{dados},undef,$cmd{prazo},0,0,'N',undef,0,$cmd{desc},$cmd{lock},$cmd{parcelas});
	} elsif ($cmd{auto_c} == 3) {
		$service = $system->execute_sql(qq|INSERT INTO `servicos` (`id`,`username`,`dominio`,`servicos`,`status`,`inicio`,`fim`,`vencimento`,`proximo`,`servidor`,`dados`,`useracc`,`pg`,`envios`,`def`,`action`,`invoice`,`pagos`,`desconto`,`lock`,`parcelas`) 
		VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,$cmd{username},$cmd{domain},$cmd{plan},'S','0000-00-00','0000-00-00','0000-00-00','0000-00-00',$cmd{server},$cmd{dados},undef,$cmd{prazo},0,0,'C',undef,0,$cmd{desc},$cmd{lock},$cmd{parcelas});
		$system->execute_sql(qq|REPLACE INTO `promocao` VALUES (?,?,?)|,$service,$cmd{dias},1) if $cmd{dias};#1 - dias gratis
	} elsif ($cmd{auto_c} == 4) {
		$service = $system->execute_sql(qq|INSERT INTO `servicos` (`id`,`username`,`dominio`,`servicos`,`status`,`inicio`,`fim`,`vencimento`,`proximo`,`servidor`,`dados`,`useracc`,`pg`,`envios`,`def`,`action`,`invoice`,`pagos`,`desconto`,`lock`,`parcelas`) 
		VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,$cmd{username},$cmd{domain},$cmd{plan},'S','0000-00-00','0000-00-00','0000-00-00','0000-00-00',$cmd{server},$cmd{dados},undef,$cmd{prazo},0,0,'N',undef,0,$cmd{desc},$cmd{lock},$cmd{parcelas});
		$system->execute_sql(qq|REPLACE INTO `promocao` VALUES (?,?,?)|,$service,$cmd{dias},1) if $cmd{dias};#1 - dias gratis
	} else {
		return "Opção auto_c inválida: $cmd{auto_c}";
	}
	
	if ($credito && $valor > 0) {#converte crédito em saldo
		my $dif = $credito > $valor ? $valor : $credito;
		my $bid = $system->execute_sql(qq{INSERT INTO `saldos` VALUES (NULL,?,?,?,?,?)},$cmd{username},$dif,"Crédito para aquisição do serviço $service - $cmd{domain}",$service,undef);
		$system->execute_sql(qq{INSERT INTO `creditos` VALUES (NULL,?,?,?,?)},$cmd{username},-$dif,"Solicitação do serviço $service",$bid);		
	}
	
	if ($cmd{setup} eq "no") {
		$system->execute_sql(qq|REPLACE INTO `promocao` VALUES (?,"1","2")|,$service);#2 - Sem setup			
	}
	
	if ($cmd{vcin} eq "yes") {
		$system->execute_sql(qq|REPLACE INTO `promocao` VALUES (?,"1","4")|,$service);#4 - Vencimento Independente			
	}

	if ($cmd{fatexc} eq "yes") {
		$system->execute_sql(qq|REPLACE INTO `promocao` VALUES (?,"1","6")|,$service);#6 - Fatura Exclusiva			
	}
	
	foreach my $type (keys %{$cmd{properties}}) {
		$system->execute_sql(qq|REPLACE INTO `promocao` VALUES (?,?,?)|,$service,$cmd{properties}{$type},$type) if $cmd{properties}{$type};
	}
	
	execute_sql(qq|DELETE FROM `cron_lock` WHERE `id` = ?|,$cmd{username},1);
	
	#Se não automático abrir um ticket	
	if ($cmd{auto_c} == 0 && $is_admin != 1) {
		ticket_new(TICKETS_METHOD_SYSTEM, TICKETS_OWNER_SYSTEM, $cmd{username}, '', "Comercial", 
			"Solicitação de Serviço", 
			"Solicito a aquisição deste serviço.", 
			"Serviço cadastrado como finalizado, altere o serviço para ativá-lo.", 
			HIDDEN, $service, "$global{'dpriS'}");
	}

	return 1, $service;
}

sub serv_exec {
	my ($serv, $action, $par, $auto_c, $dias, $setup, $touser, $nvalue) = @_;
	my ($status, $username, $tipo, $pagos) = split(" - ",Servico($serv,"status username tipo pagos"));
	return "Serviço inválido" if !$status;
	return "Username inválido" if !num($username);	
	#Liberando recalculos das alteracoes
	execute_sql(qq|DELETE FROM `cron_lock` WHERE `id` = $username|,"",1);
	
	

	if ($action eq "bl" && ($status eq "A" || ($status eq "P" && $par))){
		execute_sql(qq|UPDATE `servicos` SET `action` = "P" WHERE `id` = $serv|) if $par;
		execute_sql(qq|UPDATE `servicos` SET `action` = "B" WHERE `id` = $serv|) if !$par;
		return ("Sucesso");
	}

	if ($action eq "cn" && $status ne "C"){	
		execute_sql(qq|UPDATE `servicos` SET `status` = "C" WHERE `id` = $serv|);
		$system->execute_sql(820,$serv,$nvalue) if $nvalue ne "";

		my $auto = eval $system->setting('auto_cancel'); #Tipo => 0|1
		#new call
		if ($auto->{$tipo} == 1) {
			serv_exec($serv, "fn");
		} elsif ($is_admin != 1) {
			ticket_new(TICKETS_METHOD_SYSTEM, TICKETS_OWNER_SYSTEM, $username, '', "Comercial", 
				"Solicitação de Cancelamento", 
				"Solicito o cancelamento deste serviço.", 
				"Altere o action para R para que a alteração ocorra.", 
				HIDDEN, $serv,  "$global{'dpriS'}");
		}
				
		return ("Sucesso");
	}

	if ($action eq "fn" && $status ne "F" && $status ne "S"){
		execute_sql(qq|UPDATE `servicos` SET `action` = "R" WHERE `id` = $serv|);
		return ("Sucesso");
	}

	if ($action eq "at" && ($status ne "A" && $status ne "S" && $status ne "F")){
		execute_sql(qq|UPDATE `servicos` SET `action` = "A" WHERE `id` = $serv|);
		return ("Sucesso");
	} 				

	if ($action eq "cr" && $status eq "S") {
		execute_sql(qq|UPDATE `servicos` SET `action` = "C" WHERE `id` = $serv|);
		return ("Sucesso");
	}

	if ($action eq "rcr" && $status eq "F"){
		if ($auto_c eq "yes") {
			execute_sql(qq|UPDATE `servicos` SET `status` = "S", `action` = "C", `vencimento` = "0000-00-00", `fim` = "0000-00-00", `proximo` = "0000-00-00", `envios` = "0", `pagos` = "0" WHERE `id` = $serv|);
		} elsif ($auto_c eq "no") {
			execute_sql(qq|UPDATE `servicos` SET `vencimento` = "0000-00-00", `fim` = "0000-00-00", `proximo` = "0000-00-00", `envios` = "0", `pagos` = "0" WHERE `id` = $serv|);
		} elsif ($auto_c eq "wait") {
			execute_sql(qq|UPDATE `servicos` SET `status` = "S", `action` = "N", `vencimento` = "0000-00-00", `fim` = "0000-00-00", `proximo` = "0000-00-00", `envios` = "0", `pagos` = "0" WHERE `id` = $serv|);
		} elsif ($auto_c eq "free") {
			execute_sql(qq|UPDATE `servicos` SET `status` = "S", `action` = "C", `vencimento` = "0000-00-00", `fim` = "0000-00-00", `proximo` = "0000-00-00", `envios` = "0", `pagos` = "0" WHERE `id` = $serv|);
			execute_sql(qq|REPLACE INTO `promocao` VALUES ($serv,"$dias","1")|);#1 - dias gratis
		}

		if ($setup eq "no") {
			execute_sql(qq|REPLACE INTO `promocao` VALUES ($serv,"1","2")|);#2 - Sem setup			
		}

		if ($auto_c =~ m/yes|no|wait|free/) {
			execute_sql(qq|DELETE FROM `cron_lock` WHERE `id` = $username|,"",1);
			return ("Sucesso");
		}
	}
	
	if ($action eq "tf") {
		my $sth = select_sql(qq|SELECT * FROM `users` WHERE `username` = ?|,$touser);
		return("Usuário não existe") if $sth->rows == 0;
		execute_sql(qq|UPDATE `servicos` SET `username` = $touser WHERE `id` = $serv|);
		execute_sql(qq|INSERT INTO `actionlog` VALUES ( NULL, "ADMIN", "TRANSFERIR USUARIO", "U=$touser-S=$serv" )|);
		execute_sql(qq|DELETE FROM `cron_lock` WHERE `id` = $touser|,"",1);
		return ("Sucesso");
	}
	
	if ($action eq "nd") {
		if ($global{'auto_renew'} == 1 && $status eq "A" && $tipo eq "Registro" && $pagos > 0) {
			execute_sql(qq|UPDATE `servicos` SET `action` = "A" WHERE `id` = $serv|); #Pode repetir várias vezes que só vai renovar 1 vez, desde que o vencimento não seja modificado
		} else {
			execute_sql(qq|UPDATE `servicos` SET `action` = "N" WHERE `id` = $serv|);
		}
		return ("Sucesso");
	}

	if ($action eq "csts") {
		execute_sql(qq|UPDATE `servicos` SET `status` = "$nvalue" WHERE `id` = $serv|);
		return ("Sucesso");
	}
	
	if ($action eq "cact") {
		execute_sql(qq|UPDATE `servicos` SET `action` = "$nvalue" WHERE `id` = $serv|);
		return ("Sucesso");
	}

	return ("Erro");
}

sub serv_del {
	my ($servico) = num(shift); #Argumento
	return 0 if !$servico;

	#definir escopo das variaveis
	my ($sth);
	
	$sth = select_sql(qq|SELECT `id` FROM `calls` WHERE `service` = $servico|);
	while(my $ref = $sth->fetchrow_hashref()) {
		execute_sql(qq|DELETE FROM `activitylog` WHERE `cid` = $ref->{'id'}|);
		execute_sql(qq|DELETE FROM `notes` WHERE `call` = $ref->{'id'}|);
	}
	
	execute_sql(qq|DELETE FROM `cancelamentos` WHERE `servid` = $servico|);
	execute_sql(qq|DELETE FROM `servicos_set` WHERE `servico` = $servico|);
	execute_sql(qq|DELETE FROM `promocao` WHERE `servico` = $servico|);		

	execute_sql(qq|DELETE FROM `calls` WHERE `service` = $servico|);
	execute_sql(qq|DELETE FROM `saldos` WHERE `servicos` = $servico|);
	execute_sql(qq|DELETE FROM `servicos` WHERE `id` = $servico|);
	
	return 1;
}

1;
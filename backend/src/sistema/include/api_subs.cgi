sub section 
{
    $section = "@_";

	if ($section eq "list_planos") {
		my $plat = $q->param('plataforma');
		my $tipo = $q->param('tipo');
		my $nivel = join("::%' OR `level` LIKE '%",$q->param('level'));
				
		print "Content-type: text/plain\n\n";
		#pagamentos
		my (%pagamentos,%descontos);
		$sth = $system->select_sql(qq|SELECT `descontos`.`plano`,`descontos`.`valor`,`pagamento`.* FROM `pagamento` LEFT JOIN `descontos` ON `pagamento`.`id` = `descontos`.`pg`|);
		while (my $ref = $sth->fetchrow_hashref) {
			$descontos{$ref->{'plano'}}{$ref->{'id'}}= $ref->{'valor'};
			$pagamentos{$ref->{'id'}} = $ref->{'pintervalo'};
		}		
		#imprime id , preco e descricao de acordo com a plataforma e tipo
		$sth = $system->select_sql(qq|SELECT `servicos`,`nome`,`descricao`,`valor`,`valor_tipo`,`pagamentos` FROM `planos` WHERE (`tipo` = '$tipo' AND `plataforma` = ? AND (`level` LIKE '%$nivel%'))|,$plat);
		while (my ($id,$nome,$desc,$val,$div,$pgs) = $sth->fetchrow_array()) {
			#multiplicador de valor
			$divi = Valor($div,1);
			$val = $val/$divi; 	
			print "Id: $id\n";
			print "Nome: $nome\n";
			#print "Desc: $desc\n";	
			foreach (keys %pagamentos) {
				#nao tem desconto pq nao tem servico my $desconto = $desc ? $desc : $descontos{$id}{$_};		
				print "Parcela$_: ".($val * $pagamentos{$_} - $descontos{$id}{$_})."\n";
			}
			print $pgs =~ /\d/ ? "Pgs: ".join('::',sort ({$pagamentos{$a} <=> $pagamentos{$b}} split('::',$pgs))) ."\n" : "Pgs: ".join('::',sort ({$pagamentos{$a} <=> $pagamentos{$b}} keys %pagamentos))."\n"; #ordenado por parcelas para dar uma opção não lógica de ordem
			print "\n";
		}
	}
	
	if ($section eq "list_pagamentos") {
		my $plano = num($q->param('plano'));
		
		print "Content-type: text/plain\n\n";
		$system->pid($plano);
		my $pgs = $system->plan("pagamentos");
		$sth = $system->select_sql(qq|SELECT * FROM `pagamento` ORDER BY `intervalo`|);
		while (my $ref = $sth->fetchrow_hashref()) {
			next if $pgs && $pgs !~ m/(^|::)$ref->{'id'}(::|$)/;			
			print "Id: $ref->{id}\n";
			print "Nome: $ref->{nome}\n";
			print "Primeira: $ref->{primeira}\n";
			print "Intervalo: $ref->{intervalo}\n";
			print "Parcelas: $ref->{parcelas}\n";
			print "Consecutiva: $ref->{repetir}\n";
			print "\n";
		}
	}
	
	if ($section eq "myconnect") {

		print "Content-type: text/plain\n\n";
		my $dbname = $q->param('db');
		my $dbhost = $q->param('host');
		my $dbuser = $q->param('user');
		my $dbpass = $q->param('pwd');
		my $dbh = DBI->connect("DBI:mysql:$dbname:$dbhost","$dbuser","$dbpass") || script_fatal("Erro ao conectar-se com o banco:<br>*$DBI::errstr");
		$sth = select_sql(qq|SHOW TABLES;|);
		my $tables;
		while (my ($ref) = $sth->fetchrow_array()) {
			 $tables.="$ref\n";
		}
		$tables =~ s/\n$//;
		print $tables;
	}
	
	if ($section eq "send_2via") {
		my $dominio = $q->param('dominio');
		$dominio =~ s/^www\.//;

		print "Content-type: text/plain\n\n";
		my $sth = $system->select_sql(qq|SELECT `invoices`.*,`users`.`inscricao`,`users`.`name`,`users`.`username`,`users`.`vencimento`,`users`.`email`,`users`.`forma`,`users`.`conta` FROM `invoices` INNER JOIN `users` ON `invoices`.`username`=`users`.`username` WHERE `invoices`.`status` = "P" AND `services` LIKE CONCAT('%x',(SELECT `id` FROM `servicos` WHERE `dominio` = ?),'%')|,$dominio);		
	}
	
	if ($section eq "get_domain_info") {
		my $dominio = $q->param('dominio');
		$dominio =~ s/^www\.//;
		
		print "Content-type: text/plain\n\n";
		my $sth = $system->select_sql(qq|select `servicos`.`id`,`servicos`.`username`,`servicos`.`dominio`,
		`servicos`.`status`,`servicos`.`action`,`servicos`.`inicio`,`servicos`.`fim`,`servicos`.`vencimento`,`servicos`.`proximo`,`servicos`.`useracc`,
		`servicos`.`invoice`,`servicos`.`envios`,`servicos`.`def`,
		`planos`.`nome` AS plano,`planos`.`descricao`, `planos_modules`.`modulo`,`planos`.`tipo`,`planos`.`plataforma`,
		`planos`.`setup`,`planos`.`valor`,`servicos`.`desconto`,
		`pagamento`.`nome` AS pagamento,`pagamento`.`primeira`,`pagamento`.`intervalo`,`pagamento`.`parcelas`,
		`servidores`.`nome` AS servidor,`servidores`.`host`,`servidores`.`ip`,`servidores`.`port`,`servidores`.`os`,
		`servidores_set`.`Rns1`,`servidores_set`.`Rns2`,`servidores_set`.`Hns1`,`servidores_set`.`Hns2`,`servidores_set`.`MultiWEB`,`servidores_set`.`MultiDNS`,`servidores_set`.`MultiMAIL`,`servidores_set`.`MultiFTP`,`servidores_set`.`MultiSTATS`,`servidores_set`.`MultiDB`
		from `servicos` 
		left join `planos` on `servicos`.`servicos` = `planos`.`servicos`
		left join `planos_modules` on `servicos`.`servicos` = `planos_modules`.`plano`
		left join `pagamento` on `servicos`.`pg` = `pagamento`.`id`
		left join `servidores` on `servidores`.`id` = `servicos`.`servidor`
		left join `servidores_set` on `servidores`.`id`=`servidores_set`.`id`
		WHERE `servicos`.`dominio` = ?|,$dominio);
		while (my $ref = $sth->fetchrow_hashref()) {
			my $tables;			
			my $i=0;
			while ($sth->{NAME}->[$i]) {   
				my $column = $sth->{NAME}->[$i];
				my $type = $sth->{TYPE}->[$i];
				my $line = $ref->{$column};
				$tables.="$column: $line\n";
				$i++;
			}
			$tables .= "\n";
			print $tables;
		};				
	}
	
	if ($section eq "auth_info") {
		print "Content-type: text/plain\n\n";
		
		my $uname = $q->param('user');
		my $passwd = $q->param('pass');
		if ($uname) {
			my ($pre,$userr) = split(/-/, $uname, 2);
			my $username = $pre eq $system->setting('users_prefix') ? num($userr) : undef;
	
			if (!$username) {
				my $sth = $system->select_sql(qq|SELECT `username` FROM `servicos` WHERE `dominio` = ?|,$uname);
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
				my $sth  =  $system->select_sql(qq|SELECT `password`,`username` FROM `users` WHERE `username` in (?)|,$username); 
				while(my $ref = $sth->fetchrow_hashref()) {	
					my $cpass = encrypt_mm($passwd);
					if ($cpass ne $ref->{'password'}) {
						$username = undef;		
					} else {
						$username = $ref->{'username'};
						print 'OK';
						last;
					}
				}
				print $system->lang('error6') if $sth->rows == 0;
				$sth->finish;
			} else {
				print $system->lang('error6');
			}
		} else {
			print $system->lang('error6');
		}
	}
	
	if ($section eq "domain_avail") {
		print "Content-type: text/plain\n\n";
		
		my $domain = $q->param('domain');
		if ($domain) {
			my $modulo; 
			if ($domain =~ m/\.(?:com|net|org|biz|info|us)$/i) {
				$modulo = 'Controller::Registros::ResellOne';
			} else {
				$modulo = 'Controller::Registros::RegistroBR';
			}
			eval "use ".$modulo;
			my $registro = eval "new ".$modulo;
			
			$registro->_domain($domain);
			
			if ($registro->availdomain) {
				if ($registro->error) {
					print $system->lang('809',$registro->clear_error);
				} else {
					print 'OK';
				}
			} else {
				print $system->lang('810',$domain);
			}
		} else {
			print $system->lang('810',$domain);
		}
	}	
	
	if ($section eq "domain_info") {
		print "Content-type: text/plain\n\n";
		
		my $domain = $q->param('domain');
		if ($domain) {
			my $modulo; 
			if ($domain =~ m/\.(?:com|net|org|biz|info|us)$/i) {
				$modulo = 'Controller::Registros::ResellOne';
			} else {
				$modulo = 'Controller::Registros::RegistroBR';
			}
			eval "use ".$modulo;
			my $registro = eval "new ".$modulo;
			
			$registro->_domain($domain);
			
			my $whois = $registro->whois;
			if ($registro->error) {
				print $system->lang('809',$registro->clear_error);
			} else {
				print $whois;
			}
		} else {
			print $system->lang('9','domain_info');
		}
	}	
}

1;
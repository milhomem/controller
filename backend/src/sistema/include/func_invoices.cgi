#Rotinas de tratamento de dados
#Área: Faturas
our %SIDS;

sub gerar_fatura {
	my $un = shift;
	my $vc = shift;
	$vc = $date_no if $vc eq '00';
	my $sm = shift;
	my $force = shift || 0;
	my $srvs = shift;

	my (@refer,$srvcs,@srv,@sal,@sids);
	my ($year_new,$monthto,$venc_insert,$inv);
	my ($coud,$promo6_insert,$pgtipo_insert,$parcelas_insert,$saldo_pendente);	
	my $extra = 0;
	my $extrajm = 0;
	my $vsrv = 0;
	my $vsal = 0;
	$sm = $sm == 1 ? 2 : 0;
	my @months = ('','Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro');
	my $sthw;

	my $sids = "(`id` = '".join("' OR `id` = '",@$srvs)."')";	
	my $sts = qq|SELECT * FROM `servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` WHERE (`servicos`.`username` = ? AND (`servicos`.`status` != "C" AND `servicos`.`status` != "F"))|;
	$sts .= qq|	AND $sids| if @$srvs;
	my $sth = select_sql($sts,$un);
	while(my $ref = $sth->fetchrow_hashref()) {
		next if $SIDS{$ref->{id}} == 1;#feito para nao repetir o mesmo servico na mesma chamada	
		my ($venc_proximo,$mest,$vencto_invoice);
		my $vencto = $ref->{'vencimento'};
		my $sid	= $ref->{'id'};
		my $pid	= $ref->{'servicos'};
		my $start = $ref->{'inicio'};
		my $setup = $ref->{'setup'};
		my $desc = $ref->{'desconto'};
		my $pg = $ref->{'pg'};
		my $tipo = $ref->{'valor_tipo'};
		my $p_tipo = $ref->{'tipo'};
		my $parcelas = $ref->{'parcelas'};
		my $has_invoice = $ref->{'invoice'};

		#multiplas invoices
		my $invmult = $global{'invoices'} == 1 && $vencto ne "0000-00-00" ? 1 : 0;
		next if ($global{'invoices'} != 1 && $has_invoice > 0);
		
		#30 dias antecipados para cobranca de registro	
		my ($venc_new, $mult, $verde, $postecipado)	= $p_tipo eq "Registro" ? Prazo($sid,,$force+30) : Prazo($sid,$force);
		#verificando se existem serviços ativos a considerar
		$sthw = select_sql(qq|SELECT `servicos`.`status` FROM `servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` WHERE `servicos`.`status` != "S" AND `servicos`.`status` != "F" AND `servicos`.`vencimento` != "0000-00-00" AND `planos`.`tipo` != "Registro" AND `servicos`.`username` = $un|) if $verde == 1;
		#configurando vencimento da fatura
		if ($vencto eq "0000-00-00"){
			if (Promo($sid,1)) {
				if ($postecipado == 1) {#prazo + dias gratis
					$venc_new = date($venc_new) + Promo($sid,1);
				} else { #(start|hoje) + dias gratis
					$venc_new = $start ne '0000-00-00' ? date($start) + Promo($sid,1) : today() + Promo($sid,1);
				}
				$vencto = $venc_new;
			}
			$vencto_invoice = $venc_new;			
		}
		
		if ($vencto eq "0000-00-00"){
			#do nothing
		} elsif ($invmult == 1) {
			#invoices multiplas	
			$vencto_invoice = $venc_new;
			$extra = date($venc_new) - date($vencto) if $verde == 1;
		} else {
			$vencto_invoice = $vencto;
		}
		
		my ($anoa,$mesa,$diaa) = split(/-/,$vencto_invoice);
		my ($ano,$mes,$dia) = split(/-/,$venc_new);
		$mult = 1 if $mult == 0;
	
		#multiplicador de valor
		my $div = Valor($tipo,1);
		my $qtv = $mult/$div;

		#multiplicador de tempo
		my $qtm = $mult/30;	
		
		my ($postec,$pgtipo) = split(" - ", Pagamento($pg,"parcelas tipo"));
		$parcelas = 1 if $pgtipo eq 'S'; #sistema parcela de forma diferente, entao na fatura vai aparecer como 1x

		#separando invoices de saldos creditados
		$verde = 0 if $saldo_pendente == 1;
		#separando invoices com propriedade 6 - fatura exclusiva
		$verde = 0 if $promo6_insert == 1;
		#separando invoices de vencimentos diferentes
		$verde = 0 if $venc_insert ne "" && $vencto_invoice ne $venc_insert;
		#separando parcelamentos diferentes
		$verde = 0 if $pgtipo_insert ne "" && $pgtipo ne $pgtipo_insert;
		#separando parcelas diferentes
		$verde = 0 if $parcelas_insert ne "" && $parcelas ne $parcelas_insert;				
		if ($verde == 1){
			#verificando a referencia da fatura
			$mest = $mesa - $postecipado;
			$year_new = $anoa;
			$year_new -= 1 if ($mest < 1);
			$monthto = $months[$mest];

			$venc_insert = $vencto_invoice;
			$pgtipo_insert = $pgtipo;
			$parcelas_insert = $parcelas;
			$promo6_insert = Promo($sid,6);
			next if scalar @sids != 0 && $promo6_insert == 1; #Pula imediatamente
			my $bsth = select_sql("SELECT * FROM `saldos` INNER JOIN `creditos` ON `saldos`.`id` = `creditos`.`balance` WHERE `saldos`.`username` = $un AND `saldos`.`invoice` IS NULL AND `saldos`.`servicos` = ?",$sid);
			$saldo_pendente = 1 if $bsth->rows > 0;
			$bsth->finish;
			
			#configurando o vencimento do servico
			my ($repetir) = split(" - ", Pagamento($pid,"repetir"));
			if ($vencto ne "0000-00-00" && $mult >= 30 && $repetir == 1) { #agir somente com casos ciclicos
				if ($p_tipo eq "Registro" || Promo($sid,4) == 1) {
					$venc_proximo = $venc_new;
				} elsif ( $vc > $diaa && $diaa == DiaMes(31,$mesa) ) { # Ajustado 28 e 31 dias sem cobrança de proporcional#($vc >= DiaMes(31,$mes) && $dia > DiaMes(31,$mes)) {#isso é para nao cobrar extra, desconsidera os ultimos dias
					$venc_proximo  = "$ano-$mes-".DiaMes("$vc","$mes");
				} else {
					$venc_proximo = DiaProximo($vc,$venc_new);
					if ($start ne '0000-00-00') { #Exclui casos de servicos ainda nao tenham iniciado, problema cobrando com serviços não ativados.
						$extra = date($venc_proximo) - date($venc_new);
						$extra -= DiaMes(31,$mesa) if $postecipado >= 1;
					}
				}
			} elsif ($vencto eq "0000-00-00" && $mult >= 30 && $repetir == 1) {
				$venc_proximo = SomaMes($venc_new,$qtm);
				$venc_new = $venc_proximo;
				($ano,$mes,$dia)=split(/-/,$venc_proximo);
				if ($p_tipo eq "Registro" || Promo($sid,4) == 1) {
					#do nothing
				} elsif ($sth->rows > 1 && $sthw->rows != 0) {
					$venc_proximo = DiaProximo($vc, $venc_proximo);
					if ($vc<DiaMes(31,$mesa) || $diaa != DiaMes(31,$mesa)) {
						$extra = date($venc_proximo) - date($venc_new); 						
					}
				} else {
					execute_sql(qq|UPDATE `users` SET `vencimento` = "$dia" WHERE `username` = $un|);
				}
			} else {
				$venc_proximo = $venc_new;
				$venc_proximo = date($venc_new) + $mult if $vencto eq "0000-00-00";
			}
				
			my @s_desc = Promo($sid,3,$year_new);
			$desc = $s_desc[0] if grep({ $mest == $_ } split(',', $s_desc[1])) && $s_desc[2] == $year_new;
			my ($parc,$sdesc,$pdesc) = parcela($pid,$pg,$desc,0,$sid,$venc_proximo);
					
			my $refer = $ref->{'tipo'}." ".$ref->{'plataforma'}." ".$ref->{'nome'}." (".$ref->{'dominio'}.")";
			$refer = $qtv."x ".$refer if $qtv > 1;
			$coud = $parc > 0 ? "d" : "c";
			$refer = "($coud) $refer";
			$refer = substr($refer,0,57).'...' if length($refer) > 60;
			$refer.= " => ".CurrencyFormatted(abs $parc+$pdesc+$sdesc);
			$refer .= "\n(c) Forma de pagamento com desconto => ".CurrencyFormatted($pdesc) if $pdesc != 0;
													
			if ($extra >= 1 || $extra <= -1 || $extrajm != 0){
				my $unitario = diaria($pid,$desc/$mult,$sid,$venc_proximo);
				my $refer2;
				if ($extra) {
					my $parc2 = $extra*($unitario);
					$coud = $parc2 > 0 ? "d" : "c";
					$refer2 = "\n($coud) (".$extra." dias) ".$ref->{'tipo'}." ".$ref->{'plataforma'}." ".$ref->{'nome'}." (".$ref->{'dominio'}.")";
					$refer2 = substr($refer2,0,68).'..' if length($refer2) > 70;
					$refer2.= " => ".CurrencyFormatted(abs $parc2);
					$parc += $parc2;
				}
				$refer.= $refer2;
			}
			$parc += $setup if $vencto eq "0000-00-00" && Promo($sid,2) != 1;
			$vsrv += $parc;
			$coud = $setup > 0 ? "d" : "c";
			$refer .= "\n($coud) Quantia inicial => ".CurrencyFormatted(abs $setup) if ($setup != 0 && $vencto eq "0000-00-00" && Promo($sid,2) != 1);
			$refer .= "\n(c) Desconto => ".CurrencyFormatted($sdesc) if $sdesc != 0;
			$srvcs .= $ref->{'pg'}."x".$sid." - ";
			push(@sids,$sid);
			push(@refer,$refer);
			push(@srv,"$ref->{id}x$venc_proximo"."x$start"."x$vencto");
			$sm=1;
			$SIDS{$ref->{id}} = 1;
		}
	}
	$sth->finish;
	my $valor=$vsrv;
	if ($sm == 1 || $sm == 2) {
		if ($sm == 2) {
			$monthto=$months[$month_no];
			$year_new=$year;
			$venc_insert = today() + 3;
		}
		$stsal = 'SELECT * FROM `saldos` WHERE `username` = ?';
		my $ssth = select_sql($stsal,$un);
		while(my $sef = $ssth->fetchrow_hashref()) {	
			if (!$sef->{'invoice'}){
				last if $vsrv == 0;
				next if $sef->{'servicos'} && ! grep { $_ == $sef->{'servicos'} } @sids;
				next if $saldo_pendente && ! grep { $_ == $sef->{'servicos'} } @sids; #Separando faturas de credito
				$vsal += $sef->{'valor'}; #Debito é negativo, saldo é credito
				$coud = $sef->{'valor'} > 0 ? "c" : "d";
				my $referd = "($coud) Saldo: " . CurrencyFormatted(abs $sef->{valor});
				$referd .= " *".$sef->{'descricao'};
				$referd = substr($referd,0,68).'..' if length($referd) > 70;				
				my $refer = $referd if $sef->{'valor'} != 0;				  
				push(@refer,$refer) if $refer;	
				push(@sal,$sef->{'id'});
			}
		}
		$ssth->finish;
		$valor = $vsrv-$vsal; #Saldo sendo crédito concede desconto
		$valor = Round($valor);		
		my $vinv=$valor*(-1); #O valor restante se for negativo irá virar saldo, por isso deve inverter
		my $vmin = $global{'minimo'};
		#Conta
		my $conta = num(Users($un,"conta")) || $global{'cc'};
		my $tarifa = num(Users($un,"forma")) || $global{'forma'};		 
		if ($valor >= $vmin){
			push(@refer,"\n* (c) crédito (d) débito");
			$inv = execute_sql(qq|INSERT INTO `invoices` (`id`, `username`,`status`,`nome`,`data_envio`,`data_vencido`,`data_vencimento`,`data_quitado`,`envios`,`referencia`,`services`,`valor`,`valor_pago`,`imp`,`conta`,`tarifa`,`nossonumero`,`parcelas`,`parcelado`) VALUES ( NULL, $un, "P", "$monthto/$year_new", "$timemysql", "$venc_insert", "$venc_insert", NULL, 0, ?, "$srvcs", $valor, NULL, 0, $conta, $tarifa, NULL, "$parcelas_insert", "$pgtipo_insert")|,join("\n",@refer)) if $valor != 0;
			die $system->lang(66) if $valor != 0 && !$inv; 
			foreach $srv (@srv){
				my ($srvid,$vct_prox,$start,$vcto) = split(/x/,$srv);
				execute_sql(qq|UPDATE `servicos` SET `proximo` = "$vct_prox", `invoice` = "$inv" WHERE `id` = $srvid|);
			}
			foreach $sal (@sal){
				execute_sql(qq|UPDATE `saldos` SET `invoice` = $inv WHERE `id` = $sal|);
			}
		} elsif ($valor < $vmin && $sm == 1){
			$coud = $vinv > 0 ? "c " : "d ";											
			my $descr = "Convertido em saldo";
			my $refer = "($coud)". $descr ." => ".CurrencyFormatted(abs $vinv);
			push(@refer,$refer) if Round($valor) != 0;
			push(@refer,"\n* (c) crédito (d) débito");
			$inv = execute_sql(qq|INSERT INTO `invoices` (`id`, `username`,`status`,`nome`,`data_envio`,`data_vencido`,`data_vencimento`,`data_quitado`,`envios`,`referencia`,`services`,`valor`,`valor_pago`,`imp`,`conta`,`tarifa`,`nossonumero`) VALUES ( NULL, $un, "P", "$monthto/$year_new", "$timemysql", "$venc_insert", "$venc_insert", "$timemysql", 0, ?, "$srvcs", 0, 0, 0, $conta, $tarifa, NULL)|,join("\n",@refer));
			die $system->lang(66) if !$inv; 
			foreach $srv (@srv){
				my ($srvid,$vct_prox,$start,$vcto) = split(/x/,$srv);
				execute_sql(qq|UPDATE `servicos` SET `proximo` = "$vct_prox", `invoice` = $inv WHERE `id` = $srvid|);
				execute_sql(qq|UPDATE `servicos` SET `vencimento` = "$venc_insert" WHERE `id` = $srvid|) if $vcto eq "0000-00-00";
			}
			Quitar($inv, 0, $timemysql, 1);
			
			foreach $sal (@sal){
				execute_sql(qq|UPDATE `saldos` SET `invoice` = $inv WHERE `id` = $sal|);
			}						
			execute_sql(qq{INSERT INTO `saldos` VALUES (NULL,"$un","$vinv","$descr", NULL, NULL) }) if $vinv != 0;			
		}
	}

	return $inv;
}

sub parcela {
	my ($plano,$pg,$s_desc,$full,$sid,$venc_proximo) = @_;
	
	my ($mult) = split(" - ", Pagamento($pg,"intervalo"));
	my ($p_desc) = Desconto($plano,$pg) unless $full;#Desconto do plano por pagamento
	#multiplicador de valor
	$mult = 1 if $mult == 0;
	my $parc = $s_desc > 0 ? $mult * diaria($plano,$s_desc/$mult,$sid,$venc_proximo) : $mult * diaria($plano,0,$sid,$venc_proximo);   
	unless ($full || $s_desc > 0) {#se tiver desconto nao dar desconto do plano
		$parc -= abs $p_desc;
		return $parc, 0, abs $p_desc if wantarray;		
	}
	
	return $parc, $s_desc, 0 if wantarray;
	return $parc;
}

sub diaria {
	my $plano = shift;
	my $desc = shift; #deve vir dividido pelo intervalo, $desc/$mult
	my ($tipo,$valor) = split(" - ", Plano($plano,"valor_tipo valor"));
	my $div = Valor($tipo,1);
	
	my $val = $valor/$div; #valor dia 
	$val -= abs $desc;# Valor = mult*diaria - desconto, Valor/mult => Diaria com desconto = diaria - desconto/mult  
		
	return $val >= 0 ? $val : 0; #nao gerar credito com descontos
}

sub prorrogar {
	my $inv = shift;
	my $sj = shift;
	my $isuser = shift;
	
	my ($stats,$vencimento,$valor,$refer) = split(/::/,Invoice($inv,"status data_vencimento valor referencia"));
	my $dif = date($timemysql) - date($vencimento);
	my $prorrogavel = 0;
	$prorrogavel = 1 if $dif >= 0;
	
	if ($stats eq "Q" || $stats eq "D" || ($isuser == 1 && $stats eq "C") || $prorrogavel != 1) {die_nice("Impossível prorrogar este pagamento no momento");}

	my $nvalor=$valor;
	unless ($sj == 1) {
		$nvalor = $valor + Juros($valor,$dif);
		$nvalor += Multa($valor) if $refer !~ m/Vencimento da fatura prorrogado/;
	} 

	my $nvencimento = today() + 2;
	my @refer = split("\n",$refer);
	my $coud = $nvalor-$valor > 0 ? "d" : "c";
	$refer = "($coud) Vencimento da fatura prorrogado de ".FormatDate($vencimento)." para ".FormatDate($nvencimento);
	$refer .= " => ". CurrencyFormatted(abs ($nvalor-$valor)) if ($nvalor-$valor) != 0;
	$refer[-1] =~ m/crédito/ ? splice(@refer,-2,0,$refer) : push @refer, $refer;
	execute_sql(qq{UPDATE `invoices` SET `valor` = "$nvalor" , `data_vencimento` = "$nvencimento", `referencia` = ? WHERE `id` = $inv},join("\n",@refer));	
}

#~~~~~~~~~#
# Faturas #
#~~~~~~~~~#
sub Quitar {
 my ( $id, $pago, $data, $quiet ) = @_;
	$data ||= $timemysql; my $err;
 my ($new_vc) = (split("-",$data))[2];
 my	($status, $services, $dia, $user_inv, $gerada, $valor, $pagoantes) = split(/::/, Invoice($id,"status services vencimento username data_envio valor valor_pago"));
	if ($status ne "Q" && $status ne "D" && $status) {
		#$system->uid($user_inv);
		$system->invid($id);
		$system->tid($system->invoice('tarifa'));		
		if ($valor > 0 && $system->tid > 0 && $system->is_creditcard_module($system->tax('modulo'))) {
			return 'Não existe cartão ativo' unless $system->creditcard_active;
			$system->ccid($system->creditcard_active);
			eval "use " . $system->tax('modulo');
			my $creditcard = eval "new " . $system->tax('modulo'); #Deve continuar com os mesmos dados
			return 'Erro no sistema' if $creditcard->creditcard('username') != $system->uid;
			my %result = $creditcard->cc_capture;
			my $err = $creditcard->clear_error .' '. $result{'response'};
			if ($result{'authorized'} != 1) {
				return $err;
			} else {
				$pago = $result{'valor'};
				$data = $timemysql;
				return $err unless $pago > 0;
			}
		}

		if ($services) {
			foreach $serv (split(/ -\s?/,$services)) {
				my ($meses, $servico) = split(/x/, $serv);
				$system->sid($servico);
				if (split(" - ",Servico($servico,"id"))) {
					my ($vencto, $pid, $venc_new, $pgs, $servstats, $sdominio, $inicio, $desc, $pg, $sfatura) = split(/ - /,Servico($servico, "vencimento servicos proximo pagos status dominio inicio desconto pg invoice"));
					next if $sfatura && $sfatura ne $system->invid; #Caso duas faturas estejam abertas pro mesmo serviço, desconsiderar a primeira como acao pra mudar o vencimento, desbloquear etc..., caso o servico esteja sem fatura ela foi provavelmente cancelada e como nao tem nenhuma outra considerar como acao.					
					$template{'dominio'} = $sdominio;
					$template{'sid'} = $servico;
					my ($tipo, $ptipo, $palert) = split(" - ",Plano($pid,"valor_tipo tipo alert"));
					my ($inter, $postec, $pinter, $rep, $pgtipo) = split(" - ",Pagamento($pg,"intervalo parcelas pintervalo repetir tipo"));
					my $div = 30;#Valor do mes, para somames
					#Mudar vencimento ao quitar os serviços novos e sem ativos, inlcuindo o próprio serviço, exceto Registros
					my $sthp = select_sql(qq|SELECT `servicos`.`status` FROM `servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` WHERE `servicos`.`status` != "S" AND `servicos`.`status` != "F" AND `servicos`.`vencimento` != "0000-00-00" AND `planos`.`tipo` != "Registro" AND `servicos`.`username` = $user_inv|);
					my $sthprows = $sthp->rows;
					$sthp->finish;
					#Considerar os dias da promocao
					if (Promo($servico,1) > 0 && $pgs == 0) {
						$inicio = today() if $inicio eq '0000-00-00';
						#se pagar e ainda nao tiver sido ativado, ou ativado atrasado
						my $fvencto = date($inicio) + Promo($servico,1);
						($venc_new) = Prazo($servico,9999,$fvencto,1); 
					}					
					elsif ($pgs == 0 && $sthprows == 0 && $postec == 0																	
								&& $ptipo ne "Registro" #Excetuando Registro
					) {#aqui ele refaz o vencimento a contar a partir do dia que quitar
						return("Erro ao quitar! Novo vencimento inexistente.") if $venc_new eq "0000-00-00";
						$venc_new = SomaMes($data,$inter/$div); #quitando hoje mais um mês
						execute_sql(qq|UPDATE `users` SET `vencimento` = "$new_vc" WHERE `username` = $user_inv|);
					};

					if ($servstats eq "B" || $servstats eq "P" || $servstats eq "C") {
						serv_exec($servico,'at');											
						$system->logcron($system->lang(1),5,$id,1) if $status eq "C";#Considera mal uso							
					} elsif ($servstats eq "A" || $servstats eq "T" || $servstats eq "E") {
						serv_exec($servico,'nd');
					} elsif ($servstats eq "S") {
						serv_exec($servico,'cr');
					} elsif ($servstats eq "F") {
						serv_exec($servico,'rcr','','yes');
					}

					return("Erro ao quitar! Novo vencimento inexistente.") if $venc_new eq "0000-00-00";
					
					#Apagar promoção
					execute_sql(qq|DELETE FROM `promocao` WHERE `servico` = $servico AND `type` = 1|) if $pgs == 0;				
					$pgs += 1; #mais uma parcela paga
					if ($pgs >= $par && $par > 1 && $rep == 1) { #Revalidar parcelas repetitivas
						my $qtpg = $pgs * $pinter; #intervalo em dd
						$pgs = 0;
						$venc_new = SomaMes($vencto,($inter - $qtpg)/$div);
					}

					execute_sql(qq|UPDATE `servicos` SET `vencimento` = "$venc_new", `envios` = 0, `def` = 0, `invoice` = 0, `pagos` = $pgs WHERE `id` = $servico|);
					eval {	
						email ( To => "$global{'contas'}", From => "$global{'adminemail'}", Subject => ['sbj_renew',$template{'dominio'}], txt => "renew" ) if ($global{'auto_renew'} != 1 && $ptipo eq "Registro");
						email ( To => "$global{'contas'}", From => "$global{'adminemail'}", Subject => ['sbj_alertpg',$template{'dominio'}], txt => "alertplanopg" ) if ($palert == 1);
					};
				}
			}
		}
		execute_sql(qq|UPDATE `users` SET `status` = "CA" WHERE `username` = $user_inv|);
		execute_sql(qq|UPDATE `invoices` SET `status` = "Q", `valor_pago` = "$pago", `data_quitado` = "$data" WHERE `id` = $id|);
		execute_sql(qq|DELETE FROM `cron_lock` WHERE `id` = $user_inv|,"",1);		

		($template{'nome'}, $template{'endereco'}, $template{'numero'}, $template{'cidade'}, $template{'estado'}, $template{'cpf'}, $template{'cnpj'}, $template{'cep'},$template{'empresa'}, $umail, $ualert) = split("---",Users($user_inv,"name endereco numero cidade estado cpf cnpj cep empresa email alert"));
		$template{'user'} = "$global{'users_prefix'}-$user_inv";
		$template{'cpf'} = FormataCPFCNPJ($template{'cpf'});
		$template{'cnpj'} = FormataCPFCNPJ($template{'cnpj'});
		$template{'invoice'} = $id;
		$template{'v_invoice'} = CurrencyFormatted($valor);
		$template{'v_pago'} = CurrencyFormatted($pago);
		$template{'linkuser'} = "$global{'baseurl'}/admin.cgi?do=viewuser&user=$user_inv";
		$template{'linkinv'} = "$global{'baseurl'}/admin.cgi?do=viewinvoice&id=$id";
		eval {
			my $from = Sender(UserFinan => $user_inv);
			
			email ( To => "$global{'alertpg'}", From => "$global{'adminemail'}", Subject => ['sbj_payed',$id], txt => "alertpg" ) if $ualert == 1;
			email ( User => "$user_inv", To => "$umail", From => $from, Subject => ['sbj_payed',$id], txt => "alertuserpg" ) if $global{'alertuser'} == 1 && !$quiet;
		};
		if ($valor > $pago) {
			$err .= "!!!Fatura $id total >> $template{'v_invoice'}, pago >> $template{'v_pago'}";
			$err .= "<br>>$valor<>$pago<>maiorque:".($valor>$pago)." menorque:". ($valor<$pago)." igual:".($valor==$pago)." equal:".($valor eq $pago);
		}
		return $err;
	} elsif ($status eq "D" && $status) {
		execute_sql(qq|UPDATE `invoices` SET `status` = "P" WHERE `id` = $id|);
		return("Fatura $id estava cancelada, alterada para pendente, é necessário quitar novamente");
	} elsif ($status eq "Q" && $status) {				
		#Repetir acoes com servicos caso ao quitar tenha dado problema
		foreach $serv (split(/ -\s?/,$services)) {
			my ($meses, $servico) = split(/x/, $serv);
			if (split(" - ",Servico($servico,"id"))) {
				my ($servstats) = split(/ - /,Servico($servico, "status"));
				if ($servstats eq "B" || $servstats eq "P" || $servstats eq "C") {
					serv_exec($servico,'at');	
				} elsif ($servstats eq "A" || $servstats eq "T" || $servstats eq "E") {
					serv_exec($servico,'nd');
				} elsif ($servstats eq "S") {
					serv_exec($servico,'cr');
				} elsif ($servstats eq "F") {
					serv_exec($servico,'rcr','','yes');
				}
			}
		}
		#repetir avisos
		$template{'v_invoice'} = CurrencyFormatted($valor);
		$template{'v_pago'} = CurrencyFormatted($pagoantes);		
		if ($valor > $pagoantes) {
			$err .= "!!!Fatura $id total >> $template{'v_invoice'}, pago >> $template{'v_pago'}";
		}
		return $err;
	} else {
		return("Fatura nao encontrada");
	}
}

sub Confirmar {	
 my ( $id, $isuser ) = @_;
	($status, $services, $dia, $user_inv) = split(/::/, Invoice($id,"status services vencimento username"));
	if ($status eq "P" && $status) {
		if ($services) {
			foreach $serv (split(/ -\s?/,$services)) {
				my ($meses, $servico) = split(/x/, $serv);
				$system->sid($servico);
				my ($servstats, $vencimento,$sdominio,$pid,$venc_new) = split(" - ", Servico($servico,"status vencimento dominio servicos proximo"));
				next if !$servstats;
				my ($tipo, $ptipo, $palert) = split(" - ",Plano($pid,"valor_tipo tipo alert"));
				$template{'dominio'} = $sdominio;
				$template{'sid'} = $servico;				
				if ($servstats eq "B" || $servstats eq "P" || $servstats eq "C") {
					serv_exec($servico,'at') unless $ptipo eq 'Registro';
					$system->logcron($system->today(),5,$id) if $isuser == 1;#Considera bom uso			
				} elsif ($servstats eq "A" || $servstats eq "T" || $servstats eq "E") {
					serv_exec($servico,'nd') unless $ptipo eq 'Registro';
				}
				#Vai fazer essa parte somente apos confirmacao, quitar. 
				if ($isuser != 1 && $ptipo ne 'Registro') {#somente o usuario nao pode criar
					if ($servstats eq "S") {
						serv_exec($servico,'cr');
					} elsif ($servstats eq "F") {
						serv_exec($servico,'rcr','','yes');
					}
				}		
				#definindo vencimento q seria definido ao quitar
				return("Erro ao quitar! Novo vencimento inexistente.") if $venc_new eq "0000-00-00";				
				if ($vencimento eq '0000-00-00') {
					execute_sql(qq|UPDATE `servicos` SET `vencimento` = "$venc_new" WHERE `id` = $servico|) if ($isuser != 1);
					$vencimento = $venc_new;
				}
				if (date($vencimento) <= today()) {
					my $diasextras = 3;
					my ($pdate,$bdate,$rdate) = $system->exec_dates;  
					my $date = $pdate || $bdate || today();
					my $def = today() - $date + $system->service('def');
					$def = $def < $diasextras * -1 ? 0 : $def + $diasextras;
					$def = 0 if $vencimento eq "0000-00-00" && !Promo($servico,1) && !Promo($servico,5);
					execute_sql(qq|UPDATE `servicos` SET `def` = $def, `envios` = 0  WHERE `id` = $servico|);#`envios` = $diasextras,
				}
				email ( To => "$global{'contas'}", From => "$global{'adminemail'}", Subject => ['sbj_renew',$template{'dominio'}], txt => "renew" ) if ($global{'auto_renew'} != 1 && $ptipo eq "Registro" && $isuser != 1);
			}	
		}
		execute_sql(qq|UPDATE `invoices` SET `status` = "C" WHERE `id` = $id|);			
	}
	return "Fatura inexistente!" unless $status;
	return;
}
		
sub Pendente {
 my ( $id ) = @_;
	($status, $services, $dia, $user_inv) = split(/::/, Invoice($id,"status services vencimento username"));
	if ($status eq "C" && $status) {
		if ($services) {
			foreach $serv (split(/ -\s?/,$services)) {
				my ($meses, $servico) = split(/x/, $serv);
				my ($vencimento,$servstats) = split(" - ", Servico($servico,"vencimento status"));
				next if !$servstats; #check if service exists

				#falta definir dias com variaveis
				if ($vencimento ne "0000-00-00" && date($vencimento) <= today()) {
					execute_sql(qq|UPDATE `servicos` SET `def` = `def` + 3 WHERE `id` = $servico|);
				}
			}	  
		}									
		execute_sql(qq|UPDATE `invoices` SET `status` = "P" WHERE `id` = $id|);
	}
}
		
sub Cancelar {
 my ( $id ) = @_;
 my ($serv);
 my ($status, $services,$user) = split(/::/, Invoice($id,"status services username"));		
	if ($status ne "Q" && $status) {
		execute_sql(qq|UPDATE `invoices` SET `status` = "D" WHERE `id` = $id|);
		execute_sql(qq|UPDATE `saldos` SET `invoice` = NULL WHERE `invoice` = $id|);		
		if ($services) {
			foreach $serv (split(/ -\s?/,$services)) {		
				my ($pg, $servico) = split(/x/, $serv);
				next if Servico($servico,"id") eq " - ";
				execute_sql(qq|UPDATE `servicos` SET `invoice` = "0" WHERE `id` = $servico AND `invoice` = $id|) if $servico;
			}
		}
		execute_sql(qq|DELETE FROM `cron_lock` WHERE `id` = $user|,"",1);
		$system->logcronRemove(1,$user);
		$system->logcronRemove(2,$id);		
	}
}

1;
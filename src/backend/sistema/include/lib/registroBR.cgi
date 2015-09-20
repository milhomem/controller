sub vars_epp 
{
	$epp = RegistroBR::Epp->new;
	$epp->{host} = "beta.registro.br";
	$epp->{port} = "700";
	$epp->{user} = "001"; 
	$epp->{pass} = "XXXX";
	$epp->{certpass} = "";	
}

sub epp_availdomain
{  
	my $dominio = shift;
	my ($free,$reason);
 	vars_epp();

	my $link = $epp->connect();

	$link = $epp->login($link,'','pt');

	($link,$free,$reason) = $epp->domain_check($link,$dominio);

	return ('','',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($free,$reason);
}

sub epp_availcontact
{  
	my $cid = shift;
	my ($free,$reason);
 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');
	
	($link,$free,$reason) = $epp->contact_check($link,$cid);

	return ('','',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($free,$reason);
}

sub epp_availorg
{  
	my $oid = shift;
	my ($free,$cid);
 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');
	
	($link,$free,$reason) = $epp->org_check($link,$oid);

	return ('','',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($free,$reason);
}


sub epp_addcontact
{  
	my ($name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email,$pw) = @_;
 	vars_epp();

	my $link = $epp->connect();

	$link = $epp->login($link,'','pt') if $link;

	($link,$cid) = $epp->contact_create($link,$name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email,$pw) if $link;

	return ('',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($cid);
}

sub epp_adddomain
{  
	my ($domain,$cnpj,$renew,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,
			 $ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6) = @_;

 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');

	($link,$ticket) = $epp->domain_create($link,$domain,$cnpj,$renew,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,$ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6);

	return ('',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($ticket);
}

sub epp_addorg
{  
	my ($cnpj,$cid,$resp,$name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email,$pw) = @_;

	my $oid;
 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');
	
	($link,$oid) = $epp->org_create($link,$cnpj,$cid,$resp,$name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email,$pw);

	return ('',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($oid);
}

sub epp_poll
{
	my ($opt,$id) = @_;

 	vars_epp();
	
	my ($msgid,$msg);

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');

	($link,$msgid,$msg) = $epp->poll($link,$opt,$id);

	return ('','',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($msgid,$msg);
}

sub epp_updatedom
{
	my ($domain,$renew,$tech,$admin,$bill,$stats,$s_desc,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,
			$ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6,
			$tech_r,$admin_r,$bill_r,$stats_r,$s_desc_r,$ns1_r,$ip1v4_r,$ip1v6_r,$ns2_r,$ip2v4_r,$ip2v6_r,
			$ns3_r,$ip3v4_r,$ip3v6_r,$ns4_r,$ip4v4_r,$ip4v6_r,$ns5_r,$ip5v4_r,$ip5v6_r) = @_;

 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');
	my $res;

	($link,$res) = $epp->domain_update($link,$domain,'',$renew,$tech,$admin,$bill,$stats,$s_desc,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,
			$ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6,
			$tech_r,$admin_r,$bill_r,$stats_r,$s_desc_r,$ns1_r,$ip1v4_r,$ip1v6_r,$ns2_r,$ip2v4_r,$ip2v6_r,
			$ns3_r,$ip3v4_r,$ip3v6_r,$ns4_r,$ip4v4_r,$ip4v6_r,$ns5_r,$ip5v4_r,$ip5v6_r);

	return ('',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return $res;
}

sub epp_updateorg
{
	my ($oid,$cid,$cidr,$resp,$name,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email) = @_;

 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');
	my $res;

	($link,$res) = $epp->org_update($link,$oid,$cid,$cidr,$resp,$addr,$addrn,$addrc,$city,$sp,$pc,$cc,$voice,$voicer,$email);

	return ('',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return $res;
}

sub epp_infoticket
{
	my ($domain,$ticket) = @_;

	my ($exp);
 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');

	($link,$exp,) = $epp->domain_info($link,$domain,$ticket);

	return ('','',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($exp);
}

sub epp_updateticket
{
	my ($domain,$ticket,$renew,$tech,$admin,$bill,$stats,$s_desc,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,
			$ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6,
			$tech_r,$admin_r,$bill_r,$stats_r,$s_desc_r,$ns1_r,$ip1v4_r,$ip1v6_r,$ns2_r,$ip2v4_r,$ip2v6_r,
			$ns3_r,$ip3v4_r,$ip3v6_r,$ns4_r,$ip4v4_r,$ip4v6_r,$ns5_r,$ip5v4_r,$ip5v6_r) = @_;

 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');

	($link) = $epp->domain_update($link,$domain,$ticket,$renew,$tech,$admin,$bill,$stats,$s_desc,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,
			$ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6,
			$tech_r,$admin_r,$bill_r,$stats_r,$s_desc_r,$ns1_r,$ip1v4_r,$ip1v6_r,$ns2_r,$ip2v4_r,$ip2v6_r,
			$ns3_r,$ip3v4_r,$ip3v6_r,$ns4_r,$ip4v4_r,$ip4v6_r,$ns5_r,$ip5v4_r,$ip5v6_r);

	return ('',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return 1;
}

sub epp_infodom 
{
	my ($domain,$ticket) = @_;

	my ($response,$xml,$ext);
 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');

	($link,$xml,$ext) = $epp->domain_info($link,$domain,$ticket);

	return ('','',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;

	return ($xml,$ext);
}

sub epp_infocontact 
{
	my ($brid) = @_;

	my ($response,$xml);
 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');

	($link,$xml) = $epp->contact_info($link,$brid);

	return ('',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;

	return ($xml);
}

sub epp_infoorg 
{
	my ($cnpj) = @_;

	my ($response,$xml,$ext);
 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');

	($link,$xml,$ext) = $epp->org_info($link,$cnpj);

	return ('','',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;

	return ($xml,$ext);
}

sub epp_renew
{
	my ($domain,$date_exp,$qtd,$type) = shift;

	my $response;
 	vars_epp();

	my $link = $epp->connect();
	$link = $epp->login($link,'','pt');

	($link,$response) = $epp->domain_renew($link,$domain,$date_exp,$qtd,$type);

	return ('',$epp->{'ERR'}) if $epp->{'ERR'};

	$link = $epp->logout($link) if $link;
	$epp = $epp->disconnect($link) if $link;
	 
	return ($response);
}

sub homologar 
{
 	vars_epp();

	#2.1. Comandos Básicos	
	#2.1.1. Connect
	$link = $epp->connect();
	#2.1.2. login mudando senha e escolhando lang
	$lpw = '654321';
	$link = $epp->login($link,$lpw,"pt"); #login(link,newpw,lang)
	$epp->{'pass'} = $lpw;
	#2.1.3. Hello
	$link = $epp->hello($link);
	#2.1.4. Logout
	$link = $epp->logout($link);
	$epp = $epp->disconnect($link);

 	vars_epp();
	$epp->{'pass'} = $lpw;

	#2.1.5. Connect
	$link = $epp->connect();
	#2.1.6. Login
	$link = $epp->login($link,'','en');

	#2.2. Comandos de Contato
	#2.2.1. Create
	($link, $cid) = $epp->contact_create($link,'Controller contato','Rua Controller','1.500','Manaus','AM','69054-110','BR','55.111111-4000','milhomem@is4web.com.br');
	#$cid = 'JDSSI22';
	#2.2.2. Info
	($link, $resp) = $epp->contact_info($link,$cid);
	#2.2.3. Update
	($link) = $epp->contact_update($link,$cid,'','Av. Pinheiros','53','Sao Paulo','SP','04578-000','BR','55.119494-4949','milhomem@is4web.com.br');

	#2.3. Comandos de Organização
	#2.3.1. Check
	$cnpj = '05.251.945/0001-08';
	($link, $free, $reason) = $epp->org_check($link,$cnpj);
	#2.3.2. Create
	($link, $cnpj) = $epp->org_create($link,$cnpj,$cid,'Controller Power Ltda','Rua Controller','50','Rio de Janeiro','RJ','21031-720','BR','55.511111-5456','milhomem@is4web.com.br');
	#2.3.3. Info
	($link) = $epp->org_info($link,$cnpj); 

	#2.4. Comandos de Domínio
	#2.4.1. Domain Check
	$domain = 'controllerregistro14.com.br';
	($link, $free, $reason) = $epp->domain_check($link,$domain,$cnpj);	
	#2.4.2. Domain Create
	$auto_renew = 0;
	($link, $ticket,$reason) = $epp->domain_create($link,$domain,$cnpj,$auto_renew,
											"a.$domain",'200.7.95.1','2000:db8::1',
											"b.$domain",'200.7.95.1','',
											"c.controllerserver10.net",'','', 
											"d.$domain",'200.7.95.1','',
											"e.$domain",'200.7.95.1','2000:db8::1');	
	#2.4.3. Ticket Info
	#$ticket = '390'; 
	($link,$response) = $epp->domain_info($link,$domain,$ticket);
	#2.4.4. Ticket Update
	($link) = $epp->domain_update($link,$domain,$ticket,$auto_renew,
									'','','','','',
									"ns1.controllerserver.net",'','',
									"ns2.controllerserver.net",'','',
									'','','', 
									'','','',
									'','','',
									'','','','','',
									"a.$domain",'','',
									"b.$domain",'','',
									"c.controllerserver.net",'','', 
									"d.$domain",'','',
									"e.$domain",'','');	

	#2.1.4. Logout
	$link = $epp->logout($link);
	$epp = $epp->disconnect($link);

	#Pausa para o processamento offline do comando EPP Domain Create (15min)
	sleep(1800); #30 minutos

 	vars_epp();
	$epp->{'pass'} = $lpw;

	#2.1.1. Connect
	$link = $epp->connect();
	#2.1.6. Login
	$link = $epp->login($link,'','pt');
	#2.4.5. Poll Request
	($link,$msgid) = $epp->poll($link,'req','');
	#2.4.6. Poll Acknowledge
	($link) = $epp->poll($link,'ack',$msgid);
	#2.4.7. Organization Update #nao atualizou email
	($link) = $epp->org_update($link,$cnpj,$cid,'','Av. Controller','53','Manaus','AM','69054-110','BR','55.921111-5555','milhomem@is4web.com.br');
	#2.4.8. Organization Info
	($link) = $epp->org_info($link,$cnpj);
	#2.4.9. Poll Request	
	($link,$msgid) = $epp->poll($link,'req','');
	#2.4.10. Poll Acknowledge
	($link) = $epp->poll($link,'ack',$msgid);
	#2.4.11. Domain Info
	($link,$date_exp) = $epp->domain_info($link,$domain,'');
	#2.4.12. Domain Renew, Aguardando resposta com erro
	($link,$response) = $epp->domain_renew($link,$domain,$date_exp,'1','y');
	$link = $response; #devido ao erro pegando segunda posicao
	#2.4.13. Contact Create 3x
	($link, $cid1) = $epp->contact_create($link,'Marcelo Freire','Rua Controller','1.500','Manaus','AM','69054-110','BR','55.111111-4000','milhomem@is4web.com.br');
	($link, $cid2) = $epp->contact_create($link,'Marcelo Freire Contato','Rua Controller','1.500','Manaus','AM','69054-110','BR','55.111111-4000','milhomem2@is4web.com.br');
	($link, $cid3) = $epp->contact_create($link,'Marcelo Mil Contato ','Rua Controller','1.500','Manaus','AM','69054-110','BR','55.111111-4000','milhomem3@is4web.com.br');
	#$cid1 = 'MAMFR';
	#$cid2 = 'MMFCO';
	#$cid3 = 'MAMCO';
	#$cid_r = 'SNCON17';
	$cid_r = $cid; 
	#2.4.14. Domain Update - Contatos 
	($link) = $epp->domain_update($link,$domain,'','',
									$cid1,$cid2,$cid3,'','',
									'','','',
									'','','',
									'','','', 
									'','','',
									'','','', 
									$cid_r,$cid_r,$cid_r,'','',
									'','','',
									'','','',
									'','','', 
									'','','',
									'','','');	
	#2.4.15. Domain Update - Servidores de Nomes
	($link) = $epp->domain_update($link,$domain,'','',
									'','','','','',
									"ftp.controllerserver.net",'','',
									"controllerserver.net",'','',
									'','','', 
									'','','',
									'','','',
									'','','','','',
									"ns1.controllerserver.net",'','',
									"ns2.controllerserver.net",'','',
									'','','', 
									'','','',
									'','','');	
	#2.4.16. Domain Info
	($link) = $epp->domain_info($link,$domain,'');
	#2.4.17. Domain Update - Habilitar Renovação Automática
	($link) = $epp->domain_update($link,$domain,'',1);
	#2.4.18. Domain Update - Desabilitar Renovação Automática
	($link) = $epp->domain_update($link,$domain,'',0);	

	#2.1.4. Logout
	$link = $epp->logout($link);
	$link = $epp->disconnect($link);

	return $link;
}

1;
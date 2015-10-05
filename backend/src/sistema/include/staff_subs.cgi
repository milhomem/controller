$cookname = $q->cookie('user');
$cookpass = $q->cookie('cert');
$cooktzo = $q->cookie('tzo');

$sect = "staff";
$ufile = $sect.".cgi";
$system->{cookname} = $q->cookie('user');

sub check_user {	
	if ((!$cookname) || ($cookname eq "") || (!$ENV{'HTTP_USER_AGENT'}) || ($cooktzo eq "")) {
		$ignore = 1;
		section("login"); 
		exit;
	}

 my $sth = select_sql(qq|SELECT * FROM `staff` WHERE `username` = "$cookname"|);
	while(my $ref = $sth->fetchrow_hashref()) {
		$uid = $ref->{'sid'};
		$staff_id = $ref->{'id'};
		$username = $ref->{'username'};
		$password = $ref->{'password'};
		$name =  $ref->{'name'};
		$accesslevel = $ref->{'access'};
		$email = $ref->{'email'};
		$rkey = $ref->{'rkey'};
		our $plsound = $ref->{'play_sound'};
		$template{'ucname'} = $username; 
		$th = select_sql(qq|SELECT * FROM `online` WHERE `username` = "$cookname"|);
		if ($th->rows() eq 0) {
			execute_sql(qq|INSERT INTO `online` VALUES ('$username','$ENV{'HTTP_USER_AGENT'}','0', '$cooktzo')|);
		}
		$th->finish;
	}
	$sth->finish;

 my $md5  = Digest::MD5->new ;
	$md5->reset ;
 my $yday = (localtime)[7];

 my @ipa = split(/\./,$ENV{'REMOTE_ADDR'});
 my $startip = $ipa[0] . $ipa[1];
 my $certif = $cookname . "pd-$rkey" . $ENV{'HTTP_USER_AGENT'} . $startip  if   $IP_IN_COOKIE;
	$certif = $cookname . "pd-$rkey" . $ENV{'HTTP_USER_AGENT'}             if  !$IP_IN_COOKIE;
	$md5->add($certif);
 my $enc_cert = $md5->hexdigest();
	if($enc_cert eq $cookpass) {
		$loggedin = 1;
		print cookies(0,$global{'admin_timeout'}.'m','','user:'.$cookname,'cert:'.$cookpass);#mais 30 minutos
    } else {
		$ignore =1;
		section("login");
		exit;
	}

 my $current_time = time();
	execute_sql(qq|UPDATE `staffactive` SET `date` = "$current_time" WHERE `username` = "$cookname"|,"",1); 

	$sth = select_sql(qq|SELECT `id`,`nome`,`level` FROM `departments` ORDER BY `level`|);
	while(my $ref = $sth->fetchrow_hashref()) {
		if (($accesslevel =~ /(^|::)$ref->{'id'}(::|$)/) || ($accesslevel =~ /GLOB::/)) { 
		 my $th = select_sql(qq|SELECT COUNT(*) FROM `calls` WHERE `category` = ?|,$ref->{'id'});
		 my $total = $th->fetchrow_array();
			$template{'depview'} .= qq|<table width="100%" border="0" cellspacing="0" cellpadding="2">
									<tr><td width="10%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src=$global{'imgbase'}/folder.gif></font></td><td width="70%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$ref->{'nome'} - |.Level($ref->{'level'}).qq|</font></td>
									<td width="20%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">($total)</font></td></tr></table>|;
			$th->finish;
		}
	}
	$sth->finish;
}


sub section {
	our $section = "@_";
	local $has = 0;

	if ($section eq "login") {
		if (!$ignore) {
			check_user();
			section("main") if $loggedin;
		} else {
			$sth = select_sql(qq|SELECT DISTINCT(`name`) FROM `skins` WHERE name = 'default'|); #limitando skin
			while (my $ref = $sth->fetchrow_array()){
				my $s = "selected" if get_setting("skin") eq $ref;
				$template{'skins'} .= qq|<option value="$ref" $s>$ref</option>|;
			}
			$sth->finish;
						
			$template{'IP'} = $ENV{'REMOTE_ADDR'};
			$template{'redirect'} = $q->param('redirect') || $ENV{'QUERY_STRING'};
			print "Goto: staff.cgi\n";
			parse("$template{'data_tpl'}/staff/login",1);
		}
		$has = 1;
	}
	
	if ($section eq "pro_login") {
		$user = $q->param('username');
		$pass = $q->param('password');
	 my $tzo = num($q->param('TBClientOffset'));
	
		my $sth = select_sql(qq|SELECT * FROM `staff` WHERE `username` = "$user"|);
	    while(my $ref = $sth->fetchrow_hashref()) {
			$salt = $ref->{'rkey'};
			$cpass = encrypt_mm($pass);
			if ((!$user) || ($cpass ne $ref->{'password'})) {
				$error = 1;
			} else {
				$username = $ref->{'username'};
				$password = $ref->{'password'};
				$name = $ref->{'name'};
				$email = $ref->{'email'};
				$accesslevel = $ref->{'access'};
			}
		}
		$sth->finish;
	
		$error = 1 if !$username;
		die_nice("Invalid username or password <br><a href=staff.cgi?do=login>Back To Login Form </a>") if $error;
	
		if (@errors) {
			print "Content-type: text/html\n\n";
			print @errors;
			exit;
		}	 
	
		execute_sql(qq|UPDATE `stafflogin` SET `date` = "$hdtime" WHERE `username` = "$username"|,"",1);
		execute_sql(qq|UPDATE `staff` SET `lpage` = "0" WHERE `username` = "$username"|,"",1);
	
	 my $md5 = Digest::MD5->new ;
		$md5->reset ;
	
	 my $yday = (localtime)[7];
	 my @ipa = split(/\./,$ENV{'REMOTE_ADDR'});
	 my $startip = $ipa[0] . $ipa[1];
	 my $certif  =  $user . "pd-$salt" . $ENV{'HTTP_USER_AGENT'} . $startip  if  $IP_IN_COOKIE;
		$certif  =  $user . "pd-$salt" . $ENV{'HTTP_USER_AGENT'}  if  !$IP_IN_COOKIE;
	
		$md5->add($certif);
	 my $enc_cert = $md5->hexdigest();
	
	    if ($q->param('remember') eq "yes") {
			print cookies(0,'1y','','user:'.$user,'cert:'.$enc_cert,'tzo:'.$tzo);
		} else {
			print cookies(0,$global{'admin_timeout'}.'m','','user:'.$user,'cert:'.$enc_cert,'tzo:'.$tzo);
		}

		my $cgi = "staff.cgi?do=main";
		$cgi = "staff.cgi?".$q->param('redirect') if $q->param('redirect');	
	
		print header(-type => "text/html",-charset => $global{'iso'});
		print qq|<html><p>&nbsp;</p><p>&nbsp;</p><meta http-equiv="refresh" content="1;URL=$cgi"><p align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Thanks for logging in</b>, you are now being taken to the staff area.</font><br><br>
	       		<font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=main">click 
	  			here</a> if you are not automatically forwarded</font></p></html>|;
		$has = 1;
	}
	
	if ($section eq "logout") {
		execute_sql(qq|UPDATE `staffactive` SET `date` = "0" WHERE `username` = "$cookname"|,"",1); 
		execute_sql(qq|DELETE FROM `online` WHERE `username` = "$cookname" AND `agent` = ?|,$ENV{'HTTP_USER_AGENT'},1) if $cookname;
	   
		print cookies(0,'1y','','user:','cert:');
		print header(-type => "text/html",-charset => $global{'iso'});
		print qq|<html><p>&nbsp;</p><p>&nbsp;</p><meta http-equiv="refresh" content="1;URL=staff.cgi"><p align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Thanks for logging out</b></font><br><br> 					<font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi">click  					here</a> if you are not automatically forwarded</font></p></html>                         |;
		$has = 1;
	}
	
	if ($section eq "search") {
		check_user(); 
	
		$sth = select_sql(qq|SELECT `username`, `name` FROM `staff`|);
		while(my $ref = $sth->fetchrow_hashref()) {
			$template{'staff'} .= qq|<option value="staff.cgi?do=sresults&ustaff=$ref->{'username'}">$ref->{'name'}</option>|;
		} 
		$sth->finish;
	
		parse("$template{'data_tpl'}/staff/search");
	} 
	
	if ($section eq "sresults") {
		check_user(); 
	
		$select = $q->param('select');
		$query  = trim($q->param('query'));
	
		$field = "id";#default field if $select eq "id";
		$field = "username" if $select eq "Username" || $select eq "username";
		$field = "subject"	if $select eq "subject";
		$field = "url" if $select eq "domain";
		$field = "priority" if $select eq "priority";
		$field = "description" if $select eq "description";
		$field = "email" if $select eq "email";
	
		if ($ENV{'QUERY_STRING'} =~ /query/) {
			$query =  $q->param('query');
			$feld  =  $q->param('field');
		}
		
		if (!$feld) {
			$feld = $field;	
		} 
	
	 my $ustaff = $q->param('ustaff');
		if ($q->param('ustaff')) {
			$statement = qq|SELECT COUNT(*) FROM `calls` WHERE `ownership` = "$ustaff"|;
		} else {
			$statement = qq|SELECT COUNT(*) FROM `calls` WHERE `$feld` LIKE CONCAT("%",?,"%")|;
		}

		$sth = select_sql(qq|$statement|,$query);
		$count = $sth->fetchrow_array();
		$sth->finish;
		$total = $count;
		$limit = $q->param('pae') || "20";  # Results per page
	 my $pages = ($total/$limit);
		$pages = ($pages+0.5);
	 my $nume  = sprintf("%.0f",$pages);
	 my $page  = $q->param('page') || "0";
		$nume  = "1" if !$nume;
		$to    = ($limit * $page) if  $page;
		$to    = "0"              if !$page;
		
		$template{'path'} =  "staff.cgi" . '?' . $ENV{'QUERY_STRING'} . "&page=$page";
		$template{'path'} =~ s/&sort=(.*)//;
		$template{'path'} =~ s/&method=(.*)//;
	
		foreach (1..$nume) {       
		 my $nu = $_ -1;
			if ($nu eq $page) { $link = "[<b>$_</b>]"; } else { $link = "$_"; }          
		 my $string =  $ENV{'QUERY_STRING'};
			$string =~ s/&page=(.*)//g;
			$nav .= qq|<font face="verdana" size="1"><a href="staff.cgi?do=sresults&query=$query&select=$feld&page=$nu&pae=$limit">$link</a> </font>| if !$ustaff;
			$nav .= qq|<font face="verdana" size="1"><a href="staff.cgi?do=sresults&query=$query&select=$feld&page=$nu&pae=$limit&ustaff=$ustaff">$link</a> </font>| if  $ustaff;
		}
		$template{'nav'} = $nav;
	 my $show  = $limit *  $page;
		$sth = $system->select_sql(qq|SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls` WHERE `$feld` LIKE CONCAT("%",?,"%") ORDER BY `id` LIMIT $show,$limit|,$query) if !$ustaff; 
		$sth = $system->select_sql(qq|SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls` WHERE `ownership` = ? ORDER BY `id` LIMIT $show,$limit|,$ustaff) if  $ustaff;
		$number=0;
		while(my $ref = $sth->fetchrow_hashref()) {	
		 my $cat  = $ref->{'category'};
			$cat .= '::';

			$number++;
			if ($ref->{'priority'} eq 1) { $font = '#990000'; } else { $font = '#000000'; }	
			$subject = "$ref->{'subject'}"; 
			$subject = substr($subject,0,20).'..' if length($subject) > 22;
			$template{'results'} .= '<table width="100%" border="0" cellpadding="4"><tr bgcolor="#E4E7F8"> 
									<td width="5%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src="' . "$template{'imgbase'}/ticket.gif" . '"></font></td>
									<td width="4%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font> $ref->{'id'}" . '</font></td>
									<td width="24%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>$ref->{'username'}" . '</font></td><td width="29%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>" . '<a href="staff.cgi?do=ticket&cid=' . "$ref->{'id'}\">$subject" . '</a></font></td>
									<td width="11%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>$ref->{'status'}" . '</font></td>
									<td width="11%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>". ( Departments($ref->{'category'},"nome") )[0] . '</font></td>										
									<td width="24%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>$ref->{'time'}" . '</font></td></tr></table>';
		}
		$sth->finish;
	
		$template{'results'}   = qq|<font face="verdana" size="2">No results found</font>| if !$template{'results'};
		$template{'noresults'} = $total;
	
		parse("$template{'data_tpl'}/staff/search_results"); 
	}
	
	if ($section eq "user_details") {
		check_user(); 
	
		$template{'cid'}  = $q->param('cid');
		$puser = $q->param('user');
	
		if($puser) {
	
			die_nice("Este usuário não está cadastrado") if $puser eq "E-mail" || $puser eq "Unregistered";
	
			$sth = select_sql(qq|SELECT * FROM `users` WHERE `username` = ?|,$puser);
			while(my $ref = $sth->fetchrow_hashref()) {	
				$template{'username'} 	=   $ref->{'username'};
				$template{'name'} 		=   $ref->{'name'};
				$template{'email'}		=	$ref->{'email'};
				$template{'cpf'}	=	FormataCPFCNPJ($ref->{'cpf'});
				$template{'cnpj'}	=	FormataCPFCNPJ($ref->{'cnpj'});
				$template{'empresa'}	=	$ref->{'empresa'};
				$template{'endereco'}	=	$ref->{'endereco'};
				$template{'numero'}	= num($ref->{'numero'}) || "s/n" ;		
				$template{'cidade'}		=	unhtml($ref->{'cidade'});
				$template{'estado'}		=	$ref->{'estado'};
				$template{'cc'}	= Country($ref->{'cc'},"nome");
				$template{'cep'}		=	Cep($ref->{'cep'});
				$template{'telefone'}	=	Telefone($ref->{'telefone'});	
				$template{'level'}		=	Level($ref->{'level'});
				$template{'status'}		=	UStatus($ref->{'status'});	  
			}
			if ($sth->rows eq 0) {
				$response              =  "Nenhum usuário com o id $puser foi encontrado no sistema";
				$template{'response'}  =  $response;
				parse("$template{'data_tpl'}/staff/general");
			} else {
				parse("$template{'data_tpl'}/staff/userview"); 
			}
			$sth->finish;
		} else {
			$template{'do'} = "user_details";
			parse("$template{'data_tpl'}/staff/user"); 
		}
	}
	
	if ($section eq "service_details") {
		check_user(); 
	
		$pservice = $q->param('service');
		if($pservice) {
			$sth = select_sql(qq|SELECT `servicos`.*,`planos`.*,`users`.`username`,`users`.`email`,`users`.`name` FROM `servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` INNER JOIN `users` ON `servicos`.`username`=`users`.`username` WHERE `servicos`.`id` = ?|,$pservice);
			while(my $ref = $sth->fetchrow_hashref()) {	
				$template{'id'} 		=   $ref->{'id'};
				$template{'cliente'} 	=   $ref->{'username'};
				$template{'nome'}		=	$ref->{'name'};
				$template{'mail'}		=	$ref->{'email'};
				$template{'dominio'}	=	$ref->{'dominio'};
				$template{'servidor'}	=	Servidor($ref->{'servidor'},"nome");
				$template{'tipo'}		=	$ref->{'tipo'};
				$template{'plataforma'}	=	$ref->{'plataforma'};
				$template{'plano'}		=	$ref->{'nome'};
				$template{'pdescr'}		=	$ref->{'descricao'} || "-";
				@dados = split("::",$ref->{'dados'});
				foreach $dados(@dados){
					($nome,$dado) = split(" : ",$dados);
					push(@nome,$nome);
					push(@dado,$dado);
				}
				$ct=0;
				foreach $nome(@nome){
					$template{'descr'} .= qq|<tr valign="middle"><td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">$nome:</font></td>
					<td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">$dado[$ct]</font></td></tr>|;
					$ct++
				}
				$template{'status'}		=	Status($ref->{'status'});
				$template{'color'}		=	ColSt($ref->{'status'});
			}
			if ($sth->rows eq 0) {
				$response              =  "Nenhum serviço com o id $pservice foi encontrado no sistema";
				$template{'response'}  =  $response;
				parse("$template{'data_tpl'}/staff/general");
			} else {
				parse("$template{'data_tpl'}/staff/serviceview"); 
			}
			$sth->finish;
		} else {
			parse("$template{'data_tpl'}/staff/service"); 
		}
	}

	if ($section eq "navigator") {
		check_user();
		my $tpl;
		my $us;
		
		$tpl = qq|<table width="95%" border="0" cellspacing="1" cellpadding="5" align="center"><tr>
				<td width="10%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="admin.cgi?do=invoices&orderby=servicos&status=$status&ord=$ord">ID</a></font></td>
				<td width="20%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="admin.cgi?do=invoices&orderby=nome&status=$status&ord=$ord">Nome</a></font></td>
				<td width="30%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="admin.cgi?do=invoices&orderby=plataforma&status=$status&ord=$ord">Host</a></font></td>
				<td width="20%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="admin.cgi?do=invoices&orderby=setup&status=$status&ord=$ord">OS</a></font></td>
				<td width="20%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Acesso</font></td>
				</tr></table>|;

		$sth = select_sql(qq|SELECT * FROM `servidores` WHERE (`username` IS NOT NULL AND `username` != '') AND (`key` IS NOT NULL AND `key` != '') ORDER BY `id`|);
		while(my $ref = $sth->fetchrow_hashref()) {	
			next if $ref->{'id'} eq 1;			
			next if $ref->{'id'} eq 1;
			$i++;
			if ($i eq 2) {
				$bgcol = '#F5F5F5';
				$i = 0;
			} else {
				$bgcol = '#F0F0F0';
			}
			$tpl .= qq|
						<table width="95%" border="0" cellspacing="1" cellpadding="5" align="center"><tr bgcolor="$bgcol">
						<td width="10%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$ref->{'id'}</font></td>
						<td width="20%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$ref->{'nome'}</font></td>
						<td width="30%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$ref->{'host'}</font></td>
						<td width="20%" align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">|.OS($ref->{'os'}).qq|</font></td>			
						<td width"20%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="navigator.cgi?server_ctrl=$ref->{'id'}" target="_blank">Acessar Painel</a></font></td>
						</table>
						|;
		}
		$sth->finish;

		$template{'response'} = $tpl;
		
		parse("$template{'data_tpl'}/staff/general");
	}
	
	if ($section eq "lookupservice") {
		check_user(); 
	
		my $field   =   $q->param('select');
		my $query   =   $q->param('query');
		$query =~ s/^www\.// if $field eq "dominio";
		my $table = "`servicos` INNER JOIN `users` ON `servicos`.`username`=`users`.`username`";
		my $results = "id::username::dominio::email";
		my $order = "";
		my @result = Search($table,$results,$field,$query,$order);		
	
		$user = "<div align=left><font face=Verdana size=2><b>SERVICE LOOKUP</b></font><br><br></div>";
	
		$user .= qq|<table width=500 border="1" cellspacing="0" cellpadding="0" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">|;
	
		foreach (@result) {
			my ($s,$un,$d,$em) = split(/::/,$_);
			$user .= qq|<tr><td align="center" width="15%" height="25"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=service_details&service=$s">$s</a></font></td>
						<td align="center" width="15%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=user_details&user=$un">$un</a></font></td>
						<td align="center" width="35%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$d</font></td>
						<td align="center" width="45%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$em</font></td>
						</tr>|;
		}
		$user .= "</table>";
		if (scalar @result == 0) { $user  = '<br><div align="center"><font face="Verdana" size="2">Nenhum serviço foi encontrado</font></div>'; } 

		$template{'response'} = $user;
	
	    parse("$template{'data_tpl'}/staff/general");
	}
	
	if ($section eq "profile") {
		$goto = $q->param('goto');
	
		if (! $goto) { 
			check_user();
	
			$sth = select_sql(qq|SELECT * FROM `staff` WHERE `username` = "$cookname" AND `admin` = 1|);
			while(my $ref = $sth->fetchrow_hashref()) {
				$sig = $ref->{'signature'};
				$assigned = $ref->{'access'};
				$template{'snd'} = "checked" if  $ref->{'play_sound'};
				$template{'snd'} = ""        if !$ref->{'play_sound'};
				$template{'ncheck'} = "checked" if  $ref->{'notify'};
				$template{'ncheck'} = ""        if !$ref->{'notify'};
				$sid = $ref->{'id'};
				$template{'name'} = $ref->{'name'};
				$template{'email'} = $ref->{'email'};
				$template{'sig'} = $ref->{'signature'};
			}
		
			$sth = select_sql(qq|SELECT * FROM `preans` WHERE `author` = "$sid"|); 
			while(my $ref = $sth->fetchrow_hashref()) {
				$ddmenu .= ' <option value="?do=profile&goto=editpre&value=' . "$ref->{'id'}" . '">' . "$ref->{'subject'}" . '</option>';
			}
			
			$template{'preans'}   = $ddmenu;
			$template{'sig'}      = $sig;
	
			parse("$template{'data_tpl'}/staff/profile");
		}
		
		if ($goto eq "updateprofile") {
			check_user();
	
			$name  = $q->param('name');
			$email = $q->param('email');
			$pass1 = $q->param('pass1');
			$pass2 = $q->param('pass2');
			$notify = $q->param('notify');
			$sound = ($q->param('sound') eq "yes") ? 1 : 0;
			if ($notify eq "yes") { $notif = 1; } else { $notif = 0; }
			if (!$name) {
				$error = "You have not entered your name";
				push (@errors, $error);
			} elsif (!$email) {
				$error = "Please enter your email address";
				push(@errors,$error);
			} elsif ($pass1 ne $pass2) {
				$error = "The passwords specified do not match";
				push(@errors,$error);
			}
			if (@errors) {
				print $q->header(-type => "text/html",-charset => $system->setting('iso'));
				print @errors;
				exit;	
			}
			$cpass = encrypt_mm($pass1);
			$sig = $q->param('sig');
			$sth = select_sql(qq|SELECT * FROM `staff` WHERE `username` = "$cookname"|);
			while(my $ref = $sth->fetchrow_hashref()) {
				if ($ref->{'password'} ne $cpass) {
					if ($pass1 && $pass2) {
						if ($pass1 ne $pass2) {
							$error = "Error, Passwords entered do not match";
							push (@errors, $error);
						} else {
							$statement = qq|UPDATE `staff` SET `play_sound` = "$sound", `name` = "$name", `email` = "$email", `password` = "$cpass", `rkey` = "$salt", `notify` = "$notif", `signature` = "$sig" WHERE `username` = "$cookname"|; 
						}
					} else {
						$statement = qq|UPDATE `staff` SET `play_sound` = "$sound", `name` = "$name", `email` = "$email", `notify` = "$notif", `signature` = "$sig" WHERE `username` = "$cookname"|; 
					}
				}
			}
			$sth->finish;
			execute_sql(qq|$statement|);
	
			print $q->header(-type => "text/html");
			print qq|<html><p>&nbsp;</p><p>&nbsp;</p><meta http-equiv="refresh" content="1;URL=staff.cgi?do=profile"><p align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Thank you, profile updated</b></font><br><br>
		       		<font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=profile">click 
		  			here</a> if you are not automatically forwarded</font></p></html>|;
			$has = 1;
		}
		
		if ($goto eq "add_pre") {
			check_user();
			parse("$template{'data_tpl'}/staff/predef");
		}
	
		if ($goto eq "addpredef") {
			check_user();
			if ((defined $q->param('subject')) && (defined $q->param('content'))) {
				$subject  =  SpecialChars($q->param('subject'));
				$comments = SpecialChars($q->param('content'));
				$subject  =~ s/\"/\\"/g;
				my ($sid) = split("---",Staffs($cookname,"id"));			
				execute_sql(qq|INSERT INTO `preans` VALUES (NULL, "$sid", "$subject", "$comments", "$hdtime")|);
			} else {
				print 'Please enter all the fields';
				exit;
			}
			
			$response = "<font face=Verdana size=2>Thank you.<br><br> Your answer template has been added.</font>";
			$template{'response'}   = $response;
	
			parse("$template{'data_tpl'}/staff/general");
		}
	
		if ($goto eq "editpre") {
			check_user();
	
			$id = $q->param('value');
			$sth = select_sql(qq|SELECT * FROM `preans` WHERE `id` = $id|);
			while(my $ref = $sth->fetchrow_hashref()) {
				$subject = $ref->{'subject'};
				$content = $ref->{'text'};
			}
			$sth->finish;
			$template{'id'}      = $id;
			$template{'subject'} = $subject;
			$template{'content'} = $content;
	
			parse("$template{'data_tpl'}/staff/editpre");
		}
	
		if ($goto eq "del_pre") {
			check_user();
			$id = $q->param('id'); 
			execute_sql(qq|DELETE FROM `preans` WHERE `id` = $id|);
	
			print $q->header(-type => "text/html");
	        print qq|<html><p>&nbsp;</p><p>&nbsp;</p><meta http-equiv="refresh" content="1;URL=staff.cgi?do=profile"><p align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Thank you, response deleted</b></font><br><br>
	       			<font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=profile">click 
	  				here</a> if you are not automatically forwarded</font></p></html>|;
	  		$has = 1;		
		}
	
		if ($goto eq "editsave") {
			check_user();
	
			$id      = $q->param('id');
			$subject = $q->param('subject');
			$content = $q->param('content');
			$subject =~ s/\"/\\"/g;
			$content =~ s/\"/\\"/g;
			execute_sql(qq|UPDATE `preans` SET `subject` = "$subject", `text` = "$content" WHERE `id` = "$id"|);
			$response = "<font face=Verdana size=2>Thank you.<br><br> Your answer template has been saved.</font>";
			$template{'response'} = $response;
	
			parse("$template{'data_tpl'}/staff/general");
		}
	}
	
	if ($section eq "view_review") {
		check_user(); 
	
	 my $nid = $q->param('nid');
		if ($nid) {
			$sth = select_sql(qq|SELECT `id`,`author`,`comment`,`call` FROM `notes` WHERE `id` = $nid|);
			while(my $ref = $sth->fetchrow_hashref()) {    
				$author = $ref->{'author'};
				$template{'comment'} = my2html($ref->{'comment'});
				$template{'id'} = $ref->{'id'};
				$template{'cid'} = $ref->{'call'};
			}
			$sth->finish;
			$sth = select_sql(qq|SELECT `name` FROM `staff` WHERE `id` = "$author"|);
			while(my $ref = $sth->fetchrow_hashref()) {
				$template{'author'} = $ref->{'name'};
			}
			$sth->finish;
			$sth = select_sql(qq|SELECT * FROM `reviews` WHERE `nid` = $nid|);
			while(my $ref = $sth->fetchrow_hashref()) {   
				$template{'rating'} = $ref->{'rating'};
				$template{'user'} = $ref->{'owner'};
				$template{'review'} = my2html($ref->{'comments'}) || "No Review Given";
			}
			$sth->finish;
		}
	
		parse("$template{'data_tpl'}/staff/view_review");
	}
	
	if ($section eq "lookup") {
		check_user(); 
	
		$template{'action'} = $q->param('area');
		$template{'action'} = "user" if !$template{'action'};
	
		$template{'options'} = qq|<option value="servicos`.`dominio">Dom&iacute;nio</option>
								<option value="users`.`name">Nome</option>
								<option value="users`.`empresa">Empresa</option>
								<option value="users`.`email">Email</option>|;
	
		$template{'value'} = "log";
	
		parse("$template{'data_tpl'}/staff/lookup");
	}
	
	if ($section eq "lookupresults") {
		check_user(); 
	
		$field = $q->param('select');
		$query = $q->param('query');
		$return = $q->param('return');
		$act = $q->param('act');
	
		if ($return eq "log"){
			$dot = "log";
		} else {
			$dot = "user_details";
		}
	
		$user =  qq|<table width=500 border="1" cellspacing="0" cellpadding="0" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">|;
	
		if ($act eq "serv"){
			@usage = ("`servicos` RIGHT JOIN `users` ON `servicos`.`username`=`users`.`username`","username::dominio::email::id","$field","$query","$field");
		} elsif ($act eq "mail"){
			@usage = ("`users` RIGHT JOIN `servicos` ON `servicos`.`username`=`users`.`username`","username::name::email","$field","$query","users`.`email","$field");
		} else {
			@usage = ("`servicos` RIGHT JOIN `users` ON `servicos`.`username`=`users`.`username`","username::name::email","$field","$query","users`.`username","$field");
		}
	
		foreach $founds (Search(@usage)){
			($un,$n,$e,$f) = split ("::",$founds);
			$do = $dot . "&user=$un" if $act eq "user";
			$do = $dot . "&user=$un&service=$f" if $act eq "serv";
			$do = $dot . "&email=$e" if $act eq "mail";
			$user .= qq|<tr><td align="center" width="15%" height="25"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=service_details&service=$f">$f</a></font></td>
						<td align="center" width="15%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=user_details&user=$un">$un</a></font></td>
						<td align="center" width="35%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$n</font></td>
						<td align="center" width="45%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$e</font></td>
						</tr>|;
						
		}
	
		$user .= "</table>";
		$template{'response'} = $user;
	
	    parse("$template{'data_tpl'}/staff/general");
	}
	
	if ($section eq "notice") {
		check_user(); 
	 
		$notic     =  $q->param('id');
		$sth = select_sql(qq|SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `announce` WHERE `staff` = "1" AND `id` = $notic|);
		while(my $ref = $sth->fetchrow_hashref()) {	
			$notice .= '<table width="100%" border="0" cellspacing="1" cellpadding="0"><tr><td width="24%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Author:</font></td><td width="76%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">' . "$ref->{'author'}" . '</font></td>
				</tr><tr><td width="24%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Published:</font></td><td width="76%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">' . "$ref->{'time'}" . '</font></td></tr><tr><td width="24%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"></font></td><td width="76%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"></font></td>
				</tr><tr><td width="24%" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Subject:</font></td><td width="76%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>' . "$ref->{'subject'}" . '</b><br><br></font></td></tr><tr><td width="24%" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Announcement:</font></td><td width="76%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">' . "$ref->{'message'}" . '</font></td></tr></table>';
			}
	 	$sth->finish;
		$template{'announcement'}  =  $notice;
	
		parse("$template{'data_tpl'}/staff/announcement");
	}
	
	if ($section eq "myperformance") {
		check_user(); 
	
		$sth = select_sql(qq|SELECT COUNT(*) FROM `calls` WHERE `status` = "F" AND `closedby` = "$cookname"|);
	 my $closed = $sth->fetchrow_array();
		$sth = select_sql('SELECT COUNT(*) FROM `calls` WHERE `status` = "F"' );
	 my $total = $sth->fetchrow_array();
		$sth = select_sql('SELECT COUNT(*) FROM `calls`');
	 my $count = $sth->fetchrow_array();
		$sth = select_sql(qq|SELECT SUM(`rating`) FROM `reviews` WHERE `staff` = "$staff_id"|);
		$total_rating = $sth->fetchrow_array(); 
		$sth->finish;
		if ($total_rating) {
			$sth = select_sql(qq|SELECT `rating` FROM `reviews` WHERE `staff` = "$staff_id"|);
		 my $total_reviews = $sth->rows(); 
			$sth->finish;
			$template{'total_reviews'} = $total_reviews || "0";
		 my $crating  = $total_rating/$total_reviews;
			$crating  = sprintf("%.0f", $crating);
			$sc       = $crating;
			$sc       = $sc+1;
			for(1..$crating) {
				$template{'rating'} .= qq|<img src=$global{'imgbase'}/star_filled.gif>|;   
			}
			for ($sc..5) {
				$template{'rating'} .= qq|<img src=$global{'imgbase'}/star_empty.gif>|;   
			}
		} else {
	
			$template{'rating'} = "No Rating"; $template{'total_reviews'} = "0";
		}
		if ($closed > 0) {
			$per  = ($closed/$total)*100;	
			$perc = sprintf("%.2f",$per);
		} else {
			$perc = "0"
		} 
		$sth = select_sql(qq|SELECT `responsetime` FROM `staff` WHERE `username` = "$cookname"|);
		while(my $ref = $sth->fetchrow_hashref()) {	
			$tsec = $ref->{'responsetime'};
		}
		$sth = select_sql(qq|SELECT * FROM `reviews` WHERE `staff` = "$staff_id" ORDER BY `id` DESC LIMIT 5|);
		while(my $ref = $sth->fetchrow_hashref()) { 
			$template{'comments'} .= qq|<tr><td width="36%" valign="top"><B>$ref->{'owner'}</b><br>
			Rating: $ref->{'rating'}/5</td><td width="64%" valign="top">|.my2html($ref->{'comments'}).qq|</td></tr>|;
		}	
		$sth->finish;
	
		$template{'comments'} = qq|<tr><td>No ratings found</td></tr>| if !$template{'comments'};
		if ($closed > 0){
			$sec     =  ($tsec/$closed);	
			$days    =  int($sec/(24*60*60));
			$hours   =  ($sec/(60*60))%24;
			$mins    =  ($sec/60)%60;
			$secs    =  $sec%60;
			$restime = "$days d(s) $hours hr(s) $mins min(s) $secs seconds";
		} else {
			$restime = "No calls closed";
		}
	
		$template{'avgresp'}  = $restime;
		$template{'perc'}     = $perc;
		$template{'closed'}   = $closed;
	
		parse("$template{'data_tpl'}/staff/perf");
	}
	
	if ($section eq "events") {
		check_user();
	
		if ($q->param(doit) eq "ne"){
			$template{'events'} = qq|ADICIONAR EVENTO<br><br>Mensagem:<br><textarea name="descricao" cols="30"></textarea><input type="hidden" name="do" value="eventsnew"><br><br><input type="submit" name="Submit" value="Criar">|;
		} else {
			$sth = select_sql(qq|SELECT * FROM `events` ORDER BY `id` DESC|);
			while(my $ref = $sth->fetchrow_hashref()){
				$template{'events'} .= "<a href=?do=eventsv&id=" . $ref->{'id'} . ">" . $ref->{'id'} . ".</a> " . $ref->{'message'} . "<br>";
			}
		    $sth->finish;
	
			$template{'events'} .= qq|<br><br><a href=staff.cgi?do=events&doit=ne>Informar novo evento</a>|;
		}
	
		parse("$template{'data_tpl'}/staff/events");
	} 
	
	if ($section eq "eventsv") {
		check_user();
	
		$id = $q->param(id);
	
		$sth = select_sql(qq|SELECT * FROM `events` WHERE `id` = $id|);
		while(my $ref = $sth->fetchrow_hashref()){
			$template{'desc'} = qq|Descri&ccedil;&atilde;o</font>:<br><textarea name="descricao" cols="30" rows="7">$ref->{'message'}</textarea>|;
		}
	    $sth->finish;
		$template{'id'} = $id;
	
		parse("$template{'data_tpl'}/staff/events_view");
	}
	
	if ($section eq "eventsnew") {
		check_user();
		
		my $tos;
		my $descricao = SpecialChars($q->param('descricao'));
		my $id = execute_sql(qq|INSERT INTO `events` VALUES (NULL,?)|,$descricao);
		
		my $sth = select_sql(qq|SELECT `email` FROM `staff`|); 
		while(my $ref = $sth->fetchrow_hashref()) {
			$tos .= $ref->{'email'}.",";
		}
		$sth->finish;
		$tos =~ s/\,$//;
		
		$template{'id'} = $id;
		$template{'descricao'} = $q->param('descricao');
				
		my $ok = email ( To => "$tos", From => "$global{'adminemail'}", Subject => [ 'sbj_new_event',$cookname], txt => "newevent" );	

		print $q->header(-type => "text/html");
		print qq|<html><p>&nbsp;</p><p>&nbsp;</p><meta http-equiv="refresh" content="1;URL=staff.cgi?do=events"><p align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Eventos Alterado</b></font><br><br>
	       		<font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=events">click 
	  			here</a> if you are not automatically forwarded</font></p></html>|;
		$has = 1;
	}
	
	if ($section eq "eventsave") {
		check_user();
	
		$message = SpecialChars($q->param('descricao'));
		$id = $q->param('id');
	
		execute_sql(qq|UPDATE `events` SET `message` = "$message"  WHERE `id` = "$id"|);
	
		print $q->header(-type => "text/html");
		print qq|<html><p>&nbsp;</p><p>&nbsp;</p><meta http-equiv="refresh" content="1;URL=staff.cgi?do=events"><p align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Eventos Alterado</b></font><br><br>
	       		<font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=events">click 
	  			here</a> if you are not automatically forwarded</font></p></html>|;
		$has = 1;
	}
	
	if ($section eq "eventsrem") {
		check_user();
	
		$id = $q->param(id);
	
		execute_sql(qq|DELETE FROM `events` WHERE `id` = "$id"|);
	
		print $q->header(-type => "text/html");
		print qq|<html><p>&nbsp;</p><p>&nbsp;</p><meta http-equiv="refresh" content="1;URL=staff.cgi?do=events"><p align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Eventos Alterado</b></font><br><br>
	       		<font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=events">click 
	  			here</a> if you are not automatically forwarded</font></p></html>|;
		$has = 1;
	}

#~~~~~~~~~#
# Tickets #
#~~~~~~~~~#
	tickets($section) if !$has;
	
	section("login") if !$has;
}

1;

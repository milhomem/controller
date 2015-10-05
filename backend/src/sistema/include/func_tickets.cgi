use Controller::Notifier;
#Rotinas de tratamento de dados
#Área: Pedidos

sub ticket_new {
	my ($method,$owner,$user,$email,$depname,$subject,$text,$notes,$visible,$servico,$nivel,$author) = @_;
	
	#owner 0 - user 1 - staff 2 - system 3 - staff action
	#visible 1 - visible 0 - hidden 
	my $curtime = time();
    my @chars =   ("A" .. "Z", "a" .. "z", 0 .. 9);          
	my $key   =  $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)];          			
	($email) = Users($user,"email") unless $email;
	
	my ($dep) = EscolheDep($user,$servico,$depname);
	my $cid = $system->execute_sql(344, "A", $user, "$email", "$nivel", $servico, "$dep", "$subject", "$text", "$hdtime", undef, undef, "$method", $curtime, $curtime, "1", "0", "0", "0");
	$system->execute_sql(382, $owner, $visible, "A", $cid, "$author", "$hdtime", "$key", "$notes", $ENV{'REMOTE_ADDR'}) if $cid && $notes;
	
	return $cid;
}

sub tickets {
	my $section = "@_";
	
	inicio:
	if ($section eq "own") {
		check_user(); 
	
		$callid = num($q->param('cid'));
		if ($accesslevel !~ /GLOB::/) {
			$sth = select_sql(qq|SELECT `category` FROM `calls` WHERE `id` = $callid|); 
			while(my $ref = $sth->fetchrow_hashref()) {
				if ($accesslevel !~ /(^|::)$ref->{'category'}(::|$)/) {
					print "You do not have permission to view this call.";
					exit;
				}
			}
		}
		$response = "<div align=\"left\"><b>Claim ownership of request ID $callid?</b><br>Claiming ownership of this call will alert other techs that this call is being worked on by yourself.<br><br><a href=\"?do=claim&cid=$callid\">Claim Ownership</a></div>";
		$template{'response'} = $response;
		parse("$template{'data_tpl'}/$sect/general");
	}
	
	if ($section eq "claim") {
	
		check_user(); 
		$id = $cid  = $q->param('cid');
	
		execute_sql(qq|UPDATE `calls` SET `ownership` = "$staff_id" WHERE `id` = "$cid"|); 
		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, $cid, "$hdtime", "Staff: $cookname", "$cookname Claimed Ownership" )|,'',1);
	
		#$section = "ticket";
		#goto inicio;
		print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n";
		exit;
	}
	
	if ($section eq "update_list_calls") {
	
		check_user();
	 my $status = $q->param('status');
	 my $action = $q->param('action_call');
	
		if ($action eq "delete") { 
			@checkbx = $q->param('ticket_check');  
			for ( @checkbx ) {
				die_nice("The administrator has removed staff deletion access") if $global{'sdelete'} == 0;
				execute_sql(qq|DELETE FROM `calls` WHERE id = "$_"|);          
				$sth = select_sql(qq|SELECT * FROM `notes` WHERE `call` = ?|,$_); 
				while(my $ref = $sth->fetchrow_hashref()) {
					execute_sql(qq|DELETE FROM `files` WHERE `nid` = "$ref->{'id'}"|); 
				}
				execute_sql(qq|DELETE FROM `notes` WHERE `call` = "$_"|);
				execute_sql(qq|DELETE FROM `files` WHERE `cid` = "$_"|);                    
			}
	
			section("main");
			exit;
		} 
	
		if ($action eq "own") {
			@checkbx = $q->param('ticket_check');  
			for ( @checkbx ) {
				execute_sql(qq|UPDATE `calls` SET `ownership` = "$staff_id" WHERE `id` = $_|); 
	  		 	execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, "$_", "$hdtime", "Staff: $cookname", "$cookname Claimed Ownership" )|,"",1);
			}
	
			section("main");
			exit;
		}
	
		if ($action eq "respond") { 
			@checkbx = $q->param('ticket_check');  
			for ( @checkbx ) {
				$template{'hidden'} .= qq|<input type=hidden name=ticket_check value=$_>\n|;
			}
			parse("$template{'data_tpl'}/$sect/mass_respond");
		}
		
		$has = 1;
	}
	
	if ($section eq "tickets") {
		check_user();
		
		parse("$template{'data_tpl'}/$sect/tickets");
	}
	
	if ($section eq "listticket" || $section eq "main") {
		check_user(); 

		$sth = select_sql(qq|SELECT `level`.*,`departments`.`id` AS `did` FROM `level` INNER JOIN `departments` ON `departments`.`level`=`departments`.`id` ORDER BY `level`.`id`|); 
		while(my $ref = $sth->fetchrow_hashref()) {
			$template{'empresas'} .= " <a href=\"?do=$section&level=$ref->{'id'}\">$ref->{'nome'}</a> |" if $accesslevel =~ /(^|::)$ref->{'did'}(::|$)/ || $accesslevel =~ /GLOB(::|$)/; 
		}
		$template{'empresas'} .= " <a href=\"?do=$section&level=all\">Todos</a>";
		$sth->finish;
	
		if (defined $q->param('sort')) {
			$sort = $q->param('sort');
		} else {
			$sort = "id";
		}
		if (defined $q->param('method')) { 
			if ($q->param('method') eq "asc") { 
				$method = "ASC"; 
			} else { 
				$method = "DESC"; 
			}
		} else { 
			$method = "ASC"; 
		}
	
		if (defined $q->param('timer')){
			$template{'rtime'}     =  $q->param('timer');
			$template{'t0'} = " selected" if $q->param('timer') eq "0";
			$template{'t1'} = " selected" if $q->param('timer') eq "60000";
			$template{'t2'} = " selected" if $q->param('timer') eq "180000";
			$template{'t3'} = " selected" if $q->param('timer') eq "300000";
			$template{'t4'} = " selected" if $q->param('timer') eq "900000";
			$template{'t5'} = " selected" if $q->param('timer') eq "1800000";
			$template{'rdirector'} = ' onLoad=redirTimer();'; 
			$template{'rurl'} = qq|?do=$section&timer=| . $q->param('timer') . qq|&level=|;
			$template{'rurl'} .= $q->param('level') || "all";
		} else {
			$template{'rdirector'} = ' onLoad=redirTimer();'; 
			$template{'rtime'} = 300000;
			$template{'t3'} = " selected";
		}
	
		$sth = select_sql(qq|SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `announce` WHERE `staff` = "1"|); 
		while(my $ref = $sth->fetchrow_hashref()) {	
			$notice .= '<table width="100%" border="0" cellspacing="1" cellpadding="2"><tr><td width="5%"> <div align="center"><img src="' . "$template{'imgbase'}" . '/note.gif" width="11" height="11"></div></td><td width="62%"><a href="?do=notice&id=' . "$ref->{'id'}\"><font size=\"1\" face=\"Verdana, Arial, Helvetica, sans-serif\">$ref->{'subject'}" . '</font></a></td><td width="33%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">' . "$ref->{'time'}" . '</font></td></tr></table>';
		}
		$notice  = '<font face="verdana" size="1">0 Anúncios</font>' if !$notice;

		my $pri1  = $template{'pri1'} = $global{'pri1'};
		my $pri2  = $template{'pri2'} = $global{'pri2'};
		my $pri3  = $template{'pri3'} = $global{'pri3'};
		my $pri4  = $template{'pri4'} = $global{'pri4'};
		my $pri5  = $template{'pri5'} = $global{'pri5'};
	
		$tnum  =  0;
		my $level = $template{'level'} = $q->param('level') || "all";
        $sth = select_sql(qq|SELECT `id`,`nome`,`level` FROM `departments` ORDER BY `level`|); 
		while(my $ref = $sth->fetchrow_hashref()) {
			next if ($level && $level ne $ref->{'level'} && $ref->{'level'} && $level ne "all");
			$level = $ref->{'level'} if !$level;				
			if (($accesslevel =~ /(^|::)$ref->{'id'}(::|$)/) || ($accesslevel =~ /GLOB(::|$)/)) {
				$ssth = select_sql("SELECT COUNT(*) FROM `calls` WHERE `category` = ? AND `status` != \"F\"",$ref->{'id'});
				my $queue = $ssth->fetchrow_array();
	
	            $ssth = select_sql("SELECT COUNT(*) FROM `calls` WHERE (category = ? AND status != \"F\" AND aw = \"1\")",$ref->{'id'});
				my $staff = $ssth->fetchrow_array();
	
				$ssth = select_sql("SELECT COUNT(*) FROM `calls` WHERE (category = ? AND status != \"F\" AND aw = \"0\")",$ref->{'id'});
				my $user = $ssth->fetchrow_array();
				$ssth->finish;   
	
				$template{'dep_stats'} .= qq|<tr><td bgcolor="#E8E8E8" width="50%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">
											<a href="?do=listcalls&status=A&department=$ref->{'id'}">$ref->{'nome'} - |.Level($ref->{'level'}).qq|</a></font></td><td bgcolor="#f2f2f2" width="25%"> 
											<div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$staff</font></div></td><td bgcolor="#f2f2f2" width="25%"> 
											<div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$user</font></div></td></tr>|;
				$tnum+=$queue;							
			}
		}
		$sth->finish;

		$template{'total'} = $tnum;
	
		$template{'dep_stats'} = "" if !$template{'dep_stats'};

		@types = ("",1..20);	
		foreach $type (@types){    
			if ($accesslevel =~ /GLOB::/) {  
				$statement = qq|SELECT `calls`.*,`servicos`.`servicos`,`planos`.`tipo`,`departments`.`level` FROM `calls` LEFT JOIN servicos ON `calls`.`service`=`servicos`.`id` LEFT JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` LEFT JOIN `departments` ON `departments`.`id`=`calls`.`category` WHERE (`calls`.`status` != "F" AND `calls`.`priority` = "$type")|; # if $type eq "a";
				$statement .= qq| AND (`calls`.`ownership` = "$staff_id" OR `calls`.`ownership` IS NULL)|; 
				$statement .= qq| ORDER BY FIELD(`planos`.`tipo`,'Dedicado','Revenda','Hospedagem','Registro','Adicional') ASC,`calls`.`aw` DESC,`calls`.`status`,`calls`.`active` DESC|;
			} else {
				die_nice("Você não tem acesso a esse departamento") if !$accesslevel;
				
				@access = split(/::/,$accesslevel);
				$statement = qq|SELECT `calls`.*,`servicos`.`servicos`,`planos`.`tipo`,`departments`.`level` FROM `calls` LEFT JOIN servicos ON `calls`.`service`=`servicos`.`id` LEFT JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` LEFT JOIN `departments` ON `departments`.`id`=`calls`.`category` WHERE (`calls`.`status` != "F" AND `calls`.`priority` = "$type")|; # if $type eq "a"; 
				$statement .= qq| AND (`calls`.`ownership` = "$staff_id" OR `calls`.`ownership` IS NULL) AND (|;			
				my @deps;
				foreach $dep (@access) {
					$dep         =~  s/^\s+//g;
					push @deps, "`category` = \"$dep\"";
				}
				push @deps, "`category` = \"\"";
				push @deps, "`category` IS NULL";
				$statement .= join(" OR ",@deps).qq|) ORDER BY FIELD(`planos`.`tipo`,'Dedicado','Revenda','Hospedagem','Registro','Adicional') ASC,`calls`.`aw` DESC,`calls`.`status`,`calls`.`active` DESC|; 
			}

			$sth = select_sql($statement);
			$number = 0;			
			while($ref = $sth->fetchrow_hashref()) {
				next if ($level && $ref->{'level'} && $level ne $ref->{'level'} && $level ne "all");
				$level = $ref->{'level'} if !$level;				
				$st = "(" . $ref->{'status'} . ")";
				$id  =  $ref->{'id'};
				if ($ref->{'status'} ne "F") {
					$template{'soundb'} = qq|<BGSOUND SRC=$template{'imgbase'}/chimes.wav"><EMBED SRC="$template{'imgbase'}/chimes.wav" playmode=auto visualmode=background width=0 height=3 AUTOSTART=true>| if $plsound;
					$number++;
					$font    =   '#000000'; 
					$subject = my2html($ref->{'subject'}); 
					#$subject =~  s/^\'(.*)\'$/$1/;	 
					$subject =   substr($subject,0,20).'..' if length($subject) > 22;
	
					if ($ref->{'method'} eq "cc" ) { 
						$img = "phone.gif"; 
					} elsif ($ref->{'method'} eq "em") { 
						$img = "mail.gif"; 
					} elsif ($ref->{'method'} eq "ss") { 
						$img = "new.gif"; 
					} else { 
						$img = "ticket.gif"; 
					}
					#$subject = $1 if $subject =~ /\'(\S+)\'/;
					if ($ref->{'tipo'} eq "Hospedagem") { $color = $pri1;} 
					if ($ref->{'tipo'} eq "Revenda") { $color = $pri2;} 
					if ($ref->{'tipo'} eq "Registro") { $color = $pri3;} 
					if ($ref->{'tipo'} eq "Dedicado") { $color = $pri4;} 
					if ($ref->{'tipo'} eq "Adicional") { $color = $pri5;}
					if (!$ref->{'tipo'}) { $color = "FFFFFF";}  
					if ($ref->{'aw'} eq "1") { 
						$awt = "<img src=\"$template{'imgbase'}/online.gif\">"; 
					} else { 
						$awt = "<img src=\"$template{'imgbase'}/offline.gif\">"; 
					}
					@count = split(" ",timediff(time,$ref->{'track'}));
					$count = "$count[0] $count[1]";
					@count2 = split(" ",timediff(time,$ref->{'active'}));
					$count2 = "$count2[0] $count2[1]";
					
					if ($ref->{'ownership'} eq $staff_id) { 
						$otag = "<b>"; $ctag = "</b>"; 
					} else { 
						$otag = ''; $ctag=''; 
					}
					$type = 1 if $type eq "";
					$tcall =  $type;
					$tcall .=  "_call";
					$maxY += 0;
					$minY -= 0;
					$template{$tcall} .=  display_ticket_main($ref->{'id'}, $ref->{'username'}, $ref->{'category'}, $ref->{'status'}, $type);
					$maxY += 150;
					$minY -= 150;
					$ticket{$id} = 1 if !$match;
				}
			}
			$sth->finish; 
			$tcall =  $type;
			$tcall .=  "_call";
			$template{$tcall}  =  '<font face="Verdana" size="1">Nenhum Ticket Encontrado</font>' if !$template{$tcall};
		}
	
		$current_time = time();
		$sth = select_sql(qq|SELECT * FROM `staffread` WHERE `username` = "$cookname"|);
		while(my $ref = $sth->fetchrow_hashref()) {  
			$lastactive = $ref->{'date'}; 
		}
		$sth->finish; 
		$unread     = 0;
		
		$statemente = 'SELECT `stamp` FROM `messages` WHERE `touser` = ?'; 
		$sth        =  $dbh->prepare($statemente) ;
		$sth->execute($staff_id);
		while(my $ref = $sth->fetchrow_hashref()) { 
			if ($ref->{'stamp'} > $lastactive) {
				$unread++;
			}
		}
		$sth->finish; 
	
		$sth = select_sql(qq|SELECT `message` FROM `events` ORDER BY `id` DESC LIMIT 5|);
		while(my ( $ref ) = $sth->fetchrow_array()) { 
			$template{'events'} .= "- ".substr($ref,0,125);
			$template{'events'} .= length($ref) > 125 ? "...<br>" : "<br>";
		}
		$sth->finish; 
		
		$template{'announcement'}   =   $notice;
	#	$template{'open'}           =   $owned;
	#	$template{'queue'}          =   $queue;
		$template{'user'}           =   $cookname;
	#	$template{'deplist'}        =   $depq;

		my $partial = $ajax ? 1 : 0;
		parse("$template{'data_tpl'}/$sect/ticket_main",$partial);
	}
	
	if ($section eq "listcalls"){
	
		check_user();  
		$status             =  $q->param('status');
		$type               =  $status;
		$template{'status'} =  $status;
		$department         =  $q->param('department');
	
		if ($accesslevel !~ /(^|::)$department(::|$)/ && $accesslevel !~ /GLOB(::|$)/) { die_nice("Sorry $cookname of $accesslevel, You do not appear to have access to $department") if defined $department; }
		
		if (defined $q->param('timer')) {
			$template{'rtime'}     =  $q->param('timer');
			$template{'t0'} = " selected" if $q->param('timer') == 0;
			$template{'t1'} = " selected" if $q->param('timer') == 60000;
			$template{'t2'} = " selected" if $q->param('timer') == 180000;
			$template{'t3'} = " selected" if $q->param('timer') == 300000;
			$template{'t4'} = " selected" if $q->param('timer') == 900000;
			$template{'t5'} = " selected" if $q->param('timer') == 1800000;
	
			$template{'rdirector'} = ' onLoad=redirTimer()'; 
			$template{'rurl'} = qq|?do=$section&timer=| . $q->param('timer') . qq|&level=|;
			$template{'rurl'} .= $q->param('level') || "all";

		} else { 
			$template{'rdirector'} = ""; $template{'rurl'} = "";
		}	
	 
		$sth = select_sql(qq|SELECT `id`,`nome`,`level` FROM `departments` ORDER BY `level`|); 
		while(my $ref = $sth->fetchrow_hashref()) {	 
			$template{'departments'} .= "<option value=\"?do=listcalls&status=$status&department=$ref->{'id'}\">$ref->{'nome'} - ".Level($ref->{'level'})."</option>" if $accesslevel =~ /(^|::)$ref->{'id'}(::|$)/ || $accesslevel =~ /GLOB(::|$)/; 
		}
		$sth->finish;
	
		if ($status eq "A" || $status eq "open") {
			$template{'cc'} = "";
	        
			if ($accesslevel =~ /GLOB::/) {
				$where = qq| WHERE status != "F"|;
				$where .= qq| AND `category` = "$department"| if defined  $q->param('department');               
			} else {
				@access = split(/::/,$accesslevel);
				my @deps;
				foreach $dep (@access) {
					$dep=~s/^\s+//g;
					push @deps, "category = \"$dep\"" if $dep eq $department;
				}
				$where = qq| WHERE|;
				$where .= qq| (|.join(" OR ",@deps).qq|) AND| if @deps;
				$where .= qq| `status` != \"F\"|; 
			}          
		} else {
			$template{'cc'} = qq|<br>FILTER: ( <a href="?do=listcalls&status=closed&filter=0">CLOSED BY ME</a> / <a href="?do=listcalls&status=closed&filter=1">CLOSED BY ALL</a> )|;
	
			if ($q->param('filter') eq "1") { 
				if ($accesslevel =~ /GLOB::/) { 
	   				$where = qq| WHERE status = "F"|;
	 				$where .= qq| AND `category` = "$department" | if defined $q->param('department');                              
				} else {
					@access = split(/::/,$accesslevel);
					my @deps;
					foreach $dep (@access) {
						$dep=~s/^\s+//g;
						push @deps, "`category` = \"$dep\"";
					}
					$where = qq| WHERE (|.join(" OR ",@deps).qq|) AND `status` = \"F\"|;					
					$where .= " AND `category` = \"$department\"" if defined $q->param('department'); 
				}
			} else { 
				$where = " WHERE status = \"F\" AND closedby = \"$staff_id\"";
				$where .= " AND `category` = \"$department\" " if defined $q->param('department'); 
			}
		}

 		($nav,$limit,$page,$count,$show,$number) = paginar("calls",15,$where);
	
		$sortby = $q->param('orderby'); 
		$ord = $sortby;
		$order = "ASC";
		if ($ord eq $q->param('ord')) {
			$order = "DESC";
			$ord = "none";
		}	 
		if (!$sortby) { $sortby = "id"};

		$sortby = join("` $order, `",split(/\,/,$sortby));

		$statement  = qq|SELECT * FROM `calls`|.$where;
		$statement .= qq| ORDER BY `$sortby` $method LIMIT $show, $limit|;
		$sth = select_sql($statement);
		$number=0;
		while($ref = $sth->fetchrow_hashref()) {	
			$number++;
			$subject = my2html($ref->{'subject'}); 
			$subject = substr($subject,0,20).'..' if length($subject) > 22;
	
			$font   = '#000000';
			if ($ref->{'method'} eq "cc" ) { 
				$img = "phone.gif"; 
			} elsif ($ref->{'method'} eq "em") { 
				$img = "mail.gif"; 
			} elsif ($ref->{'method'} eq "ss") { 
				$img = "new.gif"; 
			} else { 
				$img = "ticket.gif"; 
			}
			
			if ($ref->{'tipo'} eq "Hospedagem") { $color = $global{'pri1'};} 
			if ($ref->{'tipo'} eq "Revenda") { $color = $global{'pri2'}; }  
			if ($ref->{'tipo'} eq "Registro") { $color = $global{'pri3'}; } 
			if ($ref->{'tipo'} eq "Dedicado") { $color = $global{'pri4'}; } 
			if ($ref->{'tipo'} eq "Adicional") { $color = $global{'pri5'}; }			
			
			if ($ref->{'aw'} eq "1") { $awt = "<img src=\"$template{'imgbase'}/online.gif\">"; } else { $awt = "<img src=\"$template{'imgbase'}/offline.gif\">"; }
	
			@count = split(" ",timediff(time,$ref->{'track'}));
			$count = "$count[0] $count[1]";
	
			if ($ref->{'ownership'} eq $staff_id) { $otag = "<b>"; $ctag = "</b>"; } else { $otag = ''; $ctag=''; }
	
			$opencalls .= display_ticket($ref->{'id'}, $ref->{'username'}, $ref->{'category'}, $ref->{'status'});
		}
			
		$opencalls = '<br><div align=center><font face=Verdana size=2>0 Requests Found</font></div><br>' if !$opencalls;
			
		$template{'listcalls'}	=  $opencalls;
		$template{'type'}		=  $status;
		$template{'path'}		=  "" . '?' . $ENV{'QUERY_STRING'};
		$template{'path'}		=~  s/&sort=(.*)//;
		$template{'path'}		=~  s/&method=(.*)//;
	 
		parse("$template{'data_tpl'}/$sect/listcalls");
	}
	
	if ($section eq "messanger") {
		check_user(); 
		$too = $q->param('to');
	
		if ($too eq "reply") {
	   
			$msg = $q->param('id');
	
			$statemente = 'SELECT * FROM messages WHERE id = ?'; 
			$sth = select_sql($statemente,$msg) ;
			while(my $ref = $sth->fetchrow_hashref()) {
				$from    =  $ref->{'sender'};
				$subject =  $ref->{'subject'};    
			}
	
			open (IN, "$template{'data_tpl'}/$sect/msgreply.tpl") || die "Unable to open: $!";
				while (<IN>) {
					if ($_ =~ /\{*\}/i) {
						s/\{username\}/$cookname/i;	
						s/\{touser\}/$from/ig;				
					}
					print $_;
				} 		
			close (IN);
		}
	
		if ($too eq "delete") {
	
			$msg = $q->param('id');
		
			$statemente = 'SELECT * FROM messages WHERE id = "' . "$msg" . '"'; 
			$sth = select_sql($statemente) ;
			while(my $ref = $sth->fetchrow_hashref()) {
				if ($ref->{'touser'} ne $staff_id) { print 'This is not your message to delete'; exit; } 
			}
		
			execute_sql(qq|DELETE FROM `messages` WHERE id = "$msg"|); 
		
			$statemente = "SELECT * FROM messages WHERE touser = \"$staff_id\" ORDER BY id DESC"; 
			$sth = select_sql($statemente) ;
			while(my $ref = $sth->fetchrow_hashref()) {
				$message = '<tr bgcolor="#F1F1F8"><td width="7%"><font face="Verdana" size="1">' . "$ref->{'id'}" . '</font></td> <td width="26%"><font face="Verdana" size="1">' . "$ref->{'sender'}" . '</font></td>
							<td width="28%"><font face="Verdana" size="1">' . "$ref->{'date'}" . '</font></td><td width="39%"><font face="Verdana" size="1">' . "<a href=\"staff_messanger.pl?action=view&id=$ref->{'id'}\">$ref->{'subject'}</font></a>" . '</td></tr>';
		
				push @messages, $message;
			}
		
			open (IN, "$template{'data_tpl'}/$sect/inbox.tpl") || die "Unable to open: $!";
				while (<IN>) {
					if ($_ =~ /\{*\}/i) {	s/\{messages\}/@messages/i;	}
					print $_;
				}   		
		
				$dbh->disconnect;
				exit;
			}
	
		if ($too eq "inbox") {
	
			$statemente = "SELECT * FROM messages WHERE touser = \"$staff_id\" ORDER BY id DESC"; 
			$sth = select_sql($statemente) ;
			while(my $ref = $sth->fetchrow_hashref()) {
				$message = '<tr bgcolor="#F1F1F8"><td width="7%"><font face="Verdana" size="1">' . "$ref->{'id'}" . '</font></td> <td width="26%"><font face="Verdana" size="1">' . "$ref->{'sender'}" . '</font></td>
		                                    <td width="28%"><font face="Verdana" size="1">' . "$ref->{'date'}" . '</font></td><td width="39%"><font face="Verdana" size="1">' . "<a href=\"?do=messanger&to=view&id=$ref->{'id'}\">$ref->{'subject'}</font></a>" . '</td></tr>';
				push @messages, $message;
			}
		
			$current_time = time();
		
			execute_sql(qq|UPDATE staffread SET date = "$current_time" WHERE username = "$cookname"|); 
		
			open (IN, "$template{'data_tpl'}/$sect/inbox.tpl") || die "Unable to open: $!";
				while (<IN>) {
					if ($_ =~ /\{*\}/i) {
						s/\{messages\}/@messages/i;					
					}
					print $_;
				} 		
			close (IN);
		}
	
		if ($too eq "view") {
	
			$msg = $q->param('id');
			$statemente = 'SELECT * FROM messages WHERE id = "' . "$msg" . '"'; 
			$sth = select_sql($statemente) ;
			while(my $ref = $sth->fetchrow_hashref()) {
				$from = $ref->{'sender'};
				$to = $ref->{'touser'};
				$date = $ref->{'date'};
				$subject = $ref->{'subject'};
				$message = $ref->{'message'};          
			}
	
			if ($to ne $staff_id) { print 'This is not your message'; exit; }
	
			open (IN, "$template{'data_tpl'}/$sect/msgview.tpl") || die "Unable to open: $!";
				while (<IN>) {
					if ($_ =~ /\{*\}/i) {
						s/\{subject\}/$subject/i;	
						s/\{from\}/$from/i;
						s/\{sent\}/$date/i;	
						s/\{id\}/$msg/ig;	
						s/\{message\}/$message/i;					
					}
					print $_;
				} 		
			close (IN);
			$dbh->disconnect;
			exit;
		}
	
		if ($too eq "compose") {
	
	 		$statemente = 'SELECT username FROM staff WHERE username != "' . "$cookname" . '"'; 
			$sth = select_sql($statemente) ;
			while(my $ref = $sth->fetchrow_hashref()) {
				$ddopt = "<option value=\"$ref->{'username'}\">$ref->{'username'}</option>";
				push @dd, $ddopt;
			}
			if (not @dd) { @dd = '<option value="">No Other Users</option>'; }
			open (IN, "$template{'data_tpl'}/$sect/msgcompose.tpl") || die "Unable to open: $!";
				while (<IN>) {
					if ($_ =~ /\{*\}/i) {
						s/\{ddlist\}/@dd/i;	
						s/\{username\}/$cookname/i;				
					}
					print $_;
				} 		
			close (IN);
		}
	
	 	if ($too eq "savenote") {
	
			$from    = $cookname;
			$to      = $q->param('user');
			$subject = $q->param('subject');
			$message = $q->param('message');
	
		    $statemente = qq|SELECT * FROM staff WHERE username = "$to"|; 
		    $sth = select_sql($statemente) ;
			while(my $ref = $sth->fetchrow_hashref()) {
				$valid = $ref->{'name'};
			}
	
			if (!$valid) {
				print "<div align=\"center\"><font face=\"Verdana\" size=\"2\"><br><b>Sorry,</b> user does not exist on this system <a href=\"javascript:history.back(1)\">Back</a></div>";
				exit;
			}
	
			$current_time =   time();
			$message      =~  s/\"/\\"/g;
		
			die_nice("No Subject Specified") if !$subject;
		
		 my $rv = execute_sql(qq{INSERT INTO `messages` values (NULL, "$to", "$from", "$hdtime", "$subject", "$message", "$current_time")});
		
			print "<div align=\"center\"><font face=\"Verdana\" size=\"2\"><br>Message has been sent to \'$to\' - Back to <a href=\"?do=messanger&to=inbox\">Inbox</a></font></div>";
		
			$dbh->disconnect;	
			exit;
		}
	}
	
	if ($section eq "call_del") { 
		check_user();
			
		parse("$template{'data_tpl'}/$sect/call_del");
	}
	
	if ($section eq "delete") {
		check_user(); 
		$callid = $q->param('cid');
	
		$statemente = 'SELECT * FROM `settings` WHERE `setting` = "sdelete"'; 
		$sth = select_sql($statemente) ;
		while(my $ref = $sth->fetchrow_hashref()) {
			if (!$ref->{'value'}) {
				print "<br><font face=Verdana size=2><div align=Center>Sorry. The administrator has removed delete access for staff members</div></font>";
				exit;
			}
		}
		$template{'response'} = "<b>Deletar Ticket $callid?</b><br><br><a href=\"?do=confirmdel&cid=$callid\">Sim, deletar.</a>";
		parse("$template{'data_tpl'}/$sect/general");
	}
	
	
	if ($section eq "confirmdel") {
		check_user(); 
	
		$callid = $q->param('cid');
	
		if ($accesslevel !~ /GLOB::/) {
			$statemente = 'SELECT `category` FROM `calls` WHERE `id` = ?'; 
			$sth = select_sql($statemente,$callid);
		    while(my $ref = $sth->fetchrow_hashref()) {
				if ($accesslevel =~ /(^|::)$ref->{'category'}(::|$)/) {
				} else {
					die_nice("You do not have permission to delete this call.");
					exit;
				}
			}
		}
		if (!$global{'sdelete'} || !$callid) {
			die_nice("You do not have permission to delete this call.");
			exit;
		}
	
		execute_sql(qq|DELETE FROM `calls` WHERE `id` = $callid|); 
		execute_sql(qq|DELETE FROM `notes` WHERE `call` = $callid|); 
	
		$template{'response'} = "<b>Request Deleted</b> <a href=?do=main>Back to calls</a>";
		parse("$template{'data_tpl'}/$sect/general"); 
	}
	
	if ($section eq "view_file") {
		check_user();
		$file = $q->param('id');
	
	 my $sth = select_sql(qq|SELECT `filename`, `file` FROM `files` WHERE `id` = "$file"|); 
		while(my $ref = $sth->fetchrow_hashref()) {
			$name = $ref->{'filename'}; $filename = $ref->{'file'};
		}

		if (defined $file && $file ne "") { 
			open(LOCAL, "<$filename") or die_nice("Erro ao abrir anexo: ".$!);
				print qq|Content-Disposition: attachment; filename="$name"\n|;
				print qq|Content-Type: application/octet-stream\n\n|;			
				while(<LOCAL>) {
					print;
				}
			close(LOCAL);
		}
		
		$has = 1;
	}
	
	if ($section eq "call_edit") { 
		check_user();
			
		parse("$template{'data_tpl'}/$sect/call_edit");
	}
	
	if ($section eq "ticket") {
		check_user(); 
	
		$template{'aviso'} = $q->param('aviso');
	 my $trackedcall =  $q->param('cid') || $id;
	 	$system->callid($trackedcall);
	 
	 	if ($q->param('transfer') eq "user") {
	 		execute_sql(qq|UPDATE `calls` SET `username` = ? WHERE `id` = "|.num($trackedcall).qq|"|, num($q->param('user'))); #(`username` = "" OR `username` IS NULL) and
			print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$trackedcall\n\n";
			exit;	 		 
	 	} elsif ($q->param('transfer') eq "service") {
	 		execute_sql(qq|UPDATE `calls` SET `service` = ? WHERE `id` = |.num($trackedcall).qq| AND `username` = |.num($q->param('user')), $q->param('servico')); #(`service` = "" OR `service` IS NULL) and TIREI A PROTECAO pq o precisava mudar qd tava errado
			print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$trackedcall\n\n";
			exit;
	 	} elsif ($q->param('transfer') eq "service") {
	 		execute_sql(qq|UPDATE `calls` SET `service` = ? WHERE `id` = |.num($trackedcall).qq| AND `username` = |.num($q->param('user')), $q->param('servico')); #(`service` = "" OR `service` IS NULL) and TIREI A PROTECAO pq o precisava mudar qd tava errado
			print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$trackedcall\n\n";
			exit;
	 	}
	
		$number=0;
		$sth = select_sql(qq|SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls` WHERE `id` = ? ORDER BY `id`|,$trackedcall);
		while(my $ref = $sth->fetchrow_hashref()) {	
#			if (($accesslevel =~ /(^|::)$ref->{'category'}(::|$)/) || ($accesslevel =~ /GLOB(::|$)|^$/)) {
				$template{'trackno'}     =   $ref->{'id'};
				$template{'date'}        =   FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1];
				$template{'uname'}       =   $ref->{'username'};						
				$template{'username'}    =   $ref->{'username'};
				$template{'priority'}    =   $ref->{'priority'};
				$template{'status'}      =   HStatus($ref->{status});
				$template{'subject'}     =   my2html($ref->{'subject'});
				$template{'servn'} 	     =   $ref->{'service'};
				$template{'servidor'} = $ref->{"service"} ? Servidor(Servico("$ref->{service}","servidor"),"nome") : "-";
				my ($dep,$level) = Departments($ref->{'category'},"nome level");
				$template{'category'} = "$dep - ".Level($level);
				$template{'description'} = my2html($ref->{'description'});
#				$template{'description'} =~ s/\r\n/<br>/g;
				($template{'owned'}) = split("---",Staffs($ref->{'ownership'},"name")); #TODO AKI TEM Funcao Staffs pra virar @
				$template{'owned'} ||= "Nenhum";
				$template{'number'}      =   0;
				$template{'email'} = html($ref->{'email'});
				$template{'awt'} = $ref->{'aw'} eq "1" ? "<img src=\"$template{'imgbase'}/online.gif\">" : "<img src=\"$template{'imgbase'}/offline.gif\">";
				
				if ($ref->{'is_locked'} > 0) {
					$template{'aviso'} .= qq|<font color="#FF0000">|.Staffs($ref->{'is_locked'},"name").qq| já está respondendo este pedido</font>|;
				} 
				if ($staff_id == $ref->{'is_locked'}) {
					$template{'aviso'} .= qq|<br><a href="?action=rafter&cid=$trackedcall"><font color="#0000FF">Clique aqui para responder depois</font></a>|;
				}
				
				if (grep {$cookname eq $_} $system->followers) {
					$template{'follow'} = qq|<a href="?action=unfollow&cid=$trackedcall">PARAR</a>|
				} else { 
					$template{'follow'} = qq|<a href="?action=follow&cid=$trackedcall">SEGUIR</a>|;
				}
								
				$template{'ltime'} = timediff(time(),$ref->{'active'}) || 0;
				$template{'ttime'} = timediff(time(),$ref->{'track'}) || 0;
				$template{'time_s'} = timediff($ref->{'time_spent'},0) || 0;
				$system->sid($ref->{service});
				my $dominio = $system->service('dominio'); 
				my $tipo = $system->plan('tipo');
				my $plat = $system->plan('plataforma');
				$template{'url'} = "$dominio - $tipo $plat ". $system->plan('nome'); 
				$template{'url'} =   "" if $dominio eq "-";
				$template{'title'} = sprintf($global{'epre'},$ref->{'id'})." - $template{'subject'} - ";
				if ($template{'servn'}){
					$template{'linktos'} = "?do=service_details&service=$template{'servn'}";
				} elsif ($template{'username'} eq "E-mail" || $template{'username'} eq ""){
					$template{'linktos'} = "?do=service_details";
				} else {
					$template{'linktos'} = "?do=lookupservice&select=servicos.username&query=$template{'username'}";
				}
				
				if ($ref->{'method'} eq "cc" ) { 
					$template{'method'} = "phone.gif"; 
				} elsif ($ref->{'method'} eq "em") { 
					$template{'method'} = "mail.gif"; 
				} elsif ($ref->{'method'} eq "ss") { 
					$template{'method'} = "new.gif"; 
				} else { 
					$template{'method'} = "ticket.gif"; 
				}
#			} else {
##				$error= 'You do not have permission to view this call';
#				section("main");
#				exit;
#			}								
		}
		$sth->finish;
	
		if (@errors) {
			die_nice(@errors);
			exit;
		}
	
		$sth = 	select_sql(qq|SELECT * FROM `activitylog` WHERE `cid` = ? ORDER BY `id`|,$trackedcall);
		$template{'log'} = "" if $sth->rows eq 0;
		while(my $ref = $sth->fetchrow_hashref()) {
			$template{'log'} .= qq|<tr bgcolor="#E8E8E8"><td width="25%" height="8"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$ref->{'date'}</font></td>
			<td width="20%" height="8"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$ref->{'user'}</font></td><td colspan="3" height="8" width="55%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">$ref->{'action'}</font></td></tr>|;
		}	
		$sth->finish;
	
		$sth = select_sql(qq|SELECT `id`, `cid`, `filename`, `file` FROM `files` WHERE `cid` = ?|,$trackedcall);
		$template{'filename'} = qq|Nenhum| if $sth->rows == 0;
		while(my $ref = $sth->fetchrow_hashref()) {
			$template{'filename'} .= qq|<a href="?do=view_file&id=$ref->{'id'}">$ref->{'filename'}</a> |;
		}
		$sth->finish;
	
	#	my $htmlcode = $global{'allowhtml'};
	
		my $body;
		
		$sth = select_sql(qq|SELECT *, ADDTIME(time,'$cooktzo:00:00') as time FROM `notes` WHERE `call` = ? ORDER BY `time`|,$trackedcall); 
		while(my $ref = $sth->fetchrow_hashref()) {
			$rating = "";     
			$body   = my2html($ref->{'comment'});
			#$body   = pdcode("$body");
			my $filename;
			
		 my $h = select_sql(qq|SELECT * FROM `files` WHERE `nid` = $ref->{'id'}|);
		 	$filename = "" if $h->rows == 0;
			while(my $ef = $h->fetchrow_hashref()) {	
				$filename .= qq|<a href=?do=view_file&id=$ef->{'id'}>$ef->{'filename'}</a> |;
			}
			$h->finish;
#			if ($body =~ /^</) {
#			} else {
#			#	$body =~ s/\n/<br>/g;
#			}
#die $body;

			my ($s_name) = split("---",Staffs($ref->{'author'},"name"));
			$s_name ||= "Nenhum";

			if ($ref->{'owner'} == 0) {
				($name) = Users($ref->{'author'},"name");
				$template{'notes'} .= qq|<tr><td width="30%" height="14" valign="top" bgcolor="#F2F2F2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>$ref->{'author'} - $name<br><i>$ref->{'poster_ip'}</i><br>
						</b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1">|.FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1].qq|<br><br><a href=?do=editnote&nid=$ref->{'id'}>Edit Response</a> </font></td>
						<td width="70%" height="14" valign="top" bgcolor="#F2F2F2"><font face="Verdana, Arial, Helvetica, sans-serif" size="1">$body<br><br>$filename</font></td></tr>|;
			} 
	
			if ($ref->{'owner'} == 1) {
				$th = select_sql(qq|SELECT `id`,`nid`,`rating` FROM `reviews` WHERE `nid` = $ref->{'id'}|);
				$rating = "No Rating" if $th->rows eq 0;
				while(my $ef = $th->fetchrow_hashref()) {
					for(1..$ef->{'rating'}) {
						$rating .= "<a href=?do=view_review&nid=$ref->{'id'}><img src=$template{'imgbase'}/new.gif heigh=12 border=0 width=10></a>";
					}
				}
				$th->finish;
	
				if ($ref->{'visible'} == 0) {
					$notice = '<b>PRIVADO AOS STAFFS</b><br>';
				} else {
					$notice = '';
				}
				$template{'notes'} .= qq|<tr><td width="30%" height="14" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Staff - $s_name<br><i>$ref->{'poster_ip'}</i><br>
							</b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1">|.FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1].qq|<br><br>User Rating: $rating<br><br><br><a href="?do=editnote&nid=$ref->{'id'}">Editar Resposta</a></font></td>
							<td width="70%" height="14" valign="top"><font face="Verdana, Arial, Helvetica, sans-serif" size="1">$notice $body<br><br>$filename</font></td></tr>|;
			}

			if ($ref->{'owner'} == 2) {
				$template{'notes'} .= qq|<tr><td width="30%" height="14" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Controller - Auto<br><i>$ref->{'poster_ip'}</i><br>
							</b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1">|.FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1].qq|<br><br></font></td>
							<td width="70%" height="14" valign="top"><font face="Verdana, Arial, Helvetica, sans-serif" size="1"><b>STAFF ACTION: $ref->{'action'}</b><br>$body</font></td></tr>|;
			} 
	
			if ($ref->{'owner'} == 3) {
				$template{'notes'} .= qq|<tr><td width="30%" height="14" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Staff - $s_name<br><i>$ref->{'poster_ip'}</i><br>
							</b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1">|.FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1].qq|<br><br></font></td>
							<td width="70%" height="14" valign="top"><font face="Verdana, Arial, Helvetica, sans-serif" size="1"><b>STAFF ACTION: $ref->{'action'}</b><br>$body</font></td></tr>|;
			} 
		}
		
		#Sempre permitir transferencia, pois pode existir cadastro duplicado
		$template{'fields'} = parse_var("$template{'data_tpl'}/$sect/user_transfer");
		unless ($template{'username'}) {
			#$template{'fields'} = parse_var("$template{'data_tpl'}/$sect/user_transfer");
		} else {
			#unless ($template{'servn'}) {
				my $sth = select_sql(qq|SELECT * FROM v1_servicos WHERE `username` = ? AND `status` != 'F'|,$template{'username'});
				while(my $ref = $sth->fetchrow_hashref) {
					my $status = Status($ref->{'status'});
					$template{'servicos'} .= qq|<option value = "$ref->{'id'}">$ref->{'id'} - $ref->{'tipo'} $ref->{'plataforma'} $ref->{'nome'} - $ref->{'dominio'} - $ref->{'servidor'} ($status)</option>|;
				} 
				$template{'fields2'} = parse_var("$template{'data_tpl'}/$sect/service_transfer");
				
				my $sth2 = select_sql(qq|SELECT id FROM `calls` WHERE `username` = ? AND `status` != 'F' AND `id` != |.num($trackedcall),$template{'username'});
				while(my $ref2 = $sth2->fetchrow_hashref) {					
					$template{'tickets'} .= qq|<a target="_blank" href="?do=ticket&cid=$ref2->{'id'}">$ref2->{'id'}</a> |;
				} 									 
			#}
		}
		$template{'fusername'} = $template{'username'} ? "$global{'users_prefix'}-$template{'username'}" : "<font color=ff0000><b>Não registrado</b></font>";
		
		parse("$template{'data_tpl'}/$sect/viewticket");
	}
	
	if ($section eq "pop_suser") {
		check_user();
		
		$template{'trackno'} = $q->param('cid') || $id;
		if (defined html($q->param('query'))) {
			$table = "servicos right join users on servicos.username=users.username";
			$results = "username::name::email::dominio::cidade::estado";
			$group = "servicos`.`username";
			$query = trim(html($q->param('query')));
			$order = "servicos`.`username";
			$field = html($q->param('field'));
			@result = Search($table,$results,$field,$query,$order,$group);
			$tpl = "username - name - email - domínio - cidade - estado<br>";
			foreach (@result) {
				my ($un,$n,$e,$cd,$es) = split(/::/,$_);
				$tpl .= qq|<a href="?do=ticket&cid=$template{'trackno'}&transfer=user&user=$un">$un</a>|;
				$tpl .= " $n - $e - $cd - $es<BR>";
			}
			
			$template{'response'} = $tpl;
			
			parse("$template{'data_tpl'}/staff/general");
		} else {
			$template{'option'} = qq|<option value="dominio">%Domain%</option>|;		
			parse("$template{'data_tpl'}/staff/user_search");
		}		
	} 
	
	if ($section eq "listbyuser") {
		check_user(); 
		$userview = $q->param('user');

#Tirando acesso porque é interessante listar os chamados	
#		if ($accesslevel =~ /GLOB::/) {
	
		my $where = qq| WHERE `username` = '$userview'|;
 		($nav,$limit,$page,$count,$show,$number) = paginar("calls",15,$where);
	
		$sortby = $q->param('orderby'); 
		$ord = $sortby;
		$order = "DESC";
		if ($ord eq $q->param('ord')) {
			$order = "DESC";
			$ord = "none";
		}	 
		if (!$sortby) { $sortby = "id"};

		$sortby = join("` $order, `",split(/\,/,$sortby));

		$statement  = qq|SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls`|.$where;
		$statement .= qq| ORDER BY `$sortby` $order LIMIT $show, $limit|;
		$sth = select_sql($statement); 
		
		$number=0;
		while(my $ref = $sth->fetchrow_hashref()) {			
			#if (($accesslevel =~ /$ref->{'category'}::/) || ($accesslevel =~ /GLOB::/)) {
				$number++;
				$subject = my2html($ref->{'subject'}); 
				$subject = substr($subject,0,20).'..' if length($subject) > 22;
				if ($ref->{'priority'} == 1) { $font = '#000000'; } else { $font = '#000000'; }
				my $awt;
				if ($ref->{'aw'} eq "1") { 
					$awt = "<img src=\"$template{'imgbase'}/online.gif\">"; 
				} else { 
					$awt = "<img src=\"$template{'imgbase'}/offline.gif\">"; 
				}							
				$call .= '<table width="100%" border="0" cellpadding="4"><tr bgcolor="#E4E7F8"> 
						<td width="4%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src="' . "$template{'imgbase'}/ticket.gif" . '"></font></td>
						<td width="4%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font> $ref->{'id'}" . '</font></td>
						<td width="10%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>$ref->{'username'}" . '</font></td>
						<td width="35%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>" . '<a href="?do=ticket&cid=' . "$ref->{'id'}\">$subject" . '</a></font></td>
						<td width="10%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>$ref->{'status'}" . '</font></td>
						<td width="3%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>$awt" . '</font></td>
						<td width="11%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>". ( Departments($ref->{'category'},"nome") )[0] . '</font></td>						
						<td width="23%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=' . "$font>".FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1]. '</font></td></tr></table>';
			#}
		}
		$template{'listcalls'} = $call;
		$template{'customer'}  = $userview;    
	
		parse("$template{'data_tpl'}/$sect/viewbyuser");
	  }
	
	
	if ($section eq "log") {
	
		check_user(); 
	 my $statement = qq|SELECT * FROM staff WHERE username = "$cookname"|; 
	 my $sth = select_sql($statement) ;
		while(my $ref = $sth->fetchrow_hashref()) {
			$accesslevel  =  $ref->{'access'};
		}
		$sth->finish;

		$sth = select_sql("SELECT `id`,`nome`,`level` FROM `departments` ORDER BY `nome`");
		my (@deps,$depnome,$deplevel);
		while(my $ref = $sth->fetchrow_hashref()) {
			if ($accesslevel =~ /(^|::)$ref->{'id'}(::|$)/ || $accesslevel =~ /GLOB(::|$)/ ) {
				push @deps, $ref->{'nome'};
			}
		}
		$sth->finish;
		
		foreach (Controller::iUnique(\@deps)) {	
			$list .= "<option value=\"$_\">$_</option>";
		}
		
		$sth = select_sql("SELECT `id`,`nome` FROM `level` ORDER BY `nome`");
		my $empresas;
		while(my $ref = $sth->fetchrow_hashref()) {
			$empresas .= "<option value=\"$ref->{'id'}\">$ref->{'nome'}</option>";
			
		}
		$sth->finish;
				
	 	$template{'username'} = $q->param('user');
		$template{'service'}  = $q->param('service');
		$template{'email'}    = html($q->param('email'));
		$template{'category'} = $list;
		$template{'level'} = $empresas;

		$sth = select_sql(qq|SELECT * FROM `preans` WHERE `author` = ? OR `author` IS NULL ORDER BY `subject`|,$staff_id) ;
		while(my $ref = $sth->fetchrow_hashref()) {
 			my $text = $ref->{'text'};
 			$text =~ s/\\n/\n/g;
 			$text =~ s/\\r//g;
 			$text = html($text);
			$template{'preans'} .= qq|<option value="$text">$ref->{'subject'}</option>| ;
		}
		$sth->finish;
	
		parse("$template{'data_tpl'}/$sect/newcall");
	}
	
	
	
	if ($section eq "logsave") {
		check_user(); 
	
		my $sendmail;
		my $metodo = $q->param('metodo');
	
		my $subject = $q->param('subject');
		my $description = $q->param('description');
		my $emdescription = hd2html($q->param('description'));
		my $priority =	$q->param('priority');
		my $categoryname =	$q->param('category');
		my $status = $q->param('status');
		my $email_user = $q->param('email_user');
		my $uusername = $q->param('username');
		my $service = $q->param('service');
		my $email = lc $q->param('email');
		die 'Email inválido!' if $email && !$system->is_valid_email($email);
		$system->uid($uusername) unless $service; #A orderm é importante, tem q vir antes de sid		
		$system->sid($service) if $service;
		$uusername = $system->uid if $service;
		my @entid = split('::',$system->user('level')) if $system->uid;
		my $level =	$q->param('level') || $entid[0];
		my $file = $q->param('file');
		die 'Informe uma Empresa' unless $level; 
		#TODO colocar empresa baseado no nivel do plano ? tipo se o servico aki escolhido for revenda entao prevalece do nome do usuario
		
		my @levels = ($q->param('level'), @entid);
		Controller::iDelete(\@levels);
		$sth = $system->select_sql("SELECT `id`,`level` FROM `departments` WHERE `nome` = ? AND `level` IN (". join(',' => @levels) .")", $categoryname);
		my $category;
		while(my $ref = $sth->fetchrow_hashref()) {
			$category = $ref->{'id'};
			last;
		}
		$sth->finish;
		#TODO quando é escolhido a empresa e o departamento manualmente e o cliente não tem acesso ao level ele não deixa e mostra essa mensagem errada.
		die 'Informe um departamento' unless $category;

		my ($from) = Departments($category,"sender");
		$from ||= $global{'adminemail'};		
		
		my $m = $metodo;
		if ($metodo eq "cc"){
			if ($uusername) { $m = "hd"; } else { $m = "em";	}
		}
			
		if ($m eq "hd") {
			$uname = $system->user('name');
 			$email = join ',', grep { $system->is_valid_email($_) } @{ $system->user('email') };	
			$sendmail = "hd" if $email_user eq "s";
		} elsif ($m eq "em"){
			if ($email) {
				my $sth = select_sql(qq|SELECT `username` FROM `users` WHERE `email` LIKE '%$email%'|); 
				( $uusername ) = $sth->fetchrow_array();
				$sth->finish;
			}				
			#se a busca é por email, como pode ser OU? #$email ||= Users($uusername,"email");
			#$username = "E-mail";
			$sendmail = "em" if $email_user eq "s";
		} 

		$current_time = time();
	 my @chars =  ("A" .. "Z", "a" .. "z", 0 .. 9);
		$key   =  $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)];
	   	$callid = $id = $system->execute_sql(344,"$status", "$uusername", "$email", "$priority", "$service", "$category", "$subject", "$description", "$hdtime", undef, "", "$metodo", "$current_time", "$current_time", "1", "0", "0", "0");
		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, "$callid", "$hdtime", "Staff: $cookname", "Request Logged" )|,"",1);
		
		my ($up,$filename,$fcontent);
		if (defined $file && $file ne "")  {
			($up,$filename,$fcontent) = Upload($file,$callid,0);
			die_nice("<li>Erro no upload do arquivo.</li>") unless $up; 			
		}
	
		if ($sendmail eq "hd"){	
		 	$template{'name'} = $uname;
			$template{'tid'} = $callid;
			$template{'tassunto'} = $subject;
			$template{'response'} = $emdescription;			
			($template{'tdepartamento'}) = Departments($category,"nome");
			$template{'tdepartamento'} ||= "-";
			$template{'tlink'} = qq|<a href=$template{'baseurl'}</a>|;
		 my $ok = email ( User => "$uusername", To => "$email", From => "$from", Subject => ['sbj_new_ticket',sprintf($global{'epre'},$callid)], txt => "newtickets", Att => "$fcontent", File => "$filename");
			$template{'aviso'} .= "<br><font color=FF0000>Error ao enviar e-mail: $ok</b></font>" if $ok ne "1";	
		} elsif ($sendmail eq "em"){	
			#$template{'description'} = $q->param('description');
			($template{'depto'}) = Departments($category,"nome");
			$template{'depto'} ||= "-";
			$template{'tech'} = $name;
			$template{'response'} = $emdescription;
			$template{'quote'} = $quote; 
		 my $ok = email ( User => "$uusername", To => "$email", From => "$from", Subject => ['sbj_ticket_logged',sprintf($global{'epre'},$callid),$q->param('subject')], txt => "email", Att => "$fcontent", File => "$filename" );
			$template{'aviso'} .= "<br><font color=FF0000>Error ao enviar e-mail: $ok</b></font>" if $ok ne "1";
		}
	
		#$section = "ticket";
		#goto inicio;
		print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n";
		exit;
	}
	
	if ($section eq "editnote") {
		check_user(); 
		my $noteid = $q->param('nid');
	
		my $sth = select_sql(qq|SELECT * FROM `notes` WHERE `id` = $noteid|); 
		while(my $ref = $sth->fetchrow_hashref()) {
			
			$response = qq|<table width="100%" border="0"><tr><td><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>Edit Note 
						[Call ID: |.$ref->{'call'}.qq|]</b><BR><BR></font></td></tr><tr><td><form name="form1" method="post">
						<table width="100%" border="0"><tr><td width="29%" height="20" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">EDIT 
						NOTE</font></td><td width="71%" height="20"><textarea name="comment" cols="50" rows="10">|.my2html($ref->{'comment'}).qq|</textarea>
						</td></tr><tr><td colspan="2"><div align="center"><input type="hidden" name="do" value="editnotesave"><input type="hidden" name="ticket" value="|.$ref->{'call'}.qq|"><input type="hidden" name="note" value="|.$ref->{'id'}.qq|">
						<input type="submit" name="seditnote" value="Submit"></div></td></tr></table></form>|;
		}
		$template{'response'} = $response;
		parse("$template{'data_tpl'}/$sect/general");
	}
	
	if ($section eq "editnotesave") {
		check_user(); 
	
	 my $comment = $q->param('comment');
	 my $ticket = $id = num($q->param('ticket')); 
	 my $note = $q->param('note');
		$system->execute_sql(qq|UPDATE `notes` SET `comment` = ? WHERE `id` = "$note"|,$comment);
		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, "$id", "$hdtime", "Staff: $cookname", "Nota $note editada")|,'',1);
	
		#$section = "ticket";
		#goto inicio;
		print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n";
		exit;
	}
	
	 if ($section eq "mudar_nivel") {
		check_user(); 
		$id = $q->param('id');
		$nivel = $q->param('nivel');
		
		execute_sql(qq|UPDATE `calls` SET priority = "$nivel", `ownership` = NULL, `aw` = "1" WHERE `id` = "$id"|);
		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, "$id", "$hdtime", "Staff: $cookname", "Priority Changed: $nivel")|,'',1);
	
		print "Content-type: text/html\n\n"; 
		print qq|<html><p>&nbsp;</p><p>&nbsp;</p><meta http-equiv="refresh" content="1;URL=?do=ticket&cid=$id"><p align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Ticket Updated</b></font><br><br>
	       		<font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=ticket&cid=$id">click 
	  			here</a> if you are not automatically forwarded</font></p></html>|;
	  			
	  	$has = 1;
	}
	
	 if ($section eq "change_status") {
		check_user(); 
	
		$id  = $q->param('id');
		$status = $q->param('status');
		die_nice('Ticket não existe') unless $id;
		die_nice('Status inválido') unless $status;
	 	
	 	if ($status =~ /AO|AU/i) {
	 		$status = $status =~ /au/i ? 0 : 1;
	 		execute_sql(qq|UPDATE `calls` SET `aw` = "$status" WHERE `id` = "$id"|);
	 		my $st = $status == 1 ? 'A.O.' : 'A.U.';
	 		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, "$id", "$hdtime", "Staff: $cookname", "Status Changed: $st")|,'',1);
	 	} else {
			execute_sql(qq|UPDATE `calls` SET `status` = "$status" WHERE `id` = "$id"|);
	 		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, "$id", "$hdtime", "Staff: $cookname", "Status Changed: $status")|,'',1);
	 	}
	
		if ($status eq "F") {
			execute_sql(qq|UPDATE `calls` SET `closedby` = "$staff_id" WHERE `id` = "$id"|);
		}
	
		#$section = "ticket";
		#goto inicio;
		print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n";
		exit;
	}
	
	if ($section eq "meeting") {
		check_user(); 
		$topico = $q->param('topico');
	
		if ($topico){
			execute_sql(qq|INSERT INTO `meeting` VALUES ( NULL, "$topico" )|);
		}
	
		$template{'response'} = "<FONT SIZE=1><B>TÓPICOS SALVOS<BR><BR></B>";
	
		$statemente = 'SELECT * FROM meeting'; 
		$sth = select_sql($statemente) ;
		while(my $ref = $sth->fetchrow_hashref()){
			$template{'response'} .= qq|$ref->{'id'} - $ref->{'topics'}<br><br>|;
		}
	    $sth->finish;
		$template{'response'} .= qq|</font><br><br><br><form action=$template{'baseurl'}/staff.cgi method="post" name="form"><input type="inbox" name="topico" size="30"><input type="hidden" name="do" value="meeting"> <input  type="submit" name="submit" value="Enviar">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<a href=http://192.168.1.7/cgi-bin/staff.cgi?do=meeting><b>Atualizar</b></a></form><br><br><br><br><a href=http://192.168.1.7/cgi-bin/staff.cgi?do=meeting&empty=1><b>Apagar tudo</b></a>|;	
		parse("$template{'data_tpl'}/staff/general");
	}
	
	if ($section eq "usercalls") {
		check_user();
		$cusername = $q->param('user');
		
		$statement = 'SELECT * FROM `calls` WHERE username = ? ORDER BY id'; 
		$sth = select_sql($statement,$cusername);
		$number=0;
		while(my $ref = $sth->fetchrow_hashref()) {	
			if (($ref->{'category'} eq $accesslevel) || ($accesslevel = 'GLOB')) {
				$number++;
				if ($ref->{'priority'} eq 1) { 
					$font = '#990000'; 
				} else { 
					$font = '#000000'; 
				}
				
				if ($ref->{'method'} eq "cc" ) { 
					$img = "phone.gif"; 
				} elsif ($ref->{'method'} eq "em") { 
					$img = "mail.gif"; 
				} elsif ($ref->{'method'} eq "ss") { 
					$img = "new.gif"; 
				} else { 
					$img = "ticket.gif"; 
				}
				$subject = my2html($ref->{'subject'}); 
				$subject = substr($subject,0,18).'..' if length($subject) > 20;
				$call .= display_ticket($ref->{'id'}, $ref->{'username'}, $ref->{'category'}, $ref->{'status'}, FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1]);
			}
		}
		$template{'username'}    =   $cusername;
		$template{'numcalls'}    =   $number;   
		$template{'listcalls'}   =   $call;
	
		parse("$template{'data_tpl'}/$sect/usercalls");
	}
}

sub function {

	$action = "@_";

	if ($action eq "history") {
		$trackedcall = $q->param('callid');
		$sth = select_sql("SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls` WHERE  `id` = ? ORDER BY `id`",$trackedcall) ;
		$number=0;
		print $q->header(-type => "text/html");
		while(my $ref = $sth->fetchrow_hashref()) {	
			print qq|<html><head><title>HelpDesk</title>
					 <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"><STYLE type=text/css>
					 A:active  { COLOR: #006699; TEXT-DECORATION: none       }
					 A:visited { COLOR: #334A9B; TEXT-DECORATION: none       }
					 A:hover   { COLOR: #334A9B; TEXT-DECORATION: underline  }
					 A:link    { COLOR: #334A9B; TEXT-DECORATION: none       }
					 </STYLE><link rel="stylesheet" href="$template{'imgbase'}/style.css"></head><body><table width="100%" border="0"><tr> <td width="29%" height="23" class="toptab"><font face="Verdana, Arial, Helvetica, sans-serif" size="2">Assunto:</font></td>
					 <td colspan="2" class="toptab" width="71%"><b><font size="2" face="Verdana, Arial, Helvetica, sans-serif">$ref->{'subject'}</font></b></td>
					 </tr><tr valign="top" class="stafftab">  <td colspan="3" height="56" class="stafftab"> <font size="2" face="Verdana, Arial, Helvetica, sans-serif">|.my2html($ref->{description}).qq|</font></td>
					 </tr><tr><td colspan="3" height="8">&nbsp;</td>
					 </tr><tr><td colspan="3" height="8" class="toptab"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Responses</b></font></td>
					 </tr><tr><td colspan="3" height="8"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">
					|;
		}
		$sth = select_sql("SELECT * FROM `notes` WHERE `call` = ? ORDER BY `id`",$trackedcall) ;
		while(my $ref = $sth->fetchrow_hashref()) {
			$body = my2html($ref->{'comment'});
			#if ($body =~ /^</) { } else {  $body =~ s/\n/<br>/g; }
			if ($ref->{'owner'} eq 0) {
				print  '<table width="100%" border="0" cellspacing="1" cellpadding="2"><tr class="userresponse"> 
						<td width="30%" height="14" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>' . Users($ref->{'author'},"name") . '<br>
						</b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1">' . FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1] . '<br><br></font></td>
						<td width="70%" height="14" valign="top"><font face="Verdana, Arial, Helvetica, sans-serif" size="1">' . "$body" . '</font></td></tr></table>';
			} 
			if ($ref->{'owner'} eq 3) {
				print  '<table width="100%" border="0" cellspacing="1" cellpadding="2"><tr class="staffaction"> 
						<td width="30%" height="14" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>' .  Staffs($ref->{'author'},"name") . '<br>
						</b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1">' . FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1] . '<br><br></font></td>
						<td width="70%" height="14" valign="top"><font face="Verdana, Arial, Helvetica, sans-serif" size="1">' . "<b>STAFF ACTION: $ref->{'action'}</b><br>$body" . '</font></td></tr></table>';
			} 
			if ($ref->{'owner'} eq 1) {
				if ($ref->{'visible'} eq 0) { $notice = '<b>PRIVATE STAFF NOTE</b><br>'; } else { $notice = ''; }
				print  '<table width="100%" border="0" cellspacing="1" cellpadding="2"><tr class="staffresponse"> 
						<td width="30%" height="14" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>' . Staffs($ref->{'author'},"name") . '<br>
						</b></font><font face="Verdana, Arial, Helvetica, sans-serif" size="1">' . FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1] . '<br><br></font></td>
						<td width="70%" height="14" valign="top"><font face="Verdana, Arial, Helvetica, sans-serif" size="1">' . "$notice $body" . '</font></td></tr></table>';
			}
		}
	
		print qq|</font><font size="1" face="Verdana, Arial, Helvetica, sans-serif"></font><font size="2" face="Verdana, Arial, Helvetica, sans-serif"></font></div></td></tr></table></body></html>|;
	}

	if ($action eq "print") {
		if (defined $q->param('callid')) {
			$trackedcall = $q->param('callid');
			 
			$sth = select_sql("SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls` WHERE  `id` = ?",$trackedcall);
			$number=0;
			while(my $ref = $sth->fetchrow_hashref()) {	
				if (($accesslevel =~ /(^|::)$ref->{'category'}(::|$)/) || ($accesslevel =~ /GLOB(::|$)|^$/)) {
					$trackno     =  $ref->{'id'};
					$date        =  $ref->{'time'};
					$username    =  $ref->{'username'};
					$priority    =  $ref->{'priority'};
					$status      =  $ref->{'status'};
					$subject     =  $ref->{'subject'};
					$category    =  $ref->{'category'};
					$description =  my2html($ref->{'description'});
					($owner) = split("---",Staffs($ref->{'ownership'},"name"));
					$owner ||= "Nenhum";
					$number      =  0;
					$email       =  $ref->{'email'};
					$url         =  $ref->{'url'};
					$name        =  $ref->{'name'};
				} else {
					$error = 'You do not have permission to view this call';
					push @errors, $error;
				}								
			}
		
			print $q->header(-type => "text/html");
	
			if (@errors) {
				@content = @errors;
				print @content;
				exit;
			}
		} else {
			print "No call defined!";
		}
	} 

	if ($action eq "movedep") {
		$callid = $id = $q->param('callid');
		my $comments = $q->param('comment');
		my $depnome = $q->param('select');
		my $tech = num($q->param('assignstaff'));
		my $priority = num($q->param('priority'));
		my $level = num($q->param('level'));
		
		$system->callid($callid);
		my $category = $system->call('category');
		unless (($accesslevel =~ /(^|::)$category(::|$)/) || ($accesslevel =~ /GLOB(::|$)|^$/)) {
			$id = $callid;
			section('ticket');
			exit;
		}	
	
		$sth = $system->select_sql("SELECT `id` FROM `departments` WHERE `nome` = ? AND `level` = ? LIMIT 1",$depnome,$level);
		my $dep;
		while(my $ref = $sth->fetchrow_hashref()) {
			$dep = $ref->{'id'};
		}
		$sth->finish;
		die 'Esta empresa não possui este departamento' unless $dep;
		
	 my @chars =  ("A" .. "Z", "a" .. "z", 0 .. 9);
		$key   =  $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)];
	         
		$system->execute_sql(382, "3", "0", "ASSIGN", "$callid", "$staff_id", "$hdtime", "$key", "$comments", "$ENV{'REMOTE_ADDR'}");
		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, "$callid", "$hdtime", "Staff $cookname", "Request Assigned Internal ($dep $tech)")|,'',1);
		execute_sql(qq|UPDATE `calls` SET `category` = "$dep", `ownership` = ?, `priority` = "$priority", `aw` = "1" WHERE `id` = "$callid"|,$tech); 
	
		print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n";
		exit;
	}

	if ($action eq "assign") {
		$callid = $template{'callid'} = num($q->param('callid'));	
		$sth = select_sql("SELECT `priority`,`category` FROM `calls` WHERE `id` = $callid") ;
		my ($pri, $dep) = $sth->fetchrow_array();
		$template{'pri'.$pri} = "selected";
		$sth->finish;
	
		unless (($accesslevel =~ /(^|::)$dep(::|$)/) || ($accesslevel =~ /GLOB(::|$)|^$/)) {
			$id = $callid;
			section('ticket');
			exit;
		}	

		$sth = select_sql("SELECT `id`,`nome`,`level` FROM `departments` ORDER BY `nome`");
		my (@deps,$depnome,$deplevel);
		while(my $ref = $sth->fetchrow_hashref()) {
			$depnome = $ref->{'nome'} if $dep =~ /(^|::)$ref->{'id'}(::|$)/;		
			$deplevel = $ref->{'level'} if $dep =~ /(^|::)$ref->{'id'}(::|$)/;
			push @deps, $ref->{'nome'};
		}
		$sth->finish;
		
		foreach (Controller::iUnique(\@deps)) {	
			my $selected = "selected" if $_ eq $depnome;
			$option = "<option value=\"$_\" $selected >$_</option>";
			$template{'list'} .= $option;
		}
	 
		$template{'slist'} .= "<option value=\"\">Nenhum</option>";
		$sth = select_sql("SELECT `username`, `name` FROM `staff`") ;
		while(my $ref = $sth->fetchrow_hashref()) {	
			$option = "<option value=\"$ref->{'username'}\">$ref->{'name'}</option>";
			$template{'slist'} .= $option;
		}
		$sth->finish;
		
		my @levels;
		push @levels, "<option value=\"$deplevel\">Nenhum</option>";
		$sth = select_sql("SELECT * FROM level") ;
		while(my $ref = $sth->fetchrow_hashref()) {	
			my $selected = $deplevel == $ref->{'id'} ? 'selected' : '';
			$option = "<option value=\"$ref->{'id'}\" $selected>$ref->{'nome'}</option>";
			$template{'levels'} .= $option;
		}
		$sth->finish;	
	
	
		parse("$template{'data_tpl'}/$sect/assign");
	} 

	if ($action eq "addresponse"){
		$trackno = $q->param('callid') || $q->param('ticket');
	
		my $time = time();
		execute_sql(qq|UPDATE `calls` SET `is_locked` = $staff_id WHERE `id` = "$trackno" AND `is_locked` = 0|);
		
		$sth = select_sql("SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls` WHERE `id` = ? ORDER BY `id`",$trackno);
		$number=0;
		while(my $ref = $sth->fetchrow_hashref()){	
			if (($accesslevel =~ /(^|::)$ref->{'category'}(::|$)/) || ($accesslevel =~ /GLOB(::|$)|^$/)) {			
				$template{'trackno'}	=	$ref->{'id'};
				$template{'date'}		=	$ref->{'time'};
				$template{'uname'}		=	$ref->{'username'};
				$template{'username'}	=	$ref->{'username'};
				$template{'priority'}	=	$ref->{'priority'};
				$template{'subject'}	=	my2html($ref->{'subject'});
				$template{'status'}      =   HStatus($ref->{status});
				my ($dep,$level) = Departments($ref->{'category'},"nome level");
				$template{'category'} = "$dep - ".Level($level);
				die_nice("Pedido sem departamento ou departamento sem nome, favor encaminhar para um departamento antes de responder.") if $dep eq "-";
				$template{'description'} = my2html($ref->{'description'});
				($template{'owned'}) =  split("---",Staffs($ref->{'ownership'},"name"));
				$template{'owned'} ||= "Nenhum";
				$template{'number'}		=	0;
				$template{'email'}		=	html($ref->{'email'});
				$template{'url'}		=	$ref->{'url'};
				$template{'name'}		=	$ref->{'name'};
				$mm						=	$ref->{'method'};
				$template{'title'} = sprintf($global{'epre'},$ref->{'id'})." - $template{'subject'} - ";			
	
				if ($mm eq "em") {
					$modo = "E-mail"; 
				} elsif ($mm eq "cc") {
					$modo = "Telefone";
				} else {
					$modo = "HelpDesk";
				}
	
				if ($ref->{'is_locked'} <= 0 || $staff_id == $ref->{'is_locked'}) {
					$template{'aviso'} .= qq|<br><a href="?action=rafter&cid=$trackno"><font color="#0000FF">Clique aqui para responder depois</font></a>|;
				} elsif ($ref->{'is_locked'} > 0) {
					$id = $trackno;
					section('ticket');
					exit; 
				}
				
				$template{'modo'} = $modo;
	
				if ($mm eq "em") { $template{'qt'} = "2"; }
			} else {
	        	$error= 'You do not have permission to view this call';
	        	execute_sql(qq|UPDATE `calls` SET `is_locked` = NULL WHERE `id` = "$trackno" AND `is_locked` = ?|,$staff_id);
	            push @errors, $error;
			}								
		}
		$sth->finish;
	
		$nsth = select_sql(qq|SELECT * FROM `notes` WHERE `call` = ? AND `owner` = "0" ORDER BY `id` DESC LIMIT 1|,$trackno) ;
		while(my $ref = $nsth->fetchrow_hashref()){	
			$template{'lastresp'}= my2html($ref->{'comment'});
			$template{'auth'} = split("---",Staffs($ref->{'author'},"name"));
			$template{'auth'} ||= "Nenhum";
		}
		$nsth->finish;
		
		$sth = select_sql(qq|SELECT * FROM `preans` WHERE `author` = ? OR `author` IS NULL ORDER BY `subject`|,$staff_id) ;
		while(my $ref = $sth->fetchrow_hashref()) {
 			my $text = $ref->{'text'};
 			$text =~ s/\\n/\n/g;
 			$text =~ s/\\r//g;
 			$text = html($text);
			$ddmenu .= qq|<option value="$text">$ref->{'subject'}</option>| ;
		}
		$sth->finish;
	
		$sth = select_sql("SELECT `description` FROM `calls` WHERE `id` = ?",$trackno);
		while(my $ref = $sth->fetchrow_hashref()) {
			$system->callid($trackno);
			my $category = $system->call('category');
			unless (($accesslevel =~ /(^|::)$category(::|$)/) || ($accesslevel =~ /GLOB(::|$)|^$/)) {
				$id = $trackno;
				section('ticket');
				exit; #Pode ver mas nao pode editar chamados dos outros xD
			}
			$template{'body'} = my2html($ref->{'description'});		
		}
		$sth->finish;
	
		$template{'ifpre'}   = $comments;
		$template{'preans'}  = $ddmenu;
		$template{'apreans'} = $dmenu;
		$template{'sig'}     = $sig;
		$template{'trackno'} = $trackno;
	
		parse("$template{'data_tpl'}/$sect/staffnote");
	}

	if ($action eq "editticket") {
	 my $trackno = $q->param('ticket');
		$system->callid($trackno);
		my $category = $system->call('category');
		unless (($accesslevel =~ /(^|::)$category(::|$)/) || ($accesslevel =~ /GLOB(::|$)|^$/)) {
			$id = $trackno;
			section('ticket');
			exit;
		}
	 
		$sth = select_sql("SELECT * FROM `calls` WHERE `id` = ?",$trackno);
		while(my $ref = $sth->fetchrow_hashref()) {
			$template{'call'} = my2html($ref->{'description'});
		}
		$sth->finish;
	                 
		$template{'trackno'} = $trackno;
	
		parse("$template{'data_tpl'}/$sect/editcall");
	}

	if ($action eq "rafter") {
	 my $trackno = $id = $q->param('cid');
	
		execute_sql(qq|UPDATE `calls` SET `is_locked` = 0 WHERE `id` = "$trackno"|);
	
		print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n";
		exit;
	}
	
	if ($action eq "follow") {
	 my $trackno = $id = $q->param('cid');
	
		$system->execute_sql(qq|INSERT INTO `follows` (`call`,`staff`)  VALUES  (?,?)|,$trackno,$cookname);
	
		print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n";
		exit;
	}
	
	if ($action eq "unfollow") {
	 my $trackno = $id = $q->param('cid');
	
		$system->execute_sql(qq|DELETE FROM `follows` WHERE `call` = ? AND `staff` = ?|,$trackno,$cookname);
	
		print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n";
		exit;
	}
	
	if ($action eq "spam") {
		my $trackno = $id = $q->param('cid');
		$system->callid($trackno);
		unless ($system->call('username')) {
			my @tos = split ',', $system->call('email');
			foreach my $block (grep { $system->is_valid_email($_) } @tos) {  
				#Bloqueando email
				execute_sql(qq|REPLACE INTO `blocked_email` (`id`,`address`,`type`,`count`) VALUES (NULL,?,'address','999')|,$block);
			}
	
			print "Location: $global{'baseurl'}/staff.cgi?do=delete&cid=$id\n\n";
		} else {
			#TODO AVISAR QUE É DE USUARIO E NAO PODE SER MARCADO COMO SPAM
			print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id\n\n";
		}		
		exit;	
	}

	if ($action eq "save_edit_call") {
		$id = num($q->param('ticket'));
		$text = $q->param('comments');
	
		$system->execute_sql(357,$text,$id);                       
	
		section("ticket");
	}

	if ($action eq "submitnote") {
		my $comments = $q->param('comments');
		my $fcomments = hd2html($q->param('comments'));
		die 'Nenhum texto informado!' unless $comments;
	
		my $notific =  $q->param('notify');
		my $time = time();
		my $priority   = $q->param('priority');
	
		if ($q->param('ticket_check')){ 
			$snewstatus =  $q->param('status');
			$private    =  "No";
			@checkbx = $q->param('ticket_check');
		} else {
			@checkbx = ($q->param('ticket'));	
			$snewstatus =  $q->param('newstatus');
			$private    =  $q->param('private');
			$file       =  $q->param('file'); 
		}
		$i=0;
	
		for $trackno (@checkbx) {
			$i++;
			my @set;
			push @set, qq|`ownership` = "$staff_id"| if $q->param('own') eq "1";		
			my $sth = $system->select_sql(qq|SELECT `owner` FROM `notes` INNER JOIN `calls` ON `calls`.`id` = `notes`.`call` WHERE `calls`.`id` = ? ORDER BY `notes`.`time` DESC LIMIT 1|,$trackno);
			my ($owner) = @{ $sth->fetchall_arrayref()->[0] };
			$sth->finish;						
			push @set, qq|`is_locked` = 0|;
			push @set, qq|`active` = "$time"| if $owner != 1; #not staff last
			push @set, qq|`priority` = "$priority"| if $priority;
			
			$system->callid($trackno);
			my $category = $system->call('category');
			unless (($accesslevel =~ /(^|::)$category(::|$)/) || ($accesslevel =~ /GLOB(::|$)|^$/)) {
				next;
			}
			$action	= "F"	if $snewstatus eq "Resolved";
			$action	= "A"	if $snewstatus eq "Unresolved";
			$action	= "H"	if $snewstatus eq "Hold";
	
			my $aw = $private eq "Yes" ? 1 : 0;
			push @set, qq|`aw` = "$aw"|;
			my $set = join(",",@set); 
			execute_sql(qq|UPDATE `calls` SET $set WHERE `id` = "$trackno"|);
		
		 my @chars =   ("A" .. "Z", "a" .. "z", 0 .. 9);
			$key   =  $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)];
			$template{'key'} = $key;
		
			$nsth = select_sql(qq|SELECT * FROM `notes` WHERE `call` = ? AND `visible` = 1 ORDER BY `id` DESC LIMIT 1|,$trackno);
			while(my $ref = $nsth->fetchrow_hashref()) {	
				$quoten = my2html($ref->{'comment'});	
			}
			$nsth->finish;
			
			my ($up,$filename,$fcontent);
			if (defined $file && $file ne "")  {
				($up,$filename,$fcontent) = Upload($file,0,0);
				die_nice("<li>Erro no upload do arquivo.</li>") unless $up; 			
			}
			
			$sth = select_sql(qq|SELECT `responsetime`,`signature` FROM `staff` WHERE  `username` = "$cookname"|) ;
			while(my $ref = $sth->fetchrow_hashref()) {
				$stime = $ref->{'responsetime'};
				$template{'signature'} = $ref->{'signature'};
			}
			$sth->finish;		
	
			if ($private eq "Yes") {
				$nid = $system->execute_sql(382,"1", "0", $action, $trackno, $staff_id, $hdtime, $key, $comments, $ENV{'REMOTE_ADDR'});
			} elsif ($private eq "No") {
				$nid = $system->execute_sql(382,"1", "1", $action, $trackno, $staff_id, $hdtime, $key, $comments, $ENV{'REMOTE_ADDR'});
	 
				if ($snewstatus eq "Resolved") {
					$sth = select_sql("SELECT * FROM `calls` WHERE `id` = ?",$trackno) ;
					while(my $ref = $sth->fetchrow_hashref()) {
						$logtime  = $ref->{'track'};
						$pretrack = $ref->{'an'};
						$problem  = my2html($ref->{'description'});
					}
					$sth->finish;
		
					if (!$pretrack) {	
						$totalcalls = $global->{'ssi_closed'};
						$totalcalls++;
		
						execute_sql(qq|UPDATE `settings` SET `value` = "$totalcalls" WHERE `setting` = "ssi_closed"|,'',1);
		
						$system_time	= $global{'avgtime'};
						$current_time	= time();
						$end_time		= $current_time-$logtime;
						$system_newtime	= $end_time+$system_time; 
		
						execute_sql(qq|UPDATE `settings` SET `value` = "$system_newtime" WHERE `setting` = "avgtime"|,'',1);
		
						$res_time	= $current_time - $logtime;
						$newtime	= $res_time+$stime; 
		
						execute_sql(qq|UPDATE `staff` SET `responsetime` = "$newtime" WHERE `username` = "$cookname"|,'',1); 
						execute_sql(qq|UPDATE `calls` SET `an` = "1" WHERE `id` = "$trackno"|,'',1);	
					}
				}
			}
			
			execute_sql(qq|UPDATE `files` SET `cid`="", `nid`="$nid" WHERE `id` = $up|,'',1) if $up > 0;
		
			$sth = select_sql("SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls` WHERE `id` = ?",$trackno);
			while(my $ref = $sth->fetchrow_hashref()) {
				$tid		=  $ref->{'id'};
				($qcat,$qsender)  =  Departments($ref->{'category'},"nome sender");
				$data = FormatDate(split(" ",$ref->{'time'}))." ".(split(" ",$ref->{'time'}))[1];
				$assunto = my2html($ref->{'subject'});
				$mailed = $ref->{'email'};
				$quotec = my2html($ref->{'description'});
				$time_s = $ref->{'time_spent'}; 
		
				$template{'key'} = $ref->{'ikey'};
			}
		  	$sth->finish;  
		
			$quote = qq|<DIV><FONT face=Arial size=2></FONT>&nbsp;</DIV>
						<DIV style='FONT: 10pt arial'>----------&nbsp;Última Mensagem&nbsp;----------  
						<DIV style='BACKGROUND: #e4e4e4; font-color: black'><B>De:</B> <A 
						title=$mailed href=mailto:$mailed>$mailed</A></DIV>
						<DIV><B>Para:</B> <A href=mailto:$qsender>$qcat</A> </DIV>
						<DIV><B>Data:</B> $data</DIV>
						<DIV><B>Assunto:</B> $assunto</DIV></DIV>
						<DIV><BR></DIV>|;
		
			$this_time = $q->param('time');
		       
			if (defined $this_time) {
				$new_time  = $this_time*60 + $time_s;
				execute_sql(qq|UPDATE `calls` SET `time_spent` = "$new_time" WHERE `id` = "$trackno"|);
			}
				
			if ($notific eq "Yes" && $private eq "No") {
				if (!$quoten) {
					$quote .= $quotec;
				} else {
					$quote .= $quoten;
				}
	
				$sth = select_sql("SELECT *,ADDTIME(time,'$cooktzo:00:00') as time FROM `calls` WHERE  `id` = ?",$trackno);
				while(my $ref = $sth->fetchrow_hashref()) {
					my $ok;
					$st = select_sql("SELECT * FROM `departments` WHERE `id` = ?",$ref->{'category'}) ;
					while(my $ref = $st->fetchrow_hashref()) {
						$category   = $ref->{'nome'};
						$fromemail  = $ref->{'sender'};
						$template{'signature'} ||= $ref->{'signature'};
					}
					$st->finish;
		
					$fromemail  = $global{'adminemail'} if !$fromemail;
					$recipient = $ref->{'email'} || Users($ref->{'username'},"email");
					my $subject = my2html($ref->{'subject'}); 
					if ($ref->{'username'} > 0) {
						$template{'linkcall'} = $global{'baseurl'}."/user.cgi?do=view&cid=".$ref->{'id'};
						$template{'nid'}      = $nid;
						$template{'id'}       = $trackno;
						$template{'name'} = $ref->{'name'};
						$template{'tech'} = $name;
						$template{'response'} = $fcomments;
						$template{'time'} = $timedate;
						$template{'category'} = $category;
						($template{'depto'}) = Departments($ref->{'category'},"nome");
						$template{'depto'} ||= "-";
	         
					 my $cc = $q->param('cc');
						$ok = email ( User => "$ref->{'username'}", To => "$recipient", From => "$fromemail", Cc => "$cc", Subject => ['sbj_ticket_resp',sprintf($global{'epre'},$trackno)." $cc",$subject], txt => "response", Att => "$fcontent", File => "$filename");                      
					} else { 
						($template{'depto'})  =  Departments($ref->{'category'},"nome");
						$template{'depto'} ||= "-";
						$template{'nid'}      =  $nid;
						$template{'id'}       =  $trackno;
						$template{'name'}     =  $ref->{'name'};
						$template{'tech'}     =  $name;
						$template{'response'} =  $fcomments;
						$template{'time'}   =  $timedate;
						$template{'category'} =  $category;
						$template{'quote'}    =  $quote if $q->param('inc') eq "2";
	
	  				 my $cc = $q->param('cc');
						$ok = email ( To => "$recipient", From => "$fromemail", Cc => "$cc", Subject => ['sbj_ticket_resp',sprintf($global{'epre'},$trackno)." $cc",$subject], txt => "email", Att => "$fcontent", File => "$filename");					   
					}
					$template{'aviso'} .= "<br><font color=FF0000>Error ao enviar e-mail: $ok</b></font>" if $ok ne "1";
				}
				$sth->finish;
			} 
		
			if ($snewstatus eq "Resolved") { 
				execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, ?, "$hdtime", "Staff $cookname", "Request Closed" )|,$trackno,1);
	
				$sth = select_sql("SELECT * FROM `staff` WHERE `username` = ?",$cookname);
				while(my $ref = $sth->fetchrow_hashref()){
					$callsclosed = $ref->{'callsclosed'};
				}	
				$sth->finish;
		
				$callsclosed++;
	
				execute_sql(qq|UPDATE `staff` SET `callsclosed` = "$callsclosed" WHERE `username` = "$cookname"|,'',1);
			}
			
			if ($snewstatus eq "Unresolved") {   $newstatus = "A";  }
			if ($snewstatus eq "Resolved") 	 {   $newstatus = "F";  }
			if ($snewstatus eq "Hold") 		 {   $newstatus = "H";  }
		
			if ($snewstatus eq "Resolved"){
				execute_sql(qq|UPDATE `calls` SET `status` = "$newstatus", `closedby` = "$staff_id" WHERE `id` = "$trackno"|); 
			} else {
				execute_sql(qq|UPDATE `calls` SET `status` = "$newstatus" WHERE `id` = "$trackno"|); 
			}
			
			$system->Controller::Notifier::event({  name => 'helpdesk', 
											 	object => 'call', 
											 	typeof => 'answer',
											 	action => $system->call('status') eq 'F' ? 'reopen' : undef,
											 	identifier => $system->callid,
											 	message => {  
											 				body => $fcomments }
											 	 });			
			
		}
		
		if (scalar(@checkbx) == 1) {
			$id = $checkbx[0];
			print "Location: $global{'baseurl'}/staff.cgi?do=ticket&cid=$id&aviso=".URLEncode($template{'aviso'})."\n\n"
		} else {
			print "Location: $global{'baseurl'}/staff.cgi?do=main\n\n"
		}
	}
}

sub display_ticket {
 my ($id, $username, $category, $status) = @_;

 my ($dep,$level) = Departments($category,"nome level");
 $dep ||= "-";
 $category = "$dep - ".Level($level);
 my $ticket = qq|<table width="100%" border="0" cellpadding="5" cellspacing="1"><tr bgcolor="$color"><td width="3%"><font size="1" face="Verdana"><img src="$template{'imgbase'}/$img"></font></td>
				 <td width="4%"><font size="1" face="Verdana"><input type=checkbox name=ticket_check value=$id></font></td>
				 <td width="6%"><font size="1" face="Verdana" color=$font>$otag <div align="center">$id</div>  $ctag</font></td>
				 <td width="17%"><font size="1" face="Verdana" color=$font>$otag $username $ctag</font></td><td width="21%"><font size="1" face="Verdana" color=$font><a href="?do=ticket&cid=$id">$otag $subject $ctag</a></font></td>
				 <td width="22%"><font size="1" face="Verdana" color=$font>$otag $category $ctag</font></td><td width="8%"><font size="1" face="Verdana" color=$font>$otag <div align="center">$status</div> $ctag</font></td><td width="17%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=$font>$otag $count $ctag</font></td>
				 <td width="2%"><font size="1" face="Verdana" color="$font">$awt</font></td></tr></table>
				|;
	return $ticket;
}

sub display_ticket_main {
 my ($id, $username, $category, $status, $priority) = @_;
 
 	my ($dep,$level) = Departments($category,"nome level");
 	$dep ||= "-";
 	$category = "$dep - ".Level($level);
 	$category = substr($category,0,16).'..' if length($category) > 18;
 	$username = substr($username,0,7).'..' if length($username) > 9;
 	$subject = "-" if !$subject;
 my $ticket = qq|<table width="100%" border="0" cellpadding="1" cellspacing="0" title="$count2">
				<tr bgcolor="$color">
				 <td width="15%"><font size="1" face="Verdana"><img src="$template{'imgbase'}/$img">
 				 <input type=checkbox name=ticket_check priority="$priority" value=$id><a href="?do=ticket&cid=$id">$id</a></font></td>
				 <td width="13%"><font size="1" face="Verdana" color=$font>$otag $username $ctag</font></td>
				 <td width="25%"><font size="1" face="Verdana" color=$font><a href="?do=ticket&cid=$id">$otag $subject $ctag </a></font></td>
				 <td width="25%"><font size="1" face="Verdana" color=$font>$otag $category $ctag</font></td>
				 <td width="22%" colspan = "2" align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=$font>$otag $count2 $ctag</font>
				 <font size="1" face="Verdana" color="$font">$st $awt</font></td></tr></table>
|;


	return $ticket;
}

1;
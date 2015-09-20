$DEBUG = $ARGV[1];

use MIME::Parser;
use Mail::Address;
use MIME::WordDecoder;
use Controller::Notifier;
use Encode qw/encode decode/;

my $wd = default MIME::WordDecoder;
$wd->handler('*' => 'IGNORE');


my $dir = $global{'file_path'}; 
my $parser = new MIME::Parser;
$parser->ignore_errors(1);
$parser->output_to_core(1);

my $MIME_entity = eval { $parser->parse(\*STDIN) };
my $error = ($@ || $parser->last_error);
die "Erro fatal: $error" if $error;

$header = $MIME_entity->head;
$subject = decode('MIME-Header', $header->get('Subject'));
$cto = $header->get('To');
$envelope = $header->get('Envelope-to');
$cc = $header->get('Cc');
$from = $header->get('From');
#clean
$cto =~ s/\\//g;
$cc =~ s/\\//g;
$from =~ s/\\//g; 

@to_addresses = map ($_->address(), Mail::Address->parse($cto)); 
@cc_addresses = map ($_->address(), Mail::Address->parse($cc));
@all_addresses = (@to_addresses,@cc_addresses,$envelope);
@from_addresses = Mail::Address->parse($from); #Somente 1 from

if (@to_addresses || @cc_addresses) {  
	$to = join(",",@to_addresses,@cc_addresses);
	$to =~ s/^,|,$//;
} else {
	print "nto" if $DEBUG == 1;
	exit;
}

if (@from_addresses) { 
	my $address = $from_addresses[0]->address(); #Retorna a parte do endereço
	if ($address =~ /MAILER-DAEMON|POSTMASTER/i) {
		print "mailer-daemon" if $DEBUG == 1;
		exit;
	}
	$newfrom = $address;
	if (!$newfrom) {
		print "nfrom" if $DEBUG == 1;
		exit;	
	}
} else { 
	print "nfrom" if $DEBUG == 1;
	exit;
}

if ((!$subject) || ($subject eq "")){
	email ( To => "$newfrom", From => "$global{'adminemail'}", Subject => 'sbj_no_sbj', txt => "cron/nsubject" );
	print "nsubject" if $DEBUG == 1;
	exit;
}

#~~
# Check to see if the FROM address has been banned
#~~
#To force Unicode semantics, you can upgrade the internal representation to by doing utf8::upgrade($string). 
#This can be used safely on any string, as it checks and does not change strings that have already been upgraded.
utf8::upgrade($newfrom); #Solving regex problem bellow

my ($alias, $domain) = split('@', $newfrom);
my $sth = $system->select_sql(qq|SELECT * FROM `blocked_email` WHERE ( (`address` = ? AND `type` = 'domain') OR (`address` = ? AND `type` = 'address') ) AND `count` > "$global{'blocked_limit'}"|,$domain,$newfrom);
if ($sth->rows > 0) { 
	$sth->finish;
	print "blocked" if $DEBUG == 1;
	exit; 
} # It found a result, so exit the parsing
$sth->finish;

if ($MIME_entity->parts > 0) {
	for (my $i=0;$i<$MIME_entity->parts;$i++) {
		my $subEntity = $MIME_entity->parts($i);
		my $charset = $subEntity->head->mime_attr('content-type.charset');
		
		my $ignore_plain = 0;
		my $ignore_html  = 0;

		if ($subEntity->mime_type eq 'multipart/alternative' && !$ignore_all ) {
			for (my $j=0;$j<$subEntity->parts;$j++) {
				my $subSubEntity = $subEntity->parts($j);
				$charset = $subSubEntity->head->mime_attr('content-type.charset');
				if ($subSubEntity->mime_type eq 'text/html' && $ignore_plain == 0 && !$ignore_all) {
					if (my $io = $subSubEntity->open("r")) {
						while (defined($_=$io->getline)) {    $_ =~ s/"/\"/g;  $body .= $charset && ref find_encoding($charset) ? decode($charset,$_) : $_; }
						$ignore_plain = 1;
						$ignore_all = 1;
						$ishtml = 1;
      				}
				}
			}
		} elsif ($subEntity->mime_type eq 'text/html' && $ignore_html == 0 && !$ignore_all)  {
			if (my $io = $subEntity->open("r"))	{
				while (defined($_=$io->getline))  {    $_ =~ s/"/\"/g; $body .= $charset && ref  find_encoding($charset) ? decode($charset,$_) : $_; }
				$io->close;
				$ignore_plain = 1;
				$ignore_all = 1;
				$ishtml = 1;
			}
		} elsif ($subEntity->mime_type eq 'text/plain' && $ignore_plain == 0 && !$ignore_all)  {
			if (my $io = $subEntity->open("r")) {
				while (defined($_=$io->getline)) {    $_ =~ s/"/\"/g; $body .= $charset && ref  find_encoding($charset) ? decode($charset,$_) : $_; }
				$io->close;
				$ignore_html = 1;
				$ignore_all  = 1;
				$ishtml = 0;
			}
		} else {
			my $filename = $wd->decode($subEntity->head->mime_attr('content-disposition.filename'));
			$filename = $wd->decode($subEntity->head->recommended_filename) if !$filename;
			if ($filename) {
				$filename =~ s,([/:;|]|\s|\\|\[|\])+,_,g;

				my	$i = 1;
				my ($fname, $ext) = $filename =~ m/(.*)\.(.*?)$/;
				my $file_name = $fname;
				until($assigned == 1) {
					if (-e "$dir/$file_name\.$ext") {
						$file_name = $fname . "$i";
						$i++;
					} else {
						$assigned = "1";
					}
				} 				
				$file_name .= ".$ext";
				
				if (my $io = $subEntity->open("r")) {
					my $att;
					while (defined($_=$io->getline)) { $_ =~ s/"/\"/g;  $att .= $_; }
					open (Attach, ">$dir/$file_name");
						print Attach $att; 
					close Attach;
					push @filet, $file_name;
					push @ffilet, "$dir/$file_name";

				}
			}
		}
	}
}  else  { 
	$ishtml = $MIME_entity->mime_type eq 'text/plain' ? 0 : 1;
	my $charset = $MIME_entity->head->mime_attr('content-type.charset');
	my $Entity = $MIME_entity->bodyhandle;
	if (my $io = $Entity->open("r")) {
		while (defined($_=$io->getline)) { $_ =~ s/"/\"/g;  $body .= $charset && ref  find_encoding($charset) ? decode($charset,$_) : $_; }
		$io->close;
	}
}

if ($ishtml == 1) { #Html
	Controller::html2text(\$body);#Convert html to text plain
	
	print 'html' if $DEBUG == 1;
} else { #text plain
	print 'text' if $DEBUG == 1;
	$body = html($body);
	$body =~ s/\n/<br>/g;
}	
$body =~ s/^(.*)----- Original Message.*$/$1/s;
$body =~ s/^(.*)----- Mensagem encaminhada.*$/$1/s;
$body =~ s/^(.*)Em.+?,.+?<.+?> escreveu:.*$/$1/s; #Em 25 de abril de 2011 14:38, Comercial - Empresa <comercial@empresa> escreveu:

($epreS,$epreE) = split('%d',$global{'epre'}); #start,end
($OepreS,$OepreE) = split('%d',$global{'epreg_old'}); #start,end
$subject =~ s/\n//g;

#~~
# Is this a response to a call?
#~~
if (($global{'epre'} && $subject =~ /\Q$epreS\E(\d+)\Q$epreE\E/) || ($global{'epreg_old'} && $subject =~ /\Q$OepreS\E(\d+)\Q$OepreE\E/)) {
	$callid = $1;
	$callno = $callid;
	#$callno =~ s/$epre-//g;
	$callno = num($callno);
	$system->callid($callno);	
	my $time = time();	

	$sth = select_sql(qq|SELECT `username`, `email`, `status`, `category`, `subject` FROM `calls` WHERE `id` = ?|,$callno);
	my ($user,$callemail,$status,$category,$subj) = $sth->fetchrow_array();

	$system->uid($user);
	$callemail = lc($callemail);
	$callemail ||= $system->user('emails');
	$newfrom   = lc($newfrom);
	if ($callemail !~ m/$newfrom(?:;|,|$)/i) {
		email ( To => "$newfrom", From => "$global{'adminemail'}", Subject => ['sbj_diffmail',$callid], txt => "cron/diffmail" );
		print "diffmail" if $DEBUG == 1;
		exit;
	} 
	
	if ($status eq "F") {
		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, ?, "$hdtime", "User", "Request Re-Opened" )|,$callno,1);
		execute_sql(qq|UPDATE `calls` SET `status` = "A", `aw` = "1", `active` = "$time" WHERE `id` = ?|,$callno);#, `priority` = 1, nao aguentou ficar voltando chamado pro n1.
	} else {
		my $sth = select_sql(qq|SELECT `owner` FROM `notes` INNER JOIN `calls` ON `calls`.`id` = `notes`.`call` WHERE `calls`.`id` = ? ORDER BY `notes`.`time` DESC LIMIT 1|,$callno);		
		my ($owner) = @{ $sth->fetchall_arrayref()->[0] };	
		my $sql = qq|UPDATE `calls` SET `status` = "A", `aw` = "1"|;
		$sql .= qq|, `active` = "$time" | if $owner != 0;
		$sql .= qq|WHERE `id` = ?|;
		execute_sql($sql,$callno);
	}
	
	my @chars =  ("A" .. "Z", "a" .. "z", 0 .. 9);
	$key = $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)];          
	my $note = $system->execute_sql(382,"0", "1", undef, $callno, "$user", "$hdtime", "$key", "$body", "IP Não Informado");
	
	my $i = 0;
	foreach $filet (@filet) {
		$system->execute_sql(403,undef,$note,$filet,$ffilet[$i]);
		$i++;
	}

	$category =~ s/(::)?$/::/;
	$template{'tarefa'} = "Pedido Respondido";
	$template{'referencia'} = "ID $callno";
	notify($category,"",'sbj_alert_response');
	
	$system->Controller::Notifier::event({  name => 'email_arrive', 
										 	object => 'call', 
										 	typeof => 'answer',
										 	action => $status eq 'F' ? 'reopen' : undef,
										 	identifier => $system->callid,
										 	email => {  from => $newfrom,
										 				to => $to,
										 				subject => $subject,
										 				body => $body }
										 	 });
	exit;
} else {
	$sth = $system->select_sql(qq|SELECT `address`,`category` FROM `em_forwarders` WHERE `address` IN (|. join(',',('?')x@all_addresses) .qq|) LIMIT 1|,@all_addresses);
	($fromemail,$category) = $sth->fetchrow_array();
	$fromemail ||= $global{'adminemail'};
	if ($sth->rows == 0) {
		if ($to =~ $global{'adminemail'} || $global{'adminemail'} =~ $to) {
			print "adminemail" if $DEBUG == 1; 
			exit;
		};
		
		#Bloqueando email
		execute_sql(qq|INSERT INTO `blocked_email` (`address`,  `type`,  `count`) VALUES ( ?, 'address', 1) ON DUPLICATE KEY UPDATE `count` = `count`+1|,$newfrom);
		
		$template{'emailto'} = join ',', @all_addresses;
		email ( To => "$newfrom", From => "$global{'adminemail'}", Subject => 'sbj_nofwd', txt => "cron/nfwd" );
		print "nfwd <$to>" if $DEBUG == 1;
		exit;
	}
	$sth->finish;

	my @chars =  ("A" .. "Z", "a" .. "z", 0 .. 9);
    $key = $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)] . $chars[rand(@chars)];          
	$current_time = time();
	
	if ($global{'ereqreg'} == 1) {
		$sth = select_sql(qq|SELECT `username`,`name`,`lcall` FROM `users` WHERE `email` LIKE CONCAT('%',?,'%') AND `status` != 'CC'|,$newfrom); 
		while(my $ref = $sth->fetchrow_hashref()) {
			$username	= $ref->{'username'};
			$name		= $ref->{'name'}; 
			$email		= $ref->{'email'};
		 my $newtime	= $ref->{'lcall'};
			$newtime	= $newtime + $global{'floodwait'};
			if ($newtime > $current_time) { 
				print "flood" if $DEBUG == 1;
				exit;
			};
		}
     	
		if ($sth->rows == 0) {
 			email ( To => "$newfrom", From => "$global{'adminemail'}", Subject => 'sbj_noreg', txt => "cron/nreg" );
 			print "nreg" if $DEBUG == 1;
			exit;
		}
		$sth->finish;
	
		my $sid;
		$sth = select_sql(qq|SELECT `id` FROM `servicos` WHERE `username` = ? AND `status` != 'F' AND `status` != 'S' GROUP BY `username` HAVING count(*) = 1|,$username);
		while(my $ref = $sth->fetchrow_hashref()) {
			$sid	= $ref->{'id'};
		}
		
		$trackno = $system->execute_sql(344,"A", "$username", "$newfrom", "1", $sid, "$category", "$subject", "$body", "$hdtime", undef, undef, "em", "$current_time", "$current_time", "1", "0", "0", "0");
		execute_sql(qq|INSERT INTO activitylog VALUES ( NULL, $trackno, "$hdtime", "User", "Request Logged" )|,'',1);
		#print $body;
	} else {
		$sth = select_sql(qq|SELECT `username`,`name` FROM `users` WHERE `email` LIKE CONCAT('%',?,'%') AND `status` != 'CC'|,$newfrom);
		($username,$name) = $sth->fetchrow_array();
		my $registered = "no" if $sth->rows == 0; 
		$sth->finish;

		$trackno = $system->execute_sql(344,"A",$username,$newfrom, "1", "",$category,$subject,$body,$hdtime, undef, undef,"em",$current_time,$current_time, "1", "0", "0", "0");
		execute_sql(qq|INSERT INTO `activitylog` VALUES ( NULL, $trackno, "$hdtime", "User", "Request Logged" )|,"",1);
	}
	my $i = 0;
	foreach $filet(@filet) {
		$system->execute_sql(403,$trackno,undef,$filet,$ffilet[$i]);
		$i++;
	}
	
	$template{'tarefa'} = "Novo e-mail recebido";
	$template{'referencia'} = "ID $trackno";
	notify($category,"",'sbj_alert_newticket');
	
	$system->callid($trackno);
	$system->Controller::Notifier::event({  name => 'email_arrive', 
										 	object => 'call', 
										 	typeof => 'new',
										 	action => 'open',
										 	identifier => $system->callid,
										 	email => {  from => $newfrom,
										 				to => $to,
										 				subject => $subject,
										 				body => $body }
										 	 });		
}

$parser->filer->purge();

1;
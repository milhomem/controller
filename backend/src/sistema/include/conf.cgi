# Acesso ao banco
require "../db.cfg";

# Adicionar domínio no cookie?
our	$cdomain = '';

# Adicionar o ip no cookie?
our	$IP_IN_COOKIE = 0;		# 1 = Sim
							# 0 = Não
# Sistema Operacional
our	$WIN = $ENV{'OS'} =~ /windows/i ? 1 : 0;

# Habilitar linguagem
our $enablelang = 1;  

# E-mail Remetente
#our	$ticketad = 'noreply@is4web.com.br';

# Extenções permitidas para envio de arquivos
our	%file_types = (
					txt   => "1",
					gif   => "1",
					html  => "1",
					htm   => "1",
					jpg   => "1", 
					jpeg  => "1",
					png   => "1",
					bmp   => "1",
					pdf   => "1",
					doc   => "1",
					zip   => "1",
					rar   => "1",
					db    => "1",
					TXT   => "1",
					GIF   => "1",
					HTML  => "1",
					HTM   => "1",
					JPG   => "1", 
					JPEG  => "1",
					PNG   => "1",
					BMP   => "1",
					PDF   => "1",
					DOC   => "1",
					ZIP   => "1",
					RAR   => "1",
					asp   => "1",
					ASP   => "1",
					php   => "1",
					PHP   => "1",
					pl    => "1",
					PL    => "1",
					cgi   => "1",
					CGI   => "1",
					aspx    => "1",
					ASPX    => "1",
					sql    => "1",
					SQL    => "1",
					DOCX => "1",
					docx => "1",
					XLS => "1",
					xls => "1",
					xlsx => '1',
					XLSX => '1',
					RTF => "1",
					rtf => "1",
					LOG => "1",
					'log' => "1",
					EML => "1",
					eml => "1",
					csv => "1",
					CSV	=> "1",
					ini => "1",
					INI => "1",
					HTML => "1",
					html => "1",
					mht => "1",
					MHT => "1",
					mp3 => "1",
					MP3 => "1",
					wav => "1",
					WAV => "1",
					msg => "1",
					MSG => "1",
					crt => "1",
					CRT => "1",
					pem => "1",
					PEM => "1",
					csr => "1",
					CSR => "1",	
					);

#### CONSTANTS #####
use constant {
	TICKETS_OWNER_USER => 0,
	TICKETS_OWNER_STAFF => 1,
	TICKETS_OWNER_SYSTEM => 2,
	TICKETS_OWNER_ACTION => 3,
	TICKETS_METHOD_SYSTEM => 'ss',
	TICKETS_METHOD_HD => 'hd',
	TICKETS_METHOD_EMAIL => 'em',
	TICKETS_METHOD_CALL => 'cc',
	VISIBLE => 1,
	HIDDEN => 0,				
};

#########
#Modules
#########
use Date::Simple;
require "include/lib/cpanel.cgi";
require "include/lib/helm.cgi";
require "include/lib/registroBR.cgi" if !$WIN;
require "include/lib/sms.cgi";

sub date {
	my $z;
	$z = Date::Simple->new(@_);
	return $z;
}

sub today {
	my $y;
	$y = Date::Simple->new;
	return $y;
}

sub cookies { #(0,exp[ymd],domain,name:value...)
my $frame=2;
my ($package, $filename, $line, $sub) = caller($frame++);
	my $ssl = shift;
	my $pre = "Set-Cookie: ";
	my $exp = "+".shift;
	my $domain = shift;	
	foreach (@_) {
		my ($name,$value) = split(/\:/,$_);
		print $pre;
		print $q->cookie(-name=>$name,-value=>$value,-path=>'/',-expires =>$exp,-domain => $domain);
		print "$package, $filename, $line, $sub";
		print " secure" if $ssl;
		print "\n";
	}
}

sub get_vars 
{
 my %global;
 my $statement = 'SELECT * FROM `settings`'; 
 my $sth = $dbh->prepare($statement);
	$sth->execute();
	while(my $ref = $sth->fetchrow_hashref()) {
	 my $setting = $ref->{'setting'};
		$global{$setting} = $ref->{'value'};
	}  
	$sth->finish;
	return %global;
}

sub get_skin 
{
 my ($skin, $value) = @_; 
 my $statement = 'SELECT * FROM `skins` WHERE `name` = ? AND `setting` = ?'; 
 my $sth       = $dbh->prepare($statement);
	$sth->execute( $skin, $value );
	while(my $ref = $sth->fetchrow_hashref()) { 
		$value = $ref->{'value'};
	}  
	$sth->finish;
	return $value;
}

sub get_setting 
{
 my $sql = "@_"; 
 my $value;
 my $statement = 'SELECT * FROM `settings` WHERE `setting` = ?'; 
 my $sth       = $dbh->prepare($statement);
	$sth->execute( $sql );
	while(my $ref = $sth->fetchrow_hashref()) { 
		$value = $ref->{'value'};
	}  
	$sth->finish;
	return $value;
}

sub load_rights 
{
#usage: username | right => value
#        100     | users => RIECF
#	$var = "LEITURA" if $var eq 'R';
#	$var = "INCLUIR" if $var eq 'I';
#	$var = "EXCLUIR" if $var eq 'E';
#	$var = "MODIFICAR" if $var eq 'C';
#	$var = "TOTAL" if $var eq 'F';
#	$var = "LISTAR" if $var eq 'L';

 my $n = shift; 
 my %result;

 my $stsn = 'SELECT * FROM `security` WHERE `username` = ?';
 my $sth = $dbh->prepare($stsn);
    $sth->execute($n);
	while(my $ref = $sth->fetchrow_hashref()) {
		$result->{$ref->{'right'}} = $ref->{'value'};
	}
    $sth->finish; 

	return ($result->{'users'},$result->{'invoices'},$result->{'staffs'},$result->{'tickets'},$result->{'plans'},$result->{'services'},$result->{'tools'},$result->{'configs'},$result->{'super'},
			$result->{'usersd'},$result->{'invoicesd'},$result->{'staffsd'},$result->{'ticketsd'},$result->{'plansd'},$result->{'servicesd'},$result->{'toolsd'},$result->{'configsd'},$result->{'superd'});
}

sub die_nice 
{
 my $error = shift() . $system->clear_error;
 my $hide = shift;

 my $msg = $hide ? $LANG{1} : $error;	 
	print "Content-type: text/html\n\n"; 	
	unless ($ajax) {	
		print qq|<html><head><title>Controller - Erro ao executar</title></head><body bgcolor="#FFFFFF"><p>&nbsp;</p><table width="400" border="0" cellspacing="1" cellpadding="0" align="center">
				<tr bgcolor="#666666"><td colspan="3"><table width="100%" border="0" cellspacing="1" cellpadding="0"><tr bgcolor="#E0E6ED"><td><table width="100%" border="0" cellspacing="1" cellpadding="4">
				<tr><td rowspan="2" width="21%"><div align="center"><img src="$template{'imgbase'}/error.gif"></div>
				</td><td width="79%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>ERRO </b></font></td></tr><tr><td width="79%" height="33"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">$msg</font></td>
				</tr></table></td></tr></table></td></tr></table></body></html>
				|;
	} else {
		print "Die: ".URLEncode($msg);
	}
	$template{'error'} = $msg;	
	
 	email (To => "$global{'controller_mail'}", From => "$global{'adminemail'}", Subject => "Die_nice", Body => "$error" );

	$sth->finish if $sth;
	exit; 
}

sub execute_sql {
 my ($sql,$var,$skip) = @_;

	die('Erro na integração') unless $system;
	$sql =~ s/"/'/g;
	
	local $Controller::SWITCH{skip_log} = 1 if $skip;
	my $insertid = $var 
		? $system->execute_sql($sql,$var)
		: $system->execute_sql($sql,-1);
	return $insertid;
}

sub select_sql {
 @_ = @_; #Bug 
 my ($sql,$var) = @_;
 my $tatement = qq|$sql|; 
 my $sth = $dbh->prepare($tatement);
	if ($var) {
		$sth->execute("$var") || die_nice("Erro em select_sql($DBI::errstr;) ****$tatement | $var");
	} else {
		$sth->execute() || die("Erro em select_sql($DBI::errstr;) ****$tatement");
	}
	return($sth);  
}

sub script_fatal 
{
 my $error = "@_";
 my $header = "Content-type: text/html\n\n";
	$header .= qq|<html><head><title>Erro Fatal</title><meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
			</head><body bgcolor="#FFFFFF"><p>&nbsp;</p><table width="496" border="0" cellspacing="0" cellpadding="0" align="center"><tr><td colspan="3"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Erro Fatal</b></font></td></tr><tr><td colspan="3" height="11">&nbsp;</td></tr><tr><td colspan="3" height="6"><font face="Courier New, Courier, mono" size="2">$error</font></td></tr><tr> <td colspan="3" height="2">&nbsp;</td></tr><tr> <td colspan="3" height="40"> <table width="60%" border="0" cellspacing="0" cellpadding="0" align="center"> <tr> <td width="50%"><b><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="javascript:history.back(1)">BACK</a></font></b></td><td width="50%"><div align="right"><b><font size="2" face="Verdana, Arial, Helvetica, sans-serif"></font></b></div></td></tr></table></td></tr></table><p align="center">&nbsp;</p></body></html>
			|;
	print "$header";
	exit; 
}

sub email
{
 return if $system->{'ERR'};
 my %contact = @_;
 
 $system->template($_,$template{$_}) foreach keys %template;
 return $system->email(@_) || $system->clear_error();
}

sub sms 
{  
#usage
#sms ( User => "1000", txt => "arquivo");
#sms ( User => "1000", Msg => "texto");
 my %contact = @_;

	if ($global{'use_sms'} == 1) {
		if ($contact{'txt'}){
			my $data_tpl = get_skin("$theme","data_tpl");
			if (-e "$data_tpl/sms/$contact{'txt'}.txt") {
				open (MAILTPL, "$data_tpl/sms/$contact{'txt'}.txt");
					while (<MAILTPL>) {
						s/\{(\S+?)\}/$template{$1}/gi;
						lang_parse();
						$body .= $_;
					}  
				close(MAILTPL);
				$contact{'Msg'} = $body;
			} else {
				$contact{'Msg'} = "Arquivo não encontrado, informe ao seu provedor.";
			}
		}
	
		$contact{'Tel'} = num(Users($contact{'User'},"telefone"));
		($contact{'Ddi'}) = split(" - ",Country(Users($contact{'User'},"cc"),"call"));
		$contact{'Ddi'} ||= "55";#Brasil
	 my	($ok,$result) = sms_send("$contact{'Ddi'}","$contact{'Tel'}","$contact{'Msg'}");
	
		if ($result =~ "Numéro não confere") {
			$ok = 1;
			$contact{'Msg'} = $result;
		}
	
		$result = $ok if $ok;
		
		&get_time();
		$dbh->do(qq|INSERT INTO `log_mail` VALUES (NULL,?,?,?,?,?,?,?,?,?)|,undef,"$cookname","$contact{'User'}", "$global{'sms_host'}",  "$contact{'Ddi'}$contact{'Tel'}", "", "$contact{'Msg'}", "$timemysql", "$timenow24",$result) if $contact{'User'};
		return $ok;
	}
}

sub grab_emails
 {
	use Mail::POP3Client;

	my $AMODE = "PASS";            	      
	my $query = "SELECT * FROM `popservers`";
	my $sth   = select_sql(qq|$query|);
	while (my $ref = $sth->fetchrow_hashref) {
		my $pop_server = new Mail::POP3Client( USER   =>  $ref->{'pop_user'},
	   				        PASSWORD  =>  $ref->{'pop_password'},
					        HOST      =>  $ref->{'pop_host'},
					        PORT      =>  $ref->{'pop_port'},
					        AUTH_MODE =>  $AMODE,
					        TIMEOUT => 60,
					        DEBUG     =>  "0");
		local *STDERR;
		open(STDERR, ">".$system->setting('app')."/output");

		my $state = $pop_server->State();

		return "Sorry, I was unable to establish a connection with $ref->{'pop_host'}: $state" unless ($state eq "TRANSACTION");

		my $total = $pop_server->Count();
		my $count = 0;# = $total;
		my $i;
		for ($i = 1; $i <= $total && $i <= 50; $i++) {
			my $line;			
			eval {
				local $SIG{'__DIE__'} = undef;   
				$|=1;
				open (HPDESK, "|perl email.cgi HPDESK") or die "Unable to fork script: $!";
					$line = $pop_server->HeadAndBody($i);
					print HPDESK $line;
				close HPDESK || die "bad HPDESK: $! status: $?";
				open (HPDESKOUT, $system->setting('app').'/output') or die "Unable to open file: $!";
				my @out = <HPDESKOUT>;
				close HPDESKOUT || die "bad HPDESKOUT: $! $?";				
				email (To => "$global{'controller_mail'}", From => "$global{'adminemail'}", Subject => "Erro ao ler o email", Body => "Error: ".join('<br>',@out), Att => "$line", File => 'Email-'.time().'.txt' ) if scalar @out;				
				$pop_server->Delete($i);
			};
			if ($@) {
				$count++;
				print "Could Not Close PIPE: $@<BR>";				
				email (To => "$global{'controller_mail'}", From => "$global{'adminemail'}", Subject => "Erro ao ler o email", Body => "Bad Status: $@", Att => "$line", File => 'Email-'.time().'.txt' );
				$pop_server->Delete($i);
			}
		}
		$pop_server->Close() or die "Error closing connection: $!";
		print (($i - $count - 1)." de $total Emails Downloaded from $ref->{'pop_user'} \@ $ref->{'pop_host'}\n");
	}
	print "You have not set any POP retrieval up\n" if !$sth->rows;
}

sub get_data
{
 my $sql = "@_";
 my $sth = $dbh->prepare($sql);
	$sth->execute();
	while(my $ref = $sth->fetchrow_hashref()) {
		for (keys %$ref) {
			$template{$_} = $ref->{$_};
		}
	}
}

sub script_error
{
 my $error = "@_";
	print "Content-type: text/html\n\n";
	print qq~<html><head><title>Erro</title>
			<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
			</head><body bgcolor="#FFFFFF"><p>&nbsp;</p><table width="600" border="0" cellspacing="0" cellpadding="0" align="center"><tr><td colspan="3"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Controller: 
			<font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b><font color="#990000">Erro de </font></b></font><font color="#990000">Script </font></b></font></td></tr><tr> <td>&nbsp;</td><td>&nbsp;</td><td>&nbsp;</td></tr><tr> 
			<td colspan="3"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Controller n&atilde;o pode ser rodado pelos seguintes erros:</font></td>
			</tr><tr><td colspan="3" height="40"><font face="Courier New, Courier, mono" size="2"><br>$error<br></td></tr></table><p align="center">&nbsp;</p></body></html>
			~;
	exit;
}

sub notify
{
	my ($category,$exclude,$subject) = @_;
	my $statment = qq|SELECT * FROM `staff` WHERE |;
	$statment .= qq|`username` != "$exclude" AND | if $exclude;
	$statment .= qq|(`access` LIKE '%$category::%' OR `access` LIKE '%GLOB::%')|;

	my $sth = select_sql($statment); 
	while(my $ref = $sth->fetchrow_hashref()) {
		$tos .= $ref->{'email'}."," if ($ref->{'notify'} eq "1");
	}
	$sth->finish;
	$tos =~ s/\,$//;
	
	eval { email ( To => "$tos", From => "$global{'adminemail'}", Subject => "$subject", txt => "notify") if $tos; };
	
	return $@;
}

#LANGUAGE
our @languages = ("en", "sw", "no", "es", "fr", "gm", "pt");

our %langdetails = (
	en     =>   "English",
	sw     =>   "Swedish",
	no     =>   "Norwegian",
	es     =>   "Spanish",
	fr     =>   "French",
	gm     =>   "German",
	pt     =>   "Portuguese"
);

#FORMATAÇÕES
sub get_time 
 {
	$global{'timeoffset'} = "0" if !$global{'timeoffset'};
	my $timeoffset = shift;
	my @days   = ('Domingo','Segunda','Terça','Quarta','Quinta','Sexta','Sabado');
	my @months = ('Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro');
	our ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time + (3600*$timeoffset));
	$hour = "0$hour" if ($hour < 10);
	$min  = "0$min" if ($min < 10);
	$sec  = "0$sec" if ($sec < 10);
	our $time24 = "$hour:$min";
	our $timenow24 = "$hour:$min:$sec";
    if ($hour >= 12) { $variable = "P.M."; }  else { $variable  = "A.M."; }
	if ($hour == 0) { $hour = 12; }
	if ($hour > 12) { $hour -= 12; }
	$year = 1900 + $year;
	if ($mday eq "1") {       $hy = "st"; 
	} elsif ($mday eq "21") { $hy = "st";
	} elsif ($mday eq "31") { $hy = "st"; 
	} elsif ($mday eq "2")  { $hy = "nd";
	} elsif ($mday eq "22") { $hy = "nd"; 
	} elsif ($mday eq "3")  { $hy = "rd"; 
	} elsif ($mday eq "23") { $hy = "rd";
	} else { $hy = "th"; }
	    our $day      = $days[$wday];
		our $month    = $months[$mon];
		our $month_no = ++$mon;
		our $date     = "$mday$hy";
		our $date_no  = $mday;
		our $time     = "$hour:$min:$sec $variable";
		our $time_sv  = "$hour:$min $variable";
		our $time_var = "$hour:$min:$sec";
		our $time_sec = "$hour:$min";
		$date_no  = "0$date_no" if ($date_no < 10);
		$month_no = "0$month_no" if ($month_no < 10);

		#FORMATO DA HORA
		our $hdtime = "$year-$month_no-$date_no $timenow24";
		our $timedate = "$time_sec $date_no/$month_no/$year";
		our $timenow = "$time ($date_no/$month_no/$year)";
		our $timemysql = "$year-$month_no-$date_no";
		our $datelinux = "$year/$month_no/$date_no";
		our $datenow = "$date_no/$month_no/$year";
		our $timegmt = "$day, $date-$month-$year $time GMT";
}

sub timediff {
	my ($maior,$menor) = @_;
	
	my $difference  =  $maior - $menor;
	
	my ($count,$diff);
	
	$count = int($difference / 86400);
	$diff .= "$count dia" if $count == 1;
	$diff .= "$count dias" if $count > 1;
	$difference %= 86400;
	$count = int($difference / 3600);
	$diff .= " $count hora" if $count == 1;
	$diff .= " $count horas" if $count > 1;
	$difference %= 3600;	
	$count = int($difference / 60);
	$diff .= " $count minuto" if $count == 1;
	$diff .= " $count minutos" if $count > 1;
	$difference %= 60;	
	$count = $difference;
	$diff .= " $count segundo"  if $count < 1;
	$diff .= " $count segundos" if $count > 1;
	
	return trim($diff);
} 

sub FormatDate 
{
	my $dado = shift;
	$dado =~ s/ .*//; #tira o tempo
	@data = split(/-/,$dado); 

	my $formato = $global{'dataformat'};
	#put in perl regex
	my $dsep = $formato;
	$dsep =~ s/[ymd]//g;
	$dsep = "\\".substr($dsep,0,1);

	my @formato = split(/$dsep/,$formato);
	${substr($formato[0],0,1)."t"} = length($formato[0]);
	${substr($formato[1],0,1)."t"} = length($formato[1]);
	${substr($formato[2],0,1)."t"} = length($formato[2]);
	$yt = 4 if $yt > 4;	$mt = 2 if $mt > 2;	$dt = 2 if $dt > 2;
	$data = $formato;
	$data =~ s/d+/substr("00".$data[2],-$dt)/e;
	$data =~ s/m+/substr("00".$data[1],-$mt)/e;
	$data =~ s/y+/substr("0000".$data[0],-$yt)/e;
	$formato =~ s/[myd]/0/g; #anula pra comparar
	$data = "" if $data eq $formato || $data =~ m/$dsep$dsep/;

	return "$data";
}

sub DiaMes 
{
	my $data;
	my $dia = sprintf("%02d",shift);
	my $mes = sprintf("%02d",shift);
	@31=("01","03","05","07","08","10","12");
	@30=("04","06","09","11");
	@28=("02");

	if (grep(/^$mes$/,@31)) {
		$data=$dia;
		$data=31 if $dia > 31;
	} elsif (grep(/^$mes$/,@30)) {
		$data=$dia;
		$data=30 if $dia > 30;
	} elsif (grep(/^$mes$/,@28)) {
		$data=$dia;
		$data=28 if $dia > 28;	
	}

	return "$data";
}

sub Extra {
	my $venc = shift;
	my $mult = shift;

	my ($ano,$mes,$dia)=split(/-/,$venc);
	my $case = $mult/30;
	my $sano = 0;
	until ($case<=12) {
		$case-=12;
		$sano++;
	}
	my $compar = 13-$case;
	$ano+=$sano;
	$ano++ if $mes >= $compar;
	$mes = $mes-12+$case if $mes >= $compar;
	$mes += $case if $mes < $compar;
	$mes = "0$mes" if ($mes < 10);
	my $extra = date("$ano-$mes-$dia") - date($venc) - $mult;
	
	return ($extra);
}

sub mod {
	my ($a,$b) = @_;
	
	$a -= int($a/$b);
	
	return $a;	
}

sub SomaMes {
	my $atual = shift;
	my $meses = shift;

	return("0000-00-00") if $atual eq "0000-00-00";
	my $dias = mod($meses,1) * 30;
	$meses = int($meses);
	
	my ($ano,$mes,$dia)=split(/-/,$atual);
	my $sano = 0;
	until ($meses<=12) { 
		$meses-=12;
		$sano++;
	}
	until ($meses >= 0) { #subtrai anos
		$meses += 12;
		$sano--;
	}	
	my $compar = 13-$meses;
	$ano+=$sano;
	$ano++ if $mes >= $compar;
	$mes = $mes >= $compar ? $mes-12+$meses : $mes+$meses;
	$dia = DiaMes("$dia","$mes"); #ultimo dia do mês somado os meses
	$compar = $dia+$dias;
	$dia = $compar > DiaMes(31,"$mes") ? int $compar-DiaMes(31,"$mes") : int $compar;
	$mes++ if $compar > DiaMes(31,"$mes");
	$mes = substr("00$mes",-2) if ($mes < 10);
	$dia = substr("00$dia",-2) if ($dia < 10);
	
	return ("$ano-$mes-$dia");
}

sub DiaProximo {
	my $dd = num(shift);
	my $atual = shift;
	my $true = 0;
	return $atual if $dd < 1 || $dd > 31; #vencimento inválido
	my ($ano,$mes,$dia)=split(/-/,$atual);
	
	$dia = &DiaMes("$dd","$mes");

	my $dif = date("$ano-$mes-$dia") - date($atual);

	if ($dif > 15) {
		$ano -= 1 if $mes == 1;
		$mes -= 1;
		$mes = 12 if $mes == 0;
		$mes = "0$mes" if ($mes < 10);
		$dia = &DiaMes("$dd","$mes");
	}

	if ($dif < -15) {
		$ano += 1 if $mes == 12;
		$mes += 1;
		$mes -= 12 if $mes > 12;
		$mes = "0$mes" if ($mes < 10);
		$dia = &DiaMes("$dd","$mes");
	}

	my $proximo = "$ano-$mes-$dia";
	
	return ($proximo);
}

sub Desconto {
	my ($plano,$pg) = @_;
 	my	$r;

	my $statement = qq|SELECT `valor` FROM `descontos` WHERE `plano` = ? AND `pg` = ?| ; 
	my $sth = $dbh->prepare($statement);
	$sth->execute($plano,$pg);
	($r) = $sth->fetchrow_array();
    $sth->finish;
	return ($r);	
}

sub CurrencyFormatted
{
	my $n = shift;
	my $m = shift;
	my $minus = $n < 0 ? '-' : '';
	my $dez = $global{'decimal'} || $system->setting('decimal');
	my $mil = $global{'milhar'} || $system->setting('milhar');
	my $moeda = $global{'moeda'} || $system->setting('moeda');
	
	$n = abs($n);
	$n = int(($n + .005) * 100) / 100;
	$n .= '.00' unless $n =~ /\./;
	$n .= '0' if substr($n,(length($n) - 2),1) eq '.';
    chop $n if $n =~ /\.\d\d0$/;
	chop $n if $n =~ /\,\d\d0$/;
	#colocar separador decimal
	$n =~ s/\./$dez/;
	#colocar separador milhar
	my $cs = 7;#mil
	while (length(substr($n,(length($n) - $cs),4)) eq 4) {
		$p = substr($n,(length($n) - ($cs-1)));
		$n =~ s/$p//g;
		$n .= $mil.$p;
		$cs += 4;
	}
	
	!$m ? return "$moeda $minus$n" : return "$minus$n";
}

sub Floatsql {
	my $value = shift;
	my $sep = shift;
	my @value = split(/$sep/,$value);
	my $ret;

	my $dez = "\\".$global{'decimal'};
	my $mil = "\\".$global{'milhar'};
	
	foreach (@value) {
	 my ($minus) = $_ =~ /^(-)/;
		s/$mil//g;
		s/$dez/\./;
		s/[^\d.]//g;
		$ret .= $minus.$_.",";
	}
	$ret =~ s/\,$//;

	return $ret;	
}

sub Datesql {
	my $value = shift;
	my $sep = shift || ";";
	my @value = split(/$sep/,$value);
	my $ret;

	my $formato = $global{'dataformat'};
	#put in perl regex
	my $dsep = $formato;
	$dsep =~ s/[ymd]//g;
	$dsep = "\\".substr($dsep,0,1);

	my @formato = split(/$dsep/,$formato);
	foreach (@value) {
		my @tmp = split(/$dsep/,$_);
		${substr($formato[0],0,1)} = $tmp[0];
		${substr($formato[0],0,1)."t"} = length($formato[0]);
		${substr($formato[1],0,1)} = $tmp[1];
		${substr($formato[1],0,1)."t"} = length($formato[1]);
		${substr($formato[2],0,1)} = $tmp[2];
		${substr($formato[2],0,1)."t"} = length($formato[2]);
		$yt = 4 if $yt > 4; $mt = 2 if $mt > 2; $dt = 2 if $dt > 2;
		$ret .= substr(today->year,0,4-$yt).substr("0000".$y,-$yt)."-".substr("00".$m,-$mt)."-".substr("00".$d,-$dt).",";
	}
	$ret =~ s/\,$//;

	return $ret;	
}

sub Round 
{
	my $b = shift;
	my $minus = $b < 0 ? -1 : 1; 
	$b = int((abs($b) + .005) * 100) / 100 * $minus;
	
	return sprintf("%.2f", $b);	
}

#SUBSTITUIÇÕES
sub racentos {
	my $word = shift;
	
	$word =~ s/[àáâãä]/a/g;
	$word =~ s/[èéêë]/e/g;
	$word =~ s/[ìíîï]/i/g;
	$word =~ s/[òóôõö]/o/g;
	$word =~ s/[ùúûü]/u/g;
	$word =~ s/[ÀÁÂÃÄ]/A/g;
	$word =~ s/[ÈÉÊË]/E/g;
	$word =~ s/[ÌÍÎ]/I/g;
	$word =~ s/[ÒÓÔÕÖ]/O/g;
	$word =~ s/[ÙÚÛÜ]/U/g;
	$word =~ s/Ç/C/g; $word =~ s/ç/c/g;
	$word =~ s/Ñ/N/g; $word =~ s/ñ/n/g;

	return $word;
}

sub lang_parse {
	$_ =~ s/(\%(\S*?)\%)/$LANG{$2} ? $LANG{$2} : ( $2 ? $2 : '%')/ge;
}

sub template_parse {	
	$_ =~ s/\{(\S+?)\}/$template{$1}/gi;
}

sub rights {
	my $var = shift;
	#[RIECFL]
	
	$var = "LEITURA" if $var eq 'R';
	$var = "INCLUIR" if $var eq 'I';
	$var = "EXCLUIR" if $var eq 'E';
	$var = "MODIFICAR" if $var eq 'C';
	$var = "TOTAL" if $var eq 'F';
	$var = "LISTAR" if $var eq 'L';

	return $var;
}

sub parse_var
{
 my $var;
 my $file = "@_";
	$file .= '.tpl';

 my $html;
 my $default;

	if (-e "$file") {
		open MAIN, "$file" || die_nice("parse_var: $!");
			while (<MAIN>) { 
				s/\{(\S+?)\}/$template{$1}/gi;
				s/\%(\S+)\%/$LANG{$1}/g;
				$var .= $_;
			}                                          
		close MAIN;
	}
	
	return "$var";
}

sub OS
{
 my $os = shift;
	$os = "Windows" if $os eq 'W';
	$os = "Linux" if $os eq 'L';
	
	return $os;
}

sub SO
{
 my $os = shift;
	$os = "W" if $os eq 'Windows';
	$os = "L" if $os eq 'Linux';
	
	return $os;
}

sub Valor 
{
 my $val = shift;
 my $opt = shift;
	if ($opt eq 1) {
		$val = "30" if $val eq 'M';			
		$val = "360" if $val eq 'A';	
		$val = "1" if $val eq 'D' || $val eq 'U';
	} else {
		$val = "Mês" if $val eq 'M';	
		$val = "Ano" if $val eq 'A';	
		$val = "Dia" if $val eq 'D';
		$val = "Único" if $val eq 'U';
	}
			
	return "$val";
}

	#CRON

sub Action
{
 my $s = shift;
 my $act;
    $act = "CRIAR"		if $s eq 'C';
	$act = "MODIFICAR"	if $s eq 'M';
	$act = "BLOQUEAR"	if $s eq 'B';
	$act = "PARALIZAR"	if $s eq 'P';
	$act = "REMOVER"	if $s eq 'R';
	$act = "ATIVAR"		if $s eq 'A';
	$act = "NADA A FAZER"		if $s eq 'N';	
	
	return "$act";
} 
	#TICKETS

sub HStatus
{
	my $s = shift;
	my $status;
    $status = "ABERTO"		if $s eq 'A';
	$status = "FECHADO"		if $s eq 'F';
	$status = "ESPERA"	if $s eq 'H';
	return "$status";
} 

	#CLIENTE

sub UStatus
{
	my $status;
	my $s = shift;
    $status = "ATIVO"		if $s eq 'CA';
	$status = "PENDENTE"	if $s eq 'CP';
	$status = "CANCELADO"	if $s eq 'CC';
	return "$status";
} 

sub UStatusMatch
{
	my $status;
	my $s = shift;
    $status = 'CA'		if "ATIVO" =~ m/$s/i;
	$status = 'CP'		if "PENDENTE" =~ m/$s/i;
	$status = 'CC'		if "CANCELADO" =~ m/$s/i;
	
	return "$status";
} 

	#SERVIÇOS
sub Status
{
	my $status;
	my $s = shift;
    $status = "BLOQUEADO"		if $s eq 'B';
	$status = "CONGELADO"   	if $s eq 'P';
	$status = "CANCELADO"		if $s eq 'C';
	$status = "FINALIZADO"		if $s eq 'F';
	$status = "ACIMA DA BANDA"	if $s eq 'T';
	$status = "ACIMA DO ESPAÇO"	if $s eq 'E';
 	$status = "ATIVO"			if $s eq 'A';
	$status = "SOLICITADO"		if $s eq 'S';
	return "$status";
} 

sub ColSt
{
	my $c;
	my $s = shift;
    $c = "#990000"		if $s eq 'B';
	$c = "#990000"		if $s eq 'P';
	$c = "#000000"	    if $s eq 'C';
	$c = "#000000"	    if $s eq 'F';
	$c = "#990000"		if $s eq 'T';
	$c = "#990000"		if $s eq 'E';
	$c = "#009900"     	if $s eq 'A';
	$c = "#000099"		if $s eq 'S';
	return "$c";
} 

sub Action2Status {
	my $status;
	my $s = shift;
    
    $status = "B" if $s =~ 'B';
	$status = "P" if $s =~ 'P';
	$status = "A" if $s =~ m/[CMA]/;
	$status = "F" if $s =~ 'R';
	$status = "T" if $s =~ 'T';
	$status = "E" if $s =~ 'E';
	$status = "" if $s =~ 'N';
	
	return "$status";	
}
	#INVOICES

sub InStatus
{
	my $status;
	my $s = shift;
    $status = "PENDENTE"	if $s eq 'P';
	$status = "QUITADO"		if $s eq 'Q';
	$status = "A CONFIRMAR"	if $s eq 'C';
	$status = "CANCELADA"	if $s eq 'D';
	return "$status";
} 

sub InColSt
{
	my $c;
	my $s = shift;
	$c = "#990000"		if $s eq 'P';
	$c = "#009900"	    if $s eq 'Q';
	$c = "#000099"     	if $s eq 'C';
	$c = "#999999"	    if $s eq 'D';
	return "$c";
} 


# CALCULOS DE COBRANCAS

sub Multa
{
 my $multa;
 my $valor = shift;
 	$const = $global{'multa'};
	$multa = ($valor*$const/100);
	return "$multa";
} 

sub Juros
{
 my $juros;
 my $valor = shift;
 my $dif = shift;
 	$perc = $global{'juros'};
	$juros = ($valor*$perc*($dif+2)/100/30);
	return sprintf("%.2f",$juros);
} 

# CALCULOS E PESQUISAS
sub Tarifa
{
	my $fid = shift;
	
	my $sth = select_sql(qq|SELECT * FROM `tarifas` WHERE `id` = "$fid"|);
	return() if $sth->rows == 0;
	my $ref = $sth->fetchrow_hashref();

	my @result = ( $ref->{'tipo'}.' - '.$ref->{'modo'}, $ref->{'tplIndex'}, $ref->{'modulo'}, $ref->{'valor'}, $ref->{'autoquitar'} );
	$sth->finish;
	
	return(@result);
}

sub Prazo
{
 my $sid = shift;
 my $force = shift || 0;
 my $fvenc = shift || 0;
 my $finv = shift || 0;

 my ( $pid, $ini, $fim, $venc, $prox, $sts, $fatu, $pgs, $un, $parc) = split(/ - /,Servico($sid,"pg inicio fim vencimento proximo status invoice pagos username parcelas"));
	if ($sts eq "C" || $sts eq "F" || !$sts) { return "FALSEE"};
 my $da = $global{'dias_antes'};
 	$da = $force if $force;
	$venc = $fvenc if $fvenc;
	$fatu = 0 if $finv;
 my $invoices = $global{'invoices'};
	if ($invoices == 1 && $fatu > 0) {
	 	my ($ivenc) = split(/::/, Invoice($fatu,"data_vencimento"));
	 	$fatu = "" if (!$ivenc || date($ivenc) < today());
		 my ($vc) = split(/---/,Users($un,"vencimento"));
		$venc = DiaProximo($vc,$venc) if ($venc ne "0000-00-00" && $vc > 0);
	}
 my ($prim, $inter, $postec, $rep) = split(" - ",Pagamento($pid,"primeira intervalo parcelas repetir"));

	unless ($fatu > 0) {
		if ($fim eq "0000-00-00") {
			if ($venc eq "0000-00-00") {
				if ($pgs > 0) {
					execute_sql(qq|REPLACE INTO `cron` (`id`,`tipo`,`motivo`) VALUES ($sid,6,?)|,"Dados inconsistentes! Erro sem vencimento e com fatura paga. $sid pagou $pgs",1);
					return  ("FALSED", 0, 0, 0);
				}
				if ($postec == 1 && $prim == 0) { #(postecipado ou normal sem primeira)
					$venc_new = today() + $inter;
					execute_sql(qq|UPDATE servicos SET vencimento = "$venc_new" WHERE id = $sid|);
					return ("FALSEA", $inter, 0, 1);
				} else { #(antecipado ou normal com primeira)
					$venc_new = today() + $prim;
					return ($venc_new, $inter, 1, 0);
				}
			} else {
				unless ($rep == 1) { 
					return ("FALSEB", 0, 0, 0) if $pgs >= $parc;
				}
				
				$resto = date($venc) - today();
				if (($resto <= (($inter-$da)*-1) && $invoices == 1) || ($resto <= $da && $invoices != 1)) {
vencido:
					if ($inter%30 == 0) {
						$venc_new = SomaMes($venc,$inter/30);
					} else {
						$venc_new = date($venc) + $inter;
				 	}
					#segurança para não resultar em venc_new vencido
					if (date($venc_new) < today()) {
						$venc = $venc_new;
						goto vencido;
					}
					return ($venc_new, $inter, 1, 1) if ($postec == 1);
					return ($venc_new, $inter, 1, 0);
				} else {
					return ("FALSEC", 0, 0, 0);
				} 
			}
		} 	
	}

	return ("FALSED", 0, 0, 0);	
}

sub Invoice
{
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;
	my $stiv = 'SELECT invoices.*, users.vencimento FROM invoices INNER JOIN users ON invoices.username=users.username WHERE id = ?' ; 
	my $sth = $dbh->prepare($stiv);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= "::" if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish; 
	$r = "::" if !$r;
	return "$r";
}

sub Servico
{
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;
	my $stsn = 'SELECT * FROM servicos INNER JOIN planos ON servicos.servicos=planos.servicos WHERE id = ?';
	my $sth = $dbh->prepare($stsn);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= " - " if $c>0;
				$r .= $ref->{$q};
				$r = "" if $q eq "servidor" && $r eq 1;
				$c++;
			}
	   }
    $sth->finish;
	$r = " - " if !$r;
	return "$r";
} 

sub Servico_set
{
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;
	my $stsn = 'SELECT * FROM `servicos_set` WHERE `servico` = ?';
	my $sth = $dbh->prepare($stsn);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= " - " if $c>0;
				$r .= $ref->{$q};
				$r = "" if $q eq "servidor" && $r eq 1;
				$c++;
			}
	   }
    $sth->finish;
	$r = " - " if !$r;
	return "$r";
}

sub credito {
	my $user = shift;
	my $credito;
	
	my $sth = select_sql(qq|SELECT * FROM `creditos` WHERE `username` = ?|,$user); 
	while(my $ref = $sth->fetchrow_hashref()) {
		$credito += $ref->{'valor'};
	}
	$sth->finish;
	
	return $credito > 0 ? $credito : 0;
}

sub saldo {
	my $user = shift;
	my $saldo;
	
	#comprometer saldo, gerando fatura
	my ($vc) = split("---",Users($user,"vencimento"));
	gerar_fatura($user,$vc);
	
	#consulta saldo, já não comprometidos *precavendo solicitacoes sucessivas sem credito
	my $sth = select_sql(qq|SELECT * FROM `saldos` WHERE `username` = $user AND `invoice` IS NULL|); 
	while(my $ref = $sth->fetchrow_hashref()) {
		if ($ref->{'invoice'} eq ""){
			$saldo += $ref->{'valor'};
		}
	}
	$sth->finish;
	
	return $saldo;
}

sub Saldos
{
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;
	my $stsn = 'SELECT * FROM `saldos` WHERE `id` = ?';
	$stsn .= shift;
	my $sth = $dbh->prepare($stsn);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= "---" if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish;
	$r = "---" if !$r;
	return "$r";
} 

sub Creditos
{
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	@r;

	$c=0;
	my $stsn = 'SELECT * FROM `creditos` WHERE `id` = ?';
	$stsn .= shift;
	my $sth = $dbh->prepare($stsn);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				push @r, $ref->{$q};
			}
	   }
    $sth->finish;
    
	return @r;
} 

sub Users
{
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;
	my $stsn = 'SELECT * FROM `users` WHERE `username` = ?';
	my $sth = $dbh->prepare($stsn);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= "---" if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish; 
	$r = "---" if !$r;
	return "$r";
} 

sub Staffs {
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;
	my $stsn = 'SELECT * FROM `staff` WHERE `id` = ? OR `username` = ?';
	my $sth = $dbh->prepare($stsn);
	   $sth->execute($n,$n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= "---" if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish; 
	$r = "---" if !$r;
	return "$r";
}

sub Plano {
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;
	$c=0;

	my $statement = qq|SELECT * FROM `planos` LEFT JOIN `planos_modules` ON `planos`.`servicos`=`planos_modules`.`plano` WHERE `servicos` = $n| ; 
	my $sth = $dbh->prepare($statement);
	   $sth->execute();
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $_ (@q){
				$r .= " - " if $c>0;
				$r .= $ref->{$_};
				$c++;
			}
	   }
    $sth->finish;
	$r = " - " if !$r; 
	return "$r";
}

sub Sender {
	my %option = @_;
	my $sender;
	
	if ($option{'Department'}) {
		($sender) = Departments($option{'Department'},"sender");
	}
		
	if ($option{'User'} && !$sender) {
		my ($level) = split('---',Users($option{'User'},"level"));
		#default will be the first
		$level =~ s/^[:]+//;
		($sender) = Levels((split('::',$level))[0],"mail_account");
	}
	
	if ($option{'Level'} && !$sender) {
		#default will be the first
		$option{'Level'} =~ s/^[:]+//;
		($sender) = Levels((split('::',$option{'Level'}))[0],"mail_account");
	}
	
	if ($option{'UserFinan'} && !$sender) {
		my ($level) = split('---',Users($option{'UserFinan'},"level"));
		#default will be the first
		$level =~ s/^[:]+//;
		($sender) = Levels((split('::',$level))[0],"mail_billing");
		$sender ||= $global{'financeiro'};
	}
	
	return $sender || $global{'adminemail'};
}

sub Departments {
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	@r;

	my $statement = qq|SELECT * FROM `departments` WHERE `id` = ?| ; 
	my $sth = $dbh->prepare($statement);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q (@q){
				push @r, $ref->{$q};
			}
	   }
    $sth->finish;
 
	return @r;
}

sub Servidor {
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;

	my $statement = qq|SELECT * FROM servidores WHERE id = ?| ; 
	my $sth = $dbh->prepare($statement);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q (@q){
				$r .= " - " if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish;
	$r = " - " if !$r; 
	return "$r";
}

sub Servidor_set {
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;

	my $statement = qq|SELECT * FROM servidores_set WHERE id = ?| ; 
	my $sth = $dbh->prepare($statement);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q (@q){
				$r .= " - " if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish;
	$r = " - " if !$r; 
	return "$r";
}

sub Pagamento {
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;

	my $statement = qq|SELECT * FROM `pagamento` WHERE id = ?| ; 
	my $sth = $dbh->prepare($statement);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= " - " if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish;
	$r = " - " if !$r;
	return "$r";
}

sub ContaCorrente {
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

	$c=0;
	my $stsn = 'SELECT * FROM `cc` WHERE `id` = ?';
	my $sth = $dbh->prepare($stsn);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= "---" if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish; 
	$r = "---" if !$r;
	return "$r";
}

sub Feriado
{	
	my ($a,$m,$d) = split(/-/,shift);
	$m = $month_no unless $m;
	$d = $date_no unless $d;
	
	my $statement = qq|SELECT * FROM `feriados` WHERE `dia` = $d AND `mes` = $m|; 
	my $sth = $dbh->prepare($statement);
	$sth->execute();
	my $r = $sth->rows;
	$sth->finish; 

	return "$r";
}

sub Promo
{
 my	$sid = shift;
 my	$type = shift; #1 - dias gratis 2 - Sem taxa de setup 3 - Descontos em meses 4 - Nao se orientar pelo vc do usuario 5 - dias para finalizar 6 - fatura exclusiva
 my $y = shift;
 my	$r;
	$y ||= $year;
	my $sth = $system->select_sql(qq|SELECT `value` FROM `promocao` WHERE `servico` = ? AND `type` = ?|,$sid,$type);
	($r) = $sth->fetchrow_array();
	$sth->finish;
	
	if ($type == 1 || $type == 2 || $type == 4 || $type == 5 || $type == 6) {
		$r = num($r);
		$r = 0 if $r < 0;
	}
	#4.90::3,4,5,6::2008|6.65::1,8::2009
	if ($type == 3) {
		foreach ( split '\|', $r ) {
			my @v = split("::",$_,3);
			return @v if $v[2] == $y;
		}
		return ();
	}

	return ($r);
} 

sub Country
{
 my $n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	$r;

 my	$c=0;

	my $statement = qq|SELECT * FROM `countrycode` WHERE id = ?| ; 
	my $sth = $dbh->prepare($statement);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				$r .= " - " if $c>0;
				$r .= $ref->{$q};
				$c++;
			}
	   }
    $sth->finish;
	$r = " - " if !$r;
	return "$r";
} 

sub Level {
 my	$q = shift;
	@q= split("::",$q);

 my	$r;
	$c=0;

	my $statement = qq|SELECT * FROM `level`| ; 
	my $sth = $dbh->prepare($statement);
	   $sth->execute();
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $_ (@q){
				if ($_ eq $ref->{'id'}) {
					$r .= " | " if $c>0;
					$r .= $ref->{'nome'} ;
					$c++;
				}
			}
	   }
    $sth->finish;
	$r = " - " if !$r; 
	return "$r";
} 

sub Levels {
 my	$n = shift;
 my	$q = shift;
	@q= split(" ",$q);
 my	@r;

	my $statement = qq|SELECT * FROM `level` WHERE `id` = ?| ; 
	my $sth = $dbh->prepare($statement);
	   $sth->execute($n);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach $q(@q){
				push @r, $ref->{$q};
			}
	   }
    $sth->finish;
    
	return @r;
} 

sub AltPlano
{
 my $sid = shift;
 my $a = shift;
 my $d = shift;	
 my $auto = shift;

 my	$var = $global{'altplan'};
 my $statement = qq|SELECT * FROM `planos` WHERE `servicos` = $a OR `servicos` = $d| ; 
 my $sth = $dbh->prepare($statement);
	$sth->execute();
	if ($sth->rows <= 1) {
		$sth->finish;
		return 0, "Planos não aplicáveis. Escolha outro plano."	
	}
	while(my $ref = $sth->fetchrow_hashref()) {
		$package = $ref->{'auto'} if $ref->{'servicos'} eq $d;
	}
    $sth->finish; 
	
	$system->sid($sid);
	$v1 = parcela($a,$system->service('pg'),$system->service('desconto'),0); 
	$v2 = parcela($d,$system->service('pg'),$system->service('desconto'),0);
	$v=($v2-$v1);
	
	die_nice("Servico sem vencimento, contate nosso suporte") if !$system->service('vencimento') && !Promo($sid,1) && $system->service('inicio');
	$vnc = $system->service('inicio') + Promo($sid,1) if Promo($sid,1);
	$dd = date($vnc) - date($timemysql);
	die_nice("Servico vencido, contate nosso suporte") if $dd < 0;
	$dd = 0 if $dd <= $var;
	$dv = $v/$system->payment('intervalo');
	$vadd = $dd * $dv; #dias cobrados

	@a=split("-",$vnc);
	@b=split("-",$timemysql);

	my $mm = $dd % 30 > $var ? 1 : 0;
	$mm += int($dd/30);
 
	$vadd= $mm * ($v*30/$system->payment('intervalo')) if get_setting('altmes') == 1;#só meses, sem proporcional
	$vadd = 0 if $vadd < 0 && get_setting('altcredito') == 0;#permitir credito na alteracao
	$vadd *= -1;#Invertendo valor, saldo negativo é débito
	$vadd .= "::" . $package if $auto eq "package";

	return "$vadd";
}

sub EscolheDep {
	my ($user,$servico,$nomedep) = @_;
	my $dep;
	
	my ($nivel, $ptipo) = split(" - ",Servico($servico,"level tipo"));
	my ($level) = split("---",Users($user,"level"));
	my $stmt = qq|SELECT `id`, `level` FROM `departments`|;
	$stmt .= qq| WHERE `nome` = ?|;
	my $sth = select_sql($stmt,$nomedep);
	while (my $ref = $sth->fetchrow_hashref) {
		$dep = $ref->{'id'} if $ptipo && $global{'ddep'.lc $ptipo} && $global{'ddep'.lc $ptipo} =~ m/(^|::)$ref->{'level'}(::|$)/;#Empresa que vai responder por PADRAO caso nao tenha nenhum dep		
		next unless $level =~ m/(^|::)$ref->{'level'}(::|$)/; 
		$dep = $ref->{'id'}, last if $nivel =~ m/(^|::)$ref->{'level'}(::|$)/; #Plano deve ter acesso a empresa 
	}
		
	return $dep;
} 

sub Confirmcc
{
 my $banco = shift;
 my	$ag = shift;
 my	$conta = shift;

	my $stsn = 'SELECT * FROM cc';
	my $sth = $dbh->prepare($stsn);
	   $sth->execute();
	   while(my $ref = $sth->fetchrow_hashref()) {
	   		return 1 if "$ag-$conta" eq int($ref->{'agencia'})."-".int($ref->{'conta'});
			return 1 if "$ag-$conta" eq "24-".int($ref->{'convenio'}) && $banco == 104; #24 é modalidade sem cobrança da caixa e emedito pelo cliente
	   }
    $sth->finish; 

	return 0;
} 

sub Checkdate
{
 my $d = shift;

	$d =~ /^(\d\d\d\d)-(\d\d)-(\d\d)$/;
 my	@ymd = ($1, $2, $3);
	return 0 if @ymd != 3;
	return 0 if $ymd[1] < 1 && $ymd[1] > 12;
	return 0 if $ymd[0] < 1900;
	
 my $bi = $ymd[0] % 4;
 my $lstd =	DiaMes($ymd[2], $ymd[1]);
	$lstd = 29 if $bi == 0 && $lstd == 28;

	return 0 if $lstd < $ymd[2] || $ymd[2] < 1;
	
	return 1;
}

# APLICAÇÕES
sub paginar 
{
 my ($table,$limit,$where) = @_;
 my $ufile = $ENV{'SCRIPT_NAME'};
	$ufile =~ s/\/(.+)\///g;

	$sth = &select_sql(qq|SELECT COUNT(*) FROM $table $where|);
 my ( $count ) = $sth->fetchrow_array();
	$sth->finish;
	$total = $count;
 my $pages = ($total/$limit);
	$pages = ($pages+0.5);
 my $nume  = sprintf("%.0f",$pages);
	$page  = $q->param('page'.$i) || "0";
	$nume  = "1" if !$nume;
	$to    = ($limit * $page) if  $page;
	$to    = "0"              if !$page;
	$tpage     =  $page;
	$tpage     =  $tpage + 1;
	$location  =  $page;
	$location  =  $location + 1;
	$lboundary = "1" if $location < 2;
 	$lboundary =  $location - 1  if !$lboundary;
 my ($nav, $tboundary);
	$nav .= qq|<span class="nav-pages">$nume $LANG{Page_s}: </span>|;
	 
	if ($location + 2 < $nume) { $tboundary = 3 + $location; } else { $tboundary = $nume; }

	$string =  $ENV{'QUERY_STRING'};
	$string =~ s/&page$i=(.*)&?//g; 	
	$prev   =  $page;
	$prev   =  $prev - 1;
	 
	if ($nume > 1 && $tpage > 1 ) {
		unless ($ajax) {
			$nav .= qq|<a href="$ufile?$string&page$i=0" alt="$LANG{First_Page}" class="nav-first">&laquo;</a> <a href="$ufile?$string&page$i=$prev" alt="$LANG{Previous_Page}" class="nav-previous">&#139;</a> |;
		} else {
			$nav .= qq|<span onClick="href('$string&page$i=0')" alt="$LANG{First_Page}" class="nav-first">&laquo;</span> <span onClick="href('$string&page$i=$prev')" alt="$LANG{Previous_Page}" class="nav-previous">&#139;</span> |;
		}
	}   

	foreach ($lboundary .. $tboundary) {  		 
		my $nu = $_ -1;	
		if ($nu eq $page) { $link = "<span class=\"nav-selected\">[<b>$_</b>]</span>"; } else { $link = "$_"; }
		unless ($ajax) {          
			$nav   .= qq|<a href="$ufile?$string&page$i=$nu" class="nav-page ">$link</a> |;
		} else {
			$nav   .= qq|<span onClick="href('$string&page$i=$nu')" class="nav-page ">$link</span> |;
		}
	}
	
	$next = $page + 1;
	$last = $nume - 1;
	 
	if ($tpage < $nume && $tpage >= 1) { 
		unless ($ajax) {
			$nav .= qq|<a href="$ufile?$string&page$i=$next" alt="$LANG{Next_Page}" class="nav-next">&#155;</a> <a href="$ufile?$string&page$i=$last" alt="$LANG{Last_Page}" class="nav-last">&raquo;</a>|; 
		} else {
			$nav .= qq|<span onClick="href('$string&page$i=$next')" alt="$LANG{Next_Page}" class="nav-next">&#155;</span> <span onClick="href('$string&page$i=$last')" alt="$LANG{Last_Page}" class="nav-last">&raquo;</span>|;
		}
	}   

 my $show  = $limit * $page;
 
 	$sth = select_sql(qq|SELECT * FROM $table $where LIMIT $show,$limit|);
 my $number = scalar @{$sth->fetchall_arrayref()};
	$sth->finish;
	$number += $show if $number;
 my $showing = $show + 1;
 	$showing = 0 unless $number;
	
	$template{'nav'.$i} = "<span class=\"nav\">".$nav."</span>";
	$template{'total'.$i} = $count;	
	$template{'from'.$i}  = $show;
	unless ($ajax) {
		$template{'nav_result'.$i} = qq|<a href="$string&page$i=$page"><span class=\"nav-result\">$LANG{Showing}: $showing-$number $LANG{of} $count</span></a>| ;
	} else {
		$template{'nav_result'.$i} = qq|<span onClick="href('$string&page$i=$page')" class=\"nav-result\">$LANG{Showing}: $showing-$number $LANG{of} $count</span>|;
	}
	
	$i++ if $i;
	$i = 2 if !$i;
		
	return($nav,$limit,$page,$count,$show,$number);
}

sub Search
{
	my ($table,$results,$field,$query,$response,$group) = @_;
	my @founds;
	
	return if length $query < 3;
	$query = trim(SpecialChars($query));
	$field =~ s/\`?\.\`?/\`.\`/;
	
	my $sqlcom = qq|SELECT * FROM $table WHERE |;
	$sqlcom .= $field =~ m/id|username/i ? qq|`$field` = '$query'| : qq|`$field` LIKE '%$query%'|;
	$sqlcom .= qq| GROUP BY `$group`| if $group;
	$sqlcom .= qq| ORDER BY `$response`| if $response;

	$sth = select_sql($sqlcom); 
	while(my $ref = $sth->fetchrow_hashref()) {
 		my $found;
		foreach $referer (split("::",$results)){
			 if ($referer eq "username") {
				$found .= $ref->{$referer}."::";
			} elsif ($referer eq "id"){
				$found .= $ref->{$referer}."::";
			} elsif ($referer eq "invoice"){
				$found .= $ref->{$referer}."::";
			} elsif ($referer eq "servidor"){
				$found .= Servidor($ref->{$referer}, "nome")."::";
			} elsif ($referer eq "status"){
				$found .= Status($ref->{$referer}, "nome")."::";
			} else {
				$found .= $ref->{$referer}."::" ;
			}
		}
		push(@founds,$found);
	}
	return @founds;
}

sub Upload {
	my ($file,$cid,$nid) = @_;

	my $path2 = $global{'file_path'};
 	my $tfile =  $file;
	$tfile =~ s/\\/\//g;
 	my @path = split (/\//,$tfile);
 	my $entries = @path;
 	my $filename = $path[$entries-1];
 	my	$i = 1;
 	my ($fname, $ext) = $filename =~ m/(.*)\.(.*?)$/;
 
	die_nice("Extenção ($ext) não aceita") 	unless ($file_types{$ext} == 1);
			
	my $file_name = $fname;
	until($assigned == 1) {
		if (-e "$path2/$file_name\.$ext") {
			$file_name = $fname . "$i";
			$i++;
		} else {
			$assigned = "1";
		}
	} 
	$file_name .= ".$ext";
	
	my $content;
	open(LOCAL, ">$path2/$file_name") or return;
		binmode LOCAL;
		while(<$file>) {
			print LOCAL;
			$content .= $_;
		}
	close(LOCAL);
			
	#$path2 = SpecialChars($path2);     
	my $fid = $system->execute_sql(qq|INSERT INTO `files` VALUES (NULL, ?, ?, ?, ?)|,$cid, $nid, $file_name,"$path2/$file_name");
	
	return ($fid,$file_name,$content); 			
}

#Encrypt Decrypt
sub encrypt_mm {
	my $pwd = html(trim(shift));

	#TODO colocar private key nas confs
	my @pkey = ([2,1,1],[1,1,1],[2,3,2]);
	my ($i,$j) = (0,0);
	my @code; my $codes;
	
	my @cyph = split(//,$pwd);

	until (scalar @cyph % 3 == 0) {
		push @cyph, '';#0
	}

	foreach (@cyph) {
		$j = 0 if $j > 2;		
		$code[$i][$j] = ord($_);
		$i++ if $j == 2;
		$j++;		
	}

	@code = mm(\@code,\@pkey);

	for $i (0 .. (scalar @code - 1)) {
		for $j (0 .. 2) {
			$codes .= $code[$i][$j].":";
		}
	}

	return (trim($codes));
}

sub decrypt_mm {
	my $mkey = trim(shift);
	my $result; my @code;
	#TODO gerar chave reversa se colocar chave privada no conf
	my @rkey = ([1,-1,0],[0,-2,1],[-1,4,-1]);

	my @cyph = split(/:/,$mkey);

	foreach (@cyph) {
		$j = 0 if $j > 2;		
		$code[$i][$j] = $_;
		$i++ if $j == 2;
		$j++;		
	}

	@code = mm(\@code,\@rkey);

	for $i (0 .. (scalar @code - 1)) {
		for $j (0 .. 2) {
			next if $code[$i][$j] == 0;
			$result .= chr($code[$i][$j]);
		}
	}

	return unhtml(trim($result));
}

sub mm {
	my @a = @{$_[0]};
	my @b = @{$_[1]};
	my @code; my @codes;
	my ($i,$j,$k);

	for $i (0 .. (scalar @a - 1)) {
		for $j (0 .. 2) {
			for $k (0 .. 2) {
				$code[$i][$j] += ($a[$i][$k] * $b[$k][$j]);
			}
		}
	}

	return @code;	
}

sub encrypt
{
 my $var;
 my $tam;
 my $nvar;

	$var = shift;
	$tam = length($var);
	%cripto = ("a","11","b","13","c","15","d","17","e","19","f","22","g","24","h","27","i","31","j","34","k","36","l","39","m","41","n","43","o","10","p","12","q","14","r","16","s","18","t","20","u","21","v","23","x","25","z","26","w","28","y","29","0","30","1","32","2","33","3","35","4","37","5","38","6","40","7","42","8","44","9","45","\!","50","\@","51","\#","52","\$","53","\%","54","\^","55","\&","56","\*","57","\(","58","\)","59","\-","60","\+","61","\=","62","\\","63","\_","64","\|","65","\]","66","\[","67","\{","68","\}","69","\'","70","\"","71","\;","72","\:","73","\?","74","\/","75","\.","76","\>","77","\,","78","\<","79","\`","80","\~","81");

	while ($tam) {
		$tmp = substr($var,-($tam),1);
		$tmp = $cripto{$tmp};
		$nvar .= $tmp; 
		$tam--;
	}

	return $nvar;
}

sub decrypt
{
 my $var;
 my $tam;
 my $nvar;
 
	$var = shift;
	$tam = length($var);
	return if $tam % 2 ne 0;
	%cripto = reverse("a","11","b","13","c","15","d","17","e","19","f","22","g","24","h","27","i","31","j","34","k","36","l","39","m","41","n","43","o","10","p","12","q","14","r","16","s","18","t","20","u","21","v","23","x","25","z","26","w","28","y","29","0","30","1","32","2","33","3","35","4","37","5","38","6","40","7","42","8","44","9","45","\!","50","\@","51","\#","52","\$","53","\%","54","\^","55","\&","56","\*","57","\(","58","\)","59","\-","60","\+","61","\=","62","\\","63","\_","64","\|","65","\]","66","\[","67","\{","68","\}","69","\'","70","\"","71","\;","72","\:","73","\?","74","\/","75","\.","76","\>","77","\,","78","\<","79","\`","80","\~","81");

	while ($tam) {
		$tmp = substr($var,-($tam),2);
		$tmp = $cripto{$tmp};
		$nvar .= $tmp; 
		$tam-=2;
	}
	
	return $nvar;	
}

sub log
{
	my ($action, $table, $value, $user, $debug) = @_;

	my @file = $0 =~ m/^(.*\/|.*\\)?(.*)$/;

	my $db = $user ? "log" : "log_sys";
	my $sql = qq|INSERT INTO `$db` |;
	$sql .= qq|(`file`,`action`,`table`,`value`,`byuser`,`data`,`tempo`,`debug`) | if $db eq 'log';#log
	$sql .= qq|(`file`,`action`,`table`,`value`,`data`,`tempo`,`debug`) | if $db eq 'log_sys';#log_sys
	$sql .= qq|VALUES ("$file[1]", "$action", "$table", ?,|;
	$sql .= qq|"$user",| if $user;
	&get_time();
	$sql .= qq|"$timemysql", "$timenow24", ?)|;
	$dbh->do($sql,{},$value,$debug) || die("Mysql: ".$dbh->{'mysql_error'}." <br>$sql");
}

sub URLDecode {
    my $theURL = shift;

    $theURL =~ tr/+/ /;
    $theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $theURL =~ s/<!--(.|\n)*-->//g;

    return $theURL;
}

sub URLEncode {
   my $theURL = shift;

   $theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;

   return $theURL;
}

sub SpecialChars {
	my $chars = shift;

	$chars =~ s/\\/CTRL_BARRA/g;
	$chars =~ s/([\W])/"\\" . $1/eg;
	$chars =~ s/CTRL_BARRA/\\\\/g;
	
	return $chars;
}

sub escape_ajax {
	my $chars = shift;

	#escape char ''
	$chars =~ s/(''|')/$1 eq "''" ? "'" : "\\'"/ge;
	#html nao aceita ", escape ""
	$chars =~ s/(""|")/$1 eq '""' ? '"' : "\'"/ge;
	
	#s/(''|')/$1 eq '\'\'' ? '\'' : '\\\''/ge;
	
	return $chars;
}

sub hd2mysql {
	my $chars = shift;

	$chars =~ s/\<style\>.*\<\/style\>//gi;
	$chars =~ s/\<script\>.*\<\/script\>//gi;
	$chars =~ s/\<\\?a.+?\>\n?//gi;
	$chars =~ s/\<\!--.+?\>\n?//gi;	
	$chars =~ s/\r\n/\n/g;
	$chars =~ s/\\/CTRL_BARRA/g;
	$chars =~ s/([^\w ])/"\\" . $1/eg;
	$chars =~ s/CTRL_BARRA/\\\\\\\\/g;
	
	return $chars;
}

sub hd2html {
	my $chars = shift;
	my $full = shift;

	unless ($full) {
		$chars =~ s/\<([\w.-]+?\@.+?)\>/&lt;$1&gt;/gi;
		$chars =~ s/\<(script\>.*)\<(\/script\>)/&lt;$1&lt;$2/gi;
		$chars =~ s/\<(\\?a.+?\>\n?)/&lt;$1/gi;
		$chars =~ s/"/&quot;/gi;
	}
	$chars =~ s/</&lt;/g;
	$chars =~ s/>/&gt;/g;
	$chars =~ s/\r\n|\n/<br>/g;
	$chars =~ s/\[b\]/<b>/gi;
	$chars =~ s/\[\/b\]/<\/b>/gi;
	$chars =~ s/\[i\]/<i>/gi;
	$chars =~ s/\[\/i\]/<\/i>/gi;
	$chars =~ s/\<(meta[^>]*refresh[^>]*\>\n?)/&lt;$1/gi;
	$chars =~ s/!/\!/gi;	
			
	return $chars;
}

sub my2html {
	my $chars = shift;
	my $full = shift;

	unless ($full) {
		$chars =~ s/\<([\w.-]+?\@.+?)\>/&lt;$1&gt;/sgi;
		$chars =~ s/\<(script\>.*)\<(\/script\>)/&lt;$1&lt;$2/sgi;
		$chars =~ s/\<(\\?a.+?\>\n?)/&lt;$1/sgi;
		$chars =~ s/<(\/)?tr ?.+?>//sgi;
		$chars =~ s/<(\/)?table ?.+?>//sgi;
		$chars =~ s/<(\/)?td ?.+?>//sgi;
		$chars =~ s/<(\/)?T?BODY.*?>//sgi;
		$chars =~ s/<(\/)?I?FRAME.*?>//sgi;
		$chars =~ s/<(\/)?BASE.*?>//sgi;		
		$chars =~ s/<(\/)?STYLE.*?>//sgi;
		$chars =~ s/\r\n|\n/<br>/g;		
	}
	$chars =~ s/\\(\W)/$1/g;
	$chars =~ s/\[b\]/<b>/gi;
	$chars =~ s/\[\/b\]/<\/b>/gi;
	$chars =~ s/\[i\]/<i>/gi;
	$chars =~ s/\[\/i\]/<\/i>/gi;
	$chars =~ s/\<(meta[^>]*refresh[^>]*\>\n?)/&lt;$1/gi;
			
	return $chars;
}

sub text2html {
	my $ref = shift; 

	use HTML::TextToHTML;
	my $text = new HTML::TextToHTML;
	$$ref = $text->process_chunk($$ref) if ref ($ref) eq "SCALAR";
	$ref = $text->process_chunk($ref) if ref ($ref) eq "";	
	
	return $ref;	
}

sub html {
	my $text = shift;

	use HTML::Entities;

	$text = HTML::Entities::encode($text);

	return $text;
}

sub unhtml {
	my $text = shift;

	use HTML::Entities;

	$text = HTML::Entities::decode($text);

	return $text;
}

################
# HTML Builder #
################
sub htmltag ($;@) {
    # called as htmltag('tagname', %attr)
    # creates an HTML tag on the fly, quick and dirty
    my $name = shift || return;
    my $attr = htmlattr($name, @_);     # ref return faster

    # see if we have a special tag name (experimental)
    (my $look = $name) =~ s#^(/*)##;
    $name = "$1$TAGNAMES{$look}" if $TAGNAMES{$look};

    my $htag = join(' ', $name,
                  map { qq($_=") . html($attr->{$_}) . '"' } sort keys %$attr);

    $htag .= ' /' if $name eq 'input' || $name eq 'link';  # XHTML self-closing
    return '<' . $htag . '>';
}

sub htmlattr ($;@) {
    # called as htmlattr('tagname', %attr)
    # returns valid HTML attr for that tag
    my $name = shift || return;
    my $attr = ref $_[0] ? $_[0] : { @_ };
    my %html;
    while (my($key,$val) = each %$attr) {
        # Anything but normal scalar data gets yanked
        next if ref $val || ! defined $val;

        # This cleans out all the internal junk kept in each data
        # element, returning everything else (for an html tag).
        # Crap, I used "text" here and body takes a text attr!!
        next if ($OURATTR{$key} || $key =~ /^_/
                                || ($key eq 'text'     && $name ne 'body')
                                || ($key eq 'multiple' && $name ne 'select')
                                || ($key eq 'type'     && $name eq 'select')
                                || ($key eq 'label'    && ($name ne 'optgroup' && $name ne 'option'))
                                || ($key eq 'title'    && $name eq 'form'));

        # see if we have a special tag name (experimental)
        $key = $TAGNAMES{$key} if $TAGNAMES{$key};
        $html{$key} = $val;
    }
    # "double-name" fields with an id for easier DOM scripting
    # do not override explictly set id attributes
    $html{id} = tovar($html{name}) if exists $html{name} and not exists $html{id};

    return wantarray ? %html : \%html; 
}

sub tovar ($) {
    my $name = shift;
    $name =~ s#\W+#_#g;
    $name =~ tr/_//s;
    $name =~ s/_$//;
    return $name;
}

sub post2html {
	my $postdata = shift;
	my $type = shift || 'hidden';
	
	my @data = split("&",$postdata);
	my @html;	
	foreach (@data) {
		my ($name,$value) = split("=",$_);
		push @html, htmltag('input', name => $name, type => $type, value => $value)
	}
	
	return join "\n", @html;
}
 	
sub makeform {
	my ($name,$method,$action,$data) = @_;
	
	my @html;
	push @html, htmltag('html');
	push @html, htmltag('body');
	push @html, htmltag('form',name=>"$name",method=>"$method",action=>"$action");
	push @html, post2html($data);
 	push @html, htmltag('/form');
 	 	
 	return join "\n", @html; 	
} 

sub submitform {
	my $name = shift;
	
	my @html;
 	push @html, qq|<script type="text/javascript">document.$name.submit();</script>|;
	push @html, htmltag('/body');
	push @html, htmltag('/html');
	return join "\n", @html;
}
#####################

sub iniciais {
	my $value = lc shift;
	
	$value =~ s/(\w)(.+?)( |$)/\u$1$2$3/g;
	$value =~ s/(\s\w)(\w)( |$)/\u$1\u$2$3/g;
	$value =~ s/ D(\w)(s?)( |$)/ d\l$1$2$3/gi;
	$value =~ s/ dr(s?)( |$)/ Dr$1$2/gi;
	$value =~ s/(\s\w)( |$)/\l$1$2/g;

	return $value;
}

sub iso2utf8 {
	my $text = shift;

	use Encode;

	$text = encode("utf8", decode("iso-8859-1", $text));

	return $text;
}

sub iso2puny {
	my @text = split(/\./,shift);
	my $text;

	use IDNA::Punycode;

	foreach (@text) {	
		$text .= IDNA::Punycode::to_ascii($_).".";
	}

	return $text;
}

sub num {
 my $num = shift;
 
 my ($minus) = $num =~ /^(-)/;
	$num =~ s/\D//g; 
	$num = 0 if !$num;
	
	return $minus.$num;
}

sub FormataCPFCNPJ {
	my $valor = shift;	

	$valor =~ s/[\-\.\/]//g;
	$valor = substr($valor,1,14) if (length $valor == 15);

	if (length $valor == 11) {
		$valor = substr($valor,0,3).'.'.substr($valor,3,3).'.'.substr($valor,6,3).'-'.substr($valor,9,2);
	} elsif (length $valor == 14) {
		$valor = substr($valor,0,2). '.'.substr($valor,2,3).'.'.substr($valor,5,3).'/'.substr($valor,8,4).'-'.substr($valor,12,2);
	}

	return $valor;
}

sub validaCPFCNPJ
{
	$valor = shift;
	$valor =~ s/[\-\.\/]//g;
	$valor = substr($valor,1,14) if (length $valor == 15);

	use String;
	if (length $valor == 11) {
		my $cpf = new String($valor);
		my @a;
		my $b = 0;
		my $c = 11;
		my $validate = 0;
		for ($i=0; $i<11; $i++){
			$a[$i] = $cpf->charAt($i);
			$b += ($a[$i] * --$c) if ($i < 9);
		}
		if (($x = $b % 11) < 2) { $a[9] = 0; } else { $a[9] = 11-$x; }
		$b = 0;
		$c = 11;
		for ($y=0; $y<10; $y++) { $b += ($a[$y] * $c--) }; 
		if (($x = $b % 11) < 2) { $a[10] = 0; } else { $a[10] = 11-$x; }
		
		if ($cpf eq "00000000000" || $cpf eq "11111111111" || $cpf eq "22222222222" || $cpf eq "33333333333" || $cpf eq "44444444444" || $cpf eq "55555555555" || $cpf eq "66666666666" || $cpf eq "77777777777" || $cpf eq "88888888888" || $cpf eq "99999999999")	{
		} elsif (($cpf->charAt(9) != $a[9]) || ($cpf->charAt(10) != $a[10])) {
		} else {
			return 1;
		}
	} elsif (length $valor == 14) {
		$CNPJ = new String($valor);
		my @a;
		my $b = 0;
	    my @c = (6,5,4,3,2,9,8,7,6,5,4,3,2);
	    for ($i=0; $i<12; $i++){
			$a[$i] = $CNPJ->charAt($i);
			$b += $a[$i] * $c[$i+1];
		}
		if (($x = $b % 11) < 2) { $a[12] = 0; } else { $a[12] = 11-$x; }
		$b = 0;
		for ($y=0; $y<13; $y++) {
			$b += ($a[$y] * $c[$y]); 
		}
		if (($x = $b % 11) < 2) { $a[13] = 0; } else { $a[13] = 11-$x; }
	
		if (($CNPJ->charAt(12) != $a[12]) || ($CNPJ->charAt(13) != $a[13])){
		} else{
			return 1;
		}
	}
	return;
}

sub Cep {
	my $valor = num(shift);
	
	return if $valor == 0;

	$valor = substr($valor,0,9);
	$valor = substr($valor,0,2). '.'.substr($valor,2,3).'-'.substr($valor,5,4);

	return $valor;
}

sub Telefone {
	my $valor = num(shift);

	return if $valor == 0;
	
	#especiais
	return $valor if $valor =~ m/^0800/;
	$valor =~ s/([1-9]{2})([0-9]{3,5})([0-9]{4})/($1) $2-$3/;

	return $valor;
}

sub LOG_ERROR {
	my $error = @_;
	my $file = "../logs/error.log";
	my $data = $global{'data'} || $system->setting('data');
	system("mkdir $data/../logs") unless (-e "$data/../logs");
	
	open MAIN, ">> $data/$file" or die_nice("LOG_ERROR: $!");
	print MAIN "<$0 $hdtime>: @_\n";
	close MAIN;
}

sub Translog {
	my $error = @_;
	my $file = "../logs/trans.log";
	system("mkdir $global{'data'}/../logs") unless (-e "$global{'data'}/../logs");
	
	open MAIN, ">> $global{'data'}/$file" or die_nice("Translog: $!");
	print MAIN "@_\n";
	close MAIN;
}

#BOLETO SUBS
sub dvbancobrasil
{
	my $num = shift;
	my $resto = "";
	my $digito = "";
	
	$resto = &calcdig11($num, 7, 1);
	$digito = 11 - $resto;
	if ($resto == 1) {
		$digito = "X";
	} elsif ($resto == 0) {
		$digito = 0;
	}

	return "$digito";
}

sub dvbradesco
{
	my $num = shift;
	my $resto = "";
	my $digito = "";
	
	$resto = &calcdig11($num, 7, 1);
	$digito = 11 - $resto;
	if ($resto == 10) {
		$digito = "P";
	} elsif ($resto == 11) {
		$digito = 0;
	}

	return "$digito";
}

sub dvnnbanespa
{
	my $cadeia = shift;
	my $mult=7;
	my $total=0;
	
	for ($pos=0;$pos<length($cadeia);$pos++){
		$total += substr($cadeia, $pos, 1) * $mult;
		$total = substr($total, -length($total)+1, 1);
		if ($pos % 2 == 0){
			$mult -= 4;
		}else{
			$mult -= 2;
		}
		$mult = 9 if $mult < 1;	
	}
	$total = 10 - $total;
	return "$total";
}

sub dvbanespa
{
	my $num = shift;
	my $resto = "";
	my $digito = "";
	my $exit = 0;
	
	while (!$exit) {
		$digito = &calcdig11($num, 7, 1);
		if ($digito == 0) {
			$exit = 1;
		} elsif ($digito eq 1) {
			if (substr($num,-1) == 9) {
				$num = substr($num,0,length($num)-1);
				$num = $num."0";
			} else {
				$resto = substr($num,-1) + 1;
				$num = substr($num,0,length($num)-1);
				$num = $num.$resto;
			}
		} else {
			$digito = 11 - $digito;
			$exit = 1;
		}
	}

	return "$num$digito";
}

sub calcdig10
{
	my $cadeia = shift;
	my $mult="";
	my $total="";
	my $calcdig10="";
	
	$mult = (length($cadeia) % 2);
	$mult = $mult + 1;
	$total = 0;
	for ($pos=0;$pos<length($cadeia);$pos++){
		$res = substr($cadeia, $pos, 1) * $mult;
		$res = int($res/10) + ($res % 10) if $res > 9 ;
		$total = $total + $res;
		if ($mult == 2){
			$mult = 1;
		}else{
			$mult = 2;
		}
	}
	$total = ((10-($total % 10)) % 10 );
	$calcdig10 = $total;
	return "$calcdig10";
}

sub calcdig11
{
	my $cadeia = shift;
	my $limitesup = shift;
	my $lflag = shift;
	my $mult="";
	my $nresto="";
	my $ndig="";
	my $calcdig11="";

	$mult = 1 + (length($cadeia) % ($limitesup - 1));
	$mult = $limitesup if $mult == 1;

	$total = 0;

	for ($pos=0;$pos<length($cadeia);$pos++) {
		$total += substr($cadeia,$pos,1) * $mult;
		$mult = $mult - 1;
		$mult = $limitesup if $mult == 1; 
	}
	$nresto = $total % 11;
	if ($lflag == 1) {
		$calcdig11 = $nresto;
	}else{
		if ($nresto == 0 || $nresto == 1 || $nresto == 10) {
			$ndig = 1;
		}else{
			$ndig = 11 - $nresto;
		}
		$calcdig11 = $ndig;
	}
	
	return $calcdig11;
}

sub string 
{
	my $quantidade = shift;
	my $var = shift;
	my $n="";
	for($i=0;$i<$quantidade;$i++){
	$n .= $var;
	}
	return $n;
}

sub fatorvencimento
{
	$vencimento = shift;
	if (length($vencimento) < 8){
	   $fatorvencimento="0000";
	   return "$fatorvencimento";
	}else{
	   $fatorvencimento = date($vencimento) - date('1997-10-07');
	   return "$fatorvencimento";
	}
}

sub codbar
{
	my $banco = shift;
	my $dvbanco = shift;
	my $moeda = shift;
	my $vencimento = shift;
	my $valor = shift;
	my $carteira = shift;
	my $nossonumero = shift;
	my $dvnossonumero = shift;
	my $agencia = shift;
	my $conta = shift;
	my $dvagconta = shift;
	my $codcliente = shift;
	my $strcodbar="";
	my $dv3="";
	my $codbar="";
	
	if ($banco eq "341") {
		$strcodbar = $banco.$moeda.$vencimento.$valor.$carteira.$nossonumero.$dvnossonumero.$agencia.$conta.$dvagconta."000";
		$dv3 = &calcdig11($strcodbar,9,0);
		$codbar = $banco.$moeda.$dv3.$vencimento.$valor.$carteira.$nossonumero.$dvnossonumero.$agencia.$conta.$dvagconta."000";
	} elsif ($banco eq "001") {
		$strcodbar = $banco.$moeda.$vencimento.$valor."000000".$nossonumero.$carteira;
		$dv3 = &calcdig11($strcodbar,9,0);		
		$codbar = $banco.$moeda.$dv3.$vencimento.$valor."000000".$nossonumero.$carteira;
	} elsif ($banco eq "033") {
		$strcodbar = $banco.$moeda.$vencimento.$valor.$dvagconta;
		$dv3 = &calcdig11($strcodbar,9,0);		
		$codbar = $banco.$moeda.$dv3.$vencimento.$valor.$dvagconta;
	} elsif ($banco eq "356") {
		$strcodbar = $banco.$moeda.$vencimento.$valor.$agencia.$conta.$dvagconta.$nossonumero;
		$dv3 = &calcdig11($strcodbar,9,0);		
		$codbar = $banco.$moeda.$dv3.$vencimento.$valor.$agencia.$conta.$dvagconta.$nossonumero;		
	} elsif ($banco eq "409") {
		$strcodbar = $banco.$moeda.$vencimento.$valor."5".$codcliente."00".$nossonumero.$dvnossonumero;
		$dv3 = &calcdig11($strcodbar,9,0);
		$codbar = $banco.$moeda.$dv3.$vencimento.$valor."5".$codcliente."00".$nossonumero.$dvnossonumero;		
	} elsif ($banco eq "237") {
		$strcodbar = $banco.$moeda.$vencimento.$valor.$agencia.$nossonumero.$conta."0";
		$dv3 = &calcdig11($strcodbar,9,0);
		$codbar = $banco.$moeda.$dv3.$vencimento.$valor.$agencia.$nossonumero.$conta."0";		
	} elsif ($banco eq "104" && $dvbanco == 0) { #CEF SICOB
		$strcodbar = $banco.$moeda.$vencimento.$valor.$nossonumero.$agencia.$codcliente;
		$dv3 = &calcdig11($strcodbar,9,0);
		$codbar = $banco.$moeda.$dv3.$vencimento.$valor.$nossonumero.$agencia.$codcliente;		
	} elsif ($banco eq "104" && $dvbanco == 1 ) { #CEF SIGCB
		$strcodbar = $banco.$moeda.$vencimento.$valor.$nossonumero.$dvnossonumero;
		$dv3 = &calcdig11($strcodbar,9,0);
		$codbar = $banco.$moeda.$dv3.$vencimento.$valor.$nossonumero.$dvnossonumero;		
	}		
	
	return $codbar;
}

sub linhadigitavel
{
	my $codigobarras = shift;
	
	$cmplivre = substr($codigobarras,19,25);
	
	$campo1 = substr($codigobarras,0,4) . substr($cmplivre,0,5);
	$campo1 .= &calcdig10($campo1);
	$campo1 = substr($campo1,0,5) . "." . substr($campo1,5,5);

	$campo2 = substr($cmplivre,5,10);
	$campo2 .= &calcdig10($campo2);
	$campo2 = substr($campo2,0,5) . "." . substr($campo2,5,6);

	$campo3 = substr($cmplivre,15,10);
	$campo3 .= &calcdig10($campo3);
	$campo3 = substr($campo3,0,5) . "." . substr($campo3,5,6);
	
	$campo4 = substr($codigobarras,4,1);

	$campo5 = substr($codigobarras,5,14);
	$campo5 = "000" if $campo5 eq 0;

	$linhadigitavel = $campo1 . "&nbsp;&nbsp;" . $campo2 . "&nbsp;&nbsp;" . $campo3 . "&nbsp;&nbsp;" . $campo4 . "&nbsp;&nbsp;" . $campo5;
	
	return $linhadigitavel;
}

sub wbarcode
{
	my $valor = shift;
	$fino = "1";
	$largo = "3";
	$altura = "50";
	
	if (!$BarCodes[0]) {
	  $BarCodes[0] = "00110";
	  $BarCodes[1] = "10001";
	  $BarCodes[2] = "01001";
	  $BarCodes[3] = "11000";
	  $BarCodes[4] = "00101";
	  $BarCodes[5] = "10100";
	  $BarCodes[6] = "01100";
	  $BarCodes[7] = "00011";
	  $BarCodes[8] = "10010";
	  $BarCodes[9] = "01010";
	  for ($f1=9;$f1>=0;$f1--){
	    for ($f2=9;$f2>=0;$f2--){
	      $f = $f1 * 10 + $f2;
	      $texto = "";
	      for ($i=0;$i<5;$i++){
	        $texto .= substr($BarCodes[$f1],$i,1) . substr($BarCodes[$f2],$i,1);
	      }
	      $BarCodes[$f] = $texto;
	  	}
	  }
	}
	
	#Desenho da barra
	#Guarda inicial
	$iniciobar = qq|<head><STYLE type=text/css>
				.ti { FONT: 9px Arial, Helvetica, sans-serif }
				.ct { FONT: 9px Arial Narrow; COLOR: navy }
				.cn { FONT: 9px Arial; COLOR: black }
				.cp { FONT: bold 11px Arial; COLOR: black }
				.ld { FONT: bold 15px Arial; COLOR: #000000 }
				.bc { FONT: bold 18px Arial; COLOR: #000000 }
				</STYLE>
				</head>

				<img src=$template{'imgbase'}/2.gif width=$fino height=$altura border=0><img
				src=$template{'imgbase'}/1.gif width=$fino height=$altura border=0><img
				src=$template{'imgbase'}/2.gif width=$fino height=$altura border=0><img
				src=$template{'imgbase'}/1.gif width=$fino height=$altura border=0><img|; 

	$texto = $valor;
	$texto = "0" . $texto if length($texto) % 2 ne 0;

	#Draw dos dados
	while (length($texto) > 0){
	  $i = int(substr($texto,0,2));
	  $texto = substr($texto,2,length($texto)-2);
	  $f = $BarCodes[$i];
	  $a=0;
	  while ($a<10){
		if (substr($f,$a,1) eq "0"){
	      $f1 = $fino;
	    }else{
	      $f1 = $largo;
	    }
	    $meiobar .= qq| src=$template{'imgbase'}/2.gif width=$f1 height=$altura border=0><img|;
		$a++;
	    if (substr($f,$a,1) eq "0"){
	      $f2 = $fino;
	    }else{
	      $f2 = $largo;
	    }
	    $meiobar .= qq| src=$template{'imgbase'}/1.gif width=$f2 height=$altura border=0><img|;
		$a++;
	  }
	}

	#Draw guarda final
	$fimbar = qq| src=$template{'imgbase'}/2.gif width=$largo height=$altura border=0><img 
				src=$template{'imgbase'}/1.gif width=$fino height=$altura border=0><img 
				src=$template{'imgbase'}/2.gif width=$fino height=$altura border=0>|;
				
	return $iniciobar.$meiobar.$fimbar;
}

sub boleto {
	my $inv = shift;
	my $conta = shift;
	
	#Padroes Bancos
	my $var_nnumero = { "001" => 5, "341" => 8, "033" => 7, "356" => 13, "409" => 14, "237" => 11, "104" => 8};			
	
	# SYSTEM
	my ($var_agencia,$var_conta,$var_carteira,$var_convenio,$var_banco,$var_dvbanco,$var_cedente,$var_instrucoes) = split("---",ContaCorrente($conta,"agencia conta carteira convenio banco dvbanco cedente instrucoes"));
	$var_agencia =~ s/- .*$//; #Tira dígito
	$var_conta =~ s/- .*$//;

	# INVOICE
	my ($user,$var_datavencimento,$var_valordocumento,$var_datadocumento,$var_ref,$taxid) = split("::",Invoice($inv,"username data_vencimento valor data_envio referencia tarifa"));
	my $var_observacoes = "Serviços cobrados: <BR>";

	# TARIFAS
	my ($taxa,$tarifa);
	my $sth = select_sql(qq|SELECT * FROM `tarifas` WHERE `id` = ?|,$taxid);
	while(my $ref = $sth->fetchrow_hashref()) { 
		return unless $ref->{'modulo'} eq 'boleto';
		$taxa = $ref->{'valor'}; 
		$tarifa = $ref->{'tipo'}." ".$ref->{'modo'};
	}
	$sth->finish;	
	#********************************
	# CONSTANTES
	#********************************
	my $cons_moeda = $global{'moeda_nr'};
	my $cons_especie = $global{'moeda'};
	my $cons_numerodoc = "90123";
			
	#********************************
	# CÁLCULO
	#********************************
	$var_valordocumento += $taxa;
	$var_observacoes .= $var_ref;
	$var_observacoes .= "\nTaxa Administrativa Contratual - ".CurrencyFormatted($taxa) if $taxa != 0;	
	my $numero = 12 - length($var_convenio);
	my $cod_cliente = $var_convenio if $var_banco eq "409" || $var_banco eq "104";
	$var_convenio = $var_convenio . &string($numero,0) if $var_banco eq "001";
	$var_nossonumero = &string(20,0) . $inv;
	die "Erro geral. Impossível gerar boleto para a fatura $inv, nossonúmero esgotado para o banco $var_banco." if length($inv) > $var_nnumero->{$var_banco};
	$var_nossonumero = substr($var_nossonumero,-$var_nnumero->{$var_banco});
	$var_nossonumero = $var_convenio . $var_nossonumero if $var_banco eq "001";
	$var_nossonumero = $var_carteira . $var_nossonumero if $var_banco eq "237" || ($var_banco eq "104" && $var_dvbanco == 0);
	$var_datadocumento = FormatDate($var_datadocumento);
	$var_valordocumento = &Round($var_valordocumento);
	$var_observacoes =~ s/\n/<br>/g;	
	$template{'carteira'} = $var_carteira;
	$var_carteira =~ s/-(.+)//g;				

	my ($dvnossonumero,$dvagconta,$dvagencia);			
	#itau 341
	if ($var_banco eq "341") {
		$dvnossonumero = &calcdig10($var_agencia.$var_conta.$var_carteira.$var_nossonumero);
		$dvagconta = &calcdig10($var_agencia.$var_conta);
	}
		
	#Banco do brasil 001
	if ($var_banco eq "001") { #TODO Verificar questoes de convenio
		$var_conta = substr("00000000".$var_conta,-8);		
		$dvnossonumero = &calcdig11($var_nossonumero,9,0);
		$dvagencia = &dvbancobrasil($var_agencia);
		$dvagconta = &dvbancobrasil($var_conta);
	}
		
	#Banco Banespa 033
	if ($var_banco eq "033") {
		$dvnossonumero = &dvnnbanespa($var_agencia . $var_nossonumero,9,1);
		$dvagconta = $var_agencia.$var_conta.$var_nossonumero."00".$var_banco;
		$dvagconta = $dvagconta.&calcdig10($dvagconta);
		$dvagconta = &dvbanespa($dvagconta);
	}
	
	#Banco Real 356
	if ($var_banco eq "356") {
		$var_agencia = substr("0000".$var_agencia,-4);
		$var_conta = substr("0000000".$var_conta,-7);
		$var_carteira = substr("00".$var_carteira,-2);
		$dvagconta = &calcdig10($var_nossonumero.$var_agencia.$var_conta);		
	}
	#Banespa 409
	if ($var_banco eq "409") {
		$dvnossonumero = &calcdig11($var_nossonumero,9,0);
		$var_agencia = substr("0000".$var_agencia,-4);
		$var_conta = substr("000000".$var_conta,-6);
		$cod_cliente = substr("0000000".$cod_cliente,-7);
		$dvagconta = &calcdig10($var_agencia.int $var_conta);
	}
	#Bradesco 237
	if ($var_banco eq "237") {
		$dvnossonumero = &dvbradesco($var_nossonumero);
		$var_agencia = substr("0000".$var_agencia,-4);
		$var_conta = substr("0000000".$var_conta,-7);
		$dvagconta = &calcdig11($var_conta,7,1);
	}
	#Banco CEF SICOB
	if ($var_banco eq "104" && $var_dvbanco == 0) {
		$dvnossonumero = &calcdig11($var_nossonumero,9,0);
		$var_agencia = substr("0000".$var_agencia,-4);
		$var_conta = substr("00000".$var_conta,-5);
		$var_carteira = substr("00".$var_carteira,-2);
		$cod_cliente = substr("00000000000".$cod_cliente,-11);
		$dvcodcliente = &calcdig11($cod_cliente,7,1);
	}
	#Banco CEF SIGCB
	if ($var_banco eq "104" && $var_dvbanco == 1) {
		$var_agencia = substr("0000".$var_agencia,-4);
		$var_conta = substr("00000".$var_conta,-5);
		$var_carteira = substr("00".$var_carteira,-2);
		$cod_cliente = substr("000000".$cod_cliente,-6);
		$dvcodcliente = &calcdig11($cod_cliente,7,1);
		$var_nossonumero = $cod_cliente . $dvcodcliente . '90020004' . substr('000000000'.$var_nossonumero,-9);
		$dvnossonumero = &calcdig11($var_nossonumero,9,0);
	}	
	
				
	my $var_valor1 = $var_valordocumento;
	$var_valor1 =~ s/[,.]//g;
	my $var_valor2 = 10 - length($var_valor1);
	my $var_valor = &string($var_valor2,0) . $var_valor1;
	$var_valor = "" if $var_valor1 == 0;
		
	my $var_fatorvencimento = &fatorvencimento($var_datavencimento);
	my $var_codigobarras = &codbar($var_banco,$var_dvbanco,$cons_moeda,$var_fatorvencimento,$var_valor,$var_carteira,$var_nossonumero,$dvnossonumero,$var_agencia,$var_conta,$dvagconta,$cod_cliente);

	#TEMPLATES
	$var_valordocumento =~ s/\./,/g;
	$template{'cedente'} = $var_cedente;	
	$template{'vencimento'} = &FormatDate($var_datavencimento);
	$template{'valor'} = $var_valordocumento;
	$template{'obs'} = $var_observacoes;
	$template{'instrucoes'} = $var_instrucoes ;
	$template{'agencia'} = $var_agencia;
	$template{'dvagencia'} = $dvagencia;
	$template{'conta'} = $var_conta;
	$template{'dvconta'} = $dvagconta;
	$template{'banco'} = $var_banco;
	$template{'dvbanco'} = $var_dvbanco;
	$template{'moeda'} = $cons_moeda;
	$template{'especie'} = $cons_especie;
	$template{'datadoc'} =$var_datadocumento;
	$template{'numerodoc'} = $cons_numerodoc;
	$template{'nossonum'} = $var_nossonumero;
	$template{'nossonum'} = substr($var_nossonumero,0,2)."/".substr($var_nossonumero,2) if $var_banco eq "237" || $var_banco eq "104";
	$template{'nossonum'} = '24/900'. substr($var_nossonumero,-9) if $var_banco eq "104" && $var_dvbanco == 1;
	$template{'dvnosso'} = $dvnossonumero;
	$template{'dvnosso'} =  &calcdig11('24900000'.substr($var_nossonumero,-9),9,0) if $var_banco eq "104" && $var_dvbanco == 1;	
	$template{'codcliente'} = $cod_cliente;	
	$template{'dvcodcli'} = $dvcodcliente;		

	return ($var_codigobarras,$var_banco.'-'.$var_dvbanco) if $var_banco eq "104" && $var_dvbanco == 1;
	return ($var_codigobarras,$var_banco);
}

sub make_menus {
	#menu options
	unless (num(get_skin("$theme","ajax"))) {
		$template{'menu_user'} = qq|<div class="menuitems" url="?do=users"><b>%List%</b></div>| if $r_users =~ /[LF]/;
		$template{'menu_user'} .= qq|<div class="menuitems" url="?do=adduser">%Add%</div>| if $r_users =~ /[IF]/;
		$template{'menu_user'} .= qq|<div class="menuitems" url="?do=user_del">%Del%</div>| if $r_users =~ /[EF]/;
		$template{'menu_user'} .= qq|<div class="menuitems" url="?do=user_edit">%Edit%</div>| if $r_users =~ /[CF]/;
		$template{'menu_user'} .= qq|<div class="menuitems" url="?do=validate">%Validate%</div>| if $r_users =~ /[CF]/;
		$template{'menu_user'} .= qq|<div class="menuitems" url="?do=user_search">%Search%</div>| if $r_users =~ /[RF]/;
		$template{'menu_user_plus'} = qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=users">%List%</a><br>| if $r_users =~ /[LF]/;
		$template{'menu_user_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=user_edit">Visualizar</a><br>| if $r_users =~ /[CF]/;
		$template{'menu_user_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=adduser">%Add%</a><br>| if $r_users =~ /[IF]/;
		$template{'menu_user_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=user_del">%Del%</a><br>| if $r_users =~ /[EF]/;
		$template{'menu_user_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=validate">%Validate%</a><br>| if $r_users =~ /[CF]/;
		$template{'menu_user_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=user_search">%Search%</a><br>| if $r_users =~ /[RF]/;
		$template{'menu_staff_plus'} = qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=staff">%List%</a><br>| if $r_staffs =~ /[LF]/;
		$template{'menu_staff_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Visualizar</a><br>| if $r_staffs =~ /[CF]/;
		$template{'menu_staff_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=addstaff">%Add%</a><br>| if $r_staffs =~ /[IF]/;
		$template{'menu_staff_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">%Del%</a><br>| if $r_staffs =~ /[EF]/;
		$template{'menu_staff_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">%Search%</a><br>| if $r_staffs =~ /[LF]/;
		$template{'menu_ticket'} = qq|<div class="menuitems" url="?do=tickets"><b>%List%</b></div>| if $r_tickets =~ /[LF]/;
		$template{'menu_ticket'} .= qq|<div class="menuitems" url="?do=call_edit">Visualizar</div>| if $r_tickets =~ /[CF]/;
		$template{'menu_ticket'} .= qq|<div class="menuitems" url="?do=log">%Add%</div>| if $r_tickets =~ /[IF]/;
		$template{'menu_ticket'} .= qq|<div class="menuitems" url="?do=call_del">%Del%</div>| if $r_tickets =~ /[EF]/;
		$template{'menu_ticket'} .= qq|<div class="menuitems" url="#">%Search%</div>| if $r_tickets =~ /[LF]/;
		$template{'menu_ticket_plus'} = qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=tickets">%List%</a><br>| if $r_tickets =~ /[LF]/;
		$template{'menu_ticket_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=call_edit">Visualizar</a><br>| if $r_tickets =~ /[CF]/;
		$template{'menu_ticket_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=log">%Add%</a><br>| if $r_tickets =~ /[IF]/;
		$template{'menu_ticket_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=call_del">%Del%</a><br>| if $r_tickets =~ /[EF]/;
		$template{'menu_ticket_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">%Search%</a><br>| if $r_tickets =~ /[LF]/;
		$template{'menu_invoice'} = qq|<div class="menuitems" url="?do=invoice"><b>%Invoices%</b></div>| if $r_invoices =~ /[LF]/;
		$template{'menu_invoice'} .= qq|<div class="menuitems" url="?do=invoice_edit">Visualizar</div>| if $r_invoices =~ /[CF]/;
		$template{'menu_invoice'} .= qq|<div class="menuitems" url="?do=invoice_add">%Invoice_Maker%</div>| if $r_invoices =~ /[IF]/;
		$template{'menu_invoice'} .= qq|<div class="menuitems" url="?do=invoice_chuser">%User_History%</div>| if $r_invoices =~ /[RF]/;
		$template{'menu_invoice'} .= qq|<div class="menuitems" url="?do=invoice_quitar">%Pay_Invoices%</div>| if $r_invoices =~ /[CF]/;
		$template{'menu_invoice'} .= qq|<div class="menuitems" url="?do=saldos_list">Saldos</div>| if $r_invoices =~ /[LF]/;
		$template{'menu_invoice'} .= qq|<div class="menuitems" url="?do=saldos_add">Saldos Adicionar</div>| if $r_invoices =~ /[IF]/;
		$template{'menu_invoice'} .= qq|<div class="menuitems" url="?do=finan">Stats</div>| if $r_super =~ /[RF]/;
		$template{'menu_invoice_plus'} = qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=invoice">%Invoices%</a><br>| if $r_invoices =~ /[LF]/;
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=invoice_edit">Visualizar</a><br>| if $r_invoices =~ /[CF]/;
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=invoice_add">%Invoice_Maker%</a><br>| if $r_invoices =~ /[IF]/;
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=invoice_chuser">%User_History%</a><br>| if $r_invoices =~ /[RF]/;
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=invoice_quitar">%Pay_Invoices%</a><br>| if $r_invoices =~ /[CF]/;
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=saldos_list">Saldos</a><br>| if $r_invoices =~ /[LF]/;
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=saldos_add">Saldos Adicionar</a><br>| if $r_invoices =~ /[IF]/;
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=creditos_list">Créditos</a><br>| if $r_invoices =~ /[LF]/;
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=creditos_add">Créditos Adicionar</a><br>| if $r_invoices =~ /[IF]/;		
		$template{'menu_invoice_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=finan">Stats</a><br>| if $r_super =~ /[RF]/;
		$template{'menu_plan'} = qq|<div class="menuitems" url="?do=planos"><b>%List%</b></div>| if $r_plans =~ /[LF]/;
		$template{'menu_plan'} .= qq|<div class="menuitems" url="?do=plano_view">Visualizar</div>| if $r_plans =~ /[CF]/;
		$template{'menu_plan'} .= qq|<div class="menuitems" url="?do=addplano">%Add%</div>| if $r_plans =~ /[IF]/;
		$template{'menu_plan'} .= qq|<div class="menuitems" url="?do=plano_del">%Delete%</div>| if $r_plans =~ /[EF]/;
		$template{'menu_plan'} .= qq|<div class="menuitems" url="#">%Search%</div>| if $r_plans =~ /[LF]/;
		$template{'menu_plan_plus'} = qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=planos">%List%</a><br>| if $r_plans =~ /[LF]/;
		$template{'menu_plan_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=plano_view">Visualizar</a><br>| if $r_plans =~ /[CF]/;
		$template{'menu_plan_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=addplano">%Add%</a><br>| if $r_plans =~ /[IF]/;
		$template{'menu_plan_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=plano_del">%Del%</a><br>| if $r_plans =~ /[EF]/;
		$template{'menu_plan_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">%Search%</a><br>| if $r_plans =~ /[LF]/;
		$template{'menu_service'} = qq|<div class="menuitems" url="?do=service"><b>%List%</b></div>| if $r_services =~ /[LF]/;
		$template{'menu_service'} .= qq|<div class="menuitems" url="?do=service_edit">Visualizar</div>| if $r_services =~ /[CF]/;
		$template{'menu_service'} .= qq|<div class="menuitems" url="?do=service_add">%Add%</div>| if $r_services =~ /[IF]/;
		$template{'menu_service'} .= qq|<div class="menuitems" url="#">Ativar</div>| if $r_services =~ /[CF]/;
		$template{'menu_service'} .= qq|<div class="menuitems" url="#">Bloquear</div>| if $r_services =~ /[CF]/;
		$template{'menu_service'} .= qq|<div class="menuitems" url="#">Paralizar</div>| if $r_services =~ /[CF]/;
		$template{'menu_service'} .= qq|<div class="menuitems" url="?do=service_del">Cancelar</div>| if $r_services =~ /[EF]/;
		$template{'menu_service'} .= qq|<div class="menuitems" url="?do=service_del&nomail=1">%Delete%</div>| if $r_services =~ /[EF]/;
		$template{'menu_service'} .= qq|<div class="menuitems" url="?do=service_search">%Search%</div>| if $r_services =~ /[RF]/;
		$template{'menu_service_plus'} = qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=service">%List%</a><br>| if $r_services =~ /[LF]/;
		$template{'menu_service_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=service_edit">Visualizar</a><br>| if $r_services =~ /[CF]/;
		$template{'menu_service_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=service_add">%Add%</a><br>| if $r_services =~ /[IF]/;
		$template{'menu_service_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Ativar</a><br>| if $r_services =~ /[CF]/;
		$template{'menu_service_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Bloquear</a><br>| if $r_services =~ /[CF]/;
		$template{'menu_service_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Paralizar</a><br>| if $r_services =~ /[CF]/;
		$template{'menu_service_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=service_del">Cancelar</a><br>| if $r_services =~ /[EF]/;
		$template{'menu_service_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=service_del&nomail=1">%Delete%</a><br>| if $r_services =~ /[EF]/;
		$template{'menu_service_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=service_search">%Search%</a><br>| if $r_services =~ /[RF]/;
		$template{'menu_tool_plus'} = qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=exec">Exec. em massa</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=relato">Relatórios</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=navigator">Navegador</a><br>| if $r_tools =~ /[RF]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=sql">SQL</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Backup</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Restore</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Exportar</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=import">Importar</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=loguser">Logs</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=cron">Cron</a><br>| if $r_tools =~ /[RF]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=manual">Manual</a><br>| if $r_tools =~ /[IF]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Mensagens</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_tool_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=update">Update</a><br>| if $r_tools =~ /[F]/;
		$template{'menu_config_plus'} = qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=settings">Gerais</a><br>| if $r_configs =~ /[CF]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=profile">Pessoais</a><br>| if $r_configs =~ /[RF]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=settings_finan">Financeiro</a><br>| if $r_configs =~ /[CF]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=settings_mail">%Messages%</a><br>| if $r_configs =~ /[CF]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=level">Empresas</a><br>| if $r_configs =~ /[RICF]/;		
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=departments">Departmentos</a><br>| if $r_configs =~ /[RICF]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=globalpre">Respostas Prontas</a><br>| if $r_configs =~ /[ICF]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Código Livre</a><br>| if $r_configs =~ /[CF]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=servers">Servidores</a><br>| if $r_configs =~ /[CF]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">MySQL</a><br>| if $r_configs =~ /[F]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Auto-Signup</a><br>| if $r_configs =~ /[F]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="?do=tpl">Templates</a><br>| if $r_configs =~ /[F]/;
		$template{'menu_config_plus'} .= qq|<img src="$template{'imgbase'}/exp.gif"><a href="#">Linguagem</a><br>| if $r_configs =~ /[F]/;
	} else {
		my $spacer = qq|<div class="submenu_item"></div><div class="submenu_spacer"><img border=0 width="142" height="1" src="$template{'imgbase'}/separador-menu-5.gif"></div>|;		
		$template{'menu_user'} = qq|<div class="submenu_item" onClick="href('$template{link_users_list}')">%List%</div>$spacer| if $r_users =~ /[LF]/;
		$template{'menu_user'} .= qq|<div class="submenu_item" onClick="href('$template{link_users_add}')">%Add%</div>$spacer| if $r_users =~ /[IF]/;
		$template{'menu_user'} .= qq|<div class="submenu_item" onClick="href('$template{link_users_del}')">%Del%</div>$spacer| if $r_users =~ /[EF]/;
		$template{'menu_user'} .= qq|<div class="submenu_item" onClick="href('$template{link_users_edit}')">%Edit%</div>$spacer| if $r_users =~ /[CF]/;
		$template{'menu_user'} .= qq|<div class="submenu_item" onClick="href('$template{link_users_validate}')">%Validate%</div>$spacer| if $r_users =~ /[CF]/;
		$template{'menu_user'} .= qq|<div class="submenu_item" onClick="href('$template{link_users_search}')">%Search%</div>$spacer| if $r_users =~ /[LF]/;
		$template{'menu_ticket'} = qq|<div class="submenu_item" onClick="href('$template{link_tickets_list}')">%List%</div>$spacer| if $r_tickets =~ /[LF]/;
		$template{'menu_ticket'} .= qq|<div class="submenu_item" onClick="href('$template{link_tickets_view}')">%View%</div>$spacer| if $r_tickets =~ /[CF]/;
		$template{'menu_ticket'} .= qq|<div class="submenu_item" onClick="href('$template{link_tickets_add}')">%Add%</div>$spacer| if $r_tickets =~ /[IF]/;
		$template{'menu_ticket'} .= qq|<div class="submenu_item" onClick="href('$template{link_tickets_del}')">%Del%</div>$spacer| if $r_tickets =~ /[EF]/;
		$template{'menu_ticket'} .= qq|<div class="submenu_item" onClick="href('$template{link_tickets_search}')">%Search%</div>$spacer| if $r_tickets =~ /[LF]/;
				
	}			
}

sub cpuload {
#Muito lento
	my @CPU;
	@CPU = split m|PU$/|, qx/ps ao %CPU m/ if $WIN == 0;
	@CPU = split /\n/,qx/wmic CPU GET loadpercentage/ if $WIN == 1;

	my $i = 0; my $sum;
	foreach (@CPU) {
		$i++;
		next if $i < 3 && $WIN == 0;
		next if $i < 2 && $WIN == 1;
		$sum += $_;
	}
	
	return int $sum;
}

sub Post2Get {
	my $q = shift; #CGI Handler
	my @pairs = split(/;/, $q->query_string());
	my $post;
	foreach $pair (@pairs) {
	    my ($name, $value) = split(/=/, $pair);
	    $value =~ tr/+/ /;
	    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	    $post .= "$name=$value&";
	}
	$ENV{'QUERY_STRING'} = "$post";
}

# Perl trim function to remove whitespace from the start and end of the string
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
# Left trim function to remove leading whitespace
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}

sub progress {
	my $part = shift;
	
	if ($part eq "start") {
		return qq~<html>
<head>
<script language="JavaScript1.1">
var w3c=(document.getElementById)?true:false;
var ie=(document.all)?true:false;
var N=-1;

function createBar(w,h,bgc,brdW,brdC,blkC,speed,blocks,count,action){
if(ie||w3c){
var t='<div id="_xpbar'+(++N)+'" style="visibility:visible; position:relative; overflow:hidden; width:'+w+'px; height:'+h+'px; background-color:'+bgc+'; border-color:'+brdC+'; border-width:'+brdW+'px; border-style:solid; font-size:1px;">';
t+='<span id="blocks'+N+'" style="left:-'+(h*2+1)+'px; position:absolute; font-size:1px">';
for(i=0;i<blocks;i++){
t+='<span style="background-color:'+blkC+'; left:-'+((h*i)+i)+'px; font-size:1px; position:absolute; width:'+h+'px; height:'+h+'px; '
t+=(ie)?'filter:alpha(opacity='+(100-i*(100/blocks))+')':'-Moz-opacity:'+((100-i*(100/blocks))/100);
t+='"></span>';
}
t+='</span></div>';
document.write(t);
var bA=(ie)?document.all['blocks'+N]:document.getElementById('blocks'+N);
bA.bar=(ie)?document.all['_xpbar'+N]:document.getElementById('_xpbar'+N);
bA.blocks=blocks;
bA.N=N;
bA.w=w;
bA.h=h;
bA.speed=speed;
bA.ctr=0;
bA.count=count;
bA.action=action;
bA.togglePause=togglePause;
bA.showBar=function(){
this.bar.style.visibility="visible";
}
bA.hideBar=function(){
this.bar.style.visibility="hidden";
}
bA.tid=setInterval('startBar('+N+')',speed);
return bA;
}}

function startBar(bn){
var t=(ie)?document.all['blocks'+bn]:document.getElementById('blocks'+bn);
if(parseInt(t.style.left)+t.h+1-(t.blocks*t.h+t.blocks)>t.w){
t.style.left=-(t.h*2+1)+'px';
t.ctr++;
if(t.ctr>=t.count){
eval(t.action);
t.ctr=0;
}}else t.style.left=(parseInt(t.style.left)+t.h+1)+'px';
}

function togglePause(){
if(this.tid==0){
this.tid=setInterval('startBar('+this.N+')',this.speed);
}else{
clearInterval(this.tid);
this.tid=0;
}}

function togglePause(){
if(this.tid==0){
this.tid=setInterval('startBar('+this.N+')',this.speed);
}else{
clearInterval(this.tid);
this.tid=0;
}}
</script>

<style type="text/css">
<!--
#Layer1 {
	position:absolute;
	left:231px;
	top:35px;
	width:307px;
	height:25px;
	z-index:1;
}
.style2 {
	font-size: 14px;
	font-family: "Courier New", Courier, monospace;
}
-->
</style>
</head>

<body bgcolor="#FFFFFF">
<center>
	
  <span id="pro" style="visibility:visible;" class="style2">Processing...</span>
  <script type="text/javascript">
var bar1= createBar(250,8,'F7F6F4',1,'A3AAB4','4762B9',85,20,3,"");
  </script><span id="pro">
~;
	} elsif ($part eq "end") {
		return qq|</span></center>

</body>
</html>|;
	} elsif ($part eq "pause") {
		return qq|<script>bar1.togglePause();</script>|;
	} elsif ($part eq "hide") {
		return qq|<script>bar1.hideBar();
					document.getElementById('pro').style.visibility="hidden";</script>|;	
	} elsif ($part eq "waitimg") {
		my @img = @_;
		my $tmp .= qq|<script>
			var loaded = new Array(),i,currCount = 0,preImages = new Array()
			var yourImages = new Array("|.join(",",@img).qq|")
			
			function loadImages() { 
				for (i = 0; i < yourImages.length; i++) { 
					preImages[i] = new Image()
					preImages[i].src = yourImages[i]
				}
				for (i = 0; i < preImages.length; i++) { 
					loaded[i] = false
				}
				checkLoad()
			}
			function checkLoad() {
				if (currCount == preImages.length) { 
					bar1.hideBar();
					document.getElementById('pro').style.visibility="hidden";
					return;
				}
				for (i = 0; i <= preImages.length; i++) {
					if (loaded[i] == false && preImages[i].complete) {
						loaded[i] = true
						currCount++
					}
				}
				setTimeout("checkLoad()",10) 
			}
			loadImages();</script>
		|;

		return $tmp;	
	}
}

sub cc_verify { #validar cartao de credito
    my ($number) = @_;
    my ($i, $sum, $weight);

    return 0 if $number =~ /[^\d\s\-]/;

    $number =~ s/\D//g;

    return 0 unless length($number) >= 13 && 0+$number;

    for ($i = 0; $i < length($number) - 1; $i++) {
    $weight = substr($number, -1 * ($i + 2), 1) * (2 - ($i % 2));
    $sum += (($weight < 10) ? $weight : ($weight - 9));
    }

    return 1 if substr($number, -1) == (10 - $sum % 10) % 10;
    return 0;
}

sub cc_exp_verify {
    my ($cc_exp_mon, $cc_exp_yr) = @_;

    my ($month, $year) = (localtime)[4,5];
    $month++;
    $year += 1900;

    if (12 * $year + $month <= 12 * $cc_exp_yr + $cc_exp_mon) {
        return 1;
    } else {
        return 0;
    }
}

sub can_auto {
	my $plan = shift;
	
	my ($tipo,$plataforma,$modulo) = split(" - ",Plano($plan,"tipo plataforma modulo"));
	
	if ($tipo eq "Hospedagem" || $tipo eq "Revenda") {
		my ($status) = split(" - ",Servidor($global{$plataforma.$tipo}, "ativo"));
		return $status;
	} elsif ($tipo eq "Registro") {
		return 1 if $modulo;		
	}
	
	return 0;
}

1;
$cookname = $q->cookie('user');
$cookpass = $q->cookie('cert');
$cooktzo = $q->cookie('tzo');
$system->{cookname} = $q->cookie('user');

$sect = "admin";
$ufile = $sect.".cgi";

sub check_user 
{
	if ((!$cookname) || ($cookname eq "") || (!$ENV{'HTTP_USER_AGENT'})) {
		$ignore = 1;
		if ($q->param('do') ne "login" && $q->param('do')) {
			$template{'error'} = $LANG{not_loggedin};
		}
		section("login");
		exit;	
	}
	$sth = select_sql(qq|SELECT * FROM `staff` WHERE `username` = ?|,$cookname); 
	while(my $ref = $sth->fetchrow_hashref()) {  
		$dbuser = $template{'ucname'} = $ref->{'username'};
		$template{'namez'} = $ref->{'name'};
		$accesslevel = $ref->{'access'};
		$is_admin = $ref->{'admin'};
		$template{'emailz'} = $ref->{'email'};
		$dbrkey = $ref->{'rkey'};
		$th = select_sql(qq|SELECT * FROM `online` WHERE `username` = "$dbuser" AND `agent` = ?|,$ENV{'HTTP_USER_AGENT'});
		execute_sql(qq|INSERT INTO `online` VALUES ('$dbuser','$ENV{'HTTP_USER_AGENT'}','0', '$cooktzo')|) if $th->rows eq 0;
		$th->finish;
	}
	$sth->finish;
	
	$md5 = Digest::MD5->new;
	$md5->reset;
	
	$certif = $dbuser . "pd-$dbrkey" . $ENV{'HTTP_USER_AGENT'} . $ENV{'REMOTE_ADDR'} if  $IP_IN_COOKIE ;
	$certif = $dbuser . "pd-$dbrkey" . $ENV{'HTTP_USER_AGENT'} if !$IP_IN_COOKIE ;
	$md5->add($certif);
	$enc_cert = $md5->hexdigest();

	if($enc_cert eq $cookpass){
		#remover qd a area de staff for junto com a de admin
		die_nice("Você não tem direitos a esta área.") if $is_admin ne 1;
		print cookies(0,$global{'admin_timeout'}.'m','','user:'.$cookname,'cert:'.$cookpass);#mais 30 minutos

		#reload rights
		our ( $r_users, $r_invoices, $r_staffs, $r_tickets, $r_plans, $r_services, $r_tools, $r_configs, $r_super, $rd_users ) = load_rights($cookname);

		#hash destroy template
		foreach (keys %template) {
			delete $template{$_} if /^menu_/i;
		}
	} else {
		$ignore = 1;
		if ($q->param('do') ne "login" && $q->param('do')) {
			$template{'error'} = qq|<br><br><b>Falha na autenticação.<br>Você deve se logar no sistema para ver esta página.<b><br><br><br>|;
		}
		section("login");
		exit;
	}
}

my $server = $q->param('server_ctrl');
my $port = $q->param('server_port');
my $user = $q->param('user');
$template{'server'} = $server;
my %self;
my $statement = qq|SELECT * FROM `servidores` WHERE `id` = $server|; 
my $sth = $dbh->prepare($statement);
$sth->execute();
while(my $ref = $sth->fetchrow_hashref()) {	
	for (keys %$ref) {
		$self->{$_} = $ref->{$_};
	}
}
$sth->finish;

die_nice("Especifique um Servidor") if !$server || !$self->{'host'};

$port ||= "80" if $self->{'os'} eq "L";
$port ||= "80" if $self->{'os'} eq "W";
$user ||= $self->{username};

my $cleanaccesshash = $self->{'key'};
$cleanaccesshash =~ s/[\r|\n]*//g;

my $query = $ENV{'QUERY_STRING'};
$query =~ s/\%2F/\//g;
$query =~ s/server_ctrl\=$server\&?//;
$query =~ s/server_port\=$port\&?//;
$query =~ s/user\=$user\&?//;
$query =~ s/nocache\=.*$//;
$query =~ s/url\=/url\=\/scripts\// if $query !~ /url\=\//;
if ($query =~ /url\=.*\&/ && $query !~ /\?/) {
	$query =~ s/url\=(.*?)\&/$1\?/;
} else {
	$query =~ s/url\=//;
}

my $md5 = Digest::MD5->new;
$md5->reset;
my $ip = $ENV{'REMOTE_ADDR'};
$md5->add("$user$cleanaccesshash$year$month_no$date_no");
my $key = $md5->hexdigest();
my $ncache = time();

print "Location: http://".$self->{'host'}.":$port/controller.php?username=$user&key=$key&nocache=$ncache\n\n" if $self->{'os'} eq "L";
print "Location: http://".$self->{'host'}.":$port/controller.asp?username=$user&key=$key&nocache=$ncache\n\n" if $self->{'os'} eq "W";
	
1;
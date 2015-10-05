use Helm::Membros;
use Sys::Hostname;
use Socket;
use Digest::MD5;

sub get_helm 
{
 my $server = shift;
 my %helm;
 my $statement = qq|SELECT * FROM `servidores` WHERE id = $server|; 
 my $sth       = $dbh->prepare($statement);
	$sth->execute();
    while(my $ref = $sth->fetchrow_hashref()) {
		for (keys %$ref) {
			next if $_ eq "key";
			$helm{$_} = $ref->{$_};
		}
	}
	$sth->finish;
	return %helm;     
}

sub vars 
{
	my $server = shift;
	my %helm_server		=  get_helm($server);
	$helm               =  Helm::Membros->new;
	$helm->{host}       =  $helm_server{'host'};
	$helm->{user}       =  $helm_server{'username'}; 
	$helm->{port}		=  $helm_server{'port'};
	$helm->{usessl}     =  $helm_server{'ssl'};
	$helm->{ns1}        =  $helm_server{'ns1'};
	$helm->{ns2}        =  $helm_server{'ns2'};
	$helm->{accesshash} =  get_helm_key($server);
}

sub get_helm_key 
{
	my $server = shift;
	my $statement = qq|SELECT `username`,`key` FROM servidores WHERE id = ?|; 
	my $sth = $dbh->prepare($statement) or die print "Couldn't prepare statement: $DBI::errstr; stopped";
	$sth->execute($server) or die print "Couldn't execute statement: $DBI::errstr; stopped";
	my ($user,$key) = $sth->fetchrow_array();

	my $md5 = Digest::MD5->new;
	$md5->reset;
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
	$year = 1900 + $year;
	$mon++;
	$mday  = "0$mday" if ($mday < 10);
	$mon = "0$mon" if ($mon < 10);	
	my($ip)=inet_ntoa((gethostbyname(hostname))[4]);
	$md5->add($user.$key.$ip.$year.$mon.$mday);
	$key = $md5->hexdigest();
	
	return $key;
}
  
sub reseller_plans
{
	my $server = shift;
	vars($server);
	
	%PKGS = $helm->plansR();

	return %PKGS;
}

sub hosting_plans
{
	my $server = shift;
	vars($server);

	my ($userhost) = @_;

	%PKGS = $helm->plansH($userhost);
	
	return %PKGS;
}
 
sub create_helm_res
{
	my $server = shift;
	my @helm_details = @_;
    vars($server);

	push(@helm_details,$helm->{'ns1'},$helm->{'ns2'});

    @response = $helm->creseller(@helm_details);
   
    if ($helm->{error} ne "") { die("There was an error while processing your request: '$helm_details[11]' $helm->{error}\n"); }       
	
	return (@response);
 }
  
sub create_helm_acc
{
	my $server = shift;
	my @helm_details = @_;
    vars($server);
	
	push(@helm_details,$helm->{'ns1'},$helm->{'ns2'});
    
	@response   =  $helm->chospedagem(@helm_details);
    
	if ($helm->{error} ne "") { die("There was an error while processing your request: $helm->{error}\n"); }       
	
	return (@response); 
 }

sub suspend_helm 
 {  
	 my $server = shift;
     vars($server);
     my ($user,$dominio,$reseller) = @_;

     @response = $helm->suspend_h("$user","$dominio","$reseller");
	 
     if ($helm->{error} ne "") { die("There was an error while processing your request: '$dominio' $helm->{error}\n"); }       

	 return (@response); 
 }

sub unsuspend_helm
 {    
	 my $server = shift;
     vars($server);
     my ($user,$dominio,$revenda) = @_;

     @response = $helm->unsuspend_h("$user","$dominio","$revenda");

     if ($whm->{error} ne "") { die("There was an error while processing your request: '$dominio' $whm->{error}\n"); }       

	 return (@response);

}
 
sub remove_helm 
{  
	my $server = shift;
	vars($server);
	my ($user,$dominio,$reseller,$ns1,$ns2) = @_;

	@response = $helm->removeacct("$user","$dominio","$reseller","$ns1","$ns2");

    if ($helm->{error} ne "") { die("There was an error while processing your request: '$dominio' $helm->{error}\n"); }      

	return (@response);

}
 
sub updown_helm
{
	my $server = shift;
    vars($server);
    my ($user,$dominio,$plano,$nome) = @_;
	
	@response = $helm->updown_h("$user","$dominio","$plano","$nome");

    if ($helm->{error} ne "") { die("There was an error while processing your request: '$dominio' $helm->{error}\n"); }  
	
	return (@response);     
}

sub updown_helm_res
{
	my $server = shift;
    vars($server);
    my ($user,$plano,$nome) = @_;
		
	@response = $helm->updown_hres("$user","$plano","$nome");
  
    if ($helm->{error} ne "") { die("There was an error while processing your request: '$user' $helm->{error}\n"); }  
	
	return (@response);      
}
 
1;
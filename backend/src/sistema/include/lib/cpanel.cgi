use Cpanel::Membros;

sub get_cpanel
{
 my $server = shift;
 my %cpanel;
 my $statement = qq|SELECT * FROM servidores WHERE id = $server|; 
 my $sth       = $dbh->prepare($statement);
	$sth->execute();
	while(my $ref = $sth->fetchrow_hashref()) {
		for (keys %$ref) {
			next if $_ eq "key";
			$cpanel{$_} = $ref->{$_};
		}
	}
	$sth->finish;
	return %cpanel;     
}

sub varw 
 {
   my $server = shift;
   my %cpanel  		  =  get_cpanel($server);
   $whm               =  Cpanel::Membros->new;
   $whm->{host}       =  $cpanel{'host'};
   $whm->{ip}       =  $cpanel{'ip'}; 
   $whm->{user}       =  $cpanel{'username'};
   $whm->{ip}         =  $cpanel{'ip'};
   $whm->{ns1}        =  $cpanel{'ns1'};
   $whm->{ns2}        =  $cpanel{'ns2'};
   $whm->{port}		  =  $cpanel{'port'};
   $whm->{usessl}     =  $cpanel{'ssl'};
   $whm->{accesshash} =  get_cpanel_key($server);
 }


 sub get_cpanel_key 
  {
 	 my $server = shift;
     my $statement = qq|SELECT `key` FROM servidores WHERE id = ?|; 
     my $sth       = $dbh->prepare($statement) or die print "Couldn't prepare statement: $DBI::errstr; stopped";
        $sth->execute($server) or die print "Couldn't execute statement: $DBI::errstr; stopped";
      while(my $ref = $sth->fetchrow_hashref()) 
         {
                 $key = "$ref->{'key'}";
         } 
        $sth->finish;
        return $key;
  }

sub cpget_list 
 {
	 my $server = shift;
     varw($server);
   
     %PKGS = $whm->listpkgs();

     foreach $package (sort keys %PKGS) 
      {
           $template{'planos'} .= qq|<option value=$package>$package</option>
		   							|;
      } 
 }

sub suspend_cpanel 
 {  
	 my $server = shift;
     varw($server);
     my ($username,$reseller) = @_;

     my @response = $whm->suspend_c("$username","$reseller");
	 
     if ($whm->{error} ne "") { die("There was an error while processing your request: '$username' $whm->{error}\n"); }       
	
	 return (@response);
 }

sub unsuspend_cpanel 
 {  
	 my $server = shift;
     varw($server);
     my ($username,$revenda) = @_;

	 my @response = $whm->unsuspend_c("$username","$revenda");
     if ($whm->{error} ne "") { die("There was an error while processing your request: '$username' $whm->{error}\n"); }       

	 return (@response);
 }

sub kill_cpanel 
 {  
	my $server = shift;
	varw($server);
	my ($username,$reseller) = @_;

	my @response = $whm->killacct("$username","$reseller");

    if ($whm->{error} ne "") { die("There was an error while processing your request: '$username' $whm->{error}\n"); }      

	return (@response);

 }

sub updown_cpanel
 {
	my $server = shift;
    varw($server);
    my %cp_details = @_;
	my %PKGS = $whm->listpkgs();
 
	die("Plano $cp_details{'package'} inexistente! Host: $whm->{host}") unless defined($PKGS{$cp_details{'package'}});    
	
    my @response = $whm->updown("$cp_details{'username'}","$cp_details{'package'}");

    if ($whm->{error} ne "") { die("There was an error while processing your request: '$cp_details{'username'}' $whm->{error}\n"); }  

	return (@response);     
 }

sub updown_cpanel_res
{
	my $server = shift;
	varw($server);
	my %cp_details = @_;
	my ($disk,$bw) = split(" ",$cp_details{'package'});

	my @response = $whm->updown_res("$cp_details{'username'}","$disk","$bw","$cp_details{'domain'}");

	if ($whm->{error} ne "") { die("There was an error while processing your request: '$cp_details{'username'}' $whm->{error}\n"); }
	
	return (@response);
 }

sub create_cpanel_acc
 {
	my $server = shift;
	varw($server);
	my %cp_details = @_;
	my %PKGS = $whm->listpkgs();
 
	die("Plano $cp_details{'package'} inexistente!") unless defined($PKGS{$cp_details{'package'}});
	
	$userinc = $whm->defineuser($cp_details{'domain'});    
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$cp_details{'password'} = $chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)] if $cp_details{'password'} =~ m/$userinc/;	

	my @response   =  $whm->createacct("$cp_details{'domain'}","$cp_details{'password'}","$cp_details{'package'}","$cp_details{'userhosp'}");

	if ($whm->{error} ne "") { die("There was an error while processing your request: '$cp_details{'domain'}' $whm->{error}\n"); }       

	return (@response);
 }

sub create_cpanel_res
 {
	my $server = shift;
    varw($server);
    my %cp_details = @_;
    my @response  =  $whm->createres("$cp_details{'domain'}","$cp_details{'password'}","$cp_details{'package'}","$cp_details{'disk'}","$cp_details{'bw'}");
	
    if ($whm->{error} ne "") { die("There was an error while processing your request: '$cp_details{'domain'}' $whm->{error}\n"); }       
	
	return (@response);
 }


1;
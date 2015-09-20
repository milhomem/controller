#use ResellOne::Epp;

sub vars_opensrs
{
	#TODO colocar resellone.net nas confs
	$opensrs = ResellOne::Epp->new;
	$opensrs->{host} = "https://resellers.resellone.net";
	$opensrs->{port} = "52443"; #HTTP: 55000 HTTPS: 52443
	$opensrs->{username} = "HHH"; 
	$opensrs->{private_key} = "xxxxx";
}

sub opensrs_availdomain
{  
	my $dominio = shift;
	my ($free,$reason);
 	vars_opensrs();

	($free,$reason) = $opensrs->domain_check($dominio);
	
	#free 210 - Disponivel, 211 - Registrado
	$free = $free == 210 ? 1 : 0;

	return ('','',$opensrs->{'ERR'}) if $opensrs->{'ERR'};
	 
	return ($free,$reason);
}

sub opensrs_adddomain
{  
	my ($domain,$cnpj,$renew,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,
			 $ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6) = @_;
 	vars_opensrs();

	($ticket) = $opensrs->domain_create($link,$domain,$cnpj,$renew,$ns1,$ip1v4,$ip1v6,$ns2,$ip2v4,$ip2v6,$ns3,$ip3v4,$ip3v6,$ns4,$ip4v4,$ip4v6,$ns5,$ip5v4,$ip5v6);

	return ('',$opensrs->{'ERR'}) if $opensrs->{'ERR'};

	return ($ticket);
}

1;
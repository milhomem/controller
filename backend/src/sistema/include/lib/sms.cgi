sub vars_sms 
{
	$global{'sms_modulo'} = 'SMS::Human' unless $global{'sms_modulo'};
	eval "use ".$global{'sms_modulo'};
	my $sms = eval "new ".$global{'sms_modulo'};
	($sms->{host},$sms->{port}) = split(":",$global{'sms_host'},2);
	$sms->{port} ||= 80;
	$sms->{pass} = $global{'sms_pass'};
	$sms->{from} = URLEncode($global{'sms_from'});
	$sms->{user} = $global{'sms_user'};
}

sub sms_send
{  
	my ($ddi,$nro,$msg) = @_;
 	vars_sms();

	$msg = URLEncode($msg);

	my $resultado = $sms->send("$ddi","$nro","$msg");

	return (0,$sms->{'error'}) if $sms->{'error'};

	if(!$resultado){
		return(0,"Erro de comunicação com o servidor");
	} else {
		return split(",",$resultado,2);
	}
	
	return(0,"Erro desconhecido");
}

1;
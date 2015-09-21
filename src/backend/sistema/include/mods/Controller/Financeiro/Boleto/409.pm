#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2011
# Banco 409 - ITAÚ/UNIBANCO
package Controller::Financeiro::Boleto::409;

require 5.008;

sub init { return __PACKAGE__; }

sub var_numero {
	return 14;
}

sub var_nossonumero {
	my $self = shift;
	
	my $id = $self->invoice('nossonumero') > 0 ? $self->invoice('nossonumero') : $self->invid;
	my $nossonumero = substr($self->string(20,0) . $id,-&var_numero($self));
	die $self->lang(73,$self->invid,$self->account('nome')) if length($id) > &var_numero($self);
	return $nossonumero;
}

sub dvDig11 {
	my $self = shift;
	my $cadeia = shift;
	my $limitesup = shift;
	my $lflag = shift;
	
	my $ndig;
	my $nresto =  $self->calcdig11($cadeia,$limitesup);

	if ($nresto == 0 || $nresto == 1) {
		$ndig = $lflag == 1 ? 1 : 0;
	}else{		
		$ndig = 11 - $nresto;
	}

	return $ndig; 	
}

sub dvnosso {
	my $self = shift;
	return &dvDig11($self, &var_nossonumero($self),9,0);
}

sub dvagconta {
	my $self = shift;
	my $var_agencia = substr('0000'.$self->account('agencia'),-4);
	my $var_conta = substr('000000'.$self->account('conta'),-6);	
	return $self->calcdig10($var_agencia . int $var_conta); #TODO se tiver o manual algum dia verificar se ta certo.
}

sub cod_cliente {
	return substr('0000000'.$_[0]->account('convenio'),-7);
}

sub codbar {
	my $self = shift;	
	
	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.'5'.&cod_cliente($self).'00'.&var_nossonumero($self).&dvnosso($self);
	my $dv3 = &dvDig11($self, $strcodbar,9,1);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.'5'.&cod_cliente($self).'00'.&var_nossonumero($self).&dvnosso($self);
	
	return $codbar;
}

sub parse_boleto {	
	my $self = shift;
	
	my $nossonumero = &var_nossonumero($self);
	$self->template('nossonum', $nossonumero);			
	$self->template('dvnosso',&dvnosso($self));
	$self->template('dvagencia',&dvagconta($self));
	$self->template('dvconta','');
	
	$self->parse('/boleto/unibanco');
}
1;
#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2011
# Banco 356 - SANTANDER/REAL
package Controller::Financeiro::Boleto::356;

require 5.008;	

sub init { return __PACKAGE__; }

sub var_numero {
	return 13;
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

sub dvagconta {
	my $self = shift;
	my $agencia = substr('0000'.$self->account('agencia'),-4);
	my $conta = substr('0000000'.$self->account('conta'),-7);	
	return $self->calcdig10(&var_nossonumero($self).$agencia.$conta);	 
}

sub codbar {
	my $self = shift;
	
	my $agencia = substr('0000'.$self->account('agencia'),-4);
	my $conta = substr('0000000'.$self->account('conta'),-7);
	my $carteira = substr('00'.$self->account('carteira'),-2);
	
	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.$agencia.$conta.&dvagconta($self).&var_nossonumero($self);
	my $dv3 = &dvDig11($self, $strcodbar,9,1);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.$agencia.$conta.&dvagconta($self).&var_nossonumero($self);

	return $codbar;		
}

sub parse_boleto {
	my $self = shift;
	
	my $nossonumero = &var_nossonumero($self);
	$self->template('nossonum', $nossonumero);			
	$self->template('dvnosso','');
	$self->template('dvagencia','');
	$self->template('dvconta',&dvagconta($self));
	
	$self->parse('/boleto/real');
}
1;
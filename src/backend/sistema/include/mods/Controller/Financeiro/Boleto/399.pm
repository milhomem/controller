#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2011
# Banco 399 - HSBC
package Controller::Financeiro::Boleto::399;

require 5.008;

sub init { return __PACKAGE__; }

sub var_numero {
	return 13;
}

sub format {
	my $self = shift;
	$self->account('convenio', substr('0000000'.$self->account('convenio'),-7));
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
	
	if ($lflag == 2) {
		$ndig = $nresto > 9 ? 0 : $nresto; #HSBC Se o resto for igual a 0 ou 10, o dígito é 0 (zero) se não é o próprio resto
	}elsif ($nresto == 0 || $nresto == 1) {
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
	return $self->calcdig10($var_agencia . int $var_conta);
}

sub julianday {
	return substr('000'.($_[0]->invoice('data_vencimento') - $_[0]->date($_[0]->invoice('data_vencimento')->year.'-01-01') + 1),-3) . substr($_[0]->invoice('data_vencimento')->year,-1);
}

sub cod_cliente {
	return substr('0000000'.$_[0]->account('convenio'),-7);
}

sub codbar {
	my $self = shift;	
	
	&format($self);
	
	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.&cod_cliente($self).&var_nossonumero($self).&julianday($self).'2'; #2 = CNR
	my $dv3 = &dvDig11($self, $strcodbar,9,1);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.&cod_cliente($self).&var_nossonumero($self).&julianday($self).'2';
	
	return $codbar;
}

sub parse_boleto {	
	my $self = shift;
	
	my $id = int &var_nossonumero($self);
	my $reverse = reverse $id;	
	my $nossonumero = substr($self->string(20,0) . $id,-&var_numero($self));
	$nossonumero = $nossonumero.&dvDig11($self, $reverse,9,2).'4'; #4 Com vencimento, 5 Sem vencimento
	my @ymd = $self->invoice('data_vencimento')->as_ymd;
	my $vencimento = substr('00'.$ymd[2],-2).substr('00'.$ymd[1],-2).substr('00'.$ymd[0],-2);

	$nossonumero = $nossonumero.&dvDig11($self, $nossonumero + &cod_cliente($self) + $vencimento,9,2);

	$self->template('nossonum', $nossonumero);
	$self->template('dvnosso',&dvnosso($self));
	$self->template('dvagencia',&dvagconta($self));
	$self->template('codcliente', &cod_cliente($self));	
	$self->template('dvcodcli','');	
	$self->template('dvconta','');
	
	$self->parse('/boleto/hsbc');
}
1;
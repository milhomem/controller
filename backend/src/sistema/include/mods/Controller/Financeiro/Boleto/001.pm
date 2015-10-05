#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2011
package Controller::Financeiro::Boleto::001;

require 5.008;

sub init { return __PACKAGE__; }

sub var_numero {
	return 5;
}

sub dvDig11 {
	my $self = shift;
	my @params = @_;
	
	my $ndig;
	my $nresto =  $self->calcdig11(@params);

	if ($nresto == 0 || $nresto == 1) { 			 
		$ndig = 1;
	}else{
		$ndig = 11 - $nresto; #Implicito  || $nresto == 10 => ndig = 1
	}

	return $ndig; 	
}

sub dvbancobrasil {
	my $self = shift;
	my $num = shift;
	my $resto = "";
	my $digito = "";
	
	$resto = $self->calcdig11($num, 7);
	$digito = 11 - $resto;
	if ($resto == 10) {
		$digito = "X";
	} elsif ($resto == 0) {
		$digito = 0;
	}

	return "$digito";
}

sub var_nossonumero {
	my $self = shift;
	my $numero = 12 - length($self->account('convenio'));
	
	my $convenio = $self->account('convenio') . $self->string($numero,0);
	my $nossonumero = substr($self->string(20,0) . $self->invid,-&var_numero($self));
	die $self->lang(73,$self->invid,$self->account('nome')) if length($self->invid) > &var_numero($self);
	$nossonumero = $convenio . $nossonumero;	
	return $nossonumero;
}

sub dvnosso {
	my $self = shift;
	my $nossonumero = defined $_[0] ? $_[0] : &var_nossonumero($self);
	return &dvDig11($self, $nossonumero,9);
}
	
sub codbar {
	my $self = shift;
	
	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.'000000'.&var_nossonumero($self).$self->account('carteira');
	my $dv3 = &dvDig11($self, $strcodbar,9);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.'000000'.&var_nossonumero($self).$self->account('carteira');
	
	return $codbar;		
}

sub parse_boleto {
	my $self = shift;
	my $nossonumero = &var_nossonumero($self);
	$self->template('nossonum', substr($nossonumero,0,2).'/'.substr($nossonumero,2));
	my $conta = substr("00000000".$self->account('conta'),-8);		
	$self->template('dvnosso',&dvnosso($self,$nossonumero));
	$self->template('dvagencia',&dvbancobrasil($self,$self->account('agencia')));
	$self->template('dvconta',&dvbancobrasil($self,$conta));
	$self->parse('/boleto/brasil');	
}
1;
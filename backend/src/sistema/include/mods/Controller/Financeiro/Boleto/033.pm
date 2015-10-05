#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2011
# Banco 033 - SANTANDER/BANESPA
package Controller::Financeiro::Boleto::033;

require 5.008;

sub init { return __PACKAGE__; }

sub var_numero {
	return 13-1; #-1 dv
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
	my $nresto = $self->calcdig11($cadeia,$limitesup);
	
	if ($nresto == 0 || $nresto == 1) {
		$ndig = $lflag == 1 ? 1 : 0;
	}else{		
		$ndig = 11 - $nresto; 
	}

	return $ndig; 	
}

sub dvnosso {
	my $self = shift;
	my $nossonumero = defined $_[0] ? $_[0] : &var_nossonumero($self);
	return &dvDig11($self, $nossonumero,9,0);
}

sub format {
	my $self = shift;
	$self->account('agencia', substr('0000'.$self->account('agencia'),-4));
	$self->account('conta', substr('000000000'.$self->account('conta'),-9));
	$self->account('carteira', substr('000'.$self->account('carteira'),-3));
	$self->account('convenio', substr('0000000'.$self->account('convenio'),-7));
}

sub codbar {
	my $self = shift;

	my @settings = $self->settings;
	my $iof = 0;
	$iof = int($self->setting('IOF')) if (grep {m/^IOF$/} @settings);
	die 'IOF Invalid' unless $iof == 0 || ($iof >= 7 && $iof <= 9);
	
	&format($self);
	
	my $nossonumero = &var_nossonumero($self);
	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.'9'.$self->account('convenio').$nossonumero.&dvnosso($self,$nossonumero).$iof.$self->account('carteira');	
	my $dv3 = &dvDig11($self, $strcodbar,9,1);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.'9'.$self->account('convenio').$nossonumero.&dvnosso($self,$nossonumero).$iof.$self->account('carteira');

	return $codbar;		
}
	
sub parse_boleto {
	my $self = shift;
	
	my $nossonumero = &var_nossonumero($self);
	$self->template('nossonum', $nossonumero);			
	$self->template('dvnosso',&dvnosso($self,$nossonumero));
	$self->template('dvagencia','');
	$self->template('dvconta','');
		
	$self->parse('/boleto/banespa');	
}

1;
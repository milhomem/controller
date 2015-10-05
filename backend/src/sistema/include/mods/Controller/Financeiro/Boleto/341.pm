#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2011
# Banco 341 - ITAÚ
package Controller::Financeiro::Boleto::341;

require 5.008;

sub init { return __PACKAGE__; }

sub var_numero {
	return 8;
}

sub var_nossonumero {
	my $self = shift;
	
	my $nossonumero = substr($self->string(20,0) . $self->invid,-&var_numero($self));
	die $self->lang(73,$self->invid,$self->account('nome')) if length($self->invid) > &var_numero($self);
	return $nossonumero;
}

sub dvDig11 {
	my $self = shift;
	my $cadeia = shift;
	my $limitesup = shift;
	my $lflag = shift;
	
	my $ndig;
	my $nresto =  $self->calcdig11($cadeia,$limitesup);

	if ( $lflag == 1 ) {
		if ($nresto == 0 || $nresto == 1 || $nresto == 10) {
			$ndig = 1;
		}else{		
			$ndig = 11 - $nresto;			 
		}
	} else { #Digito do banco
		if ($nresto == 10) {
			$ndig = 0;
		}else{		
			$ndig = $nresto;			 
		}		
	}

	return $ndig; 	
}

sub dvnosso {
	my $self = shift;
	my $nossonumero = defined $_[0] ? $_[0] : &var_nossonumero($self);
	if ($self->account('carteira') =~ m/^(126|131|146|150|168)$/) {
		return $self->calcdig10($self->account('carteira').$nossonumero);
	} else {		
		return $self->calcdig10($self->account('agencia').$self->account('conta').$self->account('carteira').$nossonumero);
	}
}

sub dvagconta {
	my $self = shift;
	return $self->calcdig10($self->account('agencia').$self->account('conta'));
}

sub codbar {
	my $self = shift;

	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.$self->account('carteira').&var_nossonumero($self).&dvnosso($self).$self->account('agencia').$self->account('conta').&dvagconta($self).'000';
	my $dv3 = &dvDig11($self, $strcodbar,9,1);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.$self->account('carteira').&var_nossonumero($self).&dvnosso($self).$self->account('agencia').$self->account('conta').&dvagconta($self).'000';

	return $codbar;		
}	

sub parse_boleto {
	my $self = shift;
	my $nossonumero = &var_nossonumero($self);
	$self->template('nossonum', $nossonumero);	
	$self->template('dvnosso', &dvnosso($self));
	$self->template('dvagencia', '');
	$self->template('dvconta',&dvagconta($self));	
	$self->parse('/boleto/itau');
}
1;
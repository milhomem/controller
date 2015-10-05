#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2011
# Banco 104 - CEF
package Controller::Financeiro::Boleto::104;

require 5.008;
use Controller::Financeiro::Boleto;

@ISA = qw(Controller::Financeiro::Boleto);

sub init {
        my $self = shift;
		if ($self->account('dvbanco') == 1) {
			return __PACKAGE__ .'::SIGCB';
		} elsif ($self->account('dvbanco') == 2) {
			return __PACKAGE__ .'::SINCO';
		} else {
			return __PACKAGE__ .'::SICOB';
		}
}

package Controller::Financeiro::Boleto::104::SICOB; #Default

require 5.008;

sub init { return __PACKAGE__; }

sub format {
	my $self = shift;
	$self->account('agencia', substr('0000'.$self->account('agencia'),-4));
	$self->account('conta', substr('00000'.$self->account('conta'),-5));
	$self->account('carteira', substr('00'.$self->account('carteira'),-2));
	$self->account('convenio', substr('00000000000'.$self->account('convenio'),-11));
}

sub var_numero {
	return 8;
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

sub var_nossonumero {
	my $self = shift;

	my $id = $self->invoice('nossonumero') > 0 ? $self->invoice('nossonumero') : $self->invid;
	my $nossonumero = substr($self->string(20,0) . $id,-&var_numero($self));
	die $self->lang(73,$self->invid,$self->account('nome')) if length($id) > &var_numero($self);
	return $self->account('carteira').$nossonumero;	
}

sub dvnosso {
	my $self = shift;
	my $nossonumero = defined $_[0] ? $_[0] : &var_nossonumero($self);
	return &dvDig11($self, $nossonumero,9);
}

sub dvcodcliente {
	my $self = shift; 
	return &dvDig11($self, &cod_cliente($self),7);
}

sub cod_cliente {
	return substr('00000000000'.$_[0]->account('convenio'),-11);
}

sub codbar {
	my $self = shift;
	
	&format($self);
	
	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.&var_nossonumero($self).$self->account('agencia').&cod_cliente($self);
	my $dv3 = &dvDig11($self, $strcodbar,9,1);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.&var_nossonumero($self).$self->account('agencia').&cod_cliente($self);

	return $codbar;		
}

sub parse_boleto {
	my $self = shift;
	
	my $nossonumero = &var_nossonumero($self);
	$self->template('nossonum', substr($nossonumero,0,2).'/'.substr($nossonumero,2));			
	$self->template('dvnosso',&dvnosso($self));
	$self->template('dvagencia','');
	$self->template('dvconta','');
	$self->template('codcliente', &cod_cliente($self));	
	$self->template('dvcodcli', &dvcodcliente($self));
			
	$self->parse('/boleto/cef_sicob');
}

package Controller::Financeiro::Boleto::104::SIGCB; #1

require 5.008;

sub init { return __PACKAGE__; }

sub var_numero {
	return 9;
}

sub format {
	my $self = shift;
	$self->account('agencia', substr('0000'.$self->account('agencia'),-4));
	$self->account('conta', substr('00000'.$self->account('conta'),-5));
	$self->account('carteira', substr('00'.$self->account('carteira'),-2));
	$self->account('convenio', substr('00000000000'.$self->account('convenio'),-6));
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
	return &dvDig11($self, '24900000' . $nossonumero,9,0); #24 SEM REGISTRO o 900000 é inicio do nosso numero, de livre uso, pode ser alterado
}

sub dvcodcliente {
	my $self = shift; 
	return &dvDig11($self, &cod_cliente($self),9,0);
}

sub cod_cliente {
	return substr('000000'.$_[0]->account('convenio'),-6);
}
		
sub codbar {
	my $self = shift;

	&format($self);

	my $nossonumero = &var_nossonumero($self);
	my $dvCL = &dvDig11($self, &cod_cliente($self).&dvcodcliente($self).'90020004'.$nossonumero,9,0);	
	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.&cod_cliente($self).&dvcodcliente($self).'90020004'.$nossonumero.$dvCL;
	my $dv3 = &dvDig11($self, $strcodbar,9,1);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.&cod_cliente($self).&dvcodcliente($self).'90020004'.$nossonumero.$dvCL;
	
	return $codbar;
}

sub parse_boleto {
	my $self = shift;
	
	my $nossonumero = &var_nossonumero($self);
	$self->template('nossonum', '24/900000'. $nossonumero);
	$self->template('dvnosso',&dvnosso($self));
	$self->template('dvagencia','');
	$self->template('dvconta','');
	$self->template('codcliente', &cod_cliente($self));	
	$self->template('dvcodcli', &dvcodcliente($self));
	$self->template('carteira','SR');

	$self->parse('/boleto/cef_sigcb');
}

package Controller::Financeiro::Boleto::104::SINCO;
#TODO Modelo SINCO da CEF
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
1;
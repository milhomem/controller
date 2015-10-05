#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2011
# Banco 237 - BRADESCO
package Controller::Financeiro::Boleto::237;

require 5.008;

sub init { return __PACKAGE__; }

sub var_numero {
	return 11;
}

sub var_nossonumero {
	my $self = shift;
	
	my $id = $self->invoice('nossonumero') > 0 ? $self->invoice('nossonumero') : $self->invid;
	my $nossonumero = substr($self->string(20,0) . $id,-&var_numero($self));
	die $self->lang(73,$self->invid,$self->account('nome')) if length($id) > &var_numero($self);
	return $self->account('carteira') . $nossonumero;	
}

sub dvDig11 {
	my $self = shift;
	my $cadeia = shift;
	my $limitesup = shift;
	my $lflag = shift;
	
	my $ndig;
	my $nresto =  $self->calcdig11($cadeia,$limitesup);

	if ($nresto == 0 || $nresto == 1) {
		$ndig = $lflag == 1 ? 1 : $nresto == 1 ? 'P' : 0;
	}else{		
		$ndig = 11 - $nresto; 
	}

	return $ndig; 	
}

sub dvnosso {
	my $self = shift;
	return &dvDig11($self, &var_nossonumero($self),7,0);	
}

sub codbar {
	my $self = shift;
	
	my $strcodbar = $self->account('banco').$self->setting('moeda_nr').$self->fatorvencimento.$self->valordocumento.$self->account('agencia').&var_nossonumero($self).$self->account('conta').'0';	
	my $dv3 = &dvDig11($self, $strcodbar,9,1);
	my $codbar = $self->account('banco').$self->setting('moeda_nr').$dv3.$self->fatorvencimento.$self->valordocumento.$self->account('agencia').&var_nossonumero($self).$self->account('conta').'0';

	return $codbar;		
}

sub parse_boleto {
	my $self = shift;
	
	my $nossonumero = &var_nossonumero($self);
	$self->template('nossonum', substr($nossonumero,0,2).'/'.substr($nossonumero,2));			
	$self->template('dvnosso',&dvnosso($self));
	$self->template('dvagencia','');
	$self->template('dvconta','');

	$self->parse('/boleto/bradesco');
}
1;
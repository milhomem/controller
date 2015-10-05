#!/usr/bin/perl
package Controller::Is;

require 5.008;
require Exporter;
use strict;
use Carp;

our @ISA = qw( Exporter );

BEGIN {
$Is::VERSION = "0.3";
}

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	my $self = {
				date => undef,
		 		};
	
	bless($self, $class);
	
	return($self);	
}

sub is_valid_invoice { #CUIDADO, tira referencias
	my $self = shift;
	my $invid = shift;

	my $sid = $self->sid;
	local $Controller::SWITCH{skip_error} = 1;
	$self->invid($invid);
	
	if ($invid && $self->invoice('status') ne '') {
		$self->sid($sid); 
		return 1;
	}
	return 0;	
}

sub is_valid_service { #CUIDADO, tira referencias
	my $self = shift;
	my $sid = shift;

	local $Controller::SWITCH{skip_error} = 1;
	$self->sid($sid);
	
	return $sid && $self->service('status') ne '' ? 1 : 0;
}

sub is_valid_staff { #CUIDADO, tira referencias
	my $self = shift;
	my $staffid = shift;

	local $Controller::SWITCH{skip_error} = 1;
	$self->staffid($staffid);
	
	return $staffid && $self->staff('id') > 0 ? 1 : 0;
}

sub is_valid_user { #CUIDADO, tira referencias
	my $self = shift;
	my $uid = shift;

	local $Controller::SWITCH{skip_error} = 1;
	$self->uid($uid);
	
	return $uid && $self->user('status') ne '' ? 1 : 0;
}

sub is_valid_payment { #CUIDADO, tira referencias
	my $self = shift;
	my $payid = shift;

	my $sid = $self->sid;
	local $Controller::SWITCH{skip_error} = 1;
	$self->payid($payid);
	
	if ($payid && $self->payment('nome') ne '') {
		$self->sid($sid); 
		return 1;
	}
	return 0;	
}

sub is_valid_server { #CUIDADO, tira referencias
	my $self = shift;
	my $srvid = shift;

	my $sid = $self->sid;
	local $Controller::SWITCH{skip_error} = 1;	
	$self->srvid($srvid);
	
	if ($srvid && $self->server('nome') ne '') {
		$self->sid($sid); 
		return 1;
	}
	return 0;	
}

sub is_valid_plan { #CUIDADO, tira referencias
	my $self = shift;
	my $pid = shift;

	my $sid = $self->sid;
	local $Controller::SWITCH{skip_error} = 1;
	$self->pid($pid);
	
	if ($pid && $self->plan('nome') ne '') {
		$self->sid($sid); 
		return 1;
	}
	return 0;
}

sub is_valid_account { #CUIDADO, tira referencias
	my $self = shift;
	my $actid = shift;

	local $Controller::SWITCH{skip_error} = 1;
	$self->actid($actid);

	return $actid && $self->account('banco') > 0 ? 1 : 0;	
}

sub is_valid_tax {
	my $self = shift;
	my $tid = shift;

	local $Controller::SWITCH{skip_error} = 1;
	$self->tid($tid);

	return $tid && $self->tax('tipo') ne '' ? 1 : 0;	
}

sub is_valid_department {
	my $self = shift;
	my $deptid = shift;

	local $Controller::SWITCH{skip_error} = 1;
	$self->deptid($deptid);

	return $deptid && $self->department('nome') ne '' ? 1 : 0;	
}

sub is_plano_module {
	my $self = shift;
	my $cmp = shift;

	local $Controller::SWITCH{skip_error} = 1;	
	unless ($self->{'plano'}{'modulo'}) {
		$self->planos("modulo");
	}
	if ($self->{'plano'}{'modulo'} && $self->{'plano'}{'modulo'} eq $cmp) {
			return 1;
	}
	
	return 0;  
}

sub is_creditcard_module {
	my $self = shift;
	my $cmp = shift;

	if ($cmp =~ m/::Financeiro::CreditCard/ig) {
			return 1;
	}
	
	return 0;	
}

sub is_financeiro_module {
	my $self = shift;
	my $cmp = shift;

	if ($cmp =~ m/::Financeiro::/ig) {
			return 1;
	}
	
	return 0;	
}

sub is_boleto_module {
	my $self = shift;
	my $cmp = shift;

	if ($cmp =~ m/Boleto/ig) {
			return 1;
	}
	
	return 0;	
}

sub is_CPFCNPJ {
	my $self = shift;
	my $valor = shift;
	$valor =~ s/[\-\.\/]//g;
	$valor = substr($valor,1,14) if (length $valor == 15);

	use String;
	if (length $valor == 11) {
		my $cpf = new String($valor);
		my (@a,$i,$x,$y);
		my $b = 0;
		my $c = 11;
		my $validate = 0;
		for ($i=0; $i<11; $i++){
			$a[$i] = $cpf->charAt($i);
			$b += ($a[$i] * --$c) if ($i < 9);
		}
		if (($x = $b % 11) < 2) { $a[9] = 0; } else { $a[9] = 11-$x; }
		$b = 0;
		$c = 11;
		for ($y=0; $y<10; $y++) { $b += ($a[$y] * $c--) }; 
		if (($x = $b % 11) < 2) { $a[10] = 0; } else { $a[10] = 11-$x; }
		
		if ($cpf eq "00000000000" || $cpf eq "11111111111" || $cpf eq "22222222222" || $cpf eq "33333333333" || $cpf eq "44444444444" || $cpf eq "55555555555" || $cpf eq "66666666666" || $cpf eq "77777777777" || $cpf eq "88888888888" || $cpf eq "99999999999")	{
			return 1 if $self->setting('license_id') eq 'Demo'; #Demo
		} elsif (($cpf->charAt(9) != $a[9]) || ($cpf->charAt(10) != $a[10])) {
		} else {
			return 1;
		}
	} elsif (length $valor == 14) {
		my $CNPJ = new String($valor);
		my (@a,$i,$x,$y);
		my $b = 0;
	    my @c = (6,5,4,3,2,9,8,7,6,5,4,3,2);
	    for ($i=0; $i<12; $i++){
			$a[$i] = $CNPJ->charAt($i);
			$b += $a[$i] * $c[$i+1];
		}
		if (($x = $b % 11) < 2) { $a[12] = 0; } else { $a[12] = 11-$x; }
		$b = 0;
		for ($y=0; $y<13; $y++) {
			$b += ($a[$y] * $c[$y]); 
		}
		if (($x = $b % 11) < 2) { $a[13] = 0; } else { $a[13] = 11-$x; }
	
		if (($CNPJ->charAt(12) != $a[12]) || ($CNPJ->charAt(13) != $a[13])){
		} else{
			return 1;
		}
	}
	return 0;
}

sub is_valid_email {
	my $self = shift;
	my $valor = shift;	
	$valor =~ s/\s//g;		
	return $valor =~ m/^\w+(?:[\.-]?\w+)*@\w+(?:[\.-]?\w+)*(?:\.\w{2,3})+$/ ? 1 : 0;	
}

sub is_valid_exp { #CUIDADO, tira referencias
	my $self = shift;
	my $exp = shift;

	my $m = substr($exp,0,2);
	my $y = substr($exp,-2);
	return 0 if $m <= 0 && $m > 12;
	return 0 if $y < 0 && $y > 99;
	return $exp && length($exp) == 4 ? 1 : 0;
}

sub is_valid_phone {
	my $self = shift;
	my $valor = shift;	
	$valor =~ s/\s//g;		
	return $valor =~ m/^[1-9]{2}[0-9]{7,9}|^0800/ ? 1 : 0;	
}

sub is_valid_country {
	my $self = shift;
	my $cc = shift;

	local $Controller::SWITCH{skip_error} = 1;
	foreach ($self->country_codes) {
		return 1 if $self->country_code($_)->{'name'} =~ m/^\Q$cc\E$/i;
		return 1 if $_ eq uc $cc;
	}

	return 0;	
}

sub is_windows {
	#my $os = $^O;
	return $ENV{'OS'} =~ /windows/i ? 1 : 0;  
}

sub is_running {
	my $self = shift;
	my ($type,$id) = @_;
	
	if ($self->is_windows) {
		die "TODO";
		eval{
			require Proc::PID_File;
			my $process = Proc::PID_File->new($self->setting('app') . '/' . ".$type.$id");
		};
		if ($@) {
			die("Windows requires Proc::PID_File");			
		}			
	} else {
		eval {
			require Proc::PID::File;
			my $process = Proc::PID::File->new(dir => $self->setting('app'), name => ".$type.$id");
			return $process->alive() ? 1 : 0;
		};
		if ($@) {
			die("Linux requires Proc::PID::File");
		}
	}	
}
1;
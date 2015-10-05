#!/usr/bin/perl         
# Use: Internal
# Controller - is4web.com.br
# 2012
package Controller::Financeiro::CreditCard;

require 5.008;
require Exporter;

use Controller::Financeiro;
use Controller::Interface;

use vars qw(@ISA $VERSION $tidproximo);

@ISA = qw(Controller::Financeiro Controller::Interface Exporter);
$VERSION = "0.21";

sub chooseIt {	
	my $self = shift;
	my $ok = 0;
	foreach ($system->creditcards) {
		$system->ccid($_);
		next if $system->creditcard('active') != 1;
		$ok = 1;
		last;
	}
	return $ok;
}

1;
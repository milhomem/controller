#!/usr/bin/perl
#
# Controller - is4web.com.br
# 2008
package Controller::Interface::Users;

require 5.008;
require Exporter;

use Controller::Interface;

use vars qw(@ISA $VERSION);

@ISA = qw(Exporter Controller::Interface);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = shift;
    my $s_class = ref $self;

    push @ISA, eval '@'.$s_class.'::ISA'; #Inherit ISA
    push @ISA, $s_class;

	bless($self, $class);

	$self->reDie;
		
	return $self;
}

sub chooseIt {	
	my $self = shift;
	
	if ($self->is_creditcard_module($self->tax('modulo'))) {
		my $ok = 0;
		foreach ($self->creditcards) {
			$self->ccid($_);
			next if $self->creditcard('active') != 1;
			$ok = 1;
			last;
		}
		$self->lang(400) if $ok == 0;
	}
	
	return $self->error ? 0 : 1;
}
1;
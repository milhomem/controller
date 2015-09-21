#!/usr/bin/perl
#
# Controller - Is4web.com.br
# 2008

package Controller::XML;

require 5.008;
require Exporter;
#use strict;
use XML::LibXML;
use XML::Simple;
use Controller;
use Carp;

use vars qw(@ISA $VERSION);
@ISA = qw(XML::LibXML Exporter);

$VERSION = "1.1";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;

	my $self = new XML::LibXML;
	
	bless($self, $class);
	
	return $self;
}

#Working with doc
sub newDocument {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	push @ISA, 'XML::LibXML::Document';
	my $self= XML::LibXML::Document->new($_[0],$_[1]);
	
	bless($self, $class);
	return $self;
}

sub createElementRootNS {
	my ($self) = shift;
	my $el = $self->SUPER::createElementNS($_[0],$_[1]);
	$self->setDocumentElement( $el );
	return $el;
}

sub createElementRoot {
	my ($self) = shift;
	my $el = $self->SUPER::createElement($_[0]);
	$self->setDocumentElement( $el );
	return $el;	
}

sub createElement {
	my ($self) = shift;

	my $el = $self->SUPER::createElement($_[0]);
	ref($_[1]) ne 'XML::LibXML::Element'
		? ( $self->getElementsByTagName($_[1]) )[0]->appendChild( $el )
		: $_[1]->appendChild( $el );
	$self->txtElement($_[2], $el) if exists $_[2];
	
	return $el;	
}

sub setAttribute {
	my ($self) = shift;
	$_[2]->setAttribute($_[0],Controller::html($_[1])); 
}

sub txtElement {
	my ($self) = shift;
	my $el = XML::LibXML::Text->new($_[0]);
	$_[1]->appendChild( $el );
	return 1;
}

sub get_return_value {
	my ($self, $xml) = @_;

	my $document;
	eval {
		$document = $self->parse_string($xml);
	};
	if (!defined($document) || $@ ne '') {
		chomp($@);
		croak("Frame from server wasn't well formed: \"$@\"\n\nThe XML looks like this:\n\n$xml\n\n");
	} else {
		my $class = 'XML::LibXML::Document';
		return bless($document, $class);
	}
}

sub xml2perl {
	my ($self,$xml,$fcontent,$farray) = @_;
	$fcontent = 1 unless defined $fcontent;
	$farray = 1 unless defined $farray;
	return undef unless $xml;
		
	$xml = '<?xml version="1.0" encoding="UTF-8" ?>'.$xml unless $xml =~ m/^<\?xml/i;	
	
	#How can I strip invalid XML characters from strings in Perl?
	# #x9 | #xA | #xD | [#x20-#xD7FF] | [#xE000-#xFFFD] | [#x10000-#x10FFFF]
	$xml =~ s/[^\x09\x0A\x0D\x20-\x{D7FF}\x{E000}-\x{FFFD}\x{10000}-\x{10FFFF}]//go;

	my $data = eval { local $SIG{'__DIE__'} = undef; return XML::Simple::XMLin($xml, ForceContent => $fcontent, ForceArray => $farray); } ;	#OUTPUT as incoming input
	if ($@) {
		my $ctrl = new Controller;
		$ctrl->clear_error();
		$ctrl->set_error($xml);
		die 'XML Parser error!';
	}
	return $data;
}

sub blessInputXmlUtf {
	my $d = shift;
	my $r = ref $d;
	if ( $r eq 'ARRAY') {
		foreach my $i (@$d) {
			if (ref $i) {
				blessInputXmlUtf( $i );
			} else {
				utf8::decode( $i );
			}
		}
	} elsif ($r eq 'HASH') {
		foreach my $i (keys %$d) {
			my $s = $d->{$i};
			if ( ref $s ) {
				blessInputXmlUtf( $s );
			} else {
				utf8::decode( $d->{$i} );
			}
		}
	} elsif ($r eq 'SCALAR') {
		utf8::decode( $$d );
	} else {
		utf8::decode( $d );
	}
}
1;
#!/usr/bin/perl

#       .Copyright (C)  1999-2002 TUCOWS.com Inc.
#       .Created:       11/19/1999
#       .Contactid:     <admin@opensrs.org>
#       .Url:           http://www.opensrs.org
#       .Originally Developed by:
#                       Tucows/OpenSRS
#       .Authors:       Evgeniy Pirogov
#
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU Lesser General Public 
#       License as published by the Free Software Foundation; either 
#       version 2.1 of the License, or (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful, but
#       WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#       Lesser General Public License for more details.
#
#       You should have received a copy of the GNU Lesser General Public
#       License along with this program; if not, write to the Free Software
#       Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package OpenSRS::Util::Session;

use strict;
use Core::Checksum qw/calculate compare/;
use Data::Dumper;
use Core::Exception;


sub import {
    my $pkg = shift;
    my $var = shift;
    OpenSRS::Util::Session::Serializer::init($var);
}

sub new {
    my $class = shift;
    return bless {@_},$class;
}

sub add {
    my $self = shift;
    while (@_){
	my $name = shift;
	return unless $name;
	my $val = shift;
    	$self->{$name} = $val;
    }
}

sub dump {
    my $self = shift;
    my $salt = shift;
    throw 'dev','Salt not specified ' unless $salt;
    my $dump = OpenSRS::Util::Session::Serializer::store(%$self);
    return (session => $dump, sign => calculate($dump,$salt));    
}

sub restore {
    my $class = shift;
    my $dump = shift;
    return $class->new unless $dump; 

    my $sign = shift;
    my $salt = shift;
    throw 'dev','Salt not specified ' unless $salt;
    unless (compare($sign, $dump,$salt)){
	return $class->new;
    }
    my $VAR1 =  OpenSRS::Util::Session::Serializer::restore($dump);
    return $class->new(%$VAR1);
}


package OpenSRS::Util::Session::Serializer;

use strict;
use Core::Exception;
use warnings;

my $defaultSerializer = 'Data::Dumper';

my %methods = (
    'Data::Dumper' => q/
use Data::Dumper;
sub store { 
    local $Data::Dumper::Indent = 0;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Purity = 1; 
    local $Data::Dumper::Deepcopy = 1; 
    my %hash = @_;
    my $result = Dumper(\%hash);
    $result =~ s#(.)#sprintf("%x", ord($1))#eg;
    return $result;
}

sub restore {
    my $VAR1;
    my $dump = shift;
    $dump =~ s#(..)#sprintf("%c", hex($1))#eg;
    eval($dump);
    if ($@){
        throw 'dev',"Can't restore session %s [%s]",$dump,$@;
    }
    unless (ref $VAR1 eq 'HASH'){
        throw 'dev',"Session is not hash %s",$dump;
    }
    return $VAR1;
}
/,
    'OPS' => q/
use OPS;
our $OPS = new OPS(option => 'compress');
sub store { 
    my %hash = @_;
    my $result = $OPS->encode(\%hash);
    $result =~ s#(.)#sprintf("%x", ord($1))#eg;
    return $result;
}

sub restore {
    my $dump = shift;
    $dump =~ s#(..)#sprintf("%c", hex($1))#eg;
    my $VAR1 = $OPS->decode($dump);
    if ($VAR1->{'response_code'} eq 'OPS_ERR'){
        throw 'dev',"Can't restore session %s",$dump;
    }
    unless (ref $VAR1 eq 'HASH'){
        throw 'dev',"Session  is not hash %s",$dump,$@;
    }
    return $VAR1;
}
/,
);

sub init {
    my $type = shift;
    $type ||= $defaultSerializer;
    throw 'dev','Wrong serializer type [%s]',$type unless exists $methods{$type};
    {
	$^W = 0;
	eval ($methods{$type});
	throw 'dev','Cant init serializer %s [%s]',$type,$@ if $@;
    }
}

sub store {
    die 'Serialier not inited'
}

sub restore {
    die 'Serialier not inited'
}
1;

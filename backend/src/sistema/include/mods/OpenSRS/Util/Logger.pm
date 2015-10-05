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


package OpenSRS::Util::Logger;

use strict;
use warnings;
use IO::File;
use Core::Exception;
use vars qw($AUTOLOAD);
use Carp qw(confess);


sub new {
    my $class = shift;
    my $file = shift;
    my $self = {};
    if ($file and scalar @_){ 
	$self = { category => {map {$_ =>1 } @_}};
    	my $fh = new IO::File "$file",O_WRONLY|O_CREAT|O_APPEND;
	if (defined $fh){
	    $fh->autoflush(1);
	    $self->{_fh} = $fh;
	} else {
	    confess "Can't open logfile $file [$!]";
	}
    } 
    return bless $self,$class;
}

sub import {
    return unless scalar @_ > 1;
    my $pkg = shift;
    my $var = shift;
    $var =~ s/^\$//;
    my $caller = caller(0);
    my $obj = $pkg->new(@_);
    {
	no strict 'refs';
	my $glob_name = $caller . '::' . $var;
        *{$glob_name} = \$obj;
    }
}


sub DESTROY{

}

sub AUTOLOAD{
    my $self = shift;
    
    return unless ref $self;
    
    my $category = $AUTOLOAD;
    $category =~ s/.*://;
    return unless exists $self->{category}{$category} and scalar @_;

    my $format = '%s';
    if (scalar @_ > 1) {
	$format = shift;
    }
    my $msg = "$category:\t$$\t".scalar(localtime)."\t".
		sprintf($format,@_)."\n";
    if ( defined $self->{_fh}){
	$self->{_fh}->print($msg);
    } else {
	warn $msg;
    }
}

1;

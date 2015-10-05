#!/usr/bin/perl

#       .Copyright (C)  1999-2001 TUCOWS.com Inc.
#       .Created:       03/15/2001
#       .Contactid:     <admin@vpop.net>
#       .Url:           http://www.opensrs.org
#
#       This library is free software; you can redistribute it and/or
#       modify it under the terms of the GNU Lesser General Public
#       License as published by the Free Software Foundation; either
#       version 2.1 of the License, or (at your option) any later version.
#
#       This library is distributed in the hope that it will be useful, but
#       WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#       Lesser General Public License for more details.
#
#       You should have received a copy of the GNU Lesser General Public
#       License along with this library; if not, write to the Free Software
#       Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

# OpenSRS client library

#######################################################
# **NOTE** This library should not be modified    #####
# Instead, please modify the supplied cgi scripts #####
#######################################################

package OpenSRS::Syntax;

use strict;
use vars qw($VERSION);

$VERSION = "1.0";

# Universal telephone and fax number syntax verification routines
sub PhoneSyntax
{
    my $phone = shift;

    return 0   if length($phone) > 40;

    $phone =~ s/\s//g;          # Remove all whitespace

    # Allow 0...9 ( ) - . + # *
    # - optional   extension variations
    # - optional   TDD
    return 0 if $phone !~ /^[\d\-\(\)\.\+\#\*]{4,}((x|ex|ext|xt)\.?\d+)?(TDD)?$/i;

    # Must have at least 4 digits and at least 1/3 of phone must be digits
    my $num_digits = $phone =~ tr/0-9/0-9/;
    return 0   if $num_digits < 4  or  $num_digits < (length($phone) / 3);

    # ( and ) must balance each other
    my $num_left_brackets  = $phone =~ /\(/;
    my $num_right_brackets = $phone =~ /\)/;
    return 0   if $num_left_brackets != $num_right_brackets;

    return 1;  # i.e. good
}

sub FaxSyntax
{
    my $fax = shift;

    return 0   if length($fax) > 40;

    $fax =~ s/\s//g;          # Remove all whitespace

    # Since fax number is optional an empty fax is accepted as valid
    return 1      unless length($fax);

    # Allow 0...9 - ( ) . +
    return 0      if $fax !~ /^[\d\-\(\)\.\+]{4,}$/;

    # Must have at least 4 digits and at least 1/3 of fax must be digits
    my $num_digits = $fax =~ tr/0-9/0-9/;
    return 0   if $num_digits < 4  or  $num_digits < (length($fax) / 3);

    # ( and ) must balance each other
    my $num_left_brackets  = $fax =~ /\(/;
    my $num_right_brackets = $fax =~ /\)/;
    return 0   if $num_left_brackets != $num_right_brackets;

    return 1;  # i.e. good
}

1;


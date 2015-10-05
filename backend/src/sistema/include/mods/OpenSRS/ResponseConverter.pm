#!/usr/bin/perl
#
# $Id: ResponseConverter.pm,v 1.1 2011/06/25 01:24:47 is4web Exp $
#       .Copyright (C)  2002 TUCOWS.com Inc.
#       .Created:       2002/09/03
#       .Contactid:     <admin@opensrs.net>
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

package OpenSRS::ResponseConverter;

use strict;
use warnings;

use vars qw(%ERROR_MAP);

%ERROR_MAP = (
    4100 => 'Username taken, try another one',
    2100 => 'User password is incorrect',
    7502 => \&insufficient_balance,
);

sub new {
    return bless {}, shift;
}

# Dummy response converter
sub convert {
    my $self = shift;
    my $response = shift;
    my $response_code = $response->{response_code} || -1;
    if (exists $ERROR_MAP{$response_code}) {

	my $data = $ERROR_MAP{$response_code};
	
	if (ref $data eq 'CODE') {
	    &$data($response);
	} else {
	    $response->{response_text} = $data;
	}
    }
}

sub insufficient_balance {
    my $response = shift;
    if ($response->{attributes}{order_id}) {
	$response->{is_success} = 1;
	$response->{response_text} = "Order successfully created with ID # " . 
		    $response->{attributes}{order_id}
    }
}

1;

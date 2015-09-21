#!/usr/bin/perl
#
# $Id: NullResponseConverter.pm,v 1.1 2011/06/25 01:24:47 is4web Exp $
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

package OpenSRS::NullResponseConverter;

use strict;
use warnings;

sub new {
    return bless {}, shift;
}

# Dummy response converter
sub convert {
    my $self = shift;
    return shift;
}

1;

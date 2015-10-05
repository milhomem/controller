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

package OpenSRS::Util::Error;
use strict;
use Exporter;
use HTML::Template;
our @ISA = qw/Exporter/;

our @EXPORT = qw/error_output/;

my $error_template;
#HM... Works under Apache, but failed perl -cw when template
#initialized on compile time. Initialization moved to pure runtime.

sub error_output{
    $error_template = HTML::Template->new(arrayref => [<DATA>]) unless $error_template;
    $error_template->param(error => shift);
    print $error_template->output;
}

1;
__DATA__
<html>
<head><title>Application Error</title></head>
<body>
<center>
General Application Error Occured<br>
<TMPL_VAR ESCAPE=1 ERROR>
</center>
</body>
</html>




package OpenSRS::Constants;
#
# OpenSRS::Constants - defined constants for identifying codesets
#
#

use strict;

require Exporter;

use vars qw($VERSION @ISA @EXPORT);
@ISA	= qw(Exporter);
@EXPORT = qw(LOCALE_CODE_ALPHA_2 LOCALE_CODE_ALPHA_3 LOCALE_CODE_NUMERIC
		LOCALE_CODE_DEFAULT);

use constant LOCALE_CODE_ALPHA_2 => 1;
use constant LOCALE_CODE_ALPHA_3 => 2;
use constant LOCALE_CODE_NUMERIC => 3;

use constant LOCALE_CODE_DEFAULT => LOCALE_CODE_ALPHA_2;

1;

__END__

=head1 NAME

OpenSRS::Constants - constants for Locale codes

=head1 SYNOPSIS

    use OpenSRS::Constants;
    
    $codeset = LOCALE_CODE_ALPHA_2;

=head1 DESCRIPTION

B<OpenSRS::Constants> defines symbols which are used in
the three modules from the Locale-Codes distribution:

	OpenSRS::Language
	OpenSRS::Country
	OpenSRS::Currency

B<Note:> at the moment only OpenSRS::Country supports
more than one code set.

The symbols defined are used to specify which codes you
want to be used:

	LOCALE_CODE_ALPHA_2
	LOCALE_CODE_ALPHA_3
	LOCALE_CODE_NUMERIC

You shouldn't have to C<use> this module directly yourself -
it is used by the three Locale modules, which in turn export
the symbols.

=head1 KNOWN BUGS AND LIMITATIONS

None at the moment.

=head1 SEE ALSO

=over 4

=item OpenSRS::Language

Codes for identification of languages.

=item OpenSRS::Country

Codes for identification of countries.

=item OpenSRS::Currency

Codes for identification of currencies and funds.

=back

=head1 AUTHOR

Neil Bowers E<lt>neilb@cre.canon.co.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2001, Canon Research Centre Europe (CRE).

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


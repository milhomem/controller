# $Id: America.pm,v 1.1 2011/06/25 01:24:46 is4web Exp $

package OpenSRS::Util::America;
require Exporter;
@ISA = qw (Exporter);

use strict 'vars';
use Data::Dumper;
use Time::Local;
use Time::localtime;
use OpenSRS::Util::Common qw(build_select_menu3);

use vars qw(@EXPORT_OK %america_application_purposes @america_application_purposes
                 %america_nexus_categories @america_nexus_categories);

@EXPORT_OK = qw (%america_application_purposes @america_application_purposes 
                 %america_nexus_categories @america_nexus_categories build_app_purpose_list);

my $debug = 1;

#order is very important
@america_application_purposes = qw(P1 P2 P3 P4 P5);
%america_application_purposes = (
    'P1' => 'Business use for profit',
    'P2' => 'Non-profit business, club, association, religious organization, etc.',
    'P3' => 'Personal Use',
    'P4' => 'Education purposes',
    'P5' => 'Government purposes',
);

@america_nexus_categories = qw(C11 C12 C21 C31 C32);
%america_nexus_categories = (
    'C11' => 'Natural Person -- U.S. Citizen',
    'C12' => 'Natural Person -- Permanent Resident',
    'C21' => 'U.S. Corporation',
    'C31' => 'Bona Fide U.S. Presence -- Regularly engages in lawful activities',
    'C32' => 'Bona Fide U.S. Presence -- Entity which has an office or other facility in the U.S.',
);

# dynamically build the application purpose
sub build_app_purpose_list {
    my ($default) = @_;
    my $temp = {%america_application_purposes, '' => 'Select Application Purpose'};
    return build_select_menu3($temp, ['',@america_application_purposes],$default);
}



1;


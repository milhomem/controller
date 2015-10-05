# $Id: Europe.pm,v 1.1 2011/06/25 01:24:46 is4web Exp $

package OpenSRS::Util::Europe;
require Exporter;
@ISA = qw(Exporter);

use strict 'vars';
use Data::Dumper;
use OpenSRS::Util::Common qw(build_select_menu3);

use vars qw(
    @EXPORT_OK
    @languages
    %languages
    @eu_countries
    %eu_countries
    @be_languages
    %be_languages
    );

@EXPORT_OK = qw(
    @languages
    %languages
    @be_languages
    %be_languages
    @eu_countries
    %eu_countries
    build_eu_countries_list
    build_eu_languages_list
    build_be_languages_list
    );

@languages = qw/
    cs
    da
    de
    el
    en
    es
    et
    fi
    fr
    hu
    it
    lt
    lv
    mt
    nl
    pl
    pt
    sk
    sl
    sv
/;

%languages = (
    cs => "Czech",
    da => "Danish",
    de => "German",
    el => "Greek",
    en => "English",
    es => "Spanish",
    et => "Estonian",
    fi => "Finnish",
    fr => "French",
    hu => "Hungarian",
    it => "Italian",
    'lt' => "Lithuanian",
    lv => "Latvian",
    mt => "Maltese",
    nl => "Dutch",
    pl => "Poland",
    pt => "Portuguese",
    sk => "Slovak",
    sl => "Slovenian",
    sv => "Swedish",
);

%eu_countries = (
    GB => "United Kingdom (GB)",
    AT => "Austria",
    BE => "Belgium",
    CY => "Cyprus",
    CZ => "Czech Republic",
    DK => "Denmark",
    EE => "Estonia",
    FI => "Finland",
    FR => "France",
    DE => "Germany",
    GR => "Greece",
    HU => "Hungary",
    IE => "Ireland",
    IT => "Italy",
    LV => "Latvia",
    'LT' => "Lithuania",
    LU => "Luxembourg",
    MT => "Malta (including Gozo and Comino)",
    NL => "Netherlands",
    PL => "Poland",
    PT => "Portugal",
    SK => "Slovakia",
    SI => "Slovenia",
    ES => "Spain",
    SE => "Sweden",
    AX => "Aland Islands",
    GI => "Gibraltar",
    MQ => "Martinique",
    GF => "French Guyana",
    GP => "Guadeloupe",
    RE => "Reunion",
);

@eu_countries = qw/GB AT BE CY CZ DK EE FI FR DE GR HU IE IT LV LT LU MT NL PL PT SK SI ES SE AX GI MQ GF GP RE /;

%be_languages = (
    en => "English",
    fr => "French",
    nl => "Dutch",
);
@be_languages = qw/en fr nl/;

# dynamically build the list for select box
sub build_eu_countries_list {
    my ($default) = @_;
    @eu_countries = sort { $eu_countries{$a} cmp $eu_countries{$b} } keys %eu_countries;
    my $temp = {%eu_countries, '' => ''};
    return build_select_menu3($temp, ['',@eu_countries],$default);
}

sub build_eu_languages_list {
    my ($default) = @_;
    if (not $default){
        $default = 'en';
    }
    @languages = sort { $languages{$a} cmp $languages{$b} } keys %languages;
    return build_select_menu3({%languages}, [@languages],$default);
    
}

sub build_be_languages_list {
    my ($default) = @_;
    if (not $default){
        $default = 'en';
    }
    @be_languages = sort { $be_languages{$a} cmp $be_languages{$b} } keys %be_languages;
    return build_select_menu3({%be_languages}, [@be_languages],$default);
}
	    

1;


#-----------------------------------------------------------------------

=head1 NAME

OpenSRS::Language - ISO three letter codes for language identification (ISO 639-02)
For IDN domain name registration

=head1 SYNOPSIS

    use OpenSRS::Language;
    
    $lang = code2language('eng');           # $lang gets 'English'
    $code = language2code('French-FRE');    # $code gets 'fre'
    
    @codes   = all_language_codes();
    @names   = all_language_names();
    
    $html_select_string = build_universal_encoding_menu([default_language]);

=cut

#-----------------------------------------------------------------------

package OpenSRS::Language;
use strict;

use LWP::UserAgent;
use HTTP::Request::Common qw(GET);
use Data::Dumper;

require 5.002;

#-----------------------------------------------------------------------

=head1 DESCRIPTION

The C<OpenSRS::Language> module provides access to the ISO two-letter
codes for identifying languages, as defined in ISO 639. You can either
access the codes via the L<conversion routines> (described below),
or with the two functions which return lists of all language codes or
all language names.

=cut

#-----------------------------------------------------------------------

require Exporter;

#-----------------------------------------------------------------------
#	Public Global Variables
#-----------------------------------------------------------------------
use vars qw($VERSION @ISA @EXPORT_OK $OPENSRS);
$VERSION      = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);
@ISA          = qw(Exporter);
@EXPORT_OK       = qw(code2language language2code
                   all_language_codes all_language_names 
		   build_universal_encoding_menu native_to_puny puny_to_native build_wsb_language_list);



my $useLibIDN = 0;
eval {
    require Net::LibIDN;
    $useLibIDN = 1;
};

sub native_to_puny {
    my $str = shift;
    $OPENSRS = shift;
    my $encoding = shift || $OPENSRS->{IDN_ENCODING_TYPE};
     
    return $str if $str !~ /[^a-z0-9\.\-]/;    
    return convert( 
	command => 'from', 
	str => $str, 
	encoding => $encoding,
    );
}

sub puny_to_native {
    my $str = shift;
    $OPENSRS = shift;
    my $encoding = shift || $OPENSRS->{IDN_ENCODING_TYPE};

    return $str if $str !~ /^xn--/;
    return convert( 
	command => 'to', 
	str => $str, 
	encoding => $encoding,
    );
}

sub convert {
    my %args = @_;
    my $converted;

    if ( $useLibIDN ) {
	$converted = Net::LibIDN::idn_to_ascii($args{str}, $args{encoding})
	    if $args{command} eq 'from';
	$converted = Net::LibIDN::idn_to_unicode($args{str}, $args{encoding})
	    if $args{command} eq 'to';
    } else {
	my $useragent = new LWP::UserAgent();
	my $http_request = 
	    GET "http://$OPENSRS->{REMOTE_IDN_HOST}:".
	    "$OPENSRS->{REMOTE_IDN_PORT}?$args{command}=$args{encoding}&name=$args{str}";	
	my $http_response = $useragent->request($http_request);
	my $response = parse_http_response($http_response);    
	
	if ( $response->{is_success} ) {
	    $converted = $response->{punycode} if $args{command} eq 'from';
	    $converted = $response->{native} if $args{command} eq 'to';
	} else {
	    warn "Conversion failed: $response->{response_text}";
	    $converted = $args{str}
	}
    }
    
    return $converted;
}

sub parse_http_response {
    my $http_response = shift;
    my %response;
    
    foreach ( split "\015\012", $http_response->content ) {
	$response{$1} = $2 if $_ =~ /(.*)=(.*)/;
    }   

    return \%response; 
}

#-----------------------------------------------------------------------
#	Private Global Variables
#-----------------------------------------------------------------------
my %CODES     = ();
my %LANGUAGES = ();


#=======================================================================

=head1 CONVERSION ROUTINES

There are two conversion routines: C<code2language()> and C<language2code()>.

=over 8

=item code2language()

This function takes a three letter language code and returns a string
which contains the name of the language identified. If the code is
not a valid language code, as defined by ISO 639, then C<undef>
will be returned.

    $lang = code2language($code);

=item language2code()

This function takes a language name and returns the corresponding
three letter language code, if such exists.
If the argument could not be identified as a language name,
then C<undef> will be returned.

    $code = language2code('French');

The case of the language name is not important.
See the section L<KNOWN BUGS AND LIMITATIONS> below.

=back

=cut

#=======================================================================
sub code2language
{
    my $code = shift;


    return undef unless defined $code;
    $code = lc($code);
    if (exists $CODES{$code})
    {
        return $CODES{$code};
    }
    else
    {
        #---------------------------------------------------------------
        # no such language code!
        #---------------------------------------------------------------
        return undef;
    }
}

sub language2code
{
    my $lang = shift;


    return undef unless defined $lang;
    $lang = lc($lang);
    if (exists $LANGUAGES{$lang})
    {
        return $LANGUAGES{$lang};
    }
    else
    {
        #---------------------------------------------------------------
        # no such language!
        #---------------------------------------------------------------
        return undef;
    }
}

#=======================================================================

=head1 QUERY ROUTINES

There are two function which can be used to obtain a list of all
language codes, or all language names:

=over 8

=item C<all_language_codes()>

Returns a list of all two-letter language codes.
The codes are guaranteed to be all lower-case,
and not in any particular order.

=item C<all_language_names()>

Returns a list of all language names for which there is a corresponding
two-letter language code. The names are capitalised, and not returned
in any particular order.

=back

=cut

#=======================================================================
sub all_language_codes
{
    return keys %CODES;
}

sub all_language_names {
    return values %CODES;
}

sub get_idn_for_tld{
    my $fqdn = shift;
    if ($fqdn =~ /\.(com|net)$/){
	return (sort keys %CODES);
    } elsif ( $fqdn =~ /\.org/ ){
	return (sort qw/ 
ger
dan
lit
lav
ice
num
kor
swe
pol
/);
    } elsif ( $fqdn =~ /\.info/ ){
	return (sort qw/ 
ger
/);
    } elsif ( $fqdn =~ /\.de/ ){
	return (sort qw/ 
alb
cat
fin
ger
fre
dan
dut
scr
cze
est
hun
ita
lav
ice
lit
nor
pol
por
slo
spa
swe
tur
vie
wel
/);
    }
}

sub build_universal_encoding_menu {
	my %args = @_;
	my($retstring, $language_tag, $selected);
	my @language_tags = sort keys %CODES;
	if ($args{Domain}){
	    @language_tags = get_idn_for_tld($args{Domain});
	}
	
        $args{Default} ||= 'Standard ASCII';
	$retstring = "   <OPTION VALUE=\"\">\n";
	foreach $language_tag ( @language_tags )
	{
		$selected = "";
      		$selected = "SELECTED" if ($CODES{$language_tag} eq $args{Default});
		$retstring .= "   <OPTION VALUE=\"" . $language_tag . "\" $selected>" . $CODES{$language_tag} . "\n";
	}
	
	return $retstring;
}

sub build_wsb_language_list {
	my %args = @_;
	my($retstring, $language_tag, $selected);
	my $CODES = $args{Languages}; 
	$args{Default} ||= 'English';
        foreach $language_tag ( sort { $CODES->{$a} cmp $CODES->{$b} }  (keys (%{$CODES})) )
        {
		$selected = "";
                $selected = "SELECTED" if ($CODES->{$language_tag} eq $args{Default} or $language_tag eq $args{Default});
                $retstring .= "   <OPTION VALUE=\"" . $language_tag . "\" $selected>" . $CODES->{$language_tag} . "\n";
        }
        return $retstring;
}

#-----------------------------------------------------------------------

=head1 EXAMPLES

The following example illustrates use of the C<code2language()> function.
The user is prompted for a language code, and then told the corresponding
language name:

    $| = 1;    # turn off buffering
    
    print "Enter language code: ";
    chop($code = <STDIN>);
    $lang = code2language($code);
    if (defined $lang)
    {
        print "$code = $lang\n";
    }
    else
    {
        print "'$code' is not a valid language code!\n";
    }

=head1 KNOWN BUGS AND LIMITATIONS

=over 4

=item *

In the current implementation, all data is read in when the
module is loaded, and then held in memory.
A lazy implementation would be more memory friendly.

=item *

Currently just supports the two letter language codes -
there are also three-letter codes, and numbers.
Would these be of any use to anyone?

=back

=head1 SEE ALSO

=over 4

=item OpenSRS::Country

ISO codes for identification of country (ISO 3166).
Supports 2-letter, 3-letter, and numeric country codes.

=item OpenSRS::Currency

ISO three letter codes for identification of currencies and funds (ISO 4217).

=item ISO 639:1988 (E/F)

Code for the representation of names of languages.

=item http://lcweb.loc.gov/standards/iso639-2/langhome.html

Home page for ISO 639-2

=back


=head1 AUTHOR

Neil Bowers E<lt>neilb@cre.canon.co.ukE<gt>

=head1 COPYRIGHT

Copyright (c) 1997-2001 Canon Research Centre Europe (CRE).

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#-----------------------------------------------------------------------

#=======================================================================
# initialisation code - stuff the DATA into the CODES hash
#=======================================================================
{
    my $code;
    my $language;


    while (<DATA>)
    {
        next unless /\S/;
        chop;
        ($code, $language) = split(/:/, $_, 2);
        $CODES{$code} = $language;
        $LANGUAGES{"\L$language"} = $code;
    }
}

1;

__DATA__
afr:Afrikaans					    
alb:Albanian						    
ara:Arabic					    
arg:Aragonese							    
arm:Armenian							    
asm:Assamese							    
ast:Asturian; Bable						    
ave:Avestan							    
awa:Awadhi							    
aze:Azerbaijani 						    
bak:Bashkir							    
bal:Baluchi							    
ban:Balinese							    
baq:Basque							    
bas:Basa							    
bel:Belarusian  						    
ben:Bengali							    
bho:Bhojpuri							    
bos:Bosnian							    
bul:Bulgarian							    
bur:Burmese							    
car:Carib							    
cat:Catalan							    
che:Chechen							    
chi:Chinese							    
chv:Chuvash							    
cop:Coptic							    
cos:Corsican							    
cze:Czech							    
dan:Danish							    
div:Divehi							    
doi:Dogri							    
dut:Dutch; Flemish						    
eng:English							    
est:Estonian							    
fao:Faroese							    
fij:Fijian							    
fin:Finnish							    
fre:French-FRE  						    
fry:Frisian							    
geo:Georgian-GEO						    
ger:German							    
gla:Gaelic; Scottish Gaelic					    
gle:Irish							    
gon:Gondi							    
gre:Greek							    
guj:Gujarati							    
heb:Hebrew							    
hin:Hindi							    
hun:Hungarian							    
ice:Icelandic							    
inc:Indic (Other)						    
ind:Indonesian  						    
inh:Ingush							    
ita:Italian							    
jav:Javanese							    
jpn:Japanese							    
kas:Kashmiri							    
kaz:Kazakh							    
khm:Khmer							    
kir:Kirghiz							    
kor:Korean							    
kur:Kurdish							    
lao:Lao 							    
lav:Latvian							    
lit:Lithuanian  						    
ltz:Luxembourgish; Letzeburgesch				    
mac:Macedonian  						    
mal:Malayalam							    
mao:Maori-MAO							    
may:Malay-MAY							    
mlt:Maltese							    
mol:Moldavian							    
mon:Mongolian							    
nep:Nepali							    
non:None specified						    
nor:Norwegian							    
ori:Oriya							    
oss:Ossetian; Ossetic						    
pan:Panjabi							    
per:Persian-PER 						    
pol:Polish							    
por:Portuguese  						    
pus:Pushto							    
raj:Rajasthani  						    
rum:Romanian							    
rus:Russian							    
san:Sanskrit							    
scc:Serbian							    
scr:Croatian							    
sin:Sinhalese							    
slo:Slovak							    
slv:Slovenian							    
smo:Samoan							    
snd:Sindhi							    
som:Somali							    
spa:Spanish; Castilian  					    
srd:Sardinian							    
swa:Swahili							    
swe:Swedish							    
syr:Syriac							    
tam:Tamil							    
tel:Telugu							    
tgk:Tajik							    
tha:Thai							    
tib:Tibetan							    
tur:Turkish							    
ukr:Ukrainian							    
urd:Urdu							    
uzb:Uzbek							    
vie:Vietnamese  						    
wel:Welsh							    
yid:Yiddish							    

#!/usr/bin/perl

#       .Copyright (C)  1999-2002 TUCOWS.com Inc.
#       .Created:       11/19/1999
#       .Contactid:     <admin@opensrs.org>
#       .Url:           http://www.opensrs.org
#       .Originally Developed by:
#                       VPOP Technologies, Inc. for Tucows/OpenSRS
#       .Authors:       Joe McDonald, Tom McDonald, Matt Reimer, Brad Hilton,
#                       Daniel Manley, Evgeniy Pirogov
#
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

package OpenSRS::Util::Common;

use strict;
use OpenSRS::Util::ConfigJar;
use Exporter;
use OpenSRS::Country;
use Socket;
use Data::Dumper;
#Locale::Country::_alias_code('uk' => 'gb');

use vars  qw ( @ISA @EXPORT_OK );

@ISA = qw(Exporter);
@EXPORT_OK = qw (  country_list_2_long
		   CODE_2_Country
		   send_email
                   build_select_menu
                   build_select_menu3
                   build_country_list
		   locale_build_country_list
		   make_navbar
		   make_navbar_dns
		   domain_syntax
		   username_syntax
		   password_syntax
		   hostname_syntax
		   email_syntax
		   ip_syntax
		   get_cc_fields
		   verify_cc_info
		   cc_verify
		   cc_exp_verify
		   build_year_menu
		   build_month_menu
		   build_day_menu		   
		   );

my @country_list; #For mod_perl closures
my %ccodes_hash;
my %config;

sub initialize {
    my %settings = @_;
    
    %config = %settings;
}

sub domain_syntax {

    my $domain = lc shift;
    my $error;

    if ( length $domain > 255 ) {
        $error = "Length of domain should be less than 255 characters.<br>";
    }
    if (($domain !~ /^[a-z0-9\.-]+$/) || ($domain !~ /(?:[a-z0-9](?:[-a-z0-9]*[a-z0-9])*\.)+[a-z]{2,}/)) {
        $error .= "The format of domain name $domain is invalid. You will need to correct it before proceeding.";               
    }                                                                                                                                                             
    return $error;
}

sub username_syntax {

    my $name = lc shift;
    my $error_msg;
                                                                                                                                                             
    if ($name =~ /^\s*$/) {     # don't allow empty usernames
        return "No username was given.";
    }
                                                                                                                                                             
    if (length $name > 20) {
        $error_msg = "Invalid length of username $name: Username should contain at least 1 and at most 20 characters.";
    }
                                                                                                                                                             
    if ($name !~ /^[a-z0-9]+$/i) {
        $error_msg .= "Invalid syntax of username $name: The only allowed characters are all alphanumerics (A-Z, a-z, 0-9).";
    }
                                                                                                                                                             
    return $error_msg;
}
                                                                                                                                                             
sub password_syntax {
                                                                                                                                                             
    my $password = lc shift;
    my $error_msg;
                                                                                                                                                             
    if ($password =~ /^\s*$/) {    # don't allow empty passwords
        return "No password was given.";
    }
                                                                                                                                                             
    if (length $password < 6 || length $password > 20) {
        $error_msg = "Invalid password length: Password should contain at least 6 and at most 20 characters.";
    }
                                                                                                                                                             
    #I have added the \x7F character explicitly for bug 5262
    if ($password !~ /^[a-z0-9\[\]\(\)!@\$\^,\.~\|=\-\+_\x7F\#\{\}]+$/i) {
        $error_msg .= "Invalid password syntax: The only allowed characters are all alphanumerics (A-Z, a-z, 0-9) and symbols []()!@\$^,.~|=-+_{}#";
    }
                                                                                                                                                             
    return $error_msg;
}

# return 1 if no errror, undef if error.
sub hostname_syntax {
                                                                                                                            
    my $hostname = lc shift;
    # this is very loose error checking.  it allows a-z0-9 .'s and -'s
    if ($hostname !~ /^[a-z0-9][a-z0-9\.\-]*[a-z0-9]$/) {
        return undef;
    } elsif (length $hostname > 255) {
        return undef;
    } else {
        return 1;
    }
}

# return 1 if no errror, undef if error.                                                                                                                    
sub ip_syntax {
                                                                                                                            
    my $ip = shift;
                                                                                                                            
    if (length $ip > 15) {
        return undef;
    } elsif ($ip !~ /^\d+\.\d+\.\d+\.\d+$/) {
        return undef;
    }
                                                                                                                            
    my @parts = split /\./, $ip;
    foreach (@parts) {
        # Bugzilla bug 9 -- change ">=" to just ">". dmanley
        if ($_ > 255) {
            return undef;
        }
    }
                                                                                                                            
    return 1;
}

sub email_syntax {
                                                                                                                                                             
    my $email = shift;
    return "Empty email." if (not $email);
    if ($email =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||
        $email !~ /^\S+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/) {
        return "Invalid email syntax";
    }
}

sub country_list_2_long(){
    return \@country_list if scalar @country_list;
    @country_list=all_country_codes(LOCALE_CODE_ALPHA_2);
    map {$_={code=>uc($_),name=>code2country($_,LOCALE_CODE_ALPHA_2)}} @country_list;
    @country_list = sort {$a->{name} cmp $b->{name}} @country_list;
    return \@country_list;
}

sub CODE_2_Country($){
    return code2country(lc(shift),LOCALE_CODE_ALPHA_2);
}

# generic method to send an email based on a template and a hash ref of values
sub send_email {
    my ( $template, $href ) = @_;
    my ( $mail_type, $mail_prog );

    $mail_type = $OpenSRS::Util::ConfigJar::MAIL_SETTINGS{MAIL_TYPE};
    $mail_prog = $OpenSRS::Util::ConfigJar::MAIL_SETTINGS{MAILPROG};

    open (FILE, "<$template") or die "Couldn't open $template: $!\n";
    $/ = undef;
    my $message = <FILE>;
    $/ = "\n";
    close FILE;

    $message =~ s/{{(.*?)}}/$href->{$1}/g;

    my $mailto = $href->{mailto};
    my $mailfrom = $href->{mailfrom};

    if ($mail_type eq 'sendmail') {
        open (MAIL, "|$mail_prog") or die "Can't open $mail_prog: $!\n";
        print MAIL $message;
        close MAIL or return undef;
    } else {
        #OpenSRS::Util::Common::_send_smtp_mail(
        _send_smtp_mail(
		$mailto, $mailfrom, $message
	) or return undef;
    }
    return 1;
}

sub _send_smtp_mail {

    my ( $to, $from, $message ) = @_;
    my ( $iaddr, $paddr, $proto, $smtp_server, $smtp_port, $localhost );

    $smtp_server = $OpenSRS::Util::ConfigJar::MAIL_SETTINGS{SMTP_SERVER};
    $smtp_port   = $OpenSRS::Util::ConfigJar::MAIL_SETTINGS{SMTP_PORT};
    $localhost   = $OpenSRS::Util::ConfigJar::MAIL_SETTINGS{LOCALHOST};

    $iaddr = inet_aton( $smtp_server );
    $paddr = sockaddr_in( $smtp_port, $iaddr );
    $proto = getprotobyname( 'tcp' );
    socket( SOCK, PF_INET, SOCK_STREAM, $proto )   or return 0;
    connect( SOCK, $paddr )                        or return 0;
    _receive_from_server( \*SOCK )                 or return 0;
    _send_to_server( \*SOCK, "HELO $localhost" )   or return 0;
    _receive_from_server( \*SOCK )                 or return 0;
    _send_to_server( \*SOCK, "MAIL FROM: <$from>") or return 0;
    _receive_from_server( \*SOCK )                 or return 0;
    _send_to_server( \*SOCK, "RCPT TO: <$to>" )    or return 0;
    _receive_from_server( \*SOCK )                 or return 0;
    _send_to_server( \*SOCK, "DATA" )              or return 0;
    _receive_from_server( \*SOCK )                 or return 0;
    _send_to_server( \*SOCK, "$message\n." )       or return 0;
    _receive_from_server( \*SOCK )                 or return 0;
    _send_to_server( \*SOCK, "QUIT" )              or return 0;
    _receive_from_server( \*SOCK )                 or return 0;
    close( SOCK )                                  or return 0;
    return 1;
}

sub _send_to_server {
    my( $socket )  = shift;
    my( $message ) = shift;
    send( $socket, "$message\n", 0 ) or return 0;
    return 1;
}

sub _receive_from_server {
    my( $socket ) = shift;
    my( $reply );
    while( $reply = <$socket> ) {
        return 0 if $reply =~ /^5/;
        last      if $reply =~ /^\d+ /;
    }
    return 1;
}

sub fancy_sort {

    my (@words,@ints);

    my @list = @_;
    
    foreach (@list) {
	if ($_ =~ /^\d+$/) {
	    push @ints, $_;
	} else {
	    push @words, $_;
	}
    }
    
    @words = sort @words;
    @ints = sort { $a <=> $b } @ints;
    
    return (@ints,@words);
    
}

sub build_select_menu {
    my ($key,$html);

    my $href = shift;
    my $default = shift;

    foreach $key (fancy_sort(keys %$href)) {
	if ($key eq $default) {
	    $html .= <<EOF;
<option value="$key" SELECTED> $href->{$key}
EOF
} else {
    $html .= <<EOF;
<option value="$key"> $href->{$key}
EOF
}
    }
    return $html;
}

sub build_year_menu {

    my $start_year = shift;
    my $end_year =  shift;
    my $default_year = shift;

    my %years;
    for (my $i = $start_year; $i <= $end_year; $i++) {
       $years{$i} = $i;
    }
    return build_select_menu(\%years, $default_year); 
}
sub build_month_menu {

    my @mos = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $default_month = shift || 1;
                                                                                                                                                             
    my %months;
    for (my $i = 1; $i <= 12; $i++) {
       $months{$i} = $mos[$i - 1];
    }
    return build_select_menu(\%months, $default_month);
}
sub build_day_menu {
                                                                                                                                                             
    my $default_day = shift || 1;
    my %days;
    for (my $i = 1; $i <= 31; $i++) {
       $days{$i} = $i;
    }
    return build_select_menu(\%days, $default_day);
}


sub build_radio_menu {

    my ($key,$html,$value);
    my $href = shift;
    my $default = shift;

    foreach $key (keys %$href) {
        $value=$href->{$key};
	if ($key eq $default) {
	    $html .= <<EOF;
<br><input type=radio name=pass_assgnmt value=$key checked>$value
EOF
	} else {
	    $html .= <<EOF;
<br><input type=radio name=pass_assgnmt value=$key>$value
EOF
	}
    }
    return $html;
}


sub build_select_menu3 {
    my ($key,$value,$html);
    my ($href,$aref,$default) = @_;

    foreach $key (@$aref) {
        $value = $href->{$key};
        if ($key eq $default) {
            $html .= <<EOF;
<option selected value="$key"> $value
EOF
        } else {
            $html .= <<EOF;
<option value="$key"> $value
EOF
        }
    }
    return $html;
}

sub build_country_list {
    return locale_build_country_list(@_);
}

sub locale_build_country_list {
    my $default_id = shift;

    $default_id = 'US' if not defined $default_id;
    $default_id =~ tr/a-z/A-Z/;
    my $html = join ("\n",map {
	"<option value=" . 
	$_->{code} .
	($_->{code} eq  $default_id?' selected ':'') . 
	">" . $_->{name}}  @{country_list_2_long()});    

    #old codes show as it is
    unless (code2country($default_id,LOCALE_CODE_ALPHA_2)){
	$html .= "\n". "<option value=$default_id selected>$default_id\n"; 
    }	
    return $html;
}

sub make_navbar {

    my ($start_page,$end_page,$i,$navbar,$current_page);
    my ($back,$next_page_start,$display_page);
    my ($action,$count,$items_per_page,$num_page_links,$this_page) = @_;
    if ($count == 0) {
        return "";
    }
    my $pages = int ($count/$items_per_page);
    # add extra page for remainder
    $pages++ if ($count % $items_per_page);

    $start_page = $this_page - ($this_page % $num_page_links);

    if (($start_page + $num_page_links) > ($pages - 1)) {
        $end_page = $pages - 1;
    } else {
        $end_page = $start_page + $num_page_links - 1;
    }

    if ($pages > 0) {
        $navbar .= "<b>Page</b> ";
    }

    if ($start_page > 0) {
        if (($start_page - $num_page_links) > 0) {
            $back = $start_page - $num_page_links;
        } else {
            $back = 0;
        }
 $navbar .= <<EOF;
<a href="$ENV{SCRIPT_NAME}?action=$action&page=$back">&lt;&lt;</a>
EOF
}

    for ($i = $start_page; $i <= $end_page; $i++) {
        $current_page = $i;
        $display_page = $current_page + 1;

        if ($current_page == $this_page) {
            $navbar .= "<b>$display_page</b>&nbsp;";
        } else {
            $navbar .= <<EOF;
<a href="$ENV{SCRIPT_NAME}?action=$action&page=$current_page">$display_page</a>&nbsp;
EOF
        }
    }

    if ($end_page < ($pages - 1)) {
        if (($start_page + $num_page_links) < $pages) {
            $next_page_start = $start_page + $num_page_links;
        } else {
            $next_page_start = $this_page + 1;
        }

        $navbar .= <<EOF;
<a href="$ENV{SCRIPT_NAME}?action=$action&page=$next_page_start">&gt;&gt;</a>
EOF
    }

    if ($pages > 0) {
        $navbar .= " <b>of $pages</b>";
    }
 my $next_page = $this_page + 1;

    if ($next_page <= ($pages - 1)) {
        $navbar .= <<EOF;
<a href="$ENV{SCRIPT_NAME}?action=$action&page=$next_page"> [Next]</a>
EOF
    }

    return $navbar;
}

sub make_navbar_dns {

    my ($start_page,$end_page,$i,$navbar,$current_page);
    my ($back,$next_page_start,$display_page);
    my ($action,$count,$items_per_page,$num_page_links,$this_page) = @_;
    if ($count == 0) {
        return "";
    }
    my $pages = int ($count/$items_per_page);
    # add extra page for remainder
    $pages++ if ($count % $items_per_page);

    $start_page = $this_page - ($this_page % $num_page_links);

    if (($start_page + $num_page_links) > ($pages - 1)) {
        $end_page = $pages - 1;
    } else {
        $end_page = $start_page + $num_page_links - 1;
    }

    if ($start_page > 0) {
        if (($start_page - $num_page_links) > 0) {
            $back = $start_page - $num_page_links;
        } else {
            $back = 0;
        }
   $navbar .= <<EOF;
<a href="$ENV{SCRIPT_NAME}?action=$action&page=$back">[Previous 10]</a>
EOF
}

    if ($pages > 0) {
        $navbar .= "Page ";
    }

   for ($i = $start_page; $i <= $end_page; $i++) {
        $current_page = $i;
        $display_page = $current_page + 1;
       
        if ($current_page == $this_page) {
            $navbar .= "<b>$display_page</b>&nbsp;";
        } else {
            $navbar .= <<EOF;
<a href="$ENV{SCRIPT_NAME}?action=$action&page=$current_page">$display_page</a>&nbsp;
EOF
        }
    }

    if ($pages > 0) {
        $navbar .= " displayed of $pages";
    }
 my $next_page = $this_page + 1;

    if ($next_page <= ($pages - 1)) {
        $navbar .= " ";
        $navbar .= <<EOF;
<a href="$ENV{SCRIPT_NAME}?action=$action&page=$next_page">[Next]</a>
EOF
    }

    if ($end_page < ($pages - 1)) {
        if (($start_page + $num_page_links) < $pages) {
            $next_page_start = $start_page + $num_page_links;
        } else {
            $next_page_start = $this_page + 1;
        }

        $navbar .= <<EOF;
<a href="$ENV{SCRIPT_NAME}?action=$action&page=$next_page_start">[Next 10]</a>
EOF
    }

    return $navbar;
}


#################### CREDIT CARD ################################

sub get_cc_fields {

    my $template = shift;

    return get_content($template, {CC_YEARS => build_select_menu(get_cc_years(),(localtime)[5] + 1900)});
}

# grab the contents of a template, substitute any supplied values, and return
# the results
sub get_content {
                                                                                                                                                             
    my $content;
                                                                                                                                                             
    my ($template,$HTML) = @_;
    open (FILE, "<$template") or die "Couldn't open $template: $!\n";
    while (<FILE>) {
        s/{{(.*?)}}/pack('A*',$HTML->{$1})/eg;
        $content .= $_;
    }
    close FILE;
                                                                                                                                                             
    return $content;
                                                                                                                                                             
}

sub get_cc_years {
                                                                                                                                                             
    my (%years,$i);
    my $year = (localtime)[5];
    $year += 1900;
                                                                                                                                                             
    for ($i = 0; $i <=5; $i++) {
        $years{$year} = $year;
        $year++;
    }
                                                                                                                                                             
    return \%years;                                                                                                                                                             
}

sub verify_cc_info {

    my $data = shift;
    
    my $cc_num = $data->{p_cc_num};
    my $cc_type = $data->{p_cc_type};
    my $cc_exp_mon = $data->{p_cc_exp_mon};
    my $cc_exp_yr = $data->{p_cc_exp_yr};

    ##################################################################
    # here we check the validity of the cc_number, both its length
    # and its validity
    
    return "Invalid credit card number.<br>" if not cc_verify($cc_num);
    
    return "Invalid credit card expiration: $cc_exp_mon/$cc_exp_yr.<br>"
        if not cc_exp_verify($cc_exp_mon,$cc_exp_yr);
}

sub cc_verify {
    my ($number) = @_;
    my ($i, $sum, $weight);
                                                                                                                                                             
    return 0 if $number =~ /[^\d\s\-]/;
                                                                                                                                                   
    $number =~ s/\D//g;
                                                                                                                                                             
    return 0 unless length($number) >= 13 && 0+$number;
                                                                                                                                                      
    for ($i = 0; $i < length($number) - 1; $i++) {
    $weight = substr($number, -1 * ($i + 2), 1) * (2 - ($i % 2));
    $sum += (($weight < 10) ? $weight : ($weight - 9));
    }
                                                                                                                                                             
    return 1 if substr($number, -1) == (10 - $sum % 10) % 10;
    return 0;
}
                                                                                                                                                             
sub cc_exp_verify {
                                                                                                                                                             
    my ($cc_exp_mon,$cc_exp_yr) = @_;
                                                                                                                                                             
    my ($month,$year) = (localtime)[4,5];
    $month++;
    $year += 1900;
                                                                                                                                                             
    my $current_month = sprintf("%04d%02d",$year,$month);
    my $cc_exp = sprintf("%04d%02d",$cc_exp_yr,$cc_exp_mon);
    if ($current_month > $cc_exp) {
        return 0;
    }
    return 1;
}
1;

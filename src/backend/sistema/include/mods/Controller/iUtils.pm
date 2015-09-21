#!/usr/bin/perl
package Controller::iUtils;

require 5.008;
require Exporter;
use Carp;

our @ISA = qw( Exporter );
our @EXPORT = qw( iDelete iKeys iUnique iExtension trim sem_acentos frmt escape unquote quote squote html unhtml html2text text2html iDifference iSQLjoin tostring simple_crypt simple_decrypt URLDecode URLDecode2 URLEncode Post2Get cut_string frmtCPFCNPJ num2valor valor2num string2monthyear monthyear2string nospace encrypt_mm decrypt_mm iso2puny puny2iso iso2utf8 utf82iso frmtPotalCode crypt decrypt timeadd_offset sql_comments getCreditCardType);#our @EXPORT_OK = qw();

BEGIN {
$iUtils::VERSION = "0.5";
}

#Biblioteca para exportar subrotinas, não utilizar com OOP
sub iDelete {
	my ($arrayref,$comp,$target) = @_; 
	
	return() if ref ($arrayref) ne "ARRAY";
	$target ||= '';	
	
	if ($comp eq "==") {
		@$arrayref = grep { $_ eq $target } @$arrayref;
	} else {
		@$arrayref = grep { $_ ne $target } @$arrayref;
	}
	
	return(@$arrayref);
}

sub iExtension {
	my ($name,$dot) = @_;
	
	$name =~ s/.*\.(.+)$/$1/;
	
	return $dot.$name;
}

sub iKeys {
	my ($hash,$func) = @_;
	$func ||= 'uc';
	
	my @keys = keys %$hash;
	my @array;
	@array = map( uc $_ , @keys) if ($func eq 'uc');
	@array = map( lc $_ , @keys) if ($func eq 'lc');
	
	return @array;
}

sub iUnique {
	my ($arrayref) = @_;
    my %h;
	return() if ref ($arrayref) ne "ARRAY";
	
    @$arrayref = grep {! $h{$_}++ } @$arrayref;

	return(@$arrayref);
}

sub iDifference {
	my ($arrayA,$arrayB) = @_; #need reference
	return() if ref ($arrayA) ne "ARRAY" || ref ($arrayB) ne "ARRAY";
	
	my ( @intersection, @differenceAB ) = ((),());
	my %count = ();
	foreach my $element (@$arrayB) { $count{lc $element}++ };
	foreach my $element (@$arrayA) {
		push @{ $count{lc $element} >= 1 ? \@intersection : \@differenceAB }, $element;
    }
	
	return \@differenceAB, \@intersection;
}

sub iSQLjoin {
	my ($columns, $t, $d) = @_;
	return() if ref ($columns) ne "ARRAY";
	
	return join(', ', map {"`$_`"} @$columns) if $t == 0; # SELECT
	return join(" $d ", map {"`$_` = ? "} @$columns) if $t == 1; # WHERE OR SET
}

sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//s;
	$string =~ s/\s+$//s;
	return $string;
}

sub nospace {
	my $string = shift;
	$string =~ s/\s//g;
	return $string;	
}

sub sem_acentos {
	my $word = shift;
	unhtml(\$word);#need to understand html
	
	$word =~ s/[àáâãä]/a/g;
	$word =~ s/[èéêë]/e/g;
	$word =~ s/[ìíîï]/i/g;
	$word =~ s/[òóôõö]/o/g;
	$word =~ s/[ùúûü]/u/g;
	$word =~ s/[ÀÁÂÃÄ]/A/g;
	$word =~ s/[ÈÉÊË]/E/g;
	$word =~ s/[ÌÍÎ]/I/g;
	$word =~ s/[ÒÓÔÕÖ]/O/g;
	$word =~ s/[ÙÚÛÜ]/U/g;
	$word =~ s/Ç/C/g; $word =~ s/ç/c/g;
	$word =~ s/Ñ/N/g; $word =~ s/ñ/n/g;

	return $word;
}

#formatos
sub frmt {
	my $valor = shift;
	my $case = shift;
	my %opt = @_;

	if ($case eq "phone") {
		$valor = num('',$valor);
		return undef if $valor == 0;
	
		#especiais
		return $valor if $valor =~ m/^0800/;
		$valor =~ s/^([1-9]{2})([0-9]{3,5})([0-9]{4}).*/($1) $2-$3/;
		return $valor;
	}
		
	if ($case eq "epp_phone") {
		$valor = num('',$valor);
		return undef if $valor == 0;
		if ($opt{cc}) {
			$opt{cc} =~ s/^([1-9]{1}[0-9]{0,2}).*/$1/;
			$valor = "+$opt{cc}.".$valor;
		}
		if ($opt{ext}) {
			$opt{ext} =~ s/^([0-9]{1,4}).*/$1/;
			$valor .= "x$opt{ext}" ;
		}
		
		return $valor;
	}
	
	return undef; #Return simplesmente, causa erro na definicao de valor em hash com sub
}

sub frmtCPFCNPJ {
	my $valor = shift;	

	$valor =~ s/[\-\.\/]//g;
	$valor = substr($valor,1,14) if (length $valor == 15);

	if (length $valor == 11) {
		$valor = substr($valor,0,3).'.'.substr($valor,3,3).'.'.substr($valor,6,3).'-'.substr($valor,9,2);
	} elsif (length $valor == 14) {
		$valor = substr($valor,0,2). '.'.substr($valor,2,3).'.'.substr($valor,5,3).'/'.substr($valor,8,4).'-'.substr($valor,12,2);
	}

	return $valor;
}
#
sub escape {
	my $ref = shift;
	return() if ref ($ref) ne "SCALAR";
	
	$$ref =~  s/([^\w\s-])/\\$1/g;
	
	return $ref; #copy
}

sub unquote {#backslashe quotes
	my $ref = shift;
	
	$$ref =~ s/['"\\]/\\$&/gmo if ref ($ref) eq "SCALAR";
	$ref =~ s/['"\\]/\\$&/gmo if ref ($ref) eq "";
	
	return $ref;
}

sub quote {#backslash quotes
	my $ref = shift;
	
	$$ref =~ s/['"\\]/\\$&/gmo if ref ($ref) eq "SCALAR";
	$$ref = qq{"$$ref"} if ref ($ref) eq "SCALAR";
	$ref =~ s/['"\\]/\\$&/gmo if ref ($ref) eq "";
	$ref = qq{"$ref"} if ref ($ref) eq "";
	
	return $ref;
}

sub squote {#backslash quotes
	my $ref = shift;
	
	return undef unless defined $ref;
	
	$$ref =~ s/['\\]/\\$&/gmo if ref ($ref) eq "SCALAR";
	$$ref = qq{'$$ref'} if ref ($ref) eq "SCALAR";
	$ref =~ s/['\\]/\\$&/gmo if ref ($ref) eq "";
	$ref = qq{'$ref'} if ref ($ref) eq "";
	
	return $ref;
}

sub sql_comments {#backslash SQL comments
	my $ref = shift;
	
	return undef unless defined $ref;
	
	$$ref =~ s/--/\\-\\-/gmo if ref ($ref) eq "SCALAR";
	$ref =~ s/--/\\-\\-/gmo if ref ($ref) eq "";
	
	return $ref;
}

sub unhtml {
	my $ref = shift;
	use HTML::Entities;
	
	if (ref ($ref) eq "SCALAR") {
		$$ref = HTML::Entities::decode($$ref);
	} elsif ( ref ($ref) eq "" ) {
		$ref = HTML::Entities::decode($ref);
	}

	return $ref;
}

sub html {
	my $ref = shift;
	use HTML::Entities;
	
	if (ref ($ref) eq "SCALAR") {
		$$ref = HTML::Entities::encode($$ref);
	} elsif ( ref ($ref) eq "" ) {
		$ref = HTML::Entities::encode($ref);
	}

	return $ref;
}

sub html2text {
	my $ref = shift;
	return() if ref ($ref) ne "SCALAR";

	package myHTML;
	use base HTML::TreeBuilder;
	use strict;
	use warnings;

	#require Encode;
	sub as_text {
		# Yet another iteratively implemented traverser
		my($this,%options) = @_;
		my $skip_dels = $options{'skip_dels'} || 0;
		my(@pile) = ($this);
		my $tag;
		my @text;
		my $nillio = [];
		while(@pile) {
			if(!defined($pile[0])) { # undef!
				# no-op
			} elsif(!ref($pile[0])) { # text bit!  save it!
				push @text, Encode::encode("utf8", shift @pile); #Resolve temporairamente o problema da “ trocando pra ?
			} else { # it's a ref -- traverse under it
				unshift @pile, @{$this->{'_content'} || $nillio}
					unless
						($tag = ($this = shift @pile)->{'_tag'}) eq 'style'
						or $tag eq 'script'
						or ($skip_dels and $tag eq 'del');			
				unshift @pile, shift @pile, " <".$this->attr('href').">" if $tag eq 'a' && $this->attr('href') && $pile[0] && $pile[0] ne $this->attr('href');

				push @text, "\n" if $HTML::Element::canTighten{$tag};				 
			}
		}
		
		return join('',@text);
	}	
	sub as_trimmed_text {	
		my $text = shift->as_text(@_);
		$text =~ s/[\n\r\f\t\s ]+$//s;
		$text =~ s/^[\n\r\f\t\s ]+//s;
		return $text;
	}		
	
	1;
	
	use HTML::Entities qw(_decode_entities);
	_decode_entities($$ref, { nb => "@", nbsp => " " }, 1);
		
	my $tree = myHTML->new_from_content($$ref);
	
	$$ref = $tree->as_trimmed_text(skip_dels => 1);
					
	$tree->delete();
	
	return $ref
}


sub text2html {
	my $ref = shift; 

	require HTML::TextToHTML;
	my $text = new HTML::TextToHTML;
	$$ref = $text->process_chunk($$ref) if ref ($ref) eq "SCALAR";
	$ref = $text->process_chunk($ref) if ref ($ref) eq "";	
	
	return $ref;	
}

sub iso2utf8 {
	my $text = shift;
	return undef unless $text;

	use Encode;
	$text = encode("utf8", decode("iso-8859-1", $text));

	return $text;
}

sub utf82iso {
	my $text = shift;
	return undef unless $text;

	use Encode;
	$text = encode("iso-8859-1", decode("utf8", $text));
	
	return $text;
}
	
sub iso2puny { 
	my @text = split(/\./,shift);
	return undef unless @text;

	use Net::IDN::Encode;

	return join '.', map {Net::IDN::Encode::to_ascii(Controller::trim($_))} @text;
}

sub puny2iso { 
	my @text = split(/\./,shift);
	return undef unless @text;
	
	use Net::IDN::Encode;

	return return join '.', map {Net::IDN::Encode::to_unicode(Controller::trim($_))} @text;;
}

sub tostring {
	my $ref = shift;
	my $string;

	use Data::Dumper;
	local $Data::Dumper::Indent = 0;
	local $Data::Dumper::Useperl = 1;
	
	my $class = ref $ref;
    if ($class =~ /Controller/) { #sql
		$string = Dumper $ref->{sql};		
	} else {
		$string = Dumper $ref;
	}	
	$string =~ s/^\$VAR1 =\s*//;
	
	return $string;
}

sub cut_string {
	my ($ref,$rmt,$max,$protect) = @_;
	
	$max -= length $rmt;
	return $ref if $max < length($protect);
	my $ip = index($ref, $protect);
	return $ref if $ip == -1;
	$ip = 0 unless $protect;
	my $fp = $ip + length($protect);
	my $tam = length($ref);
	return $ref if $max > $tam;	
	my $cut = $tam - $max;
	if ( $fp + $cut > $tam && $protect) {
		if ( $ip - $cut < 0) {
			$ref = $protect . $rmt;
		} else {
			substr($ref, $ip - $tam - $cut, $cut, $rmt); #corta antes
		}
	} else {
		substr($ref, -$cut, $cut, $rmt); #corta depois
	}
	return $ref	
}

sub randthis {
	my $self = shift;
	
	my $r;
	my $_rand;
	
	my $rlength = $_[0] || 10;
	my @chars = @_;
	srand;#Old version support	
	for (my $i=0; $i < $rlength ;$i++) {
		$r .= $chars[int rand(@chars)];
	}
	return $r;		
}

sub Post2Get {
	my $q = shift; #CGI Handler
	my @pairs = split(/;/, $q->query_string());
	my $post;
	foreach $pair (@pairs) {
	    my ($name, $value) = split(/=/, $pair);
	    $value =~ tr/+/ /;
	    $value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
	    $post .= "$name=$value&";
	}
	$ENV{'QUERY_STRING'} = "$post";
}

sub Hash2Query {
    my ( $self, $formdata ) = @_;
    if ( ref $formdata ) {
        return join( '&', map { $_ . '=' . URLEncode($formdata->{$_}) } keys %{$formdata} );
    }
    return $formdata;
}

sub Query2Hash {
    my ( $self, $query ) = @_;
    
    my %hash;
    for (split('&',$query)) {
    	my ($p,$v) = split('=');
		$hash{$p} = URLDecode($v);
    }
    
    return \%hash;
}

#TODO verificar de fazer esses números serem randomicos para cada cópia do sistema.
sub simple_crypt {
	my $var = shift;
	my $tam = length($var);
	my %cripto = ("a","11","b","13","c","15","d","17","e","19","f","22","g","24","h","27","i","31","j","34","k","36","l","39","m","41","n","43","o","10","p","12","q","14","r","16","s","18","t","20","u","21","v","23","x","25","z","26","w","28","y","29","0","30","1","32","2","33","3","35","4","37","5","38","6","40","7","42","8","44","9","45","\!","50","\@","51","\#","52","\$","53","\%","54","\^","55","\&","56","\*","57","\(","58","\)","59","\-","60","\+","61","\=","62","\\","63","\_","64","\|","65","\]","66","\[","67","\{","68","\}","69","\'","70","\"","71","\;","72","\:","73","\?","74","\/","75","\.","76","\>","77","\,","78","\<","79","\`","80","\~","81");
 	
 	my $nvar;
	while ($tam) {
		$tmp = substr($var,-($tam),1);
		$tmp = $cripto{$tmp};
		$nvar .= $tmp; 
		$tam--;
	}
	
	return URLEncode($nvar);
}

sub simple_decrypt {
	my $var = shift;
	my $tam = length($var);
	return if $tam % 2 ne 0;
	my %cripto = reverse("a","11","b","13","c","15","d","17","e","19","f","22","g","24","h","27","i","31","j","34","k","36","l","39","m","41","n","43","o","10","p","12","q","14","r","16","s","18","t","20","u","21","v","23","x","25","z","26","w","28","y","29","0","30","1","32","2","33","3","35","4","37","5","38","6","40","7","42","8","44","9","45","\!","50","\@","51","\#","52","\$","53","\%","54","\^","55","\&","56","\*","57","\(","58","\)","59","\-","60","\+","61","\=","62","\\","63","\_","64","\|","65","\]","66","\[","67","\{","68","\}","69","\'","70","\"","71","\;","72","\:","73","\?","74","\/","75","\.","76","\>","77","\,","78","\<","79","\`","80","\~","81");

	my $nvar;
	while ($tam) {
		$tmp = substr($var,-($tam),2);
		$tmp = $cripto{$tmp};
		$nvar .= $tmp; 
		$tam-=2;
	}
	
	return URLEncode($nvar);	
}

sub URLDecode {
    my $theURL = $_[0];

    $theURL =~ s/%([a-fA-F0-9]{2,2})/chr(hex($1))/eg;
    $theURL =~ s/<!--(.|\n)*-->//g;
    utf8::decode($theURL);
    utf8::downgrade($theURL, FAIL_OK);

    return $theURL;
}

sub URLDecode2 {
    my $value = shift;

	use Text::Iconv;
	my $ISO_UTF = Text::Iconv->new("ISO-8859-1", "UTF-8");
	my $ISO2_UTF = Text::Iconv->new("ISO-8859-2", "UTF-8");
	my $UTF_ISO = Text::Iconv->new("UTF-8", "ISO-8859-1");
	my $UTF_ISO2 = Text::Iconv->new("UTF-8", "ISO-8859-2");

	utf8::encode($value);
	utf8::decode($value);
	
	#UTF-8 Sequence
   	if ($value=~/%(C3|C4|C5)%([0-9A-Fa-f]{2})/i) {
   		utf8::encode($value);
   		$value =~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
   		utf8::decode($value);
  	}

	#ISO-8859-2 sequence
	if ($value=~/%([0-9A-Fa-f]{2})/)
	{
		utf8::encode($value);
		$value =~s/%([0-9A-Fa-f]{2})/pack("C",hex($1))/eg;
		$value = $ISO2_UTF->convert($value);
		utf8::decode($value);
	}
    
    return $value;
}

sub URLEncode {
   my $theURL = shift;

   $theURL =~ s/([\W])/"%" . uc(sprintf("%2.2x",ord($1)))/eg;

   return $theURL;
}

sub string2monthyear {
	my ($n) = shift;
	return substr($n,0,2), substr($n,-2);
}

sub monthyear2string {
	my ($m,$y) = @_;
	return substr($m,-2).substr($y,-2);
}

sub num2valor {
	my ($n) = shift;

	return 0 if !$n;
	return int((abs $n + .005) * 100);    
}

sub valor2num {
	my ($n) = num('',shift);
	
	return $n if (length $n < 3);
	substr($n,-2,0,'.');
	return $n;
}

sub Currency {
	my ($self,$n,$m) = @_;

	my $minus = $n < 0 ? '-' : '';
	my $dez = $self->setting('decimal');
	my $mil = $self->setting('milhar');
	my $moeda = $self->setting('moeda');
	
	$n = abs($n);
	$n = int(($n + .005) * 100) / 100;
	$n .= '.00' unless $n =~ /\./;
	$n .= '0' if substr($n,(length($n) - 2),1) eq '.';
    chop $n if $n =~ /\.\d\d0$/;
	chop $n if $n =~ /\,\d\d0$/;
	#colocar separador decimal
	$n =~ s/\./$dez/;
	#colocar separador milhar
	my $cs = 7;#mil
	while (length(substr($n,(length($n) - $cs),4)) == 4) {
		$p = substr($n,(length($n) - ($cs-1)));
		$n =~ s/$p//g;
		$n .= $mil.$p;
		$cs += 4;
	}
	
	return !$m ? "$moeda $minus$n" : "$minus$n";
}

sub Float {
	my ($self,$value) = @_;

	my $dez = "\\".$self->setting('decimal');
	my $mil = "\\".$self->setting('milhar');
	
	my ($minus) = $value =~ /^(-)/;
	$value =~ s/$mil//g;
	$value =~ s/$dez/\./;
	$value =~ s/[^\d.]//g;
	return $minus.$value;
}
#Math
sub mod {
	my ($self,$a,$b) = @_;
	
	$a -= int($a/$b);
	
	return $a;
}

sub num {
	my ($self,$num) = @_;
  
	my ($minus) = $num =~ /^(-)/;
	$num =~ s/\D//g; 
	$num = 0 if !$num;
	
	return $minus.$num;
}

sub round_int { #Deprecated, use $self->round(10.333,0);
	shift;
	return int($_[0] + .5 * ($_[0] <=> 0));
}

sub round {
	my ($self,$b,$casas) = @_;
	$casas = defined $casas && $casas >= 0 ? $casas : 2; 
	$b = int(($b + ($b <=> 0)*0.5*(10**(-1*$casas))) * 10 ** $casas) / (10 ** $casas);
	
	return sprintf("%.${casas}f", $b);	
}

sub timeadd_offset {
	my ($time,$offset,$day) = @_;
	return $time if $offset > 23 and $offset < -23;
	my @time = split ':', $time;
	return $time if scalar @time != 3;
	my $hour = int $time[0] + int $offset;
	return $hour > 24 ? 1 : $hour < 0 ? -1 : 0 if $day == 1;
	$hour -= $hour > 24 ? 24 : $hour < 0 ? -24 : 0;
	return join ':', $hour < 10 ? "0$hour" : $hour, $time[1], $time[2];
}
#Criptografia
#Encrypt Decrypt
sub encrypt_mm {
	my $pwd = html(trim(shift));
	#TODO colocar private key nas configuracões
	my @pkey = ([2,1,1],[1,1,1],[2,3,2]);
	my ($i,$j) = (0,0);
	my @code; my $codes;
	
	my @cyph = split(//,$pwd);

	until (scalar @cyph % 3 == 0) {
		push @cyph, '';		
	}

	foreach (@cyph) {
		$j = 0 if $j > 2;		
		$code[$i][$j] = ord($_);
		$i++ if $j == 2;
		$j++;		
	}

	@code = mm(\@code,\@pkey);

	for $i (0 .. (scalar @code - 1)) {
		for $j (0 .. 2) {
			$codes .= $code[$i][$j].":";
		}
	}

	return (trim($codes));
}

sub decrypt_mm {
	my $mkey = trim(shift);
	my $result; my @code;
	#TODO gerar chave reversa se colocar chave privada no conf
	my @rkey = ([1,-1,0],[0,-2,1],[-1,4,-1]);

	my @cyph = split(/:/,$mkey);

	foreach (@cyph) {
		$j = 0 if $j > 2;		
		$code[$i][$j] = $_;
		$i++ if $j == 2;
		$j++;		
	}

	@code = mm(\@code,\@rkey);

	for $i (0 .. (scalar @code - 1)) {
		for $j (0 .. 2) {
			next if $code[$i][$j] == 0;
			$result .= chr($code[$i][$j]);
		}
	}

	return unhtml(trim($result));
}

sub mm {
	my @a = @{$_[0]};
	my @b = @{$_[1]};
	my @code; my @codes;
	my ($i,$j,$k);

#|1 2 3| |1 2 3|   
#|4 5 6| |4 5 6| = |1*1 + 2*4 + 3*7| + |1*2 + 2*5 + 3*8| + |1*3 + 2*6 + 3*9| 
#|7 8 9| |7 8 9|
#
#|30 36 42|
#|66 
#|
	for $i (0 .. (scalar @a - 1)) {
		for $j (0 .. 2) {
			for $k (0 .. 2) {
				$code[$i][$j] += ($a[$i][$k] * $b[$k][$j]);
			}
		}
	}

	return @code;	
}

sub encrypt {
 my $self = shift;
 my $var;
 my $tam;
 my $nvar;

	$var = shift;
	$tam = length($var);
	%cripto = eval($self->setting('crypt'));

	while ($tam) {
		$tmp = substr($var,-($tam),1);
		$tmp = $cripto{$tmp};
		$nvar .= $tmp; 
		$tam--;
	}

	return $nvar;
}

sub decrypt {
 my $self = shift;
 my $var;
 my $tam;
 my $nvar;
 
	$var = shift;
	$tam = length($var);
	return if $tam % 2 ne 0;
	%cripto = reverse(eval($self->setting('crypt')));

	while ($tam) {
		$tmp = substr($var,-($tam),2);
		$tmp = $cripto{$tmp};
		$nvar .= $tmp; 
		$tam-=2;
	}
	
	return $nvar;	
}

sub frmtPotalCode {
	my $cc = shift;
	my $valor = num(shift);
	
	return if $valor == 0;

	if (uc $cc eq 'BR') {
		$valor = substr($valor,0,9);
		$valor = substr($valor,0,2). '.'.substr($valor,2,3).'-'.substr($valor,5,4);
	}

	return $valor;
}

#funcoes especificas
sub DefaultEnterprise {
	my ($self) = shift;
	
	return undef unless $self->uid;
	local $Controller::SWITCH{skip_error} = 1;
	$self->entid($self->user('level') =~ m/^(.+?)(::|$)/);
	return $self->enterprise('nome') ne '' ? $self->entid : undef;	
}	
	
sub UStatusMatch {
	my ($self) = shift;
	my $status;
	my $s = qr/\Q$_[0]/i;
    $status = 'CA' if $self->lang('USER_ACTIVE') =~ m/$s/ && $self->lang('USER_ACTIVE');
	$status = 'CP' if $self->lang('USER_PENDING') =~ m/$s/ && $self->lang('USER_PENDING');
	$status = 'CC' if $self->lang('USER_CANCEL') =~ m/$s/ && $self->lang('USER_CANCEL');
	
	return $status;
}

sub UStatus {
	my ($self) = shift;
	my $status;
	my $s = shift;
    $status = $self->lang('USER_ACTIVE') if $s eq 'CA';
	$status = $self->lang('USER_PENDING') if $s eq 'CP';
	$status = $self->lang('USER_CANCEL') if $s eq 'CC';
	return $status;
}

sub SStatusMatch {
	my ($self) = shift;
	my $status;
	my $s = qr/\Q$_[0]/i;
    $status = $self->SERVICE_STATUS_ATIVO if $self->lang('SERVICE_ACTIVE') =~ m/$s/ && $self->lang('SERVICE_ACTIVE');
	$status = $self->SERVICE_STATUS_BLOQUEADO if $self->lang('SERVICE_SUSPENDED') =~ m/$s/ && $self->lang('SERVICE_SUSPENDED');
	$status = $self->SERVICE_STATUS_CONGELADO if $self->lang('SERVICE_RESELLERHOLD') =~ m/$s/ && $self->lang('SERVICE_RESELLERHOLD');
	$status = $self->SERVICE_STATUS_TRAFEGO if $self->lang('SERVICE_BANDWIDTH') =~ m/$s/ && $self->lang('SERVICE_BANDWIDTH');
	$status = $self->SERVICE_STATUS_ESPACO if $self->lang('SERVICE_SPACE') =~ m/$s/ && $self->lang('SERVICE_SPACE');
	$status = $self->SERVICE_STATUS_SOLICITADO if $self->lang('SERVICE_REQUESTED') =~ m/$s/ && $self->lang('SERVICE_REQUESTED');
	$status = $self->SERVICE_STATUS_CANCELADO if $self->lang('SERVICE_CANCEL') =~ m/$s/ && $self->lang('SERVICE_CANCEL');
	$status = $self->SERVICE_STATUS_FINALIZADO if $self->lang('SERVICE_INACTIVE') =~ m/$s/ && $self->lang('SERVICE_INACTIVE');
	
	return $status;
}

sub SStatus {
	my ($self) = shift;
	my $status;
	my $s = shift;
    $status = $self->lang('SERVICE_ACTIVE') if $s eq $self->SERVICE_STATUS_ATIVO;
	$status = $self->lang('SERVICE_SUSPENDED') if $s eq $self->SERVICE_STATUS_BLOQUEADO;
	$status = $self->lang('SERVICE_RESELLERHOLD') if $s eq $self->SERVICE_STATUS_CONGELADO;
	$status = $self->lang('SERVICE_BANDWIDTH') if $s eq $self->SERVICE_STATUS_TRAFEGO;
	$status = $self->lang('SERVICE_SPACE') if $s eq $self->SERVICE_STATUS_ESPACO;
	$status = $self->lang('SERVICE_REQUESTED') if $s eq $self->SERVICE_STATUS_SOLICITADO;
	$status = $self->lang('SERVICE_CANCEL') if $s eq $self->SERVICE_STATUS_CANCELADO;
	$status = $self->lang('SERVICE_INACTIVE') if $s eq $self->SERVICE_STATUS_FINALIZADO;
	
	return $status;
}

sub SActionMatch {
	my ($self) = shift;
	my $action;
	my $s = qr/\Q$_[0]/i;
    $action = 'C' if $self->lang('CREATE') =~ m/$s/ && $self->lang('CREATE');
	$action = 'M' if $self->lang('MODIFY') =~ m/$s/ && $self->lang('MODIFY');
	$action = 'B' if $self->lang('SUSPEND') =~ m/$s/ && $self->lang('SUSPEND');	
	$action = 'P' if $self->lang('SUSPENDRES') =~ m/$s/ && $self->lang('SUSPENDRES');
	$action = 'R' if $self->lang('REMOVE') =~ m/$s/ && $self->lang('REMOVE');
	$action = 'A' if $self->lang('ACTIVATE') =~ m/$s/ && $self->lang('ACTIVATE');
	$action = 'N' if $self->lang('NOTHINGTODO') =~ m/$s/ && $self->lang('NOTHINGTODO');
	
	return $action;	
}

sub SAction {
	my ($self) = shift;
	my $action;
	my $s = $_[0];
    $action = $self->lang('CREATE') if $s eq 'C';
	$action = $self->lang('MODIFY') if $s eq 'M';
	$action = $self->lang('SUSPEND') if $s eq 'B';	
	$action = $self->lang('SUSPENDRES') if $s eq 'P';
	$action = $self->lang('REMOVE') if $s eq 'R';
	$action = $self->lang('ACTIVATE') if $s eq 'A';
	$action = $self->lang('NOTHINGTODO') if $s eq 'N';

	return $action;	
}

sub Action2Status {
	my ($self) = shift;
	my $status;
	my $s = qr/\Q$_[0]/i;
    $status = $self->SERVICE_STATUS_ATIVO if $self->SERVICE_ACTION_CREATE =~ m/$s/;
    $status = $self->SERVICE_STATUS_ATIVO if $self->SERVICE_ACTION_MODIFY =~ m/$s/;
    $status = $self->SERVICE_STATUS_ATIVO if $self->SERVICE_ACTION_ACTIVATE =~ m/$s/;
    $status = $self->SERVICE_STATUS_BLOQUEADO if $self->SERVICE_ACTION_SUSPEND =~ m/$s/;
	$status = $self->SERVICE_STATUS_CONGELADO if $self->SERVICE_ACTION_SUSPENDRES =~ m/$s/;
	$status = $self->SERVICE_STATUS_FINALIZADO if $self->SERVICE_ACTION_REMOVE =~ m/$s/;
	$status = $self->SERVICE_STATUS_TRAFEGO if $self->SERVICE_ACTION_TRAFEGO =~ m/$s/;
	$status = $self->SERVICE_STATUS_ESPACO if $self->SERVICE_ACTION_ESPACO =~ m/$s/;
	$status = '' if $s =~ 'N';	
	return $status;	
}

sub PriceTypeMatch {
	my ($self) = shift;
	my $status;
	my $s = qr/\Q$_[0]/i;
    $status = 'M' if $self->lang('PLAN_M') =~ m/$s/ && $self->lang('PLAN_M');
	$status = 'A' if $self->lang('PLAN_A') =~ m/$s/ && $self->lang('PLAN_A');
	$status = 'D' if $self->lang('PLAN_D') =~ m/$s/ && $self->lang('PLAN_D');	
	$status = 'U' if $self->lang('PLAN_U') =~ m/$s/ && $self->lang('PLAN_U');
	
	return $status;
}

sub PriceType {
	my ($self) = shift;
	my $status;
	my $s = $_[0];
    $status = $self->lang('PLAN_M') if $s eq 'M';
	$status = $self->lang('PLAN_A') if $s eq 'A';
	$status = $self->lang('PLAN_D') if $s eq 'D';
	$status = $self->lang('PLAN_U') if $s eq 'U';	
	
	return $status;		
}

sub OS {
	my ($self) = shift;
	my $os = shift;
	$os = $self->lang('OS_WINDOWS') if $os eq 'W';
	$os = $self->lang('OS_LINUX') if $os eq 'L';
	
	return $os;
}

sub OSMatch {
	my ($self) = shift;	
	my $os;
	return undef unless $_[0];
	my $s = qr/\Q$_[0]/i;
	
	$os = 'W' if $self->lang('OS_WINDOWS') =~ m/$s/ && $self->lang('OS_WINDOWS');
	$os = 'L' if $self->lang('OS_LINUX') =~ m/$s/ && $self->lang('OS_LINUX');
	$os = '-' if $_[0] eq '-';
	
	return $os;
}

sub CCStatusMatch {
	my ($self) = shift;
	my $status;
	return undef unless $_[0];
	
	my $s = qr/\Q$_[0]/i;
    $status = -1 if $self->lang('CREDITCARD_REFUSED') =~ m/$s/ && $self->lang('CREDITCARD_REFUSED');
	$status = 0 if $self->lang('CREDITCARD_DEACTIVATED') =~ m/$s/ && $self->lang('CREDITCARD_DEACTIVATED');
	$status = 1 if $self->lang('CREDITCARD_ACTIVE') =~ m/$s/ && $self->lang('CREDITCARD_ACTIVE');	
	$status = 2 if $self->lang('CREDITCARD_ACTIVATING') =~ m/$s/ && $self->lang('CREDITCARD_ACTIVATING');
	
	return $status;
}

sub CCStatus {
	my ($self) = shift;
	my $status;
	my $s = $_[0];
    $status = $self->lang('CREDITCARD_REFUSED') if $s == -1;
	$status = $self->lang('CREDITCARD_DEACTIVATED') if $s == 0;
	$status = $self->lang('CREDITCARD_ACTIVE') if $s == 1;
	$status = $self->lang('CREDITCARD_ACTIVATING') if $s == 2;	
	
	return $status;		
}

sub IStatusMatch {
	my ($self) = shift;
	my $status;
	return undef unless $_[0];
	
	my $s = qr/\Q$_[0]/i;
    $status = 'P' if $self->lang('INVOICE_PENDING') =~ m/$s/ && $self->lang('INVOICE_PENDING');
	$status = 'Q' if $self->lang('INVOICE_PAYED') =~ m/$s/ && $self->lang('INVOICE_PAYED');
	$status = 'C' if $self->lang('INVOICE_AWAITING') =~ m/$s/ && $self->lang('INVOICE_AWAITING');	
	$status = 'D' if $self->lang('INVOICE_CANCEL') =~ m/$s/ && $self->lang('INVOICE_CANCEL');
	
	return $status;
}

sub IStatus {
	my ($self) = shift;
	my $status;
	my $s = $_[0];
    $status = $self->lang('INVOICE_PENDING') if $s eq 'P';
	$status = $self->lang('INVOICE_PAYED') if $s eq 'Q';
	$status = $self->lang('INVOICE_AWAITING') if $s eq 'C';
	$status = $self->lang('INVOICE_CANCEL') if $s eq 'D';	
	
	return $status;		
}

sub InstallmentTypeMatch {
	my ($self) = shift;
	my $status;
	return undef unless $_[0];
	
	my $s = qr/\Q$_[0]/i;
    $status = 'S' if $self->lang('STATEMENT_S') =~ m/$s/ && $self->lang('STATEMENT_S');
	$status = 'L' if $self->lang('STATEMENT_L') =~ m/$s/ && $self->lang('STATEMENT_L');
	$status = 'O' if $self->lang('STATEMENT_O') =~ m/$s/ && $self->lang('STATEMENT_O');	
	$status = 'D' if $self->lang('STATEMENT_D') =~ m/$s/ && $self->lang('STATEMENT_D');
	
	return $status;
}

sub InstallmentType {
	my ($self) = shift;
	my $status;
	my $s = $_[0];
    $status = $self->lang('STATEMENT_S') if $s eq 'S';
	$status = $self->lang('STATEMENT_L') if $s eq 'L';
	$status = $self->lang('STATEMENT_O') if $s eq 'O';
	$status = $self->lang('STATEMENT_D') if $s eq 'D';	
	
	return $status;		
}

sub exec_dates {
	my $self = shift;
	return [undef] x 3 if !$self->service('vencimento') && !$self->serviceprop(1);
	
	my @ymd = split '-', $self->calendar('datemysql');
	my $du = $self->date(@ymd)->day_of_week;
	my @ndu = split ',', $self->setting('nonweekdays');
	$du = 0 if grep {$du == $_} @ndu;
	$du = 0 if $self->feriado(@ymd);
	
	my $has_pdias = $self->serviceprop(1) || $self->serviceprop(5);
	my $defer = $self->service('def');
	my $pdias = $self->date(@ymd) - $self->service('inicio') if $self->service('inicio');
	$pdias -= $self->serviceprop(1);
	$pdias -= $self->serviceprop(5); #somente adicional
	$pdias -= $defer;
	$pdias = 0 if (!$self->service('inicio') || ($self->service('pagos') >= 1 && !$self->serviceprop(5)) || (! $has_pdias ) );
	my $dias = $self->date(@ymd) - $self->service('vencimento') if $self->service('inicio');
	$dias -= $defer;
	$dias = 0 unless $self->service('inicio');
	$dias = 0 if $pdias; #zera dias pra cair so nas condicoes de promocao inicial tipo 1
	
	my ($d1,$d2,$d3,$d4,$d5,$d6) = split(/-/,$self->setting('WarnReve'));
	my ($d7,$d8,$d9,$d10) = split(/-/,$self->setting('WarnHosp'));
	my($d11,$d12,$d13,$d14) = split(/-/,$self->setting('WarnDedi'));
 	#defaults
 	$d1 ||= 3; $d2 ||= 5; $d3 ||= 8; $d4 ||= 10; $d5 ||= 15; $d6 ||= 17; #Revenda 
 	$d7 ||= 3; $d8 ||= 5; $d9 ||=10; $d10 ||= 12;#Hospedagem e Adicional
 	$d11 ||= 10; $d12 ||= 12; $d13 ||=20; $d14 ||= 22; #dedicado
 	
 	my $date = $has_pdias ? $self->date(@ymd) - $pdias : $self->date(@ymd) - $dias;
 	if ($_[0] eq 'l') { #Left
 		return ($date + $d1, $date + $d3, $date + d5) if $self->plan('tipo') eq 'Revenda'; 
 		return (undef, $date + $d7, $date + $d9) if $self->plan('tipo') eq 'Hospedagem' || $self->plan('tipo') eq 'Adicional';
 		return (undef, $date + $d11, $date + $d13) if $self->plan('tipo') eq 'Dedicado';
 		return (undef, undef, $self->service('vencimento') - 5) if $self->plan('tipo') eq 'Registro'; 	 
 	} else { #Right	
 		return (undef, $date + $self->setting('promo_dias'), $date + $self->setting('promo_dias_r')) if $has_pdias;
 		return ($date + $d2, $date + $d4, $date + $d6) if $self->plan('tipo') eq 'Revenda'; 
 		return (undef, $date + $d8, $date + $d10) if $self->plan('tipo') eq 'Hospedagem' || $self->plan('tipo') eq 'Adicional';
 		return (undef, $date + $d12, $date + $d14) if $self->plan('tipo') eq 'Dedicado';
 		return (undef) x 3 if $self->plan('tipo') eq 'Registro';
 	}
}	

sub unicode_string {
    join("",
        map { $_ > 127 ?                  # if wide character...
            sprintf("\\%o", $_) :  # \x{...}
            chr($_) =~ /[[:cntrl:]]/ ?  # else if control character...
                sprintf("\\%o", $_) :    # \x..
                chr($_)          # else quoted or as themselves
    } unpack("U*", $_[0]));           # unpack Unicode characters
}

sub getCreditCardType
{
    return "mastercard" if ($_[0] =~ /^5[1-5]/);
    return "visa" if ($_[0] =~ /^4/);
    return "amex" if ($_[0] =~ /^3[47]/);
    return "unknown";
}
1;
__END__
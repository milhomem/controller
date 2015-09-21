#
# XML_Codec
#
#   - Encodes perl data structures into XML representation
#   - Decodes XML into perl data structures
#
# Dependencies:
#   XML:Parser module must be installed
#
# History
#   2000-06-05	vm	First version, based on some routines in XML::Dumper
#   2000-06-16  vm      Fixed xml escaping routine to ignore undefined values
#   2000-06-21  vm      Removed uncessary call to xml_to_data, improving performance


package Controller::Registros::ResellOne::XML_Codec;

use strict;

use vars qw($_SPACER $_CRLF $can_utf8_off);
$_SPACER = " ";		# indent character
$_CRLF = "\n";

use strict;
use vars qw($VAR1 $VERSION);
use XML::Parser;

if ($] >= 5.008) {
    eval {
	require Data::Structure::Util;
	$can_utf8_off = 1;
    };
    if ($@){
	die "You must install Data::Structure::Util for proper UTF8 to byte handling with your version of Perl $]" 
    }
}

$VERSION = '0.2';



use bytes;

#
# sub: new
#
#  - constructor
#

sub new {
    my ($class, %args) = @_;
    my $option = $args{option};
    my $self = {};

    if ( defined($option) )
    {
      if ($option eq 'compress')
      {
        # use compression, turn off all spaces and newlines
#        print "DEBUG--compression on\n";
        $_SPACER = "";
        $_CRLF = "";
      }
    }
    return bless $self,$class;
}

#
# sub: data_to_xml
#
# wrapper for converting data structure to XML
#  - we dont really need this, just calle data_to_xml_string directly!
#


sub data_to_xml
{
    my ($obj,$ref) = @_;
    return $obj->data_to_xml_string($ref);
}


#
# sub: data_to_xml_string
#
# converts a data structure to an string (xml)
#

sub data_to_xml_string {
    my ($obj,$ref) = @_;
    return(
	   $_SPACER x 2 . "<data_block>" .
	   &Tree2XML($ref, 3) .
	   $_CRLF . $_SPACER x 2 . "</data_block>"
	   );
}


#
# sub: Tree2XML
#
# takes a data structure reference and converts it to XML
# representation
#

sub Tree2XML {
    my ($ref, $indent) = @_;
    my $string = '';

    # SCALAR REFERENCE
    if (defined(ref($ref)) && (ref($ref) eq 'SCALAR')) {
	$string .= $_CRLF . $_SPACER x $indent . "<dt_scalarref>" . &quote_XML_chars($$ref) . "</dt_scalarref>";
    } 

    # ARRAY REFERENCE 
    elsif (defined(ref($ref)) && (ref($ref) eq 'ARRAY')) {
	$string .= $_CRLF . $_SPACER x $indent . "<dt_array>";
	$indent++;
        my $j = 0;
	for (my $i=0; $i < @$ref; $i++) {
            # don't encode objects that are DBI thingies because
            # they are useless when decoded because they aren't
            # "magic" anymore (i.e. no connection to DB, etc...)
            if ( ref($ref->[$i]) =~ /^DBI/ )
            {
                next;
            }

	    $string .= $_CRLF . $_SPACER x $indent . "<item key=\"$j\"";
            if ( ! ( ref($ref->[$i]) =~ /^(ARRAY|SCALAR|HASH)$/ ||
                     ref($ref->[$i]) =~ /^$/ ) )
            {
               $string .= " class=\"". ref($ref->[$i]) ."\"";
            }
            $string .= ">";
	    if (ref($ref->[$i])) {
                $string .= &Tree2XML($ref->[$i], $indent+1);
                $string .= $_CRLF . $_SPACER x $indent . "</item>";
	    } else {
		$string .= &quote_XML_chars($ref->[$i]) . "</item>";
	    }
            
            $j++;
	}
	$indent--;
	$string .= $_CRLF . $_SPACER x $indent . "</dt_array>";
    }
    
    # HASH REFERENCE
    # dmanley -- 2000/07/08 -- don't just check for HASH but for
    # non blank too because that will account for object references
    # which are normally hashes anyway.
    #elsif (defined(ref($ref)) && (ref($ref) eq 'HASH')) {
    elsif (defined(ref($ref)) &&
    		( (ref($ref) eq 'HASH') || ref($ref) ne '' )
		) {
	$string .= $_CRLF . $_SPACER x $indent . "<dt_assoc>";
	$indent++;
	foreach my $key (keys(%$ref)) {
            # don't encode objects that are DBI thingies because
            # they are useless when decoded because they aren't
            # "magic" anymore (i.e. no connection to DB, etc...)
            if ( ref($ref->{$key}) =~ /^DBI/ )
            {
                next;
            }

	    $string .= $_CRLF . $_SPACER x $indent . "<item key=\"" . &quote_XML_chars($key) . "\"";
            if ( ! ( ref($ref->{$key}) =~ /^(ARRAY|SCALAR|HASH)$/ ||
                     ref($ref->{$key}) =~ /^$/ ) )
            {
                $string .= " class=\"". ref($ref->{$key}) ."\"";
            }
            $string .= ">";
	    if (ref($ref->{$key})) {
                $string .= &Tree2XML($ref->{$key}, $indent+1);
                $string .= $_CRLF . $_SPACER x $indent . "</item>";
	    } else {
		$string .= &quote_XML_chars($ref->{$key}) . "</item>";
	    }
	}
	$indent--;
	$string .= $_CRLF . $_SPACER x $indent . "</dt_assoc>";
    }

    ## SCALAR
    else {
	$string .= $_CRLF . $_SPACER x $indent . "<dt_scalar>" . &quote_XML_chars($ref) . "</dt_scalar>";
    }
    
    return($string);
}


#
# sub: quote_XML_chars
#
# quote special XML characters
#

sub quote_XML_chars
{
    my $n = shift;
    
    if ( defined ( $n ) ) {
      $n =~ s/&/&amp;/g;
      $n =~ s/</&lt;/g;
      $n =~ s/>/&gt;/g;
      $n =~ s/'/&apos;/g;
      $n =~ s/"/&quot;/g;  
      $n =~ s/([\x80-\xFF])/&UTF8_encode(ord($1))/ge;
      $n =~ s/[\x00-\x08\x0b-\x0c\x0e-\x1f]//sg;

      return($n);
    }
    #if ( defined ( $_[0] ) )
    #{
    #  $_[0] =~ s/&/&amp;/g;
    #  $_[0] =~ s/</&lt;/g;
    #  $_[0] =~ s/>/&gt;/g;
    #  $_[0] =~ s/'/&apos;/g;
    #  $_[0] =~ s/"/&quot;/g;  
    #  $_[0] =~ s/([\x80-\xFF])/&UTF8_encode(ord($1))/ge;
    #  $_[0] =~ s/[\x00-\x08\x0b-\x0c\x0e-\x1f]//sg;

    #  return($_[0]);
    #}
}


# OpenSRS-grown encoder for high-end ASCII encoding.
# Allows encoding of high-end character (128-255) into "@#nnn;" where nnn is
# dec ascii representation.
sub XML_encode{

    my $n = shift;
    return "\@\#$n;";
}



#
# sub: UTF8_encode
#
# convert to UTF8 encoding
# NOTE: Not used at this time.
#

sub UTF8_encode
{
    my $n = shift;

    if ($n < 0x80) {
	return chr ($n);
    } elsif ($n < 0x800) {
        return pack ("CC", (($n >> 6) | 0xc0), (($n & 0x3f) | 0x80));
    } elsif ($n < 0x10000) {
        return pack ("CCC", (($n >> 12) | 0xe0), ((($n >> 6) & 0x3f) | 0x80),
                     (($n & 0x3f) | 0x80));
    } elsif ($n < 0x110000) {
        return pack ("CCCC", (($n >> 18) | 0xf0), ((($n >> 12) & 0x3f) | 0x80),
                     ((($n >> 6) & 0x3f) | 0x80), (($n & 0x3f) | 0x80));
    }
    return $n;
}


sub UTF8_decode
{
    my ($str, $hex) = @_;
    my $len = length ($str);
    my $n;

    if ($len == 2)
    {
        my @n = unpack "C2", $str;
        $n = (($n[0] & 0x3f) << 6) + ($n[1] & 0x3f);
    }
    elsif ($len == 3)
    {
        my @n = unpack "C3", $str;
        $n = (($n[0] & 0x1f) << 12) + (($n[1] & 0x3f) << 6) +
                ($n[2] & 0x3f);
    }
    elsif ($len == 4)
    {
        my @n = unpack "C4", $str;
        $n = (($n[0] & 0x0f) << 18) + (($n[1] & 0x3f) << 12) +
                (($n[2] & 0x3f) << 6) + ($n[3] & 0x3f);
    }
    elsif ($len == 1)   # just to be complete...
    {
        $n = ord ($str);
    }
    else
    {
        die "bad value [$str] for UTF8_decode";
    }
    $hex ? sprintf ("&#x%x;", $n) : chr($n);
}

#
# sub: xml_to_data
#
# accepts and XML parse tree and converts it to a perl data structure
#

sub xml_to_data {
    my ($obj,$tree) = @_;
    
    ## Skip enclosing "data_block" level
    my $TopItem = $tree->[1];
    my $ref = &Undump($TopItem);
    
    return($ref);
}


#
# sub: Undump
#
# Takes a parse tree and recursively
# undumps it to create a data structure in memory.

# The top-level object is a scalar, a reference to a scalar, a hash, or an array.
# Hashes and arrays may themselves contain scalars, or references to
# scalars, or references to hashes or arrays.

# NOTE: One exception is that scalar values are never "undef" because
# there's currently no way to accurately represent undef in the dumped data.
#

sub Undump {
    my ($Tree) = shift;
    my $ref = undef;
    my $FoundScalar;
    my $i;

    for ($i = 1; $i < $#$Tree; $i+=2)
    {
	if (lc($Tree->[$i]) eq 'dt_scalar')
	{
            # process scalar datatype

	    # Make a copy of the string
	    $ref = $Tree->[$i+1]->[2];
	    last;
	}
	
	if (lc($Tree->[$i]) eq 'dt_scalarref')
	{
            # process scalar reference datatype
	
	    # Make a ref to a copy of the string
	    $ref = \ $Tree->[$i+1]->[2];
	    last;
	}
	elsif (lc($Tree->[$i]) eq 'dt_assoc')
	{
            # process associative array (hash) datatype	
	
	    $ref = {};
	    my $j;
	    for ($j = 1; $j < $#{$Tree->[$i+1]}; $j+=2)
	    {
		next unless $Tree->[$i+1]->[$j] eq 'item';
		my $ItemTree = $Tree->[$i+1]->[$j+1];
		next unless defined(my $key = $ItemTree->[0]->{key});
		$ref->{$key} = &Undump($ItemTree);
                if ( exists $ItemTree->[0]->{class} )
                {
                    bless( $ref->{$key}, $ItemTree->[0]->{class} );
                }
	    }
	    last;
	
	}
	elsif (lc($Tree->[$i]) eq 'dt_array')
	{
	    # process array datatype
	
	    $ref = [];
	    my $j;
	    for ($j = 1; $j < $#{$Tree->[$i+1]}; $j+=2)
	    {
		next unless $Tree->[$i+1]->[$j] eq 'item';
		my $ItemTree = $Tree->[$i+1]->[$j+1];
		next unless defined(my $key = $ItemTree->[0]->{key});
		$ref->[$key] = &Undump($ItemTree);
                if ( exists $ItemTree->[0]->{class} )
                {
                    bless( $ref->[$key], $ItemTree->[0]->{class} );
                }
	    }
	    last;
	}
	elsif (lc($Tree->[$i]) eq '0')
	{
            # process scalar datatype
	
	    $FoundScalar = $Tree->[$i + 1] unless defined $FoundScalar;
	}
	else
	{
	    # Unrecognized tag.  Just move on.
	}
    }

    # If $ref is not set at this point, it means we've just
    # encountered a scalar value directly inside the item tag.
    
    $ref = $FoundScalar unless defined($ref);
    if ($ref) {
	$ref =~ s/([\xC0-\xDF].|[\xE0-\xEF]..|[\xF0-\xFF]...)/$1 && &UTF8_decode($1)/egs if $ref;
	if ($can_utf8_off){
	    Data::Structure::Util::_utf8_off($ref);
	}
    }


#    print "-- $ref --";
#    $ref =~ s/(\@\#(\d+))\;/chr($2)/ge;

  done:
    
    return ($ref);
    
}


#
# sub: decode
#
# Accepts and XML protocol string and decodes it into a perl reference
#

sub decode
{
    my ($obj,$tree) = @_;
    return($obj->xml_to_data($tree));
}


#
# sub: encode
#
# Accepts a perl reference and encodes it into an XML protocol string
#

sub encode
{
    my ($obj,$ref) = @_;
    return($obj->data_to_xml_string($ref));
}




1;
__END__


=head1 NAME

XML_Codec - Encoder/Decoder for Perl memory structures to XML

=head1 SYNOPSIS

  use XML_Codec;

  my $xml = new XML_Codec;

  # encode
  $xml_string = $xml->encode($hash_ref);

  # decode
  $hash_ref = $xml->decode($xml_string);


=head1 DESCRIPTION

XML_Coded is a module that encodes perl data structures into
XML representation and decodes the same XML representation into
 perl data structures.

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for XML_Codec. Options are passed as
keyword value pairs. Recognized options are :

=over 4

=item * option

Currently the only recognized option is "compress".  This turns on XML compression by
removing irrelevant whitespace and newline characters.

=back

=item  encode(HASH REF)

This method encodes a hash structure into an XML based representation.  You must
pass a reference to a hash. Any arbitrary data structure is supported (e.g.
a hash or array, or a hash of array of hashes of hashes, and so on.)

The method returns a string.

=over 4

=item example:

example code


=back

=item  decode(STRING)

This method decodes a string which contains an XML representation of a hash
structure (such as that returned by the L<"encode"> method) and turns
it back into a perl hash structure.

The method returns a reference to a hash.

=over 4

=item example:

example code



=back


=head1 AUTHOR

Victor Magdic, Tucows Inc. <vmagdic@tucows.com>

=back

=cut




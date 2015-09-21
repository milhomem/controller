#
# OPS
#
#   - OpenSRS Protocol Suite (OPS) Protocol Translator
#
# Dependencies:
#   XML_Codec module must be installed
#
# History
#   2000-06-06	vm	First version
#   2000-06-12  vm      Updated for action,object calls, fixed version numbering,
#               vm      Added error routine to return error hash
#   2000-06-14  vm      Added msg_id and msg_type header fields
#   2000-06-19  vm      Added error trapping for XML::Parser errors
#   2000-06-20  vm      Fixed bug introduced when added error trapping, which
#                       was causing $ref variable to go out of scope
#   2000-06-21  vm      Improved decoder performance by moving parser and codec
#                       creation to package new(), so only executes once
#                       when object is created
#   2000-07-06  vlad    read_message() and write_message() methods added
#   2000-07-06  vlad    read_data() and write_data() methods added


package Controller::Registros::ResellOne::OPS;
use POSIX qw(:signal_h);
use strict;

use vars qw($_OPS_VERSION $_OPT $_SPACER $_CRLF $_SESSID $_MSGCNT
            $_PARSER $_XML_CODEC );

my $_OPS_VERSION = "0.9";
my $_OPT = "";
my $_SPACER = " ";		# indent character
my $_CRLF = "\n";
my $_MSGTYPE_STD = "standard";
my $CRLF = "\r\n";
my $MAX_POST;

use strict;
use vars qw($VAR1 $VERSION);
use IO::File;
use XML::Parser;
use Data::Dumper;
use Controller::Registros::ResellOne::XML_Codec;

$VERSION = '0.2';


#
# sub: new
#
# Class constructor
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
        $_OPT = 'compress';
        $_SPACER = "";
        $_CRLF = "";

      }
    }

    if ( $args{max_post} and $args{max_post} > 0) {
	$self->set_max_post($args{max_post});
    }

    # create private XML::Parser, so we can reuse it
    $_PARSER = XML::Parser->new(Style=>'Tree');
    $_XML_CODEC = Controller::Registros::ResellOne::XML_Codec->new(option=>$_OPT);

    # create session id for this object, reset message counter
    $_SESSID = rand;
    $_MSGCNT = 0;
    return bless $self,$class;
}


#
# sub: decode
#
# Accepts and OPS protocol message or an IO::File object
# and decodes the data into a perl reference
#

sub decode
{
    my ($obj, $in) = @_;
    my ($ops_msg, $msg_id, $msg_type, $ref);

    # determine if we were passed a string (SCALAR)
    # or a IO::File object (REF)
    if (ref($in) eq 'IO::File')
    {
      # read the file into a string, then process as usual
      $ops_msg = join ('',$in->getlines);  # no hardcoded size limit, not as efficient?
      #$in->read($ops_msg,8192);           # using read buffer, BUT limits size of message
    }
    else
    {
       $ops_msg = $in;
    }

    # if preamble exists, remove it
#    $ops_msg =~ s/(\W*)\s*\?\s*xml.+\?\s*>//i;		# <?xml ... ?>
#    $ops_msg =~ s/(\W*)\s*\!\s*DOCTYPE.+\s*>//i; 	# <!DOCTYPE ... >

    # check for envelope protocol being used

    if ($ENV{OPS_DUMP_XML}){
	warn ("OPS XML : ", $ops_msg);
    }

    if ($ops_msg !~ /\<OPS_envelope\>/)  #(\W*)
    {
      # unsupported envelope, send back error
      return $obj->_ops_error("OPS_ERR","OPS Decode Error: Envelope Protocol Not Supported");
    }
    else
    {
      # extract message type
#      $ops_msg =~ m#\<msg_type\>(.+)\<\/msg_type\>#s; $msg_type=$1;

      # extract message id
#      $ops_msg =~ m#\<msg_id\>(.+)\<\/msg_id\>#s; $msg_id=$1;

      # extract envelope body
      $ops_msg =~ m#\<body\>(.+)\<\/body\>#s; $ops_msg=$1 ;

      # trap errors
      eval
      {
        my $tree = $_PARSER->parse($ops_msg);

        # turn into a perl reference
        $ref = $_XML_CODEC->decode($tree);

        # stuff message id and type into hash
        # $ref->{'_OPS_msg_id'} 	= $msg_id;
        # $ref->{'_OPS_msg_type'} = $msg_type;
      };

      if ( $@ )
      {
        # parser error occured, send back an error code
        return $obj->_ops_error("OPS_ERR","OPS Decode Error: XML Parse Error\n[" . $@ . "]");
      }
      else
      {
        return $ref;
      }

    }
}


#
# sub: encode
#
# Accepts a perl reference and encodes it into an OPS protocol message
#

sub encode
{
    my ($obj,$ref) = @_;
    local $Data::Dumper::Useqq = 1;
    if ($ENV{OPS_DUMP_XML}){
	warn ("OPS Dumper : ", Dumper($ref));
    }

    # create message id and type
    $_MSGCNT++;
    my $msg_id = $_SESSID + $_MSGCNT;    # addition removes the leading zero
#    my $msg_id = $_MSGCNT . $_SESSID;   # marginally faster but less intuitive numbering
    my $msg_type = $_MSGTYPE_STD;

    # normalize certain fields if they exist
    $ref->{'protocol'} = uc($ref->{'protocol'}) if ($ref->{'protocol'});
    $ref->{'action'} = uc($ref->{'action'}) if ($ref->{'action'});
    $ref->{'object'} = uc($ref->{'object'}) if ($ref->{'object'});

    # add action type, which is a superset of the action
#    ($ref->{'action_type'}) = $ref->{'action'} =~ /(\w+)_/ if ($ref->{'action'});
#    ($ref->{'action_type'}) = $ref->{'action'} if ($ref->{'action_type'} eq "");

    # Note: if you want any additional values in the data_block add them
    # to the hash now, before the encoder is called

#    my $xml_codec = new XML_Codec(option=>$_OPT);
#    my $xml_data_block = $xml_codec->encode($ref);
    my $xml_data_block = $_XML_CODEC->encode($ref);
    if ($ENV{OPS_DUMP_XML}){
	warn ("OPS Dumper after encoding: ", Dumper($ref));
    }

    # wrap up data_block and add headers
    my $ops_msg = qq {<?xml version='1.0' encoding="UTF-8" standalone="no" ?>$_CRLF<!DOCTYPE OPS_envelope SYSTEM "ops.dtd">$_CRLF<OPS_envelope>$_CRLF$_SPACER<header>$_CRLF$_SPACER$_SPACER<version>$_OPS_VERSION</version>$_CRLF$_SPACER$_SPACER</header>$_CRLF$_SPACER<body>$_CRLF$xml_data_block$_CRLF$_SPACER</body>$_CRLF</OPS_envelope>};

    return $ops_msg;

}

#
# write_data(): writes a message to a socket ( buffered IO)
#

sub write_data {
	my ( $self, $fh, $msg ) = @_;
	my ( $len );

	$len = length $msg;

	local $SIG{PIPE} = 'IGNORE';

	# write headers
	print $fh "Content-Length: $len", $CRLF, $CRLF;

	# write data
	print $fh $msg;
}

#
# sub: write_message()
#
# Method to write a message to a socket (buffer IO)
#

sub write_message {
	my ( $self, $fh, $hr ) = @_;
	my ( $msg );

	$msg = $self->encode( $hr );
	$self->write_data( $fh, $msg );
}

#
# read_data(): reads data from a socket.
# Returns buffer with data (or undef for a short read)
#

my $too_long = 0;
sub alrm_handler { $too_long = 1 }

sub read_data {
	my ( $self, $fh, $timeout ) = @_;
	my ( $line, $len, $buf, $hr );

	$too_long = 0;
	if ( $timeout ) {
		sigaction SIGALRM, new POSIX::SigAction( 'OPS::alrm_handler' );
		alarm( $timeout );
	}

	while (defined( $line = <$fh>)) {

		last if $too_long;

		# get the length of the data buffer
		if ( not $len and 
		     $line =~ /^\s*Content-Length:\s+(\d+)\s*\r\n/i ) 
		{
		    $len = $1;
		    if ($self->get_max_post() and $len > $self->get_max_post()){
			die 'post_too_long';
		    }
		}

		# wait till the empty line
		next unless $line eq $CRLF;

		read( $fh, $buf, $len) == $len or $buf = undef;
		last;
	}
	alarm(0) if $timeout;
	
	return $buf;
}

#
# sub: read_message()
#
# Method to read message from a socket (buffer IO)
# Returns a reference to a hash
#
# Default timeout on read: 2 seconds
#

sub read_message {
	my ( $self, $fh, $timeout ) = @_;
	my ( $buf );

	$buf = $self->read_data( $fh, $timeout || 2 );
	
	return ( $buf ? $self->decode( $buf ) : undef );
}


#
# sub: _ops_error()
#
# Internal method to generate error code hashes
#

sub _ops_error
{
    my ($obj,$err_code,$err_text) = @_;

    return ( {	response_code=>$err_code,
    		response_text=>$err_text,
    		is_success=>0
              }
        );

}

sub get_max_post {return $MAX_POST}
sub set_max_post {
    my ( $self, $max_post ) = @_;
    if ( $max_post > 0 ) {
	$MAX_POST = $max_post;
    }
}   

1;
__END__

=head1 NAME

OPS - Protocol Translator for the OpenSRS Protocol Suite

=head1 SYNOPSIS

  use OPS;

  my $ops = new OPS;

  # encode
  $ops_msg = $ops->encode($hash_ref);

  # decode
  $hash_ref = $ops->decode($ops_msg);


=head1 DESCRIPTION

OPS is a module that encodes perl data structures into OPS protocol messages,
and also converts OPS protocol messages back into perl data structures.

=head1 METHODS

=over 4

=item new

This is a class method, the constructor for OPS. Options are passed as
keyword value pairs. Recognized options are :

=over 4

=item * option

Currently the only recognized option is "compress".  This turns on OPS protocol
compression by removing irrelevant whitespace and newline characters.

=back

=item  encode(HASH REF)

This method encodes a hash structure into an OPS protocol message.  You must
pass a reference to a hash. Any arbitrary data structure is supported (e.g.
a hash or array, or a hash of array of hashes of hashes, and so on.)

The method returns a string.

=over 4

=item example:

use OPS;
my $ops = new OPS;

# CREATE A REFERENCE TO A HASH
my $ref = {
     protocol=>'RMP',
     action=>'reply',
     response_code=>'200',
     response_text=>'OKAY',
     is_success=>1,
     domain_list=> [ 'ns1.example.com',
		     'ns2.example.com',
	  	     'ns3.example.com'
         	]						],
      } ;

# encode data structure
my $ops_msg = $ops->encode( $ref );


=back

=item  decode(STRING or IO::File object)

This method decodes an OPS protocol message
and turns it into a perl hash structure. This method accepts either an OPS
protocol string, or an IO::File object to the OPS message.

The method returns a reference to a hash.

=over 4

=item example:

use OPS;
my $ops = new OPS;

# $ops_msg is an OPS protocl message received
# from somewhere, now decode it
my $ref = $ops->decode($ops_msg);


=back

=over 4

=item read_data

This method returns a buffer with data an open socket.

=back

=over 4

=item read_message

This method reads a message from an open socket. It returns a hash reference.

=back

=over 4

=item write_data

This method writes a buffer with data to an open socket. It returns true if successul.

=back

=over 4

=item write_message

This method writes a message to an open socket. It takes a hash reference as a parameter and returns true if successul.

=back

=over 4

=item example:

use OPS;
my $ops = new OPS;

...
my $client = $server->accept();

my $request = $ops->read_message( $client );
my $response = { protocol => 'RAP',
				 action => 'reply',
				 response_code => 200,
				 response_text => 'OKAY',
				 is_success => 1
				};
$ops->write_message( $client, $response ) or error( 'can\'t write to socket' );
...

=back

=head1 AUTHOR

Victor Magdic, Tucows Inc. <vmagdic@tucows.com>

=back

=cut
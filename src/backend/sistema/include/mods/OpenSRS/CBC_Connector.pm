#!/usr/bin/perl
#
# $Id: CBC_Connector.pm,v 1.1 2011/06/25 01:24:47 is4web Exp $
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
                                                                                                                                                                                                     
# OpenSRS CBC connection library
                                                                                                                                                                                                     
#######################################################
# **NOTE** This library should not be modified    #####
# Instead, please modify the supplied cgi scripts #####
#######################################################

package OpenSRS::CBC_Connector;

BEGIN {
    if ($] >= 5.008) {
	eval "use Crypt::CBC";
    } else {
	eval "use CBC";
    }
}

use strict;
use IO::Socket;
use Digest::MD5 qw(md5);
use Data::Dumper;
use OPS;

use vars qw($AUTOLOAD);

# start random generator for Crypt::CBC
srand( time() ^ ($$ + ($$ << 15)) );

sub new {

    my $that = shift;
    my $class = ref($that) || $that;
    my %args = @_;

    my $self = {
                _authenticated => 0, # has the user logged in yet?
                _fh => undef,
                _cipher => undef,
                _log_fh => undef,
		_OPS => new OPS(),
                %args, # These would be the hash keys/values
                       # from the config and the extra parameters
                       # for initialization of this package
    };

    if ( exists $args{ xml_logfile } and $args{ xml_logfile } ) {
        require Symbol;
        my $fh = Symbol::gensym();
        open $fh, ">>$args{ xml_logfile }" or
                die "Can't open XML logfile, $args{ xml_logfile } for append: $!";
                                                                                                                                                                                                     
        select $fh;
        $| = 1;
        select STDOUT;
        $self->{ _log_fh } = $fh;
    }

    bless $self, $class;
    return $self;
}

# ------------------------------------------------------------------------
# Clean up before we're destroyed.  undef a few variables to help mod_perl
# along.
sub DESTROY {
    my $self = shift;
    close $self->_log_fh if $self->_log_fh;
}

# ------------------------------------------------------------------------
sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) || die "$self is not an object";
    my $name = $AUTOLOAD;
    my $value;

    $name =~ s/.*://;  # strip packages

    if (@_) {
        $value = shift;
        $self->{$name} = $value;
    }
    return $self->{$name};
}

sub login {
                                                                                                                                                                                                     
    my $self = shift;
    my %args = @_;

    foreach my $key (keys %args) {
        $self->{$key} = $args{$key};
    }

    my $crypt_type = $self->{crypt_type};

    eval {
        require "Crypt/$crypt_type.pm";
    };

    if ($@) {
        print "Content-type:  text/html\n\n";
        die "Couldn't load Crypt::$crypt_type: $@";
    }
}

sub logout {

    my $self = shift;

    #only send the quit command if the socket is open (i.e. defined)
    if ( $self->{_fh}) {
        $self->send_data( {
                action => "quit",
                object => "session",
                } );
    }
    $self->close_socket();
}

sub init_socket {

    my $self = shift;

    return 1 if ($self->{_fh});

    # create a socket
    my $fh = IO::Socket::INET->new(
                   Proto           => "tcp",
                   PeerAddr        => $self->{REMOTE_HOST},
                   PeerPort        => $self->{REMOTE_PORT},
                   );

    return 0 if not defined $fh;

    select($fh);
    $| = 1;
    select(STDOUT);
    $self->{_fh} = $fh;
    return 1;
}

sub close_socket {

    my $self = shift;

    close($self->{_fh}) if $self->{_fh};
    $self->{_cipher} = undef;
    $self->{_authenticated} = 0;
    $self->{_fh} = undef;
}

sub authenticate {

    my $self = shift;
    my ($answer,$prompt);
    my ($challenge, $session_key);
    my ($username,$private_key) = @_;

    if ($self->{_authenticated} == 1) {
        return (is_success => 1)
    }

    my $fh = $self->{_fh};

    if (not $username) {
        return (error => "Missing reseller username");
    } elsif (not $private_key) {
        return (error => "Missing private key");
    }

    $prompt = $self->read_data();

    if (exists $prompt->{response_code} and $prompt->{response_code} == 555 ) {
        # the ip address from which we are connecting is not accepted
        return ( error => $prompt->{response_text} );
    } elsif ( $prompt->{attributes}->{sender} !~ /OpenSRS\sSERVER/ ||
              $prompt->{attributes}->{version} !~ /^(XML|TPP)/ ) 
    {
        return ( error => Dumper(\$prompt)."\nUnrecognized Peer" );
    }

    # first response is server version
    $self->send_data({
            action => "check",
            object => "version",
            attributes => {
                    sender => "OpenSRS CLIENT",
                    version => $self->{version},
                    state => "ready",
                    }
            });

    my $crypt = lc $self->{crypt_type};
    if ($crypt eq 'blowfish_pp') { $crypt = 'blowfish' }
                                                                                                                                                                                                     
    $self->send_data({
            action => "authenticate",
            object => "user",
            attributes => {
                    crypt_type => $crypt,
                    username => $username,
                    }
            } );
                                                                                                                                                                                                     
    # Encrypt the challenge bytes with our password to generate
    # the session key.
    # Respond to the challenge with the MD5 checksum of the challenge.
    # note the use of the no_xml => 1 set, because challenges are
    # are sent without XML (XML::Parser doesn't like decoding
    # binary data)
    $challenge = $self->read_data( no_xml => 1 );

    if ($challenge =~ /is_success/g ) {
        my $buf = $self->{_OPS}->decode( $challenge );
        return (error => $buf->{response_text});
    }
    my $cipher;
    if ($Crypt::CBC::VERSION >= 2.17){
	$cipher = new Crypt::CBC(
	    -key => pack('H*', $private_key),
	    -cipher => $self->{crypt_type},
	    -header => 'randomiv',
	);
    } else {
	$cipher = new Crypt::CBC(pack('H*', $private_key), $self->{crypt_type});
    }

    $self->{_cipher} = $cipher;

    $self->send_data(md5( $challenge ), no_xml => 1);

    # Read the server's response to our login attempt.
    # This is in XML
    $answer = $self->read_data();

    if ($answer->{response_code} =~ /^2/) {
        $self->{_authenticated} = 1;
        return (is_success => 1);
    } else {
        if ($answer->{response_text} eq "No response from server") {
            #if private_key is invalid, then server closes connection
            #without sending any response
            $answer->{response_text}="Invalid private key";
        }
        return (error => $answer->{response_text});
    }
}

sub read_data {

    my $self = shift;
    my %args = @_;

    if ( not defined $self->{_OPS} ) {
        $self->{_OPS} = new OPS();
    }

    # Read the length of this input.
    my $buf = $self->{_OPS}->read_data( $self->{_fh} );

    $buf = ($self->{_cipher}) ? $self->{_cipher}->decrypt($buf) : $buf;

    # if I have a bad public key, that server doesn't response to, so it
    # will be empty buf or if connection died then buf is empty
    if (not $buf) {
        return { is_success => 0,
                 response_text => "No response from server",
                 response_code => 351,
               };
    }

    if ( not $args{no_xml} ) {
        if ( $self->_log_fh ) {
            my $logfh = $self->_log_fh;
            print $logfh scalar( localtime() ) .
                " PID $$ from OpenSRS:\n$buf\n\n";
        }

        $buf = $self->{_OPS}->decode( $buf );
    }
    return $buf;
}

# Sends request to the server.
# XXX Need error checking?
sub send_data {

    my $self = shift;
    my $message = shift; # hash ref or binary data (for challenge)
    my %args = @_;  # other flags
     
    if ( not defined $self->{_OPS} ) {
        $self->{_OPS} = new OPS();
    }

    my $data_to_send;

    if ( not $args{no_xml}) {

        if (not $message->{protocol}) {
            $message->{protocol} = $self->{protocol_name};
        }

        if ($message->{protocol} eq 'TPP' && not $message->{version}) {
            $message->{version} = $self->{protocol_version};
        }

        $data_to_send = $self->{_OPS}->encode( $message );
        # have to lowercase the action and object keys
        # because OPS.pm uppercases them
        $message->{action} = lc $message->{action};
        $message->{object} = lc $message->{object};

        if ( $message->{protocol} eq 'TPP') {
            $message->{requestor} = {
                       username => $self->{username},
                       password => $self->{password},
                       group => 'reseller',  # this is constant for the moment.
                                          # this might change in the future.
            };
        }

        my $logfh = $self->_log_fh;
        print $logfh scalar( localtime() ) .
                        " PID $$ to OpenSRS:\n$data_to_send\n\n" if $logfh;
    } else {
        # no XML encoding
        $data_to_send = $message;
    }

    $data_to_send = $self->{_cipher}->encrypt($data_to_send) if $self->{_cipher};

    return $self->{_OPS}->write_data( $self->{_fh}, $data_to_send );
}

sub encrypt_string {

    my $self = shift;
    my $plain_data = shift;

    my $cipher = new Crypt::CBC(pack('H*', $self->{private_key}), $self->{crypt_type});
    my $crypted_data = $cipher->encrypt($plain_data);
    $crypted_data = unpack("H*",$crypted_data);

    return $crypted_data;
}

sub decrypt_string {

    my $self=shift;
    my $crypted_data = shift;

    $crypted_data = pack("H*",$crypted_data);
    my $cipher = new Crypt::CBC(pack('H*', $self->{private_key}), $self->{crypt_type});
    my $plain_data =  $cipher->decrypt($crypted_data);

    return $plain_data;
}

1;

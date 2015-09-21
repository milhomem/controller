#!/usr/bin/perl
#
# $Id: HTTPS_Connector.pm,v 1.1 2011/06/25 01:24:47 is4web Exp $
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
                                                                                                                                                                                                     
# OpenSRS HTTPS connection library
                                                                                                                                                                                                     
#######################################################
# **NOTE** This library should not be modified    #####
# Instead, please modify the supplied cgi scripts #####
#######################################################
                                                                                                                                                                                                     
package OpenSRS::HTTPS_Connector;

use strict;
use HTTP::Request::Common qw(POST);
use LWP::UserAgent;
use Digest::MD5 qw/md5_hex/;
use IO::Socket::INET;
use Data::Dumper;
use OPS;


use vars qw($AUTOLOAD);

sub new {

    my $that = shift;
    my $class = ref($that) || $that;
    my %args = @_;

    my $self = {
                _buffer => {is_success => 0, response_text => 'No response'},
                _log_fh => undef,
		_OPS => new OPS(),
                _ua => LWP::UserAgent->new,
                %args, # These would be all the other hash keys/values
                       # from the config because you use this as:
                       # $client = new TPP_Client(%OPENSRS) or $client = new XML_Client(%OPENSRS)
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

sub login {}
sub logout {}
sub authenticate { return (is_success => 1); }
sub close_socket {} 
sub init_socket {
                                                                                
    my $self = shift;
    # create a socket to check connectivity
    my $fh = IO::Socket::INET->new(
                   Proto           => "tcp",
                   PeerAddr        => $self->{REMOTE_HOST},
                   PeerPort        => $self->{REMOTE_HTTPS_PORT},
                   );
                                                                                
    return 0 if not defined $fh;
    $fh->close();
    return 1;
}


sub read_data {
    
    my $self = shift;

    my $response = $self->{_buffer};
    $self->{_buffer} = {is_success => 0, response_text => 'No response'};
    return $response;
}

sub send_data{

    my $self = shift;

    my $message = $_[0];

    if ( not defined $self->{_OPS} ) {
        $self->{_OPS} = new OPS();
    }

    if ( not defined $self->{_ua} ) {
        $self->{_ua} = LWP::UserAgent->new;
    }

    if (not $message->{protocol}) {
        $message->{protocol} = $self->{protocol_name};
    }

    if ($message->{protocol} eq 'TPP' && not $message->{version}) {
      $message->{version} = $self->{protocol_version};
    }

    my $xml = $self->{_OPS}->encode($message)."\n";
    my $private_key = $self->{private_key};

    my $signature = md5_hex(md5_hex($xml,$private_key),$private_key);

    my $request = POST (
              'https://'.$self->{REMOTE_HOST}.':'.$self->{REMOTE_HTTPS_PORT},
              'Content-Type' => 'text/xml',
              'X-Username'     => $self->{username},
              'X-Signature'    => $signature,
              'Keep-Alive'  =>'off',
              'Content-Length' => length($xml),
              'Content'      => $xml);

    my $logfh = $self->{_log_fh};
    print $logfh scalar( localtime() ) .
                        " PID $$ to OpenSRS:\n$xml\n\n" if $logfh;

    my $response = $self->{_ua}->request($request);

    if (defined $response and $response->is_success) {
        my $doc = $response->content;

	print $logfh scalar( localtime() ) .
                        " PID $$ from OpenSRS:\n$doc\n\n" if $logfh;

        $self->{_buffer} = $self->{_OPS}->decode($doc);
    } elsif ($logfh) {

	print $logfh scalar( localtime() ) .
                        " PID $$\n", 
			"\tHTTP request: ",Dumper($request),"\n",
			"\tHTTP response:",Dumper($response),"\n";

    }


}

1;

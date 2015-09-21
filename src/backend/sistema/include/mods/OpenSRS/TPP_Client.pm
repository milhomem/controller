#!/usr/bin/perl
#
# $Id: TPP_Client.pm,v 1.1 2011/06/25 01:24:47 is4web Exp $
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

# OpenSRS TPP client library

#######################################################
# **NOTE** This library should not be modified    #####
# Instead, please modify the supplied cgi scripts #####
#######################################################

package OpenSRS::TPP_Client;

use strict;

use OpenSRS::Syntax;
use OpenSRS::NullResponseConverter;
use Data::Dumper;

use vars qw($VERSION $AUTOLOAD $PROTOCOL_NAME $PROTOCOL_VERSION);

$VERSION = "1.4.0";
$PROTOCOL_NAME = 'TPP';
$PROTOCOL_VERSION = '1.4';

sub new {

    my $that = shift;
    my $class = ref($that) || $that;
    my %args = @_;

    my $self = {
		_Connector => undef,
		%args, # These would be all the other hash keys/values
		       # from the config because you use this as:
		       # $client = new TPP_Client(%OPENSRS)
	       };

    $args{version} = $VERSION;
    $args{protocol_name} = $PROTOCOL_NAME;
    $args{protocol_version} = $PROTOCOL_VERSION;

    if ( $self->{connection_type} eq 'HTTPS') {
        eval {
            require "OpenSRS/HTTPS_Connector.pm";
        };
        $self->{_Connector} =
           OpenSRS::HTTPS_Connector->new(%args);
    } elsif ( $self->{connection_type} eq 'CBC') {
        eval {
            require "OpenSRS/CBC_Connector.pm";
        };
        $self->{_Connector} =
           OpenSRS::CBC_Connector->new(%args);
    }
   
    if (not exists $self->{response_converter}) {
	$self->{response_converter} = new OpenSRS::NullResponseConverter();
    }

    bless $self, $class;
    return $self;
}

# ------------------------------------------------------------------------
# Clean up before we're destroyed.  undef a few variables to help mod_perl
# along.

sub DESTROY {
    my $self = shift;
   
    undef $self->{_Connector} if $self->{_Connector};
}

# ------------------------------------------------------------------------

sub AUTOLOAD {
    my $self = shift;
    my $type = ref($self) || die "$self is not an object";
    my $name = $AUTOLOAD;
    my $value;
    
    $name =~ s/.*://;			# strip packages
    
    if (@_) {
	$value = shift;

	$self->{$name} = $value;

    }
    return $self->{$name};
}

sub login {

    my $self = shift;
    $self->{_Connector}->login(@_);
}

sub logout {

    my $self = shift;
    $self->{_Connector}->logout();
}

sub init_socket{
    my $self = shift;
    return $self->{_Connector}->init_socket();
}


####################################################
# send a command to the Tucows OpenSRS server
sub send_cmd {
    my ( $data, $response_code, $response_text, $key );
    my $self = shift;

    my $requestData = shift;
    my $action = $requestData->{action};
    my $object = $requestData->{object};
    
    # prune any private data before sending down to the server
    # (eg. credit card numbers and information
    prune_private_keys( $requestData );

    # make or get the socket filehandle
    if ( not $self->{_Connector}->init_socket() ) {
        $data->{is_success} = 0;
        $data->{response_code} = 400;
        $data->{response_text} = "Unable to establish socket";
        return $data;
    }
    
    # all TPP actions happen here
    my %auth = $self->{_Connector}->authenticate($self->{username}, $self->{private_key});
    if (not $auth{is_success}) {
        $self->{_Connector}->close_socket();
        $data->{is_success} = 0;
        $data->{response_code} = 400;
        $data->{response_text} = "Authentication Error: $auth{error}";
        return $data;
    }

    $requestData->{registrant_ip} = $ENV{REMOTE_ADDR};

    $self->{_Connector}->send_data( $requestData );

    $data = $self->{_Connector}->read_data();

    $self->{response_converter}->convert($data);

    return ($data);

}

sub validate_contacts {
    
    my ($error_msg,@missing_fields,$field,$type, $digit_count);
    my (%problem_fields,$domain);

    my $default_contact = { first_name => "First Name",
			    last_name => "Last Name",
			    org_name => "Organization Name",
			    address1 => "Address1",
			    city => "City",
			    country => "Country",
			    phone => "Phone",
			    email => "E-Mail"
			    };
    
    my %required_contact_fields = ( 
				    default => {
					owner=> $default_contact,
					admin=> $default_contact,
					billing => $default_contact,
					tech => $default_contact,
				    },
                                    email => {
                                        owner => {
                                            first_name => "First Name",
			                    last_name => "Last Name",
			                    address1 => "Address1",
			                    city => "City",
			                    country => "Country",
			                    phone => "Phone",
                                        },
                                    },
				    antispam => {
                                        owner => {
                                            first_name => "First Name",
			                    last_name => "Last Name",
			                    address1 => "Address1",
			                    city => "City",
			                    country => "Country",
			                    phone => "Phone",
					    email => "E-Mail"
                                        },
                                    },
				    wsb => {
                                        owner => {
                                            first_name => "First Name",
			                    last_name => "Last Name",
			                    address1 => "Address1",
			                    city => "City",
			                    country => "Country",
			                    phone => "Phone",
					    email => "E-Mail",
                                        },
                                    },
				    
    );
    
    my %contact_types = ( 
			  default=> {
			      owner => "",
			      admin => "Admin",
			      billing => "Billing",
			  },
                          email => {
                              owner => "Owner",
                          },
			  antispam => {
			      owner => "Owner",
			  },
			  wsb => {
			      owner => "Owner",
			  }
    );
			  


    my $self = shift;

    my $data = shift;
    my %params = @_; 
        
    #cut common contact_types and required_contact_fields to custom_verify
    %contact_types = %{$contact_types{$params{custom_verify}||'default'}};
    %required_contact_fields = %{$required_contact_fields{$params{custom_verify}||'default'}};
    
    if ($params{custom_tech_contact}) {
	$contact_types{tech} = "Tech";
    }
				 
    ####################################
    # check the required fields
    foreach $type (keys %contact_types) {
	foreach $field (keys %{$required_contact_fields{$type}}) {
	    if ($data->{"${type}_$field"} =~ /^\s*$/) {
		push @missing_fields, "$contact_types{$type} $required_contact_fields{$type}{$field}";
	    }
	}

	if ($data->{"${type}_country"} =~ /^(us|ca)$/i and not $data->{"${type}_postal_code"}) {
	    push @missing_fields, "$contact_types{$type} Postal Code";
	}

	if ( $data->{"${type}_country"} =~ /^(us|ca)$/i and not $data->{"${type}_state"}) {
	    push @missing_fields, "$contact_types{$type} State";
	}

	if ( exists $required_contact_fields{$type}{ 'country'} and 
	     $data->{"${type}_country"} !~ /^[a-zA-Z]{2}$/) {
	    $problem_fields{"$contact_types{$type} Country"} = $data->{"${type}_country"};
	}
    
	if ( exists $required_contact_fields{$type}{ 'email'} and
	     not check_email_syntax($data->{"${type}_email"})) {
	    $problem_fields{"$contact_types{$type} Email"} = $data->{"${type}_email"};
	}
        
	if ( exists $required_contact_fields{$type}{ 'phone' } and
	     not OpenSRS::Syntax::PhoneSyntax($data->{"${type}_phone"})) {
	    $problem_fields{"$contact_types{$type} Phone"} = $data->{"${type}_phone"} . " - ERROR";
	}
    }
    
    # these fields must have at least an alpha in them
    foreach $field (keys %$data) {
	if (not $data->{$field}) { next }	# skip blank ones
	
	# Bugzilla bug 32 -- removed alpha check on address[123] fields
	if ($field =~ /first_name|last_name|org_name|city|state/) {
	    if ($data->{$field} !~ /[a-zA-Z]/) {
		$error_msg .= "Field $field must contain at least 1 alpha character.<br>\n";
	    }
	}
    }
    
    # take @missing_fields and add them to $error_msg
    foreach $field (@missing_fields) {
	$error_msg .= "Missing field: $field.<br>\n";
    }
    
    # print error if %problem_fields contains any keys
    if (keys %problem_fields) {
	foreach $field (keys %problem_fields) {
	    # only show problem fields if it had a value.  Otherwise, it 
	    # would have been caught above.
	    if ($problem_fields{$field} =~ /^\s*$/) { next }
	    $error_msg .= "The field \"$field\" contained invalid characters: <i>$problem_fields{$field}</i><br>\n";
	}
    }
    
    # insert other error checking here...
    if ($error_msg) {
	return (error_msg => $error_msg);
    } else {
	return (is_success => 1);
    }
}

########################################################
########################################################
# private routines

sub login_user {
    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $requestor = shift;
	
    my $TPP_create_session = {
	action => 'create',
	object => 'session',
	requestor => {
	    username => $requestor,
        },	
	attributes => {
	    username => $username,
	    password => $password,
	},
    };

    my $result = $self->send_cmd( $TPP_create_session );

    return $result;
}

sub create_user {
    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $requestor = shift;

    my $request = {
	action => 'create',
	object => 'user',
	requestor => {
	    username => $requestor,
	},
	attributes => {
	    group => 'registrants',
	    username => $username,
	    password => $password,
	},
    };
    
    return $self->send_cmd($request);
}

sub get_user_contacts {
    my $self = shift;
    my $user_id = shift;
    my $requestor = shift;

    my $request = {
	action => 'execute',
	object => 'query',
	requestor => {
	    username => $requestor,
        },	
	attributes => {
	    query_name => 'contacts.by_user_id',
	    conditions => [
		{
		    type => 'simple',
		    field => 'user_id',
		    operand => {
			'eq' => $user_id,
		    },
		}
	    ],
	},
    };

    my $result = $self->send_cmd( $request );
    if (not $result->{is_success} or not $result->{attributes}{result}) {
	return undef;
    }

    my %contacts = map {
	# filter out read-only contacts
	$_->{parent_id} ? () : ($_->{contact_id} => $_)
    } @{$result->{attributes}{result}};

    return \%contacts;
}
    
sub get_renewable_items {
    my $self = shift;
    my %args = @_;
    
    my $request = {
	action => 'execute',
	object => 'query',
	requestor => {
	    username => $args{requestor},
        },	
	attributes => {
	    query_name => 'inventory_items.created.by_user_id',
	    conditions => [
		{
		    type => 'simple',
		    field => 'user_id',
		    operand => {
			'eq' => $args{user_id},
		    },
		},
		{
		    type => 'link',
		    link => 'and',
		},
		{
		    type => 'simple',
		    field => 'days_range',
		    operand => {
			'between' => {
			    start => $args{days_before_expiry},
			    end => $args{days_after_expiry},
			},
		    }
		},

		# XXX TODO add optional condition on service type
	    ],
	},
    };


    my $result = $self->send_cmd( $request );

    if (not $result->{is_success} or not $result->{attributes}{result}) {
	return undef;
    }

    return $result->{attributes}{result};
}

sub get_item {
    my $self = shift;
    my %args = @_;
    
    my $request = {
	action => 'execute',
	object => 'query',
	requestor => {
	    username => $args{requestor},
        },	
	attributes => {
	    query_name => 'inventory_item.by_id',
	    conditions => [
		{
		    type => 'simple',
		    field => 'inventory_item_id',
		    operand => {
			'eq' => $args{id},
		    },
		},
	    ],
	},
    };

    my $result = $self->send_cmd( $request );

    if (not $result->{is_success} or not $result->{attributes}{result} or
	    not $result->{attributes}{result}[0]) {
	return undef;
    }

    return $result->{attributes}{result}[0];
}

# NOTE: This function is depricated.
# If you use this function make sure that you use Crypt::CBC module
# and connection_type in the OpenSRS.conf is set to CBC.
sub encrypt_string {

    my $self = shift;
    my $plain_data = shift;

    return $self->{_Connector}->encrypt_string($plain_data);
}

# NOTE: This function is depricated.
# If you use this function make sure that you use Crypt::CBC module
# and connection_type in the OpenSRS.conf is set to CBC.
sub decrypt_string {

    my $self=shift;
    my $crypted_data = shift;

    return $self->{_Connector}->decrypt_string($crypted_data);
}

###############################################################
## helpful tools

sub unencode {
    
    my $text = shift;
    $text =~ tr/+/ /;
    $text =~ s/%([0-9a-fA-F]{2})/pack("c",hex($1))/ge;
    return $text;
}

sub encode {
    
    my $text = shift;
    $text =~ s/([^a-zA-Z0-9_\-.])/uc sprintf("%%%02x",ord($1))/eg;
    
    return $text;
}

sub check_email_syntax {
    
    my $email = shift;
    if ($email =~ /(@.*@)|(\.\.)|(@\.)|(\.@)|(^\.)/ ||
        $email !~ /^\S+\@(\[?)[a-zA-Z0-9\-\.]+\.([a-zA-Z]{2,4}|[0-9]{1,3})(\]?)$/) {
	return undef;
    } else {
	return 1;
    }
}

sub prune_private_keys {

    my $data = shift;
    foreach my $key ( keys %$data ) {
    	if ( $key =~ /^p_/ ) { delete $data->{$key}; }
	elsif ( ref( $data->{$key} ) eq "HASH" )
	    { prune_private_keys( $data->{$key} ); }
    }

}

1;

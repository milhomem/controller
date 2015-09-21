#!/usr/bin/perl
# $Id: XML_Client.pm,v 1.1 2011/06/25 01:24:47 is4web Exp $
#       .Copyright (C)  2000 TUCOWS.com Inc.
#       .Created:       11/19/1999
#       .Contactid:     <admin@vpop.net>
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


# OpenSRS XML client library

#######################################################
# **NOTE** This library should not be modified    #####
# Instead, please modify the supplied cgi scripts #####
#######################################################

package OpenSRS::XML_Client;

use strict;
no strict 'refs';

use OpenSRS::Syntax;
use OpenSRS::Util::America;
use Data::Dumper;

# exported data
my @export = qw(encode unencode check_email_syntax check_domain_syntax
		PERMISSIONS REG_PERIODS TRANSFER_PERIODS UK_REG_PERIODS
		RELATED_TLDS OPENSRS_TLDS_REGEX CA_LEGAL_TYPES NAME_REG_PERIODS
		build_list_from_file trim DE_REG_PERIODS);

use vars qw($VERSION $PROTOCOL_NAME $PROTOCOL_VERSION $AUTOLOAD %PERMISSIONS %REG_PERIODS
             %TRANSFER_PERIODS $RELATED_TLDS $OPENSRS_TLDS_REGEX %UK_REG_PERIODS
             %CA_LEGAL_TYPES $RETRY_DOMAIN_LOOKUP %DE_REG_PERIODS %NAME_REG_PERIODS
);

$VERSION = "XML:2.2.3b";
$PROTOCOL_NAME = 'XCP';
$PROTOCOL_VERSION = '';

# permission defines
%PERMISSIONS = (
		f_modify_owner       => 1,
		f_modify_admin       => 2,
		f_modify_billing     => 4,
		f_modify_tech        => 8,
		f_modify_nameservers => 16,
		f_modify_whois_rsp_info => 32,
		f_modify_domain_extras => 64,
	       );

%REG_PERIODS = (
		1 => "1 Year",
		2 => "2 Years",
		3 => "3 Years",
		4 => "4 Years",
		5 => "5 Years",
		6 => "6 Years",
		7 => "7 Years",
		8 => "8 Years",
		9 => "9 Years",
		10 => "10 Years",
	       );

%UK_REG_PERIODS = (
		2 => "2 Years",
	       );

%NAME_REG_PERIODS = (
		1 => "1 Year",
		2 => "2 Years",
		10 => "10 Years",
               );

%DE_REG_PERIODS = (
		1 => "1 Year",
		);

%TRANSFER_PERIODS = (
		     1 => "1 Year",
		    );

%CA_LEGAL_TYPES = (
    'ABO' => 'Aboriginal Peoples (individuals or groups) indigenous to Canada',
    'ASS' => 'Canadian Unincorporated Association',
    'CCO' => 'Corporation (Canada or Canadian province or territory)',
    'CCT' => 'Canadian citizen',
    'EDU' => 'Canadian Educational Institution',
    'GOV' => 'Government or government entity in Canada',
    'HOP' => 'Canadian Hospital',
    'INB' => 'Indian Band recognized by the Indian Act of Canada',
    'LAM' => 'Canadian Library, Archive or Museum',
    'LGR' => 'Legal Representative of a Canadian Citizen or Permanent Resident',
    'MAJ' => 'Her Majesty the Queen',
    'OMK' => 'Official mark registered in Canada',
    'PLT' => 'Canadian Political Party',
    'PRT' => 'Partnership Registered in Canada',
    'RES' => 'Permanent Resident of Canada',
    'TDM' => 'Trade-mark registered in Canada (by a non-Canadian owner)',
    'TRD' => 'Canadian Trade Union',
    'TRS' => 'Trust established in Canada',
);

# Resend lookup request on communication error
$RETRY_DOMAIN_LOOKUP = 1;

#####################################################

my %opensrs_actions = (
		       get_domain => undef,
		       get_ca_blocker_list_domain => undef,

		       get_userinfo => undef,

		       modify_domain => undef,
		       renew_domain => undef,
		       activate_domain => undef,

		       register_domain => undef,

		       get_nameserver => undef,
		       create_nameserver => undef,
		       modify_nameserver => undef,
		       delete_nameserver => undef,

		       get_subuser => undef,
		       add_subuser => undef,
		       modify_subuser => undef,
		       delete_subuser => undef,
		       
		       change_password => undef,
		       change_ownership => undef,

		       set_cookie => undef,
		       delete_cookie => undef,
		       update_cookie => undef,

		       sw_register_domain => undef,
		       bulk_transfer_domain => undef,
		       register_domain => undef,
		       revoke_domain => undef,
		       
		       lookup_domain => undef,
		       get_price_domain => undef,

		       check_transfer_domain => undef,
		       quit_session => undef,
		       buy_webcert => undef,
		       refund_webcert => undef,	
		       query_webcert => undef,
		       cprefget_webcert => undef,
		       cprefset_webcert => undef,
		       cancel_pending_webcert => undef,
		       update_webcert => undef,

		       send_password_domain => undef,
		       send_password_transfer => undef,
		       send_authcode_domain => undef,
		       send_cira_approval_email=> undef,#CA specific
			
		       query_registrant_ca => undef, #CA specific
		       check_ca_order_status_domain => undef, #CA specific
		       belongs_to_rsp_domain => undef,
		       get_user_access_info_domain => undef, 
		       process_pending_domain => undef,
		       transfer_away_domain => undef,
                       registry_add_ns_nameserver => undef,
		       registry_check_nameserver_nameserver => undef,
		       cira_email_pwd_domain => undef,
		       process_transfer_transfer => undef,
		       cancel_transfer_transfer => undef,
		       get_order_info_domain => undef,
		       query_queued_request_domain => undef,
		       submit_bulk_change => undef,
		       get_domains_by_expiredate_domain => undef,
		       cancel_active_process_domain => undef,
		       advanced_update_nameservers => undef,
		       get_deleted_domains => undef,
		       get_transfers_away => undef,
		      );


sub import {

    my $pkg = shift;
    my $call_pkg = caller();
    my @imports = @_;

    if (@imports) {
	# export necessary symbols
	foreach (@export) {
	    *{"${call_pkg}::$_"} = *{"${pkg}::$_"};
	}
    }
}

sub new {

    my $that = shift;
    my $class = ref($that) || $that;
    my %args = @_;

    my $self = {
		_Connector => undef,
		%args, # These would be all the other hash keys/values
		       # from the config because you use this as:
		       # $client = new XML_Client(%OPENSRS)
	       };

    $args{version} = $VERSION;
    $args{protocol_name} = $PROTOCOL_NAME;
    $args{protocol_version} = $PROTOCOL_VERSION;

    if ($args{LIBPATH}){
	push @INC,$args{LIBPATH};
    }

    if ( $self->{connection_type} eq 'HTTPS') {
        eval {
            require "OpenSRS/HTTPS_Connector.pm";
        };
	if ($@){
	    die "Can't load OpenSRS/HTTPS_Connector.pm. The reason is $@";
	}
        $self->{_Connector} =
           OpenSRS::HTTPS_Connector->new(%args);
    } elsif ( $self->{connection_type} eq 'CBC') {
        eval {
            require "OpenSRS/CBC_Connector.pm";
        };
	if ($@){
	    die "Can't load OpenSRS/CBC_Connector.pm. The reason is $@";
	}
        $self->{_Connector} =
           OpenSRS::CBC_Connector->new(%args);
    }

    $OPENSRS_TLDS_REGEX = $args{OPENSRS_TLDS_REGEX};
    $RELATED_TLDS = $args{RELATED_TLDS};
    
    bless $self, $class;
    return $self;
}

# ------------------------------------------------------------------------
# Clean up before we're destroyed.  undef a few variables to help mod_perl
# along.

sub DESTROY {
    my $self = shift;

    undef $self->{_Connector} if defined $self->{_Connector};
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
    return $self->{_Connector}->init_socket(@_);
}

sub read_data{
    my $self = shift;
    return $self->{_Connector}->read_data(@_);
}

sub send_data{
    my $self = shift;
    return $self->{_Connector}->send_data(@_);
}


sub authenticate{
    my $self = shift;
    return $self->{_Connector}->authenticate(@_);
}

####################################################
# send a command to the OpenSRS server
sub send_cmd {
    my ( $data, $response_code, $response_text, $key );
    my $self = shift;

    my $requestData = shift;
    my $action = $requestData->{action};
    my $object = $requestData->{object};

    # prune any private data before sending down to the server
    # (eg. credit card numbers and information
    prune_private_keys( $requestData );

    if ( not exists $opensrs_actions{lc($action)."_".lc($object)} and 
	 not exists $opensrs_actions{lc($action)} ) {
	warn "Action: ($action), Object: ($object) may not be a valid combination.\n";
    }

    # make or get the socket filehandle
    if ( not $self->{_Connector}->init_socket() ) {
        $data->{is_success} = 0;
        $data->{response_code} = 400;
        $data->{response_text} = "Unable to establish socket";
        return $data;
    }
    
    # all opensrs actions happen here
    my %auth = $self->{_Connector}->authenticate($self->{username},$self->{private_key});
    if (not $auth{is_success}) {
        $self->{_Connector}->close_socket();
        $data->{is_success} = 0;
        $data->{response_code} = 400;
        $data->{response_text} = "Authentication Error: $auth{error}";
        return $data;
    }

    $requestData->{registrant_ip} = $ENV{REMOTE_ADDR};

    if ( $requestData->{action} =~ /lookup/ ) {
    	# lookups are treated specially because XML_Client
	# will automatically lookup related domain names
    	$data = $self->lookup_domain( $requestData );
    } else {
	# send request to server
	$self->{_Connector}->send_data( $requestData );

	$data = $self->{_Connector}->read_data();
    }
    return ($data);

}

sub validate {
    my ($error_msg,@missing_fields,$field,$type, $digit_count);
    my (%problem_fields,$domain);
    my %required_fields = (
			   reg_username => "Username",
			   reg_password => "Password",
			   domain => "Domain",
			  );
    my $self = shift;

    my $data = shift;
    my %params = @_;
    # The primary and secondary nameservers are required.
    if ( $params{custom_nameservers} &&
    	 $data->{reg_type} eq "new" )
    { 
	if (!$data->{fqdn1}) {
	    push @missing_fields, "Primary DNS Hostname";
	}

	if (!$data->{fqdn2}) {       
	    push @missing_fields, "Secondary DNS Hostname"; 
	}
    }
    #############################################################
    # check syntax on several fields
    # check domain

    my @domains = split /\0/, $data->{domain};
    my $syntaxError = undef;
    foreach $domain (@domains) {
	if ($syntaxError = check_domain_syntax($domain)) {
	    $problem_fields{Domain} = $domain . " - " . $syntaxError;
	}
        
        if ( $domain =~ /\.us$/ ) {
            if ( !$data->{app_purpose} ) {
                push @missing_fields, "Domain Name Application Purpose";
            } elsif ( ! exists $OpenSRS::Util::America::america_application_purposes{$data->{app_purpose}} ) {
	        $error_msg .= "Invalid Domain Name Application Purpose: <i>".$data->{app_purpose}."</i><br>\n";
            }
            if ( !$data->{nexus_category} ) {
                push @missing_fields, "Nexus Category of Applicant";
            } elsif ( $data->{nexus_category} =~ /^C3/ && 
                      !$data->{nexus_validator} ) {
                push @missing_fields, "Nexus Validator (Country of Citizenship)";
            } elsif ( ! exists $OpenSRS::Util::America::america_nexus_categories{$data->{nexus_category}} ) {
	        $error_msg .= "Invalid Nexus Category of Applicant: <i>".$data->{nexus_category}."</i><br>\n";
            }
        } elsif ( $domain =~ /\.name$/ && $data->{email_bundle} == 1) {
	    my $email = $domain;
	    $email =~ s/\./@/;
	    if ( !$data->{forwarding_email} ) {
		push @missing_fields, "Forwarding e-mail address";
	    } elsif ( !check_email_syntax($data->{forwarding_email}) ) {
		$error_msg .= "Invalid forwarding E-mail Address: <i>" . $data->{forwarding_email} . "</i><br>\n";
	    } elsif ( $data->{forwarding_email} eq $email) {
		$error_msg .= "Bundled email '$email' cannot point to '".
		    $data->{forwarding_email}."'\n<br>";
	    }
	}
    }
    foreach $field (keys %required_fields) {
	if ($data->{$field} =~ /^\s*$/) {
	    push @missing_fields, $required_fields{$field};
	}
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
    my %result = $self->validate_contacts($data,%params); 
    if (!$result{is_success}) {
        $error_msg .= $result{error_msg};
    }
    
    foreach ( @missing_fields ) {
        $error_msg .= "Missing ".$_."<br>";
    }
    
    # insert other error checking here...
    if ($error_msg) {
	return (error_msg => $error_msg);
    } else {
	return (is_success => 1);
    }
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
				    uk => {
					owner=> $default_contact,
					admin=> {
					    email => "E-Mail",
					    first_name => "First Name",
					    last_name => "Last Name",
					},
					billing=> {
					    email => "E-Mail",
					    first_name => "First Name",
					    last_name => "Last Name",
					},
				    },
				    ca => {
					owner => {
					    org_name=>'Organization Name',
					},
					admin => $default_contact,
					tech => $default_contact,
				    },
				    eu => {
				        owner => $default_contact,	
					tech => $default_contact,
				    },
				    be => {
                                        owner => $default_contact,
                                        tech => $default_contact,
                                    },
				    de => {
					owner=> $default_contact,
					admin => {
					    first_name => "First Name",
					    last_name => "Last Name",
                          		    address1 => "Address1",
                           	 	    city => "City",
                            		    country => "Country",
                            		    phone => "Phone",
                            		    email => "E-Mail",
					},
					billing => {
					    first_name => "First Name",
					    last_name => "Last Name",
					    org_name=>'Organization Name',
                          		    address1 => "Address1",
                           	 	    city => "City",
                            		    country => "Country",
                            		    phone => "Phone",
                            		    email => "E-Mail",
					    fax => "Fax",
					},
					tech => {
					    first_name => "First Name",
					    last_name => "Last Name",
					    org_name=>'Organization Name',
                          		    address1 => "Address1",
                           	 	    city => "City",
                            		    country => "Country",
                            		    phone => "Phone",
                            		    email => "E-Mail",
					    fax => "Fax",
					},
				    },
				    );

    
    my %contact_types = ( 
			  default=> {
			      owner => "Owner",
			      admin => "Admin",
			      billing => "Billing",
			  },
			  ca => {
			      owner => "",
			      admin =>"Admin",
			  },
                          eu => {
                              owner => "Owner",
                          },
                          be => {
                              owner => "Owner",
                          },
			  name => {
			      owner => "",
			      billing => "Billing",
			  },
			  uk => {
			      admin => "Admin",
			  },
			  de => {
			      owner => "Owner",
			      admin => "Admin",
			      billing => "Zone",
			  },

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
	if($data->{reg_type} eq "transfer" and $data->{domain} =~ /\.de/ and $type eq 'owner') {
	    #skip owner for .de transfers
	    next;
	}
	if( !$data->{change_contact} and 
	    $data->{reg_type} eq "transfer" and 
	    $data->{domain} =~ /\.uk/ ){

	    if ( $type eq 'owner' or $type eq 'billing' or $type eq 'tech') {
		#skip owner/billing for .uk transfers
		next;
	    } elsif ( $type eq 'admin' ) {
		if ( $data->{admin_email} =~ /^\s*$/) {
		    push @missing_fields, "Admin E-Mail";
		}
		if ( not check_email_syntax($data->{"${type}_email"} )) {
		    $problem_fields{"Admin Email"} = $data->{"admin_email"};
		}
		next;
	    }
	}
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
        
	if ( $data->{domain} =~ /\.(info|biz|name|us|de)/ ) {
	    if ($data->{"${type}_phone"} !~ /^\+\d{1,3}\.\d{1,12}( *x\d{1,4})?$/){
		# tell the registrant about the bad phone number
		$problem_fields{"$contact_types{$type} Phone"} =
		    $data->{"${type}_phone"}.
			" - ERROR - Format must be +1.4165551212";
	    }
	    if ($data->{"${type}_fax"} ne "" and
		$data->{"${type}_fax"} !~ /^\+\d{1,3}\.\d{1,12}( *x\d{1,4})?$/) {
		# tell the registrant about the bad phone number
		$problem_fields{"$contact_types{$type} Fax"} =
		    $data->{"${type}_fax"}.
			" - ERROR - Format must be +1.4165551212";
	    }
	} else {
	    if ( exists $required_contact_fields{$type}{ 'phone' } and
		 not OpenSRS::Syntax::PhoneSyntax($data->{"${type}_phone"})) {
		$problem_fields{"$contact_types{$type} Phone"} = $data->{"${type}_phone"} . " - ERROR";
	    }
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

sub validate_cert {
    
    my ($error_msg,@missing_fields,$field,$type);
    my (%problem_fields,$domain);

    my %required_fields = (
				   contact => "Contact",
				   owner_org_name => "Organization Name",
				   owner_phone => "Phone Number",
				   owner_email => "E-Mail",
				   quantity_ordered => "Quantity"
				  );
    my $self = shift;
    my $data = shift;
    foreach $field (keys %required_fields) {
	if ($data->{$field} =~ /^\s*$/) {
		push @missing_fields, "$required_fields{$field}";
        }
    }
    if (not check_email_syntax($data->{owner_email})) {
        $problem_fields{owner_email} = $data->{owner_email};
    }
	
    if ($data->{owner_phone} !~ /^\+?[\dx\s\-\.\(\)\#\*]+$/) {
	$problem_fields{owner_phone} = $data->{owner_phone};
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
    if ($data->{quantity_ordered} <=0 || $data->{quantity_ordered} > 100) {
	$error_msg .= "<i>Quantity</i> must be an integer between 1 and 100.<br>\n";
    }
    if ($error_msg) {
	return (error_msg => $error_msg);
    } else {
	return (is_success => 1);
    }
}

########################################################
########################################################
# private routines

sub lookup_domain {
    my $self = shift;
    my $lookupData = shift;
    my ($data, $local_domain, @domains);

    my $domain = lc $lookupData->{attributes}->{domain};
    my $affiliate_id = $lookupData->{attributes}->{affiliate_id};
    
    $domain =~ /(.+)$OPENSRS_TLDS_REGEX$/;
    my ($base, $tld) = ($1, $2);
   
    #BUG 5811       
    if ( length $base < 3 and $tld eq '.org'){
        $data->{is_success} = 0;
        $data->{response_code} = 400;
        $data->{response_text} =
            "Invalid domain syntax for $domain (Domain name too short - Must be at least 7 characters " .
	    "including the \".org\")\n";
        return $data;
    }

    # first, check syntax
    my $syntaxError = check_domain_syntax($domain);
    if ( defined $syntaxError ) {
	$data->{is_success} = 0;
	$data->{response_code} = 400;
	$data->{response_text} =
	    "Invalid domain syntax for $domain ($syntaxError)\n";
	return $data;
    }

    # attempt to find other available matches if requested in conf file
    $domain =~ /(.+)$OPENSRS_TLDS_REGEX$/;
    ($base, $tld) = ($1, $2);
    my $relatedTlds = getRelatedTlds( $tld );
    if ( $self->{lookup_all_tlds} && scalar @$relatedTlds ) {
	@domains = map { "$base".$_ } @$relatedTlds;
    } else {
	@domains = ( $domain );
    }

    foreach $local_domain (@domains) {
	
	$lookupData->{attributes}->{domain} = $local_domain;

	# send request to server and get the response
	$self->{_Connector}->send_data( $lookupData );
	my $answer = $self->{_Connector}->read_data();

	# If RETRY_DOMAIN_LOOKUP is set and if we haven't got an
	# expected $answer, then try to send request once again.
	if ( $RETRY_DOMAIN_LOOKUP and not exists $answer->{attributes} ) {
	    $self->{_Connector}->send_data( $lookupData );
	    $answer = $self->{_Connector}->read_data();
	}

	if ( exists $answer->{attributes}->{status} && 
	     $local_domain !~ /^$domain$/i) {
	    if ($answer->{attributes}->{status} =~ /available/i ){
		if (exists $data->{attributes}->{matches}) {
		    push @{$data->{attributes}->{matches}}, $local_domain;
		} else {
		    $data->{attributes}->{matches} = [ $local_domain ];
		}
	    } else {
		$data->{attributes}->{lookup}->{$local_domain} = 
		    $answer->{attributes};	
	    }
	}

    	# The original domain in the lookup determines
	# the overall return values
	if ($local_domain eq $domain) {
    	    $data->{is_success} = $answer->{is_success};
	    $data->{response_code} = $answer->{response_code};
	    $data->{response_text} = $answer->{response_text};
    	    $data->{attributes}->{status} = $answer->{attributes}->{status};
    	    $data->{attributes}->{reason} = $answer->{attributes}->{reason};
	    $data->{attributes}{price_status} =
		$answer->{attributes}{price_status};
	    $data->{attributes}->{email_available} =
		$answer->{attributes}->{email_available};
	    $data->{attributes}{noservice} = 1 
		if $answer->{attributes}{noservice};
	}
	
    }
    return $data;
}

# NOTE: This function is deprecated.
# If you use this function make sure that you use Crypt::CBC module
# and connection_type in the OpenSRS.conf is set to CBC.
sub crypt_string{

    my $self=shift;
    my $plain_data = shift;
 
    return $self->{_Connector}->encrypt_string($plain_data);
}

# NOTE: This function is deprecated.
# If you use this function make sure that you use Crypt::CBC module
# and connection_type in the OpenSRS.conf is set to CBC.
sub decrypt_string{

    my $self=shift;
    my $encrypted_data = shift;

    return $self->{_Connector}->decrypt_string($encrypted_data);
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

sub trim {
    my $str = shift;
    $str =~ s/^[\s\r\n]*//;
    $str =~ s/[\s\r\n]*$//;
    return $str;
}

sub check_domain_syntax {

    my $domain = lc shift;
    #trim the whitespaces
    $domain = trim($domain);   
    my $MAX_UK_LENGTH = 61;
    my $MAX_NSI_LENGTH = 67;
    my $MAX_NAME_LENGTH = 131;
    my $maxLengthForThisCase = $MAX_NSI_LENGTH;
    $maxLengthForThisCase = $MAX_UK_LENGTH if $domain =~ /\.uk$/i;
    $maxLengthForThisCase = $MAX_NAME_LENGTH if $domain =~ /\.name$/i;    

    my $ca_regex = qr{
	^
	(?:[a-z][-a-z]*[a-z]\.(?=.*\.[a-z]{2}\.ca))?	# municipal portion
	[a-z0-9]                            # 1st char of main can't be '-'
	[-a-z0-9]*
	[a-z0-9]                            # last char of main can't be '-'
	(?:\.[a-z]{2})?			    # optional prov code
	\.ca
	$
    }x;

    if (length $domain > $maxLengthForThisCase) {
	return "Domain name exceeds maximum length for registry ($maxLengthForThisCase)";
    } elsif ($domain !~ /$OPENSRS_TLDS_REGEX$/) {
	return "Top level domain in \"$domain\" is unavailable";
    } elsif ($domain !~ /^[a-z0-9][a-z0-9\-]*\.[a-z0-9][a-z0-9\-]*[a-z0-9]\.name$|^[a-z0-9][a-z0-9\-]{1,}$OPENSRS_TLDS_REGEX$|$ca_regex/) {
        my $tld = "com";
        if ($domain =~ /$OPENSRS_TLDS_REGEX$/) {
            $tld = $1;
	}
	my $message = 'Invalid domain format.  Try something similar to ';
        if ( $domain =~ /name$/ ) { $message .= '"firstname.lastname.name"'; }
        else { $message .= '"yourname'.$tld.'"'; }
        return $message;
    }
    return undef;
}

sub prune_private_keys {

    my $data = shift;
    foreach my $key ( keys %$data ) {
    	if ( $key =~ /^p_/ ) { delete $data->{$key}; }
	elsif ( ref( $data->{$key} ) eq "HASH" )
	    { prune_private_keys( $data->{$key} ); }
    }

}

sub getRelatedTlds {

    my $tld = shift;
    
    # for each array ref in $RELATED_TLDS....
    foreach my $relatedTlds ( @$RELATED_TLDS ) {
    	# ... check each domain...
	foreach my $tldString ( @$relatedTlds )	{
	    if ( $tldString eq $tld ) {
	    	# found the array with a matching TLD,
		# so return that array ref
	    	return $relatedTlds;
	    }
	}
    }

    # No related TLDs were found, so return an empty array ref.
    return [];

}

sub build_list_from_file {
    
    my ($id,$title,$html);
    
    my ($list_file, $default_id) = @_;
    
    #$default_id =~ tr/a-z/A-Z/;
    
    open (FILE, "<$list_file") or die "Can't open $list_file: $!\n";
    while (<FILE>) {
	
	chomp;
	if (/^(\S+)\s+(.+)/) {
	    $id = $1;
	    $title = $2;
	} else {
	    next;
	}
	
	if ($id eq $default_id) {
	    $html .= <<EOF;
<option value="$id" selected>$title
EOF
	} else {
	    $html .= <<EOF;
<option value="$id">$title
EOF
	}
    }
    close(FILE);
    return $html;
}

1;


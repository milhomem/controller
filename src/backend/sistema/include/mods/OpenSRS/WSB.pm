#!/usr/bin/perl
package OpenSRS::WSB;
                                                                                                                                                             
use strict;

use OpenSRS::Util::Common qw(domain_syntax username_syntax password_syntax hostname_syntax ip_syntax email_syntax build_select_menu get_cc_fields verify_cc_info);
use Data::Dumper;
use OpenSRS::TPP_Request;
use Net::FTP;
use Date::Calc qw(check_date Mktime);
use vars qw(@ISA);
@ISA = qw(OpenSRS::TPP_Request);

use constant ERROR_M001 => 'Empty domain name.';
use constant ERROR_M002 => 'Empty username.';
use constant ERROR_M003 => 'Empty password.';
use constant ERROR_M005 => 'Empty confirm password.';
use constant ERROR_M100 => 'Error retrieving information.';
use constant ERROR_M140 => 'Password and confirm password do not match.';
use constant ERROR_M150 => 'Username is already taken.  Please enter another username.';
use constant ERROR_M170 => 'User does not exist.';
use constant ERROR_M200 => 'Username and/or password not found.';


# Success: return undef
# Failure: return error message
sub test_ftp_settings {

    my $self = shift;
    my $ftp_settings = shift;
    my ( $ftp, $message);
    
    my $validate_passwd = 1;
    my $validation_error = $self->validate_ftp_settings($ftp_settings, $validate_passwd); 
    
    return $validation_error if $validation_error; 
                                                                                                                                                                                                                                                                                                                          
    if ( not $ftp = Net::FTP->new( "$ftp_settings->{ftp_server}:$ftp_settings->{ftp_port}", Passive => 1, Debug => 1 ) ) {
	return "Cannot Connect to FTP: address [$ftp_settings->{ftp_server}:$ftp_settings->{ftp_port}] is invalid.";
    }   
                                                                                                                                                             
    if ( not $ftp->login( $ftp_settings->{ftp_username}, $ftp_settings->{ftp_password}) ) {
        $message = $ftp->message;
        $ftp->quit; 
	return "Cannot login to FTP: [$message].";
    }

    if ( not $ftp->cwd( $ftp_settings->{ftp_default_directory}) ) {        
        $message = $ftp->message;
        $ftp->quit; 
        return $message;
    } 
                                                                                                                                                             
    $ftp->binary();
                                                                                                                                                             
    $ftp->quit;
}

# Success: return undef
# Failure: return error message
sub validate_ftp_settings {

    my $self = shift;
    my $ftp_settings = shift;    
    my $error;

    return "Empty FTP settings" if not $ftp_settings;
    
    $error .= "Empty FTP username; "
    	if not $ftp_settings->{ftp_username};    
	
    $error .= "Empty FTP password; "
    	if not $ftp_settings->{ftp_password};   
	
    $error .= "FTP password and confirm password are different; "
    	if $ftp_settings->{ftp_password} ne $ftp_settings->{ftp_confirm_password};   
    
    $error .= "Invalid FTP hostname; "
    	if not $self->check_hostname_syntax($ftp_settings->{ftp_server});
		
    $error .=  "Invalid FTP port; "
    	if not $self->check_port_syntax($ftp_settings->{ftp_port});

    $error .=  "Invalid FTP directory; "
    	if $ftp_settings->{ftp_default_directory} and 
		not $self->check_directory_syntax($ftp_settings->{ftp_default_directory});
	
    $error .=  "Empty FTP index file; "
    	if not $ftp_settings->{ftp_index_filename};
	
    return $error;
}

sub recover_rwi2_password {
    
    my $self = shift;
    my $username = shift;
    
    return $self->error_exit(ERROR_M002) if not $username;

    my $result = $self->tpp_recover_password($username);
   
    return $result;
}


# Login user, authenticating with usrname and password.
sub login_user {

    my $self = shift;
    my $username = shift;
    my $password = shift;
    my ($result, $error);
    
    $error  = ERROR_M002 if not $username;
    $error .= ERROR_M003 if not $password;
    
    if ( $error ) {
        $result->{response_text} = $error;
        return $result;
    }
    return $result = $self->tpp_login_user($username, $password); 
} 

sub create_user {

    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $confirm_password = shift;
    
    return $self->error_exit(ERROR_M003) if not $password;
    return $self->error_exit(ERROR_M140) if $confirm_password ne $password;
    
    my $res = username_syntax($username);
    return $self->error_exit($res) if $res;
    
    $res = password_syntax($password);
    return $self->error_exit($res) if $res;    
    
    my $result = $self->tpp_create_user($username, $password);
    
    if ($result->{is_success}) {
        return $result;
    } elsif ($result->{response_code} eq '4103' ) {
       return $self->error_exit(ERROR_M150);
    }
    
    return $self->error_exit($result->{response_text});
}

sub check_rwi2_user {

    my $self = shift;
    my $attributes = shift;
    
    return $self->tpp_check_rwi2_user($attributes);
}

sub delete_rwi2_user {

    my $self = shift;
    my $rwi2_user_id = shift;
    
    return $self->tpp_delete_rwi2_user($rwi2_user_id);
}


# QUERIES
sub query_inv_items_created_by_user_id {
    
    my $self = shift;
    my $data = shift;

    $data->{service} = 'wsb';
    
    my $result = $self->tpp_query_inv_items_created_by_user_id( $data );

    return $result;
}


sub query_contact_by_id {

    my $self = shift;
    my $contact_id = shift;
    
    my %data = ( contact_id => $contact_id);
    my $result = $self->tpp_query_contact_by_id( \%data );

    return $result;
}



sub query_inv_item_by_description {

    my $self = shift;
    my $description = shift;
    
    my %data = ( description => $description, service => 'wsb');
    my $result = $self->tpp_query_inv_item_by_description( \%data );

    return $result;
}


sub query_inv_item_by_id {

    my $self = shift;
    my $inventory_item_id = shift;
    
    my %data = (inventory_item_id => $inventory_item_id);
    my $result = $self->tpp_query_inv_item_by_id( \%data );

    return $result;
}

# SUBSYSTEM SUBROUTINES
sub recover_wsb_password {
    
    my $self = shift;
    my $account_username = shift;
    
    return $self->error_exit(ERROR_M002) if not $account_username;
    
    my $product_data = {
        account_username => $account_username,
    };
    
    my $attributes = {
        service => 'wsb',
	product_data => $product_data,    
    };
    
    my $data = {
        attributes => $attributes,
	action => 'manage',
	object => 'wsb.send_end_user_password',
    };


    my $result = $self->tpp_process_order($data);
 
    return $result;
}

sub validate_wsb_account {
    
    my $self = shift;
    my $account_username = shift;
    my $account_password = shift;
    
    return $self->error_exit(ERROR_M002) if not $account_username;
    return $self->error_exit(ERROR_M003) if not $account_password;
    
    
    my $product_data = {
        account_username => $account_username,
	account_password => $account_password,
    };
    
    my $attributes = {
        service => 'wsb',
	product_data => $product_data,    
    };
    
    my $data = {
        attributes => $attributes,
	action => 'manage',
	object => 'wsb.validate_account_login',
    };


    my $result = $self->tpp_process_order($data);
 
    return $result;
}

sub get_account_password {

    my $self = shift;
    my $account_username = shift;


    my $product_data = {
        account_username => $account_username,
    };
    
    my $attributes = {
        service => 'wsb',
	product_data => $product_data,    
    };
    
    my $data =  {
        action => 'check', 
    	object => 'wsb.account_password', 
	attributes => $attributes
    };
    
    return $self->tpp_process_order($data);
}

sub get_lost_password_email {

    my $self = shift;
    my $account_username = shift;

    my $product_data = {
        account_username => $account_username,
    };
    
    my $attributes = {
        service => 'wsb',
	product_data => $product_data,    
    };
    
    my $data =  {
        action => 'check', 
    	object => 'wsb.lost_password_email', 
	attributes => $attributes
    };

    my $result = $self->tpp_process_order($data);
}

sub update_lost_password_email {

    my $self = shift;
    my $account_username = shift;
    my $lost_password_email = shift;
    
    my $product_data = {
        account_username => $account_username,
	email => $lost_password_email,   
    };
    
    my $attributes = {
        service => 'wsb',
	product_data => $product_data, 
    };
    
    my $data =  {
        action => 'manage', 
    	object => 'wsb.set_email_forgot_password', 
	attributes => $attributes
    };
    
    my $result = $self->tpp_process_order($data);
}

sub get_product_price {

    my $self = shift;
    my $package_name = shift;
    my $orderitem_type = shift;
    my $inventory_item_id = shift;
    
    
    my $product_data = {
        package_name => $package_name,
	($orderitem_type eq 'modcontract') ? (mc_action => 'upgrade') : (),
    };
    
    my @check_items = ({
        inventory_item_id => $inventory_item_id,
        service => 'wsb',
	product_data => $product_data,
	orderitem_type => $orderitem_type,
	object_type => 'account',
    
    });
    
    my $attributes = {
        check_items => \@check_items,
    
    };
    
    my $data =  {
        action => 'check', 
    	object => 'price', 
	attributes => $attributes
    };
        
    my $result = $self->tpp_process_order( $data );

    return $result;

}

# TPP SUBROUTINES
sub update_rwi2_user {

    my $self = shift;
    my $attributes = shift;
    
    my $data = {
        attributes => $attributes,
	action => 'update',
	object => 'user',
    };
    
    return $self->tpp_process_order($data);
}

sub update_contacts {

    my $self = shift;
    my $attributes = shift;
    
    my $data = {
        attributes => $attributes,
	action => 'update',
	object => 'contact',
    };
    
    return $self->tpp_process_order($data);

}

sub update_inventory_item {

    my $self = shift;
    my $attributes = shift;
    
    my $data = {
        attributes => $attributes,
	action => 'update',
	object => 'inventory_item',
    };
    
    return $self->tpp_process_order($data);

}

sub create_order {

    my $self = shift;
    my $attributes = shift;
        
    my $data = {
        attributes => $attributes,
	action => 'create',
	object => 'order',
    };
    
    return $self->tpp_process_order($data);
}


sub validate_expiry_info {
                                                                                                                                                             
    my ($self, $data) = @_;
                                                                                                                                                             
    if ( time >= Mktime($data->{exp_year}, $data->{exp_month}, $data->{exp_day}, 0, 0, 0 )) {
        return 'You must enter a date that is at least one day into the future. Correct the date and try again.'
    }
                                                                                                                                                             
    if ( not check_date($data->{exp_year},$data->{exp_month},$data->{exp_day}) ) {
        return "Invalid date.";
    }
}



sub validate_contacts {

    my $self = shift;
    my $contact_data = shift;
    my $val_contact_data; 
    
    map {
        $val_contact_data->{'owner_'.$_} = $contact_data->{$_};    
    } keys %{$contact_data};
    
    my $result = $self->tpp_validate_contacts( $val_contact_data, custom_verify => 'wsb' );
    
    return $result->{error_msg} if $result->{error_msg};
}


# validate domain name
sub check_domain_syntax {
    
    my $self = shift;
    my $domain = shift;

    return ERROR_M001 if not $domain;
    
    my $res = domain_syntax($domain);
    
    return $res;
}


sub check_username_syntax {

    my $self = shift;
    my $user = shift;
    my $username = shift;
    
    return ERROR_M002 if not $username;
    return ($user eq 'wsb' ? check_wsb_username_syntax($username) : check_rwi2_username_syntax($username) );    

}

sub check_rwi2_username_syntax {

    my $username = shift;
 
    my $res = username_syntax($username);
    
    return $res;
}

sub check_wsb_username_syntax {

    my $username = shift;
    
    return 'Invalid username length: must be at least 1 and at most 100.' 
    	if length $username < 1 or length $username > 100;
    
    return 'Invalid username syntax: spaces,\,",{,},<,> are not allowed.' 
    	if $username =~ /\\"\{\}<>\s+/g;
}


sub check_password_syntax {

    my $self = shift;
    my $user = shift;
    my $password = shift;
    my $confirm_password = shift;
    
    return ERROR_M140 if $password ne $confirm_password;    
    return ERROR_M003 if not $password;
    
    return ($user eq 'wsb' ? check_wsb_user_password($password) : check_rwi2_user_password($password) ); 	
}

# Return error message if error, nothing if success.
sub check_rwi2_user_password {

    my $password = shift;
    
    my $res = password_syntax($password);
    
    return $res;
}

# Return error message if error, nothing if success.
sub check_wsb_user_password {

    my $password = shift;
    
    return 'Invalid username length: must be at least 1 and at most 20.' 
    	if length $password < 1 or length $password > 20;
    
    return 'Invalid password syntax: spaces,\,",{,},<,> are not allowed.' 
    	if $password =~ /\\"\{\}<>\s+/g;
}

# return 1 if no errror, undef if error.
sub check_email_syntax {
    
    my $self = shift;
    my $email = shift;

    return email_syntax($email);
}

# return 1 if no errror, undef if error.
sub check_hostname_syntax {
    
    my $self = shift;
    my $hostname = shift;

    return hostname_syntax($hostname);
}

# return 1 if no errror, undef if error.
sub check_port_syntax {
    
    my $self = shift;
    my $port = shift;
 
    return ($port =~ /^\d+$/);
}

# return 1 if no errror, undef if error.
sub check_directory_syntax {
    
    my $self = shift;
    my $path = shift;
    
    return ($path =~ /^\// and $path !~ /\/$/)
}

sub check_preference_syntax {
    
    my $self = shift;
    my $preference = shift;
 
    return ($preference =~ /^\d+$/);
}

sub cc_fields {
    
    my $self = shift;
    return get_cc_fields(@_);
}


sub verify_cc_fields {

    my $self = shift;
        
    my $error = verify_cc_info(@_);
    return $self->error_exit($error) if $error;
    
    return { is_success => 1 };


}
   
1;

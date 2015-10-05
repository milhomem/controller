#!/usr/bin/perl
package OpenSRS::EmailDefense;
                                                                                                                                                             
use strict;

use OpenSRS::EmailDefense_errors;
use OpenSRS::Util::Common qw(domain_syntax username_syntax password_syntax hostname_syntax ip_syntax build_select_menu get_cc_fields verify_cc_info);
#use OpenSRS::Util::Common qw(default);
use Data::Dumper;
use OpenSRS::TPP_Request;
use vars qw(@ISA);
@ISA = qw(OpenSRS::TPP_Request);

# First check domain for availability.
# If it is available, return success.
# If it is taken, check that
sub check_domain {

    my $self = shift;
    my $domain_name = shift;

    return $self->error_exit(ERROR_M001) if not $domain_name;

    my $result = $self->check_domain_syntax($domain_name);

    return $result if not $result->{is_success};
    
    # check domain availability.
    $result = $self->tpp_check_emaildefense_domain($domain_name);

    return $self->error_exit($result->{response_text}) if not $result->{is_success};

    # if domain is available, return response.
    if ($result->{attributes}{product_data}{is_available}) {

	return { is_success => 1,
	         available => 1, 
	       };
    # if domain is taken, retrieve info of it's accounts.
    } else {

        $result = $self->tpp_get_domain_info($domain_name);

	if ($result->{is_success} and $result->{attributes}{result_control}{record_count}) {
            return $result;
    	} 
    }        
   
    return $self->error_exit(ERROR_M110);
}


sub recover_password {
    
    my $self = shift;
    my $username = shift;
    
    return $self->error_exit(ERROR_M002) if not $username;

    my $result = $self->tpp_recover_password($username);
 
    if ($result->{is_success}) {
	return { is_success => 1 };
    } elsif ($result->{response_code} eq '3002' ) {
       return $self->error_exit(ERROR_M170);
    }   
   
    return $self->error_exit(ERROR_M100);
}

# Login user, authenticating with usrname and password
# and cheking that the user logged in is the same as the one
# managing domain.
sub login_domain_user {
    
    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $user_id = shift;    

    my $result = $self->login_user($username,$password);
    
    if ( $result->{is_success} ) {
        if ( $result->{attributes}{user_id} == $user_id ) {
	    return $result;
	} else {
	    return $self->error_exit(ERROR_M004);
	}	
    } else {
        return $result;
    }
}

# Login user, authenticating with usrname and password.
sub login_user {

    my $self = shift;
    my $username = shift;
    my $password = shift;
    
    return $self->error_exit(ERROR_M002) if not $username;
    return $self->error_exit(ERROR_M003) if not $password;
    
    my $result = $self->tpp_login_user($username, $password);    
     
    if ( $result->{is_success} ) {
	return $result;
    } else {
        if ($result->{response_code} eq '4108' ) {
            return $self->error_exit(ERROR_M200);
	}
	return $self->error_exit(ERROR_M100);
    }
} 

sub create_user {

    my $self = shift;
    my $username = shift;
    my $password = shift;
    my $confirm_password = shift;
    
    return $self->error_exit(ERROR_M005) if not $confirm_password;
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
    
    return $self->error_exit(ERROR_M100);
}

sub check_username_syntax {

    my $self = shift;
    my $username = shift;
    
    return $self->error_exit(ERROR_M002) if not $username;
    
    my $res = username_syntax($username);
    
    return $self->error_exit($res) if $res;
    return { is_success => 1 };
}

sub check_password_syntax {

    my $self = shift;
    my $password = shift;
    
    return $self->error_exit(ERROR_M003) if not $password;
    
    my $res = password_syntax($password);
    
    return $self->error_exit($res) if $res;
    return { is_success => 1 };
}

#validate domain name
sub check_domain_syntax {
    
    my $self = shift;
    my $domain = shift;

    return $self->error_exit(ERROR_M001) if not $domain;
    
    my $res = domain_syntax($domain);
    
    return $self->error_exit($res) if $res;
    return { is_success => 1 };
}

sub check_hostname_syntax {
    
    my $self = shift;
    my $hostname = shift;

    return hostname_syntax($hostname);
}

sub check_port_syntax {
    
    my $self = shift;
    my $port = shift;
 
    return ($port =~ /^\d+$/);
}

sub check_preference_syntax {
    
    my $self = shift;
    my $preference = shift;
 
    return ($preference =~ /^\d+$/);
}

# Return all contacts of the quering user.
sub get_contacts_by_user_id {

    my $self = shift;
    my $user_id = shift;
    
    return $self->tpp_get_contacts_by_user_id($user_id);
}


sub check_edef_user_password {

    my $self = shift;
    my $passwd_assgnmt = shift;
    my $password = shift;
    my $confirm_password = shift;

    return $self->error_exit(ERROR_M140) if $password ne $confirm_password;
    
    # Password is mandatory only if account is to be added now,
    # not via quarantine report.
    if ( $passwd_assgnmt eq 'now' ) {
	return $self->error_exit(ERROR_M003) if not $password;	
	return $self->error_exit(ERROR_M006) if length $password < 6;	
    }
    
    return { is_success => 1 };
}
   
# Return all domains that belong to the user and have antispam service.
sub get_antispam_domains_by_user {
    
    my ($self, $data) = @_; 
    
    my $result = $self->tpp_get_antispam_domains_by_user($data);

    return $result if $result->{is_success};

    return $self->error_exit(ERROR_M170) if $result->{response_code} eq '4108';
   
    return $self->error_exit(ERROR_M100);
}

# Return general info on the domain.
sub get_domain_info {

    my $self = shift;
    my $domain = shift;
    
    return $self->tpp_get_domain_info($domain);
}

# Return all accounts that belong to the domain together with info on them.
sub get_domain_accounts_info {

    my $self = shift;
    my $inventory_item_id = shift;
        
    return $self->tpp_get_inventory_item_by_id($inventory_item_id);
}


# Get accounts that already exist on the domain and 
# error out if user wants to remove some accounts that don't exist on the domain.
sub check_remove_user_accounts {

    my $self = shift;    
    my $result = $self->check_user_accounts(@_, 'remove');
    
    return $self->error_exit($result->{error}) if $result->{error};
    
    return $result;
}

# Get accounts that already exist on the domain and 
# error out if user wants to add some of them again.
sub check_add_user_accounts {

    my $self = shift;
    my $result = $self->check_user_accounts(@_, 'add');
    
    return $self->error_exit($result->{error}) if $result->{error};
    
    return $result;
}

sub check_user_accounts {
    
    my ( $self, $max_users, $mod_user_accounts_string, $old_user_accounts_string, $action_type ) = @_;
    my ( $error, $account );
        
    return $self->error_exit(ERROR_M007) if not scalar @{$mod_user_accounts_string};   
    
    return $self->error_exit("<br>The maximum number of Email Defense Users you can enter is $max_users.")
	if scalar @{$mod_user_accounts_string} > $max_users;
    
    foreach $account ( @{$mod_user_accounts_string} ) {
        return $self->error_exit(ERROR_M008) if ( (grep /^$account$/, @{$mod_user_accounts_string}) > 1 );    
    }
    
    if ( $old_user_accounts_string ) {    
        map {  
            $account = $_;
            if ( $action_type eq 'add' ) { $error.= "$account<br>" if grep /^$account$/, @{$old_user_accounts_string} };
	    if ( $action_type eq 'remove') { $error.= "$account<br>" if not grep /^$account$/, @{$old_user_accounts_string} };
        } @{$mod_user_accounts_string};
    
        my $word = ( $action_type eq 'add') ? 'already' : 'do not';
        $error = "Following users $word exist on the domain:<br>$error" if $error;
            
        return $self->error_exit($error) if $error;
    }
    
    return { is_success => 1 };
}



# Here we need to decide which acounts should be included in the added accounts.
# We get a string that has all accounts (newly selected and left from previous select before edit) 
# and select only newly selected and accounts from previous select that were selected again.
# Accounts that were selected before and didn't make it into the new select are pruned out.
sub get_edit_user_accounts {

    my $self = shift;
    my $all_user_accounts_string = shift;
    my $old_user_accounts = shift;
    
    my ($error, $account);
    
    my @new_user_accounts_string = ();
    my @old_user_accounts_string = ();
    my @remaining_user_accounts = ();
    my @result_user_accounts_string = ();
    
    # make an array of names from old user accounts obj.
    map {  
	push  @old_user_accounts_string, $_->{user_account};
    } @{$old_user_accounts};

    # prune out only newly selected accounts from all accounts.
    map {  
       $account = $_; 
       push @new_user_accounts_string, $account if not grep /^$account$/, @old_user_accounts_string;
    } @{$all_user_accounts_string};
    
    # prune out previously selected accounts that made it into the new selection.
    map {  
       $account = $_; 
       push @remaining_user_accounts, $account if grep /^$account->{user_account}$/, @{$all_user_accounts_string};
    } @{$old_user_accounts};
    
    # return newly selected and previouly selected but still in the selection as separate entries.
    return { is_success => 1,
    	     user_accounts_new_added_string => \@new_user_accounts_string,
	     user_accounts_remaining_string => \@remaining_user_accounts,
	   };
}

sub validate_contacts {

    my $self = shift;
    my $contact_data = shift; 
    
    my $result = $self->tpp_validate_contacts( $contact_data, custom_verify => 'antispam' );
    
    return $self->error_exit($result->{error_msg}) if $result->{error_msg};
    return $result;
}



sub process_new_purchase_order {

    my $self = shift;  
    my $handling = shift;  
    my $order_info = shift; 
     
       
    my (@key, @value, %new_order_info, @create_items);
        
    my @contacts = ();
    my %contact_data = ();

    map { @key=keys %{$_}; 
    	  @value=values %{$_}; 
    	  $contact_data{$key[0]} = $value[0];
    } @{$order_info->{admin_contacts}};

    push @contacts, \%contact_data;

    my $product_data = {
        domain => $order_info->{domain_name},
        feature_set => $order_info->{feature_set},
        mtas => $order_info->{mtas},
        accounts => $order_info->{create_items},
    };
                                                                                                                                                             
    #this points to the contact array above
    my $contact_set = { owner => 0, };
                                                                                                                                                             
    push @create_items, {
        orderitem_type => 'new',
        product_data => $product_data,
        contact_set => $contact_set,
    };
    
    $new_order_info{user_id} = $order_info->{user_id};
    $new_order_info{create_items} = \@create_items;
    $new_order_info{contacts} = \@contacts;
    
    return $self->process_order($handling, \%new_order_info);
}

sub process_upgrade_order {

    my $self = shift; 
    my $handling = shift;    
    my $order_info = shift;

    my ( %new_order_info, @create_items, %product_data);
   
    $product_data{add_accounts} = {};
    $product_data{update_feature_set} = {};

    if ( scalar @{$order_info->{mod_user_accounts}} > 0) {
        my %add_accounts;
        $add_accounts{accounts} = $order_info->{mod_user_accounts};
        $product_data{add_accounts} = \%add_accounts;
    }
    
    if ( scalar @{$order_info->{mod_feature_set}} > 0 ) {
        my %update_feature_set;
        $update_feature_set{feature_set} = $order_info->{mod_feature_set};
        $product_data{update_feature_set} = \%update_feature_set;
    }
    
    push @create_items, {
        inventory_item_id => $order_info->{inventory_item_id},
        orderitem_type => 'upgrade',
        product_data => \%product_data,
    };
    
    $new_order_info{user_id} = $order_info->{user_id};
    $new_order_info{create_items} = \@create_items;

    return $self->process_order($handling, \%new_order_info);
}

sub process_downgrade_order {

    my $self = shift;
    my $handling = shift;     
    my $order_info = shift;    
 
    my ( %new_order_info, @create_items, %product_data);

    $product_data{delete_accounts} = {};
    $product_data{update_feature_set} = {};
                                                                                                                                                             
    if (scalar @{$order_info->{mod_user_accounts_string}}) {
        $product_data{delete_accounts} = { accounts => $order_info->{mod_user_accounts_string} };
    }

    if ( scalar @{$order_info->{mod_feature_set}}) {
    
	my %update_feature_set;
        $update_feature_set{feature_set} = $order_info->{mod_feature_set};
        $product_data{update_feature_set} = \%update_feature_set;
    }   
    
    push @create_items, {
        inventory_item_id => $order_info->{inventory_item_id},
        orderitem_type => 'downgrade',
        product_data => \%product_data,
    };
    
    $new_order_info{user_id} = $order_info->{user_id};
    $new_order_info{create_items} = \@create_items;

    
    return $self->process_order($handling, \%new_order_info);
}

sub process_order {

    my $self = shift;
    my $handling = shift;    
    my $order_info = shift;

    $order_info->{handling} = $handling ? 'process' : 'save';
    
    $order_info->{create_items}[0]{service} = 'emaildefense';
    $order_info->{create_items}[0]{object_type} = 'manualprovision';

    my $data = {
	attributes => $order_info,
	action => 'create',
	object => 'order',
    };

    return $self->tpp_process_order($data); 
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

#!/usr/bin/perl
package OpenSRS::TPP_Request;
                                                                                                                                                             
use strict;

use OpenSRS::TPP_Client;
use OpenSRS::ResponseConverter; 
use Data::Dumper;
use OpenSRS::EmailDefense_errors;
use OpenSRS::Util::ConfigJar;

my $TPP_Client;

sub new {

    my $class = shift;
    $class = ref $class if ref $class;
    my $self = {};

    $TPP_Client = new OpenSRS::TPP_Client();
        
    return bless $self, $class;
}                                                                                                                                                             

sub init {

    my $self = shift;

    # create a client object which we will use to connect to the Tucows OpenSRS server
    $TPP_Client = new OpenSRS::TPP_Client(
        %OpenSRS::Util::ConfigJar::OPENSRS,
        response_converter => new OpenSRS::ResponseConverter(),
    );
    
    $TPP_Client->login;
}

sub logout {

    my $self = shift;
    $TPP_Client->logout;
}

sub error_exit {

    my $self = shift;
    my $error = shift;

    return { is_success => 0,
	     error => $error, 
	   };
}

sub send_cmd {
    
    my $self = shift;
    my $tpp_request = shift;
    
    $tpp_request->{version} = $OpenSRS::Util::ConfigJar::WSB{PROTOCOL_VERSION};

    my $tpp_response = $TPP_Client->send_cmd( $tpp_request );
    return $tpp_response;  
}

sub tpp_validate_contacts {

    my $self = shift;
    my $contact_data = shift;
    
    my %params = @_;
    
    my %result = $TPP_Client->validate_contacts( $contact_data, custom_verify => $params{custom_verify} );
    
    return \%result;
}

sub tpp_recover_password {

    my $self = shift;    
    my $username = shift;
    
    # call the server to check the email addres availability
    my $tpp_request =  {
	    action => 'recover',
	    object => 'user.password',
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => {
	        users => [
		    { username => $username }
	        ],
	    },
    };

    return $self->send_cmd( $tpp_request );
}

sub tpp_login_user {

    my $self = shift;    
    my $username = shift;
    my $password = shift;
    
    my $tpp_request =  {
	    action => 'create',
	    object => 'session',
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => {
		    username => $username,
		    password => $password, 
	    },
    };
   
    return $self->send_cmd( $tpp_request );
}

sub tpp_create_user {

    my $self = shift;    
    my $username = shift;
    my $password = shift;
    
    # call the server to check the email addres availability
    my $tpp_request =  {
	    action => 'create',
	    object => 'user',
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => {
		    username => $username,
		    password => $password, 
	    },
    };
   
    return $self->send_cmd( $tpp_request );
}

sub tpp_delete_rwi2_user {

    my $self = shift;    
    my $rwi2_user_id = shift;
    
    # call the server to check the email addres availability
    my $tpp_request =  {
	    action => 'delete',
	    object => 'user',
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => {
		users => [
		    { user_id => $rwi2_user_id },
		],
	    },
    };
   
    return $self->send_cmd( $tpp_request );
}



sub tpp_check_emaildefense_domain {
    
    my $self = shift;
    my $domain_name = shift;
        
    # call the server to check the email addres availability
    my $tpp_request =  {
	    action => 'check',
	    object => 'emaildefense.domain',
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => {
	        service => 'emaildefense',
	        product_data => {
		    domain => $domain_name,
	        },
	    },
    };

    return $self->send_cmd( $tpp_request );        
}

sub tpp_get_domain_info {

    my $self = shift;
    my $domain_name = shift;
        
    # check if this domain belongs to the quering reseller
    my $tpp_request = {
      protocol => 'TPP',
      version => '1.3',
      action => 'execute',
      object => 'query',
      requestor => {
          username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
      },
      
      attributes => {
          query_name => 'inventory_items.by_description',
          start_index => 1,
          conditions => [
              {
                type => 'simple',
                field => 'description',
                operand => {
                    eq => $domain_name,
                }
              },                   
	      {
		type => 'link',
		link => 'and',
	      },
	      {
		type => 'simple',
		field => 'service',
		operand => {
		    eq => 'emaildefense',
		},
	      },
	      	      {
		type => 'link',
		link => 'and',
	      },
	      {
		type => 'simple',
		field => 'state',
		operand => {
		    eq => 'active',
		},
	      },
          ]
      },
    };

    return $self->send_cmd( $tpp_request );    
} 


sub tpp_query_user {

    my $self = shift;    
    my $user_id = shift;
    
    # call the server to check the email addres availability
    my $tpp_request =  {
	    action => 'execute',
	    object => 'query',
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => {
		query_name => 'user.by_id',
		conditions => [
              	    {
                	type => 'simple',
                	field => 'user_id',
                	operand => {
                    	    eq => $user_id,
                	}
		    },
		]
	    },
    };
   
    return $self->send_cmd( $tpp_request );
}

sub tpp_get_inventory_item_by_id {

    my $self = shift;
    my $inventory_item_id = shift;
    
    my $tpp_request = {
      protocol => 'TPP',
      version => '1.3',
      action => 'execute',
      object => 'query',
      requestor => {
          username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
      },
      attributes => {
          query_name => 'inventory_item.by_id',
          start_index => 1,
          conditions => [
              {
                type => 'simple',
                field => 'inventory_item_id',
                operand => {
                    eq => $inventory_item_id,
                },
              },
          ],
      },
    };
    
    my $result = $self->send_cmd( $tpp_request );

    return $result;
}


sub tpp_get_antispam_domains_by_user {

    my ($self, $data) = @_;

    my $user_id = $data->{user_id};
    
    # call the server to check the email addres availability
    my $tpp_request =  {
	    action => 'query',
	    object => 'inventory_item',
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => {
                    	    user_id => $user_id,
			    service => 'emaildefense',
			    owned_by => $user_id, 
            },
    };
       
    return $self->send_cmd( $tpp_request );
}

sub tpp_query_inv_items_created_by_user_id {

    my ($self, $data) = @_;
   
    my $attributes = {
        query_name => 'inventory_items.created.by_user_id',
	report_instance_id => $data->{report_instance_id},
	page_size => $data->{page_size},
	start_index => $data->{start_index},
        conditions => [
              {
                type => 'simple',
                field => 'user_id',
                operand => {
                    eq => $data->{user_id},
                },
              },
	      {
	      	type => 'link',
		link => 'and',  
	      },
              {
                type => 'simple',
                field => 'service',
                operand => {
                    eq => $data->{service},
                },
              },
          ],
    };
    
    my $tpp_request = $self->tpp_execute_query($attributes);
    
    return $self->send_cmd( $tpp_request );
}

sub tpp_query_inv_item_by_id {

    my ($self, $data) = @_;
    
    my $attributes = {
          query_name => 'inventory_item.by_id',
          start_index => 1,
          conditions => [
              {
                type => 'simple',
                field => 'inventory_item_id',
                operand => {
                    eq => $data->{inventory_item_id},
                },
              },
          ],
    };
    
    my $tpp_request = $self->tpp_execute_query($attributes);
    
    return $self->send_cmd( $tpp_request );
}

sub tpp_query_inv_item_by_description {

    my ($self, $data) = @_;
    
    my $attributes = {
          query_name => 'inventory_items.by_description',
          start_index => 1,
          conditions => [
              {
                type => 'simple',
                field => 'description',
                operand => {
                    eq => $data->{description},
                },
              },
	      {
	      	type => 'link',
		link => 'and',  
	      },
              {
                type => 'simple',
                field => 'service',
                operand => {
                    eq => $data->{service},
                },
              },
	      {
	      	type => 'link',
		link => 'and',  
	      },
              {
                type => 'simple',
                field => 'state',
                operand => {
                    eq => 'active',
                },
              },

          ],
    };
    
    my $tpp_request = $self->tpp_execute_query($attributes);
    
    return $self->send_cmd( $tpp_request );


}

sub tpp_query_contact_by_id {

    my ($self, $data) = @_;
    
    my $attributes = {
          query_name => 'contact.by_id',
          start_index => 1,
          conditions => [
              {
                type => 'simple',
                field => 'contact_id',
                operand => {
                    eq => $data->{contact_id},
                },
              },
          ],
    };
    
    my $tpp_request = $self->tpp_execute_query($attributes);
    
    return $self->send_cmd( $tpp_request );
}

sub tpp_execute_query {

    my ($self, $attributes) = @_;
        
    my $tpp_request = {
      protocol => 'TPP',
      version => '1.3',
      action => 'execute',
      object => 'query',
      requestor => {
          username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
      },
      attributes => $attributes,
    };
    
    return $tpp_request;
}

sub tpp_check_rwi2_user {

    my ($self, $attributes) = @_;
    
    my %data;
    
    $data{action} = 'check';
    $data{object} = 'user';
    $data{attributes} = $attributes;

    return $self->tpp_process_order(\%data);

}

sub tpp_process_order {

    my ($self, $data) = @_;
    
    my $action = $data->{action};  
    my $object = $data->{object};
    my $attributes = $data->{attributes};
    
    # call the server to check the email addres availability
    my $tpp_request =  {
	    action => $action,
	    object => $object,
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => $attributes,
    };
   
    return $self->send_cmd( $tpp_request );
}

sub tpp_get_contacts_by_user_id {    

    my $self = shift;
    my $user_id = shift;
    
    my $tpp_request =  {
	    action => 'execute',
	    object => 'query',
	    requestor => {
	        username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
	    attributes => {
		query_name => 'contacts.by_user_id',
		conditions => [
              	    {
                	type => 'simple',
                	field => 'user_id',
                	operand => {
                    	    eq => $user_id,
                	}
		    },
		    {	
			type => 'link',
			link => 'and',
		    },
		    {	
			type => 'simple',
                	field => 'original',
                	operand => {
                    	    eq => 'Y',
                	},
		    },

		]
	    },
    };
    
    return $self->send_cmd( $tpp_request );
}

sub tpp_cancel_emaildefense_service {

    my $self = shift;    
    my $inventory_item_id = shift;

    my $tpp_request = {
            action => 'delete',
            object => 'inventory_item.emaildefense',
            requestor => { 
	    	username => $OpenSRS::Util::ConfigJar::OPENSRS{username},
	    },
            attributes => {
                inventory_items => [ 
		    { 
		        inventory_item_id => $inventory_item_id 
		    } 
		],
            },
    };
                                                                                                                                                             
    return $self->send_cmd( $tpp_request );

}
1;

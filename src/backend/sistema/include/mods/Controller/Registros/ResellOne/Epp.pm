#!/usr/bin/perl
# resellone.net - Epp.pm              
#
# Controller - is4web.com.br
# 2007

package Controller::Registros::ResellOne::Epp;

require 5.004;
require Exporter;
use strict;
use Carp;

use LWP::UserAgent;
use HTTP::Request::Common;
use Controller::Registros::ResellOne::OPS;

use vars qw(@ISA $VERSION $DEBUG $ERR $dir @EXPORT_OK);

#set current dir
$dir = __FILE__;
$dir =~ s/Epp\.pm//;

@ISA = qw(Exporter);
@EXPORT_OK = qw();

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;

	my $self = {
		'OPS' => Controller::Registros::ResellOne::OPS->new,
		'UA' => LWP::UserAgent->new(timeout => 60),
		'ERR' => '',
		'domain' => undef,
		'nyears' => 1,
		'reg_type' => 'new',
		'tld_data' => undef,
		'handle' => 'process', #Por padão processa a requisição de imediato, use 'save' para testes
		'auto_renew' => 0,
		'type' => 'owner',
		'ip' => undef,	
	};
	
	bless ($self,$class);

	return ($self);
}

#####################
#Comandos de Domínio
#####################
sub domain_transferrable {
	my($self) = @_;
	
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'CHECK_TRANSFER',
						        object => 'domain',
						        attributes => {
						            domain => $self->{domain},
						            check_status => 0,
									get_request_address => 0
						        }
					    	});
	
	return ($response->{'response_code'},$response->{'attributes'}{'transferrable'},$response->{'attributes'}{'reason'});
}

sub domain_check {
	my($self) = @_;

	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'lookup',
						        object => 'domain',
						        attributes => {
						            domain => $self->{domain},
						        }
					    	});	

	return ($response->{'response_code'},$response->{'response_text'});
}

sub domain_create {
	my($self) = @_;

	$self->requeriments;
	$self->{'hide_reseller'} = undef unless $self->{'reg_type'} eq "new";
		
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'sw_register',
						        object => 'domain',
						        attributes => {
									f_lock_domain => undef,
									f_whois_privacy => $self->{'hide_reseller'},
									domain => $self->{'domain'},
#									domain_description => undef,
#									affiliate_id => undef,
									handle => $self->{'handle'}, #save | process
#									isa_trademark => '0', #1 | 0
#									legal_type => 'TRS', # TRS
									period => $self->{'nyears'},
									reg_type => $self->{'reg_type'}, #new | transfer
									reg_username => $self->{'username'},
									reg_password => $self->{'password'},
									reg_domain => $self->{'link_domain'},
									tld_data => $self->{'tld_data'},									
									auto_renew => $self->{'auto_renew'},
#									link_domains => undef,
#									encoding_type => undef,
									custom_nameservers => '1',
									custom_transfer_nameservers => '1',
									custom_tech_contact => $self->{'custom_tech'},									
									nameserver_list => $self->{'ns_list'},
									contact_set => $self->{'contact_list'},
						        }
					    	});
	$self->{'order_id'} = $response->{attributes}->{id} || $response->{attributes}->{forced_pending} || $response->{attributes}->{queue_request_id};
	$self->{'order_queue'} = $response->{attributes}->{forced_pending} || $response->{attributes}->{queue_request_id};
	
	return ($response->{'response_code'},$response->{'response_text'});
}

sub domain_get {
	my ($self) = @_;
	
	$self->_setcookie unless $self->{cookie};
	
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'get',
						        object => 'domain',
						        cookie => $self->{'cookie'},
						        registrant_ip => $self->{'ip'},
						        attributes => {
						        	type => $self->{'type'},
						        	page => $self->{'page'},
								}
							});
							
	return ($response);					        
}

sub domain_modify {
	my($self) = @_;

	$self->_setcookie unless $self->{cookie};
	$self->requeriments;
	
	#types: assign | add_remove
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'modify',
						        object => 'domain',
								cookie => $self->{'cookie'},
						        registrant_ip => $self->{'ip'},						        
						        attributes => {
						        	data => $self->{data},
						        	affect_domains => $self->{affect},
						        	#also_apply_to => ,
						        	#report_email => ,
						        	#org_name => ,
						            contact_set => $self->{'contact_list'},
						        }
					    	});	

	return ($response->{'response_code'},$response->{'response_text'});
}

sub domain_update_nameservers {
	my($self) = @_;

	$self->_setcookie unless $self->{cookie};
	
	#types: assign | add_remove
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'advanced_update_nameservers',
						        object => 'domain',
								cookie => $self->{'cookie'},
						        registrant_ip => $self->{'ip'},						        
						        attributes => {
						        	op_type => $self->{type},
						            assign_ns => $self->{assign_list},
						            add_ns => $self->{add_list},
						            remove_ns => $self->{remove_list},
						        }
					    	});	

	return ($response->{'response_code'},$response->{'response_text'});
}

sub nameserver_get {
	my ($self) = @_;
	
	$self->_setcookie unless $self->{cookie};
	
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'get',
						        object => 'nameserver',
						        cookie => $self->{'cookie'},
						        registrant_ip => $self->{'ip'},
						        attributes => {
						        	name => 'all'
								}
							});
							
	return ($response);					        
}

sub nameserver_create {
	my($self) = @_;

	#need cookie
	$self->_setcookie unless $self->{cookie};

	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'create',
						        object => 'nameserver',
						        cookie => $self->{cookie},
						        attributes => {
									name => $self->{'ns1'},
									ipaddress => $self->{'ip1'},
						        }
					    	});

	return ($response->{'response_code'},$response->{'response_text'});
}

sub nameserver2_create {
	my($self) = @_;

	#need cookie
	$self->_setcookie unless $self->{cookie};

	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'create',
						        object => 'nameserver',
						        cookie => $self->{cookie},
						        attributes => {
									name => $self->{'ns2'},
									ipaddress => $self->{'ip2'},
						        }
					    	});

	return ($response->{'response_code'},$response->{'response_text'});
}

sub nameserver_check {
	my ($self,$ns) = @_;
	
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'registry_check_nameserver',
						        object => 'nameserver',
						        attributes => {
									tld => TLD($ns,'.'),
									fqdn => $ns,
						        }
					    	});
	#200-found 212-not found
	return ($response->{'response_code'},$response->{'response_text'})
}

sub nameserver_modify {
	my($self) = @_;

	$self->_setcookie unless $self->{cookie};
	
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'modify',
						        object => 'nameserver',
								cookie => $self->{'cookie'},
						        registrant_ip => $self->{'ip'},						        
						        attributes => {
						        	name => $self->{old_ns1},
						            new_name => $self->{ns1},
						            ipaddress => $self->{ip1},
						        }
					    	});	

	return ($response->{'response_code'},$response->{'response_text'});
}
sub nameserver_delete {
	my($self) = @_;

	$self->_setcookie unless $self->{cookie};
	
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'delete',
						        object => 'nameserver',
								cookie => $self->{'cookie'},
						        registrant_ip => $self->{'ip'},						        
						        attributes => {
						        	name => $self->{ns1},
						        }
					    	});	

	return ($response->{'response_code'},$response->{'response_text'});
}

sub process {
	my($self) = @_;

	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'get_order_info',
						        object => 'domain',
						        attributes => {
						        	#command => 'cancel', #necessário somente quando quiser cancelar a ordem
						            order_id => Controller::trim($self->{'order_id'}),
						            #fax_received => 1,
						            #owner_address => 'teste@mail.com',
						        }
					    	});	

	return ($response->{'attributes'}{'field_hash'}{'status'} eq 'completed' && $response->{'response_code'} == 200 ? 1 : $response->{'attributes'}{'field_hash'}{'status'} ,$response->{'response_text'});
}

sub renew {
	my($self) = @_;

	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'renew',
						        object => 'domain',
						        attributes => {
						        	auto_renew => $self->{auto_renew},
						        	currentexpirationyear => $self->{exp_year},
						        	handle => $self->{handle},
						            domain => $self->{domain},
									period => $self->{nyears},
						        }
					    	});

	return ($response->{'response_code'},$response->{'response_text'},$response->{'attributes'}{'registration expiration date'});
}

sub revoke {
	my($self) = @_;

	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'revoke',
						        object => 'domain',
						        attributes => {
						        	reseller => $self->{username},
						            domain => $self->{domain},
						            #notes => '',
						        }
					    	});	

	return ($response->{'response_code'},$response->{'response_text'});
}

sub change_ownership {
	my($self) = @_;

	$self->_setcookie unless $self->{cookie};
	
	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'change',
						        object => 'ownership',
								cookie => $self->{'cookie'},
						        registrant_ip => $self->{'ip'},						        
						        attributes => {
						        	move_all => $self->{move_all},
						            username => $self->{change_user},
						            password => $self->{change_pass},
						            reg_domain => $self->{link_domain},
						        }					    	
							});	

	return ($response->{'response_code'},$response->{'response_text'});
}

sub requeriments {
	my ($self) = shift;
	
	my $ext = TLD($self->{domain});
	#required for .us
	if ($ext eq "us") {
		$self->{'tld_data'} = {
			'nexus' => {
				'app_purpose' => 'P3',
				'category' => 'C11',
				#'validator' => '',
			}
		};	
		$self->{'contact_list'}{'admin'}{'phone'} = Controller::frmt($self->{'contact_list'}{'admin'}{'phone'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'admin'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'admin'};
		$self->{'contact_list'}{'billing'}{'phone'} = Controller::frmt($self->{'contact_list'}{'billing'}{'phone'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'billing'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'billing'};
		$self->{'contact_list'}{'owner'}{'phone'} = Controller::frmt($self->{'contact_list'}{'owner'}{'phone'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'owner'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'owner'};
		$self->{'contact_list'}{'tech'}{'phone'} = Controller::frmt($self->{'contact_list'}{'tech'}{'phone'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'tech'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'tech'};
		$self->{'contact_list'}{'admin'}{'fax'} = Controller::frmt($self->{'contact_list'}{'admin'}{'fax'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'admin'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'admin'};
		$self->{'contact_list'}{'billing'}{'fax'} = Controller::frmt($self->{'contact_list'}{'billing'}{'fax'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'billing'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'billing'};
		$self->{'contact_list'}{'owner'}{'fax'} = Controller::frmt($self->{'contact_list'}{'owner'}{'fax'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'owner'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'owner'};
		$self->{'contact_list'}{'tech'}{'fax'} = Controller::frmt($self->{'contact_list'}{'tech'}{'fax'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'tech'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'tech'};
	} 
	if ($ext =~ /^(org|info|biz)$/) { 
		$self->{'contact_list'}{'admin'}{'phone'} = Controller::frmt($self->{'contact_list'}{'admin'}{'phone'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'admin'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'admin'};
		$self->{'contact_list'}{'billing'}{'phone'} = Controller::frmt($self->{'contact_list'}{'billing'}{'phone'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'billing'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'billing'};
		$self->{'contact_list'}{'owner'}{'phone'} = Controller::frmt($self->{'contact_list'}{'owner'}{'phone'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'owner'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'owner'};
		$self->{'contact_list'}{'tech'}{'phone'} = Controller::frmt($self->{'contact_list'}{'tech'}{'phone'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'tech'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'tech'};
		$self->{'contact_list'}{'admin'}{'fax'} = Controller::frmt($self->{'contact_list'}{'admin'}{'fax'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'admin'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'admin'};
		$self->{'contact_list'}{'billing'}{'fax'} = Controller::frmt($self->{'contact_list'}{'billing'}{'fax'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'billing'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'billing'};
		$self->{'contact_list'}{'owner'}{'fax'} = Controller::frmt($self->{'contact_list'}{'owner'}{'fax'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'owner'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'owner'};
		$self->{'contact_list'}{'tech'}{'fax'} = Controller::frmt($self->{'contact_list'}{'tech'}{'fax'},"epp_phone",cc => $self->{Controller}{'country_codes'}{$self->{'contact_list'}{'tech'}{'country'}}{'code'}) if defined $self->{'contact_list'}{'tech'};
	}	
	
	return 1; 		
}

sub _setcontacts {
	my ($self) = shift;

	$self->{admin} = shift || {};
	$self->{billing} = shift || {};
	$self->{owner} = shift || {};
	$self->{tech} = shift || {};
	$self->{'custom_tech'} = %{$self->{tech}} ? 1 : 0;
	$self->{contact_list}{'admin'} = { %{$self->{admin}} } if %{$self->{admin}}; #make unlinked copy
	$self->{contact_list}{'billing'}  = { %{$self->{billing}} } if %{$self->{billing}};
	$self->{contact_list}{'owner'} 	= { %{$self->{owner}} } if %{$self->{owner}};
	$self->{contact_list}{'tech'} = { %{$self->{tech}} } if %{$self->{tech}};
							
	return 1;	
}

sub _setns {
	my ($self) = @_;

	my $i = 0;
	foreach (@{ $self->{_nameservers} }) {
		$self->{'ns'.++$i} = trim($_->{name});
	}
		
	$self->{ns_list} = [
						{
							sortorder => '1',
							name => $self->{'ns1'}
						},
						{
							sortorder => '2',
							name => $self->{'ns2'}
						}									
						];
	return 1;	
}

sub error { return $_[0]->{'ERR'}; }
sub set_error {
	my $self = shift;
	$self->{ERR} = "@_" if "@_" ne "" && !$self->error;
	return 0;
}

sub _setcookie {
	my ($self) = @_;
	return if $self->error;
	
	$self->{'cookie_user'} ||= $self->{'username'};
	$self->{'cookie_pass'} ||= $self->{'password'};

	#make request
	my $response = $self->command ({
						        protocol => 'XCP',
						        action => 'set',
						        object => 'cookie',
						        attributes => {
						        	domain => $self->{domain},
						        	reg_username => $self->{'cookie_user'},
						        	reg_password => $self->{'cookie_pass'},
						        }
					    	});
	$self->{'cookie'} = $response->{'attributes'}->{'cookie'};
	
	$self->_setcookie if $response->{'response_text'} eq 'Fatal Server Error Occured';
	
	$self->{ERR} = $self->{Controller}->lang(822) unless $self->{'cookie'};
	
	return ($response->{'response_code'},$response->{'response_text'});
} 

#####################
#Subs
#####################
sub command {
	my ($self,$request) = @_;
	my $cmd;

	return if $self->error;
	#make commands
	die "Invalid Command\n" unless ($request) ;

	my $xml = $self->{'OPS'}->encode($request)."\n";
    my $signature = Digest::MD5::md5_hex(Digest::MD5::md5_hex($xml,$self->{private_key}),$self->{private_key});
    my $http_request = HTTP::Request::Common::POST (
			$self->{host}.':'.$self->{port},
			'Content-Type' => 'text/xml',
			'X-Username' => $self->{username},
			'X-Signature' => $signature,
			'Keep-Alive' => 'off',
			'Content-Length' => length($xml),
			'Content' => $xml,
       );

	
	my $response = $self->{'UA'}->request($http_request);

	if (defined $response and $response->is_success){
		my $response2 = $self->{'OPS'}->decode($response->{_content});
		if ( defined $response2 and $response2->{is_success}) {
			if (exists($response2->{'response_code'}) && $response2->{'response_code'} eq "OPS_ERR") {  
				#a protocol error occurred, print it out 
	            $self->set_error($response2->{'response_text'});
				return undef;
			} else {
            	return $response2;
			}
        } else {    	
            #can connect but key is invalid or Lookup failed
            $response2->{'response_code'} = 0;
            $self->set_error($request->{'action'}.': '.$response2->{'response_text'});
			return $response2;
        }
    } else {
		$self->set_error($response->status_line);
		return undef;
    }
}

sub TLD {
	my ($name,$dot) = @_;
	
	$name =~ m/\.(com|net|edu|mil|gov|pro|aero|coop|name|int|museum|org|biz|info|(?#	#internacionais
			 )[ac-z]{2}|b[a-qs-z]{2}|(?#												#gerais
			 )(a[grdt][rtmvqo]|am|b[iml][od]g?|c[ino][mgto]p?|e[cntds][ngiupc]|f[nosal][dtro]g?|(?#	#brasileiros
			 )fm|g[1og][2vf]|i[mn][bdf]|j[ou[rs]|l[e][l]|m[aieu][ltds]|n[eot][trm]|o[rd][go]|(?#	#brasileiros
			 )p[spr][ifocg]|q[s][l]|r[e][c]|s[lr][gv]|t[mur][prd]|tv|v[el][to]g?|z[l][g]|wiki)\.br(?#	#brasileiros excluindo .br
			 ))$/i;
	
	return $dot.$1;	
}

sub trim($) {
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}

sub DESTROY
{
        my ($self,$epp) = @_;
}

1;
__END__;
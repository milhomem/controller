#!/usr/bin/perl
#
# Controller - is4web.com.br
# 2009 - 2012
use Cwd;
use Digest::MD5;
use lib getcwd;
use lib '../include/mods';
#Modulos personalizados
use lib '../../app/modules';

use base Controller;
use Controller::XML;
use IO::Compress::Gzip qw(gzip $GzipError);
use Controller::Interface::Admin;

use vars qw[ $theme $language $dbname $dbhost $dbuser $dbpass $system $q ];
use vars qw(@ISA $VERSION $DEBUG $SOAP_URI $SCHEMA_URI $SCHEMAXDS_URI $NAMESPACE $SOAP_ENC $LANG $doc);

# Acesso ao banco
require "../../db.cfg";

$VERSION = '2014.09.05'; #YYYY-MM-NN sendo N 1-9, Nao pode terminar em 0  
$SOAP_URI = 'httpschemas.xmlsoap.org/soap/envelope/';
$SOAP_ENC = 'http://schemas.xmlsoap.org/soap/encoding/';
$SCHEMA_URI	= 'http://www.w3.org/2001/XMLSchema-instance';
$SCHEMAXDS_URI = 'http://www.w3.org/2001/XMLSchema';
$NAMESPACE = 'http://tempuri.org/';

my $system = new Controller( '_type'=>'mysql', 
							'_host'=>$dbhost,
							'_user'=>$dbuser,
							'_pass'=>$dbpass,
							'_inst'=>$dbname,
							'_cwd'=>getcwd,
							'_fd_logs'=>'../../logs', );

#invocar os metodos da interface e sobrescrever os parses
#os parsers vao precisar de tpl provavelmente utilizar wdsl
request($system);
die $system->nice_error if $system->error; #Hard error

# Subs #
sub newDocument {
    my $doc = Controller::XML->newDocument('1.0');
	my $soap = $doc->createElementRootNS('', 'SOAP-ENV:Envelope');
	$soap->setNamespace($SOAP_URI, 'SOAP-ENV', 0);	
	$soap->setAttribute('SOAP-ENV:encondingStyle', $SOAP_ENC);
	$doc->createElement('SOAP-ENV:Header', $soap);
	$doc->createElement('SOAP-ENV:Body', $soap);
	
	return $doc;
}

sub request {
	my ($self) = shift;
	return if $self->error; #verifica erro antes de continuar	

	die 'Versão não suportada! Unsupported version!' unless $ENV{'HTTP_USER_AGENT'} =~ m#controlleradmin/#; #Firefox plugin discontinued

  	my $action = $ENV{'HTTP_SOAPACTION'};
	my $envelope = $self->param('POSTDATA');

	my $interface = Controller::Interface::Admin->new($self);
	die 'Invalid version!' unless $interface->version() eq $VERSION;
	my %request = %{Controller::XML->xml2perl($envelope)};
	
	#Header
	if (keys %{ $request{'env:Header'} }) {
		#login info
		$interface->{cookname} = $request{'env:Header'}[0]{'cookname'}[0]{'content'};
		$interface->{cookcert} = $request{'env:Header'}[0]{'cookcert'}[0]{'content'};
		$interface->{cooktzo} = $request{'env:Header'}[0]{'cooktzo'}[0]{'content'};
		#lang info
		$interface->_setlang($request{'env:Header'}[0]{'lang'});
	}

	#Body
	foreach my $cmd (keys %{ $request{'env:Body'}[0] }) {
		#set params
		map { $interface->param($_, defined $request{'env:Body'}[0]{$cmd}[0]{$_}[0]{'content'} ? $request{'env:Body'}[0]{$cmd}[0]{$_}[0]{'content'} : exists $request{'env:Body'}[0]{$cmd}[0]{$_} ? '' : undef ) } keys %{$request{'env:Body'}[0]{$cmd}};
		#response
		my $doc = prepare_response($self,$cmd);
		#call
		eval '$interface->'.$cmd.'();';
		#Soft Error
		my $error = $self->clear_error;
		if ($error) {
			my $response = ( $doc->getElementsByTagName('response') )[0];
			$response->setAttribute('result', $self->hard_error ? '-1' : '0');
			$doc->createElement('reason', $response, $error);
		}	
		#clean params
		map { $interface->param($_,undef) } keys %{$request{'env:Body'}[0]{$cmd}};	
		#answer
		response($self,$doc);	
	}
}

sub prepare_response {
	my ($self) = shift;
	
	our $doc = newDocument;
	#header
	my $header = ( $doc->getElementsByTagName('SOAP-ENV:Header') )[0];
	$doc->createElement('generator', $header, "Controller $VERSION");
	$doc->createElement('hostname', $header, $ENV{'SERVER_NAME'});
	$doc->createElement('method', $header, $_[0]);
	$doc->createElement('cookname', $header, $self->{cookname});
	$doc->createElement('cookcert', $header, $self->{cookcert});
	$doc->createElement('cooktzo', $header, $self->{cooktzo});
	$doc->createElement('timeout', $header, $self->setting('admin_timeout'));
	$doc->createElement('request_time', $header, time);
		
	#body
	my $response = $doc->createElement('response', 'SOAP-ENV:Body');
    
	return $doc;
}

sub response {
	my $self = shift;
	my $doc = shift;
	
	my $z = \*STDOUT;
	my $charset = 'UTF-8';
	$doc->setEncoding($charset);
	binmode $z, ':utf8';
	print $z "Content-type: application/soap+xml; charset=$charset\n\n";
	$doc->createElement('sql_query', 'response', $self->{_statement});	
	$doc->toFH($z);
}

#=================== SOAP XUL API ==================
sub Controller::Interface::responseDocument { our $doc; ( $doc->getElementsByTagName('response') )[0]; }
sub Controller::Interface::xmlDocument { our $doc; }

sub Controller::setting {
	my ($self, $key, $value) = @_;
	
	$self->{settings}{$key} = $value if defined $value;
	#return 'UTF-8' if $key eq 'iso';
	$key = 'iso' if $key eq 'osi';
	if (exists $self->{settings}{$key}) { 
		return $self->{settings}{$key};
	}
	
	$self->set_error($self->lang(2, $key));
	die if $self->connected; #break, uma configuracao é essencial para o sistema
}

sub Controller::DBConnector::_mysql {
	my ($self) = shift;
	
	my $DSN = qq|DBI:mysql:database=$self->{_inst};host=$self->{_host};mysql_connect_timeout=$self->{_timeout}|;
	$DSN .= qq|port=$self->{_port}| if $self->{_port};
    $self->{dbh} = DBI->connect($DSN, $self->{_user}, $self->{_pass}) ||
    				do { $self->set_error($DBI::errstr); return undef;};
	$self->{dbh}->{HandleError} = sub { $self->Controller::DBConnector::MySQLerror(@_) };
	$self->{dbh}->{PrintError} = 0;
	$self->{dbh}->{RaiseError} = 0;
	$self->{dbh}->{mysql_auto_reconnect} = 1;
	$self->{dbh}->do('/*!40101 SET character_set_client = utf8 */;'); #WRITE
	
	return $self->{dbh};
}

sub Controller::Interface::parse {
	my ($self) = shift;
	my $result = 1; #assumir sempre sucesso
	
	our $doc;
	my $response = ( $doc->getElementsByTagName('response') )[0];
	my $header = ( $doc->getElementsByTagName('SOAP-ENV:Header') )[0];

	if ($_[0] eq '/sendToSupport') {
		$response->setAttribute('addon','null');
		$response->setAttribute('addon_type','null');
		$response->setAttribute('type','null');
		$response->setAttribute('result',$result);
		
		$doc->createElement('result', $response, $result);
	}
	
	if ($_[0] eq '/check') {
		$response->setAttribute('addon','null');
		$response->setAttribute('addon_type','null');
		$response->setAttribute('type','null');
		$response->setAttribute('result',$result);
		
		$doc->createElement('result', $response, $result);
	}
	
	if ($_[0] eq '/logged') {
		( $doc->getElementsByTagName('cookname') )[0]->getFirstChild->setData($self->{cookname});
		( $doc->getElementsByTagName('cookcert') )[0]->getFirstChild->setData($self->{cookcert});
		( $doc->getElementsByTagName('cooktzo') )[0]->getFirstChild->setData($self->{cooktzo});
	
		$response->setAttribute('addon','a301');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','login');
		unless ($self->error) {
			$response->setAttribute('result',$result);		
			$doc->createElement('reason', $response, 'Logged');
		}	
	}
	
	if ($_[0] eq '/logout') {
		( $doc->getElementsByTagName('cookname') )[0]->getFirstChild->setData($self->{cookname});
		( $doc->getElementsByTagName('cookcert') )[0]->getFirstChild->setData($self->{cookcert});
		( $doc->getElementsByTagName('cooktzo') )[0]->getFirstChild->setData($self->{cooktzo});
	
		$response->setAttribute('addon','null');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','logout');
		unless ($self->error) {
			$response->setAttribute('result',$result);		
			$doc->createElement('reason', $response, 'Logout');
		}		
	}

	if ($_[0] eq '/configs') {
		$response->setAttribute('addon','a301');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','config');
		unless ($self->error) {
			$response->setAttribute('result',$result);
			$doc->createElement('dateformat', $response, $self->setting('dataformat'));
			$doc->createElement('decimal', $response, $self->setting('decimal'));
			$doc->createElement('thousand', $response, $self->setting('milhar'));
			$doc->createElement('currency', $response, $self->setting('moeda'));
			$doc->createElement('transport_URI', $response, $self->setting('baseurl').'/rpc/');
			$doc->createElement('home_URI', $response, $self->setting('home'));
			$doc->createElement('charset', $response, $self->setting('iso'));
			$doc->createElement('autoload', $response, $self->setting('autoloadlist'));
			$doc->createElement('search_min', $response, $self->setting('search_min'));
			$doc->createElement('hidecolumnpicker', $response, $self->setting('hidecolumnpicker'));
			
			my $user = $doc->createElement('user', $response);
			$doc->createElement('ID', $user, '');
			$doc->createElement('login', $user, $self->{cookname});
			
		    my $langs = $doc->createElement('languages', $response);
		    $langs->setAttribute('default',$self->setting('language'));
		    $doc->createElement('en', $langs);
		    $doc->createElement('pt', $langs);
		    $doc->createElement('pt-BR', $langs);  
		
			my $domains = $doc->createElement('domains', $response);
			$domains->setAttribute('selected', $self->setting('baseurl'));
		    
		    my $modules = $doc->createElement('modules', $response);
			foreach my $type (sort keys %{ $self->perm('modules') }) {
				next unless $type;
				foreach my $name (keys %{ $self->perm('modules',$type) }) {
					next unless $name;
					$doc->createElement($name, $modules) if $self->perm('modules',$type,$name) == 1;				
				}
			}				
			
			my $addons = $doc->createElement('addons', $response);
			#Modules perms				
			foreach my $module (keys %{ $self->perm }) {
				next unless $module;
				next if $module eq 'modules';
				my $config_module = $doc->createElement($module, $addons);
				$config_module->setAttribute('enabled', $self->perm($module,'all','deny') == 1 ? 'false' : 'true');
				foreach my $type (keys %{ $self->perm($module) }) {
					next unless $type;
					my $config_type = $doc->createElement($type, $config_module);
					foreach my $name (keys %{ $self->perm($module,$type) }) {
						next unless $name;
						$doc->createElement($name, $config_type)->setAttribute('enabled', $self->perm($module,$type,$name) == 0 ? 'false' : 'true');
					}
				}
			}				
			$doc->createElement('eXULadmin_help', $addons)->setAttribute('enabled', 'true');
		}	
	}
	
	if ($_[0] eq '/tree') {
		$response->setAttribute('addon',$_[1]);
		$response->setAttribute('addon_type',$_[2]);
		$response->setAttribute('type','tree');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		
#Serve para fazer a arvore dinamica no menu lateral
#exemplo de resposta
#		response body <SOAP-ENV:Body xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/">
#  <response addon="a210" addon_type="page" type="tree" result="1">
#    <location>/</location>
#    <item IDitem="17">
#      <ID>17</ID>
#      <ID_entity>17</ID_entity>
#      <ID_parent></ID_parent>
#      <name>Home</name>
#      <name_url>home</name_url>
#      <path>home</path>
#      <datetime_create>2009-07-30 16:35:27</datetime_create>
#      <lng></lng>
#      <visible>Y</visible>
#      <status>Y</status>
#      <is_default>N</is_default>
#    </item>
#    <item IDitem="18">
#      <ID>18</ID>
#      <ID_entity>18</ID_entity>
#      <ID_parent>17</ID_parent>
#      <name>Society and culture</name>
#      <name_url>society-and-culture</name_url>
#      <path>home/society-and-culture</path>
#      <datetime_create>2009-10-09 08:06:10</datetime_create>
#      <lng></lng>
#      <visible>N</visible>
#      <status>Y</status>
#      <is_default>N</is_default>
#    </item>
#    <item IDitem="19">
#      <ID>19</ID>
#      <ID_entity>19</ID_entity>
#      <ID_parent>17</ID_parent>
#      <name>Definition</name>
#      <name_url>definition</name_url>
#      <path>home/definition</path>
#      <datetime_create>2009-09-10 11:52:33</datetime_create>
#      <lng></lng>
#      <visible>Y</visible>
#      <status>Y</status>
#      <is_default>N</is_default>
#    </item>
#    <item IDitem="21">
#      <ID>21</ID>
#      <ID_entity>21</ID_entity>
#      <ID_parent>17</ID_parent>
#      <name>Historia</name>
#      <name_url>historia</name_url>
#      <path>home/historia</path>
#      <datetime_create>2009-10-09 08:07:36</datetime_create>
#      <lng></lng>
#      <visible>Y</visible>
#      <status>Y</status>
#      <is_default>N</is_default>
#    </item>
#    <item IDitem="8">
#      <ID>8</ID>
#      <ID_entity>8</ID_entity>
#      <ID_parent></ID_parent>
#      <name>Kontact</name>
#      <name_url>kontact</name_url>
#      <path>kontact</path>
#      <datetime_create>2009-10-09 08:07:10</datetime_create>
#      <lng></lng>
#      <visible>Y</visible>
#      <status>Y</status>
#      <is_default>N</is_default>
#    </item>
#  </response>
#</SOAP-ENV:Body> 
	}
	
	if ($_[0] eq '/user_list') {
		$response->setAttribute('addon','c010');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/user_prenew') {
		$response->setAttribute('addon','c010');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('username','vencimento','minpass') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/user_new') {
		$response->setAttribute('addon','c010');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('username','vencimento','password','status','name','email','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','conta','forma','alert','alertinv','news','language','notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}
		
	if ($_[0] eq '/user_view') {
		$response->setAttribute('addon','c010');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('user','username','vencimento','status','name','email','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','inscricao','rkey','pending','active','acode','lcall','conta','forma','alert','alertinv','news','language','notes','balance','credit','invoice','total','minpass') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}
	
	if ($_[0] eq '/user_update') {
		$response->setAttribute('addon','c010');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('username','vencimento','status','name','email','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','inscricao','rkey','pending','active','acode','lcall','conta','forma','alert','alertinv','news','language','notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}

	if ($_[0] eq '/user_updatepass') {
		$response->setAttribute('addon','c010');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','updatepass');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
		
	if ($_[0] eq '/user_email_view') {
		$response->setAttribute('addon','c012');
		$response->setAttribute('addon_type','email');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('byuser','user','from','to','subject','body','data','tempo','enviado') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}
	
	if ($_[0] eq '/user_advinvoice') {
		$response->setAttribute('addon','c010');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','advinvoice');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('motivo') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/logmail_remove') {
		$response->setAttribute('addon','c180');
		$response->setAttribute('addon_type','emails');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
		
	if ($_[0] eq '/logmail_send') {
		$response->setAttribute('addon','c180');
		$response->setAttribute('addon_type','emails');
		$response->setAttribute('type','send');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/logmail_view') {
		$response->setAttribute('addon','c180');
		$response->setAttribute('addon_type','emails');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('byuser','user','from','to','subject','body','data','tempo','enviado') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}
	
	if ($_[0] eq '/logmail_list') {
		$response->setAttribute('addon','c180');
		$response->setAttribute('addon_type','emails');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
	
		
	if ($_[0] eq '/user_list_balance') {
		$response->setAttribute('addon','c015');
		$response->setAttribute('addon_type','balance');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/user_list_credit') {
		$response->setAttribute('addon','c016');
		$response->setAttribute('addon_type','credit');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
			
	if ($_[0] eq '/user_list_invoice') {
		$response->setAttribute('addon','c013');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/user_list_service') {
		$response->setAttribute('addon','c011');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/user_list_email') {
		$response->setAttribute('addon','c012');
		$response->setAttribute('addon_type','email');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
	
	if ($_[0] eq '/user_remove') {
		$response->setAttribute('addon','c010');
		$response->setAttribute('addon_type','user');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/service_new') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('username', 'dominio', 'plano', 'status', 'inicio', 'fim', 'vencimento', 'proximo', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'action', 'invoice', 'pagos', 'desconto', 'lock', 'parcelas', 'notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}
		
	if ($_[0] eq '/service_list') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/service_options') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','options');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
		
	if ($_[0] eq '/service_list_field') {
		$response->setAttribute('addon','c021');
		$response->setAttribute('addon_type','field');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/service_list_properties') {
		$response->setAttribute('addon','c022');
		$response->setAttribute('addon_type','properties');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
	
	if ($_[0] eq '/service_remove_properties') {
		$response->setAttribute('addon','c022');
		$response->setAttribute('addon_type','properties');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/service_new_properties') {
		$response->setAttribute('addon','c022');
		$response->setAttribute('addon_type','properties');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}			

	if ($_[0] eq '/service_list_multiservers') {
		$response->setAttribute('addon','c023');
		$response->setAttribute('addon_type','multiservers');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/service_prenew') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/service_view') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id', 'username', 'dominio', 'servicos', 'status', 'tipo', 'plataforma', 'inicio', 'fim', 'vencimento', 'proximo', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'action', 'invoice', 'pagos', 'desconto', 'lock', 'parcelas', 'pdate', 'bdate', 'rdate', 'motivo', 'notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/service_update') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('username', 'dominio', 'servicos', 'status', 'inicio', 'fim', 'vencimento', 'proximo', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'action', 'invoice', 'pagos', 'desconto', 'lock', 'parcelas', 'notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}
	
	if ($_[0] eq '/service_prorate') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','prorate');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('motivo') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}	
	
	if ($_[0] eq '/service_transfer') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','transfer');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/service_changepg') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','changepg');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/service_action') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','action');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
			
	if ($_[0] eq '/service_updatefield') {
		$response->setAttribute('addon','c021');
		$response->setAttribute('addon_type','field');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/service_remove') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/service_upgrade') {
		$response->setAttribute('addon','c020');
		$response->setAttribute('addon_type','service');
		$response->setAttribute('type','upgrade');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('saldo') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}
						
	if ($_[0] eq '/plan_prenew') {
		$response->setAttribute('addon','c030');
		$response->setAttribute('addon_type','plan');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('servicos', 'level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert', 'pservidor', 'modulo', 'notes') {
			$doc->createElement($_, $response, $self->template($_));
		}		
	}
	
	if ($_[0] eq '/plan_new') {
		$response->setAttribute('addon','c030');
		$response->setAttribute('addon_type','plan');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('servicos', 'level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert', 'pservidor', 'modulo', 'notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}	
					
	if ($_[0] eq '/plan_list') {
		$response->setAttribute('addon','c030');
		$response->setAttribute('addon_type','plan');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/plan_list_field') {
		$response->setAttribute('addon','c031');
		$response->setAttribute('addon_type','field');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/plan_list_discount') {
		$response->setAttribute('addon','c032');
		$response->setAttribute('addon_type','discount');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
				
	if ($_[0] eq '/plan_view') {
		$response->setAttribute('addon','c030');
		$response->setAttribute('addon_type','plan');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('servicos', 'level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert', 'pservidor', 'modulo', 'notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/plan_update') {
		$response->setAttribute('addon','c030');
		$response->setAttribute('addon_type','plan');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert', 'pservidor', 'modulo', 'notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}
	
	if ($_[0] eq '/plan_remove') {
		$response->setAttribute('addon','c030');
		$response->setAttribute('addon_type','plan');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
	
	if ($_[0] eq '/plan_new_field') {
		$response->setAttribute('addon','c031');
		$response->setAttribute('addon_type','field');
		$response->setAttribute('type','add');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/plan_remove_field') {
		$response->setAttribute('addon','c031');
		$response->setAttribute('addon_type','field');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/plan_new_discount') {
		$response->setAttribute('addon','c032');
		$response->setAttribute('addon_type','discount');
		$response->setAttribute('type','add');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/plan_remove_discount') {
		$response->setAttribute('addon','c032');
		$response->setAttribute('addon_type','discount');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
			
	if ($_[0] eq '/invoice_list') {
		$response->setAttribute('addon','c040');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/invoice_CNAB') {
		$response->setAttribute('addon','c042');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','CNAB');
		$response->setAttribute('result',$result);
		
		foreach ('file_hash') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		$doc->createElement('location', $response);
	}	

	if ($_[0] eq '/invoice_prenew') {
		$response->setAttribute('addon','c040');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/invoice_new') {
		$response->setAttribute('addon','c040');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('status','nome','data_envio','data_vencimento','data_quitado','referencia','services','valor','valor_pago','conta','tarifa','parcelas','parcelado') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}
	
	if ($_[0] eq '/invoice_view') {
		$response->setAttribute('addon','c040');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id' ,'username', 'status', 'nome', 'data_envio', 'data_vencido', 'data_vencimento', 'data_quitado', 'envios', 'referencia', 'services', 'valor', 'valor_pago', 'imp', 'conta', 'tarifa', 'parcelas', 'parcelado', 'nossonumero', 'link_boleto', 'emails', 'modulo', 'confirmado') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/invoice_update') {
		$response->setAttribute('addon','c040');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/invoice_postpone') {
		$response->setAttribute('addon','c040');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','postpone');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('motivo') {
			$doc->createElement($_, $response, $self->template($_));
		}		
	}	
	
	if ($_[0] eq '/invoice_send') {
		$response->setAttribute('addon','c040');
		$response->setAttribute('addon_type','invoice');
		$response->setAttribute('type','send');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
		
	if ($_[0] eq '/balance_list') {
		$response->setAttribute('addon','c050');
		$response->setAttribute('addon_type','balance');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}		

	if ($_[0] eq '/balance_view') {
		$response->setAttribute('addon','c050');
		$response->setAttribute('addon_type','balance');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id', 'username', 'valor', 'descricao', 'servicos', 'invoice','name') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/balance_new') {
		$response->setAttribute('addon','c050');
		$response->setAttribute('addon_type','balance');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);	
	}
	
	if ($_[0] eq '/balance_update') {
		$response->setAttribute('addon','c050');
		$response->setAttribute('addon_type','balance');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);	
	}

	if ($_[0] eq '/balance_remove') {
		$response->setAttribute('addon','c050');
		$response->setAttribute('addon_type','balance');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);	
	}
	
	if ($_[0] eq '/credit_list') {
		$response->setAttribute('addon','c060');
		$response->setAttribute('addon_type','credit');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}		

	if ($_[0] eq '/credit_view') {
		$response->setAttribute('addon','c060');
		$response->setAttribute('addon_type','credit');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id', 'username', 'valor', 'descricao', 'servicos', 'invoice','name') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/credit_new') {
		$response->setAttribute('addon','c060');
		$response->setAttribute('addon_type','credit');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/credit_update') {
		$response->setAttribute('addon','c060');
		$response->setAttribute('addon_type','credit');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
		
	if ($_[0] eq '/credit_remove') {
		$response->setAttribute('addon','c060');
		$response->setAttribute('addon_type','credit');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/account_prenew') {
		$response->setAttribute('addon','c080');
		$response->setAttribute('addon_type','account');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
				
	if ($_[0] eq '/account_new') {
		$response->setAttribute('addon','c080');
		$response->setAttribute('addon_type','account');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('nome','banco','dvbanco','agencia','conta','carteira','convenio','cedente','instrucoes','nossonumero') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}

	if ($_[0] eq '/account_list') {
		$response->setAttribute('addon','c080');
		$response->setAttribute('addon_type','account');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/account_view') {
		$response->setAttribute('addon','c080');
		$response->setAttribute('addon_type','account');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','nome','banco','dvbanco','agencia','conta','carteira','convenio','cedente','instrucoes','nossonumero') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/account_update') {
		$response->setAttribute('addon','c080');
		$response->setAttribute('addon_type','account');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('nome','banco','dvbanco','agencia','conta','carteira','convenio','cedente','instrucoes','nossonumero') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}		
	
	if ($_[0] eq '/account_remove') {
		$response->setAttribute('addon','c080');
		$response->setAttribute('addon_type','account');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);	
	}
	
	if ($_[0] eq '/payment_list') {
		$response->setAttribute('addon','c090');
		$response->setAttribute('addon_type','payment');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/payment_view') {
		$response->setAttribute('addon','c090');
		$response->setAttribute('addon_type','payment');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','nome','primeira','intervalo','parcelas','pintervalo','tipo','repetir','pre') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/payment_prenew') {
		$response->setAttribute('addon','c090');
		$response->setAttribute('addon_type','payment');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/payment_new') {
		$response->setAttribute('addon','c090');
		$response->setAttribute('addon_type','payment');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('nome', 'primeira', 'intervalo', 'parcelas', 'pintervalo', 'tipo', 'repetir') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}
	
	if ($_[0] eq '/payment_update') {
		$response->setAttribute('addon','c090');
		$response->setAttribute('addon_type','payment');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','nome','primeira','intervalo','parcelas','pintervalo','tipo','repetir','pre') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}

	if ($_[0] eq '/payment_remove') {
		$response->setAttribute('addon','c090');
		$response->setAttribute('addon_type','payment');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/paymentmethod_list') {
		$response->setAttribute('addon','c130');
		$response->setAttribute('addon_type','paymentmethod');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/server_prenew') {
		$response->setAttribute('addon','c100');
		$response->setAttribute('addon_type','server');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo') {
			$doc->createElement($_, $response, $self->template($_));
		}		
	}
				
	if ($_[0] eq '/server_new') {
		$response->setAttribute('addon','c100');
		$response->setAttribute('addon_type','server');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}
					
	if ($_[0] eq '/server_list') {
		$response->setAttribute('addon','c100');
		$response->setAttribute('addon_type','server');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/server_view') {
		$response->setAttribute('addon','c100');
		$response->setAttribute('addon_type','server');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/server_update') {
		$response->setAttribute('addon','c100');
		$response->setAttribute('addon_type','server');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}

	if ($_[0] eq '/server_list_field') {
		$response->setAttribute('addon','c101');
		$response->setAttribute('addon_type','field');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}	
	
	if ($_[0] eq '/server_updatefield') {
		$response->setAttribute('addon','c101');
		$response->setAttribute('addon_type','field');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','Rns1','Rns2','Hns1','Hns2','MultiWEB','MultiDNS','MultiMAIL','MultiFTP','MultiSTATS','MultiDB') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}	
	
	if ($_[0] eq '/server_remove') {
		$response->setAttribute('addon','c100');
		$response->setAttribute('addon_type','server');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);	
	}	

	if ($_[0] eq '/settings_view') {
		$response->setAttribute('addon','c070');
		$response->setAttribute('addon_type','settings');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ($self->settings) {
			$doc->createElement($_, $response, $self->template($_));
		}
	}

	if ($_[0] eq '/settings_update') {
		$response->setAttribute('addon','c070');
		$response->setAttribute('addon_type','settings');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ($self->settings) {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}

	if ($_[0] eq '/creditcard_prenew') {
		$response->setAttribute('addon','c150');
		$response->setAttribute('addon_type','creditcard');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','username','name','first','last','ccn','exp','cvv2','active','tarifa') {
			$doc->createElement($_, $response, $self->template($_));
		}		
	}
				
	if ($_[0] eq '/creditcard_new') {
		$response->setAttribute('addon','c150');
		$response->setAttribute('addon_type','creditcard');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','username','name','first','last','ccn','exp','cvv2','active','tarifa') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}
		
	if ($_[0] eq '/creditcard_list') {
		$response->setAttribute('addon','c150');
		$response->setAttribute('addon_type','creditcard');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}
	
	if ($_[0] eq '/creditcard_view') {
		$response->setAttribute('addon','c150');
		$response->setAttribute('addon_type','creditcard');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','username','name','first','last','ccn','exp','cvv2','active','tarifa') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}
	
	if ($_[0] eq '/creditcard_update') {
		$response->setAttribute('addon','c150');
		$response->setAttribute('addon_type','creditcard');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','username','name','first','last','ccn','exp','cvv2','active','tarifa') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}
	
	if ($_[0] eq '/creditcard_remove') {
		$response->setAttribute('addon','c150');
		$response->setAttribute('addon_type','creditcard');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);	
	}
		
	if ($_[0] eq '/staff_prenew') {
		$response->setAttribute('addon','c140');
		$response->setAttribute('addon_type','staff');
		$response->setAttribute('type','prenew');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','username','password','name','email','access','notify','signature','play_sound') {
			$doc->createElement($_, $response, $self->template($_));
		}		
	}
				
	if ($_[0] eq '/staff_new') {
		$response->setAttribute('addon','c140');
		$response->setAttribute('addon_type','staff');
		$response->setAttribute('type','new');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','username','password','name','email','access','notify','signature','play_sound','notes','minpass') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('fail','true') if $el;
		}		
	}
		
	if ($_[0] eq '/staff_list') {
		$response->setAttribute('addon','c140');
		$response->setAttribute('addon_type','staff');
		$response->setAttribute('type','list');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}

	if ($_[0] eq '/staff_view') {
		$response->setAttribute('addon','c140');
		$response->setAttribute('addon_type','staff');
		$response->setAttribute('type','view');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		#'username',
		foreach ('id','name','email','access','notify','signature','play_sound','notes') {
			$doc->createElement($_, $response, $self->template($_));
		}
	}
	
	if ($_[0] eq '/staff_update') {
		$response->setAttribute('addon','c140');
		$response->setAttribute('addon_type','staff');
		$response->setAttribute('type','update');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
		foreach ('id','username','password','name','email','access','notify','signature','play_sound') {
			$doc->createElement($_, $response, $self->template($_));
		}
		
		foreach (@{ $self->template('nonchanged') }) {
			my $el = ( $doc->getElementsByTagName($_) )[0];
			$el->setAttribute('update','false') if $el;
		}
	}
	
	if ($_[0] eq '/staff_remove') {
		$response->setAttribute('addon','c140');
		$response->setAttribute('addon_type','staff');
		$response->setAttribute('type','remove');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);	
	}
	
	if ($_[0] eq '/staff_updatepass') {
		$response->setAttribute('addon','c140');
		$response->setAttribute('addon_type','staff');
		$response->setAttribute('type','updatepass');
		$response->setAttribute('result',$result);
		
		$doc->createElement('location', $response);
	}		
	
	return 1;
}

sub Controller::Interface::parse_var {
	my ($self) = shift; 
	
	our $doc;
	my $response = ( $doc->getElementsByTagName('response') )[0];
	
	if ($_[1] eq '/row_users') {
		my $item = $doc->createElement('item', $response);
		foreach ('username','vencimento','status','name','email','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','inscricao','rkey','pending','active','acode','lcall','conta','forma','alert','alertinv','news','language') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}

	if ($_[1] eq '/row_user_list_credit') {
		my $cstatus = ( $doc->getElementsByTagName($self->template('cstatus')) )[0] || $doc->createElement($self->template('cstatus'), $response);		
		my $item = $doc->createElement('item',$cstatus);
		foreach ('id', 'username', 'valor', 'descricao', 'cstatus') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}

	if ($_[1] eq '/row_user_list_balance') {
		my $bstatus = ( $doc->getElementsByTagName($self->template('bstatus')) )[0] || $doc->createElement($self->template('bstatus'), $response);		
		my $item = $doc->createElement('item',$bstatus);
		foreach ('id', 'username', 'valor', 'descricao', 'servicos', 'invoice', 'bstatus') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}
	
	if ($_[1] eq '/row_user_list_invoice') {
		my $status = ( $doc->getElementsByTagName($self->template('status')) )[0] || $doc->createElement($self->template('status'), $response);		
		my $item = $doc->createElement('item',$status);
		foreach ('id', 'username', 'status', 'nome', 'data_envio', 'data_vencido', 'data_vencimento', 'data_quitado', 'envios', 'referencia', 'services', 'valor', 'valor_pago', 'imp', 'conta', 'tarifa', 'parcelas', 'parcelado', 'nossonumero') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}
	
	if ($_[1] eq '/row_users_list_email') {
		my $item = $doc->createElement('item', $response);
		foreach ('id','byuser', 'user', 'from', 'to', 'subject', 'data', 'tempo', 'enviado') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}	
			
	if ($_[1] eq '/row_services') {
		my $item = $doc->createElement('item', $response);
		#, 'proximo' 
		foreach ('id','username', 'dominio', 'plano', 'status', 'tipo', 'plataforma', 'inicio', 'fim', 'vencimento', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'action', 'invoice', 'pagos', 'desconto', 'lock', 'parcelas') {
			my $subitem = $doc->createElement($_, $item, $self->template($_));
			my $attrs = $self->templateAttr($_);
			foreach my $key (keys %{$attrs}) {
				$subitem->setAttribute($key,$attrs->{$key});
			}
		}
	}

	if ($_[1] eq '/row_service_fields') {
		my $item = $doc->createElement('item', $response);

		foreach ('id','name','value','text') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}	
	
	if ($_[1] eq '/row_plans') {
		my $item = $doc->createElement('item', $response);
		#, 'proximo'
		foreach ('servicos', 'level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert', 'pservidor') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}
	
	if ($_[1] eq '/row_plan_fields') {
		my $item = $doc->createElement('item', $response);

		foreach ('nome','text') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}	

	if ($_[1] eq '/row_plan_discounts') {
		my $item = $doc->createElement('item', $response);
		$item->setAttribute('selected',$self->template('selected') eq 'selected' ? 'true' : 'false');
			
		foreach ('id','pg','nome','valor','max','total') {
			my $el = $doc->createElement($_, $item, $self->template($_));			
		}
	}	
		
	if ($_[1] eq '/row_invoices') {
		my $item = $doc->createElement('item', $response);
		foreach ('id', 'username', 'status', 'nome', 'data_envio', 'data_vencido', 'data_vencimento', 'data_quitado', 'envios', 'referencia', 'services', 'valor', 'valor_pago', 'imp', 'conta', 'tarifa', 'parcelas', 'parcelado', 'nossonumero', 'error', 'tarifa_banco') {
			my $subitem = $doc->createElement($_, $item, $self->template($_));
			my $attrs = $self->templateAttr($_);
			foreach my $key (keys %{$attrs}) {
				$subitem->setAttribute($key,$attrs->{$key});
			}
		}
	}
	
	if ($_[1] eq '/row_balances') {
		my $item = $doc->createElement('item', $response);
		foreach ('id', 'username', 'valor', 'descricao', 'servicos', 'invoice', 'bstatus') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}

	if ($_[1] eq '/row_credits') {
		my $item = $doc->createElement('item', $response);
		foreach ('id', 'username', 'valor', 'descricao', 'cstatus') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}
		
	if ($_[1] eq '/row_accounts') {
		my $item = $doc->createElement('item', $response);
		foreach ('id','nome','banco','dvbanco','agencia','conta','carteira','convenio','cedente','instrucoes','banco_nome') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}

	if ($_[1] eq '/row_payments') {
		my $item = $doc->createElement('item', $response);
		foreach ('id','nome','primeira','intervalo','parcelas','pintervalo','tipo','repetir','pre') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}
	
	if ($_[1] eq '/row_paymentmethods') {
		my $item = $doc->createElement('item', $response);
		foreach ('id','tipo','modo','modulo','valor','tplIndex','autoquitar','visivel') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}
		
	if ($_[1] eq '/row_servers') {
		my $item = $doc->createElement('item', $response);
		foreach ('id','nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}	
	
	if ($_[1] eq '/row_server_fields') {
		my $item = $doc->createElement('item', $response);
		foreach ('id','name','value') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}	

	if ($_[1] eq '/row_creditcards') {
		my $item = $doc->createElement('item', $response);
		foreach ('id','username','name','first','last','exp','tipo','active','status') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}
	
	if ($_[1] eq '/row_staffs') {
		my $item = $doc->createElement('item', $response);
		foreach ('id','username','password','name','email','access','notify','signature','play_sound') {
			$doc->createElement($_, $item, $self->template($_));
		}
	}
				
	if ($_[1] eq '/option') {			
		my $el = ( $doc->getElementsByTagName($_[0]) )[0];
		$el = $doc->createElement($_[0], $response) if ref($el) ne 'XML::LibXML::Element';
		my $item = $doc->createElement('item', $el);
		$doc->createElement('value', $item, $self->template('option_value'));
		$doc->createElement('text', $item, $self->template('option_text'));
		$item->setAttribute('selected',$self->template('selected') eq 'selected' ? 'true' : 'false');
		$self->template('option_value',undef);
		$self->template('option_text',undef);
		return $item;
	}	

	if ($_[1] eq '/email') {			
		my $el = ( $doc->getElementsByTagName('email') )[0];
		$el = $doc->createElement('email', $response) if ref($el) ne 'XML::LibXML::Element';
		my $item = $doc->createElement('item', $el);
		$doc->createElement('reason', $item, $_[0] == 1 ? '' : $_[0]);
		$item->setAttribute('sent',$_[0] == 1 ? 'true' : 'false');
		return $item;
	}
}

sub Controller::Interface::Admin::hard_error {
	my ($self) = shift;	
	
	$self->set_error(@_) if (exists $_[0]);
	
	my $tmp = $self->{_hardError};
	$self->{_hardError} = defined $_[0] unless $tmp;
	return $tmp and !(defined $_[0]);
}

sub Controller::Interface::Admin::check {
	my ($self) = shift;
	
	$self->parse('/check');
}

sub Controller::Interface::Admin::config {
	my ($self) = shift;
	
	if ($self->check_user) {
		$self->parse('/configs');
	}
}

sub Controller::lang {
	my ($self,$no,@values) = @_;
	($no,@values) = @$no if (ref $no eq "ARRAY");

	return "missing_$no_" unless exists $self->{lang}{$no};
	my $text = sprintf($self->{lang}{$no},@values);
	utf8::decode($text); #Sprintf encode Values, so we decode again
	return $text;
}

sub Controller::_setlang {
	my ($self,$language) = @_;
	return 0 if !$language;
	
	#protect ourself
	Controller::escape(\$language);

	if (-e $self->setting('app')."/lang/$language/lang.inc") {
		$self->{_setlang} = $language;
		our %LANG = ();
		
		my $ret = do($self->setting('app')."/lang/$language/lang.inc");

	    die "couldn't parse lang file: $@" if $@;
	    die "couldn't do lang file: $!" unless defined $ret;
	    die "couldn't run lang file" unless $ret;

		$self->{'lang'} = { %LANG };
		
		return 1;
	} else {
		$self->set_error('Lang not found at '.$self->setting('app')."/lang/$language/lang.inc");
		return 0;
	}
}

sub Controller::html2text {
	my $ref = shift;
	return() if ref ($ref) ne "SCALAR";

	package myHTML_utf8;
	use base HTML::TreeBuilder;
	
	#require Encode;
	sub as_text {
		# Yet another iteratively implemented traverser
		my($this,%options) = @_;
		my $skip_dels = $options{'skip_dels'} || 0;
		my(@pile) = ($this);
		my $tag;
		my @text;
		my $nillio = [];
		while(@pile) {
			if(!defined($pile[0])) { # undef!
				# no-op
			} elsif(!ref($pile[0])) { # text bit!  save it!
				push @text, shift @pile;
			} else { # it's a ref -- traverse under it
				unshift @pile, @{$this->{'_content'} || $nillio}
					unless
						($tag = ($this = shift @pile)->{'_tag'}) eq 'style'
						or $tag eq 'script'
						or ($skip_dels and $tag eq 'del');			
				unshift @pile, shift @pile, " <".$this->attr('href').">" if $tag eq 'a' && $pile[0] ne $this->attr('href');

				push @text, "\n" if $tag && $HTML::Element::canTighten{$tag};			 
			}
		}
		
		return join('',@text);
	}	
	sub as_trimmed_text {	
		my $text = shift->as_text(@_);
		$text =~ s/\n+/\n/gs;
		return $text;
	}		
	
	1;
	
	use HTML::Entities qw(_decode_entities);
	_decode_entities($$ref, { nb => "@", nbsp => " " }, 1);
	my $tree = myHTML_utf8->new_from_content($$ref);
	$$ref = $tree->as_trimmed_text(skip_dels => 1);			
	$tree->delete();
	
	return $ref
}

sub Controller::SQL::execute_sql {
	@_ = @_;
	my ($self,$statement,@var) = @_;
	
	if ($Controller::SWITCH{skip_sql} == 1) {
		#warn 'sql skipped';
		return;
	}
	
	utf8::upgrade($_) foreach @var; #Toda escrita tem que estar em utf8 conforme determinado no DBConnector
		
	$self->{_statement} = $statement =~ m/^\d+$/ ? $self->{queries}{$statement} : $statement;
	@{ $self->{_binds} } = @var;	

	my $sth = $self->{dbh}->prepare($self->{_statement});
	if (@var) {#BIND já é protegido contra Injection
		@var = () if $var[0] == -1;#TODO retirar isso quando migrar tudo
		my $rows = $sth->execute(@var);
		if ($rows eq 'ERR') {#Erro personalizado
			my $err = $self->clear_error;
			$self->set_error("Erro $DBI::err em execute_sql($DBI::errstr) ****$statement | ".join(",",@var));
			die $err;
		} elsif ($rows) {
			#Sucesso
		} else {
			$self->set_error("Erro $DBI::err em execute_sql($DBI::errstr) ****$statement | ".join(",",@var));
			die $self->lang(1);
		}
	} else {
		do {$self->set_error("no binds ***$statement"); die $self->lang(1);}
	}

	my $serid = $sth->{'mysql_insertid'} if $self->{_type} =~ /^mysql$/i;
	$sth->finish;
	
	if ($Controller::SWITCH{skip_log} == 1 or $self->{dbh}->{'mysql_errno'}) {
		#warn 'log skipped';
	} else {
		$self->log_sql($serid);
	}
	
	return $serid;
}

sub Controller::_setCGI {
	my ($self) = shift;

	require CGI;
	my $q = CGI->new();
	my @pairs = split(/;/, $q->query_string());
	foreach my $pair (@pairs) {
	    my ($name, $value) = split(/=/, $pair);
	    $self->param($name,Controller::URLDecode2($value));
	}
	
	foreach my $name ($q->cookie()) {
		$self->cookie($name,$q->cookie($name));
	}
	
	return 1;
}

sub Controller::traceback {
	my $self = shift;
    my $err = shift;
    my @trace; #FIXME: empty list?
	
    # Skip the first frame [0], because it's the call to dotb.
    # Skip the second frame [1], because it's the call to die, with redirection
    my $frame = 2;
    my $tab = 1;
    while (my ($package, $filename, $line, $sub) = caller($frame++)) {
        if ($package eq 'main') {
            $sub =~ s/main:://;
            push(@trace, Controller::trim("$sub() called from $filename on line $line"));
        } else {
            push(@trace, Controller::trim("$package::$sub() called from $filename on line $line\n"));
        }
    }
	my $mess = "Traceback (most recent call last):\n";
	$mess .= join("\n", map { "  "x$tab++ . $_ } reverse(@trace) )."\n";
	$mess .= "Package error: ".$self->error."\n";
	$mess .= "Error: $err"; #already has \n at end    
	
	#response
	my $doc = prepare_response($self,'FatalError');
	my $response = ( $doc->getElementsByTagName('response') )[0];
	$response->setAttribute('result', '-1');
    
    $err =~ s/(.+)at.+?$/$1/;
	$doc->createElement('reason', $response, $err);
	
	#answer
	response($self,$doc);
	
	$self->logevent($mess);
	exit(1);	
}

__END__;
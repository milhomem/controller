#Alterando o pacote
use Controller::Registros::RegistroBR;
$system = new Controller::Registros::RegistroBR;
#Fazendo debugs
use Data::Dumper;

sub Controller::get_account {return};
sub Controller::get_payment {return};
sub Controller::get_user {return};
sub Controller::get_service {return};
sub Controller::get_services {return};
sub Controller::get_serviceprop {return};
sub Controller::get_servicesprop {return};
sub Controller::get_plan {return};
sub Controller::get_plans {return};
sub Controller::get_balance {return};
sub Controller::get_balances {return};
sub Controller::get_invoice {return};
sub Controller::get_creditcard {return};
sub Controller::get_account {return};
sub Controller::Services::save {return};
sub Controller::SQL::select_sql {return};
sub Controller::SQL::execute_sql {return};

$system->setting('registrobr_host','beta.registro.br'); #Live 'epp.registro.br'
$system->setting('registrobr_port',700);
$system->setting('registrobr_user','065');
$system->setting('registrobr_pass','PASSWORD HERE');

#User teste
$system->uid(999999);
$system->user('name','Teste Teste Teste');
$system->user('empresa','Teste Teste Teste');
$system->user('endereco','Rua Teste');
$system->user('numero','99');
$system->user('cidade','Sao Paulo');
$system->user('estado','SP');
$system->user('cep','04104-000');
$system->user('cc','BR');
$system->user('telefone','1199999999');
$system->user('vencimento','00');
$system->user('email','milhomem at is4web.com.br');
$system->user('status','CA');
$system->user('pending',0);
$system->user('conta',999999);
$system->user('forma',999999);
$system->user('cpf','11111111111');
$system->user('cnpj','111111111111');
$system->user('alert',1);

#Pagamentos (Forma)
$system->payid(999999); #Mensal #Perde referencia de sid
$system->payment('nome','BiAnual');
$system->payment('primeira',7);
$system->payment('intervalo',720); #Quantidade de anos de registro, sempre /360
$system->payment('parcelas',0);
$system->payment('tipo','P');
$system->payment('repetir',1);

# Serviço TEste
$system->sid(999999);
$system->service('dominio','dominioteste'.$system->randthis(4,0 .. 9).'.com.br');
diag('Dominio: '.$system->service('dominio'));
$system->service('username',999999);
$system->service('status','S');
$system->service('inicio',undef);
$system->service('fim',undef);
$system->service('vencimento',undef);
$system->service('proximo',undef);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',0);
$system->service('dados','CIDBR', 'MFCMI2');
$system->service('pg',999999);
$system->service('envios',0);
$system->service('def',0);
$system->service('action','N');
$system->service('invoice',0);
$system->service('pagos',0);
$system->service('desconto',0);
$system->service('lock',0);

#Teste connection
$system->connection;
is($system->error, undef, 'Start');
ok($system->hello =~ m/Registro.br BETA-TEST EPP Server/g, 'Hello') or diag($system->error);
#Domain Renew

#testes nomais
is($system->availdomain->{'avail'}, 1, 'Dominio disponivel') or diag($system->error);
is($system->availcontact->{'avail'}, 1, 'Contato disponivel') or diag($system->error);
$system->service('dados','CIDBR', 'MFCMI');
is($system->availcontact->{'avail'}, 0, 'MFCMI já existe') or diag($system->error);
is($system->availorg->{'avail'}, 0, 'Org já existe') or diag($system->error);
#Comentado pois ele não apaga entao nao pode ficar criando sempre
#$system->user('cnpj','66836479000109');
#is($system->addorg, 1, 't\7') or diag($system->error);
#poll and poll ack
$system->nameservers({'name' => 'ns1.'.$system->service('dominio'), 'ipv4' => '200.200.200.200', 'ipv6' => undef}); #200.200.200.200
$system->nameservers({'name' => 'dns1.resolver.tld'});
#Esgota o limite de tickes
my $adddomain = $system->adddomain;
ok($adddomain ne undef,'Registrado') or diag($system->error);
$system->service('dados','Ticket',$adddomain->{'ticket'});
ok($system->service('dados','Ticket'), 'Virou ticket') and diag($system->service('dados','Ticket') .' <> '. $system->error );
is($adddomain->{'pending'}, '', 'Sem pendencias') or diag($adddomain->{'pending'});
#poll and poll ack
my $result;
do {
	$result = $system->poll_get;
	if ($result->{'id'}) {
		#tem q pegar cada item dentro da mensagem
		diag($result->{'id'}.' = '.join(', ',$result->{'text'}));
		diag($result->{'count'});
		$system->poll_ack($result->{'id'});
	}
} while ($result->{'count'} > 0);
#Dados do dominio criado
diag('Dominio: '.$system->service('dominio'));
diag('Ticket: '.$system->service('dados','Ticket'));

die $system->response->serialize(2);
#Dados de CIDBR 

#	$system->availdomain;
#	$system->addcontact unless $system->availcontact;
#	$system->addorg unless $system->availorg;
#	$system->nameservers;#definir lista de nameserver
#	$system->adddomain;

1;
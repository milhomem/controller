#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008
package Controller::Services;

require 5.008;
require Exporter;
use Controller;
use Controller::HelpDesk;

use vars qw(@ISA $VERSION);

@ISA = qw(Controller Controller::HelpDesk);
$VERSION = "0.3";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	#Depende do Controller
	my $controller = new Controller( @_ );
	%$self = (
		%$controller,
	);
	
	bless($self, $class);

	return $self;
}

sub create_service {
	my ($self) = shift;
	return if $self->error;
	
	$self->execute_sql(qq|DELETE FROM `cancelamentos` WHERE `servid` = ?|,$self->sid);
	$self->execute_sql(qq|UPDATE `servicos` SET `status` = 'A', `action` = 'N', `servidor` = ?, `inicio` = ?, `useracc` = ?, `fim` = DEFAULT WHERE `id` = ?|,$self->srvid,$self->calendar('datemysql'),$self->service('useracc'),$self->sid);
	#Multiserver if Windows Helm
	if ($self =~ /Helm/i) {
		$self->execute_sql(qq|REPLACE INTO `servicos_set` VALUES (?,?,?,?,?,?,?)|,$self->sid,$self->service('MultiWEB'),$self->service('MultiDNS'),$self->service('MultiMAIL'),$self->service('MultiFTP'),$self->service('MultiSTATS'),$self->service('MultiDB'));
	}
	
	return $self->error ? 0 : 1;
}

sub grade_service {
	my ($self) = shift;
	return if $self->error;
	
	$self->execute_sql(qq|UPDATE `servicos` SET `action` = 'N' WHERE `id` = ?|,$self->sid);
	
	return $self->error ? 0 : 1;
}

sub suspend_service {
	my ($self) = shift;
	return if $self->error;
	
	my $status = $_[0] ? $self->SERVICE_STATUS_CONGELADO : $self->SERVICE_STATUS_BLOQUEADO;
	$self->execute_sql(qq|UPDATE `servicos` SET `status` = ?, `action` = 'N' WHERE `id` = ?|,$status,$self->sid);
	
	return $self->error ? 0 : 1;
}

sub remove_service {
	my ($self) = shift;
	return if $self->error;
	
	$self->execute_sql(qq|UPDATE `servicos` SET `fim` = ?, `status` = 'F', `action` = 'N' WHERE `id` = ?|,$self->calendar('datemysql'),$self->sid);
	
	return $self->error ? 0 : 1;
}

sub activate_service {
	my ($self) = shift;
	return if $self->error;
	
	$self->execute_sql(qq|UPDATE `servicos` SET `status` = 'A', `action` = 'N' WHERE `id` = ?|,$self->sid);
	
	return $self->error ? 0 : 1;
}

sub insert_data {
	my $self = shift;

	$self->{'_modservice'}{'ins_data'}{$_[0]} = $_[1] if exists $_[1];
	
	return $self->{'_modservice'}{'ins_data'}{$_[0]};
}

sub insert {
	my $self = shift;
	return if $self->error;

	$self->uid(insert_data($self,'username'));
	$self->pid(insert_data($self,'plano'));
	$self->srvid(insert_data($self,'servidor'));
	$self->payid(insert_data($self,'pg'));
	
	insert_data($self,'servidor', $self->num($self->setting($self->plan('plataforma').$self->plan('tipo')))) if !$self->is_valid_server(insert_data($self,'servidor'));
	insert_data($self,'parcelas',1) if insert_data($self,'parcelas') < 1;
	
	return $self->set_error("Plataforma do servidor inválida para o Plano") if $self->plan('plataforma') ne $self->OS($self->server('os')) && $self->srvid != 1;#exclui-se quando nao se tem servidor 
	return $self->set_error("Username inválido") unless $self->is_valid_user($self->uid);
	return $self->set_error("Plano inválido") unless $self->is_valid_plan($self->pid);
	return $self->set_error("Prazo inválido")  unless $self->is_valid_payment($self->payid);
	
	insert_data($self,'lock',0) unless insert_data($self,'lock');

	$sth = $self->select_sql(786,insert_data($self,'plano'),insert_data($self,'dominio'));
	if ($sth->rows != 0 and $self->finish) { 
		return $self->set_error($self->lang(307,insert_data($self,'plano'),insert_data($self,'dominio')));
	}

	insert_data($self,'desconto',0) unless insert_data($self,'desconto');
	
	#auto_create 0-no 1-yes 2-wait 3-free 4-free+wait #retirei pq agora o usuario tem opcao de usar ou nao o credito
	# 40-credito|no  42-credito|wait	
	my $credit = 0;
	my $valor = 0;
	if (insert_data($self,'useCredit')) {
		$credit = $self->credit_sum;
		#Simular um serviço
		$self->sid(-999999);
		$self->service('desconto',insert_data($self,'desconto'));
		#consulta credito, já não comprometidos *precavendo solicitacoes sucessivas sem credito
		$valor = $self->parcela; #parcela com descontos
		$valor += $self->plan('setup') if insert_data($self,'property2') == 1;
		insert_data($self,'activate',$credit && sprintf($self->accuracy,$credit) >= sprintf($self->accuracy,$valor) ? 1 : insert_data($self,'activate'));
	}
	
	my ($status, $action);
	if (insert_data($self,'activate') == 1) {
		$action = 'C';
		$status = 'S';
	} elsif (insert_data($self,'activate') == 0) {
		$action = 'N';
		$status = 'F';
	} elsif (insert_data($self,'activate') == 2) {
		$action = 'N';
		$status = 'S'; 		
	} elsif (insert_data($self,'activate') == 3 && insert_data($self,'property1') > 0) { #1 - dias gratis
		$action = 'C';
		$status = 'S';
	} else {
		return "Opção auto_c inválida: ".insert_data($self,'activate');
	}
	
	my $sid = $self->execute_sql(743,insert_data($self,'username'),insert_data($self,'dominio'),insert_data($self,'plano'),$status, insert_data($self,'inicio')||DEFAULT, insert_data($self,'fim')||DEFAULT, insert_data($self,'vencimento')||DEFAULT,insert_data($self,'proximo')||DEFAULT,
		insert_data($self,'servidor'),insert_data($self,'dados'),insert_data($self,'useracc'),insert_data($self,'pg'),insert_data($self,'envios'),insert_data($self,'def'),$action,insert_data($self,'pagos'),insert_data($self,'desconto'),
		insert_data($self,'lock'),insert_data($self,'parcelas'),insert_data($self,'notes')) if insert_data($self,'username');
	$self->sid($sid);
					
	if (sprintf($self->accuracy,$credit) && sprintf($self->accuracy,$valor) > 0) {#converte crédito em saldo
		my $dif = sprintf($self->accuracy,$credit) > sprintf($self->accuracy,$valor) ? $valor : $credit;
		$self->credit_use($dif,$self->lang(78,$sid,insert_data($self,'dominio')));
	}
	
	$self->execute_sql(821,$sid,insert_data($self,'property1'),1) if insert_data($self,'property1') > 0;#1 - dias gratis	
	$self->execute_sql(821,$sid,1,2) if (insert_data($self,'property2') == 0);#2 - Sem setup			
	$self->execute_sql(821,$sid,1,4) if (insert_data($self,'property4') == 1);#4 - Vencimento Independente			
	$self->execute_sql(821,$sid,insert_data($self,'property5'),5) if (insert_data($self,'property5') > 0);#5 - dias para finalizar
	$self->execute_sql(821,$sid,1,6) if (insert_data($self,'property6') == 1);#6 - Fatura Exclusiva			
	
	my %properties = insert_data($self,'properties');
	foreach my $type (keys %properties) {
		$self->execute_sql(821,$sid,$properties{$type},$type) if $properties{$type};
	}
	
	die $self->error if $self->error;
		
	#Se não for um serviço criado automático abrir um ticket	
	if (insert_data($self,'activate') == 0 && $self->staffid && $self->staff('admin') != 1) {
		$self->ticket_new($self->TICKETS_METHOD_SYSTEM, $self->TICKETS_OWNER_SYSTEM, undef, "Comercial", 
			"Solicitação de Serviço", 
			"Solicito a aquisição deste serviço.", 
			"Serviço cadastrado como finalizado, altere o serviço para ativá-lo.", 
			$self->HIDDEN, $self->setting('dpriS'));
	}
	
	return $self->sid;
}

sub save {
	my $self = shift;
	return if $self->error;
	
	my $service = $self->service;
	
	my (@columns,@set,@where,@wherev);
	my $planChanged = 0;
	foreach my $column ($self->service('changed')) {
		next if $column =~ m/^_/; #remove local extras columns
		
		#bool
		$planChanged = 1 if $column eq 'servicos' || $column eq 'dominio';
		
		push @columns, $column;
		if ($column eq 'dados') {
			my %dados = %{ $self->service($column) };
			my $dados = "";
			foreach my $col (keys %dados) {
				$dados .= "$col : $dados{$col}::";
			}
			push @set, $dados;
		} else {
			push @set, $service->{"$column"};
		}
	}
	push @where, 'id';
	push @wherev, $self->sid;
	
	#Não pode alterar o plano para o mesmo de um dominio que já existe com esse plano.
	if ($planChanged) {
		$sth = $self->select_sql(786,$service->{'servicos'},$service->{'dominio'});
		if ($sth->rows != 0 and $self->finish) { 
			die $self->set_error($self->lang(307,$service->{'servicos'},$service->{'dominio'}));
		}
	}
	
	$self->SUPER::save($self->TABLE_SERVICES,\@columns,\@set,\@where,\@wherev);
	$self->service('changed',{});
	$self->unlock_billing;
	
	return $self->error ? 0 : 1;
}

sub service_exec {
	my ($self, $action, $par, $auto_c, $dias, $setup, $touser, $nvalue) = @_;
	$self->set_error($self->lang(300)) and return unless $self->service('status');
	return if $self->error;

	#Liberando recalculos das alteracoes
	$self->unlock_billing;
	#Liberar a ação do cron!
	$self->logcronRemove(4,$self->sid) if ($action !~ m/^(csts|tf)$/);

	if ($action eq "bl" && 
			($self->service('status') eq $self->SERVICE_STATUS_ATIVO || ($self->service('status') eq $self->SERVICE_STATUS_CONGELADO && $par))){
		$self->execute_sql(745,'P',$self->sid) if $par;
		$self->execute_sql(745,'B',$self->sid) if !$par;
		return ("Sucesso");
	}

	if ($action eq "cn" && $self->service('status') ne SERVICE_STATUS_CANCELADO){	
		$self->execute_sql(763,'C',$self->sid);
		$self->execute_sql(820,$self->sid,"$nvalue") if $nvalue ne "";

		my $auto = eval $self->setting('auto_cancel');
		if ($auto->{$self->plan('tipo')} == 1) {
			$self->service_exec('fn');
		} else {
			$self->ticket_new($self,$self->TICKETS_METHOD_SYSTEM, $self->TICKETS_OWNER_SYSTEM, undef, "Comercial", 
				"Solicitação de Cancelamento", 
				"Solicito o cancelamento deste serviço.", 
				"Altere o action para R para que a alteração ocorra.", 
				$self->HIDDEN, $self->setting('dpriS'));
		}
		
		return ("Sucesso");
	}

	if ($action eq "fn" && $self->service('status') ne $self->SERVICE_STATUS_FINALIZADO){
		$self->execute_sql(745,'R',$self->sid);
		return ("Sucesso");
	}

	if ($action eq "at" && 
				($self->service('status') ne $self->SERVICE_STATUS_ATIVO &&  $self->service('status') ne SERVICE_STATUS_SOLICITADO &&  $self->service('status') ne SERVICE_STATUS_FINALIZADO)){
		$self->execute_sql(745,'A',$self->sid);
		return ("Sucesso");
	} 				

	if ($action eq "cr" && $self->service('status') eq $self->SERVICE_STATUS_SOLICITADO) {
		$self->execute_sql(745,'C',$self->sid);
		return ("Sucesso");
	}

	if ($action eq "rcr" && $self->service('status') eq $self->SERVICE_STATUS_FINALIZADO){
		my $credit = $self->credit_sum;
		my $valor = 0;
		if ($self->param('credit')) {
			$self->service('desconto',$self->param('desconto'));
			#consulta credito, já não comprometidos *precavendo solicitacoes sucessivas sem credito
			$valor = $self->parcela; #parcela com descontos
			$valor += $self->plan('setup') if $self->param('property2') == 1;
			$self->param('activate',$credit && $credit >= $valor ? 1 : $self->param('activate')); # : $1
		}
		
		my ($status, $action, $query);
		if ($self->param('activate') == 1) {
			$action = 'C';
			$status = 'S';
			$self->execute_sql(769,$status,$action,'0000-00-00','0000-00-00','0000-00-00',0,0,$self->sid) unless $self->error;
		} elsif ($self->param('activate') == 0) {
			$action = 'N';
			$status = 'F';
			$self->execute_sql(770,'0000-00-00','0000-00-00','0000-00-00',0,0,$self->sid) unless $self->error;
		} elsif ($self->param('activate') == 2) {
			$action = 'N';
			$status = 'S';
			$self->execute_sql(769,$status,$action,'0000-00-00','0000-00-00','0000-00-00',0,0,$self->sid) unless $self->error;	
		} elsif ($self->param('activate') == 3) { #1 - dias gratis
			$action = 'C';
			$status = 'S';
			$self->execute_sql(769,$status,$action,'0000-00-00','0000-00-00','0000-00-00',0,0,$self->sid) unless $self->error;
		} else {
			return "Opção auto_c inválida: $self->param('activate')";
		}		

		if ($credit && $valor > 0) {#converte crédito em saldo
			my $dif = $credit > $valor ? $valor : $credit;
			$self->credit_use($dif,$self->lang(78,$sid,$self->service('dominio')));
		}
		
		$self->insertPropertie(1,$self->param('property1')) if $self->param('property1') > 0;#1 - dias gratis	
		$self->insertPropertie(2,1) if ($self->param('property2') == 0);#2 - Sem setup			
		$self->insertPropertie(4,1) if ($self->param('property4') == 1);#4 - Vencimento Independente			
		$self->insertPropertie(5,$self->param('property5')) if ($self->param('property5') > 0);#5 - dias para finalizar
		$self->insertPropertie(6,1) if ($self->param('property6') == 1);#6 - Fatura Exclusiva	

		die $self->error if $self->error;
		if ($self->param('activate') =~ m/1|0|2|3/) {
			return ("Sucesso");
		}
	}
	
	if ($action eq "tf") {
		$self->service('username',$touser);
		return unless $self->user('status');
		$self->execute_sql(771,$touser,$self->sid);

		return ("Sucesso");
	}
	
	if ($action eq "nd") {
		$self->execute_sql(745,'N',$self->sid);				
		return ("Sucesso");
	}

	if ($action eq "csts") {
		$self->execute_sql(763,"$nvalue",$self->sid);
		return ("Sucesso");
	}
	
	if ($action eq "cact") {
		$self->execute_sql(745,"$nvalue",$self->sid);
		return ("Sucesso");
	}

	return ("Erro");
}

sub remove {
	my $self = shift;
	return $self->set_error($self->lang(3,'Services::remove')), return unless $self->sid;
		
	#Apagando chamados 
	foreach ($self->calls) {
		$self->execute_sql(65,$self->sid);
		$self->execute_sql(381,$self->sid);
	}
	
	$self->execute_sql(341,$self->sid);
	#use Data::Dumper; 
	$self->execute_sql(811,$self->sid);#Cancelamentos
	#die Dumper	$self->{'sql'}{where_cols};
	$self->execute_sql(43,$self->sid);#servicos_set
	$self->execute_sql(822,$self->sid);#promocao
	$self->execute_sql(qq|DELETE FROM `indicates` WHERE `service` = ?|,$self->sid);
	$self->execute_sql(qq|DELETE FROM `saldos` WHERE `servicos` = ?|,$self->sid);
	
	$self->execute_sql(741,$self->sid);
	#Cancelar(Servico($servico,"invoice"));
	
	return $self->error ? 0 : 1;
}

sub removePropertie {
	my $self = shift;
	return $self->set_error($self->lang(3,'Services::removePropertie')) unless $self->sid;
	my $type = shift;
		
	$self->execute_sql(823,$self->sid,$type);
	
	return $self->error ? 0 : 1;	
}

sub insertPropertie {
	my $self = shift;
	return $self->set_error($self->lang(3,'Services::insertPropertie')) unless $self->sid;
	my $type = shift;
	my $value = shift;	
	#types 1 - dias gratis 2 - Sem taxa de setup 3 - Descontos em meses 
	#4 - Nao se orientar pelo vc do usuario 5 - dias para finalizar 6 - fatura exclusiva	
	#7 - Valores +- por mes/ano % ou $
	
	if ($type =~ /^[246]$/) {
		$value = $value == 1
					? 1
					: 0;
	} elsif ($type =~ /^[15]$/) {
		return $self->set_error($self->lang(3,'Services::insertPropertie'))	unless $self->num($value) > 0;	
		$value = $self->num($value);
	} elsif ($type == 7) { #Stringfy
		return $self->set_error($self->lang(3,'Services::insertPropertie'))	unless ref $value eq 'HASH';
		$value = Controller::tostring($value); #Storable?
	}
	
	$self->execute_sql(825,$self->sid,$value,$type);
	
	return $self->error ? 0 : 1;	
}
1;
__END__
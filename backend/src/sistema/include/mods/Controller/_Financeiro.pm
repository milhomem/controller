#!/usr/bin/perl         
# Use: Internal
# Controller - is4web.com.br
# 2007 - 2008
package Controller::_Financeiro;

require 5.008;
require Exporter;
use Controller;
use Controller::Services;

use vars qw(@ISA $VERSION %SWITCH);

push @ISA, qw(Controller::Services Controller Exporter);

$VERSION = "0.6";
=pod
########### ChangeLog #######################################################  VERSION  #
=item operator == >= <= != > <												#			#
- Added	float accuracy						                                #   0.3     #
=item diaria, parcela														#			#
- Discounts can be negatives (-) increasing amounts                         #   0.4     #
=item faturar_service														#			#
- Undefine _desconto so it dont generate a cache mess                       #   0.4     #
=item valorProrrogado														#			#
- Added													                    #   0.4     #
=item prorate																#			#
- Corrigido bug de inversão de data						                    #   0.5     #
=item vcto_adjust															#			#
- Corrigido bug de usuario vindo da fatura				                    #   0.6     #
#############################################################################           #
=cut
$SWITCH{prazo_force} = 0;
  
sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	#Depende do Controller
	my $inherit = new Controller( @_ );
	push @ISA, @Controller::ISA; #Inherit ISA
		
	my $self = {
		%$inherit,
	};
	
	$SIG{'__DIE__'} = sub { $self->traceback($_[0]); }; #Manter a referencia do DIE
	
	bless($self, $class);
	
	return $self;
}

sub change_plan {
	my ($self) = shift;

	return $self->set_error($self->lang(3,$self->sid)) unless $self->sid; #Precisa de servico
	return $self->set_error($self->lang(303, $self->dateformat($self->service('vencimento')))) if !$self->service('vencimento') && $self->service('inicio') && !$self->serviceprop(1);
	return $self->set_error($self->lang(640,$self->payid)) unless $self->payment('pintervalo') > 0;
	
	my $vbf = $self->parcela;	
	$self->service('servicos',$self->num($_[0]));
	my $sid = $self->sid;
	return $self->set_error($self->lang(1002)) unless $self->is_valid_plan($self->pid); #Plano não encontrado, tira referência
	$self->sid($sid);
 	my $vaf = $self->parcela;
	my $v=($vaf-$vbf); #diferença na parcela
	my $vnc = $self->service('inicio') + $self->serviceprop(1) if $self->serviceprop(1);
	my $dd = $self->service('vencimento') - $self->today;
	return $self->set_error($self->lang(304)) if $dd < 0;
	$dd = 0 if $dd <= $self->setting('altplan'); #Zera adicionais #VARIABILIDADE - DIAS CONCEDIDOS AOS CLIENTES MUDAREM O PLANO SEM ADICIONAIS
	$dv = $v/$self->payment('pintervalo');
	
	my $mm = int($dd/30);#Quantidade de meses
 	$mm++ if $dd > $self->setting('altplan');# 1 mes a mais caso tenha passado dos dias gratuitos
 	
	$vadd = $dd * $dv; #dias cobrados
	$vadd = $mm * ($v*30/$self->payment('pintervalo')) if $self->setting('altmes') == 1;#só meses, sem proporcional
	$vadd = 0 if sprintf($self->accuracy,$vadd) < 0 && $self->setting('altcredito') == 0;#permitir credito na alteracao
	$vadd *= -1;#Invertendo valor, saldo negativo é débito
	
	return $vadd;
}

sub prazo {
	my ($self) = shift;
	my $vencimento = $_[0] || $self->service('vencimento');
	
	return $self->set_error($self->lang(640,$self->payid)) unless $self->payment('intervalo') > 0;
	return $self->set_error($self->lang(640,$self->payid)) if $self->payment('repetir') == 1 && $self->payment('pintervalo') != $self->payment('intervalo');#Se repete o pintervalo tem q ser igual ao intervalo 	
	$self->set_error($self->lang(40)) and return if ($self->service('status') eq $self->SERVICE_STATUS_CANCELADO || $self->service('status') eq $self->SERVICE_STATUS_FINALIZADO || !$self->service('status'));
	
	# Faturas multiplas, gerar fatura mesmo com fatura existente
	if ($self->setting('invoices') == 1 && $self->service('invoice')) {
		local $Controller::SWITCH{skip_error} = 1; #A fatura pode ser inválida
		$self->invid($self->service('invoice'));
	 	$self->service('invoice',0) if (!$self->invoice('data_vencimento') || $self->invoice('data_vencimento') < $self->today());
	}
	
	unless ($self->service('invoice') > 0 && !exists $_[0]) {#precisa não ter fatura pra gerar outra
		unless ($self->service('fim')) { #ou seja não está finalizado
			unless ($vencimento) { #vencimento inicial
				$self->set_error($self->lang(41,$self->sid,$self->service('pagos'))) and return if $self->service('pagos') > 0;

				if ($self->postecipado && $self->payment('primeira') == 0) { #(postecipado ou normal sem primeira)
					$self->service('proximo',
						$self->somames(\$self->today,$self->payment('pintervalo')/30) );
						$self->save;
						return 0;
				} else { #(antecipado ou normal com primeira)					
					my $primeira = $self->payment('primeira');
					$self->service('proximo',
							$self->somames(\$self->today, $primeira ? $primeira/30 : 0) );
					return 1;
				}
			} else {
				if ($self->service('pagos') >= $self->service('parcelas') && $self->payment('repetir') == 0) { #fim de parcelas
					#como nao repete o pagos tem que ser o original				
					return 0;
				} 
				#verificar quanto tempo falta para o vencimento				 
				my $resto = $vencimento - $self->today;				
				# vencido a intervalo - dias antecedentes ou a vencer dias antecedentes
				if ( (($self->setting('dias_antes')-$self->payment('pintervalo')) >= $resto && $self->setting('invoices') == 1) #multiplas faturas
						|| ($self->setting('dias_antes') >= $resto && $self->setting('invoices') != 1) || defined $_[0] || $Controller::Financeiro::SWITCH{prazo_force}) {#tempo hábil para cobrança		
					$self->service('proximo',undef);#Redefinir pois está calculando justamente o proximo
vencido:
					my $inter = $self->payment('repetir') == 1 #Se repete o pintervalo tem q ser igual ao intervalo 
										? $self->payment('intervalo')
										: $self->service('pagos') + 1 == $self->service('parcelas') #Próximo é a última parcela 
											? $self->payment('intervalo') - $self->service('primeira') - ($self->service('pagos') * $self->payment('pintervalo'))
											: $self->payment('pintervalo');
											
					my $proximo = $self->somames(\$vencimento,$inter/30);#security
					die 'Fatal Error '.$self->sid.' proximo '.$proximo if ($self->service('proximo') eq $proximo && !defined $_[0]); 
					$self->service('proximo', $proximo);
					#segurança para não resultar em venc_new vencido
					if ($self->service('proximo') < $self->today) {
						$self->service('vencimento',$self->service('proximo'));
						$vencimento = $self->service('proximo');
						goto vencido;
					}
					return 1;
				} else { #não cobrar				
					return 0;
				} 
			}
		} 	
	}
	return 0;	
}

sub faturar {
	my ($self) = shift;
	return if $self->error;
	
	#per user
	return unless $self->uid;
	
	$self->{_faturar} = undef; #Cache para esta fatura
	#Gerar só saldo apenas quando for solicitado;
	$self->{_faturar}{saldo} = $_[1];
	
	my @sids = scalar @{$_[0]} ? @{$_[0]} : $self->services; #Serviços escolhidos ou todos os servicos
	
	$self->plans; #Cache info de todos os planos deste usuário 
	$self->servicesprop(@sids) if scalar @sids; #Cache das propriedades dos serviços  
	
	my @rsids; #serviços que serão processados
	my $oldsid = $self->sid; #Guardando sid antigo
	foreach (@sids) { #Escolher serviços a incluir na fatura
		next unless $_;
		$self->sid($_);				
		
		if (!$self->is_valid_payment($self->payid) || !$self->is_valid_plan($self->pid)) {
			$self->set_error($self->lang(306,'Financeiro.pm line 206.'));
		}

		if (!$self->error && $self->prazo) { #Determina se o serviço será faturado
			$self->split_invoice; #separar faturas
			next unless $self->vcto_service;
			$self->vcto_fatura($self->vcto_service); #Definindo que o vencimento da fatura será igual a deste serviço
			$self->referencia($self->vcto_fatura);
			#Redefinindo o vencimento do servico
			#Normalmente o prazo calculado sera o proximo pagamento
			$self->vcto_adjust($self->vcto_fatura); #Ajustando o proximo vencimento			
			push @rsids, $self->faturar_service unless $self->error; #Finaliza
			$self->next; #go next if necessary
		} else {
			#Determina se houve algum erro
			$self->logcron($self->lang(306,$self->clear_error),6) if $self->error;
		}    
	}
	$self->sid($oldsid);
	
	if ($self->{_faturar}{saldo} && !$self->vcto_fatura) {
		$self->vcto_fatura($self->today + $self->setting('dias_prorrogado'));
		$self->referencia($self->vcto_fatura);
	}
	
	my $inv = $self->faturar_process(@rsids);
	
	return wantarray ? ($inv,\@rsids) : $inv;
}

sub balances_update {
	my ($self,@balances) = @_;
	die if $self->error;
	
	foreach (@balances){
		$self->execute_sql(446,$self->invid,$_);
	}
}

sub services_update {
	my ($self,@sids) = @_;
	die if $self->error;

	my $oldsid = $self->sid;
	foreach (@sids){
		$self->sid($_);
		$self->service('invoice',$self->invid);
		$self->execute_sql(757,$self->service('proximo'),$self->invid,$self->sid);
	}

	$self->sid($oldsid);
}

sub services_add {
	my ($self,@sids) = @_;
	die if $self->error;
	
	return $self->set_error($self->lang(3,'services_add')) unless $self->invoice('status') ne 'Q' && $self->invoice('status') ne 'D';

	my @services;
	foreach (keys %{ $self->invoice('services') }) { #get
		push @services, $self->invoice('services', $_)."x".$_;
	}
	my $oldsid = $self->sid;
	foreach (@sids){ #add
		next unless $_;
		$self->sid($_);
		next if $self->service('invoice') > 0;
		if ($self->prazo) {
			$self->vcto_adjust($self->invoice('data_vencimento'));
			$self->invoice('services', $_, $self->service('pg'));
			push @services, $self->service('pg')."x".$self->sid;
			$self->service('invoice',$self->invid);
			$self->execute_sql(757,$self->service('proximo'),$self->invid,$self->sid);
		} else {
			#Determina se houve algum erro
			$self->logcron($self->lang(306,$self->clear_error),6) if $self->error;
			next;
		}
	}
	$self->execute_sql(487,join(' - ',@services).' -',$self->invid);
	$self->sid($oldsid);
	
	return 1;
}

sub faturar_process {
	my ($self,@sids) = @_;
	return if $self->error;
	
	#Saldos
	my @balances = $self->faturar_balance(@sids); #Gera os saldos
	#Servicos
	my $oldsid = $self->sid;
	foreach $sid (@sids) {
		next unless $sid;
		$self->sid($sid);
		$self->{_faturar}{services} .= $self->service('pg') ."x$sid - ";
	}#Ao sair vai deixar o sid selecionado
	$self->sid($oldsid);
		
	my $subj = $self->referencia;
	my $nomeinv = $self->lang(60,$subj->{'monthname'},$subj->{'year'},$subj->{'month'}) if $subj;
	my ($inv);
	if (sprintf($self->accuracy,$self->{_faturar}{total}) >= sprintf($self->accuracy,$self->setting('minimo'))) {
		$self->{_faturar}{referencia} .= $self->lang(49,$self->lang('f_credit'),$self->lang('f_debit'));		
		$inv = $self->create_invoice($self->INVOICE_STATUS_PENDENTE,$nomeinv,$self->vcto_fatura,DEFAULT,$self->{_faturar}{referencia},$self->{_faturar}{services},$self->{_faturar}{total}, NULL) if sprintf($self->accuracy,$self->{_faturar}{total}) != 0;
		$self->invid($inv);
		$self->services_update(@sids);
		$self->balances_update(@balances);	
	} elsif ($self->{_faturar}{services} || ($self->{_faturar}{saldo} && sprintf($self->accuracy,$self->{_faturar}{total}) > 0)) {#BUGFIX adicionado o elsif e else será undef #BUG gera faturas zeradas sempre
		my $saldo = $self->{_faturar}{total} * (-1); #O valor restante se for negativo irá virar saldo, por isso deve inverter
		$coud = sprintf($self->accuracy,$saldo) > 0 ? $self->lang('f_credit') : $self->lang('f_debit');										
		$self->{_faturar}{referencia} .= Controller::cut_string( $self->lang(61, $coud, $self->Currency(abs $saldo)),$self->lang('dots'),73,$self->Currency(abs $saldo) );		
		$self->{_faturar}{referencia} .= "\n".$self->lang(49,$self->lang('f_credit'),$self->lang('f_debit'));	
		$inv = $self->create_invoice($self->INVOICE_STATUS_PENDENTE,$nomeinv,$self->vcto_fatura,DEFAULT,$self->{_faturar}{referencia},$self->{_faturar}{services},0, NULL);
		$self->invid($inv);
		$self->services_update(@sids);
		$self->balances_update(@balances);		
		$self->pay_invoice(0, $self->today, 1);
		$self->create_balance($saldo, $self->lang(83)) if sprintf($self->accuracy,$saldo) != 0;	
	}
	
	return $inv;
}

sub create_balance {
	my ($self) = shift;
	die if $self->error;
	
	$self->set_error($self->lang(3,'create_balance')) and return unless $self->uid;
	
	return $self->execute_sql(445,$self->uid,$_[0],$_[1],$_[2],$_[3]);	
}

sub create_invoice {
	my ($self) = shift;
	die if $self->error;
	
	$self->set_error($self->lang(3,'create_invoice')) and return unless $self->uid;
	
	#Added round 2, pois o Currency faz esse arredondamento de 2 casas então para não diferenciar o valor temos que forçar o arredondamento de 2
	return $self->execute_sql(432,$self->uid,$_[0],$_[1],$self->today,$_[2],$_[2],$_[3],DEFAULT,$_[4],$_[5],$_[6],$self->round($_[7],2),DEFAULT,$_[8]||$self->user('conta') || $self->setting('cc'),undef,$_[9]||$self->user('forma')||$self->setting('forma'),$_[10]||1,$_[11]||'S');	
}

sub create_credit {
	my ($self) = shift;	
	die if $self->error;
	return $self->execute_sql(461,$_[0],$_[1],$_[2],$_[3]);
}

sub credit_use {
	my ($self) = shift;
	die if $self->error;
	
	$self->set_error($self->lang(3,'credit_use')) and return unless $self->sid;
	
	my $bid = $self->create_balance($_[0],$_[1]);
	return $self->create_credit($self->uid,-$_[0],$self->lang(78,$self->sid,$self->service('dominio')),$bid);
}

sub faturar_balance {
	my ($self,@sids) = @_;

	my ($vsal,$refer,@bal);
	if (sprintf($self->accuracy,$self->{_faturar}{total}) != 0 || $self->{_faturar}{saldo}) {
		foreach my $bid ($self->balances) {
			$self->balanceid($bid);
			next if $self->balance('servicos') && (scalar @sids != 1 || $sids[0] != $self->balance('servicos')); #Separando faturas de credito
			next if sprintf($self->accuracy,$self->balance('valor')) == 0;
			$vsal += $self->balance('valor');
			my $coud = sprintf($self->accuracy,$vsal) <= 0 ? $self->lang('f_debit') : $self->lang('f_credit');
			$refer .= Controller::cut_string( $self->lang(48, $coud, $self->Currency(abs $self->balance('valor'))),$self->lang('dots'),73,$self->Currency(abs $self->balance('valor')) );
			$refer .= "\n";
			push(@bal,$self->balanceid);
		}			
	}	

	return if sprintf($self->accuracy,$self->{_faturar}{total}) == 0 && sprintf($self->accuracy,$vsal) >= 0;
	$self->{_faturar}{total} -= $vsal; #Saldo sendo crédito concede desconto
	$self->{_faturar}{referencia} .= $refer;

	return @bal;
}

sub diaria {
	my ($self) = @_;
	
	#Desconto temporário
	$self->service('_desconto',$self->service('desconto')) if $self->sid && !$self->service('_desconto');	
	my $val = $self->plan('valor') / ($self->valor(1) == $self->VALOR_U ? $self->payment('pintervalo') : $self->valor(1)); #valor dia
	$val -= $self->service('_desconto') / $self->payment('pintervalo') if $self->sid && $self->service('_desconto');  
	
	return sprintf($self->accuracy,$val) >= 0 ? $val : 0; #nao gerar credito com descontos
}

sub parcela {
	my ($self,$full) = @_;

	#Desconto temporário
	$self->service('_desconto',$self->service('desconto')) if $self->sid && !$self->service('_desconto');
	my $parc = $self->payment('pintervalo') * $self->diaria;
	unless ($full || ($self->sid && $self->service('_desconto')) ) {#se tiver desconto nao dar desconto do plano
		$parc -= $self->plan('descontos');
	}
	
	return $parc;
}

sub faturar_extra {
	my ($self) = shift;
	
	if ($self->service('_extra')) { 
		my $parc = $self->service('_extra') * $self->diaria;
		$coud = sprintf($self->accuracy,$parc) > 0 ? $self->lang('f_debit') : $self->lang('f_credit');
		$self->{_faturar}{total} += $parc;
		return "\n".Controller::cut_string( $self->lang(47, $coud, $self->service('_extra'), $self->plan('tipo'), $self->plan('plataforma'), $self->plan('nome'),$self->service('dominio'),$self->Currency(abs $parc)),$self->lang('dots'),73,$self->Currency(abs $parc));
	}
	return undef;
}

sub faturar_service {
	my ($self) = shift;
	
	my $ref = $self->referencia;
	my $s_desc = $self->serviceprop(3,$ref->{year});
	$self->service('_desconto',$s_desc->{'value'}) if $s_desc->{'months'} =~ m/$ref->{'month'}(,|$)/;
	my $s_prop7 = $self->serviceprop(7);
	my $s_acres = $s_prop7->{$ref->{'year'}}[$ref->{'month'}] if $s_prop7;	

	$self->service('_desconto',$s_acres->{'price'}) if $s_acres && sprintf($self->accuracy,$s_acres->{'price'}) != 0 && $s_acres->{'type'} == 0;
	$self->service('_desconto', $self->parcela(1) * ($s_acres->{'price'}/100)) if $s_acres && sprintf($self->accuracy,$s_acres->{'price'}) != 0 && $s_acres->{'type'} == 1;

	$self->{_faturar}{total} += $self->parcela; #se tiver desconto nao aplica desconto do plano
	my $coud = sprintf($self->accuracy,$self->{_faturar}{parcela}) > 0 ? $self->lang('f_debit') : $self->lang('f_credit');
	my $refer = $self->lang(42, $coud, $self->plan('tipo'), $self->plan('plataforma'), $self->plan('nome'), $self->service('dominio'), $self->Currency($self->parcela(1))); 
	$refer = $self->lang(43, $coud, $self->plan('tipo'), $self->plan('plataforma'), $self->plan('nome'), $self->service('dominio'), $self->Currency($self->parcela(1)), $self->payment('pintervalo') / 30) if sprintf($self->accuracy,$self->payment('pintervalo') / 30) > 1;
	$refer = Controller::cut_string( $refer,$self->lang('dots'),73,$self->Currency($self->parcela(1)) );
	$refer .= "\n". Controller::cut_string( $self->lang(44,$self->lang('f_credit'),$self->Currency($self->plan('descontos'))),$self->lang('dots'),73,$self->Currency($self->plan('descontos')) ) if sprintf($self->accuracy,$self->plan('descontos')) != 0;			
	
	$refer .= $self->faturar_extra;
	
	$self->{_faturar}{total} += $self->plan('setup') if !$self->service('vencimento') && $self->serviceprop(2) != 1;
	$coud = sprintf($self->accuracy,$self->plan('setup')) > 0 ? $self->lang('f_debit') : $self->lang('f_credit');
	$refer .= "\n".Controller::cut_string( $self->lang(45,$self->lang('f_credit'),$self->Currency(abs $self->plan('setup'))),$self->lang('dots'),73,$self->Currency(abs $self->plan('setup')) ) if (sprintf($self->accuracy,$self->plan('setup')) != 0 && !$self->service('vencimento') && $self->serviceprop(2) != 1);
	$self->{_faturar}{referencia} .= $refer."\n";

	#Desconto apagado, deve ser memorizado novamente
	$self->service('_desconto',undef);
	
	return $self->sid;
}

sub servicos_ativos {
	my ($self) = shift;
	
	my $sid = $self->sid;
	my $a=0;my @sids;
	foreach ($self->services) {
		$self->sid($_);
		if ($self->service('status') && $self->service('status') ne $self->SERVICE_STATUS_FINALIZADO &&
		$self->service('status') ne $self->SERVICE_STATUS_SOLICITADO &&
		$self->service('vencimento') && $_ != $sid) {
			push @sids, $_;
			$a++ if $self->plan('tipo') ne 'Registro';
		} 
	}
	$self->sid($sid) if $sid;
	
	return wantarray ? @sids : $a;
}

sub vcto_adjust {
	my ($self,$vcto_atual) = @_;
	return if $self->error;
	
	die $self->lang(3,'vcto_adjust') unless $vcto_atual;
	
	my $extra;
	if ($self->service('vencimento') && $self->payment('repetir') == 1 && $self->payment('pintervalo') >= 30 ) { #agir somente com casos ciclicos
		if ($self->plan('tipo') eq 'Registro' || $self->serviceprop(4) == 1) { 
			#Nao alinhar vencimento
		} elsif ( int $self->user('vencimento') > $vcto_atual->day && $vcto_atual == $self->diames($vcto_atual->year,$vcto_atual->month,31) ) {
			$self->service('proximo', $self->diames($vcto_atual->year,$vcto_atual->month,$self->user('vencimento')));			
		} else {
			#Ajustar o vencimento para o vencimento do usuário
			$venc_proximo = $self->diaproximo(int $self->user('vencimento'),\$self->service('proximo'));			
			if ($self->service('inicio')) {
				$extra = $venc_proximo - $self->service('proximo');				
				$self->service('_extra',$extra);
			}
			$self->service('proximo',$venc_proximo);
		}
	} elsif (!$self->service('vencimento') && $self->payment('repetir') == 1 && $self->payment('pintervalo') >= 30) {
		unless ($self->prazo($self->service('proximo')) ) {#force
			#Determina se houve algum erro
			$self->logcron($self->lang(306,$self->clear_error),6) if $self->error;
			return;
		}
		 
		if ($self->plan('tipo') eq 'Registro' || $self->serviceprop(4) == 1) {
			#do nothing
		} elsif ($self->servicos_ativos) {
			$venc_proximo = $self->diaproximo(int $self->user('vencimento'),\$self->service('proximo'));
			if ( $self->user('vencimento') < $self->diames($vcto_atual->as_ymd)->day || $vcto_atual != $self->diames($vcto_atual->as_ymd)) {
				$extra = $venc_proximo - $self->service('proximo');						
			}
			$self->service('proximo',$venc_proximo);
		} else {
			$self->execute_sql(675,$vcto_atual->day,$self->uid()) unless $self->user('vencimento') > 0;
		}
	} else {
		if (!$self->service('vencimento')) {
			unless ($self->prazo($self->service('proximo')) ) {#force
				#Determina se houve algum erro
				$self->logcron($self->lang(306,$self->clear_error),6) if $self->error;
				return;
			}
			
		}
	}
	$self->service('_extra',$extra);

	return $self->service('proximo');
}

sub vcto_fatura {
	my ($self) = shift;
	return $self->{_faturar}{vencimento} = $_[0] if exists $_[0];
	return $self->{_faturar}{vencimento};
}

sub vcto_service {
	my ($self) = shift;#Precisa de prazo e faturar
	return $self->{_faturar}{$self->sid}{vencimento} if $self->{_faturar}{$self->sid}{vencimento};
	
	#configurando vencimento da fatura
	if (!$self->service('vencimento')){#Servico novo
		$self->{_faturar}{$self->sid}{vencimento} = $self->service('proximo');
		if ($self->serviceprop(1)) {#Dias gratis
			if ($self->service('inicio') && $self->service('status') eq $self->SERVICE_STATUS_ATIVO) {
				$self->save;
			} else {
				$self->logcron($self->lang(66),1) if $self->service('status') eq $self->SERVICE_STATUS_ATIVO;
				$self->gonext;
			}
		}
	} elsif ($self->setting('invoices') == 1) {
		$self->{_faturar}{$self->sid}{vencimento} = $self->service('proximo');
		$self->service('_extra',$self->service('proximo') - $self->service('vencimento'));
	} else {
		$self->{_faturar}{$self->sid}{vencimento} = $self->service('vencimento');
	}
		
	return $self->{_faturar}{$self->sid}{vencimento};
}

sub split_invoice {
	my ($self) = @_;

	if ($self->vcto_fatura) { #serviços seguintes
		#separando invoices com propriedade 6 - fatura exclusiva
		next if $self->serviceprop(6) == 1; #pula imediatamente
		#separando invoices de vencimentos diferentes
		next if $self->vcto_fatura != $self->vcto_service;
		#separando invoices de saldos creditados		
		next if $self->servicebalances;	
	} else { #primeiro servico da fatura
		$self->golast if 
				$self->serviceprop(6) == 1
				|| $self->servicebalances
				;#sai do loop logo apos este
	}
}

sub postecipado {
	my ($self) = shift;
	return $self->payment('parcelas') == 1 ? 1 : 0;
}

sub referencia {
	@_=@_;
	my ($self) = shift;
	return $self->{'referencia'} unless exists $_[0];
	
	if ($_[0]) {
		$self->{'referencia'} = undef;
		$self->{'referencia'}{'month'} = $self->sid ? $_[0]->month - $self->postecipado : $_[0]->month;
		$self->{'referencia'}{'year'} = $_[0]->year;
		$self->{'referencia'}{'year'} -= 1 if ($self->{'referencia'}{'month'} < 1);
		$self->{'referencia'}{'monthname'} = $self->monthname($self->{'referencia'}{'month'}-1);
	}
	
	return $self->{'referencia'};
}

sub paidService {
	my $self = shift;
	
	if ($self->service('status') =~ m/^(?:${\$self->SERVICE_STATUS_BLOQUEADO}|${\$self->SERVICE_STATUS_CONGELADO}|${\$self->SERVICE_STATUS_CANCELADO})$/) {
		$self->service_exec('at');	
	} elsif ($self->service('status') =~ m/^(?:${\$self->SERVICE_STATUS_ATIVO}|${\$self->SERVICE_STATUS_TRAFEGO}|${\$self->SERVICE_STATUS_ESPACO})$/) {
        if ($self->setting('auto_renew') == 1 && $self->service('status') eq $self->SERVICE_STATUS_ATIVO && $self->plan('tipo') eq 'Registro' && $self->service('pagos') > 0) { 
            $self->execute_sql(745,'A',$self->sid);
        } else {		
            $self->service_exec('nd');
        }
		$self->logcron($self->lang(1),5,$self->invid) if $self->invoice('status') eq $self->INVOICE_STATUS_CONFIRMATION; #Bom uso = 1
	} elsif ($self->service('status') eq $self->SERVICE_STATUS_SOLICITADO && $self->staffid && $self->staff('admin') == 1) {
		$self->service_exec('cr');
	} elsif ($self->service('status') eq $self->SERVICE_STATUS_FINALIZADO && $self->staffid && $self->staff('admin') == 1) {
		$self->param('activate',1);
		$self->service_exec('rcr');
	}
}

sub confirm_invoice {	
	my $self = shift;
	
	if ($self->invoice('status') eq $self->INVOICE_STATUS_PENDENTE) {
		#Exporting vars
		$self->template($_,$self->user($_)) foreach qw(name endereco numero cidade estado cep empresa);
		$self->template('nome',$self->user('name'));
		$self->template('user',$self->setting('users_prefix').'-'.$self->invoice('username'));
		$self->template('cpf',Controller::frmtCPFCNPJ($self->user('cpf')));
		$self->template('cnpj',Controller::frmtCPFCNPJ($self->user('cnpj')));
		$self->template('invoice',$self->invid);
		$self->template('linkuser',$self->setting('baseurl').'/admin.cgi?do=viewuser&user='.$self->invoice('username'));
		$self->template('linkinv',$self->setting('baseurl').'/admin.cgi?do=viewinvoice&id='.$self->invid);		
		
		foreach (keys %{ $self->invoice('services') }) {
			$self->sid($_);
			next unless $self->is_valid_service($self->sid); #CUIDADO, tira referencias
			next if $self->service('invoice') && $self->service('invoice') != $self->invid;
			
			#Exporting vars	
			$self->template('invoice',$self->service('dominio'));
			$self->template('sid',$self->sid);
											
			$self->paidService unless $self->plan('tipo') eq 'Registro';
			if ($self->service('status') =~ m/^(?:${\$self->SERVICE_STATUS_BLOQUEADO}|${\$self->SERVICE_STATUS_CONGELADO}|${\$self->SERVICE_STATUS_CANCELADO})$/) {
				$self->logcron($self->today,5,$self->invid) unless $self->staffid || !$self->invid; #Inicialmente é bom uso = today para exibir no sistema
			}			
			
			return 0, $self->set_error($self->lang(72)) unless $self->service('proximo');
 											
			unless ($self->service('vencimento')) {
				$self->execute_sql(751,$self->service('proximo'),$self->sid);
				$self->service('vencimento',$self->service('proximo'));
			}
			
			if ($self->service('vencimento') <= $self->today()) {
				my $diasextras = $self->setting('dias_confirmado');
				my ($pdate,$bdate,$rdate) = $self->exec_dates;  
				my $date = $pdate || $bdate || $self->today();
				my $def = $self->today() - $date + $self->service('def');				
				$def = $def < $diasextras * -1 ? 0 : $def + $diasextras;
				$def = 0 if !$self->service('vencimento') && !$self->serviceprop(1) && !$self->serviceprop(5);
				$self->execute_sql(744,$def,$self->sid); #Set def
				$self->service('def',$def);
			}

			$self->messages( To => $self->setting('contas'), From => $self->setting('adminemail'), Subject => ['sbj_renew',$self->service('dominio')], txt => "renew" ) if ($self->setting('auto_renew') != 1 && $self->plan('tipo') eq 'Registro' && $self->staffid && $self->staff('admin') == 1);
			$self->nice_error() if $self->error;			
		}		
		$self->execute_sql(478,$self->INVOICE_STATUS_CONFIRMATION,$self->invid);		
	}
	return 0, $self->set_error($self->lang(65,$self->invid)) unless $self->invoice('status');
	return 1;
}
		
sub pending_invoice {
	my $self = shift;
	
	if ($self->invoice('status') eq $self->INVOICE_STATUS_CONFIRMATION) {		
		foreach (keys %{ $self->invoice('services') }) {
			$self->sid($_);
			next unless $self->service('status');
			next if $self->service('invoice') && $self->service('invoice') ne $self->invid;

			#falta definir dias com variaveis
			if ($self->service('vencimento') && $self->service('vencimento') <= $self->today()) {
				$self->execute_sql(744,$self->service('def') + $self->setting('dias_confirmado'),$self->sid);
			}	  
		}									

		$self->execute_sql(478,$self->INVOICE_STATUS_PENDENTE,$self->invid);
	}
	return 1;
}
		
sub cancel_invoice {
	my $self = shift;
	
	if ($self->invoice('status') && $self->invoice('status') ne $self->INVOICE_STATUS_QUITADO) {					
		foreach (keys %{ $self->invoice('services') }) {
			$self->sid($_);
			next unless $self->service('status');
			next if $self->service('invoice') && $self->service('invoice') ne $self->invid; 

			$self->service('invoice', undef);
			$self->execute_sql(768,undef,$self->sid,$self->invid); #zerando invoice
		}
		$self->execute_sql(447,$self->invid);		
		
		$self->execute_sql(478,$self->INVOICE_STATUS_CANCELED,$self->invid);
		$self->lock_billing;
		
		$self->logcronRemove(1, $self->uid);
		$self->logcronRemove(2, $self->invid);
	}

	return 1;
}

sub cancel_balances {
	my $self = shift;

	#Estorno do saldo
	my $invid = $self->invid;
	my $sum = 0;my $min = 0;my $max = 0;
		
	foreach my $bid ($self->get_balances(450,'%',$self->uid)) {			
		$self->balanceid($bid);			
		if ($self->balance('invoice') == $self->invid) {
				
			$min = $self->balanceid();
			if ($self->balance('bstatus') ne 'O') {
				$sum += $self->balance('valor');
			}
			$self->balance('invoice',undef); #SQL 447			
		} else {
			if ( ($self->balanceid() > $min && $self->balanceid() < $max) || ($self->balanceid() > $min && $max == 0) ) {
				$max = $self->balanceid(); #Saldo inserido imediatamente posterior
			}
		}			
	}
	$self->balanceid($max);
	if (sprintf($self->accuracy,$sum) > 0 && $max && $self->balance('descricao') eq 'Convertido em saldo') {
		$sum -= $self->balance('valor');
		my $coud = sprintf($self->accuracy,$sum) > 0 ? $self->lang('f_credit') : $self->lang('f_debit');	
		$self->create_balance($sum, $self->lang(82, $invid)) if sprintf($self->accuracy,$sum) != 0;  
	} else {						
		$self->execute_sql(447,$invid);
	}	
}

sub pay_invoice {
	my ($self, $pago, $data, $quiet) = @_;
	$data = $self->today unless $data;
	my $err;
	my ($new_vc) = $data->day;
	if ($self->invoice('status') && $self->invoice('status') ne $self->INVOICE_STATUS_QUITADO && $self->invoice('status') ne $self->INVOICE_STATUS_CANCELED) {
		$self->tid($self->invoice('tarifa'));
		#Setting input values
		$self->invoice('valor_pago',$pago);
		$self->invoice('data_quitado',$data);
		
		$self->variable('threshold',$self->invoice('valor') - $self->tax('valor'));
		
		if (sprintf($self->accuracy,$self->invoice('valor')) > 0 && $self->is_valid_tax($self->tid)) { 
			if ($self->is_creditcard_module($self->tax('modulo'))) {
				return 0, $self->set_error($self->lang(2002)) unless $self->creditcard_active;
				$self->ccid($self->creditcard_active);
				eval "use " . $self->tax('modulo');
				my $creditcard = eval "new " . $self->tax('modulo');
				die 'Fatal Error' if $creditcard->creditcard('username') != $self->uid;
	
				my %result = $creditcard->cc_capture;
				my $err = $creditcard->clear_error .' '. $result{'response'};
				if ($result{'authorized'} != 1) {
					$self->logcron($err,1);
					$self->set_error($err);
					return 0;
				} else {
					$pago = $result{'valor'};
					$data = $self->today();
					return 0, $self->set_error($err), $self->logcron($err,1) unless sprintf($self->accuracy,$pago) > 0 && !$self->error;
				}			
			} elsif ($self->is_boleto_module($self->tax('modulo')) || $self->tax('modulo') eq 'deposito') {
				#Do nothing
			} else {
				eval "use " . $self->tax('modulo');
				my $module = eval "new " . $self->tax('modulo');
				unless ($module->payDay) {
					return 0;
				}
			}
		}
		
		#Exporting vars
		$self->template('v_invoice',$self->Currency($self->invoice('valor')));
		$self->template('v_pago',$self->Currency($self->invoice('valor_pago')));
		$self->template($_,$self->user($_)) foreach qw(name endereco numero cidade estado cep empresa);
		$self->template('nome',$self->user('name'));
		$self->template('user',$self->setting('users_prefix').'-'.$self->invoice('username'));
		$self->template('cpf',Controller::frmtCPFCNPJ($self->user('cpf')));
		$self->template('cnpj',Controller::frmtCPFCNPJ($self->user('cnpj')));
		$self->template('invoice',$self->invid);
		$self->template('linkuser',$self->setting('baseurl').'/admin.cgi?do=viewuser&user='.$self->invoice('username'));
		$self->template('linkinv',$self->setting('baseurl').'/admin.cgi?do=viewinvoice&id='.$self->invid);
				
		my $oldsid = $self->sid;
		foreach (keys %{ $self->invoice('services') }) {
			$self->sid($_);
			next unless $self->is_valid_service($self->sid);
			next if $self->service('invoice') && $self->service('invoice') != $self->invid;
			$self->service('pagos', $self->service('pagos')+1); #mais uma parcela paga
			#Considerar os dias da promocao
			if ($self->serviceprop(1) > 0 && $self->service('pagos')-1 == 0) {
				#vai botar pra criar hoje, entao presume-se que vai ser inicio = today 
				$self->service('inicio',$self->today()) unless $self->service('inicio');
				#se pagar e ainda nao tiver sido ativado, ou ativado atrasado 
				$self->prazo($self->service('inicio') + $self->serviceprop(1));
			}
			elsif ($self->service('pagos')-1 == 0 && $self->postecipado == 0
				&& ($self->service('inicio') && $self->service('status') eq $self->SERVICE_STATUS_ATIVO) ) { #Servico ativou antes de quitar
				$self->prazo($self->service('inicio'));#force
				$new_vc = $self->service('inicio')->day;
			}								
			elsif ($self->service('pagos')-1 == 0 && $self->postecipado == 0 && 
					$self->plan('tipo') ne 'Registro' #Excetuando Registro
						) {					
				$self->prazo($self->invoice('data_quitado')) if !$self->service('vencimento');		
			}

			if ($self->servicos_ativos == 0 && !($self->user('vencimento') > 0)) { #Exceto usuários que já possuem o dia de vencimento
				$self->user('vencimento',$new_vc);
				$self->execute_sql(675,$new_vc,$self->invoice('username'));
			}
		
			$self->paidService;
			if ($self->service('status') =~ m/^(?:${\$self->SERVICE_STATUS_BLOQUEADO}|${\$self->SERVICE_STATUS_CONGELADO}|${\$self->SERVICE_STATUS_CANCELADO})$/) {
				$self->logcron(1,5,$self->invid,1) if $self->invoice('status') eq $self->INVOICE_STATUS_CONFIRMATION; #Mal uso = 1
			}
			
			unless ($self->service('proximo')) {			
				$self->set_error($self->lang(72));
				return 0;
			}		
						
			#Apagar promoção
			$self->execute_sql(823,$self->sid,1) if $self->serviceprop(1);

			$self->execute_sql(778,$self->service('proximo'),$self->service('pagos'),$self->sid);
			$self->service('vencimento', $self->service('proximo'));
			$self->service('envios', 0); $self->service('def', 0); $self->service('invoice', 0);
			$self->service('proximo',undef); #Já utilizou o proximo, retirar pra nao confundir

			$self->template('sid',$self->sid);
			$self->template('dominio',$self->service('dominio'));
						
			$self->messages( To => $self->setting('contas'), From => $self->setting('adminemail'), Subject => ['sbj_renew',$self->service('dominio')], txt => "renew" ) if ($self->setting('auto_renew') != 1 && $self->plan('tipo') eq 'Registro');

			$self->messages( To => $self->setting('contas'), From => $self->setting('adminemail'), Subject => ['sbj_alertpg',$self->service('dominio')], txt => "alertplanopg" ) if ($self->plan('alert') == 1);

			$self->nice_error() if $self->error;	
		}
		$self->sid($oldsid);
		$self->invoice('status',$self->INVOICE_STATUS_QUITADO);
		$self->user('status','CA');		

		$self->execute_sql(667,'CA',$self->uid);
		$self->execute_sql(475,$self->INVOICE_STATUS_QUITADO,$self->invoice('valor_pago'),$self->invoice('data_quitado'),$self->invid);
		$self->unlock_billing;

		$self->messages( To => $self->setting('alertpg'), From => $self->setting('adminemail'), Subject => ['sbj_payed',$self->invid], txt => 'alertpg' ) if $self->user('alert') == 1;
		
		$self->messages( User => $self->uid, To => $self->user('emails'), From => $self->setting('financeiro'), Subject => ['sbj_payed',$self->invid], txt => 'alertuserpg' ) if $self->setting('alertuser') == 1 && !$quiet;

		if ( sprintf($self->accuracy,$self->variable('threshold')) > sprintf($self->accuracy,$self->invoice('valor_pago')) ) {
			$self->set_error($self->lang(63,$self->invid,$self->Currency($self->invoice('valor')),$self->Currency($self->invoice('valor_pago'))));
			$self->error_code(63);
		}
	
		return 1;
	} elsif ($self->invoice('status') && $self->invoice('status') eq $self->INVOICE_STATUS_CANCELED) {
		$self->execute_sql(478,'P',$self->invid);
		$self->set_error($self->lang(64,$self->invid,$self->invoice('valor')));
		return 1;
	} elsif ($self->invoice('status') && $self->invoice('status') eq $self->INVOICE_STATUS_QUITADO) {
		#Repetir acoes com servicos caso ao quitar tenha dado problema
		my $oldsid = $self->sid;
		foreach (keys %{ $self->invoice('services') }) {
			$self->sid($_);
			next unless $self->is_valid_service($self->sid); #CUIDADO, tira referencias
			$self->paidService;
		}
		$self->sid($oldsid);
		#repetir avisos
		$self->template('v_invoice',$self->Currency($self->invoice('valor')));
		$self->template('v_pago',$self->Currency($self->invoice('valor_pago')));
		if (sprintf($self->accuracy,$self->invoice('valor')) > sprintf($self->accuracy,$self->invoice('valor_pago'))) {
			$self->set_error($self->lang(63,$self->invid,$self->Currency($self->invoice('valor')),$self->Currency($self->invoice('valor_pago'))))
		}
		return 1;
	} else {
		$self->set_error($self->lang(65,$self->invid));		
		return 0;
	}
}

sub multa {
	my $self = shift;
	my $valor = shift;
	my $multa = $valor * $self->setting('multa') / 100;
	return sprintf("%.2f",$multa);
}

sub juros {
	my $self = shift;
	my $valor = shift;
 	my $dias = shift;
 	$perc = $self->setting('juros');

	my $juros = $valor * $perc * $dias /100 /30;
	return sprintf("%.2f",$juros);
}

sub valorProrrogado {
	my $self = shift;
	my $dias = shift;
	
	my $nvalor=$self->invoice('valor');
	$nvalor += $self->juros($self->invoice('valor'), $dias);
	$nvalor += $self->multa($self->invoice('valor')) if $self->invoice('data_vencido') eq $self->invoice('data_vencimento');
	
	return $nvalor;
}

sub prorrogar {
	my $self = shift;
	my $sj = shift;
	
	my $dif = $self->today() - $self->invoice('data_vencimento') if $self->invoice('data_vencimento');
	my $prorrogavel = $dif >= 0 ? 1 : 0;
	
	if ($self->invoice('status') ne $self->INVOICE_STATUS_PENDENTE || $prorrogavel != 1 || (!$self->staffid && $self->invoice('status') eq $self->INVOICE_STATUS_CONFIRMATION)) {
		$self->set_error($self->lang(71));
		return;
	}

	my $nvalor=$self->invoice('valor');
	$nvalor = $self->valorProrrogado($dif + $self->setting('dias_prorrogado')) unless ($sj == 1); 
	
	my $nvencimento = $self->today() + $self->setting('dias_prorrogado');
	my @refer = split("\n",$self->invoice('referencia'));
	my $coud = sprintf($self->accuracy,$nvalor - $self->invoice('valor')) > 0 ? $self->lang(76) : $self->lang(77);
	$refer = $self->lang(70,$self->dateformat($self->invoice('data_vencimento')),$self->dateformat($nvencimento));
	$refer = $self->lang(69,$coud,$self->dateformat($self->invoice('data_vencimento')),$self->dateformat($nvencimento),$self->Currency(abs ($nvalor - $self->invoice('valor')))) if sprintf($self->accuracy,($nvalor - $self->invoice('valor'))) != 0;	
	splice(@refer,-2,0,$refer) if scalar @refer > 2;
	
	die $self->clear_error() if $self->error();
	$self->execute_sql(473,$nvalor,$nvencimento,join("\n",@refer),$self->invid);
	$self->invoice(0); #atualizando
}

sub credit_sum {
	my ($self) = shift;
	return $self->set_error($self->lang(3,'credit_sum')) unless $self->uid;
	
	#consulta credito, já não comprometidos *precavendo solicitacoes sucessivas sem credito
	my $sth = $self->select_sql(qq|SELECT SUM(`valor`) FROM `creditos` WHERE `username` = ?|,$self->uid); 
	my ($credito) = $sth->fetchall_arrayref();#creditos negativos irao descontar e dar um total disponivel
	$sth->finish;
	$self->user('_credit', sprintf($self->accuracy,$credito) > 0 ? $credito : 0);
	
	return $self->user('_credit'); # nao pode ser negativo
}

sub prorate {
	my ($self, $newVencimento) = @_;
	return $self->set_error($self->lang(3,$self->sid)) unless $self->sid; #Precisa de servico
	
	my $extra = $self->service('vencimento') - $newVencimento; #Negativo gera débito
	if ($extra) { 
		my $parc = $extra * $self->diaria;
		my $coud = sprintf($self->accuracy,$parc) > 0 ? $self->lang('f_credit') : $self->lang('f_debit');
		my $desc = $self->lang(86, $coud, $self->service('dominio'), $self->dateformat($self->service('vencimento')), $self->dateformat($newVencimento), $self->Currency(abs $parc));
		$self->create_balance($parc, $desc, $self->sid) if sprintf($self->accuracy,$parc) != 0;
		return $parc;
	}
	return undef;
}
1;
#!/usr/bin/perl
#
# Controller - is4web.com.br
# 2009 - 2012
package Controller::Interface::_Admin;

require 5.008;
require Exporter;

use Controller::Interface;

use vars qw(@ISA $VERSION);

@ISA = qw(Controller::Interface);

$VERSION = '2014.09.05'; #YYYY-MM-NN sendo N 1-9, Nao pode terminar em 0 

=pod
########### ChangeLog #######################################################  VERSION   #
=item user_new  	                                                        #            #
	-fix password crypted twice												# 2013.02.01 #
=item lists																	#			 #
	-add limit search by characters											# 2013.06.01 #
=item update																#			 #
	-Fix $value on check valid values (BUG)									# 2013.06.02 #
	-add limit of search results											# 2013.06.02 #			
=item update																#			 #
	- Added new modules to invoice_send 									# 2014.09.14 #
#############################################################################            #
=cut

#invocar os metodos da interface e sobrescrever os parses
sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = shift;
    my $s_class = ref $self;

    push @ISA, eval '@'.$s_class.'::ISA'; #Inherit ISA
    push @ISA, $s_class;

	bless($self, $class);#Rename class

	return $self;
}

sub version { $VERSION };

sub login {
	my ($self) = shift;
	
	if ($self->check_user) {
		$self->parse('/loggedin');
	} else {
		my $sel_skin = $self->skin('name');
		foreach my $skin ($self->skins) {
			$self->template('skinname',$skin);
			$self->option_enabled($sel_skin eq $skin ? 1 : 0);
			$self->parse_var('skins','/row_sel_skin');
		}
	
		$self->template('IP') = $ENV{'REMOTE_ADDR'};
		$self->template('redirect') = $self->param('redirect') || $ENV{'QUERY_STRING'};
	
		$self->parse('/login');
	}
}

sub plogin {
	my ($self) = shift;

	my $pass = $self->param('password');
	my $user = $self->param('username');
	my $tzo = $self->num($self->param('TBClientOffset'));

	$self->staffid($user);
	if (Controller::encrypt_mm($pass) ne $self->staff('password') || $self->staff('admin') != 1) {
		$self->set_error($self->lang('error6'));
		return $self->parse('/logged');
	}
	
	my $md5 = Digest::MD5->new;
	$md5->reset;

	my $certif = $self->staff('username').$self->staff('rkey').$ENV{'HTTP_USER_AGENT'}.$ENV{'REMOTE_ADDR'};
	$certif = $self->staff('username').$self->staff('rkey').$ENV{'HTTP_USER_AGENT'} if $self->setting('IP_IN_COOKIE') == 0;
	$md5->add($certif);
	my $enc_cert = $md5->hexdigest();
	
	$self->{cookname} = $user;
	$self->{cookcert} = $enc_cert;
	$self->{cooktzo} = $tzo;
	
	return $self->parse('/logged');
}

sub logout {
	my ($self) = shift;
	
	local $Controller::SWITCH{skip_log} = 1;
	$self->execute_sql(qq|DELETE FROM `online` WHERE `username` = ? AND `agent` = ?|,$self->{cookname},$ENV{'HTTP_USER_AGENT'});							
	
	$self->setting('admin_timeout','525600'); #1y
	$self->{cookname} = undef;
	$self->{cookcert} = undef;
	$self->parse('/logout');
}

sub check_user {
	my ($self) = shift;
	
	unless ($self->{cookname} && $ENV{'HTTP_USER_AGENT'}) {
		$self->set_error($self->lang('not_loggedin'));	
		return 0;
	}
	
	$self->staffid($self->{cookname});
	
	my $md5 = Digest::MD5->new;
	$md5->reset;

	my $certif = $self->staff('username').$self->staff('rkey').$ENV{'HTTP_USER_AGENT'}.$ENV{'REMOTE_ADDR'};
	$certif = $self->staff('username').$self->staff('rkey').$ENV{'HTTP_USER_AGENT'} if $self->setting('IP_IN_COOKIE') == 0;
	$md5->add($certif);
	my $enc_cert = $md5->hexdigest();	
	
	if($enc_cert eq $self->{cookcert} && $self->staff('admin') == 1){
		local $Controller::SWITCH{skip_log} = 1;
		my $sth = $self->select_sql(186,$self->{cookname},$ENV{'HTTP_USER_AGENT'});
		my ($t) = $sth->fetchrow_array if $sth; 
		$self->finish;
		if ($t >= $self->setting('users_limit')) {
			$self->set_error($self->lang(18,$self->setting('users_limit')));
		} else {
			$self->execute_sql(185,$self->{cookname},$ENV{'HTTP_USER_AGENT'},0,$self->{cooktzo},$self->{cookname},$ENV{'HTTP_USER_AGENT'});
		}		 	
		return $self->error ? 0 : 1;
	} else {
		$self->set_error($self->lang('error6')) if ($self->param('do') ne 'login' && $self->param('do'));	
		return 0;
	}
}

*users_list = \&user_list;
sub user_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_list')) if $self->perm('users','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'username DESC';
	my $limit = $self->param('limit') || 50;	
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $ustatus = $self->UStatusMatch($filter) if $filter;
	my $pending = defined $self->param('pending') ? $self->param('pending') : '%';
	my $username = $self->num($self->param('username'));
	
	my $sql_679 = $self->{queries}{679};
	my $sql_678 = $self->{queries}{678};
	my $sql_683 = $self->{queries}{683};
		
	if ($username > 0) {
		$sql_679 .= " AND `username` = $username";
		$sql_678 .= " AND `username` = $username";
		$sql_683 .= " AND `username` = $username";
	}

	$sql_679 .= qq| AND `pending` LIKE ?|;
	$sql_683 .= qq| AND `pending` LIKE ?|;

	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_679 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_678 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_683 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @columns = ('vencimento','name','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','rkey','pending','active','acode','lcall','conta','forma','alert','alertinv','news','language');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'username');
	$sql_683 =~ s/`\?`/`$col`/;
	
	my @users = $filter
		? $col 
			? $self->get_users($sql_683,$filter,$pending,$offset,$limit) 
			: $self->get_users($sql_679,($filter)x10,$ustatus,$pending,$offset,$limit)
		: $self->get_users($sql_678,$pending,$offset,$limit);
			
	if (scalar @users == 0) {
		$self->parse_var('rows','/row_users_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @users,$self->setting('search_limit'))) if ($self->setting('search_limit') && $self->setting('search_limit') && scalar @users > $self->setting('search_limit'));
		
		foreach my $uid (@users) {
			$self->uid($uid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);
			
			#'password',
			foreach (@columns) {
				if (m/cpf|cnpj/) {	
					$self->template($_, Controller::frmtCPFCNPJ($self->user($_)));
				} else {
					$self->template($_, $self->user($_));
				}
			}
			$self->template('username',$uid);
			$self->template('email', ${$self->user('email')}[0]) if $self->user('email');
			$self->template('cep', Controller::frmtPotalCode($self->user('cep'),$self->user('cc')));
			$self->template('telefone', Controller::frmt($self->user('telefone'),'phone'));
			$self->template('inscricao', $self->dateformat($self->user('inscricao')));
			$self->template('status', $self->UStatus($self->user('status')));				
				
			$self->parse_var('rows','/row_users');
		}
	}
	
	$self->parse('/user_list');
}

sub user_prenew {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_prenew')) if $self->perm('users','new','deny') == 1;	
			
	#Options
	my $fields = $self->{dbh}->column_info(undef, undef, 'users', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('status') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'status') {
				$self->template('option_text',$self->UStatus($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}
	
	#Pais
	#selected value
	foreach ($self->country_codes) {
		$self->option_enabled( $_ eq $self->setting('pais') ? 1 : 0);		
		$self->template('option_value',$_);
		$self->template('option_text',$self->country_code($_)->{'name'});					
		$self->parse_var('options_cc','/option');
	}

	#Forma
	#selected value
	foreach ($self->taxs) {
		$self->tid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->setting('forma') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->tax('tipo'));					
		$self->parse_var('options_forma','/option');
	}			

	#Contas
	#selected value
	foreach ($self->accounts) {
		$self->actid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->setting('cc') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->account('nome'));
		$self->parse_var('options_conta','/option');
	}
	
	#Language
	#selected value
	foreach ('',$self->list_langs) {
		$self->option_enabled( $_ eq $self->setting('language') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$_);		
		$self->parse_var('options_language','/option');
	}	

	#Level
	#selected value
	foreach ($self->enterprises) {
		$self->entid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		#$self->option_enabled( $self->xx   ('level') =~ /(^|::)$_(::|$)/ ? 1 : 0 );
		$self->template('option_value',$_);
		$self->template('option_text',$self->enterprise('nome'));		
		$self->parse_var('options_level','/option');
	}	
	
	$self->template('minpass',$self->setting('pass_chars'));	
	$self->template('vencimento',$self->today->day());
			
	$self->parse('/user_prenew');
}

sub user_new {
	my ($self) = shift;	
	use Controller::Users;
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_new')) if $self->perm('users','new','deny') == 1;

	#Selecionando usuário
	my $sth = $self->select_sql(702);
	my $ref = $sth->fetchrow_hashref() if $sth;
	$self->finish;
	$self->template('username',$ref->{'username'});
	$self->set_error($self->lang(401)), return unless $ref->{'username'};
	
	$self->Controller::Users::insert_data('username',$ref->{'username'});
	my (@changed, @novalue);
	my $reRequired = qr/^(name|cep|cidade|estado|endereco|email|conta|forma|language|cc)$/;
	#'password'
	my @fields = ('vencimento','name','email','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','conta','forma','alert','alertinv','news','language','notes');
	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		unless (defined $value || $column =~ $reRequired) {
			push(@novalue, $column);
			next;
		}
				
		#Erros, next
		if ($column eq 'cpf' || ($column eq 'cnpj' && $self->param('empresa'))) { 
			$value = $self->is_CPFCNPJ($self->param($column))
				? $self->num($self->param($column)) : 0;#Permitir cadastro indevido pelo admin #next;
			$value =~ s/^0// if length($value) == 15;
		};
		if ($column eq 'cc') { $value = $self->is_valid_country($value) ? uc($value) : undef;}
		if ($column eq 'telefone') { $value = $self->is_valid_phone($self->num($value)) ? $self->num($value) : undef;}
		if ($column eq 'cep' && uc $self->param('cc') eq 'BR') { $value = $self->num($self->param($column)); $value =~ s/^(\d{5})(\d*)$/$1-$2/; next if $value !~ /^\d{5}\-\d*$/; }
		if ($column eq 'estado') { $value = uc($self->param($column)); next if length $value != 2; }
		if ($column =~ /^(alert|alertinv|news)$/) { $value = $self->param($column) == 1 ? '1' : '0'; }
		if ($column eq 'level') { 
			my @nivel = split '::', $value;
			unshift @nivel, $self->param($column.'d') if $self->param($column.'d');
			Controller::iUnique( \@nivel );
			$value = scalar @nivel > 0 ? join("::",@nivel) . "::" : undef;
		}		
		next if ($column =~ /^(forma|conta)$/ && !$self->num($value));
		#must be filled
		next if !$value && $column =~ $reRequired;
		
		$self->template($column, $value);
		$self->Controller::Users::insert_data($column, $value);
		push @changed, $column;
	}
	
	#Random password
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$self->param('password',$self->randthis($self->setting('pass_chars'),@chars)) unless $self->param('password');	
	#Default values;
	$self->Controller::Users::insert_data('status','CA');
	$self->Controller::Users::insert_data('pending',0);
	$self->Controller::Users::insert_data('password',$self->param('password'));

	#Qualidade de dados
	my ($nchanged) = Controller::iDifference(\@fields,\@changed);
	my ($nonchanged) = Controller::iDifference(\@$nchanged,\@novalue);	
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	#Test data only
	local $Controller::SWITCH{skip_sql} = $self->param('fake') == 1 ? 1 : 0;
	
	my $uid = $self->Controller::Users::insert if scalar @$nonchanged == 0;
	$self->uid($uid);
	if ($self->uid && $self->param('sendmail') == 1) {			
		$self->template('user', $self->Controller::Users::fullid);
		$self->template('name', $self->user('name'));
		$self->template('password', $self->param('password'));		
		my $from = $self->return_sender('User');
		my $to = join ',', grep { $self->is_valid_email($_) } @{ $self->user('email') };
		my $sent = $self->messages( User => $self->uid, To => $to, From => $from, Subject => 'sbj_welcome', txt => 'welcome2');
		$self->messages( User => $self->uid, To => $self->setting('contas'), From => $from, Subject => 'sbj_new_user', txt => 'alertnewuser2');

		$self->parse_var($sent,'/email');	
	}
	
	$self->parse('/user_new');
}

sub user_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_view')) if $self->perm('users','view','deny') == 1;
	
	use Controller::Users;
	my $uid = $self->param('ID');
	return $self->hard_error($self->lang('3','user_view')) unless $self->is_valid_user($uid);
	$self->uid($uid);
	
	#'password',
	foreach ('vencimento','name','status','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','rkey','pending','active','acode','lcall','conta','forma','alert','alertinv','news','language','notes') {
		if (m/cpf|cnpj/) {	
			$self->template($_, Controller::frmtCPFCNPJ($self->user($_)));
		} else {
			$self->template($_, $self->user($_));
		}
	}
	$self->template('username',$uid);
	$self->template('user', $self->Controller::Users::fullid);
	$self->template('email', $self->user('emails'));
	$self->template('cep', Controller::frmtPotalCode($self->user('cep'),$self->user('cc')));
	$self->template('telefone', Controller::frmt($self->user('telefone'),'phone'));
	$self->template('inscricao', $self->dateformat($self->user('inscricao')));
	
	#History
	my $sum = 0;
	#total creditos	
	my @creditids = $self->credits;
	foreach (@creditids) {
		$self->creditid($_);
		$self->template('credit', $self->template('credit') + $self->credit('valor'));
	}
	$self->template('credit', $self->Currency($self->template('credit'),1));		
	#total saldos	
	my @bids = $self->balances;
	foreach (@bids) {
		$self->balanceid($_);
		$self->template('balance', $self->template('balance') + $self->balance('valor'));
	}
	$sum -= $self->template('balance');
	$self->template('balance', $self->Currency($self->template('balance'),1));	
	#total faturas
	my @ccids = $self->get_invoices(438,$self->uid,'P');
	push @invids, $self->get_invoices(438,$self->uid,'C');
	foreach (@invids) {
		$self->invid($_);
		$self->template('invoice', $self->template('invoice') + $self->invoice('valor'));
	}
	$sum += $self->template('invoice');
	$self->template('invoice', $self->Currency($self->template('invoice'),1));		
	$self->template('total', $self->Currency($sum,1));
	
	#Options
	my $fields = $self->{dbh}->column_info(undef, undef, 'users', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('status') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){
			$self->option_enabled( $mysql_values->[$a] eq $self->user($_) ? 1 : 0);		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'status') {
				$self->template('option_text',$self->UStatus($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}
	
	#Pais
	#selected value
	foreach ($self->country_codes) {
		$self->option_enabled( $_ eq $self->user('cc') ? 1 : 0);		
		$self->template('option_value',$_);
		$self->template('option_text',$self->country_code($_)->{'name'});					
		$self->parse_var('options_cc','/option');
	}

	#Forma
	#selected value
	foreach ($self->taxs) {
		$self->tid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->user('forma') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->tax('tipo'));					
		$self->parse_var('options_forma','/option');
	}			

	#Contas
	#selected value
	foreach ($self->accounts) {
		$self->actid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->user('conta') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->account('nome'));
		$self->parse_var('options_conta','/option');
	}
	
	#Language
	#selected value
	foreach ('',$self->list_langs) {
		$self->option_enabled( $_ eq $self->user('language') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$_);		
		$self->parse_var('options_language','/option');
	}	

	#Level
	#selected value
	foreach ($self->enterprises) {
		$self->entid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $self->user('level') =~ /(^|::)$_(::|$)/ ? 1 : 0 );
		$self->template('option_value',$_);
		$self->template('option_text',$self->enterprise('nome'));
		$self->parse_var('options_level','/option');
	}	
	
	$self->template('minpass',$self->setting('pass_chars'));	
			
	$self->parse('/user_view');
}

sub user_list_invoice {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_list_invoice')) if $self->perm('invoices','list','deny') == 1;

	my $uid = $self->param('ID');
	return $self->hard_error($self->lang('3','user_list_invoice')) unless $self->is_valid_user($uid);
	$self->uid($uid);

	my $order = $self->param('order_by') || 'id DESC';
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	
	my $sql_439 = $self->{queries}{439};
	$sql_439 .= qq| ORDER BY |.join(', ', @orderby);
			
	my @list = $self->get_invoices($sql_439,'%',$self->uid);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_user_list_invoice_nodata');	
	} else {
		foreach my $invid (@list) {
			$self->invid($invid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach ('username', 'status', 'nome', 'data_envio', 'data_vencido', 'data_vencimento', 'data_quitado', 'envios', 'referencia', 'services', 'valor', 'valor_pago', 'imp', 'conta', 'tarifa', 'parcelas', 'parcelado', 'nossonumero') {							
				if (m/data_envio|data_vencimento|data_quitado|data_vencido/) {
					$self->template($_, $self->dateformat($self->invoice($_)));
				} elsif (m/valor_pago|valor/) {
					$self->template($_, $self->Currency($self->invoice($_),1));				
				} elsif (m/services/) {
					$self->template($_, join ',', keys %{$self->invoice($_)});
				} else {
					$self->template($_, $self->invoice($_));
				}
			}

			$self->template('id',$invid);
			$self->template('parcelado', $self->InstallmentType($self->invoice('parcelado')));				
			
			$self->parse_var('rows','/row_user_list_invoice');
		}
	}	

	$self->parse('/user_list_invoice');
}

sub user_list_balance {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_list_balance')) if $self->perm('balances','list','deny') == 1;

	my $uid = $self->param('ID');
	return $self->hard_error($self->lang('3','user_list_balance')) unless $self->is_valid_user($uid);
	$self->uid($uid);

	my $order = $self->param('order_by') || 'id DESC';
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	my $sql_450 = $self->{queries}{450};
	$sql_450 .= qq| ORDER BY |.join(', ', @orderby);	
		
	my @list = $self->get_balances($sql_450,'%',$self->uid);
	
	if (scalar @list == 0) {
		$self->parse_var('rows','/row_user_list_balance_nodata');	
	} else {
		foreach my $balanceid (@list) {
			$self->balanceid($balanceid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach ('username', 'valor', 'descricao', 'servicos', 'invoice', 'bstatus') {							
				if (m/valor/) {
					$self->template($_, $self->Currency($self->balance($_),1));
				} else {
					$self->template($_, $self->balance($_));
				}
			}

			$self->template('id',$balanceid);
			
			$self->parse_var('rows','/row_user_list_balance');
		}
	}	

	$self->parse('/user_list_balance');
}

sub user_list_credit {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_list_credit')) if $self->perm('credits','list','deny') == 1;

	my $uid = $self->param('ID');
	return $self->hard_error($self->lang('3','user_list_credit')) unless $self->is_valid_user($uid);
	$self->uid($uid);

	my $order = $self->param('order_by') || 'id DESC';
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	
	my $sql_486 = $self->{queries}{486};
	$sql_486 .= qq| ORDER BY |.join(', ', @orderby);	
		
	my @list = $self->get_credits($sql_486,'%',$self->uid);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_user_list_credit_nodata');	
	} else {
		foreach my $creditid (@list) {
			$self->creditid($creditid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach ('username', 'valor', 'descricao', 'cstatus') {							
				if (m/valor/) {
					$self->template($_, $self->Currency($self->credit($_),1));
				} else {
					$self->template($_, $self->credit($_));
				}
			}

			$self->template('id',$creditid);
			
			$self->parse_var('rows','/row_user_list_credit');
		}
	}	

	$self->parse('/user_list_credit');
}

sub user_list_service {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_list_service')) if $self->perm('services','list','deny') == 1;
	
	my $uid = $self->param('ID');
	return $self->hard_error($self->lang('3','user_list_service')) unless $self->is_valid_user($uid);
	$self->uid($uid);
	
	my @filter = map { $self->num($_) } split ',', $self->param('services') if $self->param('services');
	$self->invid($self->num($self->param('invoice'))); #Filter by invoice services
	@filter = keys %{ $self->invoice('services') } if $self->invid > 0 && ref $self->invoice('services') eq 'HASH';
	my $sql_785 = $self->{queries}{785};
	$sql_785 .= qq| AND `id` IN (|.join(',', @filter).qq|)| if @filter;
	
	my $order = $self->param('order_by') || 'id DESC';
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_785 .= qq| ORDER BY |.join(', ', @orderby);	
	
	my @columns = ('username', 'dominio', 'plano', 'status', 'tipo', 'plataforma', 'inicio', 'fim', 'vencimento', 'proximo', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'action', 'invoice', 'pagos', 'desconto', 'lock');
	
	my @list = $self->get_services($sql_785,'%',$self->uid);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_services_nodata');	
	} else {
		foreach my $sid (@list) {
			$self->sid($sid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);
						
			foreach (@columns) {
				#Attr
				my $attrs = $self->templateAttr($_);
				$attrs->{'value'} = $self->service($_);				
				if (m/inicio|fim|vencimento|proximo/) {
					$self->template($_, $self->dateformat($self->service($_)));
				} elsif (m/pg|plano|servidor/) {
					$self->template($_, $self->service($_.'_nome'));
				} elsif ($_ eq 'desconto') {
					$self->template($_, $self->Currency($self->service($_),1));					
				} else {
					$self->template($_, $self->service($_));
				}
			}
			$self->template('id',$sid);
			my $attrs = $self->templateAttr('id');
			$attrs->{'value'} = $sid;
			$self->template('status', $self->SStatus($self->service('status')));
			$self->template('action', $self->SAction($self->service('action')));			
				
			$self->parse_var('rows','/row_services');
		}
	}

	$self->parse('/user_list_service');
}

sub user_list_email {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_list_email')) if $self->perm('emails','list','deny') == 1;

	my $uid = $self->param('ID');
	return $self->hard_error($self->lang('3','user_list_email')) unless $self->is_valid_user($uid);
	$self->uid($uid);
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = $self->param('keywords');
	my $date = $self->datefromformat($filter) if $filter;
	my $tzo = $self->{cooktzo} || $self->offset/3600;
		
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}
	my $sql_162 = $self->{queries}{162};	
	$sql_162 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @list = $filter
		? $self->get_logmails($sql_162,$self->uid,($filter)x9,$date,$offset,$limit)
		: $self->get_logmails($sql_162,$self->uid,('%')x9,$date,$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_users_list_email_nodata');	
	} else {
		foreach my $logmailid (@list) {
			$self->logmailid($logmailid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);
						
			foreach ('byuser', 'user', 'from', 'to', 'subject', 'data', 'tempo', 'enviado') {
				if (m/^data$/) {
					$self->template($_, $self->dateformat($self->logmail($_) + Controller::timeadd_offset($self->logmail('tempo'),$tzo,1) ));
				} elsif (m/^tempo/) {
					$self->template($_, Controller::timeadd_offset($self->logmail($_),$tzo));
				} elsif (m/^(byuser)$/) {
					$self->template($_, $self->logmail($_));
				} else {
					$self->template($_, $self->logmail($_));
				}
			}
			$self->template('id',$logmailid);	
				
			$self->parse_var('rows','/row_users_list_email');
		}
	}

	$self->parse('/user_list_email');
}

sub user_update {
	my ($self) = shift;	
	use Controller::Users;
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_update')) if $self->perm('users','update','deny') == 1;
		
	my $uid = $self->param('username');
	return $self->hard_error($self->lang('3','user_update')) unless $self->is_valid_user($uid);
	$self->uid($uid);
	
	my @tobechanged;
	my @noerror;
	my @fields = ('vencimento','status','name','email','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','conta','forma','alert','alertinv','news','language','notes');
	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value);
		
		#Com valores para update
		push @tobechanged, $column;
				
		#Erros, next
		if ($column eq 'cpf' || $column eq 'cnpj') { 
			$value = $self->is_CPFCNPJ($value)
				? $self->num($value) : $value eq '' ? '' : next;
			$value =~ s/^0// if length($value) == 15;
		};
		if ($column eq 'telefone') { $value = $self->is_valid_phone($self->num($value)) ? $self->num($value) : next;}
		if ($column eq 'cep') { $value = $self->num($value); $value =~ s/^(\d{5})(\d*)$/$1-$2/; next if $value !~ /^\d{5}\-\d*$/; }
		if ($column eq 'estado') { $value = uc($value); next if length $value != 2; }
		if ($column =~ /^(alert|alertinv|news)$/) { $value =$value == 1 ? '1' : '0'; }
		if ($column eq 'level') { 
			my @nivel = split '::', $value;
			unshift @nivel, $self->param($column.'d') if $self->param($column.'d');
			Controller::iUnique( \@nivel );
			$value = scalar @nivel > 0 ? join("::",@nivel) . "::" : undef;
		}		
		next if ($column =~ /forma|conta/ && !$self->num($value));

		#Erros normais
		push @noerror, $column;

		$self->user($column, $value);
		$self->template($column, $value);
	}

	my @changed = $self->user('changed');
	my ($nonchanged) = Controller::iDifference(\@tobechanged,\@noerror);
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);
	
	$self->Controller::Users::save;

	$self->parse('/user_update');
}

sub user_updatepass {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_updatepass')) if $self->perm('users','update','deny') == 1;

	use Controller::Users;		
	my $uid = $self->param('username');
	return $self->hard_error($self->lang('3','user_updatepass')) unless $self->is_valid_user($uid);
	$self->uid($uid);
		
	$self->Controller::Users::update_pass($self->param('password'));

	if ($self->param('sendmail') == 1) {
		$self->template('user', $self->Controller::Users::fullid);
		$self->template('name', $self->user('name'));
		$self->template('password', $self->param('password'));
		
		my $from = $self->return_sender('User');
		my $to = join ',', grep { $self->is_valid_email($_) } @{ $self->user('email') };
		my $sent = $self->email( User => $self->uid, To => $to, From => $from, Subject => 'sbj_resetpass', txt => 'resetpass');
		$self->parse_var($sent,'/email');	
	}	

	$self->parse('/user_updatepass');
}

sub user_resetpass {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_resetpass')) if $self->perm('users','update','deny') == 1;

	use Controller::Users;		
	my $uid = $self->param('username');
	return $self->hard_error($self->lang('3','user_resetpass')) unless $self->is_valid_user($uid);
	$self->uid($uid);
	
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$self->template('password',$self->randthis($self->setting('pass_chars'),@chars));
	$self->Controller::Users::update_pass($self->template('password'));

	$self->template('user', $self->Controller::Users::fullid);
	$self->template('name', $self->user('name'));
		
	my $from = $self->return_sender('User');
	my $to = join ',', grep { $self->is_valid_email($_) } @{ $self->user('email') };
	my $sent = $self->email( User => $self->uid, To => $to, From => $from, Subject => 'sbj_resetpass', txt => 'resetpass');
	$self->parse_var($sent,'/email');	

	$self->parse('/user_updatepass');
}

sub user_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_remove')) if $self->perm('users','delete','deny') == 1;
	
	use Controller::Users;
	
	my @errors;
	foreach my $uid (split ',', $self->param('username')) { #Loop para questões de LOG
		$self->uid($self->num($uid));
		next unless $self->is_valid_user($uid);
		$self->Controller::Users::remove;
		push @errors, $self->clear_error if $self->error;
	}
	$self->set_error(join "\n", @errors) if scalar @errors;
	
	$self->parse('/user_remove');
}

sub user_advinvoice {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_advinvoice')) if $self->perm('invoices','new','deny') == 1;
			
	my $uid = $self->param('username');
	return $self->hard_error($self->lang('3','user_advinvoice')) unless $self->is_valid_user($uid);
	$self->uid($uid);
	
	my @checkbox = $self->param('IDs');
	Controller::iUnique(\@checkbox);
	Controller::iDelete(\@checkbox);
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);

	local $Controller::Financeiro::SWITCH{prazo_force} = 1;  
	my $ok; my @invs;	
	until ($ok==1) {
		my ($inv,$rsids) = $self->faturar(\@checkbox,1);
		foreach my $sid (@$rsids) {
			next unless $sid > 0;
			$self->sid($sid);
			$self->service('invoice',$inv) if $inv; #fake invoice para inibir a repetição para o mesmo serviço
		}
		push @invs, $inv if $inv;
		$ok = 1 if !$inv;
	}
	
	$self->template('motivo', !@invs ? $self->lang(81) : $self->lang(80,join(',',@invs)) );
	
	$self->parse('/user_advinvoice');
}

sub user_email_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_email_view')) if $self->perm('emails','view','deny') == 1;
	
	my $logmailid = $self->param('ID');
	$self->logmailid($logmailid);
	my $tzo = $self->{cooktzo} || $self->offset/3600;
	
	foreach  my $column ('byuser','user','from','to','subject','body','data','tempo','enviado') {
		if (m/^(from|to)$/) {
			my @emails = split ',', $self->logmail($column);
			$self->template($column, join ',', grep { $self->is_valid_email($_) } @emails);					
		} elsif (m/^(data)$/) {
			$self->template($column, $self->dateformat($self->logmail($column) + Controller::timeadd_offset($self->logmail('tempo'),$tzo) ));
		} elsif (m/^(tempo)$/) { #Set offset
			$self->template($column, Controller::timeadd_offset($self->logmail($column),$tzo));													
		} elsif (m/^(byuser)$/) {
			$self->template($column, $self->logmail($column));
		} else {
			$self->template($column, $self->logmail($column));
		}
	}
	$self->template('id',$logmailid);
	
	$self->parse('/user_email_view');
}

sub service_prenew {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_prenew')) if $self->perm('services','new','deny') == 1;	

	my $pid = $self->param('plan');
	$self->pid($pid);
		
	my @list = split('::', $self->plan('campos'));
	Controller::iUnique(\@list);
	Controller::iDelete(\@list);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_service_fields_nodata');	
	} else {
		foreach my $field (@list) {
			$self->template('name',$field);
			$self->parse_var('rows','/row_service_fields');
		}
	}	
	
	my $response = $self->responseDocument;
	my $doc = $self->xmlDocument;
	
	if ($self->is_valid_server($self->plan('pservidor'))) {
		my $el = $doc->createElement('pserver', $response, $self->server('nome'));
		$el->setAttribute('value', $self->srvid);
	}	
	
	$self->lock_billing;
			
	$self->parse('/service_prenew');
}

sub service_new {
	my ($self) = shift;	
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_new')) if $self->perm('services','new','deny') == 1;

	$self->set_error($self->lang(3,'service_new')), return unless $self->param('username');
	
	$self->Controller::Services::insert_data('username',$self->param('username'));
	$self->Controller::Services::insert_data('activate',$self->param('activate'));
	$self->Controller::Services::insert_data('property1',$self->param('property1'));#1 - dias gratis   
	$self->Controller::Services::insert_data('property2',$self->param('property2'));#2 - Sem taxa de setup 
	$self->Controller::Services::insert_data('property3',$self->param('property3'));#3 - Descontos em meses
	$self->Controller::Services::insert_data('property4',$self->param('property4'));#4 - Nao se orientar pelo vc do usuario
	$self->Controller::Services::insert_data('property5',$self->param('property5'));#5 - dias para finalizar 
	$self->Controller::Services::insert_data('property6',$self->param('property6'));#6 - fatura exclusiva

	my @changed;
	my @fields = ('dominio', 'servicos', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'invoice', 'pagos', 'desconto', 'lock','notes');
	my $fields = $self->{dbh}->column_info(undef, undef, 'servicos', '%')->fetchall_hashref('COLUMN_NAME');
	foreach my $column (@fields) {
		#Coluna temporária
		$column = 'plano' if $column eq 'servicos';
		
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value || $column =~ /dados|useracc|envios|def|action|invoice|pagos|desconto|lock|notes/);
				
		#Erros, next
		next if ($column eq 'plano' and !$self->is_valid_plan($value));
		next if ($column eq 'servidor' and !$self->is_valid_server($value));
		next if ($column eq 'pg' and !$self->is_valid_payment($value));

		if ($column =~ /^(dominio)$/) { $value = $value eq '' ? undef : $value; }  
		if ($column =~ /^(invoice)$/) { $value = undef; }
		if ($column =~ /^(envios|def|pagos)$/) { $value = $self->num($value); } #permite zero	
		$value = $self->datefromformat($value) if $value ne '0000-00-00' && $column =~ /^(inicio|fim|vencimento|proximo)$/;
		$value = $self->Float($value) if $column =~ /^(desconto)$/;
		next if $column =~ /^(status|action)$/ && !grep { $value eq $_} @{ $fields->{$column}->{mysql_values} }; 	
		if ($column =~ /^(dados)$/ && $self->param('plano')) { #Casos especias
			$self->pid($self->param('plano'));
			my @list = split('::', $self->plan('campos'));
			Controller::iUnique(\@list);
			Controller::iDelete(\@list);
			foreach my $col (@list) {
				my $val = $self->param('dados_'.$col);
				$value .= "${col} : ${val}::";
			}
			$self->template($column, $value);
			$self->Controller::Services::insert_data($column, $value);
			push @changed, $column;
			next;#Valores definidos
		}
		
		if ($column =~ /^(lock)$/) { $value = $self->param($column) == 1 ? '1' : '0'; }
		#must be filled
		next if !$value && $column =~ /dominio|servicos|status|servidor|pg'/;
		
		$self->template($column, $value);
		$self->Controller::Services::insert_data($column, $value);
		push @changed, $column;
	}
			
	#Qualidade de dados
	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	if (scalar @$nonchanged == 0) {
		$self->Controller::Services::insert;
		$self->unlock_billing;
	}

	$self->parse('/service_new');
}

*services_list = \&service_list;
sub service_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_list')) if $self->perm('services','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $sstatus = $self->param('status');
	my $platform = $self->param('plataforma') || $filter if $filter;
	my $sstatusf = $self->SStatusMatch($filter) if $filter;
	my $saction = $self->SActionMatch($filter) if $filter;
	my $date = $self->datefromformat($filter) if $filter;
	my $valor = $self->Float($filter) || undef if $filter =~ m/^[\d\W]+$/;
	my $username = $self->num($self->param('username'));
	my $id = $self->num($self->param('id'));
	my $invoice = $self->num($self->param('invoice'));
	
	my $sql_789 = $self->{queries}{789};
	my $sql_783 = $self->{queries}{783};
	my $sql_782 = $self->{queries}{782};
	
	if ($username > 0) {
		$sql_789 .= " AND s.`username` = $username";
		$sql_783 .= " AND s.`username` = $username";
		$sql_782 .= " AND s.`username` = $username";
	}
	if ($id > 0) {
		$sql_789 .= " AND s.`id` = $id";
		$sql_783 .= " AND s.`id` = $id";
		$sql_782 .= " AND s.`id` = $id";
	}
	if ($invoice > 0) {
		$sql_789 .= " AND (s.`invoice` = 0 OR s.`invoice` IS NULL)";	 
		$sql_783 .= " AND (s.`invoice` = 0 OR s.`invoice` IS NULL)";
		$sql_782 .= " AND (s.`invoice` = 0 OR s.`invoice` IS NULL)";
	}	
	
	my $appen = $self->param('status')
		? qq| AND s.`status` LIKE ?| : undef;
	
	$sql_789 .= $appen;
	$sql_783 .= $appen;	
	
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		
		#Replace temporario para condizer com a fake view
		$order[0] = 's`.`'.$order[0] if ($order[0] =~ m/^(id|username|servicos)$/);
		$order[0] = 'pl`.`'.$order[0] if ($order[0] =~ m/^(tipo)$/); 
		$order[0] = 'pl`.`nome' if ($order[0] =~ /^(servicos)$/); #pl.`nome`
		$order[0] = 'srv.`nome' if ($order[0] =~ /^(servidor)$/); #srv.`nome` 
		$order[0] = 'pg.`nome' if ($order[0] =~ /^(pg)$/); #pg.`nome`	
	
		push @orderby, qq|`$order[0]` $order[1]|;
	}
	$sql_789 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;	
	$sql_783 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_782 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;	 	 

	my @columns = ('username', 'dominio', 'plano', 'status', 'tipo', 'plataforma', 'inicio', 'fim', 'vencimento', 'proximo', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'action', 'invoice', 'pagos', 'desconto', 'lock');

	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'id');
	$col = 's`.`'.$col if ($col =~ m/^(id|username|servicos)$/);
	$col = 'pl`.`'.$col if ($col =~ m/^(tipo)$/); 
	$col = 'pl`.`nome' if ($col =~ /^(servicos)$/); #pl.`nome`
	$col = 'srv`.`nome' if ($col =~ /^(servidor)$/); #srv.`nome` 
	$col = 'pg`.`nome' if ($col =~ /^(pg)$/); #pg.`nome`	
	
	$sql_789 =~ s/`\?`/`$col`/;

	my @list = $filter
					? $col 
						? $self->param('status')
							? $self->get_services($sql_789,$filter,$sstatus || '%',$offset,$limit)	
							: $self->get_services($sql_789,$filter,$offset,$limit)				 
						: $self->param('status') 
							? $self->get_services($sql_783,($filter)x14,$saction,$valor,$date,$date,$date,$sstatusf,$sstatus || '%',$offset,$limit)
							: $self->get_services($sql_783,($filter)x14,$saction,$valor,$date,$date,$date,$sstatusf,$offset,$limit)
					: $self->get_services($sql_782,$self->param('status') || '%',$offset,$limit);					

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_services_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $sid (@list) {
			$self->sid($sid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);
						
			foreach (@columns) {
				#Attr
				my $attrs = $self->templateAttr($_);
				$attrs->{'value'} = $self->service($_);				
				if (m/inicio|fim|vencimento|proximo/) {
					$self->template($_, $self->dateformat($self->service($_)));
				} elsif (m/pg|plano|servidor/) {
					$self->template($_, $self->service($_.'_nome'));
				} elsif ($_ eq 'desconto') {
					$self->template($_, $self->Currency($self->service($_),1));					
				} else {
					$self->template($_, $self->service($_));
				}
			}
			$self->template('id',$sid);
			my $attrs = $self->templateAttr('id');
			$attrs->{'value'} = $sid;
			$self->template('status', $self->SStatus($self->service('status')));	
			$self->template('action', $self->SAction($self->service('action')));			
				
			$self->parse_var('rows','/row_services');
		}
	}

	$self->parse('/service_list');
}

sub service_list_field {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_list_field')) if $self->perm('services','view','deny') == 1;
	
	my $sid = $self->param('ID');
	return $self->hard_error($self->lang('3','service_list_field')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	$self->template('id',$sid);
	
	my $dados = $self->service('dados');
	my @list = (keys(%$dados), map { Controller::trim($_) } split('::', $self->plan('campos')));
	Controller::iUnique(\@list);
	Controller::iDelete(\@list);
					
	if (scalar @list == 0) {
		$self->parse_var('rows','/row_service_fields_nodata');	
	} else {
		foreach my $field (@list) {
			$self->template('name',$field);
			$self->template('value', $self->service('dados',$field));
			$self->parse_var('rows','/row_service_fields');
		}
	}
	$self->parse('/service_list_field');	
}

sub service_list_multiservers {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_list_multiservers')) if $self->perm('services','view','deny') == 1;
	
	my $sid = $self->param('ID');
	return $self->hard_error($self->lang('3','service_list_multiservers')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	$self->template('id',$sid);

	my %list = map { $_ => $self->service('multi' . lc $_) } ('WEB','DNS', 'FTP', 'DB', 'MAIL', 'STATS');

	$self->get_servers(46,'%');				
	foreach my $field (keys %list) {
		$self->template('name',$field);
		$self->srvid($list{$field}); #Perde Sid
		$self->template('value', $self->srvid ? $self->server('nome') : undef);
		$self->parse_var('rows','/row_service_fields'); #like fields
	}
		
	$self->parse('/service_list_multiservers');	
}

sub service_list_properties {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_list_properties')) if $self->perm('services','view','deny') == 1;
	
	my $sid = $self->param('ID');
	return $self->hard_error($self->lang('3','service_list_properties')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	$self->template('id',$sid);

	foreach my $field (1 .. 7) {
		$self->template('id',$field);
		$self->template('name',$self->lang('propertie'.$field));
		if ($field == 3 && $self->serviceprop($field)) {
			foreach $year (keys %{ $self->serviceprop($field)}) {
				my $prop = $self->serviceprop($field,$year);
				my $value = $self->lang('301',$year,join(', ',@{$prop->{'months'}}),$self->Currency($prop->{'value'})) if $prop->{'value'} > 0;
				$self->template('value', $value);
				$self->template('text', $value);
				$self->parse_var('rows','/row_service_fields'); #like fields
			}				
		} elsif ($field == 7 && $self->serviceprop($field)) {
			$self->template('value', $self->JSON->encode($self->serviceprop($field)));			
			$self->template('text', $self->lang(305,join(',',keys %{ $self->serviceprop($field)})));
			$self->parse_var('rows','/row_service_fields'); #like fields				
		} else {
			$self->template('value', $self->serviceprop($field));
			$self->template('text', 
					$field =~ /^[246]$/ && $self->serviceprop($field)
					?
						$self->lang($self->serviceprop($field) == 1 ? 'Yes' : 'No')
					:
						$self->serviceprop($field)
				);
			$self->parse_var('rows','/row_service_fields'); #like fields
		}
	}
		
	$self->parse('/service_list_properties');	
}

sub service_new_properties {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_new_properties')) if $self->perm('services','edit','deny') == 1;
	
	use Controller::Services;
	
	my $sid = $self->param('ID');
	$self->sid($self->num($sid));
	return $self->hard_error($self->lang('3','service_new_properties')) unless $self->is_valid_service($sid);
	
	my $value = $self->param('value');
	if ( $self->param('json') ) {		
		$value = $self->JSON->decode($self->param('json'));
	} 	
	$self->Controller::Services::insertPropertie($self->param('type'),$value);
	
	$self->parse('/service_new_properties');
}

sub service_remove_properties {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_remove_properties')) if $self->perm('services','edit','deny') == 1;
	
	use Controller::Services;
	
	my $sid = $self->param('id');
	$self->sid($self->num($sid));
	return $self->hard_error($self->lang('3','service_remove_properties')) unless $self->is_valid_service($sid);	
	my @errors;
	foreach my $type (split ',', $self->param('type')) { #Loop para questões de LOG
		$self->Controller::Services::removePropertie($type);
		push @errors, $self->clear_error if $self->error;
	}
	$self->set_error(join "\n", @errors) if scalar @errors;
	
	$self->parse('/service_remove_properties');
}

sub service_view {
	my ($self) = shift;	
		
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_view')) if $self->perm('services','view','deny') == 1;
	
	my $sid = $self->param('ID');
	return $self->hard_error($self->lang('3','service_view')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	foreach ('username', 'dominio', 'servicos', 'status', 'tipo', 'plataforma', 'inicio', 'fim', 'vencimento', 'proximo', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'action', 'invoice', 'pagos', 'desconto', 'lock', 'parcelas','notes') {
		if (m/inicio|fim|vencimento|proximo/) {
			$self->template($_, $self->dateformat($self->service($_)));
		} elsif (m/desconto/) {
			$self->template($_, $self->Currency($self->service($_),1));
		} else {
			$self->template($_, $self->service($_));
		}
	}
	$self->template('id',$sid);
	$self->template('motivo',$self->service('motivo')) if $self->service('status') eq $self->SERVICE_STATUS_CANCELADO ||  $self->service('status') eq $self->SERVICE_STATUS_FINALIZADO;
	
	#Options
	my $fields = $self->{dbh}->column_info(undef, undef, 'servicos', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('status','action') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){
			$self->option_enabled( $mysql_values->[$a] eq $self->service($_) ? 1 : 0);		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'status') {
				$self->template('option_text',$self->SStatus($mysql_values->[$a]));
			} elsif ($_ eq 'action') {
				$self->template('option_text',$self->SAction($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}
	
	#Dates
	my ($pdate,$bdate,$rdate) = $self->exec_dates;
	$self->template('pdate',$self->dateformat($pdate));
	$self->template('bdate',$self->dateformat($bdate));
	$self->template('rdate',$self->dateformat($rdate));	
						
	$self->parse('/service_view');
}

sub service_options {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_options')) if $self->perm('services','options','deny') == 1;
	
	my $sid = $self->param('ID');
	return $self->hard_error($self->lang('3','service_options')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	$self->template('id',$sid);
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);	

	#Servidores	
	my @srvids = $self->get_servers(46,$self->OSMatch($self->plan('plataforma')));
	#Pagamentos
	my @payments = $self->get_payments(1031,$self->service('servicos'));
	#Planos
	my @pids = 	($self->service('servicos'));	
	
	$self->template('servicos',$self->service('servicos'));
	$self->template('servidor',$self->service('servidor'));
	$self->template('pg',$self->service('pg'));
	
	#Losting reference
	$self->sid(0);
	#Servidores
	foreach (@srvids) {
		$self->srvid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$_ eq $self->template('servidor') ? $self->option_enabled(1) : $self->option_enabled(0);			
		$self->template('option_value',$_);
		$self->template('option_text',$self->server('nome'));		
		$self->parse_var('options_servidor','/option');
	}
	
	#Planos
	foreach (@pids) {
		$self->pid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->template('servicos') ? 1 : 0);		
		$self->template('option_value',$_);
		$self->template('option_text',$self->plan('nome'));					
		$self->parse_var('options_planos','/option');
	}

	#Pagamentos
	foreach (@payments) {
		$self->payid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->template('pg') eq $_ ? $self->option_enabled(1) : $self->option_enabled(0);				
		$self->template('option_value',$_);
		$self->template('option_text',$self->payment('nome'));
		my $item = $self->parse_var('options_pg','/option');
		my $parcela = $self->parcela;
		$item->setAttribute('max',$self->Currency($parcela,1));
	}
	
	$self->parse('/service_options');
}

sub service_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_update')) if $self->perm('services','update','deny') == 1;
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  
	
	my $sid = $self->param('id');
	return $self->hard_error($self->lang('3','service_update')) unless $self->is_valid_service($sid);
	$self->sid($sid);

	my (@tobechanged, @noerror);
	my $reFilled = qr/^(dominio|servicos|status|inicio|vencimento|servidor|pg|action|parcelas)$/;
	#'username', utilize o transfer para alterar o username 
	my @fields = ('dominio', 'servicos', 'status', 'inicio', 'fim', 'vencimento', 'proximo', 'servidor', 'dados', 'useracc', 'pg', 'envios', 'def', 'action', 'invoice', 'pagos', 'desconto', 'lock', 'parcelas','notes');

	my $fields = $self->{dbh}->column_info(undef, undef, 'servicos', '%')->fetchall_hashref('COLUMN_NAME');
	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless defined($value);
		
		#Com valores para update
		push @tobechanged, $column;		
					
		#Erros, next
		if ($column =~ /^(invoice)$/ && $self->is_valid_invoice($value) && $self->invoice('status') ne $self->INVOICE_STATUS_PENDENTE && $self->invoice('status') ne $self->INVOICE_STATUS_CONFIRMATION) {		#Neste topico a ordem é importante
			next if $value != $self->service('invoice'); #Não pode associar uma fatura que já foi quitada ou cancelada
			$value = undef;
		}
		next if ($column =~ /^(vencimento)$/ && $self->is_valid_invoice($self->service('invoice')) && $self->datefromformat($value) != $self->service($column)); #Não pode ser alterado o vencimento sem cancelar antes a fatura
		next if ($column =~ /^(servicos)$/ && !$self->is_valid_plan($value));
		next if ($column =~ /^(pg)$/ && !$self->is_valid_payment($value));
		next if ($column =~ /^(servidor|pg|parcelas)$/ && !$self->num($value));
		next if ($column =~ /^(invoice)$/ && $self->num($value) < 0); #permite zero	
		$value = $self->datefromformat($value) if $value ne '0000-00-00' && $column =~ /^(inicio|fim|vencimento|proximo)$/;
		$value = $self->Float($value) if $column =~ /^(desconto)$/;
		next if $column =~ /^(status|action)$/ && !grep { $value eq $_} @{ $fields->{$column}->{mysql_values} }; 	
		if ($column =~ /^(dados)$/) { #Casos especias, verificacao de antigo
			foreach (split('::', $self->param($column))) {
				my ($col,$val) = split(' : ',$_);
				$self->service('dados',$col,$val);
			}
			next;
		}		
		
		#Regras
		next if
		$value &&
		#Ao ser definido uma data de fim, o status tem que ficar finalizado		
		($column =~ /^(fim)$/ && $self->param('status') ne $self->SERVICE_STATUS_FINALIZADO);
		
		next if
		!$value &&
		#Ao ser definido o status finalizado sem ter uma data de fim
		($column =~ /^(fim)$/ && $self->param('status') eq $self->SERVICE_STATUS_FINALIZADO);		
        
        next if
        $value &&
        #Ao ser definido uma data de inicio, o status tem que ficar diferente de finalizado     
        ($column =~ /^(inicio)$/ && $self->param('status') eq $self->SERVICE_STATUS_FINALIZADO);
        
        next if
        !$value &&
        #Ao ser definido o status não for o finalizado ter que se ter uma data de inicio
        ($column =~ /^(inicio)$/ && $self->param('status') ne $self->SERVICE_STATUS_FINALIZADO);		
				
		#must be filled
		next if !$value && $column =~ $reFilled;		
		#Erros normais
		push @noerror, $column;		
				
		$self->service($column, $value); 
		$self->template($column, $value);
	}
	
	#Qualidade de dados
	my ($nonchanged) = Controller::iDifference(\@tobechanged,\@noerror);
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->Controller::Services::save;
	
	$self->parse('/service_update');
}

sub service_transfer {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_transfer')) if $self->perm('services','update','deny') == 1;
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  
	
	my $sid = $self->param('id');
	return $self->hard_error($self->lang('3','service_transfer')) unless $self->is_valid_user($self->param('touser')) && $self->is_valid_service($sid);
	$self->sid($sid);
	
	$self->Controller::Services::service_exec('tf','','','','',$self->param('touser'));
	
	if ($self->param('invoice') == 1 && $self->service('invoice') > 0) { #Transferir a fatura junto
		return $self->hard_error($self->lang('3','service_transfer')) unless $self->is_valid_invoice($self->service('invoice'));
		$self->execute_sql(488,$self->param('touser'),$self->service('invoice'));
	}
	
	$self->parse('/service_transfer');	
}

sub service_changepg {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_changepg')) if $self->perm('services','update','deny') == 1;
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  
	
	my $sid = $self->param('id');
	return $self->hard_error($self->lang('3','service_changepg')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	my $payid = $self->num($self->param('payment'));
	return $self->hard_error($self->lang('3','service_changepg')) unless $self->is_valid_payment($payid);
	
	$self->service('pg',$payid);
	if ($self->param('apply') == 1) {
		$self->cancel_invoice;
		$self->service('envios',0);
		$self->('def',
			$self->service('vencimento') ?  $self->today() + $self->setting('dias_prorrogado') - $self->service('vencimento') : 0
		);				
	}
	$self->service('desconto', $self->Float($self->param('discount'))) if defined $self->param('discount');
	$self->service('parcelas', $self->param('installments') > 1 ? int $self->param('installments') : 1) if defined $self->param('installments');
	
	$self->Controller::Services::save;
	
	$self->parse('/service_changepg');	
}

sub service_action {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_action')) if $self->perm('services','update','deny') == 1;
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  
	
	my $sid = $self->param('id');
	return $self->hard_error($self->lang('3','service_action')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	$self->service_exec($self->param('action'),$self->param('parcial'),'','','','', $self->param('reason'));
	
	$self->parse('/service_action');
}

sub service_updatefield {
	my ($self) = shift;
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_updatefield')) if $self->perm('services','update','deny') == 1;
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  
	
	my $sid = $self->param('id');
	return $self->hard_error($self->lang('3','service_updatefield')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	$self->service('dados', $self->param('name'), $self->param('value'));
	$self->Controller::Services::save if $self->param('name') && defined $self->param('value');
	
	$self->parse('/service_updatefield');	
}

sub service_removefield {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_removefield')) if $self->perm('services','update','deny') == 1;
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  
	
	my $sid = $self->param('id');
	return $self->hard_error($self->lang('3','service_removefield')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	
	my $name = Controller::trim($self->param('name'));
	my $ref = $self->service(); #load data
	$self->service('dados',$name,''); #tell to change
	delete $ref->{'dados'}{$name};
	
	$self->Controller::Services::save if $name;
	
	$self->parse('/service_updatefield');	
}

sub service_upgrade {
	my $self = shift;
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_upgrade')) if $self->perm('services','update','deny') == 1;
	
	my $sid = $self->param('id');
	return $self->hard_error($self->lang('3','service_upgrade')) unless $self->is_valid_service($sid);
	$self->sid($sid);
	my $newpid = $self->param('plan');
	my $oldpid = $self->pid;
		
	return $self->set_error($self->lang('302',$self->service('dominio'))) if $self->service('status') ne $self->SERVICE_STATUS_ATIVO;

	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);
	
	my $valor = $self->change_plan($newpid);
	$self->service('action',$self->SERVICE_ACTION_MODIFY);
	$self->Controller::Services::save;
	
	#templates
	$self->template('saldo',$self->Currency($valor));
		
	#Colocar action M para agendar, se surgir necessida colocar para criar imediatamente	
	unless ($self->error){			
		my $descrc = $self->lang(602,$oldpid,$self->service('dominio'),$newpid);
		$self->execute_sql(445,$self->uid,$valor,$descrc,undef,undef) if $valor != 0;
		my $dd = $self->service('vencimento') - $self->today;
		if ($self->param('apply') == 1) {
			$self->cancel_invoice;
		}
	return $self->set_error($self->lang(304)) if $dd < 0;
	$dd = 0 if $dd <= $self->setting('altplan'); #Zera adicionais #VARIABILIDADE - DIAS CONCEDIDOS AOS CLIENTES MUDAREM O PLANO SEM ADICIONAIS
	$dv = $v/$self->payment('pintervalo');
	}
	
	$self->parse('/service_upgrade');
}

sub service_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_remove')) if $self->perm('services','delete','deny') == 1;
	
	use Controller::Services;
	
	my @errors;
	foreach my $sid (split ',', $self->param('id')) { #Loop para questões de LOG
		$self->sid($self->num($sid));
		next unless $self->is_valid_service($sid);
		$self->Controller::Services::remove;
		push @errors, $self->clear_error if $self->error;
	}
	$self->set_error(join "\n", @errors) if scalar @errors;
	
	$self->parse('/service_remove');
}

sub service_prorate {
	my ($self) = shift;
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','service_prorate')) if $self->perm('services','update','deny') == 1;
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);
	
	my $sid = $self->param('id');
	my $new_venc = $self->datefromformat($self->param('vencimento'));	
	return $self->hard_error($self->lang('3','service_prorate')) unless $self->is_valid_service($sid) && $new_venc;	
	$self->sid($sid);
	
	my $valor = $self->prorate($new_venc); #Novo vencimento
	$self->service('vencimento', $new_venc);

	$self->Controller::Services::save;
	
	my $coud = $valor > 0 ? $self->lang('f_credit') :  $self->lang('f_debit');	
	$self->template('motivo',$self->lang(61,$coud,$self->Currency(abs $valor)));
	
	$self->parse('/service_prorate');	
}

*plans_list = \&plan_list;
sub plan_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_list')) if $self->perm('plans','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'servicos DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $platform = $self->param('plataforma') || $filter if $filter;
	my $tipo = $self->param('tipo') || $filter if $filter;
	my $valor_tipo = $self->PriceTypeMatch($filter) if $filter;
	my $valor = $self->Float($filter) || undef if $filter =~ m/^[\d\W]+$/;
	my $id = $self->num($self->param('plano'));

	my $sql_609 = $self->{queries}{609};	
	my $sql_606 = $self->{queries}{606};
	my $sql_605 = $self->{queries}{605};
	
	if ($id > 0) {
		$sql_609 .= " AND `servicos` = $id";
		$sql_606 .= " AND `servicos` = $id";
		$sql_605 .= " AND `servicos` = $id";
	}
	
	my $sql = $self->param('plataforma') 
		? qq| AND `plataforma` LIKE CONCAT('%',?,'%')|
		: qq| OR `plataforma` LIKE CONCAT('%',?,'%')|;
	$sql_609 .= $sql;
	$sql_606 .= $sql;  
	$sql = $self->param('tipo')
		? qq| AND `tipo` LIKE CONCAT('%',?,'%')|
		: qq| OR `tipo` LIKE CONCAT('%',?,'%')|;
	$sql_609 .= $sql;
	$sql_606 .= $sql;
	  		
	my @notid = map { $self->num($_) } split ',', $self->param('notid');
	$sql_605 .= qq| AND `servicos` NOT IN (|.join(',', @notid).qq|)| if @notid;
	$sql_606 .= qq| AND `servicos` NOT IN (|.join(',', @notid).qq|)| if @notid;

	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}
	$sql_609 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;	
	$sql_606 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_605 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;	
	
	my @columns = ('level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'auto', 'pagamentos', 'alert', 'pservidor');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'servicos');
	$sql_609 =~ s/`\?`/`$col`/;
	
	my @list = $filter
				? $col
					? $self->get_plans($sql_609,$filter,$offset,$limit) #TODO colocar filtro por valor, valor_tipo e plataforma também
					: $self->get_plans($sql_606,($filter)x7,$valor,$valor,$valor_tipo,$platform,$tipo,$offset,$limit)
				: $self->get_plans($sql_605,$self->param('plataforma') || '%', $self->param('tipo') || '%',$offset,$limit);
	
	if (scalar @list == 0) {
		$self->parse_var('rows','/row_plans_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $pid (@list) {
			$self->pid($pid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);
						
			foreach (@columns) {
				if (m/setup|valor/) {
					$self->template($_, $self->Currency($self->plan($_),1));					
				} else {
					$self->template($_, $self->plan($_));
				}
			}
			$self->template('id',$pid);
			$self->template('servicos',$pid);
			$self->template('valor_tipo', $self->PriceType($self->plan('valor_tipo')));				
				
			$self->parse_var('rows','/row_plans');
		}
	}

	$self->parse('/plan_list');
}

sub plan_list_field {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_list_field')) if $self->perm('plans','view','deny') == 1;
	
	my $pid = $self->param('ID');
	$self->pid($pid);
	
	$self->template('campos', $self->plan('campos'));
	$self->template('id',$pid);
	
	my @list = split('::', $self->template('campos'));
				
	if (scalar @list == 0) {
		$self->parse_var('rows','/row_plan_fields_nodata');	
	} else {
		foreach my $field (@list) {
			$self->template('nome',$field);
			$self->template('text',$self->lang($field) =~ m/^missing_/i ? $field : $self->lang($field));       
			$self->parse_var('rows','/row_plan_fields');
		}
	}
	$self->parse('/plan_list_field');	
}

sub plan_list_discount {
	my ($self) = shift;	
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);
		
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_list_discount')) if $self->perm('plans','view','deny') == 1;
	
	my $pid = $self->param('ID');
	$self->pid($pid);
	
	#Pagamentos
	my @payments = $self->get_payments(1031,$self->pid); #pagamentos com desconto para o plano
	if (scalar @payments == 0) {
		$self->parse_var('rows','/row_plan_discounts_nodata');	
	} else {
		foreach my $id (@payments) {
			$self->payid($id);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
			$self->option_enabled( $self->payment('valor') ? 1 : 0);
			$self->template('id',$self->payment('did'));				
			$self->template('pg',$id);
			$self->template('nome',$self->payment('nome'));
			$self->template('valor',$self->Currency($self->payment('valor'),1));
			my $parcela = $self->parcela;
			$self->template('max',$self->Currency($parcela,1));
			$self->template('total',$self->Currency($parcela - $self->payment('valor'),1));
			
			$self->parse_var('rows','/row_plan_discounts');
		}
	}	
	
	$self->parse('/plan_list_discount');	
}

sub plan_prenew {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_prenew')) if $self->perm('plans','new','deny') == 1;	

	my $pid = $self->param('plan');
	$self->pid($pid);

	if ($self->pid) {
		foreach ('level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert', 'pservidor', 'modulo') {
			if (m/^(setup|valor)$/) {
				$self->template($_, $self->Currency($self->plan($_),1));					
			} else {
				$self->template($_, $self->plan($_));
			}
		}
	}
						
	#Options
	my $fields = $self->{dbh}->column_info(undef, undef, 'planos', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('valor_tipo','plataforma','tipo') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){		
			$self->option_enabled( $mysql_values->[$a] eq $self->plan($_) ? 1 : 0) if $self->pid;
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'valor_tipo') {
				$self->template('option_text',$self->PriceType($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');
			$a++;
		}	
	}
	
	#servidores
	my @srvids = $self->get_servers(46,'%');
	foreach (@srvids) {
		$self->option_enabled( $_ eq $self->plan('pservidor') ? 1 : 0) if $self->pid;
		$self->srvid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->template('option_value',$_);
		$self->template('option_text',$self->server('nome'));		
		my $item = $self->parse_var('options_servidor','/option');
		$item->setAttribute('plataforma',$self->OS($self->server('os')));
	}
	#modulos
	#selected value
	foreach ( '', $self->list_modules) {
		$self->option_enabled( $_ eq $self->plan('modulo') ? 1 : 0) if $self->pid;
		$self->template('option_value',$_);
		$self->template('option_text',$_);
		$self->template('option_text',$self->lang('Default')) if $_ eq '';
		$self->parse_var('options_modulo','/option');
	}
	#Pagamentos
	my @payments = $self->payments;
	#selected value
	foreach (@payments) {		
		$self->payid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO	
		$self->pid && $self->plan('pagamentos') =~ /(^|::)$_(::|$)/ ? $self->option_enabled(1) : $self->option_enabled(0);			
		$self->template('option_value',$_);
		$self->template('option_text',$self->payment('nome'));
		$self->parse_var('options_pagamentos','/option');
	}
	#Empresas
	foreach ($self->enterprises) {		
		$self->entid($_);
		$self->pid && $self->plan('level') =~ /(^|::)$_(::|$)/ ? $self->option_enabled(1) : $self->option_enabled(0);					
		$self->template('option_value',$_);
		$self->template('option_text',$self->enterprise('nome'));
		$self->parse_var('options_empresas','/option');		
	}	
				
	$self->parse('/plan_prenew');
}

sub plan_new {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_new')) if $self->perm('plans','new','deny') == 1;
	
	#Selecionando plano
	my $sth = $self->select_sql(607);
	my $ref = $sth->fetchrow_hashref() if $sth;
	$self->finish;
	$self->template('plano',$ref->{'plano'});
	$self->set_error($self->lang(1000)), return unless $ref->{'plano'};

	my (@changed, %insert_data);
	my @fields = ('level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert','pservidor','notes');
	my $fields = $self->{dbh}->column_info(undef, undef, 'planos', '%')->fetchall_hashref('COLUMN_NAME');
	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value || $column =~ /descricao|campos|setup|auto|pagamentos|alert|pservidor|notes/);
		
		#Erros, next
		next if ($column eq 'pservidor' and !$self->is_valid_server($value));
  	
		$value = $self->Float($value) if $column =~ /^(setup|valor)$/;
		next if $column =~ /^(plataforma|tipo|valor_tipo)$/ && !grep { $value eq $_} @{ $fields->{$column}->{mysql_values} }; 
		if ($column =~ /^(level|campos|pagamentos)$/) { 
			my @nivel = split '::', $value;
			Controller::iUnique( \@nivel );
			$value = scalar @nivel > 0 ? join("::",@nivel) . "::" : undef;
		}
		
		if ($column =~ /^(alert)$/) { $value = $self->param($column) == 1 ? '1' : '0'; }
		#must be filled
		next if !$value && $column =~ /nome|plataforma|tipo|valor'/;
		
		
		push @changed, $column;
		$insert_data{$column} = $value;
		$self->template($column, $value);				
	}

	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	my @insert;
	push @insert, $insert_data{$_} foreach @fields;
	
	$self->execute_sql(602,$ref->{'plano'},@insert) if scalar @$nonchanged == 0; #Não retorna ID pois não é autoincremento
	die $self->error if $self->error;
	
	#SALVAR , 'modulo'
	if ($self->param('modulo')) {
		$self->execute_sql(621,$ref->{'plano'},$self->param('modulo'));
	}
	
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/plan_new');	
}

sub plan_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_view')) if $self->perm('plans','view','deny') == 1;
	
	my $pid = $self->param('ID');
	$self->pid($pid);
	
	foreach ('level', 'plataforma', 'nome', 'tipo', 'descricao', 'campos', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert', 'pservidor', 'modulo','notes') {
		if (m/^(setup|valor)$/) {
			$self->template($_, $self->Currency($self->plan($_),1));					
		} else {
			$self->template($_, $self->plan($_));
		}
	}
	$self->template('id',$pid);
	$self->template('servicos',$pid);
	
	#Options
	my $fields = $self->{dbh}->column_info(undef, undef, 'planos', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('valor_tipo','plataforma','tipo') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){
			$self->option_enabled( $mysql_values->[$a] eq $self->plan($_) ? 1 : 0);		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'valor_tipo') {
				$self->template('option_text',$self->PriceType($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');
			$a++;
		}	
	}
	
	#servidores
	my @srvids = $self->get_servers(46,'%');
	foreach (@srvids) {
		$self->option_enabled( $_ eq $self->plan('pservidor') ? 1 : 0);		
		$self->srvid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->template('option_value',$_);
		$self->template('option_text',$self->server('nome'));		
		my $item = $self->parse_var('options_servidor','/option');
		$item->setAttribute('plataforma',$self->OS($self->server('os')));
	}
	#modulos
	#selected value
	foreach ( '', $self->list_modules) {
		$self->option_enabled( $_ eq $self->plan('modulo') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$_);
		$self->template('option_text',$self->lang('Default')) if $_ eq '';
		$self->parse_var('options_modulo','/option');
	}
	#Pagamentos
	my @payments = $self->get_payments(1031,$self->pid);
	#selected value
	foreach (@payments) {
		$self->payid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->plan('pagamentos') =~ /(^|::)$_(::|$)/ ? $self->option_enabled(1) : $self->option_enabled(0);				
		$self->template('option_value',$_);
		$self->template('option_text',$self->payment('nome'));
		$self->parse_var('options_pagamentos','/option');
	}
	#Empresas
	foreach ($self->enterprises) {
		$self->entid($_);
		$self->plan('level') =~ /(^|::)$_(::|$)/ ? $self->option_enabled(1) : $self->option_enabled(0);				
		$self->template('option_value',$_);
		$self->template('option_text',$self->enterprise('nome'));
		$self->parse_var('options_empresas','/option');		
	} 
	
	#Statistics
	my $sth = $self->select_sql(784,$self->pid);
	while(my $ref = $sth->fetchrow_hashref()) {
		$self->template('option_value',$ref->{'total'});
		$self->template('option_text',$self->SStatus($ref->{'status'}));
		$self->parse_var('statistics','/option');
	}
		
	$self->parse('/plan_view');
}

sub plan_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_update')) if $self->perm('plans','update','deny') == 1;
		
	my $pid = $self->param('plano');
	$self->pid($pid);

	my @srvids = $self->get_servers(46,$self->OSMatch($self->param('plataforma')));
	unless ( grep { $_ == $self->param('pservidor')} @srvids ) {
		$self->param('pservidor',1); #undef pservidor invalido
	}
	
	my (@changed,@set);
	my @fields = ('level', 'plataforma', 'nome', 'tipo', 'descricao', 'setup', 'valor', 'valor_tipo', 'auto', 'pagamentos', 'alert','pservidor','notes');
	foreach my $column (@fields) {
		my $value = $self->param($column);
		#Erros normais
		next unless (defined $value || $column =~ /descricao|campos|setup|auto|pagamentos|alert|pservidor|notes/);
				
		#Erros, next
		if ($column =~ /^(alert)$/) { $value = $self->param($column) == 1 ? '1' : '0'; }
		if ($column =~ /^(level|pagamentos)$/) { 
			my @nivel = split '::', $value;
			#Casos especias, verificacao de antigo
			my @nivelold = split '::', $self->param($column.'_old');
			if (@nivelold && $self->param($column.'_old') ne $self->plan($column)) {
				my ($diffnova) = Controller::iDifference([split '::', $self->plan($column)], \@nivelold );
				push @nivel, @$diffnova; #merge da diferenca do novo com o velho.
			}
			Controller::iUnique( \@nivel );
			$value = scalar @nivel > 0 ? join("::",@nivel) . "::" : undef;			
		}
		$value = $self->Float($value) if $column =~ /^(setup|valor)$/;
		next if ($column =~ /^(pservidor)$/ && !$self->num($value));	

		#Erros normais
		next if $value eq $self->plan($column);
		push @changed, $column;
		push @set, $value;
				
		$self->plan($column, $value);
		$self->template($column, $value);
	}

	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	$self->Controller::save($self->TABLE_PLANS,\@changed,\@set,['servicos'],[$self->pid]) if @set;
	
	#SALVAR , 'modulo'
	if ($self->param('modulo') ne $self->plan('modulo')) {
		$self->execute_sql(621,$self->pid,$self->param('modulo')) ;
		Controller::iDelete($nonchanged, '==', 'modulo');
	}
	
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/plan_update');
}

sub plan_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_remove')) if $self->perm('plans','delete','deny') == 1;
	
	my @pids = split(',', $self->param('id'));

	my $sql_787 = $self->{queries}{787};
	#Selecionando serviço com o plano
	$sql_787 .= qq| IN (|.join(',', @pids).qq|)| if @pids;
	my $sth = $self->select_sql($sql_787);  
	my @refused = keys %{ $sth->fetchall_hashref('plano') } if $sth;
	$self->finish;
	#Verificando permitidos para exclusão
	my ($goahead,$trowerror) = Controller::iDifference(\@pids,\@refused);
		
	foreach my $pid (@$goahead) { #Loop para questões de LOG		
		$self->execute_sql(601,$pid);
	}
	
	$self->set_error($self->lang(1001,join(',',@$trowerror))) if scalar @$trowerror;
	
	$self->parse('/plan_remove');
}

sub plan_new_field {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_new_field')) if $self->perm('plans','update','deny') == 1;
	
	my $pid = $self->param('plano');
	$self->pid($pid);
	
	push my @nivel, (split '::', $self->plan('campos')); #merge da diferenca do novo com o velho.
	push @nivel, $self->param('name');
	Controller::iUnique( \@nivel );
	my $value = scalar @nivel > 0 ? join("::",@nivel) . "::" : undef;
	
	$self->Controller::save($self->TABLE_PLANS,['campos'],[$value],['servicos'],[$self->pid]) if $value;

	$self->template('nonchanged', []);
	$self->template('nonchanged', []);

	$self->parse('/plan_new_field');
}

sub plan_remove_field {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_remove_field')) if $self->perm('plans','update','deny') == 1;
	
	my $pid = $self->param('plano');
	$self->pid($pid);
	
	my $value = $self->plan('campos');
	foreach my $exclude (split ',', $self->param('name')) {
		$value =~ s/\Q$exclude\E(?:\:\:|$)//g;
	}
	
	$self->Controller::save($self->TABLE_PLANS,['campos'],[$value],['servicos'],[$self->pid]) if $value ne $self->plan('campos');

	$self->template('nonchanged', []);
	
	$self->parse('/plan_remove_field');
}

sub plan_new_discount {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_new_discount')) if $self->perm('plans','update','deny') == 1;

	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  
	
	my $pid = $self->param('plano');
	$self->pid($pid);
	$self->payid($self->param('pg'));
	
	my $desc = $self->Float($self->param('desconto')) if $self->payid;
	$self->execute_sql(641,$self->pid,$self->payid,$desc) if $desc && $desc <= $self->parcela;

	$self->template('nonchanged', []);
	
	$self->parse('/plan_new_discount');
}

sub plan_remove_discount {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','plan_remove_discount')) if $self->perm('plans','update','deny') == 1;
	
	my $did = $self->param('id');
	
	foreach (split ',', $did) {
		$self->execute_sql(642,$_);
	}
	
	$self->parse('/plan_remove_discount');
}

sub invoice_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_list')) if $self->perm('invoices','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');;
	my $istatus = $self->param('status') || $self->IStatusMatch($filter) if $filter;
	my $stmttype = $self->InstallmentTypeMatch($filter) if $filter;
	my $username = $self->num($self->param('username'));
	my $id = $self->num($self->param('id'));
	my $date = $self->datefromformat($filter) if $filter;
	my $valor = $self->Float($filter) || undef if $filter =~ m/^[\d\W]+$/;
	
	my $sql_455 = $self->{queries}{455};
	my $sql_436 = $self->{queries}{436};
	my $sql_435 = $self->{queries}{435};
	
	if ($username > 0) {
		$sql_455 .= " AND `username` = $username";
		$sql_436 .= " AND `username` = $username";
		$sql_435 .= " AND `username` = $username";
	}
	if ($id > 0) {
		$sql_455 .= " AND `id` = $id";
		$sql_436 .= " AND `id` = $id";
		$sql_435 .= " AND `id` = $id";
	}	
	
	my $sql = $self->param('status')
		? qq| AND `status` LIKE ?|
		: qq| OR `status` LIKE ?|;
	$sql_455 .= $sql;
	$sql_436 .= $sql;
		
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_455 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_436 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_435 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @columns = ('username', 'status', 'nome', 'data_envio', 'data_vencido', 'data_vencimento', 'data_quitado', 'envios', 'referencia', 'services', 'valor', 'valor_pago', 'imp', 'conta', 'tarifa', 'parcelas', 'parcelado', 'nossonumero');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns);
	$sql_455 =~ s/`\?`/`$col`/;
	
	my @list = $filter
				? $col
					? $self->get_invoices($sql_455,$filter,$offset,$limit) #TODO filtro por data, istatus stmttype
					: $self->get_invoices($sql_436,($filter)x8,$stmttype,$date,$date,$date,$date,$valor,$valor,$istatus,$offset,$limit)
				: $self->get_invoices($sql_435,$self->param('status') || '%',$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_invoices_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $invid (@list) {
			$self->invid($invid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach (@columns) {
				#Attr
				my $attrs = $self->templateAttr($_);
				$attrs->{'value'} = $self->invoice($_);
				if (m/data_envio|data_vencimento|data_quitado|data_vencido/) {
					$self->template($_, $self->dateformat($self->invoice($_)));
				} elsif (m/valor_pago|valor/) {
					$self->template($_, $self->Currency($self->invoice($_),1));				
				} elsif (m/services/) {
					$self->template($_, join ',', keys %{$self->invoice($_)});
				} else {
					$self->template($_, $self->invoice($_));
				}
			}

			$self->template('id',$invid);
			my $attrs = $self->templateAttr('id');
			$attrs->{'value'} = $invid;
			
			$self->template('status', $self->IStatus($self->invoice('status')));
			$self->template('parcelado', $self->InstallmentType($self->invoice('parcelado')));				
			
			$self->parse_var('rows','/row_invoices');
		}
	}	

	$self->parse('/invoice_list');
}

sub invoice_prenew {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_prenew')) if $self->perm('invoices','new','deny') == 1;	

	#Options
	my $fields = $self->{dbh}->column_info(undef, undef, 'invoices', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('status','parcelado') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){
			$self->option_enabled( $mysql_values->[$a] eq 'S' ? 1 : 0);		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'status') {
				$self->template('option_text',$self->IStatus($mysql_values->[$a]));
			} elsif ($_ eq 'parcelado') {
				$self->template('option_text',$self->InstallmentType($mysql_values->[$a]));					
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}	
				
	$self->parse('/invoice_prenew');
}

sub invoice_new {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_new')) if $self->perm('invoices','new','deny') == 1;
	return $self->set_error($self->lang('3','invoice_new')) if !$self->is_valid_user($self->param('username'));

	my (@changed, %insert_data);
	
	#Default values;
	$self->param('status', $self->INVOICE_STATUS_PENDENTE);	
	
	my @fields = ('status','nome','data_vencimento','data_quitado','referencia','services','valor','valor_pago','conta','tarifa','parcelas','parcelado');
	my $fields = $self->{dbh}->column_info(undef, undef, 'invoices', '%')->fetchall_hashref('COLUMN_NAME');
	foreach my $column (@fields) {
		my $value = $self->param($column);
		
		#Erros normais
		next unless (defined $value || $column =~ /^(data_envio|data_vencido|data_quitado|envios|services|valor_pago|imp|nossonumero)$/);
		
		#Erros, next
		$value = undef if ($column eq 'conta' and !$self->is_valid_account($value));
		$value = undef if ($column eq 'tarifa' and !$self->is_valid_tax($value));
  	
  		$value = $self->datefromformat($value) if $value ne '0000-00-00' && $column =~ /^data_/;
		$value = $self->Float($value) if $column =~ /^(valor)$/;
		next if $column =~ /^(status|parcelado)$/ && !grep { $value eq $_} @{ $fields->{$column}->{mysql_values} }; 
		$value = 1 if $column =~ /^(parcelas)$/ and $value < 1;

		#must be filled
		next if !$value && $column =~ /^(status|nome|data_vencimento|referencia|valor)$/;
				
		#Valores zerados para uma fatura pendente
		$value = undef if $column =~ /^(data_vencido|data_quitado|envios|services|valor_pago|imp|nossonumero)$/; #Não tem valor no insert
		
		push @changed, $column;		
		$insert_data{$column} = $value;
		$self->template($column, $value);
	}
	
	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	my @insert;
	push @insert, $insert_data{$_} foreach @fields;
	
	#Usando o pacote sem perder a referência
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro); 
	
	$self->create_invoice(@insert) if scalar @$nonchanged == 0;
	die $self->error if $self->error;
		
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/invoice_new');
}

sub invoice_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_view')) if $self->perm('invoices','view','deny') == 1;
	
	my $invid = $self->param('ID');
	$self->invid($invid);
	
	foreach ('username', 'status', 'nome', 'data_envio', 'data_vencido', 'data_vencimento', 'data_quitado', 'envios', 'referencia', 'services', 'valor', 'valor_pago', 'imp', 'conta', 'tarifa', 'parcelas', 'parcelado', 'nossonumero', 'confirmado') {
		if (m/data_envio|data_vencimento|data_quitado|data_vencido|confirmado/) {
			$self->template($_, $self->dateformat($self->invoice($_)));
		} elsif (m/valor_pago|valor/) {
			$self->template($_, $self->Currency($self->invoice($_),1));
		} elsif (m/services/) {
			$self->template($_, join ',', keys %{$self->invoice($_)}) if $self->invoice($_);												
		} else {
			$self->template($_, $self->invoice($_));
		}
	}
	$self->template('id',$invid);
	$self->template('emails',$self->user('emails'));
				
		
	#Options
	my $fields = $self->{dbh}->column_info(undef, undef, 'invoices', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('status','parcelado') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){
			$self->option_enabled( $mysql_values->[$a] eq $self->invoice($_) ? 1 : 0);		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'status') {
				$self->template('option_text',$self->IStatus($mysql_values->[$a]));
			} elsif ($_ eq 'parcelado') {
				$self->template('option_text',$self->InstallmentType($mysql_values->[$a]));					
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}

	#Forma
	#selected value
	foreach ($self->taxs) {
		$self->tid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->invoice('tarifa') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->tax('tipo'));					
		$self->parse_var('options_tarifa','/option');
		$self->template('modulo',$self->tax('modulo')) if $_ eq $self->invoice('tarifa');
	}			

	#Contas
	#selected value
	foreach ($self->accounts) {
		$self->actid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->invoice('conta') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->account('nome'));
		$self->parse_var('options_conta','/option');
	}
	
	my $cryptkey = $self->encrypt($self->invoice('username').'/'.$self->user('inscricao').'/'.$self->invid);
	$self->template('link_boleto',
		$self->setting('baseurl').'/boleto.cgi?noclick=1&key='.Controller::URLEncode($cryptkey));	
	
	$self->parse('/invoice_view');
}

sub invoice_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_update')) if $self->perm('invoices','update','deny') == 1;
	
	my $invid = $self->param('id');
	$self->invid($invid);
	
	my (@changed,@set);
	my @fields = ('status', 'nome', 'data_vencimento', 'data_quitado', 'referencia', 'valor', 'valor_pago', 'conta', 'tarifa', 'parcelas', 'parcelado');
	
	foreach my $column (@fields) {
		my $value = $self->param($column);
		#Erros normais		
		next unless defined($value);
					
		#Erros, next
		next if ($column =~ /^(envios|imp|conta|tarifa|parcelas)$/ && !$self->num($value));		
		$value = $self->datefromformat($value) if $value ne '0000-00-00' && $column =~ /^data_/;
		$value = $self->Float($value) if $column =~ /^valor|valor_pago/;
		
		#Erros normais
		next if $value eq $self->invoice($column);
		push @changed, $column;
		push @set, $value;
				
		$self->invoice($column, $value); 
		$self->template($column, $value);
	}
	
	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	$self->lock_billing if @set;
	
	$self->Controller::save($self->TABLE_INVOICES,\@changed,\@set,['id'],[$self->invid]) if @set;
	
	$self->execute_sql(479,undef,$self->invid) if @set && grep { $_ eq 'tarifa' } @changed;
		
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/invoice_update');
}

sub invoice_send {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_send')) if $self->perm('invoices','send','deny') == 1;
	
	my $invid = $self->param('id');
	$self->template('id', $invid);
	$self->invid($invid);
	$self->tid($self->invoice('tarifa'));
	my $sbj = 'sbj_invoice'; #TODO colocar um sbj pra cada

	$self->actid($self->invoice('conta'));
	
	if ($self->is_boleto_module($self->tax('modulo'))) {
		$sbj = 'sbj_boleto';
		eval "use ".$self->tax('modulo');
		my $boleto = eval "new ".$self->tax('modulo');
		$boleto->boleto();
		my $cryptkey = $self->encrypt($self->invoice('username').'/'.$self->user('inscricao').'/'.$self->invid);
		$self->template('link_boleto',
		$self->setting('baseurl').'/boleto.cgi?key='.Controller::URLEncode($cryptkey));
		$self->template('link',$self->template('link_boleto'));#suportar links antigos		
		$self->template('linhadigitavel', $boleto->linhadigitavel);
	} elsif ($self->tax('modulo') eq 'deposito') {
		$sbj = 'sbj_deposito';
		$self->template('agencia', $self->account('agencia'));
		$self->template('contacorrente', $self->account('conta'));
		$self->template('favorecido', $self->account('cedente'));
		$self->template('codbanco', $self->account('banco'));
		$self->template('banco', $self->account('nome'));
	} elsif ($self->is_creditcard_module($self->tax('modulo'))) {
		$sbj = 'sbj_cartao';
	} elsif ($self->is_creditcard_module($self->tax('modulo'))) { 
		#RETURN that cannot send email
    } elsif ($self->is_financeiro_module($self->tax('modulo'))) {                 
        eval "use ".$self->tax('modulo');
        my $finan = eval "new ".$self->tax('modulo');
        unless ($finan->doBilling()) { #Gerar link para o email
            $err = $self->hard_error($finan->clear_error || $self->lang(85,$self->tax('modulo')));
            $finan->posBilling();
            return $err;
        }
    }

	$self->template('name', $self->user('nome'));
	$self->template('valor_fatura', $self->Currency( $self->invoice('valor') ));
	$self->template('valor_total', $self->Currency( $self->invoice('valor') + $self->tax('valor') ));
	$self->template('venc', $self->dateformat($self->invoice('data_vencimento')));
	$self->template('referencia', $self->invoice('referencia'));
	$self->template('taxa', $self->Currency( $self->tax('valor') ) );

	$self->template('password', $self->param('password'));
	
	my $from = $self->return_sender('Billing');
	my @emails = split ',', $self->param('email');
	Controller::iUnique(\@emails);
	my $to = join ',', grep { $self->is_valid_email($_) } @emails;
	
	my $sent = $self->email( User => $self->uid, To => $to, From => $from, Subject => [$sbj, $self->invoice('nome'), $self->invid], txt => 'cron/'.$self->tax('tplindex').'2');
	
	$self->parse_var($sent,'/email');
		
	$self->parse('/invoice_send');
}

sub invoice_postpone {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_postpone')) if $self->perm('invoices','postpone','deny') == 1;
	
	my $invid = $self->param('id');
	$self->invid($invid);
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  

	my $oldvalor = $self->invoice('valor');
	my $oldvencimento = $self->invoice('data_vencimento');
	
	$self->prorrogar($self->param('multa') ? 0 : 1);
	#Alertar somente
	unless ($self->error) { #cuidado parametros invertidos
		if (($self->invoice('valor') - $oldvalor) != 0) {
			my $coud = $self->invoice('valor') - $oldvalor > 0 ? $self->lang(76): $self->lang(77);
			$self->template('motivo', $self->lang(69,$coud,$self->dateformat($oldvencimento),$self->dateformat($self->invoice('data_vencimento')),$self->Currency(abs ($self->invoice('valor') - $oldvalor))));
		} else {
			$self->template('motivo', $self->lang(70,$self->dateformat($oldvencimento),$self->dateformat($self->invoice('data_vencimento'))));
		}			
	}
		
	$self->parse('/invoice_postpone');
}

sub invoice_due {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_due')) if $self->perm('invoices','due','deny') == 1;
	
	my $invid = $self->param('id');
	$self->invid($invid);
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  

	$self->pay_invoice($self->Float($self->param('valor_pago')),$self->datefromformat($self->param('data_quitado')),$self->param('noemail'));
		
	$self->parse('/invoice_update');
}

sub invoice_confirm {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_confirm')) if $self->perm('invoices','confirm','deny') == 1;
	
	my $invid = $self->param('id');
	$self->invid($invid);
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  

	$self->confirm_invoice;
		
	$self->parse('/invoice_update');
}

sub invoice_pending {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_pending')) if $self->perm('invoices','pending','deny') == 1;
	
	my $invid = $self->param('id');
	$self->invid($invid);
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  

	$self->pending_invoice;
		
	$self->parse('/invoice_update');
}

sub invoice_cancel {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_cancel')) if $self->perm('invoices','cancel','deny') == 1;
	
	my $invid = $self->param('id');
	$self->invid($invid);
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  

	$self->cancel_invoice;
		
	$self->parse('/invoice_update');
}

sub invoice_service { #Add service into invoice
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_service')) if $self->perm('invoices','update','deny') == 1;
	
	my $invid = $self->param('id');
	$self->invid($invid);
	my @list = map { $self->num($_) } split ',', $self->param('services') if $self->param('services');

	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);  

	$self->services_add(@list);
		
	$self->parse('/invoice_update');
}

sub invoice_CNAB {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','invoice_cnab')) if $self->perm('invoices','cnab','deny') == 1;
	
	my $response = $self->responseDocument;
	my $doc = $self->xmlDocument;
	
	use Controller::Financeiro::Boleto;
	push @ISA, qw(Controller::Financeiro::Boleto);  

	my (@tmp) = $self->cnab_ret($self->param('file_hash'));
	my @checkbx = @{$tmp[0]};
	my @val = @{$tmp[1]};
	my @pagamento = @{$tmp[2]};
	my @total = @{$tmp[3]};
	my @invalidos = @{$tmp[4]};
	my @tax = @{$tmp[5]};

	my %err_quitar;
	for (my $c = 0; $c < scalar(@checkbx) ; $c++) {						
		my $invid = $checkbx[$c];
		next if !$invid;
		$self->invid($invid);		
			
		unless ( $self->invoice('status') ) {			
			$err_quitar{$invid} = $self->lang(2304);
			next;
		}		
		if ( $invalidos[$c] == 1 ) {
			$err_quitar{$invid} = $self->lang(2305);
			next;
		}				
		if ($val[$c] <= 0) {
			$err_quitar{$invid} = $self->lang(2302);
			next;
		}
		if (!$pagamento[$c] || !$self->date($pagamento[$c])) {
			$err_quitar{$invid} = $self->lang(2303);
			next;
		}
		if ($self->invoice('username') == 999) { #Test user
			$err_quitar{$invid} = $self->lang(2306);
			$self->invoice('valor_pago',$val[$c]);
			next;
		}
		
		if ($self->invoice('status') && $self->invoice('status') eq $self->INVOICE_STATUS_QUITADO) {
			$self->tid($self->invoice('tarifa'));
			#Já pago, simular valores do boleto e indicar a diferença
			my $threshold = $self->invoice('valor') + $self->tax('valor') - $tax[$c];
			my $dif = $threshold - $val[$c];  
			$self->invoice('valor_pago',$val[$c]);
			$self->set_error($self->lang(2308,$self->Currency($dif))) if sprintf('%.2f',$dif) > 0;
			$self->set_error($self->lang(2307));						
		}
		
		$self->pay_invoice($val[$c],$self->date($pagamento[$c]));
		
		$err_quitar{$invid} = $self->clear_error;
	}
		
	if (scalar @checkbx == 0) {
		$self->parse_var('rows','/row_invoices_nodata');	
	} else {
		for (my $c = 0; my $invid = $checkbx[$c]; $c++) {
			my $item = $doc->createElement('item', $response);
			$self->invid($invid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);
							
			foreach ('username', 'status', 'nome', 'data_envio', 'data_vencido', 'data_vencimento', 'data_quitado', 'envios', 'referencia', 'services', 'valor', 'valor_pago', 'imp', 'conta', 'tarifa', 'parcelas', 'parcelado', 'nossonumero') {
				my $el = $doc->createElement($_, $item);
				my $val = $self->invoice($_);
				$doc->setAttribute('value',$val,$el);
								
				unless ($self->invoice('status') && $invalidos[$c] != 1) {	#Impressao de boletos inválidos		
					if ($_ eq 'data_quitado') {
		 				$self->template('data_quitado',$self->dateformat($self->date($pagamento[$c])));
						$el->setAttribute('value',$self->date($pagamento[$c]));		 				
		 				$doc->txtElement($self->template($_), $el);		 				
					} elsif ($_ eq 'valor_pago') {
		 				$self->template('valor_pago',$self->Currency($val[$c]));
		 				$el->setAttribute('value',$val[$c]);
		 				$doc->txtElement($self->template($_), $el);	 				
					} else {		 			
						$self->template($_,undef);
					}
					next;
		 		}												
												
				if (m/data_envio|data_vencimento|data_quitado|data_vencido/) {
					$self->template($_, $self->dateformat($self->invoice($_)));
				} elsif (m/valor_pago|valor/) {
					$self->template($_, $self->Currency($self->invoice($_)));
					$el->setAttribute('value',0) unless $self->invoice($_);
				} elsif (m/services/) {
					$self->template($_, join ',', keys %{$self->invoice($_)});
				} elsif (m/status/) {
					$self->template($_,$self->IStatus($self->invoice($_)));
				} elsif (m/parcelado/) {
					$self->template($_,$self->InstallmentType($self->invoice($_)));					
				}  elsif (m/tarifa/) {
					$self->tid($self->invoice($_));
					$self->template($_,$self->tax('tipo'));					
				} elsif (m/conta/) {
					$self->actid($self->invoice($_));
					$self->template($_,$self->account('nome'));					
				} else {
					$self->template($_, $self->invoice($_));
				}
				
				$doc->txtElement($self->template($_), $el);
			}
					
			$self->template('id',$invid);
		 	$self->template('tarifa_banco',$self->Currency($tax[$c]));							
			$self->template('error', $err_quitar{$invid});		 	
		 	
			$self->clear_error;
			
			foreach ('id', 'error', 'tarifa_banco') {
				my $el = $doc->createElement($_, $item, $self->template($_));
				$el->setAttribute('value',$tax[$c]) if $_ eq 'tarifa_banco';
			}
		}
	}
		
	$self->template('file_hash', $self->param('file_hash'));
			
	$self->parse('/invoice_CNAB');
}

sub balance_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','balance_list')) if $self->perm('balances','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $bstatus = $self->param('status') if $filter;
	my $valor = $self->Float($filter) || undef if $filter =~ m/^[\d\W]+$/;
	my $username = $self->num($self->param('username'));
	my $id = $self->num($self->param('id'));
	
	my $sql_457 = $self->{queries}{457};
	my $sql_452 = $self->{queries}{452};
	my $sql_451 = $self->{queries}{451};
	
	if ($username > 0) {
		$sql_457 .= " AND `b`.`username` = $username";
		$sql_452 .= " AND `b`.`username` = $username";
		$sql_451 .= " AND `b`.`username` = $username";
	}
	if ($id > 0) {
		$sql_457 .= " AND `b`.`id` = $id";
		$sql_452 .= " AND `b`.`id` = $id";
		$sql_451 .= " AND `b`.`id` = $id";
	}
		
	my $sql = $self->param('status')
		? qq| AND IFNULL(`i`.`status`,'O') LIKE ?|
		: qq| OR IFNULL(`i`.`status`,'O') LIKE ?|;
	$sql_457 .= $sql;
	$sql_452 .= $sql;
		
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_457 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_451 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_452 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;	

	my @columns = ('username', 'valor', 'descricao', 'servicos', 'invoice', 'bstatus');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns);
	$sql_457 =~ s/`\?`/`$col`/;
	
	my @list = $filter
				? $col 
					? $self->get_balances($sql_457,$filter,$bstatus,$offset,$limit)
					: $self->get_balances($sql_452,($filter)x5,$valor,$bstatus,$offset,$limit)
				: $self->get_balances($sql_451,$self->param('status') || '%',$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_balances_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $balanceid (@list) {
			$self->balanceid($balanceid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach (@columns) {							
				if (m/valor/) {
					$self->template($_, $self->Currency($self->balance($_),1));
				} else {
					$self->template($_, $self->balance($_));
				}
			}

			$self->template('id',$balanceid);
			
			$self->parse_var('rows','/row_balances');
		}
	}	

	$self->parse('/balance_list');
}

sub balance_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','balance_view')) if $self->perm('balances','view','deny') == 1;
	
	my $bid = $self->param('ID');
	$self->balanceid($bid);
	
	#'id'
	foreach ('username', 'valor', 'descricao', 'servicos', 'invoice') {
		if (m/valor/) {
			$self->template($_, $self->Currency($self->balance($_),1));
		} else {
			$self->template($_, $self->balance($_));
		}
	}
	$self->template('id',$bid);
	$self->template('name',$self->user('cnpj') && $self->user('empresa') ? $self->user('empresa') : $self->user('name'));
		
	$self->parse('/balance_view');
}

sub balance_new {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','balance_new')) if $self->perm('balances','new','deny') == 1;
	
	$self->set_error($self->lang('600')), return unless $self->param('username');
	$self->set_error($self->lang('601')), return unless $self->Float($self->param('valor')) != 0;
	$self->execute_sql(445,$self->param('username'),$self->Float($self->param('valor')),$self->param('descricao'),undef,undef);
		
	$self->parse('/balance_new');
}

sub balance_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','balance_update')) if $self->perm('balances','update','deny') == 1;
	
	my $bid = $self->param('id');
	
	$self->execute_sql(448,$self->param('username'),$self->Float($self->param('valor')),$self->param('descricao'),$bid) if $bid;
		
	$self->parse('/balance_update');
}

sub balance_remove {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','balance_remove')) if $self->perm('balances','remove','deny') == 1;
	
	my @bid = map { $self->num($_) } split ',', $self->param('id');
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);	
	
	foreach (@bid) {
		$self->balanceid($_);
		
		$self->cancel_invoice() if ($self->is_valid_invoice($self->balance('invoice')));

		my $sql_440 = $self->{queries}{440};
		$sql_440 .= qq| AND `|.$self->TABLE_BALANCES.qq|`.`id` = ?|;
	
		$self->execute_sql($sql_440,'O',$_);
	}
		
	$self->parse('/balance_remove');
}

sub credit_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','credit_list')) if $self->perm('credits','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $cstatus = $self->param('status') if $filter;
	my $valor = $self->Float($filter) || undef if $filter =~ m/^[\d\W]+$/;
	my $username = $self->num($self->param('username'));
	my $id = $self->num($self->param('id'));
	
	my $sql_489 = $self->{queries}{489};
	my $sql_484 = $self->{queries}{484};
	my $sql_483 = $self->{queries}{483};
	
	if ($username > 0) {
		$sql_489 .= " AND `username` = $username";
		$sql_484 .= " AND `username` = $username";
		$sql_483 .= " AND `username` = $username";
	}
	if ($id > 0) {
		$sql_489 .= " AND `id` = $id";
		$sql_484 .= " AND `id` = $id";
		$sql_483 .= " AND `id` = $id";
	}
	
	my $sql = $self->param('status')
		? qq| AND IF(`valor` > 0,'P','U') LIKE CONCAT('%',?,'%')|
		: qq| OR IF(`valor` > 0,'P','U') LIKE CONCAT('%',?,'%')|;
	$sql_489 .= $sql;
	$sql_484 .= $sql;
	
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_489 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_484 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_483 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;	
	
	my @columns = ('username', 'valor', 'descricao');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'id');
	$sql_489 =~ s/`\?`/`$col`/;
	
	my @list = $filter
					? $col 				
						? $self->get_credits($sql_489,$filter,$cstatus,$offset,$limit)
						: $self->get_credits($sql_484,($filter)x3,$valor,$cstatus,$offset,$limit)
					: $self->get_credits($sql_483,$self->param('status') || '%',$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_credits_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $creditid (@list) {
			$self->creditid($creditid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach (@columns) {							
				if (m/valor/) {
					$self->template($_, $self->Currency($self->credit($_),1));
				} else {
					$self->template($_, $self->credit($_));
				}
			}

			$self->template('id',$creditid);
			
			$self->parse_var('rows','/row_credits');
		}
	}	

	$self->parse('/credit_list');
}

sub credit_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','credit_view')) if $self->perm('credits','view','deny') == 1;
	
	my $cid = $self->param('ID');
	$self->creditid($cid);
	$self->uid($self->credit('username'));
	
	#'id'
	foreach ('username', 'valor', 'descricao', 'servicos', 'invoice') {
		if (m/valor/) {
			$self->template($_, $self->Currency($self->credit($_),1));
		} else {
			$self->template($_, $self->credit($_));
		}
	}
	$self->template('id',$cid);
	$self->template('name',$self->user('cnpj') && $self->user('empresa') ? $self->user('empresa') : $self->user('name'));
		
	$self->parse('/credit_view');
}

sub credit_new {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','credit_new')) if $self->perm('credits','new','deny') == 1;
	
	$self->set_error($self->lang('620')), return unless $self->param('username');
	$self->set_error($self->lang('621')), return unless $self->Float($self->param('valor')) != 0;
	
	use Controller::Financeiro;
	push @ISA, qw(Controller::Financeiro);
	$self->create_credit($self->param('username'),$self->Float($self->param('valor')),$self->param('descricao'),undef);
		
	$self->parse('/credit_new');
}

sub credit_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','credit_update')) if $self->perm('credits','update','deny') == 1;
	
	my $cid = $self->param('id');
	
	$self->execute_sql(480,$self->param('username'),$self->Float($self->param('valor')),$self->param('descricao'),$cid) if $cid;
		
	$self->parse('/credit_update');
}

sub credit_remove {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','credit_remove')) if $self->perm('credits','remove','deny') == 1;
	
	my @cid = map { $self->num($_) } split ',', $self->param('id');
	
	if (scalar @cid == 1) {
		$self->creditid($cid[0]);
		$self->balanceid($self->credit('balance'));
		if ($self->credit('balance') && $self->balance('invoice') > 0) {
			$self->set_error($self->lang('622',$self->balance('invoice'))), return if $self->get_invoices(433,$self->INVOICE_STATUS_CANCELED,$self->balance('invoice')) >= 1; #nao pode ter fatura existente associada
		}
	}

	my $sql_462 = $self->{queries}{462};
	$sql_462 .= qq| AND `|.$self->TABLE_CREDITS.qq|`.`id` IN (|.join(',', @cid).qq|)| if @cid;
	$self->execute_sql($sql_462,'O') if @cid;
		
	$self->parse('/credit_remove');
}

sub account_prenew {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','bankaccount_prenew')) if $self->perm('accounts','new','deny') == 1;

	#Bancos
	$self->option_enabled(0);
	foreach ($self->banks) {
		$self->bankid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->template('option_value',$_);
		$self->template('option_text',$self->bank('nome'));					
		$self->parse_var('options_banco','/option');
	}
					
	$self->parse('/account_prenew');
}

sub account_new {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','account_new')) if $self->perm('accounts','new','deny') == 1;
			
	my (@changed, %insert_data);
	my @fields = ('nome','banco','dvbanco','agencia','conta','carteira','convenio','cedente','instrucoes','nossonumero');

	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value || $column =~ /^(dvbanco|convenio|carteira|instrucoes|nossonumero)$/); #TODO rever essa condição que já é imposta na condição abaixo, posso remover essa então?
		
		#must be filled
		next if !$value && $column =~ /^(nome|banco|agencia|conta|cedente)$/;		
		
		push @changed, $column;
		$insert_data{$column} = $value;
		$self->template($column, $value);				
	}
	
	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
		
	my @insert;
	push @insert, $insert_data{$_} foreach @fields;
	
	$self->execute_sql(422,@insert) if scalar @$nonchanged == 0;
	die $self->error if $self->error;	
				
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/account_new');	
}

sub account_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','account_list')) if $self->perm('accounts','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $id = $self->num($self->param('id'));
	
	my $sql_429  = $self->{queries}{429};
	my $sql_425  = $self->{queries}{425};
	my $sql_424 = $self->{queries}{424};
	
	if ($id > 0) {
		$sql_429 .= " AND `id` = $id";
		$sql_425 .= " AND `id` = $id";
		$sql_424 .= " AND `id` = $id";
	}	
	
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}
	$sql_429 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;	
	$sql_425 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_424 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @columns = ('nome','banco','dvbanco','agencia','conta','carteira','convenio','cedente','instrucoes','nossonumero');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'id');
	$sql_429 =~ s/`\?`/`$col`/;
	
	my @list = $filter
				? $col
					? $self->get_accounts($sql_429,$filter,$offset,$limit)
					: $self->get_accounts($sql_425,($filter)x10,$offset,$limit)
				: $self->get_accounts($sql_424,$offset,$limit);

	$self->banks;
	
	if (scalar @list == 0) {
		$self->parse_var('rows','/row_accounts_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $actid (@list) {
			$self->actid($actid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach (@columns) {	
				if (m/agencia|conta/) {
					my @value = ( $self->account($_), $self->account($_.'dv') );
					$self->template($_, join('-', grep(defined, @value)));
				} else {
					$self->template($_, $self->account($_));
				}		
			}
				
			$self->template('id',$actid);
			$self->bankid($self->account('banco'));
			$self->template('banco_nome',$self->bank('nome'));
			
			$self->parse_var('rows','/row_accounts');
		}
	}	

	$self->parse('/account_list');
}

sub account_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','account_view')) if $self->perm('accounts','view','deny') == 1;
	
	my $actid = $self->param('ID');
	$self->actid($actid);
	
	#'id'
	foreach ('nome','banco','dvbanco','agencia','conta','carteira','convenio','cedente','instrucoes','nossonumero') {
		if (m/agencia|conta/) {
			my @value = ( $self->account($_), $self->account($_.'dv') );
			$self->template($_, join('-', grep(defined, @value)));
		} else {
			$self->template($_, $self->account($_));
		}
	}
	$self->template('id',$actid);

	#Bancos
	#selected value
	foreach ($self->banks) {
		$self->bankid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->account('banco') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->bank('nome'));
		$self->parse_var('options_banco','/option');
	}
		
	$self->parse('/account_view');
}

sub account_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','account_update')) if $self->perm('accounts','update','deny') == 1;
	
	my $actid = $self->param('id');
	$self->actid($actid);
	
	my (@changed,@set);
	my @fields = ('nome','banco','dvbanco','agencia','conta','carteira','convenio','cedente','instrucoes','nossonumero');
	foreach my $column (@fields) {
		my $value = $self->param($column);
		#Erros normais
		next unless (defined $value);
				
		#Erros, next
		next if ($column =~ /^(agencia|conta|carteira|banco)$/ && !$self->num($value));	

		#Erros normais
		next if $value eq $self->account($column);
		push @changed, $column;
		push @set, $value;
				
		$self->account($column, $value); 
		$self->template($column, $value);
	}

	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	$self->Controller::save($self->TABLE_ACCOUNTS,\@changed,\@set,['id'],[$self->actid]) if @set;
		
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/account_update');
}

sub account_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','account_remove')) if $self->perm('accounts','delete','deny') == 1;
	
	my @ids = split(',', $self->param('id'));

	my $sql_428 = $self->{queries}{428};
	#Selecionando faturas com conta
	$sql_428 .= qq| IN (|.join(',', @ids).qq|)| if @ids;
	my $sth = $self->select_sql($sql_428);  
	my @refused = keys %{ $sth->fetchall_hashref('id') } if $sth;
	$self->finish;
	#Verificando permitidos para exclusão
	my ($goahead,$trowerror) = Controller::iDifference(\@ids,\@refused);
		
	foreach my $pid (@$goahead) { #Loop para questões de LOG		
		$self->execute_sql(421,$pid);
	}
	
	$self->set_error($self->lang(1101,join(',',@$trowerror))) if scalar @$trowerror;
	
	$self->parse('/account_remove');
}

sub payment_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','payment_list')) if $self->perm('payments','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $type = $self->InstallmentTypeMatch($self->param('tipo')) if $filter;
	my $pre = $self->param('pre');
	my $plano = $self->param('plano');
	my $id = $self->num($self->param('id'));
	
	my $sql_1038 = $self->{queries}{1038};
	my $sql_1033 = $self->{queries}{1033};
	my $sql_1032 = $self->{queries}{1032};
	
	$self->pid($plano);
	my @ids = split '::', $self->plan('pagamentos') if ($plano);
	
	if ($id > 0) {
		$sql_1038 .= " AND `id` = $id";
		$sql_1033 .= " AND `id` = $id";
		$sql_1032 .= " AND `id` = $id";		
	}
	
	if (@ids) {
		$sql_1038 .= ' AND `id` IN ('.join(',', @ids).')';
		$sql_1033 .= ' AND `id` IN ('.join(',', @ids).')';
		$sql_1032 .= ' AND `id` IN ('.join(',', @ids).')';
	}	
	my @notid = map { $self->num($_) } split ',', $self->param('notid');
	$sql_1038 .= qq| AND `id` NOT IN (|.join(',', @notid).qq|)| if @notid;
	$sql_1033 .= qq| AND `id` NOT IN (|.join(',', @notid).qq|)| if @notid;
	$sql_1032 .= qq| AND `id` NOT IN (|.join(',', @notid).qq|)| if @notid;	
	
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_1038 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_1033 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_1032 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @columns = ('nome','primeira','intervalo','parcelas','pintervalo','tipo','repetir','pre');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'id');
	$sql_1038 =~ s/`\?`/`$col`/;
	
	my @list = $filter
					? $col
						? $self->get_payments($sql_1038,$filter,$offset,$limit)
						: $self->get_payments($sql_1033,($filter)x7,$type,defined $pre ? $pre : '%',$offset,$limit)
					: $self->get_payments($sql_1032,defined $pre ? $pre : '%',$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_payments_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $payid (@list) {
			$self->payid($payid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach (@columns) {							
				if (m/^(pre|repetir)$/) {
					$self->template($_, $self->lang($self->payment($_) ? 'Yes' : 'No') );
				} else {
					$self->template($_, $self->payment($_));
				}
			}

			$self->template('id',$payid);
			$self->template('tipo', $self->InstallmentType($self->payment('tipo')));
			
			$self->parse_var('rows','/row_payments');
		}
	}	

	$self->parse('/payment_list');
}

sub payment_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','payment_view')) if $self->perm('payments','view','deny') == 1;
	
	my $payid = $self->param('ID');
	$self->payid($payid);
	
	#'id'
	foreach ('nome','primeira','intervalo','parcelas','pintervalo','tipo','repetir','pre') {
		$self->template($_, $self->payment($_));
	}
	$self->template('id',$payid);

	my $fields = $self->{dbh}->column_info(undef, undef, 'pagamento', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('tipo') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){
			$self->option_enabled( $mysql_values->[$a] eq $self->payment($_) ? 1 : 0);		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'tipo') {
				$self->template('option_text',$self->InstallmentType($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}
		
	$self->parse('/payment_view');
}

sub payment_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','payment_update')) if $self->perm('payments','update','deny') == 1;
	
	my $payid = $self->param('id');
	$self->payid($payid);
	
	my (@changed,@set);
	my @fields = ('nome','primeira','intervalo','parcelas','pintervalo','tipo','repetir');
	
	foreach my $column (@fields) {
		my $value = $self->param($column);
		#Erros normais
		next unless (defined $value);
				
		#Erros, next
		next if ($column =~ /^(primeira|invertalo|parcelas|pintervalo|repetir)$/ && $self->num($value) < 0); #permite zero
		

		#Erros normais
		next if $value eq $self->payment($column);
		push @changed, $column;
		push @set, $value;
				
		$self->payment($column, $value); 
		$self->template($column, $value);
	}

	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	$self->Controller::save($self->TABLE_PAYMENTS,\@changed,\@set,['id'],[$self->payid]) if @set;
		
	$self->template('nonchanged', \@$nonchanged);
$self->template('nonchanged', []);

	$self->parse('/payment_update');
}

sub payment_prenew {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','payment_prenew')) if $self->perm('payments','new','deny') == 1;	

	#Options
	$self->option_enabled(0);
	my $fields = $self->{dbh}->column_info(undef, undef, 'pagamento', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('tipo') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'tipo') {
				$self->template('option_text',$self->InstallmentType($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}
				
	$self->parse('/payment_prenew');
}

sub payment_new {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','payment_new')) if $self->perm('payments','new','deny') == 1;
	
	my (@changed, %insert_data);
	my @fields = ('nome', 'primeira', 'intervalo', 'parcelas', 'pintervalo', 'tipo', 'repetir');
	my $fields = $self->{dbh}->column_info(undef, undef, 'pagamentos', '%')->fetchall_hashref('COLUMN_NAME');
	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value || $column =~ /primeira/);
		
		#Erros, next 	
		next if $column =~ /^(tipo)$/ && !grep { $value eq $_} @{ $fields->{$column}->{mysql_values} }; 				
		if ($column =~ /^(repetir|parcelas)$/) { $value = $self->param($column) == 1 ? '1' : '0'; }
		if ($column =~ /^(pintervalo)$/) { $value = $self->param('repetir') == 1 ? $self->num($self->param('intervalo')) : $self->num($value); }
		#must be filled
		next if !$value && $column =~ /nome|plataforma|parcelas|intervalo|tipo|repetir'/;		
		
		push @changed, $column;
		$insert_data{$column} = $value;
		$self->template($column, $value);
	}
	
	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	my @insert;
	push @insert, $insert_data{$_} foreach @fields;
	
	$self->execute_sql(1035,@insert) if scalar @$nonchanged == 0;
	die $self->error if $self->error;		
	
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/payment_new');	
}

sub payment_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','payment_remove')) if $self->perm('payments','delete','deny') == 1;
	
	my @ids = split(',', $self->param('id'));

	my $sql_1036 = $self->{queries}{1036};
	#Selecionando servicos com pagamento
	$sql_1036 .= qq| IN (|.join(',', @ids).qq|)| if @ids;
	my $sth = $self->select_sql($sql_1036);  
	my @refused = keys %{ $sth->fetchall_hashref('id') } if $sth;
	$self->finish;
	#Verificando permitidos para exclusão
	my ($goahead,$trowerror) = Controller::iDifference(\@ids,\@refused);
		
	foreach my $payid (@$goahead) { #Loop para questões de LOG		
		$self->execute_sql(1037,$payid);
	}
	
	$self->set_error($self->lang(641,join(',',@$trowerror))) if scalar @$trowerror;
	
	$self->parse('/payment_remove');
}

sub paymentmethod_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','paymentmethod_list')) if $self->perm('taxs','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $visile = $self->param('visible');
	my $id = $self->num($self->param('id'));
	
	my $sql_875 = $self->{queries}{875};
	my $sql_874 = $self->{queries}{874};	
	my $sql_873 = $self->{queries}{873};
	
	if ($id > 0) {
		$sql_875 .= " AND `id` = $id";
		$sql_874 .= " AND `id` = $id";
		$sql_873 .= " AND `id` = $id";
	}
	
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_875 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_874 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_873 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @columns = ('tipo','modo','modulo','valor','tplIndex','autoquitar','visivel');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'id');
	$sql_875 =~ s/`\?`/`$col`/;
	
	my @list = $filter
					? $col
						? $self->get_payments($sql_875,$filter,defined $visile ? $visile : '%',$offset,$limit)
						: $self->get_payments($sql_874,($filter)x7,defined $visile ? $visile : '%',$offset,$limit)
					: $self->get_payments($sql_873,defined $visile ? $visile : '%',$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_paymentmethods_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $tid (@list) {
			$self->tid($tid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach (@columns) {							
				if (m/^(autoquitar|visivel)$/) {
					$self->template($_, $self->lang($self->tax($_) ? 'Yes' : 'No') );
				} else {
					$self->template($_, $self->tax($_));
				}
			}

			$self->template('id',$tid);
			
			$self->parse_var('rows','/row_paymentmethods');
		}
	}	

	$self->parse('/paymentmethod_list');
}

sub server_prenew {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','server_prenew')) if $self->perm('servers','new','deny') == 1;
	
	my $srvid = $self->param('ID');
	$self->srvid($srvid);
	

	if ($self->srvid) {
		#'id'
		foreach ('nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo') {
			$self->template($_, $self->server($_));
		}
	}
	
	#Options
	my $fields = $self->{dbh}->column_info(undef, undef, 'servidores', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('os') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){
			$self->option_enabled( $mysql_values->[$a] eq $self->server($_) ? 1 : 0) if $self->srvid;		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'os') {
				$self->template('option_text',$self->OS($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}
				
	$self->parse('/server_prenew');
}

sub server_new {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','server_new')) if $self->perm('servers','new','deny') == 1;
		
	my (@changed, %insert_data);
	my @fields = ('nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo');
	my $fields = $self->{dbh}->column_info(undef, undef, 'servidores', '%')->fetchall_hashref('COLUMN_NAME');
	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value || $column =~ /username|key|ns1|ns2/);
	
		next if $column =~ /^(os)$/ && !grep { $value eq $_} @{ $fields->{$column}->{mysql_values} }; 		
		if ($column =~ /^(ssl|ativo)$/) { $value = $self->param($column) == 1 ? '1' : '0'; }
		#must be filled
		next if !$value && $column =~ /nome|host|ip|port|os'/;
		
		
		push @changed, $column;
		$insert_data{$column} = $value;
		$self->template($column, $value);				
	}

	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	my @insert;
	push @insert, $insert_data{$_} foreach @fields;
	
	$self->execute_sql(42,@insert) if scalar @$nonchanged == 0; #Não retorna ID pois não é autoincremento
	die $self->error if $self->error;
		
	$self->template('nonchanged', \@$nonchanged);
$self->template('nonchanged', []);

	$self->parse('/server_new');	
}

sub server_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','server_list')) if $self->perm('servers','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $os = $self->OSMatch($self->param('os'));	
	$os ||= $self->OSMatch($filter) if $filter;
	my $id = $self->num($self->param('id'));
	
	my $sql_51 = $self->{queries}{51};
	my $sql_48 = $self->{queries}{48};
	my $sql_47 = $self->{queries}{47};	
	
	if ($id > 0) {
		$sql_51 .= " AND `id` = $id";
		$sql_48 .= " AND `id` = $id";
		$sql_47 .= " AND `id` = $id";
	}
		
	my $sql = $self->param('os') 
		? qq| AND `os` LIKE CONCAT('%',?,'%')|
		: qq| OR `os` LIKE CONCAT('%',?,'%')|;
	$sql_51 .= $sql;
	$sql_48 .= $sql;
		 
	my @notid = map { $self->num($_) } split ',', $self->param('notid');
	$sql_51 .= qq| AND `id` NOT IN (|.join(',', @notid).qq|)| if @notid;
	$sql_48 .= qq| AND `id` NOT IN (|.join(',', @notid).qq|)| if @notid;
	$sql_47 .= qq| AND `id` NOT IN (|.join(',', @notid).qq|)| if @notid;
	
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_51 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_48 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_47 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @columns = ('nome','host','ip','port','ssl','username','ns1','ns2','os','ativo');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'id');
	$sql_51 =~ s/`\?`/`$col`/;
	
	my @list = $filter
					? $col
						? $self->get_servers($sql_51,$filter,$os,$offset,$limit)
						: $self->get_servers($sql_48,($filter)x11,$os,$offset,$limit)
					: $self->get_servers($sql_47,$os || '%',$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_servers_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $srvid (@list) {
			$self->srvid($srvid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach (@columns) { 							
				if (m/^(ssl|ativo)$/) {
					$self->template($_, $self->lang($self->server($_) ? 'Yes' : 'No') );
				} else {
					$self->template($_, $self->server($_));
				}
			}

			$self->template('id',$srvid);
			$self->template('os', $self->OS($self->server('os')));
			
			$self->parse_var('rows','/row_servers');
		}
	}	

	$self->parse('/server_list');
}

sub server_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','server_view')) if $self->perm('servers','view','deny') == 1;
	
	my $srvid = $self->param('ID');
	return $self->hard_error($self->lang('3','server_view')) unless $self->is_valid_server($srvid);
	$self->srvid($srvid);
	
	#'id'
	foreach ('nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo') {
		$self->template($_, $self->server($_));
	}
	$self->template('id',$srvid);

	my $fields = $self->{dbh}->column_info(undef, undef, 'servidores', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('os') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){
			$self->option_enabled( $mysql_values->[$a] eq $self->server($_) ? 1 : 0);		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'os') {
				$self->template('option_text',$self->OS($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}
			
	$self->parse('/server_view');
}

sub server_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','server_update')) if $self->perm('servers','update','deny') == 1;
	
	my $srvid = $self->param('id');
	return $self->hard_error($self->lang('3','server_update')) unless $self->is_valid_server($srvid);
	$self->srvid($srvid);
	
	my (@changed,@set);
	my @fields = ('nome','host','ip','port','ssl','username','key','ns1','ns2','os','ativo');
	
	foreach my $column (@fields) {
		my $value = $self->param($column);
		#Erros normais
		next unless (defined $value);
				
		#Erros normais
		next if $value eq $self->server($column);
		push @changed, $column;
		push @set, $value;
				
		$self->server($column, $value); 
		$self->template($column, $value);
	}

	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	$self->Controller::save($self->TABLE_SERVERS,\@changed,\@set,['id'],[$self->srvid]) if @set;
		
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/server_update');
}	

sub server_list_field {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','server_list_field')) if $self->perm('servers','view','deny') == 1;
	
	my $srvid = $self->param('ID');
	return $self->hard_error($self->lang('3','server_list_field')) unless $self->is_valid_server($srvid);
	$self->srvid($srvid);
	
	$self->template('id',$srvid);
	
	my $fields = $self->{dbh}->column_info(undef, undef, 'servidores_set', '%')->fetchall_hashref('COLUMN_NAME');
	my @list = keys %$fields;
					
	if (scalar @list == 0) {
		$self->parse_var('rows','/row_server_fields_nodata');	
	} else {
		foreach my $field (sort @list) {
			next if $field eq 'id';
			$self->template('name',$field);
			$self->template('value', $self->server(lc $field));
			$self->parse_var('rows','/row_server_fields');
		}
	}
	$self->parse('/server_list_field');	
}

sub server_updatefield {
	my ($self) = shift;
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','server_updatefield')) if $self->perm('servers','update','deny') == 1;
	
	my $srvid = $self->param('id');
	return $self->hard_error($self->lang('3','server_updatefield')) unless $self->is_valid_server($srvid);
	$self->srvid($srvid);
	
	$self->server('nome'); #load data
	$self->server($self->param('name'), $self->param('value'));
	
	$self->execute_sql(49,$self->srvid,$self->server('Rns1'), $self->server('Rns2'), $self->server('Hns1'), $self->server('Hns2'), $self->server('MultiWEB'), $self->server('MultiDNS'), $self->server('MultiMAIL'), $self->server('MultiFTP'), $self->server('MultiSTATS'), $self->server('MultiDB'));
		
	$self->parse('/server_updatefield');	
}

sub server_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','server_remove')) if $self->perm('servers','delete','deny') == 1;
	
	my @srvids = split(',', $self->param('id'));

	my $sql_788 = $self->{queries}{788};
	#Selecionando serviço com o plano
	$sql_788 .= qq| IN (|.join(',', @srvids).qq|)| if @srvids;
	my $sth = $self->select_sql($sql_788);  
	my @refused = keys %{ $sth->fetchall_hashref('servidor') } if $sth;
	$self->finish;
	#Verificando permitidos para exclusão
	my ($goahead,$trowerror) = Controller::iDifference(\@srvids,\@refused);
		
	foreach my $srvid (@$goahead) { #Loop para questões de LOG		
		$self->execute_sql(41,$srvid);
	}
	
	$self->set_error($self->lang(1001,join(',',@$trowerror))) if scalar @$trowerror;

	$self->parse('/server_remove');	
}

sub settings_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','settings_view')) if $self->perm('settings','view','deny') == 1;

	foreach my $n ($self->settings) {
		next if $n =~ /^(crypt|file_path|epreg_old|avgtime|data|version|app|access_rate)$/; #Internas
		$self->template($n, $self->setting($n));
		$self->template($n, $self->setting('osi')) if $n eq 'iso';
		$self->template($n, '****') if $n =~ /_pass|_cappass|_certpass/ && $self->setting($n);
	}

	#Pais
	#selected value
	foreach ($self->country_codes) {
		$self->option_enabled( $_ eq $self->setting('pais') ? 1 : 0);		
		$self->template('option_value',$_);
		$self->template('option_text',$self->country_code($_)->{'name'});					
		$self->parse_var('options_country','/option');
	}

	#Language
	#selected value
	foreach ('',$self->list_langs) {
		$self->option_enabled( $_ eq $self->setting('language') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$_);		
		$self->parse_var('options_language','/option');
	}	
		
	#Skins
	#selected value
	foreach ($self->skins) {
		$self->option_enabled( $_ eq $self->setting('skin') ? 1 : 0);		
		$self->template('option_value',$_);
		$self->template('option_text',$_);					
		$self->parse_var('options_skin','/option');
	}

	#Forma
	#selected value
	foreach ($self->taxs) {
		$self->tid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->setting('forma') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->tax('tipo'));					
		$self->parse_var('options_forma','/option');
	}			

	#Contas
	#selected value
	foreach ($self->accounts) {
		$self->actid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->option_enabled( $_ eq $self->setting('cc') ? 1 : 0);
		$self->template('option_value',$_);
		$self->template('option_text',$self->account('nome'));
		$self->parse_var('options_conta','/option');
	}
	
	#modulos
	#selected value
	foreach my $mod ($self->list_modules) {
		next unless $mod =~ /^SMS::/; 
		$self->option_enabled( $mod eq $self->setting('sms_modulo') ? 1 : 0);
		$self->template('option_value',$mod);
		$self->template('option_text',$mod);
		$self->template('option_text',$self->lang('Default')) if $mod eq '';
		$self->parse_var('options_smsmodulo','/option');
	}

	#servidores
	$self->option_enabled(0);
	my @srvids = $self->get_servers(46,'%');
	foreach (@srvids) {
		$self->srvid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->template('option_value',$_);
		$self->template('option_text',$self->server('nome'));		
		my $item = $self->parse_var('options_servidor','/option');
		$item->setAttribute('plataforma',$self->server('os'));
	}

	#Options
	$self->option_enabled(0);
	my $fields = $self->{dbh}->column_info(undef, undef, 'servicos', '%')->fetchall_hashref('COLUMN_NAME');
	foreach ('status','action') {
		my $a=0;
		my $mysql_values = $fields->{$_}->{mysql_values};
		while($mysql_values->[$a]){		
			$self->template('option_value',$mysql_values->[$a]);
			if ($_ eq 'status') {
				$self->template('option_text',$self->SStatus($mysql_values->[$a]));
			} elsif ($_ eq 'action') {
				$self->template('option_text',$self->SAction($mysql_values->[$a]));
			} else {
				$self->template('option_text',$mysql_values->[$a]);					
			}
			$self->parse_var('options_'.$_,'/option');			
			$a++;
		}	
	}
				
	$self->parse('/settings_view');
}

sub settings_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','settings_update')) if $self->perm('settings','update','deny') == 1;
	
	my (@tobechanged,@changed,@set);
	my @fields = $self->settings;
	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value);
		next if $column =~ /^(crypt|file_path|epreg_old|avgtime|data|version|app|access_rate|license_id)$/; #Internas + license_id
	
		#Com valores para update
		push @tobechanged, $column;
				
		#Erros, next
		if ($column =~ /^(invoices|altmes|altcredito|alertuser|auto_create|auto_suspend|auto_unsuspend|auto_updown|auto_remove|auto_manual|use_email|use_smtp|use_sms)$/) { $value = $self->param($column) == 1 ? '1' : '0';}	

		#Erros normais
		push @changed, $column;
		push @set, $value;
				
		$self->setting($column, $value); 
		$self->template($column, $value);
	}

	my ($nonchanged) = Controller::iDifference(\@tobechanged,\@changed);
	$self->template('nonchanged', \@$nonchanged);
	
	for(my $i = 0; $i < scalar @changed; $i++) {
		$self->Controller::save($self->TABLE_SETTINGS,['value'],[$set[$i]],['setting'],[$changed[$i]]) if defined $set[$i];
	}
		
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/settings_update');
}

sub creditcard_prenew {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','creditcard_prenew')) if $self->perm('creditcards','new','deny') == 1;

	#Forma
	$self->option_enabled(0);
	foreach ($self->taxs) {
		$self->tid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->template('option_value',$_);
		$self->template('option_text',$self->tax('tipo'));					
		$self->parse_var('options_forma','/option');
	}
					
	$self->parse('/creditcard_prenew');
}

sub creditcard_new {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','creditcard_new')) if $self->perm('creditcards','new','deny') == 1;
	return $self->set_error($self->lang('3','creditcard_new')) if !$self->is_valid_user($self->param('username'));

	#Default values;
	$self->param('admin', 1); #Não tem mais utilidade
	$self->param('exp', Controller::monthyear2string(substr('00'.$self->param('month'),-2),substr('00'.$self->param('year'),-2)));	
	#First, Last
	$self->param('first', substr($self->param('ccn'),0,4));
	$self->param('last', substr($self->param('ccn'),-4));
			
	my (@changed, %insert_data);
	my @fields = ('username', 'name', 'first', 'last', 'ccn', 'exp', 'cvv2', 'active', 'tarifa');
	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value || $column =~ /name|first|last/);
		
		#Erros, next
		next if ($column eq 'tarifa' and !$self->is_valid_tax($value));
		next if ($column =~ /ccn/ && length($value) <= 14); #TODO Verificar o cartao direito
		if ($column =~ /ccn|cvv2/) { $value = Controller::encrypt_mm($self->param($column)); }
		next if ($column eq 'exp' and !$self->is_valid_exp($value));
		#must be filled
		next if !$value && $column =~ /username|name|ccn|exp|cvv2|active|tarifa/;		
		
		push @changed, $column;
		$insert_data{$column} = $value;
		$self->template($column, $value);				
	}

	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	#Testando o Cartão
	$self->tid($self->param('tarifa'));
	if ( $self->param('active') != -1 && $self->is_creditcard_module($self->tax('modulo')) && $self->param('cvv2')) {
		eval "use " . $self->tax('modulo');
		my $creditcard = eval "new " . $self->tax('modulo');
		$creditcard->ccid(999999); #teste
		$creditcard->creditcard('ccn',$self->param('ccn'));
		$creditcard->creditcard('cvv2',$self->param('cvv2'));
		$creditcard->creditcard('exp',$self->param('exp'));
					
		if ($creditcard->cc_verify(10.00)) { #TODO definir valor	
			my @insert;
			push @insert, $insert_data{$_} foreach @fields;
			
			my $ccid = $self->execute_sql(854,@insert) if scalar @$nonchanged == 0; #Não retorna ID pois não é autoincremento
			die $self->error if $self->error;
			
			$self->ccid($ccid);
			$self->template('id', $ccid);			
		} else {
			$self->set_error($self->lang(2001,$self->clear_error));
		}
	} else {
		$self->set_error($self->lang(2003,$self->clear_error));
	}
				
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/creditcard_new');	
}

sub creditcard_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','creditcard_list')) if $self->perm('creditcards','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $ccstatus = $self->param('status') || $self->CCStatusMatch($filter) if $filter;
	my $username = $self->num($self->param('username'));
	my $id = $self->num($self->param('id'));

	my $sql_861 = $self->{queries}{861};
	my $sql_860 = $self->{queries}{860};		
	my $sql_859 = $self->{queries}{859};
	
	if ($username > 0) {
		$sql_861 .= " AND `username` = $username";
		$sql_860 .= " AND `username` = $username";
		$sql_859 .= " AND `username` = $username";
	}
	if ($id > 0) {
		$sql_861 .= " AND `id` = $id";
		$sql_860 .= " AND `id` = $id";
		$sql_859 .= " AND `id` = $id";
	}	
	
	my $sql = $self->param('status')
		? qq| AND `active` LIKE ?|
		: qq| OR `active` LIKE ?|;
	$sql_861 .=	$sql;
	$sql_860 .= $sql;
		
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_861 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_860 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_859 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @columns = ('username', 'name', 'first', 'last', 'exp', 'tipo');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'id');
	$sql_861 =~ s/`\?`/`$col`/;
	
	my @list = $filter
					? $col
						? $self->get_creditcards($sql_860,$filter,$ccstatus,$offset,$limit)
						: $self->get_creditcards($sql_860,($filter)x6,$ccstatus,$offset,$limit)
					: $self->get_creditcards($sql_859,defined $self->param('status') ? $self->param('status') : '%',$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_creditcards_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $ccid (@list) {
			$self->ccid($ccid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);

			foreach (@columns) {							
				if (m/exp/) {
					$self->template($_, join('/',Controller::string2monthyear($self->creditcard($_))) );
				} else {
					$self->template($_, $self->creditcard($_));
				}
			}

			$self->template('id',$ccid);
			$self->template('active', $self->CCStatus($self->creditcard('active')));
			$self->template('status', $self->creditcard('active'));		
			
			$self->parse_var('rows','/row_creditcards');
		}
	}	

	$self->parse('/creditcard_list');
}

sub creditcard_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','creditcard_view')) if $self->perm('creditcards','view','deny') == 1;
	
	my $ccid = $self->param('ID');
	$self->ccid($ccid);
	
	#'id'
	foreach ('username', 'name', 'first', 'last', 'exp', 'active', 'tarifa') {
		if (m/exp/) {
			$self->template($_, $self->creditcard($_));
			my @exp = Controller::string2monthyear($self->creditcard($_));
			$self->template('month', $exp[0]);
			$self->template('year', $exp[1]);
		} else {
			$self->template($_, $self->creditcard($_));
		}
	}
	$self->template('id',$ccid);
	
	#Forma
	#selected value
	foreach ($self->taxs) {
		$self->tid($_);#CUIDADO, TIRANDO REFERENCIA DO SERVICO
		$self->template('option_value',$_);
		$self->option_enabled( $self->creditcard('tarifa') == $_ ? 1 : 0 );
		$self->template('option_text',$self->tax('tipo'));		
		$self->parse_var('options_forma','/option');
	}
		
	$self->parse('/creditcard_view');
}

sub creditcard_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','creditcard_update')) if $self->perm('creditcards','update','deny') == 1;
	
	my $ccid = $self->param('id');
	$self->ccid($ccid);
	
	#Default values;
	$self->param('exp', Controller::monthyear2string(substr('00'.$self->param('month'),-2),substr('00'.$self->param('year'),-2)));	
	
	my $reFilled = qr/^(name|exp|tarifa)$/;#|username
	
	my (@tobechanged,@changed,@set,@noerror);
	my @fields = ('name', 'exp', 'cvv2', 'active', 'tarifa');
	
	foreach my $column (@fields) {
		my $value = $self->param($column);
		#Erros normais
		next unless (defined $value);
		
		#Com valores para update
		push @tobechanged, $column;	

		next if ($column eq 'tarifa' and !($self->is_valid_tax($value) and $self->is_creditcard_module($self->tax('modulo'))));
		next if ($column eq 'exp' and !$self->is_valid_exp($value));

		#must be filled
		next if !$value && $column =~ $reFilled;		
				
		#Erros normais
		push @noerror, $column;
		next if $value eq $self->creditcard($column);
		push @changed, $column;
		if ($column =~ /cvv2/) { $value = Controller::encrypt_mm($self->param($column)); }	
		push @set, $value;
				
		$self->creditcard($column, $value); 
		$self->template($column, $value);
	}

	my ($nonchanged) = Controller::iDifference(\@tobechanged,\@noerror);
	
	$self->Controller::save($self->TABLE_CREDITCARDS,\@changed,\@set,['id'],[$self->ccid]) if @set;
		
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/creditcard_update');
}	

sub creditcard_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','creditcard_remove')) if $self->perm('creditcards','delete','deny') == 1;
	
	my $ccid = $self->param('id');
	
	foreach (split ',', $ccid) { #Loop para questões de LOG	
		$self->execute_sql(857,$_);
	}
	
	$self->parse('/creditcard_remove');	
}

sub staff_prenew {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','staff_prenew')) if $self->perm('staffs','new','deny') == 1;
	
	$self->template('minpass',$self->setting('pass_chars'));
	#Departments
	$self->option_enabled(0);
	foreach ($self->departments) {
		$self->deptid($_);#CUIDADO, TIRANDO REFERENCIA
		$self->entid($self->department('level'));
		$self->template('option_value',$_);
		$self->template('option_text',$self->lang('department_name',$self->department('nome'),$self->enterprise('nome')));		
		$self->parse_var('options_department','/option');
	}
	
	#Groups
	$self->option_enabled(0);
	foreach my $group ($self->groups) {
		$self->template('option_value',$group);
		$self->template('option_text',$group);		
		$self->parse_var('options_groups','/option');
	}	
				
	$self->parse('/staff_prenew');
}

sub staff_new {
	my ($self) = shift;	

	return unless $self->check_user();
	return $self->hard_error($self->lang('16','staff_new')) if $self->perm('staffs','new','deny') == 1;

	#Default values;
	$self->param('admin', 1); #Não tem mais utilidade
			
	my (@changed, %insert_data);
	my @fields = ('username','password','name','email','access','notify','responsetime','callsclosed','signature','rkey','lpage','play_sound','llogin','admin','notes');

	foreach my $column (@fields) {
		my $value = $self->param($column);

		#Erros normais
		next unless (defined $value || $column =~ /email|signature|responsetime|callsclosed|rkey|lpage|llogin|admin|access|notes|password/);
		
		#Erros, next
		if ($column =~ /^(email)$/) { $value = $self->is_valid_email($value) == 1 ? $value : undef; }
		if ($column eq 'access') { 
			my @nivel = split '::', $value;
			Controller::iUnique( \@nivel );
			$value = join '::', grep { $self->is_valid_department($_) } @nivel;
			$value = 'GLOB' if ($value eq 'GLOB');
		}  	 		
		if ($column =~ /^(notify|play_sound)$/) { $value = $self->param($column) == 1 ? '1' : '0'; }
		#must be filled
		next if !$value && $column =~ /username|name/;	
		
		push @changed, $column;
		$insert_data{$column} = $value;
		$self->template($column, $value);				
	}

	my ($nonchanged) = Controller::iDifference(\@fields,\@changed);
	
	#Random password
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$self->param('password',$self->randthis($self->setting('pass_chars'),@chars)) unless $self->param('password');
	$insert_data{'password'} = Controller::encrypt_mm($self->param('password'));
	
	my @insert;
	push @insert, $insert_data{$_} foreach @fields;
	
	my $staffid = $self->execute_sql(322,@insert) if scalar @$nonchanged == 0;
	die $self->error if $self->error;
	
	$self->staffid($staffid);
	$self->template('id', $staffid);
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);

	$self->parse('/staff_new');	
}

sub staff_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','staff_list')) if $self->perm('staffs','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');
	my $username = $self->num($self->param('username'));
	my $id = $self->num($self->param('id'));

	my $sql_334 = $self->{queries}{334};
	my $sql_333 = $self->{queries}{333};		
	my $sql_332 = $self->{queries}{332};
	
	if ($username > 0) {
		$sql_334 .= " AND `username` = '$username'";
		$sql_333 .= " AND `username` = '$username'";
		$sql_332 .= " AND `username` = '$username'";
	}
	if ($id > 0) {
		$sql_334 .= " AND `id` = $id";
		$sql_333 .= " AND `id` = $id";
		$sql_332 .= " AND `id` = $id";
	}	
	
	my $sql = $self->param('status')
		? qq| AND IF((SELECT count(*) FROM `online` WHERE `username` = staff.username) > 0,1,0) LIKE ?|
		: qq| OR IF((SELECT count(*) FROM `online` WHERE `username` = staff.username) > 0,1,0) LIKE ?|;
	$sql_334 .= $sql;
	$sql_333 .= $sql;		
		
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	$sql_334 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_333 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_332 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	
	my @columns = ('vencimento','name','empresa','cpf','cnpj','telefone','endereco','numero','cidade','estado','cc','cep','level','rkey','pending','active','acode','lcall','conta','forma','alert','alertinv','news','language');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns,'username');
	$sql_334 =~ s/`\?`/`$col`/;	
	
	my @list = $filter
					? $col
						? $self->get_staffs($sql_334,$filter,$self->param('status'),$offset,$limit)
						: $self->get_staffs($sql_333,($filter)x5,$self->param('status'),$offset,$limit)
					: $self->get_staffs($sql_332,$self->param('status') || '%',$offset,$limit);

	if (scalar @list == 0) {
		$self->parse_var('rows','/row_staffs_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
		
		foreach my $staffid (@list) {
			$self->staffid($staffid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);
				
			#password
			foreach ('id', 'name', 'email', 'notify', 'signature', 'play_sound') {
				if (m/^(play_sound|notify)$/) {
					$self->template($_, $self->lang($self->staff($_) ? 'Yes' : 'No') );
				} else {
					$self->template($_, $self->staff($_));
				}				
			}

			$self->template('username',$staffid);		
			
			$self->parse_var('rows','/row_staffs');
		}
	}	
	
	#Departments
	#selected value
	foreach ($self->departments) {
		$self->deptid($_);#CUIDADO, TIRANDO REFERENCIA
		$self->entid($self->department('level'));
		$self->option_enabled( $self->staff('access') =~ /(^|::)GLOB(::|$)/ ? 1 : $self->staff('access') =~ /(^|::)$_(::|$)/ ? 1 : 0 );
		$self->template('option_value',$_);
		$self->template('option_text',$self->lang('department_name',$self->department('nome'),$self->enterprise('nome')));		
		$self->parse_var('options_department','/option');
	}	

	$self->parse('/staff_list');
}

sub staff_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','staff_view')) if $self->perm('staffs','view','deny') == 1;
	
	my $staffid = $self->param('ID');
	return $self->hard_error($self->lang('3','staff_view')) unless $self->is_valid_staff($staffid);
	$self->staffid($staffid);
	
	#'id','username'
	foreach ('name','email','access','notify','responsetime','callsclosed','signature','rkey','lpage','play_sound','llogin','admin','notes') {
		$self->template($_, $self->staff($_));
	}
	$self->template('id',$staffid); 

	#Departments
	#selected value
	foreach ($self->departments) {
		$self->deptid($_);#CUIDADO, TIRANDO REFERENCIA
		$self->entid($self->department('level'));  
		$self->option_enabled( $self->staff('access') =~ /(^|::)GLOB(::|$)/ ? 1 : $self->staff('access') =~ /(^|::)$_(::|$)/ ? 1 : 0 );
		$self->template('option_value',$_);
		$self->template('option_text',$self->lang('department_name',$self->department('nome'),$self->enterprise('nome')));		
		$self->parse_var('options_department','/option');
	}
	
	#Groups
	#selected value
	my @gids = $self->staffGroups;
	foreach my $group ($self->groups) {
		if (grep { $_ eq $group } @gids) {
			$self->option_enabled(1);
		} else {
			$self->option_enabled(0);
		}
		$self->template('option_value',$group);
		$self->template('option_text',$group);		
		$self->parse_var('options_groups','/option');
	}			
		
	$self->parse('/staff_view');
}

sub staff_update {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','staff_update')) if $self->perm('staffs','update','deny') == 1;
	
	my $staffid = $self->param('id');
	return $self->hard_error($self->lang('3','staff_update')) unless $self->is_valid_staff($staffid);
	$self->staffid($staffid);
	
	my $reFilled = qr/^(name)$/;
	
	my (@changed, @set, @tobechanged, @noerror);
	my @fields = ('name','email','access','notify','signature','play_sound','notes'); #'admin','responsetime','callsclosed','rkey','lpage','llogin'
	
	foreach my $column (@fields) {
		my $value = $self->param($column);
		#Erros normais
		next unless (defined $value);
		
		#Com valores para update
		push @tobechanged, $column;
		
		#Erros, next
		if ($column =~ /^(notify|play_sound)$/) { $value = $self->param($column) == 1 ? '1' : '0'; }
		if ($column =~ /^(email)$/) { $value = $self->is_valid_email($value) == 1 ? $value : undef; }
		if ($column eq 'access') { 
			my @nivel = split '::', $value;
			Controller::iUnique( \@nivel );
			if ($value eq 'GLOB') {
				$value = 'GLOB';
			} else {
				$value = join '::', grep { $self->is_valid_department($_) } @nivel;
			}
		}
		#must be filled
		next if !$value && $column =~ $reFilled;
		
		#Erros normais
		push @noerror, $column;
		next if $value eq $self->staff($column);
				
		push @changed, $column;
		push @set, $value;
				
		$self->staff($column, $value); 
		$self->template($column, $value);
	}

	my ($nonchanged) = Controller::iDifference(\@tobechanged,\@noerror);
	
	$self->Controller::save($self->TABLE_STAFFS,\@changed,\@set,['username'],[$self->staffid]) if @set;
	
	#SALVAR  grupos de acesso
	my @groups = split(',',$self->param('groups'));

	$self->execute_sql(336,$self->staffid);
	foreach my $group (@groups) {
		$self->execute_sql(335,$self->staffid,$group);
	}
		
	$self->template('nonchanged', \@$nonchanged);
	$self->template('nonchanged', []);
	
	$self->parse('/staff_update');
}	

sub staff_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','staff_remove')) if $self->perm('staffs','delete','deny') == 1;
	
	my $staffid = $self->param('id');
	
	foreach (split ',', $staffid) { #Loop para questões de LOG	
		next unless $self->is_valid_staff($_);
		next if $_ eq $self->{cookname} || $_ eq 'admin'; 
		$self->execute_sql(321,$_);
	}
	
	$self->parse('/staff_remove');	
}

sub staff_updatepass {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','staff_updatepass')) if $self->perm('staffs','update','deny') == 1;
		
	my $staffid = $self->param('id');
	return $self->hard_error($self->lang('3','staff_updatepass')) unless $self->is_valid_staff($staffid);
	$self->staffid($staffid);
		
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$self->staff('password',Controller::encrypt_mm($self->param('password')));
	$self->execute_sql(323,$self->staff('password'),$self->randthis(4,@chars),$self->staffid) if $self->param('password');

	if ($self->param('sendmail') == 1) {
		$self->template('user', $self->staffid);
		$self->template('name', $self->staff('name'));
		$self->template('password', $self->param('password'));
		
		my $from = $self->return_sender();
		my $to = join ',', grep { $self->is_valid_email($_) } @{ $self->staff('email') };
		my $sent = $self->email( To => $to, From => $from, Subject => 'sbj_resetpass', txt => 'resetpass');
		$self->parse_var($sent,'/email');	
	}	

	$self->parse('/staff_updatepass');
}

sub staff_resetpass {
	my ($self) = shift;	
		
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','staff_resetpass')) if $self->perm('staffs','update','deny') == 1;

	my $staffid = $self->param('id');
	return $self->hard_error($self->lang('3','staff_resetpass')) unless $self->is_valid_staff($staffid);
	$self->staffid($staffid);
	
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$self->template('password',$self->randthis($self->setting('pass_chars'),@chars));
	$self->staff('password',Controller::encrypt_mm($self->template('password')));	
	$self->execute_sql(323,$self->staff('password'),$self->randthis(4,@chars),$self->staffid);	

	$self->template('user', $self->staffid);
	$self->template('name', $self->staff('name'));
		
	my $from = $self->return_sender();
	my $to = $self->staff('email') if $self->is_valid_email($self->staff('email'));
	my $sent = $self->email( To => $to, From => $from, Subject => 'sbj_resetpass', txt => 'resetpass');
	$self->parse_var($sent,'/email');

	$self->parse('/staff_updatepass');
}

sub logmail_list {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','email_list')) if $self->perm('emails','list','deny') == 1;
	
	my $order = $self->param('order_by') || 'id DESC';
	my $limit = $self->param('limit') || 50;
	my $offset = $self->param('offset') || 0;
	my $filter = length($self->param('keywords')) < $self->setting('search_min') ? undef : $self->param('keywords');;
	my $valor = $self->Float($filter) || undef if $filter =~ m/^[\d\W]+$/;
	my $tzo = $self->{cooktzo} || $self->offset/3600;
	my $username = $self->num($self->param('username')) || '%';
	my $id = $self->num($self->param('id'));
	my $enviado = $self->param('status');
	
	my $sql_166 = $self->{queries}{166};
	my $sql_162 = $self->{queries}{162};
	my $sql_167 = $self->{queries}{167};

	if ($id > 0) {
		$sql_166 .= " AND `id` = $id";
		$sql_162 .= " AND `id` = $id";
		$sql_167 .= " AND `id` = $id";
	}		

	$enviado = '%' if $enviado == 2;
	my $sql = $self->param('status')
		? $enviado == 1 
			? qq| AND `enviado` LIKE ?|
			: qq| AND (`enviado` LIKE ? AND `enviado` != 1)|
		: qq| OR `enviado` LIKE ?|;
	$sql_166 .= $sql;
	$sql_162 .= $sql;
	$sql_167 .= $sql;
		
	my @orderby;
	foreach my $order (split(',',$order)) {
		my @order = split(' ',$order);
		$order[1] = $order[1] =~ /^desc$/i ? 'DESC' : 'ASC';
		$order[0] =~ s/`//gs;
		push @orderby, qq|`$order[0]` $order[1]|;
	}	
	
	$sql_166 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_162 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;
	$sql_167 .= qq| ORDER BY |.join(', ', @orderby).qq| LIMIT ?,?|;

	my @columns = ('byuser', 'user', 'from', 'to', 'subject', 'data', 'tempo', 'enviado');
	
	#Column filter
	my ($col) = grep $_ eq $self->param('column'), (@columns);
	$sql_166 =~ s/`\?`/`$col`/;
				
	my @list = $filter
				? $col
					? $self->get_logmails($sql_166,$filter,$username,$enviado,$offset,$limit)
					: $self->get_logmails($sql_162,$username,($filter)x9,$valor,$enviado,$offset,$limit)
				: $self->get_logmails($sql_167,$username,$enviado,$offset,$limit);


	if (scalar @list == 0) {
		$self->parse_var('rows','/row_users_list_email_nodata');	
	} else {
		#Limit results by settings
		return $self->hard_error($self->lang('19',scalar @list,$self->setting('search_limit'))) if ($self->setting('search_limit') && scalar @list > $self->setting('search_limit'));
			
		foreach my $logmailid (@list) {
			$self->logmailid($logmailid);
			$self->template('class',
					$self->template('class') eq 'odd' ? 'even' : 'odd'
				);
						
			foreach (@columns) {
				if (m/^data$/) {
					$self->template($_, $self->dateformat($self->logmail($_) + Controller::timeadd_offset($self->logmail('tempo'),$tzo,1) ));
				} elsif (m/^tempo/) {
					$self->template($_, Controller::timeadd_offset($self->logmail($_),$tzo));
				} elsif (m/^(byuser)$/) {
					$self->template($_, $self->logmail($_));
				} else {
					$self->template($_, $self->logmail($_));
				}
			}
			$self->template('id',$logmailid);
				
			$self->parse_var('rows','/row_users_list_email');
		}
	}

	$self->parse('/logmail_list');
}


sub logmail_remove {
	my ($self) = shift;		
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','logmail_remove')) if $self->perm('emails','delete','deny') == 1;
	
	my $logmailid = $self->param('id');
	
	foreach (split ',', $logmailid) { #Loop para questões de LOG	
		$self->execute_sql(165,$_);
	}
	
	$self->parse('/logmail_remove');	
}

sub logmail_send {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','logmail_send')) if $self->perm('emails','send','deny') == 1;
		
	my @logmailid = split(',',$self->param('id'));
	@logmailid = (-9999) if scalar @logmailid == 0; #New mail

	my $user = $self->param('username');
	my $from = $self->param('from');
	my $tos = $self->param('to');
	my $subject = $self->param('subject');
	my $body = $self->param('body');	
	$self->logmailid($logmailid);
	
	my $newmail = 0;
	if ($logmailid != -9999) {
		$user = $self->logmail('user');		
		$from ||= $self->logmail('from');
		$tos ||= $self->logmail('to');
		$subject ||= $self->logmail('subject');
		$body ||= $self->logmail('body');
	}
	
	my $to = join ',', grep { $self->is_valid_email($_) } (split ',', $tos);
	$self->set_error($self->lang(3,'logmail_send')) unless $from && $to && $subject && $body; #$user && 
	local $Controller::SWITCH{skip_logmail} = 1;
	my $sent;
	unless ($self->error) {
		$sent = $user > 0 
				? $self->email( User => $user, To => $to, From => $from, Subject => $subject, Body => $body)
				: $self->email( To => $to, From => $from, Subject => $subject, Body => $body)
	}
				
	{
		local $Controller::SWITCH{skip_logmail} = $sent == 1 ? 0 : 1;
		#log_mail
		my $newid = $self->log_mail($user,$from,$to,$subject,$body,$self->error);
		
		unless ($user) {		
			$self->log(
					'cmd' => 'SEND',
					'table' => 'log_email',
					'value' => '',
					'byuser' => $self->{cookname},
					'debug' =>  $self->lang(95,$to,$subject,$body)
					) if $sent == 1;
		}
		
		my $item = $self->parse_var($sent,'/email');
		$item->setAttribute('id',$newid > 0 ? $newid : $logmailid);
	}
	
	$self->parse('/logmail_send');
}

sub logemail_view {
	my ($self) = shift;	
	
	return unless $self->check_user();
	return $self->hard_error($self->lang('16','user_email_view')) if $self->perm('emails','view','deny') == 1;
	
	my $logmailid = $self->param('ID');
	$self->logmailid($logmailid);
	my $tzo = $self->{cooktzo} || $self->offset/3600;
	
	foreach  my $column ('byuser','user','from','to','subject','body','data','tempo','enviado') {
		if (m/^(from|to)$/) {
			my @emails = split ',', $self->logmail($column);
			$self->template($column, join ',', grep { $self->is_valid_email($_) } @emails);					
		} elsif (m/^(data)$/) {
			$self->template($column, $self->dateformat($self->logmail($column) + Controller::timeadd_offset($self->logmail('tempo'),$tzo) ));
		} elsif (m/^(tempo)$/) { #Set offset
			$self->template($column, Controller::timeadd_offset($self->logmail($column),$tzo));													
		} elsif (m/^(byuser)$/) {
			$self->template($column, $self->logmail($column));
		} else {
			$self->template($column, $self->logmail($column));
		}
	}
	$self->template('id',$logmailid);
	
	$self->parse('/logmail_view');
}

sub AUTOLOAD { #Holds all undef methods
	my $self = $_[0];
	my $type = ref($self) or die "$AUTOLOAD is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion
		
	if ($name =~ /_tree$/i) {
		my ($addon,$cat) = $name =~ /(.+?)_(.*)/;
		return $self->parse('/tree',$addon,$cat) if ($_[0]->check_user);		
	}

	$self->hard_error("$name not implemented at Interface Admin");
	return undef;#Simular erro
}

sub sendToSupport {
	my ($self) = shift;
	return unless $self->check_user();
	
	my $path = $self->setting('file_path').'/tmp';
	my $file_path = "$path/ctrl_".$self->param('file_hash');	
	
	my $sent = $self->email( To => 'suporte@is4web.com', From => $self->setting('adminemail'), Subject => 'Debug request for domain: '.$self->param('system'), Body => 'Please check the attach!', Attf => $file_path, File => $self->param('file_hash'));

	$self->parse_var($sent,'/email');	
	
	$self->parse('/sendToSupport');
}
1;
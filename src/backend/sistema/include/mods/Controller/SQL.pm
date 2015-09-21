#!/usr/bin/perl
#
# Controller - is4web.com.br
# 2007
package Controller::SQL;

require 5.008;
require Exporter;
use Controller::LOG;
use Cwd;
use lib getcwd;
use SQL::ParserController;

our @ISA = qw(Exporter);

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    	
	my $self = {
		'ERR' => undef,
		'_statement' => undef,
		'_binds' => undef,
	};
	
	bless($self, $class);
	
	return $self;
}

sub mysql_parse {
	my ($self) = shift;
   	my $sql = shift;
   		
	my $parser = SQL::ParserController->new('MySQL', {'PrintError' => 0, 'RaiseError' => 0});
	$parser->feature('valid_commands','CALL',0);
	$parser->parse($sql);
	
	return $parser->structure;
}

sub execute_sql {
	@_ = @_;
	my ($self,$statement,@var) = @_; 

	if ($Controller::SWITCH{skip_sql} == 1) {
		#warn 'sql skipped';
		return;
	}
	
	$self->{_statement} = $statement =~ m/^\d+$/ ? $self->{queries}{$statement} : $statement;
	@{ $self->{_binds} } = @var;	

	my $sth = $self->{dbh}->prepare($self->{_statement});
	if (@var) {
		@var = () if $var[0] == -1;
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

sub select_sql {
	@_ = @_;
 my ($self,$statement,@var) = @_;

	$self->{_statement} = $statement =~ m/^\d+$/ ? $self->{queries}{$statement} : $statement;
 	@{ $self->{_binds} } = @var;
 
 my $sth = $self->{dbh}->prepare($self->{_statement});
	if (@var) {
		$sth->execute(@var) || do {$self->set_error("Erro $DBI::err em execute_sql($DBI::errstr) ****$statement | ".join(",",@var)); return;};
	} else {
		do {$self->set_error("WHERE with no binds ***$statement"); return;} if $self->{_statement} =~ /WHERE/i && $self->{_statement} =~ /\?/g;
		$sth->execute() || do {$self->set_error("Erro $DBI::err em select_sql($DBI::errstr)"); return;};
	}
	push @{ $self->{_sths} }, $sth;
	return($sth);
}

sub last_select {
	return $_[0]->{_sths}[-1];
}

sub sql_parse {
	my ($self) = shift;
	$self->{_statement} = shift if exists $_[0];
	@{ $self->{_binds} } = @_ if exists $_[0];
	die $self->lang(3,'sql_parse') unless $self->{_type};
	
	$self->{_statement} =~ s/`//g if $self->{_type} =~ /^mysql$/i;
	
	my $i = -1;
	$self->{_statement} =~ s/([^'"]\s*)\?/(defined $self->{_binds}[++$i]) ? $1.&Controller::squote($self->{_binds}[$i]) : $1.'NULL'/sgeo;
	
	$self->{'sql'} = undef;
	$self->{'sql'} = $self->mysql_parse($self->{_statement}) if $self->{_type} =~ /^mysql$/i;

	#map Hash column and values
	if ($self->{'sql'}{'column_names'}[0]{value} eq '*') {
		$self->{'sql'}{'column_names'} = undef;
		foreach my $table (@{$self->{'sql'}{'table_names'}}) {
			push @{ $self->{'sql'}{'column_names'} }, map +{ value => $_, fullorg => $_, type => 'column' }, $self->columns(undef, undef, $table, '%');
		}
	}
	for (my $i = 0; my $column = uc $self->{'sql'}{'column_names'}[$i]{value}; $i++) {
		$self->{'sql'}{'set'}{$column} = $self->{'sql'}{'values'}[0][$i]{'fullorg'};
	}
	
	return $self->{'sql'}{'errstr'} ? 0 : 1;
}

sub parsedump {
	my ($self) = @_;
	
	use Data::Dumper;
	print $self->error ? $self->error : Dumper $self->{"sql"};	
	
	return $self->error ? 0 : 1;	
}

sub columns {
	my ($self,$catalog, $schema, $table, $column) = @_;
	
	my $fields = $self->{dbh}->column_info($catalog, $schema, lc $table, $column)->fetchall_hashref('COLUMN_NAME');
	
 	return map {uc $_} sort{$fields->{$a}{'ORDINAL_POSITION'} <=> $fields->{$b}{'ORDINAL_POSITION'} } keys %{ $fields };
}

sub _setqueries {
	my ($self) = shift;
	#TODO adicionar selects;
	my $SELECT_v3_services = qq|SELECT s.`id` AS `id`,s.`username` AS `username`,s.`dominio` AS `dominio`,pl.`tipo` AS `tipo`,pl.`plataforma` AS `plataforma`,pl.`servicos` AS `plano`,pl.`nome` AS `plano_nome`,s.`status` AS `status`,s.`inicio` AS `inicio`,s.`fim` AS `fim`,s.`vencimento` AS `vencimento`,s.`proximo` AS `proximo`,srv.`id` AS `servidor`,srv.`nome` AS `servidor_nome`,s.`dados` AS `dados`,s.`useracc` AS `useracc`,pg.`id` AS `pg`,pg.`nome` AS `pg_nome`,s.`envios` AS `envios`,s.`def` AS `def`,s.`action` AS `action`,s.`invoice` AS `invoice`,s.`pagos` AS `pagos`,s.`desconto` AS `desconto`,s.`lock` AS `lock`,s.`parcelas` AS `parcelas` 
FROM (
`servicos` AS s inner join `planos` AS pl ON s.`servicos` = pl.`servicos`
 INNER JOIN `pagamento` AS pg ON s.`pg` = pg.`id`
 LEFT JOIN `servidores` AS srv ON srv.`id` = s.`servidor`
)|; #FAKE VIEW
	
	%{ $self->{queries} } = (
		##############
		#   Core	 #
		##############		
		# Cron #
		1 => qq|DELETE FROM `cron` WHERE `id` = ? AND `tipo` = ?|,		
		2 => qq|INSERT INTO `cron` (`id`,`tipo`,`motivo`) VALUES (?,?,?)|,				
		3 => qq|UPDATE `cron` SET `motivo` = ? WHERE `id` = ? AND `tipo` = ?|,
		20 => qq|TRUNCATE `cron`|,		
		# Protecao do Cron #
		21 => qq|REPLACE INTO `cron_lock` (`id`,`data`,`hora`) VALUES (?,?,?)|,
		22 => qq|DELETE FROM `cron_lock` WHERE `id` = ?|,					
		# Servidores / Painel de Controle #
		41 => qq|DELETE `servidores`.*,`servidores_set`.* FROM `servidores` LEFT JOIN `servidores_set` ON `servidores`.`id`=`servidores_set`.`id` WHERE `servidores`.`id` = ?|,
		42 => qq|INSERT INTO `servidores` (`id`,`nome`,`host`,`ip`,`port`,`ssl`,`username`,`key`,`ns1`,`ns2`,`os`,`ativo`) VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?)|,		
		43 => qq|UPDATE `servidores` SET `nome` = ?, `host` = ?, `ip` = ?, `port` = ?, `ssl` = ?, `username` = ?, `ns1` = ?, `ns2` = ?, `os` = ?, `ativo` = ? WHERE `id` = ?|,
		44 => qq|UPDATE `servidores` SET `key` = ? WHERE `id` = ?|,
		45 => qq|SELECT `servidores`.*,`servidores_set`.`Rns1`,`servidores_set`.`Rns2`,`servidores_set`.`Hns1`,`servidores_set`.`Hns2`,`servidores_set`.`MultiWEB`,`servidores_set`.`MultiDNS`,`servidores_set`.`MultiMAIL`,`servidores_set`.`MultiFTP`,`servidores_set`.`MultiSTATS`,`servidores_set`.`MultiDB` FROM `servidores` LEFT JOIN `servidores_set` ON `servidores`.`id`=`servidores_set`.`id` WHERE `servidores`.`id` IN (?)|,
		46 => qq|SELECT `servidores`.*,`servidores_set`.`Rns1`,`servidores_set`.`Rns2`,`servidores_set`.`Hns1`,`servidores_set`.`Hns2`,`servidores_set`.`MultiWEB`,`servidores_set`.`MultiDNS`,`servidores_set`.`MultiMAIL`,`servidores_set`.`MultiFTP`,`servidores_set`.`MultiSTATS`,`servidores_set`.`MultiDB` FROM `servidores` LEFT JOIN `servidores_set` ON `servidores`.`id`=`servidores_set`.`id` WHERE (`servidores`.`os` LIKE ? OR `servidores`.`os` = "-") AND `servidores`.`ativo` = 1 ORDER BY `servidores`.`nome`|,
		47 => qq|SELECT * FROM `servidores` WHERE `os` LIKE ? OR `id` = 1|,
		48 => qq|SELECT * FROM `servidores` WHERE `id` = 1 OR (`id` LIKE CONCAT('%',?,'%') OR `nome` LIKE CONCAT('%',?,'%') OR `host` LIKE CONCAT('%',?,'%') OR `ip` LIKE CONCAT('%',?,'%') OR `port` LIKE CONCAT('%',?,'%') OR `ssl` LIKE CONCAT('%',?,'%') OR `username` LIKE CONCAT('%',?,'%') OR `ns1` LIKE CONCAT('%',?,'%') OR `ns2` LIKE CONCAT('%',?,'%') OR `os` LIKE CONCAT('%',?,'%') OR `ativo` LIKE CONCAT('%',?,'%'))|,
		49 => qq|INSERT INTO `servidores_set` (`id`, `Rns1`, `Rns2`, `Hns1`, `Hns2`, `MultiWEB`, `MultiDNS`, `MultiMAIL`, `MultiFTP`, `MultiSTATS`, `MultiDB`) VALUES (?,?,?,?,?,?,?,?,?,?,?)
				 ON DUPLICATE KEY UPDATE `Rns1`= IF(VALUES(Rns1) IS NULL,Rns1,VALUES(Rns1)),`Rns2`= IF(VALUES(Rns2) IS NULL,Rns2,VALUES(Rns2)),`Hns1`= IF(VALUES(Hns1) IS NULL,Hns1,VALUES(Hns1)),`Hns2`= IF(VALUES(Hns2) IS NULL,Hns2,VALUES(Hns2)),`MultiWEB`= IF(VALUES(MultiWEB) IS NULL,MultiWEB,VALUES(MultiWEB)),`MultiMAIL`= IF(VALUES(MultiMAIL) IS NULL,MultiMAIL,VALUES(MultiMAIL)),`MultiFTP`= IF(VALUES(MultiFTP) IS NULL,MultiFTP,VALUES(MultiFTP)),`MultiSTATS`= IF(VALUES(MultiSTATS) IS NULL,MultiSTATS,VALUES(MultiSTATS)), `MultiDB`= IF(VALUES(MultiDB) IS NULL,MultiDB,VALUES(MultiDB));|,
		51 => qq|SELECT * FROM `servidores` WHERE (`?` LIKE CONCAT('%',?,'%')) AND `os` LIKE ?|,
		 
		# Registros Gerais #
		61 => qq|DELETE FROM `events` WHERE `id` = ?|,		
		62 => qq|INSERT INTO `events` (`id`,`message`) VALUES (NULL,?)|,
		63 => qq|UPDATE `events` SET `message` = ?  WHERE `id` = ?|,
		64 => qq|INSERT INTO `actionlog` (`id`,`agent`,`action`,`refer`) VALUES (NULL,?,?,?)|,
		65 => qq|DELETE FROM `activitylog` WHERE `cid` = ?|,		
		80 => qq|INSERT INTO `activitylog` (`id`,`cid`,`date`,`user`,`action`) VALUES (NULL,?,?,?,?)|,				
		# Configuracoes #
		81 => qq|UPDATE `settings` SET `value` = ? WHERE `setting` = ?|,
		# Respostas Prontas #
		101 => qq|DELETE FROM `preans` WHERE `id` = ?|,
		102 => qq|DELETE FROM `preans` WHERE `author` = ?|,				
		103 => qq|INSERT INTO `preans` (`id`,`author`,`subject`,`text`,`date`) VALUES (NULL,?,?,?,?)|,		
		120 => qq|UPDATE `preans` SET `subject` = ?, `text` = ? WHERE `id` = ?|,
		# Servidores POP 3 #		
		121 => qq|DELETE FROM `popservers` WHERE `id` = ?|,
		122 => qq|SELECT * FROM `popservers`|,		
		140 => qq|INSERT INTO `popservers` (`id`,`pop_host`,`pop_user`,`pop_password`,`pop_port`) VALUES (NULL,?,?,?,?)|,	
		# Emails bloqueados para leitura #
		141 => qq|REPLACE INTO `blocked_email` (`address`,`type`,`count`) VALUES (?,?,?)|,
		142 => qq|DELETE FROM `blocked_email` WHERE `address` = ? LIMIT 1|,
		160 => qq|INSERT INTO `blocked_email` (`address`,`type`,`count`) VALUES (NULL,?,?,?)|,	
		# Logs #
		161 => qq|DELETE FROM `log_mail` WHERE `user` = ?|,	
		162 => qq|SELECT `id`, `byuser`, `user`, `from`, `to`, `subject`, `data`, `tempo`, `enviado` FROM `log_mail` WHERE `user` = ? AND (`id` LIKE CONCAT('%',?,'%') OR `byuser` LIKE CONCAT('%',?,'%') OR `user` LIKE CONCAT('%',?,'%') OR `from` LIKE CONCAT('%',?,'%') OR `to` LIKE CONCAT('%',?,'%') OR `subject` LIKE CONCAT('%',?,'%') OR `body` LIKE CONCAT('%',?,'%') OR `tempo` LIKE CONCAT('%',?,'%') OR `enviado` LIKE CONCAT('%',?,'%') OR `data` LIKE CONCAT('%',?,'%'))|, # `user` LIKE ? AND causou uma demora excessiva na query 			
		163 => qq|SELECT `id`, `byuser`, `user`, `from`, `to`, `subject`, `data`, `tempo`, `enviado` FROM `log_mail`|,
		164 => qq|SELECT * FROM `log_mail` WHERE `id` = ?|,
		165 => qq|DELETE FROM `log_mail` WHERE `id` = ?|,
		166 => qq|SELECT `id`, `byuser`, `user`, `from`, `to`, `subject`, `data`, `tempo`, `enviado` FROM `log_mail` WHERE (`?` LIKE CONCAT('%',?,'%')) AND `user` LIKE ?|,	
		167 => qq|SELECT `id`, `byuser`, `user`, `from`, `to`, `subject`, `data`, `tempo`, `enviado` FROM `log_mail` WHERE `user` LIKE ?|,
		##############
		# Interface	 #
		##############	
		# Logados #
		181 => qq|DELETE FROM `online` WHERE `username` = ? AND `agent` = ?|,		
		182 => qq|DELETE FROM `online` WHERE `del` = 1|,
		184 => qq|UPDATE `online` SET `del` = 1|,
		185 => qq|INSERT INTO `online` SELECT ?,?,?,? FROM DUAL WHERE NOT EXISTS (SELECT * FROM `online` WHERE `username` = ? AND `agent` = ? )|,
		186 => qq|SELECT count(*) as total FROM `online` WHERE NOT `username` > 0 AND NOT (`username` = ? AND `agent` = ?)|,
		200 => qq|UPDATE `online` SET `del` = 0 WHERE `username` = ? AND `agent` = ?|,
		# Manual #
		201 => qq|DELETE FROM `documentacao` WHERE `id` = ?|,
		202 => qq|DELETE FROM `documentacao` WHERE `id` = ? AND `sid` = ?|,		
		203 => qq|INSERT INTO `documentacao` (`id`,`sid`,`nome`,`value`) VALUES (?,?,?,?)|,
		204 => qq|INSERT INTO `documentacao` (`id`,`sid`,`nome`,`value`) VALUES (?,?,?,NULL)|,
		220 => qq|UPDATE `documentacao` SET `nome` = ?, `value` = ?  WHERE `id` = ? AND `sid` = ?|,		
		# Anuncios #
		221 => qq|DELETE FROM `announce` WHERE id = ?|,
		240 => qq|INSERT INTO `announce` (`id`,`author`,`subject`,`message`,`staff`,`users`,`time`) VALUES (NULL,?,?,?,?,?,?)|,		
		##############
		# Helpdesk	 #
		##############
		# Registros #
		241 => qq|DELETE FROM `stafflogin` WHERE `username` = ?|,
		242 => qq|INSERT INTO `stafflogin` (`username`,`date`) VALUES (?,?)|,
		243 => qq|UPDATE `stafflogin` SET `date` = ? WHERE `username` = ?|,
		244 => qq|INSERT INTO `staffread` (`username`,`date`) VALUES (?,?)|,		
		245 => qq|DELETE FROM `staffread` WHERE `username` = ?|,
		246 => qq|UPDATE `staffread` SET `date` = ? WHERE `username` = ?|,		
		247 => qq|DELETE FROM `staffactive` WHERE `username` = ?|,
		248 => qq|INSERT INTO `staffactive` (`username`,`date`) VALUES (?,?)|,
		260 => qq|UPDATE `staffactive` SET `date` = ? WHERE `username` = ?|,
		# Departamentos #
		261 => qq|DELETE FROM `departments` WHERE `level` = ?|,
		262 => qq|DELETE FROM `departments` WHERE `id` = ?|,		
		263 => qq|INSERT INTO `departments` (`id`,`nome`,`sender`,`signature`,`level`) VALUES (NULL,?,?,NULL,?)|,
		264 => qq|UPDATE `departments` SET `nome` = ?, `sender` = ?, `signature` = ?, `level` = ? WHERE `id` = ?|,
		265 => qq|SELECT `id`, `level` FROM `departments`  WHERE `nome` = ?|,
		266 => qq|SELECT * FROM `departments` ORDER BY `level`,`nome`|,
		267 => qq|SELECT * FROM `departments` WHERE `id` LIKE ?|,
		# Encaminhamentos para departamentos #
		281 => qq|DELETE FROM `em_forwarders` WHERE `address` = ?|,
		300 => qq|INSERT INTO `em_forwarders` (`address`,`category`) VALUES (?,?)|,
		# Empresas #
		301 => qq|DELETE FROM `level` WHERE `id` = ?|,
		302 => qq|INSERT INTO `level` (`id`,`nome`,`sender`) VALUES (NULL,?,?)|,
		303 => qq|SELECT * FROM `level` ORDER BY `nome`|,
		304 => qq|SELECT * FROM `level` WHERE `id` LIKE ?|,
		320 => qq|UPDATE `level` SET `nome` = ? WHERE `id` = ?|,								
		# Operadores #	
		321 => qq|DELETE FROM `staff` WHERE `username` = ?|,
		322 => qq|INSERT INTO `staff` (`id`,`username`,`password`,`name`,`email`,`access`,`notify`,`responsetime`,`callsclosed`,`signature`,`rkey`,`lpage`,`play_sound`,`llogin`,`admin`,`notes`) VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,			
		323 => qq|UPDATE `staff` SET `password` = ?, rkey = ? WHERE username = ?|,
		324 => qq|UPDATE `staff` SET `name` = ?, `email` = ?, `notify` = ?, `play_sound` = ?, `access` = ? WHERE `username` = ?|,		
		325 => qq|UPDATE `staff` SET `name` = ?, `email` = ?, `notify` = ?, `signature` = ? WHERE `username` = ?|,		
		326 => qq|UPDATE `staff` SET `password` = ?, `rkey` = ? WHERE `username` = ?|,
		327 => qq|UPDATE `staff` SET `play_sound` = ?, `name` = ?, `email` = ?, `notify` = ?, `signature` = ? WHERE `username` = ?|,		
		328 => qq|UPDATE `staff` SET `lpage` = ? WHERE `username` = ?|,
		329 => qq|UPDATE `staff` SET `responsetime` = ? WHERE `username` = ?|,
		330 => qq|UPDATE `staff` SET `callsclosed` = ? WHERE `username` = ?|,
		331 => qq|SELECT * FROM `staff` WHERE `username` = ?|,
		332 => qq|SELECT * FROM `staff` WHERE `username` != 'suporte' AND IF((SELECT count(*) FROM `online` WHERE `username` = staff.username) > 0,1,0) LIKE ?|,
		333 => qq|SELECT * FROM  `staff` WHERE `username` != 'suporte' AND (`id` LIKE CONCAT('%',?,'%') OR `username` LIKE CONCAT('%',?,'%') OR `name` LIKE CONCAT('%',?,'%') OR `email` LIKE CONCAT('%',?,'%') OR `signature` LIKE CONCAT('%',?,'%') )|, # OR `play_sound` LIKE CONCAT('%',?,'%') OR `notify` LIKE CONCAT('%',?,'%') )
		334 => qq|SELECT * FROM `staff` WHERE `username` != 'suporte' AND (`?` LIKE CONCAT('%',?,'%'))|,
		335 => qq|REPLACE INTO `staffgroups` (`username`,`group`) VALUES (?,?)|,
		336 => qq|DELETE FROM `staffgroups` WHERE `username` = ?|,
		# Tickets	 #
		341 => qq|DELETE FROM `calls` WHERE `service` = ?|,
		342 => qq|DELETE FROM `calls` WHERE `id` = ?|,
		343 => qq|DELETE FROM `calls` WHERE `username` = ?|,
		344 => qq|INSERT INTO `calls` (`id`,`status`,`username`,`email`,`priority`,`service`,`category`,`subject`,`description`, `time`,`ownership`,`closedby`,`method`,`track`,`active`,`aw`,`an`,`time_spent`,`is_locked`) VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,
		345 => qq|UPDATE `calls` SET `nome` = ? WHERE `category` = ?|,
		347 => qq|UPDATE `calls` SET `status` = ?, `aw` = ? WHERE `id` = ?|,
		348 => qq|UPDATE `calls` SET `ownership` = ? WHERE `id` = ?|,
		349 => qq|UPDATE `calls` SET `username` = ? WHERE (`username` = ? OR `username` IS NULL) and `id` = ?|,
		350 => qq|UPDATE `calls` SET `service` = ? WHERE (`service` = ? OR `service` IS NULL) and `id` = ?|,
		351 => qq|UPDATE `calls` SET priority = ?, `ownership` = NULL, `aw` = ? WHERE `id` = ?|,
		352 => qq|UPDATE `calls` SET `aw` = ? WHERE `id` = ?|,
		353 => qq|UPDATE `calls` SET `status` = ? WHERE `id` = ?|,
		354 => qq|UPDATE `calls` SET `closedby` = ? WHERE `id` = ?|,
		355 => qq|UPDATE `calls` SET `category` = ?, `ownership` = ?, `priority` = ?, `aw` = ? WHERE `id` = ?|,
		356 => qq|UPDATE `calls` SET `is_locked` = ? WHERE `id` = ?|,
		357 => qq|UPDATE `calls` SET `description` = ? WHERE `id` = ?|,
		358 => qq|UPDATE `calls` SET $set WHERE `id` = ?|,
		359 => qq|UPDATE `calls` SET `an` = ? WHERE `id` = ?|,
		360 => qq|UPDATE `calls` SET `time_spent` = ? WHERE `id` = ?|,
		361 => qq|UPDATE `calls` SET `status` = ?, `closedby` = ? WHERE `id` = ?|,
		362 => qq|UPDATE `calls` SET `priority` = ? WHERE `id` = ?|,
		363 => qq|UPDATE `calls` SET `active` = ? WHERE `id` = ?|,
		364 => qq|UPDATE `calls` SET `active` = ?, `aw` = ? WHERE `id` = ?|,
		365 => qq|SELECT * FROM `|.$self->TABLE_CALLS.qq|` WHERE `id` = ?|,
		366 => qq|SELECT * FROM `|.$self->TABLE_CALLS.qq|` WHERE `username` = ?|,
		367 => qq|SELECT * FROM `|.$self->TABLE_CALLS.qq|` WHERE `service` = ?|,
		# Follows #
		379 => qq|SELECT DISTINCT `call` FROM `follows` WHERE `staff` = ?|,
		380 => qq|SELECT DISTINCT `staff` FROM `follows` WHERE `call` = ?|,		
		# Respostas #
		381 => qq|DELETE FROM `notes` WHERE `call` = ?|,		
		382 => qq|INSERT INTO `notes` (`owner`,`visible`,`action`, `call`,`author`, `time`,`ikey`,`comment`,`poster_ip`) VALUES (?,?,?,?,?,?,?,?,?)|,
		400 => qq|UPDATE `notes` SET `comment` = ? WHERE `id` = ?|,
		# Anexos #
		401 => qq|DELETE FROM `files` WHERE `nid` = ?|,
		402 => qq|DELETE FROM `files` WHERE `cid` = ?|,
		403 => qq|INSERT INTO `files` (`id`,`cid`,`nid`,`filename`,`file`) VALUES (NULL,?,?,?,?)|,		
		404 => qq|INSERT INTO `files` (`id`,`cid`,`nid`,`filename`,`file`) VALUES (NULL,NULL,?,?,?)|,
		405 => qq|INSERT INTO `files` (`id`,`cid`,`nid`,`filename`,`file`) VALUES (NULL,?,NULL,?,?)|,
		420 => qq|UPDATE `files` SET `cid` = ?, `nid` = ? WHERE `id` = ?|,
		##############
		# Financeiro #
		##############
		# Contas Correntes #
		421 => qq|DELETE FROM `cc` WHERE `id` = ?|,
		422 => qq|INSERT INTO `cc` (`id`,`nome`,`banco`,`dvbanco`,`agencia`,`conta`,`carteira`,`convenio`,`cedente`,`instrucoes`) VALUES (NULL,?,?,?,?,?,?,?,?,?)|,
		423 => qq|SELECT * FROM `|.$self->TABLE_ACCOUNTS.qq|` WHERE `id` LIKE ?|,		
		424 => qq|SELECT * FROM `|.$self->TABLE_ACCOUNTS.qq|` WHERE 1=1|,
		425 => qq|SELECT * FROM `|.$self->TABLE_ACCOUNTS.qq|` WHERE (`id` LIKE CONCAT('%',?,'%') OR `nome` LIKE CONCAT('%',?,'%') OR `banco` LIKE CONCAT('%',?,'%') OR `dvbanco` LIKE CONCAT('%',?,'%') OR `agencia` LIKE CONCAT('%',?,'%') OR `conta` LIKE CONCAT('%',?,'%') OR `carteira` LIKE CONCAT('%',?,'%') OR `convenio` LIKE CONCAT('%',?,'%') OR `cedente` LIKE CONCAT('%',?,'%') OR `instrucoes` LIKE CONCAT('%',?,'%'))|,
		426 => qq|SELECT * FROM `bancos` WHERE `codigo` = ?|,		
		427 => qq|SELECT * FROM `bancos`|,
		428 => qq|SELECT DISTINCT `conta` AS id FROM `invoices` WHERE conta|,
		429 => qq|SELECT * FROM `|.$self->TABLE_ACCOUNTS.qq|` WHERE (`?` LIKE CONCAT('%',?,'%'))|,
				
		#  Faturas 	 #
		431 => qq|DELETE FROM `|.$self->TABLE_INVOICES.qq|` WHERE `username` = ?|,		
		432 => qq|INSERT INTO `|.$self->TABLE_INVOICES.qq|` (`id`,`username`,`status`,`nome`,`data_envio`,`data_vencido`,`data_vencimento`,`data_quitado`,`envios`,`referencia`,`services`,`valor`,`valor_pago`,`imp`,`conta`,`nossonumero`,`tarifa`,`parcelas`,`parcelado`) VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,
		434 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `imp` = ?, `valor` = ?, `referencia` = ?, `data_vencimento` = ? WHERE `id` = ?|,
		435 => qq|SELECT * FROM `v1_invoices` WHERE `status` LIKE ?|,
		436 => qq|SELECT * FROM `v1_invoices` WHERE (`id` LIKE CONCAT('%',?,'%') OR `username` LIKE CONCAT('%',?,'%') OR `nome` LIKE CONCAT('%',?,'%') OR `envios` LIKE CONCAT('%',?,'%') OR `referencia` LIKE CONCAT('%',?,'%') OR `conta` LIKE CONCAT('%',?,'%') OR `tarifa` LIKE CONCAT('%',?,'%') OR `nossonumero` LIKE CONCAT('%',?,'%') OR `parcelado` LIKE CONCAT('%',?,'%') OR `data_envio` LIKE CONCAT('%',?,'%') OR `data_vencido` LIKE CONCAT('%',?,'%') OR `data_vencimento` LIKE CONCAT('%',?,'%') OR `data_quitado` LIKE CONCAT('%',?,'%') OR `valor` LIKE CONCAT('%',?,'%') OR `valor_pago` LIKE CONCAT('%',?,'%'))|,
		437 => qq|SELECT `invoices`.*, `cron`.`motivo` AS confirmado FROM `|.$self->TABLE_INVOICES.qq|` LEFT JOIN `cron` ON `invoices`.`id` = `cron`.`id` AND `cron`.`tipo` = 5 WHERE `invoices`.`id` = ?|,
		438 => qq|SELECT * FROM `v1_invoices` WHERE `username` = ? AND `status` LIKE ?|,
		439 => qq|SELECT * FROM `v1_invoices` WHERE `status` LIKE ? AND `username` = ?|,
		
		433 => qq|SELECT `invoices`.*, `cron`.`motivo` AS confirmado FROM `|.$self->TABLE_INVOICES.qq|` LEFT JOIN `cron` ON `invoices`.`id` = `cron`.`id` AND `cron`.`tipo` = 5 WHERE `invoices`.`status` != ? AND `invoices`.`id` = ?|,
		
		455 => qq|SELECT * FROM `v1_invoices` WHERE (`?` LIKE CONCAT('%',?,'%'))|,
		
		453 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `imp` = ? WHERE `id` = ?|,
		456 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `envios` = ? WHERE `id` = ?|,
		473 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `valor` = ? , `data_vencimento` = ?, `referencia` = ? WHERE `id` = ?|,		
		475 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `status` = ?, `valor_pago` = ?, `data_quitado` = ? WHERE `id` = ?|,
		478 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `status` = ? WHERE `id` = ?|,
		479 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `nossonumero` = ? WHERE `id` = ?|,
		487 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `services` = ? WHERE `id` = ? AND `status` != 'D' AND `status` != 'Q'|,
		488 => qq|UPDATE `|.$self->TABLE_INVOICES.qq|` SET `username` = ? WHERE `id` = ?|,
		#  Saldos 	 #
		440 => qq|DELETE `|.$self->TABLE_BALANCES.qq|`.* FROM `|.$self->TABLE_BALANCES.qq|` LEFT JOIN `invoices` ON `invoices`.`id` = `saldos`.`invoice` WHERE IFNULL(`invoices`.`status`,'O') = ?|,
		441 => qq|DELETE FROM `|.$self->TABLE_BALANCES.qq|` WHERE `id` = ?|,		
		442 => qq|DELETE FROM `|.$self->TABLE_BALANCES.qq|` WHERE `username` = ?|,
		443 => qq|DELETE FROM `|.$self->TABLE_BALANCES.qq|` WHERE `servicos` = ?|,		
		445 => qq|INSERT INTO `|.$self->TABLE_BALANCES.qq|` (`id`,`username`,`valor`,`descricao`,`servicos`,`invoice`) VALUES (NULL,?,?,?,?,?)|,		
		446 => qq|UPDATE `|.$self->TABLE_BALANCES.qq|` SET `invoice` = ? WHERE `id` = ?|,
		447 => qq|UPDATE `|.$self->TABLE_BALANCES.qq|` SET `invoice` = NULL WHERE `invoice` = ?|,
		448 => qq|UPDATE `|.$self->TABLE_BALANCES.qq|` SET `username` = ?, `valor` = ?, `descricao` = ? WHERE `id` = ?|,
		449 => qq|SELECT * FROM `|.$self->TABLE_BALANCES.qq|` WHERE `id` = ?|,
		450 => qq|SELECT `b`.*, IFNULL(`i`.`status`,'O') AS `bstatus` FROM `|.$self->TABLE_BALANCES.qq|` AS b LEFT JOIN `|.$self->TABLE_INVOICES.qq|` AS i ON `i`.`id` = `b`.`invoice` WHERE IFNULL(`i`.`status`,'O') LIKE ? AND `b`.`username` = ?|, #IF(`i`.`status` = 'D','O',IFNULL(`i`.`status`,'O'))
		451 => qq|SELECT `b`.*, IFNULL(`i`.`status`,'O') AS `bstatus` FROM `|.$self->TABLE_BALANCES.qq|` AS b LEFT JOIN `|.$self->TABLE_INVOICES.qq|` AS i ON `i`.`id` = `b`.`invoice` WHERE IFNULL(`i`.`status`,'O') LIKE ?|, #O Open #status D nao deve ocorrer
		452 => qq|SELECT `b`.*, IFNULL(`i`.`status`,'O') AS `bstatus` FROM `|.$self->TABLE_BALANCES.qq|` AS b LEFT JOIN `|.$self->TABLE_INVOICES.qq|` AS i ON `i`.`id` = `b`.`invoice` WHERE (`b`.`id` LIKE CONCAT('%',?,'%') OR `b`.`username` LIKE CONCAT('%',?,'%') OR `b`.`descricao` LIKE CONCAT('%',?,'%') OR `b`.`servicos` LIKE CONCAT('%',?,'%') OR `b`.`invoice` LIKE CONCAT('%',?,'%') OR `b`.`valor` LIKE CONCAT('%',?,'%'))|,
		454 => qq|SELECT `b`.*, IFNULL(`i`.`status`,'O') AS `bstatus` FROM `|.$self->TABLE_BALANCES.qq|` AS b LEFT JOIN `|.$self->TABLE_INVOICES.qq|` AS i ON `i`.`id` = `b`.`invoice` WHERE IFNULL(`i`.`status`,'O') LIKE ? AND `b`.`servicos` = ?|,
		457 => qq|SELECT `b`.*, IFNULL(`i`.`status`,'O') AS `bstatus` FROM `|.$self->TABLE_BALANCES.qq|` AS b LEFT JOIN `|.$self->TABLE_INVOICES.qq|` AS i ON `i`.`id` = `b`.`invoice` WHERE (`?` LIKE CONCAT('%',?,'%'))|,
		
		#  Creditos  #
		460 => qq|DELETE FROM `creditos` WHERE `id` = ?|,		
		461 => qq|INSERT INTO `creditos` (`id`,`username`,`valor`,`descricao`,`balance`) VALUES (NULL,?,?,?,?)|,
		462 => qq|DELETE `|.$self->TABLE_CREDITS.qq|`.*,`|.$self->TABLE_BALANCES.qq|`.* FROM `|.$self->TABLE_CREDITS.qq|` LEFT JOIN `|.$self->TABLE_BALANCES.qq|` ON `|.$self->TABLE_BALANCES.qq|`.`id` = `|.$self->TABLE_CREDITS.qq|`.`balance` LEFT JOIN `invoices` ON `invoices`.`id` = `saldos`.`invoice` WHERE IFNULL(`invoices`.`status`,'O') = ?|,
		480 => qq|UPDATE `creditos` SET `username` = ?, `valor` = ?, `descricao` = ? WHERE `id` = ?|,
		481 => qq|SELECT * FROM `|.$self->TABLE_CREDITS.qq|` WHERE `id` = ?|,
		482 => qq|SELECT * FROM `|.$self->TABLE_CREDITS.qq|` WHERE `username` LIKE ?|,
		483 => qq|SELECT *, IF(`valor` > 0,'P','U') AS `cstatus` FROM `|.$self->TABLE_CREDITS.qq|` WHERE IF(`valor` > 0,'P','U') LIKE CONCAT('%',?,'%')|,		
		484 => qq|SELECT *, IF(`valor` > 0,'P','U') AS `cstatus` FROM `|.$self->TABLE_CREDITS.qq|` WHERE (`id` LIKE CONCAT('%',?,'%') OR `username` LIKE CONCAT('%',?,'%') OR `descricao` LIKE CONCAT('%',?,'%') OR `valor` LIKE CONCAT('%',?,'%'))|,		
		485 => qq|SELECT `username`, sum(`valor`) `total` FROM `|.$self->TABLE_CREDITS.qq|` GROUP BY `username`|,
		486 => qq|SELECT *, IF(`valor` > 0,'P','U') AS `cstatus` FROM `|.$self->TABLE_CREDITS.qq|` WHERE IF(`valor` > 0,'P','U') LIKE CONCAT('%',?,'%') AND `username` = ?|,	
		489 => qq|SELECT *, IF(`valor` > 0,'P','U') AS `cstatus` FROM `|.$self->TABLE_CREDITS.qq|` WHERE (`?` LIKE CONCAT('%',?,'%'))|,
		#############
		# Cadastros #
		#############
		# Planos #
		601 => qq|DELETE FROM `planos` WHERE `servicos` = ?|,
		602 => qq|INSERT INTO `planos` (`servicos`,`level`,`plataforma`,`nome`,`tipo`,`descricao`,`campos`,`setup`,`valor`,`valor_tipo`,`auto`,`pagamentos`,`alert`,`pservidor`,`notes`) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,
		603 => qq|UPDATE `planos` SET `$colum` = ? WHERE `servicos` = ?|,
		604 => qq|SELECT `planos`.*, `planos_modules`.`modulo` FROM `planos` LEFT JOIN `planos_modules` ON `planos`.`servicos`=`planos_modules`.`plano` WHERE `servicos` = ?|,
		605 => qq|SELECT * FROM `v1_planos` WHERE `plataforma` LIKE ? AND `tipo` LIKE ?|,
		606 => qq|SELECT * FROM `v1_planos` WHERE (`servicos` LIKE CONCAT('%',?,'%') OR `nome` LIKE CONCAT('%',?,'%') OR `plataforma` LIKE CONCAT('%',?,'%') OR `tipo` LIKE CONCAT('%',?,'%') OR `descricao` LIKE CONCAT('%',?,'%') OR `auto` LIKE CONCAT('%',?,'%') OR `pservidor` LIKE CONCAT('%',?,'%') OR `setup` LIKE CONCAT('%',?,'%') OR `valor` LIKE CONCAT('%',?,'%') OR `valor_tipo` LIKE CONCAT('%',?,'%'))|,
		607 => qq|(SELECT IF(`servicos` >= 1000, `servicos`+1, 1000) AS plano FROM `planos` ORDER BY `servicos` DESC LIMIT 1) UNION (SELECT '1000' FROM DUAL) LIMIT 1|,
		608 => qq|SELECT * FROM `v1_planos` WHERE `level` LIKE ? AND `servicos` IN (SELECT `servicos` FROM `servicos` WHERE `username` = ?)|,			
		609 => qq|SELECT * FROM `v1_planos` WHERE (`?` LIKE CONCAT('%',?,'%'))|,
		# Módulos dos Planos #
		621 => qq|REPLACE INTO `planos_modules` (`plano`,`modulo`) VALUES (?,?)|,
		# Descontos de Plano #
		641 => qq|REPLACE INTO `descontos` (`id`,`plano`,`pg`,`valor`) VALUES (NULL,?,?,?)|,
		642 => qq|DELETE FROM `descontos` WHERE `id` = ?|,			
		660 => qq|DELETE FROM `descontos` WHERE `plano` = ? AND `pg` = ?|,				
		# Usuários #
		661 => qq|DELETE FROM `users` WHERE `username` = ?|,
		662 => qq|INSERT INTO `users` (`username`,`password`,`vencimento`,`status`,`name`,`email`,`empresa`,`cpf`,`cnpj`,`telefone`,`endereco`,`numero`,`cidade`,`estado`,`cc`,`cep`,`level`,`inscricao`,`rkey`,`pending`,`active`,`acode`,`lcall`,`conta`,`forma`,`alert`,`news`,`language`,`notes`) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,
		663 => qq|INSERT INTO `users` (`username`,`password`,`vencimento`,`status`,`name`,`email`,`empresa`,`cpf`,`cnpj`,`telefone`,`endereco`,`numero`,`cidade`,`estado`,`cc`,`cep`,`level`,`inscricao`,`rkey`,`pending`,`active`,`acode`,`lcall`,`conta`,`forma`,`alert`,`alertinv`,`news`,`language`,`notes`) values (?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?)|,		
		664 => qq|UPDATE `users` SET `pending` = ? WHERE `username` = ?|,
		665 => qq|UPDATE `users` SET `$colum` = ? WHERE `username` = ?|,
		666 => qq|UPDATE `users` SET `password` = ? , `rkey` = ? WHERE `username` = ?|,
		667 => qq|UPDATE `users` SET `status` = ? WHERE `username` = ?|,
		668 => qq|UPDATE `users` SET `news` = ? WHERE `email` LIKE CONCAT('%',?,'%')|,
		669 => qq|UPDATE `users` SET `active` = ? WHERE `username` = ?|,
		671 => qq|UPDATE `users` SET `forma` = ? WHERE `username` = ? |,
		672 => qq|UPDATE `users` SET `email` = ?, `telefone` = ?, `endereco` = ?, `numero` = ?, `cidade` = ?, `estado` = ?, `cep` = ?, `cc` = ? WHERE `username` = ?|,
		673 => qq|UPDATE `users` SET `password` = ?, `rkey` = ? WHERE `username` = ?|,
		674 => qq|UPDATE `users` SET `lcall` = ? WHERE `username` = ?|,
		675 => qq|UPDATE `users` SET `vencimento` = ? WHERE `username` = ?|,
		678 => qq|SELECT * FROM `users` WHERE `pending` LIKE ?|,
		679 => qq|SELECT * FROM `users` WHERE (`username` LIKE CONCAT('%',?,'%') OR `name` LIKE CONCAT('%',?,'%') OR `email` LIKE CONCAT('%',?,'%') OR `empresa` LIKE CONCAT('%',?,'%') OR `cidade` LIKE CONCAT('%',?,'%') OR `estado` LIKE CONCAT('%',?,'%') OR `cpf` LIKE CONCAT('%',?,'%') OR `cnpj` LIKE CONCAT('%',?,'%') OR `telefone` LIKE CONCAT('%',?,'%') OR `cep` LIKE CONCAT('%',?,'%') OR `status` = ?)|,
		680 => qq|SELECT * FROM `users` WHERE `username` = ?|,
		681 => qq|SELECT * FROM `users_config` WHERE `username` = ?|,
		682 => qq|INSERT INTO `users_config` (`setting`, `value`,`username`) VALUES (?,?,?)
				 ON DUPLICATE KEY UPDATE `value` = VALUES(`value`)|, 
		683 => qq|SELECT * FROM `users` WHERE (`?` LIKE CONCAT('%',?,'%'))|,
		
		# Usuarios excluidos #
		701 => qq|DELETE FROM `users_del` WHERE `username` = ?|,
		702 => qq|SELECT IF(`username` > 1000, `username`, (SELECT `username` FROM `users` ORDER BY `username` DESC LIMIT 1) + 1) AS username FROM `users_del` LEFT JOIN `users` AS t1 USING(`username`) WHERE t1.`username` IS NULL UNION (SELECT `username`+1 FROM `users` ORDER BY `username` DESC LIMIT 1) UNION (SELECT '1000' FROM DUAL) LIMIT 1|,
		# Usuarios Aprovados #
		721 => qq|INSERT INTO `users_validate` SELECT * FROM `users` WHERE `username` = ?|,		
		740 => qq|UPDATE `users_validate` SET `lcall` = ? WHERE `username` = ?|,			
		# Serviços #
		741 => qq|DELETE FROM `servicos` WHERE `id` = ?|,
		742 => qq|DELETE FROM `servicos` WHERE `username` = ?|,
		743 => qq|INSERT INTO `servicos` (`id`,`username`,`dominio`,`servicos`,`status`,`inicio`,`fim`,`vencimento`,`proximo`,`servidor`,`dados`,`useracc`,`pg`,`envios`,`def`,`action`,`invoice`,`pagos`,`desconto`,`lock`,`parcelas`,`notes`) VALUES (NULL,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,NULL,?,?,?,?,?)|,
		744 => qq|UPDATE `servicos` SET `def` = ? WHERE `id` = ?|,
		745 => qq|UPDATE `servicos` SET `action` = ? WHERE `id` = ?|,
		746 => qq|UPDATE `servicos` SET `$colum` = ? WHERE `id` = ?|,
		747 => qq|UPDATE `servicos` SET `pg` = ? WHERE `id` = ?|,
		748 => qq|UPDATE `servicos` SET `pg` = ?, `envios` = 0, `invoice` = 0 WHERE `id` = ?|,
		749 => qq|UPDATE `servicos` SET `def` = ?, `vencimento` = ? WHERE `id` = ?|,
		750 => qq|UPDATE `servicos` SET `servicos` = ? WHERE `id` = ?|,
		751 => qq|UPDATE `servicos` SET `vencimento` = ? WHERE `id` = ?|,
		752 => qq|UPDATE `servicos` SET `fim` = ? WHERE `id` = ?|,
		753 => qq|UPDATE `servicos` SET `vencimento` = ?, `inicio` = ? WHERE `id` = ?|,
		754 => qq|UPDATE `servicos` SET `envios` = ? WHERE `id` = ?|,
		755 => qq|UPDATE `servicos` SET `proximo`=? WHERE `id` = ?|,
		756 => qq|UPDATE `servicos` SET `vencimento`=? WHERE `id` = ?|,
		757 => qq|UPDATE `servicos` SET `proximo` = ?, `invoice` = ? WHERE `id` = ?|,
		758 => qq|UPDATE `servicos` SET `inicio` = ?, `vencimento` = ? WHERE `id` = ?|,
		759 => qq|UPDATE `servicos` SET `invoice` = NULL, `vencimento` = ? WHERE `id` = ?|,
		760 => qq|UPDATE `servicos` SET `inicio` = ? WHERE `id` = ?|,
		761 => qq|UPDATE `servicos` SET `servidor` = ?, `inicio` = ?, `useracc` = ?, `fim` = ? WHERE `id` = ?|,
		762 => qq|UPDATE `servicos` SET `fim` = ?, `invoice` = ? WHERE `id` = ?|,
		763 => qq|UPDATE `servicos` SET `status` = ? WHERE `id` = ?|,
		764 => qq|UPDATE `servicos` SET `inicio` = ?, `fim` = ? WHERE `id` = ?|,
		765 => qq|UPDATE `servicos` SET `useracc` = ? WHERE `id` = ?|,
		766 => qq|UPDATE `servicos` SET `useracc` = ? WHERE `servidor` = ? AND `dominio` = ?|,
		767 => qq|UPDATE `servicos` SET `envios` = ?, `def` = ? WHERE `id` = ?|,
		768 => qq|UPDATE `servicos` SET `invoice` = ? WHERE `id` = ? AND `invoice` = ?|,
		769 => qq|UPDATE `servicos` SET `status` = ?, `action` = ?, `vencimento` = ?, `fim` = ?, `proximo` = ?, `envios` = ?, `pagos` = ? WHERE `id` = ?|,
		770 => qq|UPDATE `servicos` SET `vencimento` = ?, `fim` = ?, `proximo` = ?, `envios` = ?, `pagos` = ? WHERE `id` = ?|,
		771 => qq|UPDATE `servicos` SET `username` = ? WHERE `id` = ?|,		
		772 => qq|UPDATE `servicos` SET `status` = ?, `action` = ?, `servidor` = ?, `inicio` = ?, `useracc` = ?, `fim` = DEFAULT WHERE `id` = ?|,
		773 => qq|UPDATE `servicos` SET `status` = ?, `action` = ? WHERE `id` = ?|,
		774 => qq|UPDATE `servicos` SET `fim` = ?, `status` = ?, `action` = ? WHERE `id` = ?|,
		775 => qq|UPDATE `servicos` SET `status` = ? WHERE `id` = ? AND `username` = ? |,
		776 => qq|UPDATE `servicos` SET `pg` = ? WHERE `id` = ? AND `username` = ? |,
		777 => qq|UPDATE `servicos` SET `servicos` = ?, `action` = ? WHERE `id` = ? AND `username` = ?|,
		778 => qq|UPDATE `servicos` SET `vencimento` = ?, `envios` = 0, `def` = 0, `invoice` = 0, `pagos` = ? WHERE `id` = ?|,
		779 => qq|UPDATE `servicos` SET `invoice` = ? WHERE id = ?|,
		780 => qq|SELECT `servicos`.*,`planos`.`level`,`planos`.`plataforma`,`planos`.`nome`,`planos`.`tipo`,`planos`.`descricao`,`planos`.`campos`,`planos`.`setup`,`planos`.`valor`,`planos`.`valor_tipo`,`planos`.`auto`,`planos`.`pagamentos`,`planos`.`alert`,`planos`.`pservidor`,`servicos_set`.`MultiWEB`,`servicos_set`.`MultiDNS`,`servicos_set`.`MultiFTP`,`servicos_set`.`MultiDB`,`servicos_set`.`MultiMAIL`,`servicos_set`.`MultiSTATS`,`cancelamentos`.`motivo` FROM `servicos` LEFT JOIN `planos` ON `servicos`.`servicos`  = `planos`.`servicos` LEFT JOIN `servicos_set` ON `servicos`.`id`=`servicos_set`.`servico` LEFT JOIN `cancelamentos` ON `servicos`.`id`=`cancelamentos`.`servid` WHERE `servicos`.`id` = ?|,
		781 => qq|SELECT `id` FROM `servicos` WHERE (`servicos`.`username` = ? AND (`servicos`.`status` != "C" AND `servicos`.`status` != "F"))|,
		782 => qq|$SELECT_v3_services  WHERE s.`status` LIKE ?|,
		783 => qq|$SELECT_v3_services WHERE (s.`id` LIKE CONCAT('%',?,'%') OR useracc LIKE CONCAT('%',?,'%') OR s.`username` LIKE CONCAT('%',?,'%') OR `dominio` LIKE CONCAT('%',?,'%') OR s.`servicos` LIKE CONCAT('%',?,'%') OR pl.`nome` LIKE CONCAT('%',?,'%') OR `servidor` LIKE CONCAT('%',?,'%') OR srv.`nome` LIKE CONCAT('%',?,'%') OR `dados` LIKE CONCAT('%',?,'%') OR `pg` LIKE CONCAT('%',?,'%') OR pg.`nome` LIKE CONCAT('%',?,'%') OR `invoice` LIKE CONCAT('%',?,'%') OR `pagos` LIKE CONCAT('%',?,'%') OR pl.`tipo` LIKE CONCAT('%',?,'%') OR `action` LIKE ? OR `desconto` LIKE CONCAT('%',?,'%') OR `inicio` LIKE CONCAT('%',?,'%') OR `fim` LIKE CONCAT('%',?,'%') OR `vencimento` LIKE CONCAT('%',?,'%') OR status LIKE CONCAT('%',?,'%'))|,
		
		789 => qq|$SELECT_v3_services WHERE (`?` LIKE CONCAT('%',?,'%'))|,
		
		784 => qq|SELECT `status`, COUNT(*) `total` FROM `servicos` WHERE `servicos` = ? GROUP BY `status`|,
		785 => qq|SELECT * FROM `v3_servicos` WHERE `status` LIKE ? AND `username` = ?|,
		786 => qq|SELECT `servicos`.`id` FROM `servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` WHERE (`servicos`.`servicos` = ? AND HEX(`servicos`.`dominio`) = HEX(CONVERT(? USING latin1)) AND `planos`.`tipo` != "Adicional") AND `servicos`.`status` NOT IN ('F','C')|,
		787 => qq|SELECT DISTINCT `servicos` AS plano FROM `servicos` WHERE servicos|,
		788 => qq|SELECT DISTINCT `servidor` FROM `servicos` WHERE servidor|,
		# Definicoes de Servicos #
		791 => qq|REPLACE INTO `servicos_set` (`servico`,`MultiWEB`,`MultiDNS`,`MultiFTP`,`MultiDB`,`MultiMAIL`,`MultiSTATS`) VALUES (?,NULL,NULL,NULL,NULL,NULL,NULL)|,
		792 => qq|SELECT (SELECT `nome` FROM `servidores` WHERE `servidores`.`id` = `servicos_set`.`MultiWEB`) MultiWEB, (SELECT `nome` FROM `servidores` WHERE `servidores`.`id` = `servicos_set`.`MultiDNS`) MultiDNS, (SELECT `nome` FROM `servidores` WHERE `servidores`.`id` = `servicos_set`.`MultiFTP`) MultiFTP, (SELECT `nome` FROM `servidores` WHERE `servidores`.`id` = `servicos_set`.`MultiDB`) MultiDB, (SELECT `nome` FROM `servidores` WHERE `servidores`.`id` = `servicos_set`.`multiMAIL`) MultiMAIL, (SELECT `nome` FROM `servidores` WHERE `servidores`.`id` = `servicos_set`.`MultiSTATS`) MultiSTATS FROM `servicos_set` WHERE `servicos_set`.`servico` = ?|,		
		9 => qq|REPLACE INTO `servicos_set` (`servico`,`MultiWEB`,`MultiDNS`,`MultiFTP`,`MultiDB`,`MultiMAIL`,`MultiSTATS`) VALUES (?,?,?,?,?,?,?)|,		
		43 => qq|DELETE FROM `servicos_set` WHERE `servico` = ?|,		
		810 => qq|UPDATE `servicos_set` SET `$_` = ? WHERE `servico` = ?|,
		# Cancelamento de Servicos #
		811 => qq|DELETE FROM `cancelamentos` WHERE `servid` = ?|,		
		820 => qq|INSERT INTO `cancelamentos` (`id`,`servid`,`motivo`) VALUES (NULL,?,?)|,
		# Propriedades #
		821 => qq|REPLACE INTO `promocao` (`servico`,`value`,`type`) VALUES (?,?,?)|,
		822 => qq|DELETE FROM `promocao` WHERE `servico` = ?|,		
		823 => qq|DELETE FROM `promocao` WHERE `servico` = ? AND `type` = ?|,
		824 => qq|SELECT * FROM `promocao` WHERE `servico` in (?)|,
		825 => qq|INSERT INTO `promocao` (`servico`,`value`,`type`) VALUES (?,?,?)
				ON DUPLICATE KEY UPDATE `value`= VALUES(value)|,
		# Cartao de Credito Infos
		851 => qq|SELECT * FROM `cc_info` WHERE `id` = ?|,
		852 => qq|SELECT * FROM `cc_info` WHERE `tarifa` = ? AND `active` = ? AND `username` = ?|,
		853 => qq|UPDATE `cc_info` SET `active` = ?  WHERE `id` = ?|,
		854 => qq|INSERT INTO `cc_info` (`username`,`name`,`first`,`last`,`ccn`,`exp`,`cvv2`,`active`,`tarifa`) VALUES (?,?,?,?,?,?,?,?,?)
				ON DUPLICATE KEY UPDATE `exp` = VALUES(exp), `cvv2` = VALUES(cvv2)|,
		855 => qq|SELECT * FROM `cc_info` WHERE `username` = ?|,
		856 => qq|UPDATE `cc_info` SET `active` = ? WHERE `tarifa` = ? AND `username` = ? AND `id` != ?|,
		857 => qq|DELETE FROM `cc_info` WHERE `id` = ?|,
		858 => qq|UPDATE `cc_info` SET `cvv2` = ?, `exp` = ?, `name` = ? WHERE `ccn` = ? AND `username` = ? AND `id` != ?|,
		859 => qq|SELECT * FROM `v1_ccinfo` WHERE `active` LIKE ?|,
		860 => qq|SELECT * FROM  `v1_ccinfo` WHERE (`id` LIKE CONCAT('%',?,'%') OR `username` LIKE CONCAT('%',?,'%') OR `name` LIKE CONCAT('%',?,'%') OR `first` LIKE CONCAT('%',?,'%') OR `last` LIKE CONCAT('%',?,'%') OR `tarifa` LIKE CONCAT('%',?,'%'))|,
		861 => qq|SELECT * FROM `v1_ccinfo` WHERE (`?` LIKE CONCAT('%',?,'%')) AND `active` LIKE ?|,		
		# Tarifas
		871 => qq|SELECT * FROM `tarifas` WHERE `id` = ?|,
		872 => qq|SELECT * FROM `tarifas`|,
		873 => qq|SELECT * FROM `tarifas` WHERE `visivel` LIKE ?|,		
		874 => qq|SELECT * FROM `tarifas` WHERE (`id` LIKE CONCAT('%',?,'%') OR `tipo` LIKE CONCAT('%',?,'%') OR `modo` LIKE CONCAT('%',?,'%') OR `modulo` LIKE CONCAT('%',?,'%') OR `valor` LIKE CONCAT('%',?,'%') OR `tplIndex` LIKE CONCAT('%',?,'%') OR `autoquitar` LIKE CONCAT('%',?,'%')) AND `visivel` LIKE ?|,
		875 => qq|SELECT * FROM `tarifas` WHERE (`?` LIKE CONCAT('%',?,'%')) AND `visivel` LIKE ?|,
		# Ips Bloqueados
		900 => qq|SELECT * FROM `blocked_ips` WHERE `ip` = INET_ATON(?) AND `time` + INTERVAL 1 DAY > NOW()|,
		901 => qq|INSERT INTO `blocked_ips` (`ip`,`time`) VALUES (INET_ATON(?),NOW())|,
		# Mail #
		1000 => qq|SELECT * FROM `em_forwarders` WHERE ? REGEXP `address`|,
		#Pagamentos
		1030 => qq|SELECT *,IF(`parcelas` = 1,1,0) pre FROM `pagamento` WHERE `id` in (?)|,
		1031 => qq|SELECT `pagamento`.*, `descontos`.`id` AS `did`, `descontos`.`valor` FROM `pagamento` LEFT JOIN `descontos` ON `pagamento`.`id`=`descontos`.`pg` AND `plano` = ?|,	
		1032 => qq|SELECT *,IF(`parcelas` = 1,1,0) pre FROM `pagamento` WHERE IF(`parcelas` >= 1 AND `primeira` = 0,0,1) LIKE ?|,
		1033 => qq|SELECT *,IF(`parcelas` = 1,1,0) pre FROM `pagamento` WHERE (`id` LIKE CONCAT('%',?,'%') OR `nome` LIKE CONCAT('%',?,'%') OR `primeira` LIKE CONCAT('%',?,'%') OR `intervalo` LIKE CONCAT('%',?,'%') OR `parcelas` LIKE CONCAT('%',?,'%') OR `pintervalo` LIKE CONCAT('%',?,'%') OR `repetir` LIKE CONCAT('%',?,'%') OR `tipo` LIKE CONCAT('%',?,'%')) AND IF(`parcelas` >= 1 AND `primeira` = 0,0,1) LIKE ?|,
		1034 => qq|SELECT * FROM `pagamento`|,
		1035 => qq|INSERT INTO `pagamento` (`id`,`nome`,`primeira`,`intervalo`,`parcelas`,`pintervalo`,`tipo`,`repetir`) VALUES (NULL,?,?,?,?,?,?,?)|,
		1036 => qq|SELECT DISTINCT `pg` AS id FROM `servicos` WHERE pg|,
		1037 => qq|DELETE FROM `pagamento` WHERE `id` = ?|,	
		1038 => qq|SELECT *,IF(`parcelas` = 1,1,0) pre FROM `pagamento` WHERE (`?` LIKE CONCAT('%',?,'%'))|,
		#Formulários
		1050 => qq|SELECT * FROM `|.$self->TABLE_FORMS.qq|` WHERE `id` = ?|,
		#Stats
		1065 => qq|INSERT `|.$self->TABLE_STATS.qq|` (`id`, `username`, `service`, `invoice`, `call`, `conheceu`) VALUES (NULL,?,?,?,?,?)|,
		#Segurança
		1081 => qq|SELECT `username`,`right`,`value` FROM `|.$self->TABLE_PERMS.qq|` WHERE `username` = ?|,
		1082 => qq|SELECT `username`,`right`,`value` FROM `|.$self->TABLE_PERMS.qq|` WHERE `username` = ?
					UNION SELECT ?,`right`,`value` FROM `securitygroups` WHERE |,
		1083 => qq|SELECT `group` FROM `staffgroups` WHERE `username` = ?|,						
		1084 => qq|SELECT distinct `groupname` FROM `|.$self->TABLE_PERMSGROUP.qq|`|,
		1090 => qq||,
	);
}
1;
__END__;
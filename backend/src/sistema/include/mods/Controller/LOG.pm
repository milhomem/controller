#!/usr/bin/perl
#
# Controller - is4web.com.br
# 2007
package Controller::LOG;

require 5.008;
require Exporter;

use Cwd;
use File::Spec;

our @ISA = qw( Exporter );

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	my $self = {
		@_,
		'ERR' => undef,
		'_queue' => 'log.sql',
		'_error' => 'error.log',
	};
	
	system("mkdir $self->{'_cwd'}/$self->{'_fd_logs'}") unless (-e "$self->{'_cwd'}/$self->{'_fd_logs'}");
	$self->{'handle_log'} = sub { open HANDLE, ">> $self->{'_cwd'}/$self->{'_fd_logs'}/$self->{'_queue'}" or die($!);  binmode HANDLE, ':utf8'; print HANDLE @_; close HANDLE;};
	$self->{'handle_error'} = sub { open HANDLE, ">> $self->{'_cwd'}/$self->{'_fd_logs'}/$self->{'_error'}" or die($!); binmode HANDLE, ':utf8'; print HANDLE @_; close HANDLE;};

	bless($self, $class);	
	
	return $self;
}

sub logevent {
	my ($self) = shift;

	my $file = File::Spec->abs2rel( Cwd::abs_path($0), $self->setting('data') );
	$self->{'handle_error'}("<$file ".$self->calendar('timenow24').">: @_\n");

	return 1;
}

sub logcron {
	my ($self) = shift;
	
	local $Controller::SWITCH{skip_log} = 1;
	local $Controller::SWITCH{skip_sql} = 0;
	my $mess = Controller::URLDecode2(shift);
	Controller::html2text(\$mess);
	my $type = $_[0] || $self->{cron}{type} || 4;
	my $id = $_[1] || $self->{cron}{id} || $self->sid;
	my $sql = qq|REPLACE INTO `cron` (`id`,`tipo`,`motivo`) SELECT ?,?,? FROM DUAL|;
	if ($_[2] == 1) {
		$sql .= qq| WHERE NOT EXISTS (SELECT * FROM `cron` WHERE `id` = ? AND `tipo` = ?)|; #No Replace
		$self->execute_sql($sql,$id,$type,$mess,$id,$type) if $id and $type and defined $mess;	
	} else {
		$self->execute_sql($sql,$id,$type,$mess) if $id and $type and defined $mess;
	}
	
	return 1;
}

sub logcronRemove {
	my ($self) = shift;
	
	local $Controller::SWITCH{skip_log} = 1;
	local $Controller::SWITCH{skip_sql} = 0;
	my $type = $_[0] || $self->{cron}{type} || 4;
	my $id = $_[1] || $self->{cron}{id} || $self->sid;
	$self->execute_sql(1,$id,$type) if $id and $type;
	
	return 1;
}

sub log {
	my ($self, %log) = @_;	
	
	my @file = (undef, File::Spec->abs2rel( Cwd::abs_path($0), $self->setting('data') ) );
	my $db = $log{byuser} ? "log" : "log_sys";
	my $sql = qq|INSERT INTO `$db` |;
	$sql .= qq|(`file`,`action`,`table`,`user`,`servico`,`value`,`byuser`,`data`,`tempo`,`debug`) | if $db eq 'log';#log
	$sql .= qq|(`file`,`action`,`table`,`user`,`servico`,`value`,`data`,`tempo`,`debug`) | if $db eq 'log_sys';#log_sys
	$sql .= qq|VALUES (?,?,?,?,?,?,|;
	$sql .= qq|?,| if $log{byuser};
	$sql .= qq|?,?,?)|;
	$self->get_time;
	my @binds = ($file[1],$log{cmd},$log{table},$log{user},$log{servico},$log{value},$self->{date}{timemysql},$self->{date}{time24},$log{debug});
	splice(@binds,6,0,$log{byuser}) if $log{byuser};
	$self->{dbh}->do($sql,undef,@binds) || die "Log Mysql: ".$self->{dbh}->{'mysql_error'}." ***$sql : @binds";
	
	return $self->error ? 0 : 1;
}

sub log_news {
	my ($self) = shift;

	$self->get_time();
	local $Controller::SWITCH{skip_log} = 1;
	$_[3] =~ s/\{(link|news)\}/#/g;
	my $id = $self->execute_sql(qq|INSERT INTO `log_news` (`id`,`byuser`,`from`,`to`,`subject`,`body`,`data`,`tempo`) 
		VALUES (NULL,?,?,?,?,?,?,?)|,
		$self->{cookname},$_[0],$_[1],$_[2],$_[3],$self->{date}{timemysql},$self->{date}{time24}
	);
	
	return $self->error ? 0 : $id;
}

sub log_mail {
	my ($self) = shift;

	return 1 if $Controller::SWITCH{skip_logmail} == 1;
	use Encode 'is_utf8';	
	$self->get_time();
	local $Controller::SWITCH{skip_log} = 1;
	my $id = $self->execute_sql(qq|INSERT INTO `log_mail` (`id`,`byuser`,`user`,`from`,`to`,`subject`,`body`,`data`,`tempo`,`enviado`) 
		VALUES (NULL,?,?,?,?,?,?,?,?,?)|,
		$self->{cookname},$_[0],$_[1],$_[2],$_[3],$_[4],$self->{date}{timemysql},$self->{date}{time24},
		$_[5] || 1 #Caso não tenha erros marca como sucesso
	) if $self->num($_[0]); #Username must be num
	
	return $self->error ? 0 : $id;
}

sub log_sql {
	my ($self,$insertid) = @_;
	
	$self->sql_parse;

	my $tables = join(',', @{$self->{'sql'}{'table_names'}});
	unless ($tables =~ /(?:online|actionlog)(?:,|$)/i) {
		my $username = $self->{'sql'}{where_cols}{USERNAME}[0] || $self->{'sql'}{set}{USERNAME};
		$username = $self->{'sql'}{where_cols}{USER}[0] || $self->{'sql'}{set}{USER} if ($tables =~ /(?:log_mail)(?:,|$)/i);  	
		my $servico = $self->{'sql'}{where_cols}{ID}[0] || $self->{'sql'}{set}{ID} if ($tables =~ /(?:servicos|promocao)(?:,|$)/i);
		$servico = $self->{'sql'}{where_cols}{SERVICO}[0] || $self->{'sql'}{set}{SERVICO} if ($tables =~ /(?:promocao|servicos_set)(?:,|$)/i);
		$servico = $self->{'sql'}{where_cols}{SERVID}[0] || $self->{'sql'}{set}{SERVID} if ($tables =~ /(?:cancelamentos)(?:,|$)/i);
		$username = $insertid if ($tables =~ /^users$/i and $self->{'sql'}{command} eq 'INSERT');
		$servico = $insertid if ($tables =~ /^servicos$/i and $self->{'sql'}{command} eq 'INSERT');
		$self->{'sql'}{where_cols}{ID}[0] = $self->{'sql'}{set}{CALL}[0] if ($tables =~ /(?:notes)(?:,|$)/i) and $self->{'sql'}{command} eq 'INSERT';
		#Lookup when info is unavaiable
		unless ($username) {
			my $olderr = $self->clear_error;
			if ($servico) {
				$self->sid($servico);
				$username = $self->uid;
			} else {
				$username = $self->return_username($self->{'sql'}{where_cols}{ID}[0], $tables) if $self->{'sql'}{where_cols}{ID}[0];
			}
			#Recuperando os dados
			$self->clear_error;
			$self->set_error($olderr) if $olderr;
		}

		$self->{'sql'}{'errstr'} || !$self->{'sql'}{command}
			?	$self->log(
						'cmd' => 'UNKNOW',
						'table' => 'TODO',
						'value' => $self->{'sql'}{'errstr'},
						'byuser' => $self->{cookname},
						'debug' => $self->{_statement} )
			:	$self->log(
						'cmd' => $self->{'sql'}{command},
						'table' => lc join(',', @{$self->{'sql'}{'table_names'}} ),
						'value' => '',
						'user' => $username,
						'servico' => $servico,
						'byuser' => $self->{cookname},
						'debug' => $self->tostring );
	}	

	return 1;
}

sub logged_mail {
	my ($self) = shift;
	my %dados = @_;
	$dados{lc $_} = delete $dados{$_} for keys %dados; #LC keys %dados
	
	my @columns =keys %{ $self->{dbh}->column_info(undef, undef, 'log_mail', '%')->fetchall_hashref('COLUMN_NAME') };
	my @dadoscol = keys %dados;
	my ($select,$where) = Controller::iDifference(\@columns,\@dadoscol);
	
	my $i;
	my $sth = $self->select_sql(qq|SELECT |.Controller::iSQLjoin($select,0)
			.qq| FROM `log_mail` WHERE |.Controller::iSQLjoin($where,1,"AND").qq| ORDER BY `data` DESC,`tempo` DESC|,map { $dados{$_} } @$where);
	   while(my $ref = $sth->fetchrow_hashref()) {
			foreach my $q (@$select) {
				if ($sth->{TYPE}->[$sth->{NAME_hash}{$q}] == 9) {
					$self->{'logged_mail'}[$i]{lc $q} = $self->date($ref->{$q});
				} else {
					$self->{'logged_mail'}[$i]{lc $q} = $ref->{$q};
				}				
			}
			$i++;
	   }
    $self->finish;
    
	return $self->error ? 0 : 1;
}

1;
__END__;
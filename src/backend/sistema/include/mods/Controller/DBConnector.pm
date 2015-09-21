#!/usr/bin/perl
package Controller::DBConnector;

require 5.008;
require Exporter;

use Carp;
use DBI;
#use DBD::Oracle qw(:ora_types);
use DBD::mysql;

@ISA = qw(Exporter);
@EXPORT_OK = qw( connect );

BEGIN {
$Controller::DBConnector::VERSION = "0.3";
}

=head1 NAME

DBConnec tor - Connector and Operator of DataBases with DBI

=head1 SYNOPSIS
	use DBConnector;

	#Connect Oracle
	$dbh = DBConnector->new();
	$dbh = $dbh->connect('oracle', 'user', 'pass', 'hsot', 'port', 'instancia');
	
	#Connect MSSQL
	$dbh = DBConnector->new();
	$dbh = $dbh->connect('mssql', 'user', 'pass', 'host', 'port', 'database');
	
	#Connect MySQL
	$dbh = DBConnector->new();
	$dbh = $dbh->connect('mysql', 'user', 'pass', 'host', 'port', 'database');
	
	$dbh is now a reference to DBI::db package
	
=cut

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	my $self = {
		'_type' => undef,
		'_user' => undef,
		'_pass' => undef,
		'_host' => 'localhost',
		'_port' => undef,
		'_inst' => undef,
		'dbh' => undef,
		'ERR' => undef,
	};
	
	bless($self,$class);
		
	return($self);	
}

sub connect {
	my ($self,$type,$user,$pass,$host,$port,$inst,$timeout) = @_;

	$self->{_user} = $user if $user;
	$self->{_pass} = $pass if $pass;
	$self->{_host} = $host if $host;
	$self->{_port} = $port if $port;
	$self->{_inst} = $inst if $inst;
	$self->{_type} = $type if $type;
	$self->{_timeout} = $type if $timeout;	
	$self->{_timeout} ||= 300;

	if ($self->{_type} =~ /^oracle$/i) {
		return $self->_oracle();
	};
	
	if ($self->{_type} =~ /^mssql$/i) {
		return $self->_mssql();
	};

	if ($self->{_type} =~ /^mysql$/i) {
		return $self->_mysql();
	};

	return undef;
}

#Oracle
sub _oracle {
	my ($self) = shift;
	
	my $cstring = qq|dbi:Oracle:host=$self->{_host};sid=$self->{_inst};|;
	$cstring .= qq|port=$self->{_port}| if $self->{_port};
	$self->{dbh} = DBI->connect($cstring, $self->{_user}, $self->{_pass}) || do {$self->set_error($DBI::errstr); return undef;};
 	$self->{dbh}->{AutoCommit} = 1;
	$self->{dbh}->{RaiseError} = 1;
	$self->{dbh}->{ora_check_sql} = 0;
	$self->{dbh}->{RowCacheSize} = 16;
	$self->{dbh}->{LongReadLen} = 1024 * 1024; # 1 MB
	$self->{dbh}->{LongTruncOk} = 1; ### We are interested in the first 1 MB of data and We're happy to truncate any excess
		
	return $self->{dbh};
}

#MSSQL
sub _mssql {
	my ($self) = shift;
	#Pre-requisitos para Unix ou Linux
	#Instalar OOB cliente no Linux e Server do Windows
	#http://www.easysoft.com/developer/languages/perl/sql_server_unix_tutorial.html#accessing_sql_server_perl_unix_linux

	my $host = $self->{_host};
	$host .= ','.$self->{_port} if $self->{_port};
	my $DSN = qq|Driver={SQL Server};Server=$host;Database=$self->{_inst};Uid=$self->{_user};|;
	$DSN .= qq|Pwd=$self->{_pass};| if $self->{_pass};
	$self->{dbh} = DBI->connect("dbi:ODBC:$DSN", '','');
	$self->{dbh}->{HandleError} = sub { $self->Controller::DBConnector::MSSQLerror(shift) };
	$self->{dbh}->{PrintError} = 0;
	$self->{dbh}->{RaiseError} = 0;
	
	return $self->{dbh};
}

#MySQL
sub _mysql {
	my ($self) = shift;

	my $DSN = qq|DBI:mysql:database=$self->{_inst};host=$self->{_host};mysql_connect_timeout=$self->{_timeout}|;
	$DSN .= qq|port=$self->{_port}| if $self->{_port};
    $self->{dbh} = DBI->connect($DSN, $self->{_user}, $self->{_pass}) ||
    				do { $self->set_error(DBI::errstr); return undef;};
	$self->{dbh}->{HandleError} = sub { $self->Controller::DBConnector::MySQLerror(@_) };
	$self->{dbh}->{PrintError} = 0;
	$self->{dbh}->{RaiseError} = 0;
	$self->{dbh}->{mysql_auto_reconnect} = 1;
	$self->{dbh}->do("SET time_zone = '+0:00';");
	
	return $self->{dbh};
}

sub finish {
	my ($self,$qtd) = @_;
	
	$qtd ||= 1;
	for($i=1; $i <= $qtd; $i++) {
		my $sth = pop @{ $self->{_sths} };
		$sth->finish if $sth;
	}
		
	return 1;
}

sub disconnect {
	my ($self) = @_;
	
	$_ && $_->finish foreach @{ $self->{_sths} };
	$self->{dbh}->disconnect;
	$self->{dbh} = undef;
	
	return 1;	
}

sub connected {
	my ($self) = @_;
	
	return $self->{dbh}->{Active};
}

sub MySQLerror {
	my ($self) = shift;
	
	my $errno = $_[1]->err;
	if ($errno == 1062) {# the error to 'hide'
	    $_[2] = 'ERR'; #[ ... ];    # supply alternative return value
	    $self->set_error($self->lang(900));
	}
    return 1;
}

#construir query de acordo com o banco
# query_builder('select','*','table','id = 2','id')
sub query_builder {
#	my ($self,$type,$table,$itens,$) = @_;
}

1;
__END__;
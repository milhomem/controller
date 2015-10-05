#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008
package Controller::Users;

require 5.008;
require Exporter;
use Controller;

use vars qw(@ISA $VERSION);

@ISA = qw(Controller);

$VERSION = "0.2";

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

sub insert_data {
	my $self = shift;

	$self->{'_moduser'}{'ins_data'}{$_[0]} = $_[1] if exists $_[1];
	
	return $self->{'_moduser'}{'ins_data'}{$_[0]};
}

sub insert {
	my $self = shift;
	return if $self->error;

	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
		
	my $newuid = $self->execute_sql(663,insert_data($self,'username'),Controller::encrypt_mm(insert_data($self,'password')),insert_data($self,'vencimento'), insert_data($self,'status'), insert_data($self,'name'), insert_data($self,'email'),insert_data($self,'empresa'),
		insert_data($self,'cpf'),insert_data($self,'cnpj'),insert_data($self,'telefone'),insert_data($self,'endereco'),insert_data($self,'numero'),insert_data($self,'cidade'),insert_data($self,'estado'),insert_data($self,'cc'),insert_data($self,'cep'),
		insert_data($self,'level'),$self->today(), $self->randthis(2,@chars), insert_data($self,'pending'), "0", undef, "0", insert_data($self,'conta'),insert_data($self,'forma'),insert_data($self,'alert'),insert_data($self,'alertinv'),insert_data($self,'news'),insert_data($self,'language'),insert_data($self,'notes')) if insert_data($self,'username');
	$self->execute_sql(701,$newuid) if $newuid;		
	return $newuid;
		
	die $self->lang(1);	
}

sub save {
	my $self = shift;
	return if $self->error;
	
	my $user = $self->user;
	my (@columns,@set,@where,@wherev);
	foreach my $column ($self->user('changed')) {
		next if $column =~ m/^_/; #remove local extras columns
		push @columns, $column;
		if ($column eq 'email') {
			Controller::iUnique( $user->{$column} );
			push @set, join(',', @{ $user->{$column}});
		} else {
			push @set, $user->{$column};
		}
	}
	push @where, 'username';
	push @wherev, $self->uid;
	
	$self->SUPER::save($self->TABLE_USERS,\@columns,\@set,\@where,\@wherev) if scalar @set > 0;
	$self->user('changed',{});
	
	return $self->error ? 0 : 1;
}

sub save_config {
	my $self = shift;
	return if $self->error;
	foreach my $column ($self->user_config('changed')) {
		next if $column =~ m/^_/; #remove local extras columns
		$self->execute_sql(682,$column,$self->user_config($column),$self->uid);
	}
	
	return $self->error ? 0 : 1;
}

sub update_pass {
	my $self = shift;
	return if $self->error;
	
	my @chars = ("A" .. "Z", "a" .. "z", 0 .. 9);
	$self->user('password',Controller::encrypt_mm($_[0]));
	$self->execute_sql(666,$self->user('password'),$self->randthis(4,@chars),$self->uid) if $_[0];
	
	return $self->error ? 0 : 1;
}

sub fullid {
	my $self = shift;
	return if $self->error;
		
	return $self->setting('users_prefix').'-'.$self->uid;	  
}

sub remove {
	my $self = shift;
	return $self->set_error($self->lang(3,'Users::remove')), return unless $self->uid;
	
	my @sids = $self->services;
	my @erros;
	if (scalar @sids) {
		use Controller::Services;
	
		foreach (@sids) {
			$self->sid($_);
			$self->Controller::Services::remove;
			push @errors, $self->clear_error if $self->error;
		}
	}
	$self->set_error(join "\n", @errors) if scalar @errors;
	
	#Apagando chamados 
	foreach ($self->calls) {
		$self->execute_sql(65,$_);
		$self->execute_sql(381,$_);
	}
	$self->execute_sql(343,$self->uid);		
	#Apagando financeiro
	$self->execute_sql(431,$self->uid);#primeiro faturas
	my $sql_462 = $self->{queries}{462};
	$sql_462 .= qq| AND `|.$self->TABLE_CREDITS.qq|`.`username` = ?|;
	$self->execute_sql($sql_462,'O',$self->uid); #Creditos e Saldos		
	$self->execute_sql(qq|DELETE FROM `cc_info` WHERE `username` = ?|,$self->uid);
	#Apagando logs
	$self->execute_sql(161,$self->uid);
	$self->execute_sql(qq|DELETE FROM `indicates` WHERE `username` = ?|,$self->uid);
	$self->execute_sql(qq|DELETE FROM `stats` WHERE `username` = ?|,$self->uid);		
	#Ultimos		
	$self->execute_sql(661,$self->uid);
	$self->execute_sql(qq|INSERT INTO `users_del` (`username`) VALUES (?)|,$self->uid);
	
	return $self->error ? 0 : 1;
}

1;
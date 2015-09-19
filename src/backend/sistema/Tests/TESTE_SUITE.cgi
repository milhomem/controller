#!/usr/bin/perl
use CGI qw(:standard);
use CGI::Carp qw(fatalsToBrowser set_message);
use Cwd; 

use lib getcwd;
use lib 'include/mods';

use Test::More('no_plan');
Test::More->builder->failure_output(*STDOUT); #Apache sometimes dont output STDERR

use Controller;
$CGI::DISABLE_UPLOADS = 0;
$CGI::POST_MAX = 2048 * 1024;

use vars qw[ $system $dbhost $dbuser $dbpass $dbname $q ];

require "../db.cfg";

eval{
	our $q = new CGI;
	print header(-type => $q->param('html') == 1 ? "text/html" : "text/plain",-charset => 'iso-8859-1');	
	$system = new Controller (
				'_type'=>'mysql', 			
				'_host'=>$dbhost,
				'_user'=>$dbuser,
				'_pass'=>$dbpass,
				'_inst'=>$dbname,
				'_cwd'=>getcwd,
				'_fd_logs'=>'../logs',
	);
	
	#Modulos personalizados	
	push @INC, $system->setting('app').'/modules';

	ok( defined($system) && ref $system eq 'Controller', 'new Controller' );
	ok ( $system->setting('app'), 'Diretorio App definido: '.$system->setting('app') );
	ok( $system->_setlang('pt'), 'Linguagem pt-br') or diag($system->error);
	is( $system->lang(100, 'Mensagem', '100'), 'Teste de linguagem nome: Mensagem numero: 100', 'Lang test');

	$system->connect();

	ok( defined($system->{'dbh'}), 'connected to Mysql' );
	is($system->select_sql('SELECT `value` FROM `settings` WHERE `setting` = ?','version')->fetchrow_array(), '1.2', 'Controller version');

	$system->disconnect();

	ok( $system->{'dbh'} eq undef, 'disconnected to Mysql' );

	$system->connect();

	ok( defined($system->{'dbh'}), 'connected to Mysql' );
	can_ok($system, 'logevent');

	#Tests suite
	require "Tests/t/".$q->param('module').".pl";
};

if ($@) {
	print $@;
}

END{};
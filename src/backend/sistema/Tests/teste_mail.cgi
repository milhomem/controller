#!/usr/bin/perl

package Teste;
use lib 'include/mods';
use Controller;

use vars qw(@ISA $VERSION);

@ISA = qw(Controller Exporter);

$VERSION = "0.1";
$EMAIL = 'mail@toFireOut.tld';

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	#Subclass do Controller
	my $self = new Controller( @_ );
	$self = {
		%$self,
		'ERR' => undef,
	};
	
	bless($self, $class);
	
	return $self;
}

#simulando rotinas
sub sub_rotina_orverride {
	my $self = shift;
	return;
} 

1;

package main;
use CGI qw(:standard);                                 
#use DBI();                                             
#use Digest::MD5;
use CGI::Carp qw(fatalsToBrowser set_message);   # IMPRIME ERROS
use Cwd;
use Time::HiRes qw(sleep gettimeofday tv_interval);
	
use strict;
use lib getcwd;  
use lib 'include/mods';
	
use Test::More('no_plan');

use vars qw[ $system $dbhost $dbuser $dbpass $dbname $q ]; 

require "../db.cfg";

eval
{
	print header(-type => "text/plain",-charset => 'iso-8859-1');
	
	$system = new Teste ( 
			'_type'=>'mysql', 
			'_host'=>$dbhost, 
			'_user'=>$dbuser, 
			'_pass'=>$dbpass, 
			'_inst'=>$dbname,
			'_cwd'=>getcwd,
			'_fd_logs'=>'../logs',
			);
	my $rand = int rand(100); #identification
			
	ok( defined($system) && ref $system eq 'Teste', 'iniciando Teste de email' );

	local $Controller::Mail::SWITCH{skip_log} = 1;
	
	my $t0 = [gettimeofday()];
	my $i = 0;
	while (++$i < 1000) {
		#teste de email
		$system->email( To => $TESTE::EMAIL, From => $system->setting('adminemail'), Subject => "Teste de Email", Body => "Teste $i", ctype => 'text/plain');
		ok($system->{sender} && $system->{sender}->Connected,"Conexão re-aberta após ".($i-1)." emails enviados") or diag($system->error) if $system->{sender}{ctrl_counter} == 1;		
	}
	
	is( $i, 1001, "$i emails sended");
	print "Tempo total: ".tv_interval ($t0)."\n";
};

if ($@) {
	print $system->error;
	print "\n$@";
}                                                        

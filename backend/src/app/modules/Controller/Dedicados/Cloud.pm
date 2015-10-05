#!/usr/bin/perl
# Use: Module
# Controller - is4web.com.br
# 2010
#Pacote personalizado para criar servidores cloud
#através de um script perl e disponibilida na área
#do cliente um vncviewer em java para que ele acesse 
#o console remotamente sem usuário e senha.
package Controller::Dedicados::Cloud;

require 5.008;
require Exporter;

use vars qw(@ISA $VERSION $DEBUG $ERR);

@ISA = qw(Controller);

$VERSION = "0.1";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	#Depende do Controller
	my $self = new Controller( @_ );	
	%$self = (
		%$self,
		'ERR' => undef,
	);
	
	bless($self, $class);

	return $self;
}

sub has_adm {
	return 0;
}

#######################################
# Implementa a interface de Registros #
#######################################
sub Controller::Interface::Users::Clouds {
	my $self = shift;

	$self->template('id',$self->sid);
	$self->template('dominio',lc Controller::iso2puny($self->service('dominio')));  
	$self->template('useracc',$self->service('useracc'));
	$self->template('error', $self->template('useracc') ne '' ? '' : 'VM não identificada, contate nosso suporte!');
	
	$self->template('error', $self->lang(10)) if $self->service('lock') != 0;#Bloqueia edição de arquivos
	if ($self->service('lock') == 0 && $self->template('useracc') ne '') {
		my $cgi_file;		
		$cgi_file = 'Cloud.sh %s stop' if $self->param('reboot') == 0;
		$cgi_file = 'Cloud.sh %s start' if $self->param('reboot') == 1;
		$cgi_file = 'Cloud.sh %s restart' if $self->param('reboot') == 2;
		$cgi_file = 'Cloud.sh %s ticket' if $self->param('reboot') == 3;
		
		if ($cgi_file && defined $self->param('reboot')) {
			my $cmd = sprintf("/home/is4web/$cgi_file",$self->template('useracc'));
			my $result = `$cmd`;
			my $ok = $result !~ m/OK\n$/ ? 0 : 1;
			$self->template('error', $ok == 0 ? 'Falha ao executar!'.$result : 'Executado com sucesso!');	
								
			if ($self->param('reboot') == 3 && $ok) {
				$self->template('port',$1) if $result =~ m/Display Port:\s+(\d.+)/m;
				$self->template('host',$1) if $result =~ m/Host IP:\s+(\d+?\.\d+?\.\d+?\.\d+)/m;
				$self->template('password',$1) if $result =~ m/VM VNC password is:\s+(.+)/m;				
				$self->parse_jnlp('/vncviewer');
			} 
		} 
	}
	
	$self->parse('/cloud_adm');
}

sub parse_jnlp { #Mais utilizados pelos modulos que interagem com a interface grafica do usuario
	my ($self, $tpl) = @_;
	require CGI;
	my $q = CGI->new();
	
	my $file = $self->skin('data_tpl').$tpl.'.tpl';
	
	#this will supply content-type and \n to end header
	print $q->header(-type => "text/html",-charset => $self->setting('iso'));

	if (-e $file) {
		open TPL, "$file" || $self->die_nice($self->lang(15,$self->skin('name'),$file,$!));
			while (<TPL>) {                       
				$self->template_parse('text/plain'); #O template já está em html. 
				$self->lang_parse;
				print;
			}
		close TPL;        
	} else {
		print '<!-- '.$self->lang(15,$self->skin('name'),$file,$self->lang('notfound')).' -->';    
	}	
	
	exit(0);#Success	
}
1;
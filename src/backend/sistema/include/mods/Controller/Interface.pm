#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008 - 2012
package Controller::Interface;

require 5.008;
require Exporter;
use LWP::UserAgent;
use JSON;

use vars qw(@ISA $VERSION $inst_JSON);
@ISA = qw(Exporter JSON);

$VERSION = "0.3";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	%$self = ();
	
	bless($self, $class);
	
	return $self;
}

sub JSON {
	return $inst_JSON if $inst_JSON;
	our $inst_JSON = new JSON->utf8;
}

sub die_nice {}

sub parse { #Mais utilizados pelos modulos que interagem com a interface grafica do usuario
	my ($self, $tpl) = @_;
	require CGI;
	my $q = CGI->new();
	
	my $file = $self->skin('data_tpl').$tpl.'.tpl';
	my $default = $self->skin('data_tpl').'/default.tpl';
	unless (-e $default) {
		$self->script_error($self->lang(15,$self->skin('name'),'default.tpl',$self->lang('notfound')));
	}

	#this will supply content-type and \n to end header
	print cookies(0,$self->setting('user_timeout').'m','','user:'.$self->{cookname},'cert:'.$self->{cookcert},'tzo:'.$self->{cooktzo});	
	print $q->header(-type => "text/html",-charset => $self->setting('iso'));

	if ( $self->skin('ajax') == 1 ) {
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
	} else {
		open MAIN, "$default" || $self->script_error($self->lang(15,$self->skin('name'),'default.tpl',$!));
			while (<MAIN>) {  
				if (m/^(.*)\{(?:INNER|CONTENT)\}(.*)$/) {
					my ($bef,$aft) = ($1,$2);
					if (-e $file) {
						open TPL, "$file" || $self->die_nice($self->lang(15,$self->skin('name'),$file,$!));
							while (<TPL>) {                       
								$self->template_parse('text/plain'); #O template já está em html. ;
								$self->lang_parse;
								print;
							}
						close TPL;        
					} else {
						print $bef;
						print $self->lang(15,$self->skin('name'),$file,$self->lang('notfound'));
						print $aft;    
					}
				} elsif (m/^(.*)\{include:\s*(.+?)\s*\}(.*)$/i) {#a linha nao será removida
					my ($bef,$aft,$file) = ($1,$3,$2);
					$file = $self->skin('data_tpl').$tpl.'.tpl';
					print $bef;
					if (-e $file) {
						open TPL, "$file" || $self->die_nice($self->lang(15,$self->skin('name'),$file,$!));
							while (<TPL>) {                       
								$self->template_parse('text/plain'); #O template já está em html. 
								$self->lang_parse;
								print;
							}
						close TPL; 
					} else {
						print $self->lang(15,$self->skin('name'),$file,$self->lang('notfound'));
					}
					print $aft;
				} else {
					$self->template_parse('text/plain'); #O template já está em html. 
					$self->lang_parse;
					print;
				}
			}
		close MAIN;
	}
	
	exit(0);#Success	
}

sub parse_var {
	my ($self, $name, $tpl) = @_;
	
	my $file = $self->skin('data_tpl').$tpl.'.tpl';
	my $template = $self->template;
	
	if (-e $file) {
		my $var;
		open MAIN, "$file" || die_nice("parse_var: $!");
			while (<MAIN>) { 
				$self->template_parse('text/plain'); #O template já está em html. 
				$self->lang_parse;
				$var .= $_;
			}                                          
		close MAIN;
		$template->{$name} .= $var;
	}
	
	return 1;	
}

sub option_enabled {
	my ($self) = shift;
	
	$self->template('selected', $_[0] == 1 ? 'selected' : '');
	$self->template('checked', $_[0] == 1 ? 'checked' : '');
	
	return 1;
}

sub cookies { #(0,exp[ymd],domain,name:value...)
	my ($self) = shift;
	my $ssl = shift;
	my $pre = "Set-Cookie: ";
	my $exp = "+".shift;
	my $domain = shift;	
	
	require CGI;
	my $q = CGI->new();
	foreach (@_) {
		my ($name,$value) = split(/\:/,$_);
		print $pre;
		print $q->cookie(-name=>$name,-value=>$value,-path=>'/',-expires =>$exp,-domain => $domain);
		print " secure" if $ssl;
		print "\n";
	}
}

sub templateAttr {
	@_=@_;
	my ($self,$el,$hashRef) = @_;
	
	$self->{templateAttrs}{$el} = $hashRef if exists $_[2] && ref($hashRef) eq 'HASH';
	$self->{templateAttrs}{$el} = {} unless ref($self->{templateAttrs}{$el}) eq 'HASH';
	
	return $self->{templateAttrs}{$el}	;
}

1;
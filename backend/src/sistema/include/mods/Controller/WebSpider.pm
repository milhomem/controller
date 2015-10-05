#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008
package Controller::WebSpider;

require 5.008;
require Exporter;
#use strict;
use WWW::Mechanize;
use Clone::PP qw(clone);

use vars qw(@ISA $VERSION);

@ISA = qw(WWW::Mechanize Exporter);

$VERSION = "0.2";

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	my $self;
	$self = new WWW::Mechanize( timeout => 180, ssl_opts => { verify_hostname => 0, SSL_verify_mode => SSL_VERIFY_NONE }, cookie_jar => {});
	$self->agent_alias('Windows Mozilla');
	
	bless($self, $class);
	
	return $self;
}

sub redirect {
	my ($self) = @_; 
	#redirected
	if ($self->success and my $refresh = $self->response->header('Refresh') ){#implementar no módulo
	    my($delay, $uri) = split m/;url=/i, $refresh;
	    $uri ||= $self->uri; # No URL; reload current URL.
	    sleep $delay;
	    $self->get($uri);
	}
	
	return 1;
}

sub refer2me {
	$childclass = shift;
	return 1;
}

sub Carp::croak {
	$childclass->{ERR} = "@_";
	return undef;
}

sub HTML::Form::value {
    my $self = shift;
    my $key  = shift;
    my $input = $self->find_input($key);
	return Carp::croak("No such field '$key'") unless $input;
    local $Carp::CarpLevel = 1;
    $input->value(@_);
}

sub get_frames {
	my $self = shift;
    my $num = 0;
    my @array;
    my @links = $self->find_all_links( tag_regex => qr/^(iframe|frame)$/ );
    foreach my $link (@links) {
        ++$num;
        my $link = $link->url_abs;
        $array[$num-1] = $link;
    }
return @array;
}
1;
__END__
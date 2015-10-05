#!/usr/bin/perl         
#
# Controller - is4web.com.br
# 2008
package Controller::Mail;

require 5.008;
require Exporter;

use vars qw(@ISA $VERSION);

@ISA = qw(Exporter);

$VERSION = "0.4";

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

sub messages {
	my ($self) = shift;
	
	$self->email(@_);
	#$self->sms(@_);
	
	return 1;
}

sub contact { #Has unliked, On change check
	my $self = shift;
	
	$self->{contact}{$_[0]} = $_[1] if $_[1];
	if ($_[0] =~ /^(To|Cc|Bcc)$/) {
		$self->{contact}{$_[0]} =~ s/;/,/g; 
	}

	return $self->{contact}{$_[0]};	
}

sub loadbody {
	my $self = shift;
		
	#sub
	my ($body,$bodyfull);
	
	$self->contact('ctype',undef);
	if ($self->contact('txt') && !$self->contact('Body')) {
		my $entid = (split('::',$self->user('level')))[0] if $self->uid;
		if ($entid && -e $self->setting("app")."/lang/".$self->{_setlang}."/emails/empresas/$entid/".$self->contact('txt').".txt") {
			open (MAILTPL, $self->setting("app")."/lang/".$self->{_setlang}."/emails/empresas/$entid/".$self->contact('txt').".txt");
				while (<MAILTPL>) {
					$self->contact('ctype', $1) if $. == 1 && $_ =~ /Content-Type: (.*)$/;					
					$self->template_parse($self->contact('ctype'));
					$self->lang_parse();
					$body .= $_ if $. != 1 || !$self->contact('ctype');
					$bodyfull .= $_;
				}  
			close(MAILTPL);
			$self->contact('Body',$body);
		} elsif (-e $self->setting("app")."/lang/".$self->{_setlang}."/emails/".$self->contact('txt').".txt") {
			open (MAILTPL, $self->setting("app")."/lang/".$self->{_setlang}."/emails/".$self->contact('txt').".txt");
				while (<MAILTPL>) {
					$self->contact('ctype', $1) if $. == 1 && $_ =~ /Content-Type: (.*)$/;					
					$self->template_parse($self->contact('ctype'));
					$self->lang_parse();
					$body .= $_ if $. != 1 || !$self->contact('ctype');
					$bodyfull .= $_;
				}  
			close(MAILTPL);
			$self->contact('Body',$body);
		} else {
			$self->contact('Body', $self->lang(5));
		}
	}

	$self->contact('BodyFull', $bodyfull ? $bodyfull : $self->contact('Body'));
	$self->{contact}{'Body'} =~ s/^Content-Type: .*\n//;#TODO unlinked to contact()
	$self->contact('ctype', Controller::trim($self->{contact}{'ctype'}) || 'text/html');
 my $em_header = $self->setting("em_header");
 my $em_footer = $self->setting("em_footer");
 	$self->{contact}{'Body'} =~ s/\[(header)\]/$em_header/gi;
 	$self->{contact}{'Body'} =~ s/\[(footer)\]/$em_footer/gi;
#die  	$self->{contact}{'Body'}; 	
	$self->{contact}{'TextBody'} = $self->{contact}{'Body'};
	
	Controller::html2text(\$self->{contact}{'TextBody'});#Convert html to text plain
	
	return 1;
}

sub _news {
	my ($self) = shift;

	my $news = $self->setting('baseurl')."/news.cgi?id=".$_[0];	
	my $link = $news . "&do=unsubscribe&key=".Controller::simple_crypt($_[1]);
	my $linkn = $news . "&do=view&key=".Controller::simple_crypt($_[1]);
	
	return ($link,$linkn);
}

sub _smtp {
	my ($self) = shift;
	
	$self->{sender}->Close(1) if $self->{sender} && $self->{sender}{ctrl_counter} >= $self->setting('max_mails_per_connection');	
	if (ref($self->{sender}) eq 'Mail::Sender' && $self->{sender}->Connected) {
		$self->{sender}{ctrl_counter}++;		
	} else {
		use Mail::Sender;
		use Sys::Hostname;
		$Mail::Sender::NO_X_MAILER = 1;
	 	$self->{sender} = new Mail::Sender {
				smtp => $self->setting("smtp_address"),
				port => $self->setting("smtp_port"), 
				reply => '',
				auth => 'LOGIN',
				authid => $self->setting("smtp_login"),
				authpwd => $self->setting("smtp_pass"),
				keepconnection => 1,
				client => hostname,
		};
		$self->{sender} = undef, $self->set_error($Mail::Sender::Error) if ref($self->{sender}) ne 'Mail::Sender';
		$self->{sender}{ctrl_counter}=1 if $self->{sender};
	}			

	return 1;
}

sub sendsmtp {
	my $self = shift;
	return 0 if $self->error;
		
	my (@bcc,$id);
	my $charset = $self->setting("iso");			

	#Addon Make Bcc become To, Only for Smtp Messages
	if ($self->contact('Bcc')) {
		@bcc = split(',',Controller::trim($self->contact('Bcc')));
	}
	if ($self->contact('News')) {
		$id = $self->log_news($self->contact('From'),Controller::trim($self->contact('Bcc')),$self->contact('Subject'),$self->contact('BodyFull'));
		return unless $id;		
	}
	for (my $i=0; $i <= scalar @bcc; $i++) {#make a loop to send messages
		my $to = $bcc[$i];
		my $cc;
		if ($i == scalar @bcc) { #send first to Bcc's than later To's and Cc's
			$to = $self->contact('To');
			$cc = $self->contact('Cc');
		}
		next unless $to; #A To is always required
		$self->_smtp; #connect to server
		if ($self->{sender}) {
			my $body = $self->contact('Body');
			my $txtbody = $self->contact('TextBody');
			if ($self->contact('News')) {
				my ($link,$linkn) = $self->_news($id,$to);
				$body =~s/\{link\}/$link/g;
				$txtbody =~s/\{link\}/$link/g;
				$body =~s/\{view\}/$linkn/g;
				$txtbody =~s/\{view\}/$linkn/g;
			}	
	
			$self->{sender}->OpenMultipart({
				from => Controller::trim($self->contact('From')),
				to => Controller::trim($to),
				cc => Controller::trim($cc),
				subject => $self->contact('Subject'),
				charset => $charset,					
			}) if !$self->{sender}->{'error_msg'};
			$self->{sender}->Part({ctype => 'multipart/alternative'}) if !$self->{sender}->{'error_msg'};
			$self->{sender}->Body({ 
				ctype => 'text/plain',
				msg => $txtbody,
				charset => $charset,
			}) if $self->contact('ctype') ne 'text/plain' && !$self->{sender}->{'error_msg'};				
			$self->{sender}->Body({ 
				msg => $body,
				ctype => $self->contact('ctype'),
				charset => $charset,					
			}) if !$self->{sender}->{'error_msg'};
			$self->{sender}->EndPart("multipart/alternative") if !$self->{sender}->{'error_msg'};
			$self->{sender}->Attach({
				encoding => 'Base64',
				disposition => "attachment; filename=".$self->contact('File'),
				file => $self->contact('Attf'),
			}) if $self->contact('Attf') && !$self->{sender}->{'error_msg'};
			$self->{sender}->Part({
				encoding => 'Base64',
				disposition => "attachment; filename=".$self->contact('File'),
				msg => $self->contact('Att'),
			}) if $self->contact('Att') && !$self->{sender}->{'error_msg'};
			$self->{sender}->Close; #Send the message and remain connection
		}
		
	}
	
	$self->set_error($self->{sender}->{'error_msg'}) if $self->{sender}->{'error_msg'};
	$self->set_error($self->lang(93)) unless $self->{sender}{ctrl_counter};	
	
	return $self->error ? 0 : 1;
}

sub sendmail {
	my $self = shift;
	return 0 if $self->error;	

	use Encode;

	my (@bcc,$id);
	if ($self->contact('News')) {
		$id = $self->log_news($self->contact('From'),Controller::trim($self->contact('Bcc')),$self->contact('Subject'),$self->contact('BodyFull'));
		return unless $id;		
	}	
	#Addon Make Bcc became To, Only for Smtp Messages
	if ($self->contact('Bcc')) {
		@bcc = split(',',Controller::trim($self->contact('Bcc')));
	}
	for (my $i=0; $i <= scalar @bcc; $i++) {#make a loop to send messages
		my $to = $bcc[$i];
		my $cc;
		if ($i == scalar @bcc) { #send first to Bcc's than later To's and Cc's
			$to = $self->contact('To');
			$cc = $self->contact('Cc');
		}
		next unless $to; #A To is always required
		my $body = $self->contact('Body'); 
		if ($self->contact('News')) {
			my ($link,$linkn) = $self->_news($id,$to);
			$body =~s/\{link\}/$link/g;
			$body =~s/\{view\}/$linkn/g;
		}			
		open(MAIL, "|".$self->setting('sendmail')." -t") || do{ ($self->{'ERR'}) = $! =~ m/(.*)at.*/; };		
			print MAIL "To: $to\n" if $to;
			print MAIL "Cc: $cc\n" if $cc;
			print MAIL "From: ".$self->contact('From')."\n";
			print MAIL "Content-Type: text/html; charset=UTF-8; format=flowed\n";
			print MAIL "Content-Transfer-Encoding: 8bit\n";
			print MAIL 'Subject: '.Encode::encode('MIME-Q',$self->contact('Subject'))."\n\n";
			print MAIL "$body\n";
		close(MAIL) || do{ ($self->{'ERR'}) = $! =~ m/(.*)at.*/; };			
	}
	
	return $self->{'ERR'} ? 0 : 1;
}

sub email {
	my $self = shift;
	return 0 if $self->error;
	%{ $self->{contact} } = @_;#email ( To => "email_to", From => "email_from", Subject => "", Body => "", Att => "att_scalar", File => "filename.ext", Attf => "att_file");
	$self->set_error($self->lang(91,$self->contact('From'))) if $self->contact('From') !~ /\@/;			
	return 0 if $self->error;		
	$self->{_emaillang} = $self->contact('Lang');
	#Teria que ser presumido um uid antes de chamar a funcao email
	$self->uid($self->contact('User')) if $self->contact('User') && $self->contact('User') != $self->uid;
	$self->{_emaillang} ||= $self->user('language') if $self->contact('User');		
	if ($self->setting("use_email") == 1) {
		if ($Contrller::SWITCH{skip_mail} != 1) {	
			#define lang
			my $roolback = $self->{_setlang} if $self->{_emaillang};
			$self->_setlang($self->{_emaillang}) if $self->{_emaillang};			
			$self->contact( 'Subject', $self->lang($self->contact('Subject')) ) unless $self->contact('Body');#body must be translated, so subject too
			$self->loadbody;
			my $sth = $self->select_sql(1000,$self->contact('To'));
		 	local $Contrller::SWITCH{skip_mail} = 1 if $sth->rows > 0;
		 	$self->set_error($self->lang(90,$self->contact('To'))) if $sth->rows > 0;
		 	#TESTE
		 	if ($self->setting('email_tester')) {
		 		$self->contact('Subject', $self->contact('Subject') . ' To:' . $self->contact('To').','.$self->contact('Cc').','.$self->contact('Bcc')); 
		 		$self->contact('To', $self->setting('email_tester') );
			 	$self->contact('Cc',''); $self->contact('Bcc','');	
		 	}

			if ($self->setting('use_smtp') == 1) {
				$self->sendsmtp;		
			} elsif ($self->setting('use_smtp') == 0) {
				$self->sendmail;
			} else {
				$self->set_error($self->lang(92,'use_smtp'));
				return 0;
			}
			#log_mail
			$self->log_mail($self->contact('User'),$self->contact('From'),$self->contact('To'),$self->contact('Subject'),$self->contact('BodyFull'),$self->error);
			#roolback system lang
			$self->_setlang($roolback) if $roolback;
			
			return $self->error ? 0 : 1;
		} else { warn 'email skipped'; }
	} else {
		$self->set_error($self->lang(6,'email'));
	}
	
	return 0;
}

sub sms {  #TODO SMS arrumar
 my %contact = @_;
 	return 0 if $self->error;

	if ($global{'use_sms'} == 1) {
		if ($self->contact('txt')){
			my $data_tpl = get_skin("$theme","data_tpl");
			if (-e "$data_tpl/sms/$self->contact('txt').txt") {
				open (MAILTPL, "$data_tpl/sms/$self->contact('txt').txt");
					while (<MAILTPL>) {
						s/\{(\S+?)\}/$template{$1}/gi;
						lang_parse();
#						$ctype = $_ if $a ne 1 && $_ =~ "Content-Type:";
						$body .= $_;# if $a eq 1 || !$ctype;
#						$bodyfull .= $_;
#						$a = 1;
					}  
				close(MAILTPL);
				$self->contact('Msg') = $body;
			} else {
				$self->contact('Msg') = "Arquivo não encontrado, informe ao seu provedor.";
			}
		}
	
		$self->contact('Tel') = num(Users($self->contact('User'),"telefone"));
		($self->contact('Ddi')) = split(" - ",Country(Users($self->contact('User'),"cc"),"call"));
		$self->contact('Ddi') ||= "55";#Brasil
	 my	($ok,$result) = sms_send("$self->contact('Ddi')","$self->contact('Tel')","$self->contact('Msg')");
	
		if ($result =~ "Numéro não confere") {
			$ok = 1;
			$self->contact('Msg') = $result;
		}
	
		$result = $ok if $ok;
		
		&get_time();
		$dbh->do(qq|INSERT INTO `log_mail` VALUES (NULL, "$self->contact('User')", "$global{'sms_host'}", "$self->contact('Ddi')$self->contact('Tel')", "", "$self->contact('Msg')", "$timemysql", "$timenow24", "$result")|) if $self->contact('User');
		
		return $ok;
	}
}

sub grab_emails {
	my $self = shift;
	return 0 if $self->error;
	use Mail::POP3Client;
	my $AMODE = "PASS";
	my $sth = $self->select_sql(122);
	while (my $ref = $sth->fetchrow_hashref) {			        
		my $pop_server = new Mail::POP3Client( USER   =>  $ref->{'pop_user'},
	   				        PASSWORD  =>  $ref->{'pop_password'},
					        HOST      =>  $ref->{'pop_host'},
					        PORT      =>  $ref->{'pop_port'},
					        AUTH_MODE =>  $AMODE,
					        TIMEOUT => 60,
					        DEBUG     =>  "1");
		return $self->set_error($self->lang(660, $ref->{'pop_host'},'No module')) unless $pop_server;
		my $state = $pop_server->State();
		return $self->set_error($self->lang(660, $ref->{'pop_host'}, $state)) unless ($state eq "TRANSACTION");
		my $total = $pop_server->Count();
		my $count = $total;
		for (my $i = 1; $i <= $total; $i++) {
			eval {
				$|=1;
				local $SIG{PIPE} = sub { print $self->lang(661,@_); return; };
				open (HPDESK, "|perl include/email.cgi HPDESK")  or return $self->set_error($self->lang(662,$!));
					my $line = $pop_server->HeadAndBody($i);
					print HPDESK $line;			
					$pop_server->Delete($i);
				close HPDESK;
				open (HPDESKOUT, ">> $self->{'_cwd'}/$self->{'_fd_logs'}/mreader.log");
				my @out = <HPDESKOUT>;
				close HPDESKOUT;
				die @out if scalar @out;
			};
			if ($@) {
				$count--;
				print $self->lang(661,$@);
			}
		}
		$pop_server->Close() or print $self->lang(663,$!);
		print "$count de $total Emails Downloaded from $ref->{'pop_user'} \@ $ref->{'pop_host'}\n";
	}
	print "You have not set any POP retrieval up\n" if !$sth->rows;
	$self->finish;
}

1;
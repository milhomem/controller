#!/usr/bin/perl 
 
use strict;
#use warnings;
my $check = "1";
my $install;
my @mods = ( 
				'CGI',
				'Test::Deep',
				'MIME::Tools',
				'MIME::Parser', 
				'Mail::Address',
				'Mail::POP3Client',
				'Mail::Sender',
				'File::Temp',
				'Digest::MD5',
				'Date::Simple',
				'DBI',
				'CGI',
				'MD5',
				'GD::Graph',
				'DBD::mysql',
#				'DBD::mysqlPP',
				'HTML::Entities',
				'Net::IDN::Encode',
				'Encode',
				'Time::HiRes',
				'Cwd',
				'Data::Structure::Util',
				#windows
				#'Proc::PID_file',
				#linux
				'Net::EPP::Client',
				'Net::EPP::Frame',
				'Proc::PID::File',
				'Crypt::Simple',
				'Net::SSLeay',
				'Hash::Case::Upper',
				'Class::Load',
				'parent',
				'DateTime::TimeZone',
				'Class::Singleton',
				'YAML',
				'DateTime',
				'DateTime::Format::Builder',
				'DateTime::Format::ISO8601',
				'HTML::TreeBuilder',
				'B::RecDeparse',
				'HTML::TextToHTML',
				'Error',
				'XML::Simple',
				'XML::Parser',
				'WWW::Mechanize',
				'Socket6',
				'IO::Socket',
				'IO::Socket::INET6',
				'Net::DNS',
				'Net::DRI',
				'Digest::MD5',
				'Text::Iconv',
				'cPanel::PublicAPI',
				'Sys::Hostname',
				#Manual instalation
				'String',
				'IDNA::Punycode',
				'IO::Compress::Gzip',
				'Scalar::Util',
				'JSON',
				'Clone::PP',
				'Mozilla::CA',
		      ); 

print "Content-Type: text/html\n\n";
print qq|<HTML><HEAD><TITLE>Verificação de Módulos</TITLE></HEAD><BODY>
             <br><br><div align="center"><font color=blue face=Tahoma size=3><b>TESTE DE MÓDULOS</b><br></font><FONT SIZE=1 Face=Tahoma>$ENV{'SERVER_NAME'}<br><br><br></FONT>
             </div><table wifth="300" align="center"><td><font face="Tahoma" size="2">
  	  |;
	  
for my $mod (@mods) { 	
	eval "use $mod";
	if($@) { 
		print "[ <b><font color=red>ERROR</font></b> ] $mod não encontrado no servidor<br>\n";
		$check = "0";
		$install .= "$mod ";
	} else {
		print "[ <b><font color=green>OK</font></b> ] $mod<br>\n";			
	} 
}

if($check) { 
	print "Módulos [ <font color=green><b>OK</b></font> ]<br><br>Seu servidor possui todos os módulos necessários.<br> Você já pode utilizar o sistema CONTROLLER - is4web - software for web.\n";
} else { 
	print "<br>[ <font color=red><b>Execute</b></font> ] echo 'install $install' | cpan \n" if $install;
	print "<br>Antes de utilizar este script, certifique-se de que instalou todos os módulos requeridos.\n";
} 

print qq|</font></td></table></div></BODY></HTML>|;

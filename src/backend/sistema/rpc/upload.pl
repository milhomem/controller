#!/usr/bin/perl
# Controller - is4web.com.br
# 2011

use open ':utf8', ':std';
use encoding 'utf8';
use utf8; # encode = fromutf8, decode=toutf8
use strict;
use Cwd;
use File::Copy;
	
no encoding;

eval {
require CGI;
};

my $pwd = getcwd;
print "Content-Type: text/xml\n\n";

print "<upload>\n";

sub genhash
{
	my @WCHAR=qw/0 1 2 3 4 5 6 7 8 9 A B C D E F G H I J K L M N O P Q R S T U V W X Y Z a b c d e f g h i j k l m n o p q r s t u v w x y z/;
	my $var;
	for (1..$_[0])
	{
		$var.=$WCHAR[int(rand(@WCHAR))];
	}
	return $var;
}

eval
{
	my %form;
	my $filehash;
	my $filename;
	my $filenfo;
	my $filesize;
	
	my $folder = $pwd.'/../../upload/tmp';
	system("mkdir $folder; chmod 777 $folder") unless (-e "$folder");  
	my $f_prefix =  $folder.'/ctrl_';
	
	if (my $query=new CGI())
	{	
		my $i=0;
		my @names = $query->param;
		foreach my $name(@names)
		{			
			$form{$name}=$query->param($name);
			if (my $fh=CGI::upload($name))
			{
				my $tmpfilename = $query->tmpFileName($query->param($name));
				my $size=(stat($tmpfilename))[7];
				$filehash=genhash(16);
				my $filename=$query->param($name) || $form{'Filename'};
				if ($filename=~/^.*\.(.*?)$/){$filehash.=".".$1;}
				File::Copy::copy($tmpfilename, $f_prefix.$filehash);
				chmod(0777,$f_prefix.$filehash);
				$form{$name.'_hash'}=$filehash;
				
				$filename=~s|\'|\\'|;
				
				print "\t<file>\n";
				print "\t\t<hash><![CDATA[".$filehash."]]></hash>\n";
				print "\t\t<filename><![CDATA[".$filename."]]></filename>\n";
				print "\t</file>\n";
				
				$i++;
			}
		}
	}
	
};

if ($@) {
	print "<error>$@</error>";	
}

print "</upload>\n";

if ($@)
{
	open HANDLE, ">> $pwd/../../logs/upload.log" or die($!);
	binmode HANDLE, ':utf8';  
	print HANDLE $@;
	close HANDLE;		
}

1;
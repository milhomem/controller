%template = ( 
			lang    => $language,
			data => $global{'data'},
			title   => $global{'title'},
			baseurl => $global{'baseurl'} );

			$template{'data_tpl'} = get_skin("$theme","data_tpl");
			$template{'url_tpl'} = get_skin("$theme","url_tpl");
			$template{'imgbase'} = get_skin("$theme","imgbase");
			$template{'logo'} = get_skin("$theme","logo_url");

sub parse
{
 
 my $file  = "@_";
	$file .= '.tpl';

	unless (-e $file) {
		die_nice("Template não encontrado.<br>Configure o banco de dados e confira se os arquivos existem.");
	}

	#this will supply content-type and \n to end header
	print header(-type => "text/html",-charset => $global{'iso'});

	open TPL, "$file" || die "Error opening $file: $!";
		while (<TPL>) {                          
			template_parse();
			lang_parse();
			print;
		}
	close TPL;               
}

1;
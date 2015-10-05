%template = ( 
			lang    => $language,
			data => $global{'data'},
			title   => $global{'title'},
			baseurl => $global{'baseurl'},
			timen    => $timenow,  
#oldversion
			timen     => $timenow,
			custom    => 'custom_value',
			rtime     => "900",
			rdirector => "",
			sounda     => "",
			soundb     => ""
			);

			$template{'data_tpl'} = get_skin("$theme","data_tpl");
			$template{'url_tpl'} = get_skin("$theme","url_tpl");
			$template{'imgbase'} = get_skin("$theme","imgbase");
			$template{'logo'} = get_skin("$theme","logo_url");


sub parse
{
 my $file  = shift;
	$file .= '.tpl';
	$inneronly = shift;

 my $html;
 my $default;

	unless (-e "$template{'data_tpl'}/staff/default.tpl") {
		die_nice("Template não encontrado.<br>Configure o banco de dados e confira se os arquivos existem.");
	}

	#this will supply content-type and \n to end header
	print header(-type => "text/html",-charset => $global{'iso'});

	unless ($inneronly == 1) {
		open MAIN, "$template{'data_tpl'}/staff/default.tpl" || die_nice("Error: $!");
			while (<MAIN>) {  
				if (/\{CONTENT\}/) {
					if (-e $file) { 
						open TPL, "$file" || die "Error opening $file: $!";
							while (<TPL>) {                          
								template_parse();
								lang_parse();
								print;
							}
						close TPL;      
					} else {
						print "<td align=\"center\" valign=\"middle\">Template $file não encontrado.</td>";       
					}
				}
				template_parse();
				lang_parse();
				print;
			}                                          
		close MAIN;
	} else {
		if (-e $file) { 
			open TPL, "$file" || die "Error opening $file: $!";
				while (<TPL>) {                          
					template_parse();
					lang_parse();
					print;
				}
			close TPL;      
		} else {
			print "<td align=\"center\" valign=\"middle\">Template $file não encontrado.</td>";       
		}
	}	
	$has = 1;
}

1;
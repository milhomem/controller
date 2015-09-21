package OpenSRS::Util::ConfigJar;

sub import {
    my $class = shift;
    my $file = shift;
    if ($file) {
	do "$file";
    }
    return 1;
}

1;

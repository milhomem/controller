#!/usr/bin/perl
package Controller::Date;

require 5.008;
require Exporter;
use strict;
use Carp;
use Date::Simple;
use DateTime;

our @ISA = qw( Exporter );

BEGIN {
$Date::VERSION = "0.3";
}

=pod
########### ChangeLog #######################################################  VERSION  #
=item offset                                                                #           #
- Criado substituindo o método de offset antigo							    #    0.3    #
=item datefromISO8601                                                       #           #
- Adicionado opção de trazer a data para UTC ou timezone determinado        #    0.3    #
#############################################################################           #
=cut

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
	
	my $self = {
				date => undef,
		 		};
	
	bless($self, $class);
	
	return($self);	
}

sub calendar {
	my ($self) = shift;
	$self->get_time;
	$self->{date}{$_[0]} = $_[1] if $_[1];	
	return $self->{date}{$_[0]};
}

sub offset {
	my $self = shift;
	
	my $tz = DateTime::TimeZone->new( name => $self->setting('timeZone') );
	return $tz->offset_for_datetime( DateTime->now );
}

sub calendar_local {
	my ($self) = shift;
	$self->get_time($self->offset);	
	$self->{date}{$_[0]} = $_[1] if $_[1];	
	return $self->{date}{$_[0]};
}

sub get_time {
	my ($self,$offset) = @_;
	
	my ($variable,$hy);
	my $date = \%{$self->{'date'}};
	my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = gmtime(time+$offset);
	$hour = "0$hour" if ($hour < 10);
	$min  = "0$min" if ($min < 10);
	$sec  = "0$sec" if ($sec < 10);
	$date->{'time24'} = "$hour:$min:$sec";
	$date->{'timenow24'} = "$hour:$min";
    if ($hour >= 12) { $variable = "P.M."; }  else { $variable  = "A.M."; }
	if ($hour == 0) { $hour = 12; }
	if ($hour > 12) { $hour -= 12; }
	if ($mday =~ m/1$/) { $hy = "st"; 
	} elsif ($mday =~ m/2$/)  { $hy = "nd";
	} elsif ($mday =~ m/3$/)  { $hy = "rd"; 
	} else { $hy = "th"; }
	$date->{'year'} = 1900 + $year;
	$date->{'day'} = $self->dayname($wday);
	$date->{'month'} = $self->monthname($mon);
	$date->{'month_no'} = ++$mon < 10 ? "0$mon" : $mon;	
	$date->{'date'} = "$mday$hy";
	$date->{'date_no'} = $mday < 10 ? "0$mday" : $mday;
	$date->{'time'} = "$hour:$min:$sec $variable";
	$date->{'time_sv'} = "$hour:$min $variable";
	$date->{'time_var'} = "$hour:$min:$sec";
	$date->{'time_sec'} = "$hour:$min";	
	#FORMATO DA HORA PREDEFINIDOS
	$date->{'hdtime'} = qq|$date->{'year'}-$date->{'month_no'}-$date->{'date_no'} $date->{'timenow24'}|;
	$date->{'timedate'} = qq|$date->{'time_sec'} $date->{'date_no'}/$date->{'month_no'}/$date->{'year'}|;
	$date->{'timenow'} = qq|$date->{'time'} ($date->{'date_no'}/$date->{'month_no'}/$date->{'year'})|;
	$date->{'timenow24'} = qq|$date->{'timenow24'} ($date->{'date_no'}/$date->{'month_no'}/$date->{'year'})|;
	$date->{'timemysql'} = qq|$date->{'year'}-$date->{'month_no'}-$date->{'date_no'}|;
	$date->{'datemysql'} = qq|$date->{'year'}-$date->{'month_no'}-$date->{'date_no'}|;
	$date->{'datelinux'} = qq|$date->{'year'}/$date->{'month_no'}/$date->{'date_no'}|;
	$date->{'datenow'} = qq|$date->{'date_no'}/$date->{'month_no'}/$date->{'year'}|;
	$date->{'timestamp'} = ($self->date($date->{'datemysql'}) - $self->date('1970-01-01'))*24*60*60+($hour+12)*60*60+$min*60+$sec; #+1900y +12h
		
 	return 1;	
}

sub somames { #soma X meses a partir da data dada
	my ($self,$date,$meses) = @_;
	return $self->{'date'}{'somames'} unless $_[0];	

	my $dias = $self->round($self->mod($meses,1) * 30,0); #quantidade de resto dos meses em dias
	$meses = int($meses); #quantidade de meses inteiros

	my @ymd = $$date->as_ymd;
	until ($meses <= 12) { #soma anos
		$meses -= 12;
		$ymd[0]++;
	}
	until ($meses >= 0) { #subtrai anos
		$meses += 12;
		$ymd[0]--;
	}	
	$ymd[0]++ if $ymd[1]+$meses > 12;
	$ymd[1] = $ymd[1]+$meses > 12 ? $ymd[1]+$meses-12 : $ymd[1]+$meses;

	$self->{'date'}{'somames'} = $self->diames(@ymd) + $dias; #Ajuste de borda

	return $self->{'date'}{'somames'};
}

sub diames { #retorna ultimo dia do mes ou o dia atual
	my ($self,@ymd) = @_;

	my $maxdias = $self->days_in_month($ymd[0], $ymd[1]);

	return ($ymd[2] > $maxdias)
		? $self->date($ymd[0],$ymd[1],$maxdias)
		: $self->date(@ymd);
}

sub diaproximo { #próximo dia X a partir da data dada
	my ($self,$dd,$date) = @_;
	return $self->{'date'}{'diaproximo'} unless $_[0];	
	
	if ($dd < 1 || $dd > 31) {#vencimento usuário inválido
		$self->{'date'}{'diaproximo'} = $$date;
		return $self->{'date'}{'diaproximo'};
	}

	my @ymd = $$date->as_ymd;
	my $dif = $self->diames($ymd[0],$ymd[1],$dd) - $$date;

	#    tolera até 15 dias de variação para + ou para -
	#31/09 15/09     1/10       15/10    31/10
	#   ++         0         0        --              
	#--------|---------|---------|------- 
	#/\/\/\-15         0        15/\/\/\/
	#ex: extremo: atual=01/10/2007 data=31/10/2007 dif-(30) muda para 30/09/2007
	# limites: atual=16/10/2007 data=31/10/2007 dif=(-16) fica em 31/10/2007 (o inverso é o limite positivo)
	# entre |30| dias usar o mesmo mes    
	if ($dif > 15) {
		$ymd[0]-- if $$date->month == 1;
		$ymd[1]--;
		$ymd[1] = 12 if $ymd[1] == 0;
	} elsif ($dif < -15) {
		$ymd[0]++ if $$date->month == 12;
		$ymd[1]++;
		$ymd[1] -= 12 if $ymd[1] > 12;
	}
	
	$self->{'date'}{'diaproximo'} = $self->diames($ymd[0],$ymd[1],$dd); #ajuste de borda

	return $self->{'date'}{'diaproximo'};
}

sub date {
	shift;
	return Date::Simple->new(@_);
}

sub today {
	return Date::Simple->new;
}

sub day {
	return Date::Simple->new->day;
}

sub dayname {
	my ($self) = shift;
	my @days = ('Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday');
	@days = @{$self->{lang}{date_days}} if $self->{lang}{date_days};
	
	return $_[0] >= 0 && $_[0] <= 6 ? $days[$_[0]] : ! $self->set_error($self->lang(3,'dayname'));
}

sub month {
	return Date::Simple->new->month;
}

sub monthname {
	my ($self) = shift;
	my @months = ('January','February','March','April','May','June','July','August','September','October','November','December'); 
	@months = @{$self->{lang}{date_months}} if $self->{lang}{date_months};
	
	return $_[0] >= 0 && $_[0] <= 11 ? $months[$_[0]] : ! $self->set_error($self->lang(3,'monthname'));	
}

sub year {
	return Date::Simple->new->year;
}

sub days_in_month {
	shift;
	return Date::Simple::days_in_month($_[0],$_[1]);
}

*julianday = \&doy; 
sub doy {
	return $_[0]->today - $_[0]->date($_[0]->year.'-01-01') + 1;
}

sub timenow {
	my $self = shift;
	$self->get_time;
	return split(":",$self->{'date'}{'time24'}); #Hour, Min, Sec 
}

sub timenow_local {
	my $self = shift;
	$self->get_time($self->offset);
	return split(":",$self->{'date'}{'time24'}); #Hour, Min, Sec 
}

sub dateformat {
	my ($self) = shift; #only handle date
	return undef unless $_[0];
	#Usage: dateformat('2008-01-02','yyyy-mm-dd','dd/mm/yyyy');
	#Usage: dateformat('2008-01-02');	
	my $finput = lc $_[1] || 'yyyy-mm-dd'; #Mysql
	my $foutput = lc $_[2] || lc $self->setting('dataformat');

	my @original_date = split /\D+?/, $_[0];
	my @original_format = split /[^ymd]/, $finput;
	my %dt; 
	@dt{@original_format} = @original_date;
	
	my $output = $foutput;
	$output =~ s/(([ymd])\2*)/$dt{$1}/g;
	
	return undef if $output !~ m/\d/;
	return $output;
}

sub datefromformat {
	my ($self) = shift;
	return undef unless $_[0];
	#Usage: datefromformat('01/02/2008','dd/mm/yyyy');
	my $finput = lc $_[1] || lc $self->setting('dataformat');
	
	my @original_date = split /\D+?/, $_[0];
	my @original_format = split /[^ymd]/, $finput;
	my %dt;
	@dt{@original_format} = @original_date;

	return $self->date($dt{'yyyy'}||$dt{'yy'},$dt{'mm'},$dt{'dd'});
} 
	
sub datefromISO8601 {
	my ($self) = shift;
	return undef unless $_[0];
	#ISO: dateformat('2008-10-30T12:51:06.0Z', 'YYYY-MM-DDThh:mm:ss.sTZD')
	#ISO: dateformat('1997-07-16T19:20:30.45+01:00', 'YYYY-MM-DDThh:mm:ss.sTZD')
	#More formats http://search.cpan.org/~jhoblitt/DateTime-Format-ISO8601/lib/DateTime/Format/ISO8601.pod#Supported_via_parse_datetime
	
	use DateTime::Format::ISO8601;
	my $dt = DateTime::Format::ISO8601->parse_datetime($_[0]);
	$dt->set_time_zone($self->setting('timeZone'));
	return $self->date($dt->year,$dt->month,$dt->day);
}

sub feriado {
	my ($self) = shift;	
	my ($a,$m,$d) = @_;
	$m = $self->month unless $m;
	$d = $self->day unless $d;
	  
	return defined $self->{'feriados'}{$m}{$d} ? 1 : undef;
}

sub date_diff {
	my ($self) = shift;	
	my ($end,$from,$return) = @_;

	my $diff;
	if ($return eq 'Y') {
		$diff = $end->year - $from->year;
		$diff-- if ($diff > 0 && $end->month - $from->month < 0);
		$diff++ if ($diff < 0 && $end->month - $from->month > 0);
	} else {
		$diff = $end - $from;
	}
	
	return $diff;
}

sub subtract_period { #Years
	my ($self) = shift;
	my $date = shift;
	my %opt = @_;
	
	if ($opt{years} > 0) {
		my $nyear = $date->year - $opt{years};
		my $lastDay = $self->days_in_month($nyear,$date->month());
		return $self->date($nyear, $date->month(), 
				$date->day() > $lastDay ? $lastDay : $date->day()
			 );		
	}
	die 'uniplemented period';
}
1;
__END__
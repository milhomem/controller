######################################################################
package SQL::ParserController;
######################################################################
#
# This module is copyright (c), 2001,2005 by Jeff Zucker.
# All rights resered.
#
# It may be freely distributed under the same terms as Perl itself.
# See below for help and copyright information (search for SYNOPSIS).
#
# 2008 Improved by is4web systems :: Controller
# 2012 Fixed Bug by is4web systems :: Controller 
######################################################################

use base SQL::Parser; #qw( SQL::Parser ); #Add Controller
use strict;
use warnings;
use vars qw($VERSION);
use constant FUNCTION_NAMES => join( '|', qw(TRIM SUBSTRING) );
use Carp qw(carp croak);
use Data::Dumper;
use Params::Util qw(_ARRAY0 _ARRAY _HASH);
use Scalar::Util qw(looks_like_number);

$VERSION = '1.1';

BEGIN
{
    if ( $ENV{SQL_USER_DEFS} ) { require SQL::UserDefs; }
}

#############################
# PUBLIC METHODS
#############################

sub new
{
    my $class = shift;
    my $dialect = shift || 'ANSI';
    $dialect = 'ANSI' if ( uc $dialect eq 'ANSI' );
    $dialect = 'AnyData' if ( ( uc $dialect eq 'ANYDATA' ) or ( uc $dialect eq 'CSV' ) );
    $dialect = 'AnyData' if ( $dialect eq 'SQL::Eval' );
    $dialect = 'MySQL'  if uc $dialect eq 'MYSQL'; #Add Controller

    my $flags = shift || {};
    $flags->{dialect} = $dialect;
    $flags->{PrintError} = 1 unless ( defined( $flags->{PrintError} ) );

    my $self = bless( $flags, $class );
    $self->dialect( $self->{dialect} );
    $self->set_feature_flags( $self->{select}, $self->{create} );

    $self->LOAD('LOAD SQL::Statement::Functions');

    return $self;
}

sub do_err {
    my $self = shift;
	
	$self->SUPER::do_err(@_);
    
    return undef;
}

sub clean_sql {
    my ( $self, $sql ) = @_;
    my $fields;
    my $i = -1;
    my $e = '\\';
    $e = quotemeta($e);

	#
	# patch from Controller for matain case of where_cols hash
	#
	use Hash::Case::Upper;
 	tie %{$self->{"struct"}{"where_cols"}}, 'Hash::Case::Upper';
 	    
    #
    # patch from cpan@goess.org, adds support for col2=''
    #
    # $sql =~ s~'(([^'$e]|$e.|'')+)'~push(@$fields,$1);$i++;"?$i?"~ge;
    # $sql =~ s~(?<!')'(([^'$e]|$e.|'')+)'~push(@$fields,$1);$i++;"?$i?"~ge; #BUG Segment Fault
    #
    # patch replacement from suporte@is4web.com, avoid segment fault 
    $sql =~ s/$e'/?escape?/gs;
    $sql =~ s~(?<!')'(([^'$e])*?)'~push(@$fields,$1);$i++;"?$i?"~ge;
    @$fields = map { s/\?escape\?/"$e'"/ge; $_ } @$fields; #Remap $e'  

    #
    foreach (@$fields) { $_ =~ s/''/\\'/g; }
	my @a = $sql =~ m/((?<!\\)(?:(?:\\\\)*)')/g;
    if ( ( scalar(@a) % 2 ) == 1 )    
    {
        $sql =~ s/^.*\?(.+)$/$1/;
        $self->do_err("Mismatched single quote before: <$sql>");
    }
    if ( $sql =~ m/\?\?(\d)\?/ )
    {
        $sql = $fields->[$1];
        $self->do_err("Mismatched single quote: <$sql>");
    }
    foreach (@$fields) { $_ =~ s/$e'/'/g; s/^'(.*)'$/$1/; }

    #
    # From Steffen G. to correctly return newlines from $dbh->quote;
    #
    foreach (@$fields) { $_ =~ s/([^\\])\\r/$1\r/g; }
    foreach (@$fields) { $_ =~ s/([^\\])\\n/$1\n/g; }

    $self->{struct}->{literals} = $fields;

    my $qids;
    $i = -1;
    $e = q/""/;

    #    $sql =~ s~"(([^"$e]|$e.)+)"~push(@$qids,$1);$i++;"?QI$i?"~ge;
    $sql =~ s/"(([^"]|"")+)"/push(@$qids,$1);$i++;"?QI$i?"/ge;

    #@$qids = map { s/$e'/'/g; s/^'(.*)'$/$1/; $_} @$qids;
    $self->{struct}->{quoted_ids} = $qids if ($qids);

    #    $sql =~ s~'(([^'\\]|\\.)+)'~push(@$fields,$1);$i++;"?$i?"~ge;
    #    @$fields = map { s/\\'/'/g; s/^'(.*)'$/$1/; $_} @$fields;
    #print "$sql [@$fields]\n";# if $sql =~ /SELECT/;

## before line 1511
    my $comment_re = $self->{comment_re};

    #    if ( $sql =~ s/($comment_re)//gs) {
    #       $self->{comment} = $1;
    #    }
    if ( $sql =~ m/(.*)$comment_re$/s )
    {
        $sql = $1;
        $self->{comment} = $2;
    }
    if ( $sql =~ m/^(.*)--(.*)(\n|$)/ )
    {
        $sql = $1;
        $self->{comment} = $2;
    }

    $sql =~ s/\n/ /g;
    $sql =~ s/\s+/ /g;
    $sql =~ s/(\S)\(/$1 (/g;                     # ensure whitespace before (
    $sql =~ s/\)(\S)/) $1/g;                     # ensure whitespace after )
    $sql =~ s/\(\s*/(/g;                         # trim whitespace after (
    $sql =~ s/\s*\)/)/g;                         # trim whitespace before )
                                                 #
                                                 # $sql =~ s/\s*\(/(/g;   # trim whitespace before (
                                                 # $sql =~ s/\)\s*/)/g;   # trim whitespace after )
                                                 #    for my $op (qw(= <> < > <= >= \|\|))
                                                 #    {
                                                 #        $sql =~ s/(\S)$op/$1 $op/g;
                                                 #        $sql =~ s/$op(\S)/$op $1/g;
                                                 #    }
    $sql =~ s/(\S)(=|<>|<|>|<=|>=|\|\|)/$1 $2/g;
    $sql =~ s/(=|<>|<|>|<=|>=|\|\|)(\S)/$1 $2/g;
    $sql =~ s/< >/<>/g;
    $sql =~ s/< =/<=/g;
    $sql =~ s/> =/>=/g;
    $sql =~ s/\s*,/,/g;
    $sql =~ s/,\s*/,/g;
    $sql =~ s/^\s+//;
    $sql =~ s/\s+$//;

    return $sql;
}

sub IDENTIFIER {
    my ( $self, $id ) = @_;
    if ( $id =~ m/^\?QI(.+)\?$/ )
    {
        return 1;
    }
    if ( $id =~ m/^(.+)\.([^\.]+)$/ )
    {
        my $schema = $1;    # ignored
        $id = $2;
    }
    return 1 if $id =~ m/^".+?"$/s;    # QUOTED IDENTIFIER
    my $err = "Bad table or column name: '$id' ";    # BAD CHARS
    if ($id !~ /[\w_]/) { #MySQL permit underscore
#TODO ver implementacao disso no arquivo de mysql, ver se tem impacto com outros bancos    
        $err .= "has chars not alphanumeric or underscore!";
        return $self->do_err($err);
    }
    # CSV requires optional start with _
    my $badStartRx = uc( $self->{dialect} ) eq 'ANYDATA' ? qr/^\d/ : qr/^[_\d]/;
    if ( $id =~ $badStartRx )
    {                                                # BAD START
        $err .= "starts with non-alphabetic character!";
        return $self->do_err($err);
    }
    if ( length $id > 128 )
    {                                                # BAD LENGTH
        $err .= "contains more than 128 characters!";
        return $self->do_err($err);
    }
    $id = uc $id;
    if ( $self->{opts}->{reserved_words}->{$id} )
    {                                                # BAD RESERVED WORDS
        $err .= "is a SQL reserved word!";
        return $self->do_err($err);
    }
    return 1;
}

sub CALL {
    my $self = shift;
#    my $stmt = shift;
#    $stmt =~ s/^CALL\s+(.*)/$1/i;
#    $self->{struct}->{command}   = 'CALL';
#    $self->{struct}->{procedure} = $stmt;
#    return 1;
	return $self->do_err( 'No Command Found' );
}
#################################
1;

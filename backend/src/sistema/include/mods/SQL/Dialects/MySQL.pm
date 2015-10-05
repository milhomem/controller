package SQL::Dialects::MySQL;

sub get_config {
return <<EOC;
[VALID COMMANDS]
CREATE
DROP
SELECT
INSERT
UPDATE
DELETE
#REPLACE
#TRUNCATE

[VALID OPTIONS]
SELECT_MULTIPLE_TABLES
SELECT_AGGREGATE_FUNCTIONS

[VALID COMPARISON OPERATORS]
=
<>
<
<=
>
>= 
!=
<=>
LIKE
NOT LIKE
CLIKE 
NOT CLIKE
RLIKE
NOT RLIKE
IS
IS NOT
IS NOT NULL
IS NULL
REGEXP
NOT REGEXP

[VALID DATA TYPES]
CHAR
VARCHAR
REAL
INT
INTEGER
BLOB
TEXT
FLOAT

[FUNCTION NAMES]
IF
IFNULL
NULLIF
ASCII
BIN
BIT_LENGTH
CHAR_LENGTH
CHAR
CHARACTER_LENGTH
CONCAT_WS
CONCAT
ELT
EXPORT_SET
FIELD
FIND_IN_SET
FORMAT
HEX
INSERT
INSTR
LCASE
LEFT
LENGTH
LOAD_FILE
LOCATE
LOWER
LPAD
LTRIM
MAKE_SET
MATCH
MID
OCTET_LENGTH
ORD
POSITION
QUOTE
REPEAT
REPLACE
REVERSE
RIGHT
RPAD
RTRIM
SOUNDEX
SPACE
STRCMP
SUBSTR
SUBSTRING_INDEX
SUBSTRING
TRIM
UCASE
UNHEX
UPPER
ADDDATE
ADDTIME
CONVERT_TZ
CURDATE
CURRENT_DATE
CURRENT_TIME
CURRENT_TIMESTAMP
CURTIME
DATE_ADD
DATE_FORMAT
DATE_SUB
DATE
DATEDIFF
DAY
DAYNAME
DAYOFMONTH
DAYOFWEEK
DAYOFYEAR
EXTRACT
FROM_DAYS
FROM_UNIXTIME
GET_FORMAT
HOUR
LOCALTIME
LOCALTIMESTAMP
MAKEDATE
MAKETIME
MICROSECOND
MINUTE
MONTH
MONTHNAME
NOW
PERIOD_ADD
PERIOD_DIFF
QUARTER
SEC_TO_TIME
SECOND
STR_TO_DATE
SUBDATE
SUBTIME
SYSDATE
TIME_FORMAT
TIME_TO_SEC
TIME
TIMEDIFF
TIMESTAMP
TIMESTAMPADD
TIMESTAMPDIFF
TO_DAYS
UNIX_TIMESTAMP
UTC_DATE
UTC_TIME
UTC_TIMESTAMP
WEEK
WEEKDAY
WEEKOFYEAR
YEAR
YEARWEEK
ABS
ACOS
ASIN
ATAN2
ATAN
CEIL
CEILING
CONV
COS
COT
CRC32
DEGREES
EXP
FLOOR
LN
LOG10
LOG2
LOG
MOD
OCT
PI
POW
POWER
RADIANS
RAND
ROUND
SIGN
SIN
SQRT
TAN
TRUNCATE

[RESERVED WORDS NOT IN USE YET]
ACCESSIBLE
ADD
ALL
ALTER
ANALYZE
AND
AS
ASC
ASENSITIVE
BEFORE
BETWEEN
BIGINT
BINARY
BLOB
BOTH
BY
CALL
CASCADE
CASE
CHANGE
CHAR
CHARACTER
CHECK
COLLATE
COLUMN
CONDITION
CONSTRAINT
CONTINUE
CONVERT
CREATE
CROSS
CURRENT_DATE
CURRENT_TIME
CURRENT_TIMESTAMP
CURRENT_USER
CURSOR
DATABASE
DATABASES
DAY_HOUR
DAY_MICROSECOND
DAY_MINUTE
DAY_SECOND
DEC
DECIMAL
DECLARE
DEFAULT
DELAYED
DELETE
DESC
DESCRIBE
DETERMINISTIC
DISTINCT
DISTINCTROW
DIV
DOUBLE
DROP
DUAL
EACH
ELSE
ELSEIF
ENCLOSED
ESCAPED
EXISTS
EXIT
EXPLAIN
FALSE
FETCH
FLOAT
FLOAT4
FLOAT8
FOR
FORCE
FOREIGN
FROM
FULLTEXT
GRANT
GROUP
HAVING
HIGH_PRIORITY
HOUR_MICROSECOND
HOUR_MINUTE
HOUR_SECOND
IF
IGNORE
IN
INDEX
INFILE
INNER
INOUT
INSENSITIVE
INSERT
INT
INT1
INT2
INT3
INT4
INT8
INTEGER
INTERVAL
INTO
IS
ITERATE
JOIN
KEY
KEYS
KILL
LEADING
LEAVE
LEFT
LIKE
LIMIT
LINEAR
LINES
LOAD
LOCALTIME
LOCALTIMESTAMP
LOCK
LONG
LONGBLOB
LONGTEXT
LOOP
LOW_PRIORITY
MASTER_SSL_VERIFY_SERVER_CERT
MATCH
MEDIUMBLOB
MEDIUMINT
MEDIUMTEXT
MIDDLEINT
MINUTE_MICROSECOND
MINUTE_SECOND
MOD
MODIFIES
NATURAL
NOT
NO_WRITE_TO_BINLOG
NULL
NUMERIC
ON
OPTIMIZE
OPTION
OPTIONALLY
OR
ORDER
OUT
OUTER
OUTFILE
PRECISION
PRIMARY
PROCEDURE
PURGE
RANGE
READ
READS
READ_WRITE
REAL
REFERENCES
REGEXP
RELEASE
RENAME
REPEAT
REPLACE
REQUIRE
RESTRICT
RETURN
REVOKE
RIGHT
RLIKE
SCHEMA
SCHEMAS
SECOND_MICROSECOND
SELECT
SENSITIVE
SEPARATOR
SET
SHOW
SMALLINT
SPATIAL
SPECIFIC
SQL
SQLEXCEPTION
SQLSTATE
SQLWARNING
SQL_BIG_RESULT
SQL_CALC_FOUND_ROWS
SQL_SMALL_RESULT
SSL
STARTING
STRAIGHT_JOIN
TABLE
TERMINATED
THEN
TINYBLOB
TINYINT
TINYTEXT
TO
TRAILING
TRIGGER
TRUE
UNDO
UNION
UNIQUE
UNLOCK
UNSIGNED
UPDATE
USAGE
USE
USING
UTC_DATE
UTC_TIME
UTC_TIMESTAMP
VALUES
VARBINARY
VARCHAR
VARCHARACTER
VARYING
WHEN
WHERE
WHILE
WITH
WRITE
XOR
YEAR_MONTH
ZEROFILL
ACCESSIBLE
READ_ONLY
ABS 
ACOS 
ADDDATE 
ADDTIME 
AES_DECRYPT 
AES_ENCRYPT 
ASCII 
ASIN 
ATAN2
ATAN 
AVG 
BENCHMARK 
BIN 
BIT_AND 
BIT_COUNT 
BIT_LENGTH 
BIT_OR 
BIT_XOR 
CAST 
CEIL 
CEILING 
CHAR_LENGTH 
CHAR 
CHARACTER_LENGTH 
CHARSET 
COALESCE 
COERCIBILITY 
COLLATION 
COMPRESS 
CONCAT_WS 
CONCAT 
CONNECTION_ID 
CONV 
CONVERT_TZ 
Convert 
COS 
COT 
COUNT(DISTINCT)
COUNT 
CRC32 
CURDATE 
CURTIME 
DATABASE 
DATE_ADD 
DATE_FORMAT 
DATE_SUB 
DATE 
DATEDIFF 
DAY 
DAYNAME 
DAYOFMONTH 
DAYOFWEEK 
DAYOFYEAR 
DECODE 
DEFAULT 
DEGREES 
DES_DECRYPT 
DES_ENCRYPT 
ELT 
ENCODE 
ENCRYPT 
EXP 
EXPORT_SET 
EXTRACT 
FIELD 
FIND_IN_SET 
FLOOR 
FORMAT 
FOUND_ROWS 
FROM_DAYS 
FROM_UNIXTIME 
GET_FORMAT 
GET_LOCK 
GREATEST 
GROUP_CONCAT 
HEX 
HOUR 
IF 
IFNULL 
IN 
INET_ATON 
INET_NTOA 
INSERT 
INSTR 
INTERVAL 
IS_FREE_LOCK 
IS NOT NULL
IS NOT
IS NULL
IS_USED_LOCK 
ISNULL 
LAST_DAY
LAST_INSERT_ID 
LCASE 
LEAST 
LEFT 
LENGTH 
LN 
LOAD_FILE 
LOCALTIMESTAMP 
LOCATE 
LOG10 
LOG2 
LOG 
LOWER 
LPAD 
LTRIM 
MAKE_SET 
MAKEDATE 
MAKETIME
MASTER_POS_WAIT 
MAX 
MD5 
MICROSECOND 
MID 
MIN 
MINUTE 
MOD 
MONTH 
MONTHNAME 
NAME_CONST 
NOT IN 
NOT LIKE
NOT REGEXP
NOW 
NULLIF 
OCT 
OCTET_LENGTH 
OLD_PASSWORD 
ORD 
PASSWORD 
PERIOD_ADD 
PERIOD_DIFF 
PI
POSITION 
POW 
POWER 
PROCEDURE ANALYSE 
QUARTER 
QUOTE 
RADIANS 
RAND 
RELEASE_LOCK 
REPEAT 
REPLACE 
REVERSE
RIGHT 
ROUND 
ROW_COUNT 
RPAD 
RTRIM 
SCHEMA 
SEC_TO_TIME 
SECOND 
SESSION_USER 
SHA1
SHA 
SIGN 
SIN 
SLEEP 
SOUNDEX 
SOUNDS LIKE
SPACE 
SQRT 
STD 
STDDEV_POP 
STDDEV_SAMP 
STDDEV 
STR_TO_DATE 
STRCMP 
SUBDATE 
SUBSTR 
SUBSTRING_INDEX 
SUBSTRING 
SUBTIME 
SUM 
SYSDATE 
SYSTEM_USER 
TAN 
TIME_FORMAT 
TIME_TO_SEC 
TIME 
TIMEDIFF 
TIMESTAMP 
TIMESTAMPADD 
TIMESTAMPDIFF 
TO_DAYS 
TRIM 
TRUNCATE 
UCASE 
UNCOMPRESS 
UNCOMPRESSED_LENGTH 
UNHEX 
UNIX_TIMESTAMP 
UPPER 
USER 
UTC_DATE 
UTC_TIME 
UTC_TIMESTAMP 
UUID 
VALUES 
VAR_POP 
VAR_SAMP 
VARIANCE 
VERSION 
WEEK 
WEEKDAY 
WEEKOFYEAR 
YEAR 
YEARWEEK 
EOC
}

# SQL Parser #
sub SQL::Parser::REPLACE { 
    my($self,$str) = @_;
    $self->{"struct"}->{"command"} = 'REPLACE';    
    my ($col_str,$table_name,$remainder,$val_str);
    $str =~ s/^REPLACE.+?INTO\s+/REPLACE /i; # allow INTO to be optional
	$str =~ s/^REPLACE\s+(?:LOW_PRIORITY|DELAYED)\s+/REPLACE /i; #discard options
	if ($str =~ s/(.*?) SELECT (.*)$/$1/i) {
		#return undef unless $self->SELECT($2); #precisa conectar pra saber os valores
		return $self->do_err('REPLACE clause with select not implemented yet');
	}
    	     
    if ($str and $str =~ m/\s+?SET\s+?/i) {	     
		($table_name,$remainder) = $str =~
		        /^REPLACE (.+?) SET (.+)$/i;
	    return $self->do_err('Incomplete REPLACE clause') if !$table_name or !$remainder;
	    return undef unless $self->TABLE_NAME($table_name);
	    $self->{"tmp"}->{"is_table_name"}  = {$table_name => 1};
	    $self->{"struct"}->{"table_names"} = [$table_name];
	    my($set_clause,$where_clause) = $remainder =~
	        /(.*?) WHERE (.*)$/i;
	    $set_clause = $remainder if !$set_clause;
	    return undef unless $self->SET_CLAUSE_LIST($set_clause);
	    if ($where_clause) {
	        return undef unless $self->SEARCH_CONDITION($where_clause);
	    }
	    my @vals                 = @{ $self->{struct}->{values}->[0] };
	    my $num_val_placeholders=0;
	    for my $v(@vals) {
	       $num_val_placeholders++ if $v->{"type"} eq 'placeholder';
	    }
	    $self->{"struct"}->{"num_val_placeholders"}=$num_val_placeholders;
	    return 1;    
    } else {
    	($table_name,$val_str) = $str =~
	        /^REPLACE\s+(.+?)\s+(?:VALUES|VALUE)\s+\((.+?)\)$/i;
	    if ($table_name and $table_name =~ /[()]/ ) {	
    		($table_name,$col_str,$val_str) = $str =~	
        	/^REPLACE\s+(.+?)\s+\((.+?)\)\s+(?:VALUES|VALUE)\s+\((.+?)\)$/i;
	    }    
    }
   	return $self->do_err('Missing values list!') unless defined $val_str;    
    return $self->do_err('No table name specified!') unless $table_name;
    return undef unless $self->TABLE_NAME($table_name);
    $self->{"struct"}->{"table_names"} = [$table_name];
    if ($col_str) {
        return undef unless $self->COLUMN_NAME_LIST($col_str);
    } else {
		$self->{"struct"}->{"column_names"} = ['*'];
    }
    return undef unless $self->LITERAL_LIST($val_str);
    return 1;
}

sub SQL::Parser::INSERT {
    my($self,$str) = @_;
    my ($col_str,$table_name,$remainder,$val_str);    
    $str =~ s/^INSERT\s+INTO\s+/INSERT /i; # allow INTO to be optional
	$str =~ s/^INSERT\s+(?:LOW_PRIORITY|DELAYED|HIGH_PRIORITY)\s+/INSERT /i; #discard options
	$str =~ s/^INSERT\s+IGNORE\s+/INSERT /i;
	$str =~ s/ ON DUPLICATE KEY UPDATE.*$//i; #discard duplicated keys, not implemented yet
	
	if ($str =~ s/(.*?) SELECT (.*)$/$1/i) {
		#return undef unless $self->SELECT($2); #precisa conectar pra saber os valores
		return $self->do_err('INSERT clause with select not implemented yet');
	}
    if ($str and $str =~ m/\s+?SET\s+?/i) {	     
		($table_name,$remainder) = $str =~
		        /^INSERT (.+?) SET (.+)$/i;
	    return $self->do_err('Incomplete INSERT clause') if !$table_name or !$remainder;
	    return undef unless $self->TABLE_NAME($table_name);
	    $self->{"tmp"}->{"is_table_name"}  = {$table_name => 1};
	    $self->{"struct"}->{"table_names"} = [$table_name];
	    my($set_clause,$where_clause) = $remainder =~
	        /(.*?) WHERE (.*)$/i;
	    $set_clause = $remainder if !$set_clause;
	    return undef unless $self->SET_CLAUSE_LIST($set_clause);
	    if ($where_clause) {
	        return undef unless $self->SEARCH_CONDITION($where_clause);
	    }
	    my @vals                 = @{ $self->{struct}->{values}->[0] };
	    my $num_val_placeholders=0;
	    for my $v(@vals) {
	       $num_val_placeholders++ if $v->{"type"} eq 'placeholder';
	    }
	    $self->{"struct"}->{"num_val_placeholders"}=$num_val_placeholders;
	    return 1;    
    } else {
    	($table_name,$val_str) = $str =~ /^INSERT\s+(.+?)\s+(?:VALUES|VALUE)\s+(\(.+?\))$/i;
	    if ($table_name and $table_name =~ /[()]/ ) {	
   		 ( $table_name, $col_str, $val_str ) =
          $str =~ m/^INSERT\s+(.+?)\s+\((.+?)\)\s+(?:VALUES|VALUE)\s+(\(.+?\))$/i;

	    }
    }
    return $self->do_err('No table name specified!') unless ($table_name);
    return $self->do_err('Missing values list!')     unless ( defined $val_str );
    return undef                                     unless ( $self->TABLE_NAME($table_name) );
    $self->{struct}->{command}     = 'INSERT';
    $self->{struct}->{table_names} = [$table_name];
    if ($col_str)
    {
        return undef unless ( $self->{struct}->{column_names} = $self->ROW_VALUE_LIST($col_str) );
    }
    else
    {
        $self->{struct}->{column_names} = [
                                           {
                                             type  => 'column',
                                             value => '*'
                                           }
                                         ];
    }
    $self->{struct}->{values} = [];
    while ( $val_str =~ m/\((.+?)\)(?:,|$)/g )
    {
        my $line_str = $1;
        return undef unless ( $self->LITERAL_LIST($line_str) );
    }
    return 1;
}

sub SQL::Parser::UPDATE {
    my($self,$str) = @_;
    $self->{"struct"}->{"command"} = 'UPDATE';
   
	$str =~ s/^UPDATE\s+LOW_PRIORITY\s+/UPDATE /i; #discard options
	$str =~ s/^UPDATE\s+IGNORE\s+/UPDATE /i;
    my ( $table_name, $remainder ) = $str =~ m/^UPDATE (.+?) SET (.+)$/i;
    return $self->do_err('Incomplete UPDATE clause') unless ( $table_name && $remainder );
    return undef unless $self->TABLE_NAME_LIST($table_name);	
#    $self->{"tmp"}->{"is_table_name"}  = {$table_name => 1};
#    $self->{"struct"}->{"table_names"} = [$table_name];
	my($order_clause,$limit_clause);
	if ($self->{"struct"}->{"multiple_tables"} != 1) {
  		if ( $str =~ s/^(.+) LIMIT (.+)$/$1/i    ) { $limit_clause = $2; }
    	if ( $str =~ s/^(.+) ORDER BY (.+)$/$1/i ) { $order_clause = $2; }
		if ($order_clause) {
#			$order_clause =~ s/`?([^\` ]+)`?(,?)/$1$2/g; #####Alterado Controller
			return undef unless $self->SORT_SPEC_LIST($order_clause);
		}
		if ($limit_clause) {
			return undef unless $self->LIMIT_CLAUSE($limit_clause);
		}
	}
    my ( $set_clause, $where_clause ) = $remainder =~ m/(.*?) WHERE (.*)$/i;
    $set_clause = $remainder if !$set_clause;
    return undef unless ( $self->SET_CLAUSE_LIST($set_clause) );

    if ($where_clause)
    {
        return undef unless ( $self->SEARCH_CONDITION($where_clause) );
    }
    
	my @vals                 = @{ $self->{struct}->{values}->[0] };
    my $num_val_placeholders = 0;
    for my $v (@vals)
    {
        ++$num_val_placeholders if ( $v->{type} eq 'placeholder' );
    }
    $self->{struct}->{num_val_placeholders} = $num_val_placeholders;

    return 1;
}

sub SQL::Parser::DELETE {
    my($self,$str) = @_;
    $self->{struct}->{command} = 'DELETE';
    $str =~ s/^DELETE\s+FROM\s+/DELETE /i;    # Make FROM optional
	$str =~ s/^DELETE\s+LOW_PRIORITY\s+/DELETE /i; #discard options
	$str =~ s/^DELETE\s+QUICK\s+/DELETE /i;
	$str =~ s/^DELETE\s+IGNORE\s+/DELETE /i;
	my($order_clause,$limit_clause,$where_clause);
  	if ( $str =~ s/^(.+) LIMIT (.+)$/$1/i    ) { $limit_clause = $2; }
    if ( $str =~ s/^(.+) ORDER BY (.+)$/$1/i ) { $order_clause = $2; }
    my ( $table_name, $where_clause ) = $str =~ /^DELETE (\S+)(.*)$/i;
    return $self->do_err('Incomplete DELETE statement!') if !$table_name;
    return undef unless $self->TABLE_NAME_LIST($table_name);

	if ($self->{"struct"}->{"multiple_tables"} != 1) {    	
		if ($order_clause) {
			return undef unless $self->SORT_SPEC_LIST($order_clause);
		}
		if ($limit_clause) {
			return undef unless $self->LIMIT_CLAUSE($limit_clause);
		}		
	}    
#    $self->{"tmp"}->{"is_table_name"}  = {$table_name => 1};
#    $self->{"struct"}->{"table_names"} = [$table_name];
    $self->{struct}->{column_names} = [
                                       {
                                         type  => 'column',
                                         value => '*'
                                       }
                                     ];
    $where_clause =~ s/^\s+//;
    $where_clause =~ s/\s+$//;
    
    if ($where_clause)
    {
        $where_clause =~ s/^WHERE\s*(.*)$/$1/i;
        return undef unless $self->SEARCH_CONDITION($where_clause);
    }
    return 1;
}


1;
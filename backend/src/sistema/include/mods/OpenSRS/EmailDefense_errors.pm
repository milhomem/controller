#!/usr/bin/perl
                                                                                                           
package OpenSRS::EmailDefense_errors;

use strict;
use Exporter;
use vars  qw( @ISA @EXPORT );

@ISA = qw(Exporter);

@EXPORT = (	'ERROR_M001', 
		'ERROR_M002',
		'ERROR_M003',
		'ERROR_M004',
		'ERROR_M005',
		'ERROR_M006',
		'ERROR_M007',
		'ERROR_M008',
		'ERROR_M110',
		'ERROR_M120',
		'ERROR_M140',
		'ERROR_M150',
		'ERROR_M100',
		'ERROR_M170',
		'ERROR_M200',
		'ERROR_M210',
	  );


use constant ERROR_M001 => 'Empty domain name.';
use constant ERROR_M002 => 'Empty username.';
use constant ERROR_M003 => 'Empty password.';
use constant ERROR_M004 => 'User does not own queried domain.';
use constant ERROR_M005 => 'Empty confirm password.';
use constant ERROR_M006 => 'Passwords must be a minimum of 6 characters.';
use constant ERROR_M007 => 'Empty users.';
use constant ERROR_M008 => 'Duplicate users.';
use constant ERROR_M110 => 'Email Defense Service for this domain cannot be purchased or managed through this interface.  Please contact your current provider for assistance.';
use constant ERROR_M100 => 'Error retrieving information.';
use constant ERROR_M140 => 'Passwords do not match.';
use constant ERROR_M150 => 'Username is already taken.  Please enter another username.';
use constant ERROR_M170 => 'User does not exist.';
use constant ERROR_M200 => 'Username and/or password not found.';
use constant ERROR_M210 => 'The maximum number of Email Defense Users you can enter is ';

1;

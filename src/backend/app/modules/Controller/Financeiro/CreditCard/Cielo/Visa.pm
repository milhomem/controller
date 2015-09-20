#!/usr/bin/perl         
# Use: Module
# Controller - is4web.com.br
# 2014
#Pacote personalizado
package Controller::Financeiro::CreditCard::Cielo::Visa;

require 5.008;
require Exporter;

use base Controller::Financeiro::CreditCard::Cielo;

sub brandlogo {
    return 'visa.png';
}

sub brandname {
    return 'Visa';
}

1;
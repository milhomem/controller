#!/usr/bin/perl         
# Use: Module
# Controller - is4web.com.br
# 2014
#Pacote personalizado
package Controller::Financeiro::CreditCard::Cielo::Amex;

require 5.008;
require Exporter;

use base Controller::Financeiro::CreditCard::Cielo;

sub brandlogo {
    return 'amex.png';
}

sub brandname {
    return 'Amex';
}

1;
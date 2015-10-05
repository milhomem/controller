#!/usr/bin/perl         
# Use: Module
# Controller - is4web.com.br
# 2014
#Pacote personalizado
package Controller::Financeiro::CreditCard::Cielo::Mastercard;

require 5.008;
require Exporter;

use base Controller::Financeiro::CreditCard::Cielo;

sub brandlogo {
    return 'master.jpg';
}

sub brandname {
    return 'Mastercard';
}

1;
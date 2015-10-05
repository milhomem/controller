{
    #Overwrite for test
    local *Controller::SQL::execute_sql = sub {
    	my ($self,$statement,@var) = @_; 
     
    	$self->{_statement} = $statement =~ m/^\d+$/ ? $self->{queries}{$statement} : $statement;
    	@{ $self->{_binds} } = @var;

    	return $self->sql_parse;
    };

    # t/1
    ok ( $system->execute_sql(
    qq|UPDATE `documentacao` SET `nome` = ?, `value` = ? WHERE ID = ? AND `sid` = ?|,
    ,"a","b",'c"a','\a\\\\'), 't/1' ) and diag($system->parsedump);
    is( $system->{'sql'}{where_cols}{ID}[0], 'c"a', 't/1-1');
    is( $system->{'sql'}{where_cols}{SID}[0], '\a\\\\', 't/1-2' );
    is( $system->{'sql'}{set}{NOME}, 'a', 't/1-3' );
    is( lc $system->{'sql'}{'table_names'}[0], 'documentacao', 't/1-4');
    #t/2
    ok ( $system->execute_sql(
    qq|INSERT INTO  tabela2 (`id`,`sid`,`nome`,`value`) VALUES (NULL,?,?,?)|,
    ,"b",'c"a','d\A'), 't/2' ) and diag($system->parsedump);
    is( $system->{'sql'}{set}{NOME}, 'c"a', 't/2-1');
    is( $system->{'sql'}{set}{VALUE}, 'd\A', 't/2-2' );
    is( $system->{'sql'}{set}{ID}, 'NULL', 't/2-3' );
    is( lc $system->{'sql'}{'table_names'}[0], 'tabela2', 't/2-4');
    #t/5
    ok ( $system->execute_sql(
    qq|INSERT INTO saldos VALUES (NULL, 1019, -99.9166666666667, 'Débito por atraso', '31', 1234)|
    ), 't/5' ) and diag($system->parsedump);
    is( $system->{'sql'}{set}{ID}, 'NULL', 't/5-1');
    is( $system->{'sql'}{set}{USERNAME}, '1019', 't/5-2');
    is( $system->{'sql'}{set}{VALOR}, '-99.9166666666667', 't/5-3');
    is( $system->{'sql'}{set}{DESCRICAO}, 'Débito por atraso', 't/5-4');
    is( $system->{'sql'}{set}{SERVICOS}, '31', 't/5-5');
    is( $system->{'sql'}{set}{INVOICE}, '1234', 't/5-6');
    is( lc $system->{'sql'}{'table_names'}[0], 'saldos', 't/5-7');
    ok ( $system->execute_sql(
    qq|UPDATE `servicos_set` SET `?` = '123' WHERE `servico` = 123|, 'MultiWEB'),
    't/6'
    ) or diag($system->parsedump);
    ok ( $system->execute_sql(344,'A','12478','max@domain.tld','1','19633','1','Pagamento','Ola ? qm diria q ? fazia mal com foreach hein','2008-11-10 00:32:53',undef,undef,'hd','1226284373','1226284373','1','0','0','0'),
    't/9'
    ) or diag($system->parsedump);
    ok ( $system->execute_sql(
    qq|delete from saldos where id =7251 AND username = 8699 AND servicos =44161|
    ), 't/10' ) and diag($system->parsedump);
    is( $system->{'sql'}{where_cols}{ID}[0], '7251', 't/10-1');
    is( $system->{'sql'}{where_cols}{USERNAME}[0], '8699', 't/10-2');
    is( $system->{'sql'}{where_cols}{SERVICOS}[0], '44161', 't/10-3');
    is( lc $system->{'sql'}{'table_names'}[0], 'saldos', 't/1-4');

} #Finall do override, a partir daqui executa realmente

1;
use Controller::Notifier;
use Controller::Financeiro;

&grab_emails; #sempre receber emails com prioridade
#1 Criar as Faturas no banco de dados e mexer com os servicos
#2 Enviar os emails de avisos das faturas
#3 Modificar os servicos no banco de dados (Criar, Bloquear e etc)
#4 Criar e etc
#5 Receber emails
#LOG  log(action, table, value, user, debug);
#BUG problemas com a chave pela troca de data
print ("exit hour! h: $hour m: $min time: $time\n"), exit if int($hour) == 12 && int($min) <= 10 && $time !~ 'P.M.';

# Início
#users online
execute_sql(qq|DELETE FROM `online` WHERE `del` = 1|,"",1);
execute_sql(qq|UPDATE `online` SET `del` = 1|,"",1);

# Selecionando Execuções
my (@run,@usrs);
my $csth = select_sql(qq|SELECT `id`,`tipo` FROM `cron` WHERE `tipo` != 5|);
while(my $cef = $csth->fetchrow_hashref()) {
    push(@run,$cef->{'id'}.'-'.$cef->{'tipo'});
}
#Selecionando usuarios para cobrança
execute_sql(qq|INSERT INTO `cron_lock` (`id`,`data`,`hora`) 
SELECT username, '$timemysql', '$time24' FROM `users` LEFT JOIN `cron_lock` ON `users`.`username`=`cron_lock`.`id`
WHERE (`cron_lock`.`data` != '$timemysql' or `cron_lock`.`data` IS NULL)
ON DUPLICATE KEY UPDATE `data` =  '$timemysql', `hora` = '$time24'|);

#variaveis de ambiente;
local $auto_create = get_setting('auto_create');
local $auto_remove = $global{'auto_remove'};
local $auto_suspend = $global{'auto_suspend'};
local $auto_unsuspend = get_setting('auto_unsuspend');
local $auto_updown = get_setting('auto_updown');
local $starthour = (split(':',get_setting('startdaytime')))[0] - get_setting('timeoffset');

goto execucoes if $q->param('donow'); 
warn "1" if $DEBUG == 1;
#1 Início - Financeiro - Alterações no Banco
    $stun = qq|SELECT `username`,`vencimento`,`email` FROM `users` LEFT JOIN `cron_lock` ON `users`.`username`=`cron_lock`.`id` WHERE (`cron_lock`.`data` != "$timemysql" AND `cron_lock`.`hora` IS NULL) OR TIME_TO_SEC(TIMEDIFF('$timemysql $time24',CONCAT(`cron_lock`.`data`,' ',`cron_lock`.`hora`)))/60 > 15 OR `cron_lock`.`id` IS NULL|; #Isso já eliminas os nulls, que são a forma de falar que já foi processado
    my $nsth = select_sql($stun);
    while(my $uef = $nsth->fetchrow_hashref()) {
        my $has_inv = -1;
        if (grep { $_ eq $uef->{'username'}."-1" } @run){
            #do nothing
            next;
        } else {
            $system->soft_reset;
            die 'error cron step 1' if $system->error;
            #Lock
            $system->{cron}{type} = $Etipo = 1;
            $system->{cron}{id} = $Eid = $uef->{'username'};
            execute_sql(qq|INSERT INTO `cron` (`id`,`tipo`,`motivo`) VALUES ($uef->{'username'},"1","Locked")|,"",1);

            $finan = new Controller::Financeiro;
            $finan->uid($uef->{'username'});
            $has_inv = $finan->faturar;

            die 'error cron step 1' if $finan->error;
            #UnLock
            execute_sql(qq|DELETE FROM `cron` WHERE `id` = $uef->{'username'} AND `tipo` = 1|,"",1);
        }
        execute_sql(qq|REPLACE INTO `cron_lock` VALUES ($uef->{'username'},"$timemysql",NULL)|,"",1) if $has_inv == 0;      
    }
    $nsth->finish;

goto execucoes if int((split(':',$time24))[0]) < int($starthour);
warn "2" if $DEBUG == 1;
#2 Início - Financeiro - Execuções
    $stinus = 'SELECT `invoices`.*,`users`.`inscricao`,`users`.`name`,`users`.`username`,`users`.`vencimento`,`users`.`email`,`users`.`forma`,`users`.`alertinv` FROM `invoices` INNER JOIN `users` ON `invoices`.`username`=`users`.`username` WHERE `invoices`.`status` = "P"';# AND `invoices`.`envios` < 3';
    my $iusth = select_sql($stinus);
    while(my $iuef = $iusth->fetchrow_hashref()) {
        if (grep { $_ eq $iuef->{'id'}."-2" } @run){
            #do nothing
            next;
        } else {
            $system->soft_reset;
            #Lock
            $system->{cron}{type} = $Etipo = 2;
            $system->{cron}{id} = $Eid = $iuef->{'id'};
            execute_sql(qq|INSERT INTO `cron` (`id`,`tipo`,`motivo`) VALUES ($iuef->{'id'},"2","Locked")|,"",1);

            $template{'user'} = "";
            $template{'name'} = "";
            $template{'id'}   = "";
            $template{'venc'} = "";
            $template{'valor_fatura'} = "";
            $template{'referencia'} = "";
            $template{'name'} = $iuef->{'name'};
            $template{'id'}   = $iuef->{'id'};
            $template{'venc'} = FormatDate($iuef->{data_vencimento});
            $template{'referencia'} = $iuef->{'referencia'};
            $template{'referencia'} =~ s/\n/<br>/g;
            
            $system->clear_error;
            $system->invid($iuef->{'id'});
            $system->tid($system->invoice('tarifa'));
            $template{'user'} = $system->invoice('username');
            
            my $days = date($timemysql) - date($iuef->{data_vencimento}) if ($iuef->{data_vencimento} ne "0000-00-00");
            $days = 1 if ($iuef->{data_vencimento} eq "0000-00-00"); 
            my ($forma, $tplIndex, $modulo, $taxa, $autoquitar) = Tarifa($iuef->{'tarifa'});
            $template{'forma'} = $forma;
            $template{'taxa'} = CurrencyFormatted($taxa);
            $template{'valor_fatura'} = CurrencyFormatted($iuef->{valor});
            $template{'valor_total'} = CurrencyFormatted($iuef->{valor}+$taxa);
            my $mailtpl;
            
            die 'error cron step 2' if $system->error;          
                                    
            if ( ($days > 0 && $iuef->{'envios'} > 0 && int($hour) == 7)  #Passar varias vezes no cartao se vencido
                        || ($iuef->{'envios'} == 0) || ($days == -7 && $iuef->{'envios'} == 1) || ($iuef->{'envios'} < 3 && $days == 0)) {  
warn "Fatura: $Eid" if $DEBUG == 1;     
                #Boleto
                $template{'link'} = "";
                $template{'linhadigitavel'} = '';           
                if ($system->is_boleto_module($system->tax('modulo'))) {
                    eval "use ".$system->tax('modulo');
                    my $boleto = eval "new ".$system->tax('modulo'); #Deve continuar com os mesmos dados        
                    $boleto->boleto();
                    my $cryptkey = $system->encrypt($system->invoice('username').'/'.$system->user('inscricao').'/'.$system->invid);
                    $template{'link'} = $system->setting('baseurl').'/boleto.cgi?key='.Controller::URLEncode($cryptkey);#suportar links antigos     
                    $template{'linhadigitavel'} = $boleto->linhadigitavel;
                }                                       
                elsif ($modulo eq "boleto") {           
                        my $cryptkey = encrypt($iuef->{'username'}."/".$iuef->{'inscricao'}."/".$iuef->{'id'});
                        my $cod = URLEncode( $cryptkey );
                        $template{'link'} = qq|$global{'baseurl'}/boleto.cgi?key=$cod|;
                        my ($var_codigobarras) = boleto($iuef->{'id'},$iuef->{'conta'}); 
                        $template{'linhadigitavel'} = linhadigitavel($var_codigobarras);
                }
                elsif ($modulo eq "deposito") {
                    ($template{'agencia'},$template{'contacorrente'},$template{'favorecido'},$template{'codbanco'},$template{'banco'}) = split("---",ContaCorrente($iuef->{'conta'}, "agencia conta cedente banco nome"));           
                }
                #Tomar cuidado pois se não entrar nessa condicao ele vai enviar email
                elsif ($system->is_creditcard_module($system->tax('modulo'))) { # && $days >= 0 tava mandando email com texto trocado antes do vencimento sendo que so tem q mandar no vencimento #no vencimento, depois de vencido e pendente
                    if ($days < 0 || ($iuef->{'envios'} > 3 && ($days - $iuef->{'envios'} + 4) <= 0) || int($hour) != 7 ) {
                        #UnLock
                        execute_sql(qq|DELETE FROM `cron` WHERE `id` = $iuef->{'id'} AND `tipo` = 2|,"",1);
                        next;
                    }
                    #AUTOQUITAÇÃO
                    $system->logcron('system invid: '.$system->invid. ' username: '. $system->invoice('username') . ' taxid: ' .$system->invoice('tarifa') . ' module: ' . $system->tax('modulo'). ' auto: ' . $system->tax('autoquitar').' quitar '.$iuef->{'id'}.", ".$iuef->{'tarifa'}.", $tplIndex, $modulo, $taxa, $autoquitar, ". $iuef->{'forma'}), next if $autoquitar != 1;
                    my $err;
                    if ($system->invoice('nossonumero')) {
                        $err = Quitar($iuef->{'id'});#today
                        if ($err) {
                            $system->invoice('nossonumero',undef);
                            $err = Quitar($iuef->{'id'});#today
                        }   
                    } else {
                        $err = Quitar($iuef->{'id'});#today
                    }
                    
                    if ($err) {
                        $system->logcron($err);
                        execute_sql(qq|UPDATE `invoices` SET `envios` = ? WHERE `id` = $iuef->{'id'}|, $iuef->{'envios'} > 3 ? (4 + $days) : 4 );                       
                        next if $err eq 'Não existe cartão ativo' || $err eq 'Erro no sistema';
                        
                        my $from = Sender(UserFinan => $iuef->{'username'});
                        eval { 
                            email ( User => "$iuef->{'username'}", To => "$iuef->{'email'}", From => $from, Subject => ['sbj_cartao'], txt => "cron/${tplIndex}");      
                            sms ( User => "$iuef->{'username'}", Txt => "/cron/${tplIndex}");                   
                        };
                        $mailtpl = "/cron/${tplIndex}";                                         
                    }
                    #UnLock
                    execute_sql(qq|DELETE FROM `cron` WHERE `id` = $iuef->{'id'} AND `tipo` = 2|,"",1);                 
                    next;           
                }
                elsif ($system->is_financeiro_module($system->tax('modulo'))) {                 
                    eval "use ".$system->tax('modulo');
                    my $finan = eval "new ".$system->tax('modulo'); #Deve continuar com os mesmos dados     
                    unless ($finan->doBilling()) { #Gerar link para o email
                        $system->logcron($finan->clear_error || $system->lang(85,$system->tax('modulo')));
                        $finan->posBilling();                        
                        next;
                    }
                    $template{'link'} = $system->template('link');
                    #AUTOQUITAÇÃO
                    $system->logcron('system invid: '.$system->invid. ' username: '. $system->invoice('username') . ' taxid: ' .$system->invoice('tarifa') . ' module: ' . $system->tax('modulo'). ' auto: ' . $system->tax('autoquitar').' quitar '.$iuef->{'id'}.", ".$iuef->{'tarifa'}.", $tplIndex, $modulo, $taxa, $autoquitar, ". $iuef->{'forma'}), next if $system->tax('autoquitar') != 1;                 
                    if ($days >= 0 && $iuef->{'envios'} >= 3 && ($days - $iuef->{'envios'} + 4) > 0 && $min % 10 == 0 ) {
                        execute_sql(qq|UPDATE `invoices` SET `envios` = ? WHERE `id` = $iuef->{'id'}|, $iuef->{'envios'} > 3 ? (4 + $days) : 4 ) if $system->error;
                        $finan->pay_invoice();
                        $system->logcronRemove();
                        next;
                    }
                }
                                
                my $from = Sender(UserFinan => $iuef->{'username'});
                if (($iuef->{'envios'} == 0 && $days < 0) || ($days == -7 && $iuef->{'envios'} == 1)){
                    eval {
                        my $bcc = $iuef->{'alertinv'} && $iuef->{'envios'} == 0 ? "$global{'alertinv'}" : undef;
                        email ( User => "$iuef->{'username'}", To => "$iuef->{'email'}", From => $from, Subject => ['sbj_invoice',$iuef->{'nome'},$iuef->{'id'}], txt => "cron/${tplIndex}${extmail}");
                        email ( User => "$iuef->{'username'}", To => "$bcc", From => $from, Subject => ['sbj_invoice',$iuef->{'nome'},$iuef->{'id'}], txt => "cron/${tplIndex}${extmail}_bcc") if $bcc;
                        sms ( User => "$iuef->{'username'}", Txt => "/cron/${tplIndex}${extmail}");
                    };
                    $mailtpl = "/cron/${tplIndex}${extmail}";
                    execute_sql(qq|UPDATE `invoices` SET `envios` = ? WHERE `id` = $iuef->{'id'}|,$days == -7 ? 2 : 1);                 
                } elsif ($iuef->{'envios'} < 3 && $days == 0){ #o envios trava pra nao enviar mais vezes, mas o dia nao pode ser = 0 pq se nao pode nao enviar caso nao rode nesse dia exato, #Esse aviso é exclusivo para o dia de vencimento da fatura por isso == 0
                    eval { 
                        email ( User => "$iuef->{'username'}", To => "$iuef->{'email'}", From => $from, Subject => ['sbj_invoice',$iuef->{'nome'},$iuef->{'id'}], txt => "cron/${tplIndex}1${extmail}");        
                        sms ( User => "$iuef->{'username'}", Txt => "/cron/${tplIndex}1${extmail}");                    
                    };
                    $mailtpl = "/cron/${tplIndex}1${extmail}";
                    execute_sql(qq|UPDATE `invoices` SET `envios` = 3 WHERE `id` = $iuef->{'id'}|);
                } elsif ($iuef->{'envios'} < 3 && $days > 0) {
                    execute_sql(qq|UPDATE `invoices` SET `envios` = 3 WHERE `id` = $iuef->{'id'}|);
                }
            }
            
            {
                local $Controller::SWITCH{skip_error} = 1; 
                $system->Controller::Notifier::event({  name => 'alerts', 
                                        object => 'invoice',
                                        identifier => $system->invid,
                                        message => {
                                                    txt => $mailtpl 
                                                    }
                                        }); 
            }
            #UnLock
            execute_sql(qq|DELETE FROM `cron` WHERE `id` = $iuef->{'id'} AND `tipo` = 2|,"",1);
        }
    }
    $iusth->finish;

warn "3" if $DEBUG == 1;
#3 Início - Contas - Alterações no Banco
    $stsrplus = qq|SELECT `servicos`.*,`planos`.*,`users`.`username`,`users`.`name`,`users`.`email`,`users`.`inscricao` FROM (`servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos`) INNER JOIN `users` ON `servicos`.`username`=`users`.`username` WHERE (`servicos`.`status` != "S" AND `servicos`.`status` != "F") ORDER BY `servicos`.`vencimento`|;
    my $spusth = select_sql($stsrplus);
    my $du = today()->day_of_week;
    $du = 0 if $du == 1; #mudei para 1 pq sabado e domingo normal é 6 e 0, mas como roda 0h atrasei para 0 e 1
    $du = 0 if $du == 2; #tem q resolver logo isso pqp, terça-feira é o dia q recebe quitacao até sabado.
    $du = 0 if Feriado();
    while(my $spuef = $spusth->fetchrow_hashref()) {
        if (grep { $_ eq $spuef->{'id'}."-3" } @run){
            #do nothing
            next;
        } else {
            $system->soft_reset;            
            #Lock
            $system->{cron}{type} = $Etipo = 3;
            $system->{cron}{id} = $Eid = $spuef->{'id'};
            $system->sid($spuef->{'id'});
            $system->service('status'); 
            #Skip
            my $parc = $spuef->{'parcelas'};
            die "A quantidade de parcelas ($parc) do serviço ".$spuef->{'id'}." tem que ser maior ou igual a 1" unless $parc >= 1;
            my ($postec, $rep) = split(" - ",Pagamento($spuef->{'pg'},"parcelas repetir"));
            next if $parc && $rep != 1 && $spuef->{pagos} >= $parc; 
            
            die 'error cron step 3' if $system->error;
            my $defer = $spuef->{'def'};
            my $dias = date($timemysql) - date($spuef->{vencimento}) if ($spuef->{vencimento} ne "0000-00-00");
            my $pdias = date($timemysql) - date($spuef->{inicio}) if ($spuef->{inicio} ne "0000-00-00");
            $pdias -= Promo($spuef->{'id'},1);
            $pdias -= Promo($spuef->{'id'},5); #somente adicional ? Pq somente adicional? Se eu quiser uma hospedagem temporária?
            $pdias -= $spuef->{'envios'}; #enviar um aviso por dia          
            
            $dias -= $defer;
            $dias = 0 if ($spuef->{vencimento} eq "0000-00-00");
            $pdias -= $defer;
            $pdias = 0 if ($spuef->{inicio} eq "0000-00-00" || ($spuef->{pagos} >= 1 && ! Promo($spuef->{'id'},5)) || (! Promo($spuef->{'id'},1) && ! Promo($spuef->{'id'},5)) );#Previnindo que tenha promocao inicial se ja foi pago
            $dias = 0 if $pdias; #zera dias pra cair so nas condicoes de promocao inicial tipo 1
            $template{'name'} = "";
            $template{'id'}   = ""; 
            $template{'serv'} = "";
            $template{'dom'}  = "";
            $template{'servn'} = "";
            $template{'vto'} = "";
            $template{'processo'} = "";
            $template{'prazo'} = "";
            $space = "";
            $template{'name'} = $spuef->{'name'};
            $template{'id'}   = $spuef->{'invoice'};    
            $template{'serv'} = $spuef->{'tipo'}." ".$spuef->{'plataforma'}." ".$spuef->{'nome'};
            $template{'dom'}  = $spuef->{'dominio'};
            $template{'servn'}= $spuef->{'id'};
            $template{'vto'}  = FormatDate($spuef->{vencimento});
         my ($d1,$d2,$d3,$d4,$d5,$d6) = split(/-/,$global{"WarnReve"});
         my ($d7,$d8,$d9,$d10) = split(/-/,$global{"WarnHosp"});
         my ($d11,$d12,$d13,$d14) = split(/-/,$global{"WarnDedi"});
            #defaults
            $d1 ||= 3; $d2 ||= 5; $d3 ||= 8; $d4 ||= 10; $d5 ||= 15; $d6 ||= 17; #Revenda 
            $d7 ||= 3; $d8 ||= 5; $d9 ||=10; $d10 ||= 12;#Hospedagem e Adicional e outros
            $d11 ||= 10; $d12 ||= 12; $d13 ||=20; $d14 ||= 22; #dedicado
            my $dueday = $spuef->{'envios'}+$d1; #soma 3 pra chegar na primeira condicao de $d1 dias
            $dueday -= 5 + $d1 if $spuef->{'tipo'} eq "Registro"; #-$d1 de antes e -5 pra chegar na primeira condicao
            $dueday = $spuef->{'envios'}+$d7 if $spuef->{'tipo'} eq "Revenda";
            $dueday = $spuef->{'envios'}+$d11 if $spuef->{'tipo'} eq "Dedicado";
            my $soma = $spuef->{'envios'};
            my $sndmail = 0;
            my $did = 0;
            my $bcc; #copias de emails
            my $action;
            my ($file,$exec_day);
            if ($spuef->{'status'} ne "S" && $spuef->{'status'} ne "F"){
                if ($dueday <= $dias || $pdias >= $global{"promo_dias"}){
                    execute_sql(qq|INSERT INTO `cron` (`id`,`tipo`,`motivo`) VALUES ($spuef->{'id'},"3","Locked")|,"",1);
                    $soma -= $dueday - $dias unless $pdias;
                    if ($spuef->{'tipo'} eq "Revenda"){ 
                    #AVISOS
                        if ($dias >= $d1 && $dias <= $d2){
                            $template{'processo'} = "Bloqueio Parcial";
                            $template{'descricao'} = "bloqueio da conta principal";
                            $bcc = 1 if $global{'bcc_suspend'} && $dias == $d2;
                            $sndmail=1;
                            $action = 'P';
                        } elsif ($dias >= $d3 && $dias <= $d4){
                            $template{'processo'} = "Bloqueio";
                            $template{'descricao'} = "bloqueio de todas as contas";
                            $bcc = 1 if $global{'bcc_suspendf'} && $dias == $d4;
                            $sndmail=1;
                            $action = 'B';
                        } elsif ($dias >= $d5 && $dias <= $d6){
                            $template{'processo'} = "Remoção";
                            $template{'descricao'} = "exclusão dos arquivos";
                            $bcc = 1 if $global{'bcc_remove'} && $dias == $d6;
                            $sndmail=1;
                            $action = 'R';
                        }
            
                        if ($dias == ($d2-1) || $dias == ($d4-1) || $dias == ($d6-1)){
                            $space = " -";
                            $template{'prazo'} = "48 horas";
                        } elsif ($dias == ($d2) || $dias == ($d4) || $dias == ($d6)){
                            $space = " -";
                            $template{'prazo'} = "24 horas";
                        }   
                        $did = 1 if $template{'processo'};
                        $file = "process";
                        $file .= "do" if $dias == $d2 || $dias == $d4 || $dias == $d6;
                        $exec_day = 1 if $dias == $d2 || $dias == $d4 || $dias == $d6;          
                    #EXECUÇÕES
                        if ( $pdias && $pdias >= $global{"promo_dias"} && $pdias < $global{"promo_dias_r"} ) {
                            $action = substr($global{"promo_action"},0,1);
                            $action =~ s/[^NCMBPA]//;
                            unless (Action2Status($action) eq $spuef->{'status'}) {
                                execute_sql(qq|UPDATE `servicos` SET `action` = "$action" WHERE `id` = $spuef->{'id'}|);
                                $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                                execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                                $soma += $pdias - $global{"promo_dias"} + 1;
                            }
                        } elsif ($dias >= ($d2+1) && $spuef->{'status'} ne "P" && $dias <= ($d4) && $du){
                            execute_sql(qq|UPDATE `servicos` SET `action` = "P" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            $did = 1;#1 vez por dia
                            $action = 'P';
                        } elsif ($dias >= ($d4+1) && $spuef->{'status'} ne "B" && $dias <= ($d6) && $du){
                            execute_sql(qq|UPDATE `servicos` SET `action` = "B" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            $did = 1;#1 vez por dia
                            $action = 'B';
                        } elsif ( ($dias >= ($d6+1) || ($pdias && $pdias >= $global{"promo_dias_r"}) ) && $spuef->{'status'} ne "F" && $du){
                            execute_sql(qq|UPDATE `servicos` SET `action` = "R" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            #$soma=$d6+1-$d1;
                            $soma += $pdias ? $pdias - $global{"promo_dias_r"} + 1 : $dias - $dueday + 1;#executar uma vez ao dia
                            $action = 'R';
                        }
                    } elsif ($spuef->{'tipo'} eq "Hospedagem" || $spuef->{'tipo'} eq "Adicional"){
            #AVISOS
                        if ($dias >= $d7 && $dias <= $d8){
                            $template{'processo'} = "Bloqueio";
                            $template{'descricao'} = "desativação da conta";
                            $bcc = 1 if $global{'bcc_suspend'} && $dias == $d8;
                            $sndmail=1;
                            $action = 'B';
                        } elsif ($dias >= $d9 && $dias <= $d10){
                            $template{'processo'} = "Remoção";
                            $template{'descricao'} = "exclusão dos arquivos";
                            $bcc = 1 if $global{'bcc_remove'} && $dias == $d10;
                            $sndmail=1;
                            $action = 'R';
                        }
            
                        if ($dias == ($d8-1) || $dias == ($d10-1)){
                            $space = " -";
                            $template{'prazo'} = "48 horas";
                        } elsif ($dias == ($d8) || $dias == ($d10)){
                            $space = " -";
                            $template{'prazo'} = "24 horas";
                        }
            
                        $did = 1 if $template{'processo'};
                        $file = "process";
                        $file.= "do" if $dias == $d8 || $dias == $d10;
                        $exec_day = 1 if $dias == $d8 || $dias == $d10;
            #EXECUÇÕES
                        if ( $pdias && $pdias >= $global{"promo_dias"} && $pdias < $global{"promo_dias_r"} ) {
                            $action = substr($global{"promo_action"},0,1);
                            $action =~ s/[^NCMBPA]//;
                            unless (Action2Status($action) eq $spuef->{'status'} || $spuef->{'status'} =~ /^(S|F)$/) {#Acoes de bloqueio nao se aplicam ao status S e F
                                execute_sql(qq|UPDATE `servicos` SET `action` = "$action" WHERE `id` = $spuef->{'id'}|);
                                $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                                execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                                $soma += $pdias - $global{"promo_dias"} + 1;                            
                            }
                        } elsif ($dias >= ($d8+1) && $spuef->{'status'} ne "B" && $dias <= $d10 && $du){
                            execute_sql(qq|UPDATE `servicos` SET `action` = "B" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            $did = 1;#1 vez por dia
                            $action = 'B';  
                        } elsif ( ($dias >= ($d10+1) || ($pdias && $pdias >= $global{"promo_dias_r"}) ) && $spuef->{'status'} ne "F" && $du){                           
                            execute_sql(qq|UPDATE `servicos` SET `action` = "R" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            $soma += $pdias ? $pdias - $global{"promo_dias_r"} + 1 : $dias - $dueday + 1;#executar uma vez ao dia
                            $action = 'R';      
                        }
                    } elsif ($spuef->{'tipo'} eq "Registro") {
                        if ($dias == -5){
                            my %dados;
                            my @campos = split(/::/, $spuef->{'dados'});
                            foreach my $campo (@campos) {
                                my ($key,$value) = split(/ : /,$campo);
                                $dados{$key}=$value;           
                            }
                            
                            my $credito = credito($spuef->{'username'});
                            my ($mult) = split(" - ", Pagamento($spuef->{'pg'},"intervalo"));
                            my $valor = parcela($spuef->{'servicos'},$spuef->{'pg'},$spuef->{'desconto'}); #parcela com descontos                       
                            if ($dados{'Renew'} == 1 && $credito && $credito >= $valor) {
                                execute_sql(qq|UPDATE `servicos` SET `action` = "A" WHERE `id` = ?|,$spuef->{'id'});
                                $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                                $action = 'A';
                            } else {
                                $template{'processo'} = "Expirar";
                                $template{'descricao'} = "Congelamento do domínio";
                                $template{'prazo'} = "5 dias";
                                $space = " -";
                                $bcc = 1 if $global{'bcc_renew'};
                                $sndmail=1;
                            }
                        }

                        $did = 1 if $template{'processo'};
                        $file = "dominio";

                        if ($dias >= 30 && $spuef->{'status'} ne "F" && $du)  {
                            execute_sql(qq|UPDATE `servicos` SET `action` = "R" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            $soma += $dias - $dueday + 1;#executar uma vez ao dia   
                            $action = 'R';
                        }   
                    } elsif ($spuef->{'tipo'} eq "Dedicado") {
                        #AVISOS
                        if ($dias >= $d11 && $dias <= $d12){
                            $template{'processo'} = "Bloqueio";
                            $template{'descricao'} = "desativação da conta";
                            $bcc = 1 if $global{'bcc_suspend'} && $dias == $d12;
                            $sndmail=1;
                            $action = 'B';
                        } elsif ($dias >= $d13 && $dias <= $d14){
                            $template{'processo'} = "Remoção";
                            $template{'descricao'} = "exclusão dos arquivos";
                            $bcc = 1 if $global{'bcc_remove'} && $dias == $d14;
                            $sndmail=1;
                            $action = 'R';
                        }
            
                        if ($dias == ($d12-1) || $dias == ($d14-1)){
                            $space = " -";
                            $template{'prazo'} = "48 horas";
                        } elsif ($dias == ($d12) || $dias == ($d14)){
                            $space = " -";
                            $template{'prazo'} = "24 horas";
                        }
            
                        $did = 1 if $template{'processo'};
                        $file = "process";
                        $file.= "do" if $dias == $d12 || $dias == $d14;
                        $exec_day = 1 if $dias == $d12 || $dias == $d14;
            #EXECUÇÕES
                        if ( $pdias && $pdias >= $global{"promo_dias"} && $pdias < $global{"promo_dias_r"} ) {
                            $action = substr($global{"promo_action"},0,1);
                            $action =~ s/[^NCMBPA]//;
                            unless (Action2Status($action) eq $spuef->{'status'} || $spuef->{'status'} =~ /^(S|F)$/) {
                                execute_sql(qq|UPDATE `servicos` SET `action` = "$action" WHERE `id` = $spuef->{'id'}|);
                                $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                                execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                                $soma += $pdias - $global{"promo_dias"} + 1;
                            }                                                       
                        } elsif ($dias >= ($d12+1) && $spuef->{'status'} ne "B" && $dias <= $d14 && $du){
                            execute_sql(qq|UPDATE `servicos` SET `action` = "B" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            $did = 1;#1 vez por dia 
                            $action = 'B';  
                        } elsif ( ($dias >= ($d14+1) || ($pdias && $pdias >= $global{"promo_dias_r"}) ) && $spuef->{'status'} ne "F" && $du){
                            execute_sql(qq|UPDATE `servicos` SET `action` = "R" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            $soma += $pdias ? $pdias - $global{"promo_dias_r"} + 1 : $dias - $dueday + 1;#executar uma vez ao dia
                            $action = 'R';
                        }
                    } else { #Outros personalizados             
            #AVISOS
                        if ($dias >= $d7 && $dias <= $d8){
                            $template{'processo'} = "Bloqueio";
                            $template{'descricao'} = "desativação da conta";
                            $bcc = 1 if $global{'bcc_suspend'} && $dias == $d8;
                            $sndmail=1;
                            $action = 'B';
                        } elsif ($dias >= $d9 && $dias <= $d10){
                            $template{'processo'} = "Remoção";
                            $template{'descricao'} = "exclusão dos arquivos";
                            $bcc = 1 if $global{'bcc_remove'} && $dias == $d10;
                            $sndmail=1;
                            $action = 'R';
                        }
            
                        if ($dias == ($d8-1) || $dias == ($d10-1)){
                            $space = " -";
                            $template{'prazo'} = "48 horas";
                        } elsif ($dias == ($d8) || $dias == ($d10)){
                            $space = " -";
                            $template{'prazo'} = "24 horas";
                        }
            
                        $did = 1 if $template{'processo'};
                        $file = "process";
                        $file.= "do" if $dias == $d8 || $dias == $d10;
                        $exec_day = 1 if $dias == $d8 || $dias == $d10;
            #EXECUÇÕES
                        if ( $pdias && $pdias >= $global{"promo_dias"} && $pdias < $global{"promo_dias_r"} ) {
                            $action = substr($global{"promo_action"},0,1);
                            $action =~ s/[^NCMBPA]//;
                            unless (Action2Status($action) eq $spuef->{'status'} || $spuef->{'status'} =~ /^(S|F)$/) {
                                execute_sql(qq|UPDATE `servicos` SET `action` = "$action" WHERE `id` = $spuef->{'id'}|);
                                $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                                execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                                $soma += $pdias - $global{"promo_dias"} + 1;                            
                            }
                        } elsif ($dias >= ($d8+1) && $spuef->{'status'} ne "B" && $dias <= $d10 && $du){
                            execute_sql(qq|UPDATE `servicos` SET `action` = "B" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            $did = 1;#1 vez por dia
                            $action = 'B';  
                        } elsif ( ($dias >= ($d10+1) || ($pdias && $pdias >= $global{"promo_dias_r"}) ) && $spuef->{'status'} ne "F" && $du){                           
                            execute_sql(qq|UPDATE `servicos` SET `action` = "R" WHERE `id` = $spuef->{'id'}|);
                            $system->logcronRemove(4,$spuef->{'id'}); #Liberar a ação do cron!
                            execute_sql(qq|UPDATE `users` SET `status` = "CP" WHERE `username` = $spuef->{'username'}|);
                            $soma += $pdias ? $pdias - $global{"promo_dias_r"} + 1 : $dias - $dueday + 1;#executar uma vez ao dia
                            $action = 'R';      
                        }
                    }

                    $soma += $did;#soma 1
                    #se final de semana ou feriado adiar 1 dia para execucoes;
                    if (!$du && $exec_day == 1) {
                        $sndmail = 0;
                    }
                    if ($sndmail == 1) {                
                        if ($spuef->{'invoice'} && $system->is_valid_invoice($spuef->{'invoice'})) {
                            $system->invid($spuef->{'invoice'});
                            $system->tid($system->invoice('tarifa'));
                            $template{'link'} = "";
                            $template{'linhadigitavel'} = '';                       
                            if ($system->invid && $system->is_boleto_module($system->tax('modulo'))) {
                                eval "use ".$system->tax('modulo');
                                my $boleto = eval "new ".$system->tax('modulo'); #Deve continuar com os mesmos dados        
                                $boleto->boleto();
                                my $cryptkey = $system->encrypt($system->invoice('username').'/'.$system->user('inscricao').'/'.$system->invid);
                                $template{'link'} = $system->setting('baseurl').'/boleto.cgi?key='.Controller::URLEncode($cryptkey);#suportar links antigo      
                                $template{'linhadigitavel'} = $boleto->linhadigitavel;                          
                            } else {
                                my $cryptkey = encrypt($spuef->{'username'}."/".$spuef->{'inscricao'}."/".$spuef->{'invoice'});
                                my $cod = URLEncode( $cryptkey );
                                $template{'link'} = qq|$global{'baseurl'}/boleto.cgi?key=$cod| if $spuef->{'invoice'};
                                $system->invid($spuef->{'invoice'}) if $spuef->{'invoice'};                         
                                my ($var_codigobarras) = boleto($spuef->{'invoice'},$system->invoice('conta')) if $spuef->{'invoice'}; 
                                $template{'linhadigitavel'} = linhadigitavel($var_codigobarras) if $spuef->{'invoice'};
                            }
                            $template{'confirmar'} = $system->setting('baseurl')."/news.cgi?id=".$spuef->{'invoice'}."&do=confirmar&key=".Controller::simple_crypt($spuef->{'username'});                       
                        }
                        
                        my $Bccs = $global{'bcc_avisos'} if $bcc == 1;
                        eval {
                            my $from = Sender(User => $spuef->{'username'});
                            email ( User => "$spuef->{'username'}", To => "$spuef->{'email'}", Bcc => "$Bccs", From => $from, Subject => ['sbj_todo',"$template{'processo'}$space $template{'prazo'}"], txt => "cron/$file");
                            sms ( User => "$spuef->{'username'}", Txt => "/cron/$file");
                        };
                    }
                    execute_sql(qq|UPDATE `servicos` SET `envios` = $soma WHERE `id` = $spuef->{'id'}|) if $soma > $spuef->{'envios'};
                }             
                #UnLock
                execute_sql(qq|DELETE FROM `cron` WHERE `id` = $spuef->{'id'} AND `tipo` = 3|,"",1);
                
                {
                    local $Controller::SWITCH{skip_error} = 1; 
                    $system->Controller::Notifier::event({  name => 'alerts', 
                                            object => 'service', 
                                            typeof => $exec_day == 1 ? 'exec' : 'warn',
                                            action => $action,
                                            identifier => $system->sid,
                                            message => {
                                                        txt => "cron/$file" 
                                                        },
                                            emailed => $sndmail, #TODO melhorar isso!
                                            }); 
                }
            }                                       
        }
    }
    $spusth->finish;

execucoes:
warn "4" if $DEBUG == 1;
#4 Início - Contas - Execuções
    $system = $system->hard_reset; #Consulta novamente do banco as infos
    $this = $q->param('donow');
    $doaction = $q->param('action');
    #Info Servicos
    $template{'campoextra'} = "";
    $stsn = 'SELECT * FROM `servicos` INNER JOIN `planos` ON `servicos`.`servicos`=`planos`.`servicos` WHERE';
    $stsn.= ' `servicos`.`action` != "N" AND `id` NOT IN (SELECT `id` FROM `cron` WHERE `tipo` = 4)' unless $this;
    $stsn.= ' id = '.$this if $this; #TODO, colocar isso com bind
    #$stsn.= ' OR id = '.$this if $doaction && $this;
    $stsn.= ' ORDER BY FIELD(`action`,\'N\',\'A\',\'C\',\'M\',\'B\',\'P\',\'R\') LIMIT 5';#Ate fazer um fork
    $usth = select_sql($stsn) ;
    while(my $ref = $usth->fetchrow_hashref()) {
        $system->soft_reset; #Apaga ids antigos
        
        $system->{cron}{type} = $Etipo = 4;
        $system->{cron}{id} = $Eid = $ref->{'id'};
        execute_sql(qq|INSERT INTO `cron` (`id`,`tipo`,`motivo`) VALUES ($ref->{'id'},"4","Locked")|,"",1) if !$this;
        execute_sql(qq|DELETE FROM `cron_lock` WHERE `id` = $ref->{'username'}|,"",1);
        my $m;
        my $chg;
        my $update; my $update2;
        my $assunto;
        my $new_useracc;
        my $bcc;
        my @PAGE;
        $template{'sucesso'} = undef;
        $update = 0;
        $update2 = 0;
        
        #Ação forçada
        $ref->{'action'} = $doaction if $doaction;
        
        #improved
        $system->sid($ref->{'id'});
        die $system->sid.' != '.$ref->{'id'} if $system->sid != $ref->{'id'};
        $system->service('status');
        die 'error cron step 4' if $system->error;
        $system->service('pg',$ref->{'pg'});
        $system->service('action',$ref->{'action'});
        $system->service('servidor', $system->setting($system->plan('plataforma').$system->plan('tipo'))) unless ($system->service('servidor') > 1 || $system->plan('plataforma') eq '-');
        
        $id = $ref->{'id'}; 
        $status = $ref->{'status'};
        $dominio = $ref->{'dominio'};
        $servidor = $ref->{'servidor'};
        $uusername = $ref->{'username'};
        $useracc = $ref->{'useracc'};
        my $tipo = $ref->{'tipo'};
        $plano = $ref->{'auto'};
        $ns1 = "ns1.".$ref->{'dominio'};
        $ns2 = "ns2.".$ref->{'dominio'};        
        my @chars =  ("A" .. "Z", "a" .. "z", 0 .. 9);
        $system->service('dados','Senha',$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)].$chars[rand(@chars)]) if !$system->service('dados','Senha');        

        #Info Cliente
        $sth = select_sql(qq|SELECT * FROM `users` WHERE `username` = ?|,$uusername) ;
        while(my $uref = $sth->fetchrow_hashref()) {
            for (keys %$uref) {
                next if $_ eq "username"; next if $_ eq "password"; next if $_ eq "status"; next if $_ eq "level";  next if $_ eq "rkey";
                next if $_ eq "pending"; next if $_ eq "acode"; next if $_ eq "lcall";  next if $_ eq "inscricao";  
                $details{$_} = $uref->{$_};
                $details{$_} = $uref->{$_} if $_ eq "email";
            }
            #link de fatura
            $template{'link'} = "";
            $template{'linhadigitavel'} = '';               
            if ($system->service('invoice')) {
                $system->invid($system->service('invoice'));
                $system->tid($system->invoice('tarifa'));
                if ($system->is_boleto_module($system->tax('modulo'))) {    
                    eval "use ".$system->tax('modulo');
                    my $boleto = eval "new ".$system->tax('modulo');        
                    $boleto->boleto();
                    my $cryptkey = $system->encrypt($system->invoice('username').'/'.$system->user('inscricao').'/'.$system->invid);
                    $template{'link'} = $system->setting('baseurl').'/boleto.cgi?key='.Controller::URLEncode($cryptkey);#suportar links antigo      
                    $template{'linhadigitavel'} = $boleto->linhadigitavel;                                  
                    $template{'confirmar'} = $system->setting('baseurl')."/news.cgi?id=".$ref->{'invoice'}."&do=confirmar&key=".Controller::simple_crypt($ref->{'username'});
                }                           
            }           
        }
        $sth->finish;
        
        $servidor = $global{$ref->{'plataforma'}.$tipo} if !$servidor;
        
        $template{'name'} = &URLDecode($details{'name'});
        $template{'dominio'} = $dominio;    
        ($template{'ns1'},$template{'ns2'}, $template{'servidor'}, $template{'web'},$template{'ip'}) = split(" - ",Servidor($servidor,"ns1 ns2 host nome ip"));
        ($template{'Rns1'}, $template{'Rns2'}, $template{'Hns1'}, $template{'Hns2'}) = split(" - ",Servidor_set($servidor,"Rns1 Rns2 Hns1 Hns2"));
    
        #old version
        ($template{'dns1'},$template{'dns2'}) = ($template{'Hns1'}, $template{'Hns2'});
        
        $template{'servn'} = $ref->{'id'};
        $template{'serv'}  = $ref->{'tipo'}." ".$ref->{'plataforma'}." ".$ref->{'nome'};
        $template{'preco'} = CurrencyFormatted($ref->{'valor'});
        $template{'invoice'} = $ref->{'invoice'};
        $template{'vencserv'} = FormatDate($ref->{'vencimento'});
        $template{'plano'} = $ref->{'nome'};
        $template{'plano_tipo'} = $ref->{'tipo'};   
        $template{'plano_descricao'} = $ref->{'descricao'};
        $template{'plataforma'} = $ref->{'plataforma'};
        $template{'periodo'} = $system->payment('nome');            
                    
        my $canAuto =   ($auto_create && $ref->{'action'} eq "C") ||
                        ($auto_remove && $ref->{'action'} eq "R") ||
                        ($auto_suspend && $ref->{'action'} =~ /^(B|P)$/) ||
                        ($auto_unsuspend && $ref->{'action'} eq "A") ||
                        ($auto_updown && $ref->{'action'} eq "M");

        if ($canAuto && ($ref->{'tipo'} eq "Revenda" || $ref->{'tipo'} eq "Hospedagem") && $ref->{'plataforma'} ne "-") {
            unless ($system->plan('modulo')) { #TODO Módulos padrões
                $system->plan('modulo', $ref->{'plataforma'} eq 'Linux' ? 'Controller::ControlPanel::cPanel' : 'Controller::ControlPanel');
            };                      
            eval "use ".$system->plan('modulo');
            my $panel = eval "new ".$system->plan('modulo');#Sid herdado

            if ($ref->{'action'} eq "C"){
                $chg = "A";
                $m = "dados_";
                $assunto = "Dados da Conta";
                if ($ref->{'plataforma'} eq "Windows"){
                    if ($tipo eq "Hospedagem"){
                        if ($panel->chosting || $panel->error) {
                            $m.="hw".$panel->email_txt;
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;
                            $template{'user'} = $panel->service('useracc');
                            $template{'pass'} = $panel->result('PassWord');
                            $template{'ftp'} = $panel->result('FtpUser');
                            $new_useracc = $panel->service('useracc');
                        } else {                            
                            %PKGS = hosting_plans($servidor,$global{"user_host_win"});
                            $planoid = $PKGS{$plano};
                            @PAGE =  create_helm_acc($servidor,$details{'name'},$details{'email'},$details{'endereco'},$details{'cep'},$details{'empresa'},$details{'cidade'},$details{'estado'},$details{'telefone'},$system->service('dados','Senha'),$planoid,$dominio,$ns1,$ns2,$global{"user_host_win"},$plano);
                            $template{'sucesso'} = join("\n",@PAGE);
                            foreach $_ (@PAGE){
                                s/\n//g;
                                ($campo,$valor)=split(/: /,$_);
                                push (@dados,$campo,$valor);
                            }
                            $update = 1 if $template{'sucesso'} =~ "Sucesso";
                            $m.="hw";
                            %dados = @dados;
                            $template{'user'} = $dados{'Username'};         
                            $template{'pass'} = $dados{'Pass'};
                            $template{'ftp'} = $dados{'FtpUser'};
                            $new_useracc = $dados{'Username'};
                        }
                    } elsif ($tipo eq "Revenda"){
                        if ($panel->creseller || $panel->error) {
                            $m.="rw".$panel->email_txt;
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;
                            $template{'user'} = $panel->service('useracc');
                            $template{'pass'} = $panel->result('PassWord');
                            $template{'ftp'} = $panel->result('FtpUser');
                            $new_useracc = $panel->service('useracc');                              
                        } else {
                            $m.="rw";
                            %PKGS = reseller_plans($servidor);
                            $planoid = $PKGS{$plano};           
                            @PAGE = create_helm_res($servidor,$details{'name'},$details{'email'},$details{'endereco'},$details{'cep'},$details{'empresa'},$details{'cidade'},$details{'estado'},$details{'telefone'},$system->service('dados','Senha'),$planoid,$dominio,$ns1,$ns2);
                            $template{'sucesso'} = join("\n",@PAGE);
                            foreach $_ (@PAGE){
                                s/\n//g;
                                ($campo,$valor)=split(/: /,$_);
                                push (@dados,$campo,$valor);
                            }
                            $update = 1 if $template{'sucesso'} =~ "Sucesso";                   
                            %dados = @dados;
                            $template{'reseller'} = $dados{'Reseller'};
                            $template{'user'} = $dados{'Username'};         
                            $template{'pass'} = $dados{'Pass'};
                            $template{'ftp'} = $dados{'FtpUser'};
                            $new_useracc = $dados{'Reseller'};                              
                        }           
                    }
                    $template{'mailp'} = "mail\@".$dominio;
                } elsif ($ref->{'plataforma'} eq "Linux"){
                    if ($tipo eq "Hospedagem") {
                        my %dados = $panel->create_cpanel_acc;
                        $template{'sucesso'} = $panel->{ERR};
                        $m.="hl".$panel->email_txt;
                        $template{'user'} = $dados{'UserName'};
                        $template{'pass'} = $dados{'PassWord'};
                        $template{'quota'} = $dados{'Quota'};
                        $template{'ip'} = $dados{'Ip'};
                        $new_useracc = $dados{'UserName'};
                        #make sure cpanel do
                        $update2 = $dados{'UserName'} ? 1 : 0;
                    } elsif ($tipo eq "Revenda"){
                        my %dados = $panel->create_cpanel_res();
                        $template{'sucesso'} = $panel->{ERR};
                        $m.="rl".$panel->email_txt;
                        $template{'user'} = $dados{'UserName'};
                        $template{'pass'} = $dados{'PassWord'};
                        $template{'quota'} = $dados{'Quota'};
                        $template{'ip'} = $dados{'Ip'};
                        $new_useracc = $dados{'UserName'};
                        #make sure cpanel do
                        $update2 = $dados{'UserName'} ? 1 : 0;
                    } 
                }

                if ($update == 1){
                    execute_sql(qq|DELETE FROM `cancelamentos` WHERE `servid` = $id|);
                    execute_sql(qq|UPDATE `servicos` SET `servidor` = "$servidor", `inicio` = "$timemysql", `useracc` = "$new_useracc", `fim` = "0000-00-00" WHERE `id` = $id|);
                    #Multiserver
                    execute_sql(qq|REPLACE INTO `servicos_set` VALUES ($id,NULL,NULL,NULL,NULL,NULL,NULL)|);
                    foreach ("MultiWEB", "MultiDNS", "MultiMAIL", "MultiFTP", "MultiSTATS", "MultiDB") {
                        my $sth = select_sql(qq|SELECT `id` FROM `servidores` WHERE `ip` = "$dados{$_}"|);
                        my ( $srid ) = $sth->fetchrow_array();
                        execute_sql(qq|UPDATE `servicos_set` SET `$_` = '$srid' WHERE `servico` = $id|);
                        $sth->finish;
                        ( $template{$_} ) = split(/ -\s?/,Servidor_set($srid,"$_"));
                        ( $template{$_} ) = split(/ -\s?/,Servidor_set($servidor,"$_")) if $ref->{'plataforma'} eq "Linux";
                    }
                }
            } elsif ($ref->{'action'} eq "M" and $ref->{'status'} ne "F"){
                $m = "updown".$panel->email_txt;
                $assunto = "Mudança de Plano";
                if ($ref->{'plataforma'} eq "Windows"){
                    if ($ref->{'tipo'} eq "Hospedagem"){
                        if ($panel->updowngrade || $panel->error) {
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;
                        } else {                            
                            %PKGS = hosting_plans($servidor,$global{"user_host_win"});
                            $planoid = $PKGS{$plano};
                            @PAGE = updown_helm($servidor,$useracc,$dominio,$planoid,$plano);
                            $template{'sucesso'} = join("\n",@PAGE);
                            $update = 1 if $template{'sucesso'} =~ "Sucesso";
                        }
                    } elsif ($ref->{'tipo'} eq "Revenda"){
                        if ($panel->updowngrade || $panel->error) {
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;
                        } else {                        
                            %PKGS = reseller_plans($servidor);
                            $planoid = $PKGS{$plano};
                            @PAGE = updown_helm_res($servidor,$useracc,$planoid,$plano);
                            $template{'sucesso'} = join("\n",@PAGE);
                            $update = 1 if $template{'sucesso'} =~ "Sucesso";
                        }
                    }
                } elsif ($ref->{'plataforma'} eq "Linux"){
                    if ($ref->{'tipo'} eq "Hospedagem"){
                        if ($panel->updowngrade || $panel->error) {
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;                              
                        } else {
                            @PAGE = updown_cpanel($servidor, username => "$useracc" , 'package' => "$plano" );
                            $template{'sucesso'} = join("\n",@PAGE);
                            $update = 1 if $template{'sucesso'} =~ "Warning";
                        }
                    } elsif ($ref->{'tipo'} eq "Revenda"){
                        if ($panel->updowngrade || $panel->error) {
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;                              
                        } else {                            
                            @PAGE = updown_cpanel_res($servidor, username => "$useracc" , 'package' => "$plano" , domain => "$dominio");
                            $template{'sucesso'} = join("\n",@PAGE);
                            $update = 1 if $template{'sucesso'} =~ "Modified reseller";
                        }
                    }
                }
            } elsif ($ref->{'action'} eq "B" and $ref->{'status'} ne "F"){
                $m = "bloqueado".$panel->email_txt;
                $chg = "B";
                $assunto = "Bloqueio da Conta";
                
                my $flag = $ref->{'tipo'} eq "Revenda" ? 1 : 0;
                if ($ref->{'plataforma'} eq "Windows"){
                    if ($panel->suspend('all') || $panel->error) {
                        #compat old way
                        $chg = '';
                        $template{'sucesso'} = $panel->error;
                        $update2 = 1 unless $panel->error;
                    } else {
                        @PAGE = suspend_helm($servidor,$useracc,$dominio,$flag);
                        $template{'sucesso'} = join("\n",@PAGE);
                        $update = 1 if $template{'sucesso'} =~ "Sucesso";
                    }
                } elsif ($ref->{'plataforma'} eq "Linux"){
                    @PAGE = $panel->suspend_cpanel($flag);
                    $template{'sucesso'} = join("\n",@PAGE) eq '' ? 'usuário "'.url($panel->service('useracc')).'" não existe na sua posse.' : join("\n",@PAGE);            
                    $update = 1 if $template{'sucesso'} =~ "account has been suspended" || $template{'sucesso'} =~ "passwd: Success";
                }
                $bcc = 1 if $global{'bcc_suspendedf'} && $update == 1;
            } elsif ($ref->{'action'} eq "P" and $ref->{'status'} ne "F"){
                $m = "paralisado".$panel->email_txt;
                $chg = "P";                 
                $assunto = "Bloqueio Parcial da Conta";
                if ($ref->{'plataforma'} eq "Windows"){
                    if ($panel->suspend || $panel->error) {
                        #compat old way
                        $chg = '';
                        $template{'sucesso'} = $panel->error;
                        $update2 = 1 unless $panel->error;
                    } else {
                        @PAGE = suspend_helm($servidor,$useracc,$dominio);
                        $template{'sucesso'} = join("\n",@PAGE);
                        $update = 1 if $template{'sucesso'} =~ "Sucesso";
                    }
                } elsif ($ref->{'plataforma'} eq "Linux"){
                    @PAGE = $panel->suspend_cpanel;
                    $template{'sucesso'} = join("\n",@PAGE) eq '' ? 'usuário "'.url($panel->service('useracc')).'" não existe' : join("\n",@PAGE);
                    $update = 1 if $template{'sucesso'} =~ "passwd: Success";
                }
                $bcc = 1 if $global{'bcc_suspended'} && $update == 1;
            } elsif ($ref->{'action'} eq "R"){
                $m = "removido".$panel->email_txt;
                $m = "removidopagamento".$panel->email_txt if $ref->{'invoice'} > 0;
                $m = "removidosolicitado".$panel->email_txt if $ref->{'status'} =~ /^C$/;
                
                $chg = "F";
                $assunto = "Remoção da Conta";
                if ($ref->{'plataforma'} eq "Windows"){
                    if ($tipo eq "Hospedagem") {
                        if ($panel->rhosting || $panel->error) {
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;
                        } else {
                            @PAGE =  remove_helm($servidor,$useracc,$dominio);
                            $template{'sucesso'} = join("\n",@PAGE);
                            $update = 1 if $template{'sucesso'} =~ "Sucesso";
                        }
                    } elsif ($tipo eq "Revenda"){
                        if ($panel->rreseller || $panel->error) {
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;
                        } else {                            
                            @PAGE =  remove_helm($servidor,$useracc,"",1,$ns1,$ns2);
                            $template{'sucesso'} = join("\n",@PAGE);
                            $update = 1 if $template{'sucesso'} =~ "Sucesso";
                        }
                    }
                } elsif ($ref->{'plataforma'} eq "Linux"){
                    my $flag = $ref->{'tipo'} eq "Revenda" ? 1 : 0;
                    @PAGE = $panel->kill_cpanel($flag);
                    $template{'sucesso'} = join("\n",@PAGE);
                    $update = 1 if ($template{'sucesso'} =~ "Removing User....Done"  || $template{'sucesso'} =~ "Account Removal Status: ok" || $template{'sucesso'} =~ "account removed...Done") && ($template{'sucesso'} !~ "Warning" || $template{'sucesso'} =~ /Warning\: Unable to determine .*s main domain\./);
                }
                if ($update == 1) {                 
                    execute_sql(qq|UPDATE `servicos` SET `fim` = "$timemysql" WHERE `id` = $id|);
                }
                $bcc = 1 if $global{'bcc_removed'} && ($update == 1 || $update2 == 1);      
            } elsif ($ref->{'action'} eq "A" and $ref->{'status'} ne "F"){
                $m = "ativo".$panel->email_txt;
                $chg = "A";
                $assunto = "Ativação da Conta";
                if ($ref->{'plataforma'} eq "Linux") {
                    if ($tipo eq "Hospedagem") {
                        @PAGE = $panel->unsuspend_cpanel;
                        $template{'sucesso'} = join("\n",@PAGE);
                        $update = 1 if $template{'sucesso'} =~ "passwd: Success";
                    } elsif ($tipo eq "Revenda") {
                        if ($status eq "P") {
                            @PAGE = $panel->unsuspend_cpanel;
                        } else {
                            @PAGE = $panel->unsuspend_cpanel(1);        
                        }
                        $template{'sucesso'} = join("\n",@PAGE);            
                        $update = 1 if $template{'sucesso'} =~ "passwd: Success";
                    }
                } elsif ($ref->{'plataforma'} eq "Windows"){
                    if ($tipo eq "Hospedagem") {
                        if ($panel->unsuspend || $panel->error) {
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;
                        } else {
                            @PAGE = unsuspend_helm($servidor,$useracc,$dominio);
                            $template{'sucesso'} = join("\n",@PAGE);
                            $update = 1 if $template{'sucesso'} =~ "Sucesso";
                        }
                    } elsif ($tipo eq "Revenda"){
                        my $flag = $status eq "P" ? 0 : 1;
                        if ($panel->unsuspend || $panel->error) {
                            #compat old way
                            $chg = '';
                            $template{'sucesso'} = $panel->error;
                            $update2 = 1 unless $panel->error;
                        } else {
                            @PAGE = unsuspend_helm($servidor,$useracc,$dominio,$flag);
                            $template{'sucesso'} = join("\n",@PAGE);
                            $update = 1 if $template{'sucesso'} =~ "Sucesso";
                        }
                    }   
                }
            }
            #acao forcada
            $m = "" if $doaction;
            print $template{'sucesso'}."\n" if $doaction;               
            
            if ($update eq 1 || $update2 == 1){
                foreach ("MultiWEB", "MultiDNS", "MultiMAIL", "MultiFTP", "MultiSTATS", "MultiDB") {
                    $template{$_} = $system->server(lc $_) if $system->plan('plataforma') eq 'Linux';
                }                

                execute_sql(qq|UPDATE `servicos` SET `status` = "$chg" WHERE `id` = $id|) if $chg;
                if ($update == 1) {
                    execute_sql(qq|UPDATE `servicos` SET `action` = "N" WHERE `id` = $id|);
                    $system->logcronRemove(4,$id); #Liberar a ação do cron!
                }

                my $blind = $global{'bcc_avisos'} if $bcc == 1;
                eval {
                    my $from = Sender(User => $uusername);
                    if ($m) {
                        email ( User => "$uusername", To => $system->user('emails'), Bcc => "$blind", From => "$from", Subject => ['sbj_todo',"$assunto - $dominio"], txt => "cron/$m");                
                        sms ( User => "$uusername", Txt => "/cron/$m");
                    }
                };
                $action = Action($ref->{'action'});
                execute_sql(qq|INSERT INTO `actionlog` VALUES ( NULL, "CRON", "$action", "$ref->{'id'}" )|);
            } else {
                $template{'sucesso'} =~ s/\<head\>.+?\<\/head\>//;
                if ($this) {
                    die $template{'sucesso'}.$system->error;
                } else { 
                    $system->logcron($template{'sucesso'}.$system->clear_error);
                }
                next;#Proximo no loop de servicos
            }               
            
            $panel = undef; 
        } elsif ($canAuto && $ref->{'tipo'} eq "Registro" && $ref->{'action'} ne "N") {                
            $system->plan('modulo','Controller::Registros') unless $system->plan('modulo');                     
            eval "use ".$system->plan('modulo');
            my $domain = eval "new ".$system->plan('modulo');
            $domain->_domain($ref->{'dominio'});
            $domain->{_epp}{'ERR'} = undef;
            $domain->{'_epp'}{'order_id'} = $ref->{'useracc'};
            $domain->{ns1} = ''; $domain->{ip1} = '';
            $domain->{ns2} = ''; $domain->{ip2} = '';
            my %dados = %{$domain->service('dados')};

            if ($ref->{'action'} eq "C") {
                $m = "registrado";
                $chg = "A";
                $assunto = "Ativação do registro de domínio";
                
                if ($domain->{'_epp'}{'order_id'}) { #pendencias e processamento dos nao automaticos
                    my ($code,$reason) = $domain->{'_epp'}->process;
                    $update = 1 if $code == 1;
                    $template{'sucesso'} = $reason ." ". $domain->{_epp}{'ERR'}." status: $code";
                } else {
                    #nameservers
                    $domain->{ns1} = URLDecode($dados{'NS1'});
                    $domain->{ns2} = URLDecode($dados{'NS2'});
                    $domain->{ns1} = $system->setting('registro_ns1') unless $domain->{ns1};
                    $domain->{ns2} = $system->setting('registro_ns2') unless $domain->{ns2};
                    $domain->{ip1} = $dados{'NS1IP'};
                    $domain->{ip2} = $dados{'NS2IP'};
                    
                    $template{ns1} = $domain->{ns1};
                    $template{ns2} = $domain->{ns2};
                    $template{ip1} = $dados{'NS1IP'};
                    $template{ip2} = $dados{'NS2IP'};
                    #Registro.br compat
                    $domain->nameservers({ 'name' => $domain->{ns1}, 'ipv4' => $domain->{ip1}});
                    $domain->nameservers({ 'name' => $domain->{ns2}, 'ipv4' => $domain->{ip2}});
        
                    #options
                    $domain->{_epp}{'reg_type'} = $dados{'transfer'} == 1 ? 'transfer' : 'new'; #new | transfer
                    $domain->{_epp}{'nyears'} = int($system->payment('intervalo')/360);                 
                    #$domain->{_epp}{'handle'} = "save"; # save | process
                    
                    $domain->{_epp}{'hide_reseller'} = 1 if $dados{'ResellerInfo'} == 1;
                    unless ($domain->registrar) {
                        $template{'sucesso'} = $domain->{_epp}{'ERR'} || $domain->clear_error;
                    } else {
                        $update = 1;
                    }
                    #atualizacoes a fazer, useracc etc
                    execute_sql(qq|UPDATE `servicos` SET `useracc` = "$domain->{_epp}{'order_id'}" WHERE `id` = $id|) if $domain->{_epp}{'order_id'};
                }
                
                if ($update == 1) {
                        execute_sql(qq|DELETE FROM `cancelamentos` WHERE `servid` = $id|);
                        execute_sql(qq|UPDATE `servicos` SET `inicio` = "$timemysql", `fim` = "0000-00-00" WHERE `id` = $id|);                          
                        if ($dados{'transfer'} != 1 || $ref->{'useracc'}) {
                            my $expdate = $domain->expdate;
                            my $start = $system->subtract_period($expdate, years => int($system->payment('intervalo')/360));
                            die "erro inesperado servico $id data de expiracao $expdate, verifique o useracc" if (!$expdate || ($expdate && $expdate <= today()));
                            execute_sql(qq|UPDATE `servicos` SET `inicio` = "$expdate", `vencimento` = "$expdate" WHERE `id` = $id|);
                            my $fromdate = $expdate;
                            my $prox = ($dados{'transfer'} == 1 || !$expdate) ? SomaMes($timemysql,$system->payment('intervalo')/30) : $fromdate; #consultar no registro
                            $system->logcron('Transferência iniciada!') if $dados{'transfer'} == 1;
                            $template{'vencserv'} = FormatDate($prox); #Vencimento presumido
                            if ($ref->{'invoice'} > 0) {#se tem fatura em aberto, movimentar o proximo
                                execute_sql(qq|UPDATE `servicos` SET `proximo`="$prox" WHERE `id` = $id|);                      
                            }
                        }
                }
            } elsif ($ref->{'action'} eq "A") {
                $m = "renovacao";
                $chg = "A";
                $assunto = "Renovação de registro de domínio";
                die "vencimento inválido" unless $system->service('vencimento');
                
                $domain->{_epp}{'nyears'} = int($system->payment('intervalo')/360);
                $domain->{_epp}{'exp_year'} = $system->service('vencimento')->year - $domain->{_epp}{'nyears'};

                $expdate = $domain->renew;
                if ($expdate eq $system->service('vencimento')) {
                    $update = 1;
                } else {
                    $template{'sucesso'} = $domain->clear_error;
                    $update = 1 unless $template{'sucesso'};
                    execute_sql(qq|UPDATE `servicos` SET `vencimento` = "$expdate" WHERE `id` = $id|) if $update == 1 && $expdate > today();
                    email ( To => "$global{'controller_mail'}", From => "$global{'adminemail'}", Subject => "Olhar data de registro $id ATIVADO!", Body => "Nao existe erro: $template{'sucesso'} e o expdate é $expdate" );
                }
                $bcc = 1 if $global{'bcc_renewed'} && $update == 1;
            } elsif ($ref->{'action'} eq "R") {
                $m = "expiracao";
                $chg = "F";
                $assunto = "Expiração do registro de domínio";
                            
                #TODO Verificar casos de autorenew, pois pode haver encargos
                unless ($domain->expire) {
                    $template{'sucesso'} = $domain->{_epp}{'ERR'} || $domain->clear_error;
                } else {        
                    $update = 1;                    
                    execute_sql(qq|UPDATE `servicos` SET `fim` = "$timemysql" WHERE `id` = $id|);
                }                                                       
            }
            #clear module
            $domain = undef;
            
            if ($update == 1){
                execute_sql(qq|UPDATE `servicos` SET `status` = "$chg" WHERE `id` = $id|) if $chg;
                execute_sql(qq|UPDATE `servicos` SET `action` = "N" WHERE `id` = $id|);
                $system->logcronRemove(4,$id); #Liberar a ação do cron!
                eval {
                    my $from = Sender(User => $uusername);
                    my $blind = $global{'bcc_avisos'} if $bcc == 1;
                    email ( User => "$uusername", To => $system->user('emails'), From => "$from", Bcc => "$blind", Subject => ['sbj_todo',"$assunto - $dominio"], txt => "cron/$m");                
                    sms ( User => "$uusername", Txt => "/cron/$m");
                };
                $action = Action($ref->{'action'});
                execute_sql(qq|INSERT INTO `actionlog` VALUES ( NULL, "CRON", "$action", "$ref->{'id'}" )|);                
            } else {
                if ($this) {
                    die $template{'sucesso'};
                } else { 
                    $system->logcron($template{'sucesso'});
                }
                next;#Proximo no loop de servicos
            }
        } elsif ($ref->{'action'} ne "N") {
            #Modulos
            $system->plan('modulo', 'Controller::Adicional') unless ($system->plan('modulo') =~ m/Controller::Adicional::/);
            eval "use ".$system->plan('modulo');
            my $module = eval "new ".$system->plan('modulo');#Sid herdado
            $system->plan('modulo', 'Controller::Adicional');
            
            unless ($module->cronAction) {
                $module->manual_action;
            }       
            #Manter o erro no cron
            next if $module->clear_error;#Proximo no loop de servicos                       
        }
        
        die 'error cron step 4' if $system->error;
        #UnLock
        execute_sql(qq|DELETE FROM `cron` WHERE `id` = $ref->{'id'} AND `tipo` = 4|,"",1) if !$this;
    }
    $usth->finish;
    $system->{cron}{id} = undef;
    $system->{cron}{type} = undef;

#5 Verificacao de poll registro.br
warn "5" if $DEBUG == 1;
    $system->soft_reset;
    if ($system->setting('registrobr_user')){# && int($min) % 15 == 0) {
        use Controller::Registros::RegistroBR;
        my $registro = new Controller::Registros::RegistroBR;
        my ($msg,$result);
        eval{
            do {
                $result = $registro->poll_get;
                print "mensagens em pool: ".$result->{'count'}."\n";
                                
                if ($result->{'id'}) {
                    if ($result->{'created'} == 1 && $result->{'ticket'}) {#set created
                        $system->sid( $system->search_sid('dados','Ticket',$result->{'ticket'}) ); 
                        if ($system->sid > 0) { 
                            $system->service('dados','MsgPoll',1);
                            $system->service('action','C');                 
                            use Controller::Services;
                            $system->Controller::Services::save; #Nao vai salvar se nao achar o servico
                            execute_sql(qq|DELETE FROM `cron` WHERE `id` = ? AND `tipo` = 4|,$system->sid,1) if $system->service('dados','Ticket');
                        }                       
                    } elsif ($result->{'created'} == -1 && $result->{'ticket'}) {
                        $system->logcron(join "\n", @{$result->{'text'}});                          
                    }               
                    $msg .= join("\n", 'MsgID: '.$result->{'id'}, @{$result->{'text'}})."\n\n";
                    $registro->poll_ack($result->{'id'});
                }
            } while ( $result->{'count'} > 0);
        };
        my $err = $@ if $@;     
        $system->email( To => $system->setting('alertregistrobr'), From => $system->setting('adminemail'), Subject => 'Mensagens de Pool do Registro.br' , Body => $msg, ctype => 'text/plain') if $msg;
        die $err if $err;
        die $system->error if $system->error;
    }
    
#6 Início - Email - Verificação
warn "6" if $DEBUG == 1;
    $system->soft_reset;
    my $secs = $global{'exp_ownership'};
    # TODO está muito lento 
    if (int($min) == 30 && $secs) { execute_sql(qq|UPDATE `calls` SET `calls`.`ownership` = NULL, `calls`.`is_locked` = 0 WHERE (SELECT COUNT(`notes`.`call`) FROM `notes` WHERE `calls`.`id` = `notes`.`call` AND DATE_ADD( `notes`.`time`, INTERVAL $secs SECOND) > NOW() ORDER BY `notes`.`id` DESC LIMIT 1) = 0 AND (`calls`.is_locked != 0 OR `calls`.`ownership` IS NOT NULL)|,"",1); } #SLOW 
    if (int ($hour) == 1 && $time !~ 'P.M.') { execute_sql(qq|update invoices set status = 'D' where username = 999 and status != 'D' and (status = 'Q' OR `data_vencimento` + INTERVAL 1 MONTH < NOW() )|,"",1); }
    if (int ($hour) == 8) { execute_sql(qq|UPDATE `servicos` a left join `invoices` b on a.invoice = b.id  SET `invoice` = NULL WHERE a.username != 999 and a.invoice > 0 and ( b.`status` = 'D' or b.`status` is NULL or b.`status` = 'Q')|,'',1); }


warn "7" if $DEBUG == 1;
#7 Cleanup Financeiro
#não pode processar imediatamente faturas que acabaram de ser editadas, dar um tempo para o usuario, se possível avisar.
    $stinus = qq|SELECT `invoices`.* FROM `invoices` LEFT JOIN `cron_lock` ON `invoices`.`username`=`cron_lock`.`id` WHERE `invoices`.`status` = "P" OR `invoices`.`status` = "C" AND (`cron_lock`.`data` != "$timemysql" AND `cron_lock`.`hora` IS NULL)|;
    my $iusth2 = select_sql($stinus);
    while(my $iuef = $iusth2->fetchrow_hashref()) {
        if (grep { $_ eq $iuef->{'id'}."-7" } @run){
            #do nothing
            next;
        } else {
            $system->soft_reset;
            $system->clear_error;
            $system->invid($iuef->{'id'});
            $system->tid($system->invoice('tarifa'));
            $template{'user'} = $system->invoice('username');
            
            die 'error cron step 7' if $system->error;
            my $extmail = '';
            #Apagando faturas antigas
            my $apaga=1;
            foreach (keys %{ $system->invoice('services') }) {
                $system->sid($_);
                next if $system->sid && !$system->service('status'); #servico nao existe?
                next if $system->service('status') eq $system->SERVICE_STATUS_FINALIZADO;
                next if $system->service('invoice') && $system->service('invoice') ne $system->invid && $system->setting('invoices') != 1;
                if ($system->service('invoice') && ( ($system->service('status') eq $system->SERVICE_STATUS_SOLICITADO && ($system->today - $system->invoice('data_vencimento')) > 180) || ($system->service('status') eq $system->SERVICE_STATUS_CANCELADO && !$system->service('inicio')) )  ) {
                    execute_sql(qq|UPDATE `servicos` SET `status` = "F", fim = "$timemysql" WHERE `id` = ?|,$system->sid);
                    $system->service('status','F');
                    $system->service('fim',$system->date($timemysql));
                    next;
                }
                $apaga=0;
                last;
            }               
            if ($apaga == 1 && scalar(keys %{ $system->invoice('services') })) {
                my $err = Cancelar($iuef->{'id'}); #Essa funcao ainda nao tem retorno
            }
        }       
    }
1;
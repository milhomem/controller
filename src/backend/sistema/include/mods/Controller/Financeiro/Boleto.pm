#!/usr/bin/perl         
# Use: Internal
# Controller - is4web.com.br
# 2011
package Controller::Financeiro::Boleto;

require 5.008;
require Exporter;

use Controller::Financeiro;
use Controller::Interface;

use vars qw(@ISA $VERSION $tidproximo);

@ISA = qw(Controller::Financeiro Controller::Interface Exporter);
$VERSION = "0.2";

=pod
########### ChangeLog #######################################################  VERSION  #
=item cnab_ret                                                              #           #
- Adicionado inválido se fatura não estiver associada a um módulo de boleto #    0.2    #
#############################################################################           #
=cut

sub new {
        my $proto = shift;
        my $class = ref($proto) || $proto;
		
        #Depende do Controller
        my $inherit = new Controller::Financeiro( @_ );
        push @ISA, @Controller::Financeiro::ISA; #Inherit ISA

        my $self = {
                %$inherit,
        };
		
        bless($self, $class);

        return $self;
}

sub class {
	my $inherit = shift;

	die 'Undefined Invoice!' unless $inherit->invid > 0;
	$inherit->actid($inherit->invoice('conta'));
	die 'Undefined Bank Code' unless $inherit->account('banco') > 0;
	my $base = 'Controller::Financeiro::Boleto::'.$inherit->account('banco');
	eval 'require '.$base;
	my $class = eval '$inherit->'.$base.'::init';
	die $@ if $@;
	return $class;
}

use constant {
	DOC => '90123',
};

sub AUTOLOAD { #Holds all undef methods
	my $self = $_[0];
	my $type = ref($self) or die "$AUTOLOAD is not an object";

	my $name = $AUTOLOAD;
	$name =~ s/.*://;   # strip fully-qualified portion
	
	my $r = eval '$self->'.$self->class()."::$name";
	die $@ if $@;
	return $r;		
}

sub var_nossonumero {
	my $r = eval '$_[0]->'.$_[0]->class().'::var_nossonumero';
	die $@ if $@;
	return $r;
}

sub parse_boleto {
	my $r = eval '$_[0]->'.$_[0]->class().'::parse_boleto';
	die $@ if $@;
	return $r;		
}

sub codbar {
	my $r = eval '$_[0]->'.$_[0]->class().'::codbar';
	die $@ if $@;
	return $r;
}

sub boleto {
	my $self = shift;

	$self->tid($self->invoice('tarifa'));
	$self->actid($self->invoice('conta'));
		
	#********************************
	# Variáveis
	#********************************
	my $var_banco = $self->account('banco');
	#********************************
	# CÁLCULO
	#********************************
	my $var_valordocumento = $self->valordocumento('float');
	my $taxa = $self->tax('valor');
	
	my $var_observacoes = $self->lang( $taxa != 0 ? 74 : 75 ,$self->invoice('referencia'),$self->Currency($taxa));
	$var_observacoes =~ s/\n/<br>/g;

	#TEMPLATES
	$self->template('cedente', $self->account('cedente'));	
	$self->template('vencimento', $self->dateformat($self->invoice('data_vencimento')));
	$self->template('valor', $self->Currency($var_valordocumento,1));
	$self->template('obs', $var_observacoes);
	$self->template('instrucoes', $self->account('instrucoes'));
	$self->template('agencia', $self->account('agencia'));
	$self->template('conta', $self->account('conta'));
	$self->template('banco', $self->account('banco'));
	$self->template('dvbanco', $self->account('dvbanco'));
	$self->template('moeda', $self->setting('moeda_nr'));
	$self->template('especie', $self->setting('moeda'));
	$self->template('datadoc', $self->dateformat($self->invoice('data_envio')));
	$self->template('numerodoc', $self->DOC);
	$self->template('sacado',$self->user('empresa') eq "" ? $self->user('name') : $self->user('empresa'));
	$self->template('cpfcnpj',$self->user('cnpj') eq "" || $self->user('cnpj') == 0 ? Controller::frmtCPFCNPJ($self->user('cpf')) : Controller::frmtCPFCNPJ($self->user('cnpj')));
	$self->template('endereco',$self->user('endereco'));
	$self->template('endereco', $self->user('endereco') . ", ".$self->user('numero')) if $self->user('numero');
	$self->template('cidade',$self->user('cidade'));
	$self->template('estado',$self->user('estado'));
	$self->template('cep',$self->user('cep'));
	$self->template('codigobarras',$self->codbar);
	$self->template('linhadigitavel',$self->linhadigitavel);
	$self->template('imgcodebar',$self->wbarcode);
	$self->template('codcliente','');	
	$self->template('dvcodcli','');	
	$self->template('dvconta','');		

	return ($self->codbar,$var_banco);
}

#BOLETO SUBS
sub valordocumento {
	my $self = shift;
	
	my $var_valor1 = $self->invoice('valor') + $self->tax('valor');	
	$var_valor1 = $self->round($var_valor1);
	return $var_valor1 if exists $_[0];
	$var_valor1 =~ s/[,.]//g;
	my $var_valor2 = 10 - length($var_valor1);
	my $var_valor = $self->string($var_valor2,0) . $var_valor1;
	
	
	return $var_valor1 == 0 ? '' : $var_valor;
}

sub var_carteira {
	my $self = shift;
	$var_carteira = $self->account('carteira');
	$var_carteira =~ s/-(.+)//g;
	return substr('00'.$var_carteira,-2);
}

sub calcdig10 {
	my $self = shift;
	my $cadeia = shift;
	my $mult="";
	my $total="";
	my $calcdig10="";
	
	$mult = (length($cadeia) % 2);
	$mult = $mult + 1;
	$total = 0;
	for ($pos=0;$pos<length($cadeia);$pos++){
		$res = substr($cadeia, $pos, 1) * $mult;
		$res = int($res/10) + ($res % 10) if $res > 9 ;
		$total = $total + $res;
		if ($mult == 2){
			$mult = 1;
		}else{
			$mult = 2;
		}
	}
	$total = ((10-($total % 10)) % 10 );
	$calcdig10 = $total;
	return "$calcdig10";
}

sub calcdig11 {
	my $self = shift;
	my $cadeia = shift;
	my $limitesup = shift;
	#my $lflag = shift;
	my $mult="";
	my $nresto="";
	my $ndig="";
	my $calcdig11="";

	$mult = 1 + (length($cadeia) % ($limitesup - 1));
	$mult = $limitesup if $mult == 1;

	$total = 0;
	
	for ($pos=0;$pos<length($cadeia);$pos++) {
		$total += substr($cadeia,$pos,1) * $mult;
		$mult = $mult - 1;
		$mult = $limitesup if $mult == 1; 
	}

	return $total % 11;
}

sub string {
	my $self = shift;	
	my $quantidade = shift;
	my $var = shift;
	my $n="";
	for($i=0;$i<$quantidade;$i++){
	$n .= $var;
	}
	return $n;
}

sub fatorvencimento {
	my $self = shift;
	
	unless ($self->invoice('data_vencimento')) {
	   return "0000";
	}else{ 
	   return substr('0000'. ($self->invoice('data_vencimento') - $self->date('1997-10-07')), -4);
	}
}

sub linhadigitavel {
	my $self = shift;
	my $codigobarras = $self->codbar;
	
	my $cmplivre = substr($codigobarras,19,25);
	
	my $campo1 = substr($codigobarras,0,4) . substr($cmplivre,0,5);
	$campo1 .= &calcdig10($self,$campo1);
	$campo1 = substr($campo1,0,5) . "." . substr($campo1,5,5);

	my $campo2 = substr($cmplivre,5,10);
	$campo2 .= &calcdig10($self,$campo2);
	$campo2 = substr($campo2,0,5) . "." . substr($campo2,5,6);

	my $campo3 = substr($cmplivre,15,10);
	$campo3 .= &calcdig10($self,$campo3);
	$campo3 = substr($campo3,0,5) . "." . substr($campo3,5,6);
	
	my $campo4 = substr($codigobarras,4,1);

	my $campo5 = substr($codigobarras,5,14);
	$campo5 = "000" if $campo5 eq 0;

	my $linhadigitavel = $campo1 . " " . $campo2 . " " . $campo3 . " " . $campo4 . " " . $campo5;
	
	return $linhadigitavel;
}

sub wbarcode {
	my $self = shift;
	my $valor = $self->codbar;
	my $fino = "1";
	my $largo = "3";
	my $altura = "50";
	
	my @BarCodes;
	$BarCodes[0] = "00110";
	$BarCodes[1] = "10001";
	$BarCodes[2] = "01001";
	$BarCodes[3] = "11000";
	$BarCodes[4] = "00101";
	$BarCodes[5] = "10100";
	$BarCodes[6] = "01100";
	$BarCodes[7] = "00011";
	$BarCodes[8] = "10010";
	$BarCodes[9] = "01010";
	for (my $f1=9;$f1>=0;$f1--){
		for (my $f2=9;$f2>=0;$f2--){
			my $f = $f1 * 10 + $f2;
			my $texto = "";
			for (my $i=0;$i<5;$i++){
				$texto .= substr($BarCodes[$f1],$i,1) . substr($BarCodes[$f2],$i,1);
			}

			$BarCodes[$f] = $texto;
		}
	}

	#Desenho da barra
	#Guarda inicial
	my $imgbase = $self->template('imgbase');
	my $iniciobar = qq|<head><STYLE type=text/css>
				.ti { FONT: 9px Arial, Helvetica, sans-serif }
				.ct { FONT: 9px Arial Narrow; COLOR: navy }
				.cn { FONT: 9px Arial; COLOR: black }
				.cp { FONT: bold 11px Arial; COLOR: black }
				.ld { FONT: bold 15px Arial; COLOR: #000000 }
				.bc { FONT: bold 18px Arial; COLOR: #000000 }
				</STYLE>
				</head>

				<img src="$imgbase/2.gif" width="$fino" height="$altura" border=0><img
				src="$imgbase/1.gif" width="$fino" height="$altura" border=0><img
				src="$imgbase/2.gif" width="$fino" height="$altura" border=0><img
				src="$imgbase/1.gif" width="$fino" height="$altura" border=0><img|; 

	my $texto = $valor;
	$texto = "0" . $texto if length($texto) % 2 ne 0;

	#Draw dos dados
	my $meiobar;
	while (length($texto) > 0){
	  my $i = int(substr($texto,0,2));
	  $texto = substr($texto,2,length($texto)-2);
	  my $f = $BarCodes[$i];
	  my $a=0;
	  while ($a<10){
	  	my $f1;
		if (substr($f,$a,1) eq "0"){
	      $f1 = $fino;
	    }else{
	      $f1 = $largo;
	    }
	    $meiobar .= qq| src="$imgbase/2.gif" width="$f1" height="$altura" border=0><img|;
		$a++;
		my $f2;
	    if (substr($f,$a,1) eq "0"){
	      $f2 = $fino;
	    }else{
	      $f2 = $largo;
	    }
	    $meiobar .= qq| src="$imgbase/1.gif" width="$f2" height="$altura" border=0><img|;
		$a++;
	  }
	}

	#Draw guarda final
	my $fimbar = qq| src="$imgbase/2.gif" width="$largo" height="$altura" border=0><img 
				src="$imgbase/1.gif" width="$fino" height="$altura" border=0><img 
				src="$imgbase/2.gif" width="$fino" height="$altura" border=0>|;
				
	return $iniciobar.$meiobar.$fimbar;
}


sub check_account {
	my $self = shift;
 	my $banco = shift;
 	my $ag = shift;
 	my $conta = shift;

	
	foreach my $actid ($self->accounts) {
		$self->actid($actid);
	   	return 1 if "$ag-$conta" eq int($self->account('agencia'))."-".int($self->account('conta'));
		return 1 if "$ag-$conta" eq "24-".int($self->account('convenio')) && $banco == 104; #24 é modalidade sem cobrança da caixa e emedito pelo cliente
	} 

	return 0;
}

sub check_account_invoice {
	my $self = shift;
 	my $banco = shift;
 	my $ag = shift;
 	my $conta = shift;
	
	local $Controller::SWITCH{skip_error} = 1;
	
	return 0 unless ($self->invid && $self->invoice('conta'));
	$self->actid($self->invoice('conta'));

   	return 1 if "$ag-$conta" eq int($self->account('agencia'))."-".int($self->account('conta'));
	return 1 if "$ag-$conta" eq "24-".int($self->account('convenio')) && $banco == 104; #24 é modalidade sem cobrança da caixa e emedito pelo cliente 

	return 0;
} 

sub cnab_ret { #Processa o arquivo de retorno
	my $self = shift;
	my $file = shift;
	my $process = 0;
	
	my $path = $self->setting('file_path').'/tmp';
	my $file_path = "$path/ctrl_$file";	
	open(HANDLE, "<$file_path") || die $self->lang(17,$file_path,$!);
	
	my (@checkbx,@val,@valtotal,@pagamento,@invalidos,@tarifas);
	if ($file =~ /\.bbt$/i) {
		while (<HANDLE>) {
			my @tmp = split(/\;/, $_);
			#verifica agência e conta
			$process = 1 if $tmp[0] && $self->check_account('001',int($tmp[0]),int($tmp[1]));
			if ($process == 1) {
				$process = 0;
				my $pg = $tmp[8];
				$pg =~ s/(..)(..)(....)/$3\-$2\-$1/;
				my $num = int($tmp[11]);
				$num =~ s/(\d\d$)/\.$1/;
				$self->invid(int(substr(substr($tmp[4],-11), 0, 10)));
				$self->tid($self->invoice('tarifa'));
				push @invalidos, $self->check_account_invoice('001',int($tmp[0]),int($tmp[1])) && $self->is_boleto_module($self->tax('modulo')) ? 0 : 1;
				push @checkbx, $self->invid;
				push @val, $num;
				push @pagamento, $pg;
				my $num2 = int($tmp[14]);
				$num2 =~ s/(\d\d$)/\.$1/;
				push @tarifas, $num2; 
			}
		}		
	} else { #if ($file =~ /\.ret$|\.txt$/i) {
		my ($pos,$banco);
		my $pre = substr($self->today()->year,0,2);
		my $posicoes400 = { "356" => [[18,4],[23,7],[46,13],[0,13]],
						 "001" => "",
						 "341" => [
						 			[17,4], #Agencia
						 			[23,5], #Conta
						 			[62,8], #Nossonumero
						 			[0,8] #Tamanho nossonumero sem digito
						 		],
						 "033" => [
						 			[17,4],	[21,8],  #Cada Segmento Agencia / Conta
						 			[62,8], [0,7]  #Cada Segmento Nossonumero / Tamanho nossonumero sem digito
						 		],						 		
						};
		my $posicoes240 = { "356" => [[18,4],[28,7],[44,13],[0,13],[198,15]],
						 "001" => "",
						 "104" => [
						 			[39,2], #Modalidade Nosso Número
						 			[23,6], #Convenio
						 			[41,15], #Nossonumero
						 			[1,14], #Tamanho do nossonumero, tiranto prefixo 9
						 			[198,15] ], #Tarifa
						 '033' => [ [17,4], [22,9], #Segmento T   Agencia / Conta
						 			[40,13], [0,12],  #Segmento T  Nossonumero / Substr range
						 			[193,15] ], #Segmento T  Tarifa
#						 '399'
						};						
		my @lines = <HANDLE>;
		my $line = 1; my $reg;			
		foreach (@lines) {
			last if $self->error;
			s/(\n|\r)*$//;
			$pos = (length $_) if !$pos;
			if ($pos == 400) {
				if ($line == 1) {
					$self->set_error($self->lang(2300)) if substr($_,1,1) != 2;
					$banco = substr($_,76,3);
					$self->set_error($self->lang(2301,$banco)) unless $posicoes400->{$banco};
				} else {
					#verifica agência e conta
					$process = 1;
					$process = 0 if $line == @lines;
					if ($process == 1) {
						$process = 0;
						$self->invid(int(substr(substr($_,$posicoes400->{$banco}[2][0],$posicoes400->{$banco}[2][1]), $posicoes400->{$banco}[3][0], $posicoes400->{$banco}[3][1])));
						$self->tid($self->invoice('tarifa'));
						push @invalidos, $self->check_account_invoice($banco,int(substr($_,$posicoes400->{$banco}[0][0],$posicoes400->{$banco}[0][1])),int(substr($_,$posicoes400->{$banco}[1][0],$posicoes400->{$banco}[1][1]))) 
											&& $self->is_boleto_module($self->tax('modulo')) ? 0 : 1;
						push @checkbx, $self->invid;
						my $pg = substr($_,110,6);
						$pg =~ s/(..)(..)(..)/$pre$3\-$2\-$1/;
						my $num = int(substr($_,253,13)) - int(substr($_,175,13));
						$num = &string(3 - length($num),0).$num; 
						$num =~ s/(\d\d$)/\.$1/;
						my $total = int(substr($_,152,13)) + int(substr($_,266,13)); #Total nominal + Juros, ITAU CNAB 400 valor liquido + juros
						$total = &string(3 - length($total),0).$total;
						$total =~ s/(\d\d$)/\.$1/;						
						push @val, $num;
						push @pagamento, $pg;
						push @valtotal, $total;
						my $num2 = int(substr($_,175,13));
						$num2 = &string(3 - length($num2),0).$num2; 
						$num2 =~ s/(\d\d$)/\.$1/;
						push @tarifas, $num2; 
					}
				}
				$line++;
			} elsif ($pos == 240) {
				if ($line <= 2) {
					$self->set_error($self->lang(2300)) if $line == 1 && substr($_,142,1) != 2; 
					$banco = substr($_,0,3);
					$self->set_error($self->lang(2301,$banco)) unless $posicoes240->{$banco};
				} else {
					#verifica agência e conta					
					$process = 1 if $process == 0;
					$process = 0 if $line >= @lines - 1; #duas linhas					
					if ($process == 1) {
						#arquivo tem que estar em sequencia
						$seg = substr($_,13,1);
						if ($seg eq 'T' && !(defined $reg)) {
							$self->invid(int(substr(substr($_,$posicoes240->{$banco}[2][0],$posicoes240->{$banco}[2][1]), $posicoes240->{$banco}[3][0], $posicoes240->{$banco}[3][1])));
							$self->tid($self->invoice('tarifa'));
							push @invalidos, $self->check_account_invoice($banco,int(substr($_,$posicoes240->{$banco}[0][0],$posicoes240->{$banco}[0][1])),int(substr($_,$posicoes240->{$banco}[1][0],$posicoes240->{$banco}[1][1]))) 
												&& $self->is_boleto_module($self->tax('modulo')) ? 0 : 1;
							push @checkbx, $self->invid;
							$reg = substr($_,8,5);	
							my $num2 = int(substr($_,$posicoes240->{$banco}[4][0],$posicoes240->{$banco}[4][1]));
							$num2 = &string(3 - length($num2),0).$num2; 
							$num2 =~ s/(\d\d$)/\.$1/;
							push @tarifas, $num2;
						} elsif ($seg eq 'U' && $reg+1 == int(substr($_,8,5))) {
							$process = 0;
							$reg = undef;
							my $pg = substr($_,145,8);
							$pg =~ s/(..)(..)(....)/$3\-$2\-$1/;
							my $num = int(substr($_,92,15));
							$num = &string(3 - length($num),0).$num; 
							$num =~ s/(\d\d$)/\.$1/;
							push @val, $num;
							push @pagamento, $pg;
							my $total = int(substr($_,77,15));
							$total = &string(3 - length($total),0).$total;
							$total =~ s/(\d\d$)/\.$1/;						
							push @valtotal, $total;
						} elsif (defined $reg) { #Passou no T antes, esse tem que ser U em sequência, como não está, desfazer T
							pop @checkbx;
							pop @invalidos;
							pop @tarifas;
							$reg=undef;							
						}
					}
				}
				$line++;				
			}
		}
	}
	close(HANDLE);
	
	$self->set_error($self->lang(2300)) unless scalar @checkbx;
	return (\@checkbx,\@val,\@pagamento,\@valtotal,\@invalidos,\@tarifas);
}
 
sub parse {
	my ($self, $tpl) = @_;
	require CGI;
	my $q = CGI->new();
	
	my $file = $self->skin('data_tpl').$tpl.'.tpl';

	print $q->header(-type => "text/html",-charset => $self->setting('iso'));
	
	if (-e $file) {
		open TPL, "$file" || $self->die_nice($self->lang(15,$self->skin('name'),$file,$!));
			while (<TPL>) {                       
				$self->template_parse('text/plain'); #Os template do código de barras já está em html.
				$self->lang_parse;
				print;
			}
		close TPL;        
	} else {
		print '<h1>'.$self->lang(15,$self->skin('name'),$file,$self->lang('notfound')).'</h1>';    
	}
	
	exit(0);#Success	
}
1;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "DTD/xhtml1-transitional.dtd">
<html>
<head>
<title>Controller | Boleto via web</title>
<meta name="description" content="Imprima boletos banc&aacute;rios pela Internet. Cobran&ccedil;a online com impress&atilde;o do c&oacute;digo de barras. Usado para vendas em geral, ingresso para feiras, congressos, conven&ccedil;&otilde;es ou eventos. Administra&ccedil;&atilde;o pelo navegador">
<meta name="keywords" content="banco, dinheiro, pagamento, impress&atilde;o, direta, cedente, sacado, vencimento, boleto">
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
</head>
<body bgcolor="#FFFFFF" leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<table width="100%" border="0" cellspacing="0" cellpadding="2">
  <tr> 
    <td valign="top" width="34%"></td>
    <td valign="middle" align="center" width="66%"><font size="2"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Imprima 
      este boleto em qualidade m&eacute;dia de sua impressora Jato de Tinta ou 
      Laser. Utilize papel carta ou A4.</font><b><font face="Verdana, Arial, Helvetica, sans-serif"><a href="#" onClick='x86()'><br>
      Imprimir este boleto</a></font></b></font></td>
  </tr>
</table>
<table width="100%" border="0" cellspacing="0" cellpadding="4">
  <tr valign="top"> 
    <td width="66%"> 
      <div align="left"> 
        <font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
        <table width='640' border='0' cellspacing='0' cellpadding='1'>
          <tr> 
            <td valign='top' width='250'> <table width='250' border='0' cellspacing='0' cellpadding='0'>
                <tr> 
                  <td width='175'><img src='{url_tpl}/images/logo_409.gif' width='175' height='30'></td>
                  <td width='10'> <div align='center'><img src='{url_tpl}/images/separador.gif' width='5' height='30'></div></td>
                  <td width='79'> <div align='center'><img src='{url_tpl}/images/numero_409.gif' width='63' height='30'></div></td>
                  <td width='7'> <div align='center'><img src='{url_tpl}/images/separador.gif' width='5' height='30'></div></td>
                </tr>
              </table></td>
            <td valign='bottom' width='397' align='right'><b><font face='Arial, Helvetica, sans-serif' size='2'> 
              {linhadigitavel} </font></b></td>
          </tr>
        </table>
        <table width='640' border='1' cellspacing='0' cellpadding='2'>
          <tr valign='top'> 
            <td colspan='5'><font face='Arial, Helvetica, sans-serif' size='1'>CEDENTE<br>
              </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
              {cedente} </font></b></td>
            <td width='138'><font face='Arial, Helvetica, sans-serif' size='1'>VENCIMENTO<br>
              </font> <div align='right'> <b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                {vencimento} </font></b></div></td>
          </tr>
          <tr valign='top'> 
            <td width='100'><font size='1' face='Arial, Helvetica, sans-serif'>DATA 
              DOCUMENTO<br>
              </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
              {datadoc}</font></b></td>
            <td width='109'><font size='1' face='Arial, Helvetica, sans-serif'>NUM 
              DO DOC<br>
              </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
              {numerodoc}</font></b></td>
            <td width='79'><font size='1' face='Arial, Helvetica, sans-serif'>ESPECIE 
              DOC<br>
              </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
              Duplicata</font></b></td>
            <td width='75'><font size='1' face='Arial, Helvetica, sans-serif'>ACEITE<br>
              </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
              Sim</font></b></td>
            <td width='101'><font size='1' face='Arial, Helvetica, sans-serif'>DATA 
              PROCES.<br>
              </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
              {datadoc}</font></b></td>
            <td width='138'><font face='Arial, Helvetica, sans-serif' size='1'>AGENCIA 
                / COD. CEDENTE</font> 
              <div align='right'> <font face='Verdana, Arial, Helvetica, sans-serif'><b> 
                <font size='1'>{agencia}/{conta}-{dvconta}</font></b></font></div></td>
          </tr>
          <tr valign='top'> 
            <td width='100'><font face='Arial, Helvetica, sans-serif' size='1'>USO 
              DO BANCO </font></td>
            <td width='109'><font size='1' face='Arial, Helvetica, sans-serif'>CARTEIRA<br>
              </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
              {carteira}</font></b></td>
            <td width='79'><font face='Arial, Helvetica, sans-serif' size='1'>ESP&Eacute;CIE<br>
              </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
              {especie}</font></b></td>
            <td width='75'><font size='1' face='Arial, Helvetica, sans-serif'>QUANTIDADE</font></td>
            <td width='101'><font size='1' face='Arial, Helvetica, sans-serif'>VALOR</font></td>
            <td width='138'><font face='Arial, Helvetica, sans-serif' size='1'>NOSSO 
              N&Uacute;MERO<br>
              </font><font face='Arial, Helvetica, sans-serif' size='1'> 
              <div align='right'> <font face='Verdana, Arial, Helvetica, sans-serif'><b> 
                {nossonum}-{dvnosso}</b></font></div>
              </font></td>
          </tr>
          <tr valign='top'> 
            <td colspan='2'><font face='Arial, Helvetica, sans-serif' size='1'>(=)VALOR 
              DOCUMENTO<br>
              </font><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>&nbsp; 
              </font><font face='Arial, Helvetica, sans-serif' size='1'> 
              <div align='right'> <font face='Verdana, Arial, Helvetica, sans-serif'><b> 
                {valor}</b></font></div>
              </font></td>
            <td colspan='2'><font face='Arial, Helvetica, sans-serif' size='1'>(-)DESCONTO</font></td>
            <td width='101'><font face='Arial, Helvetica, sans-serif' size='1'>(+)MORA 
              / MULTA</font></td>
            <td width='138'><font face='Arial, Helvetica, sans-serif' size='1'>(=)VALOR 
              COBRADO</font></td>
          </tr>
        </table>
        <table width='640' border='1' cellspacing='0' cellpadding='0'>
          <tr> 
            <td valign='top'> <font size='1' face='Arial, Helvetica, sans-serif'>SACADO</font><br>
                <b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                {sacado} - {cpfcnpj} <br>
                {endereco} - {cep}<br>
                {cidade} - {estado}
                </font></b> </td>
          </tr>
        </table>
        <table width='640' border='0' cellspacing='0' cellpadding='0'>
          <tr> 
            <td width='445'><font face='Arial, Helvetica, sans-serif' size='1'>Recibo 
              do sacado</font></td>
            <td width='195'> <div align='center'><font size='1' face='Arial, Helvetica, sans-serif'>AUTENTICA&Ccedil;&Atilde;O 
                MECANICA </font></div></td>
          </tr>
        </table>
        <br>
        <br>
        <img src='{url_tpl}/images/linha_pontilhada.gif' width='639' height='7'><br>
        <table width='640' border='0' cellspacing='0' cellpadding='1'>
          <tr> 
            <td valign='top' width='250'> <table width='250' border='0' cellspacing='0' cellpadding='0'>
                <tr> 
                  <td width='175'><img src='{url_tpl}/images/logo_409.gif' width='175' height='30'></td>
                  <td width='10'> <div align='center'><img src='{url_tpl}/images/separador.gif' width='5' height='30'></div></td>
                  <td width='79'> <div align='center'><img src='{url_tpl}/images/numero_409.gif' width='63' height='30'></div></td>
                  <td width='7'> <div align='center'><img src='{url_tpl}/images/separador.gif' width='5' height='30'></div></td>
                </tr>
              </table></td>
            <td valign='bottom' width='397' align='right'><b><font face='Arial, Helvetica, sans-serif' size='1'> 
              </font><font face='Arial, Helvetica, sans-serif' size='2'> {linhadigitavel} 
              </font></b></td>
          </tr>
          <tr> 
            <td valign='top' colspan='2'> <table width='640' border='1' cellspacing='0' cellpadding='2'>
                <tr valign='top'> 
                  <td colspan='5'> <font face='Arial, Helvetica, sans-serif' size='1'>LOCAL 
                      DE PAGAMENTO<br>
                      </font> <font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                      <b> Pagável em qualquer banco até o vencimento. <br>
                      Após o vencimento pagável apenas no Banco Unibanco. </b> </font></td>
                  <td width='141' valign='top'> <font face='Arial, Helvetica, sans-serif' size='1'>VENCIMENTO<br>
                    </font> <div align='right'> <b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                      <br />
                      {vencimento} </font></b></div></td>
                </tr>
                <tr valign='top'> 
                  <td colspan='5'><font face='Arial, Helvetica, sans-serif' size='1'>CEDENTE<br>
                    </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                    {cedente}</font></b></td>
                  <td width='141' valign='top'> <font face='Arial, Helvetica, sans-serif' size='1'>AGENCIA 
                      / COD. CEDENTE<br>
                      </font> 
                    <div align='right'><font face='Verdana, Arial, Helvetica, sans-serif'><b><font size='1'> 
                      {agencia}/{conta}-{dvconta}</font></b></font></div></td>
                </tr>
                <tr valign='top'> 
                  <td width='110'><font size='1' face='Arial, Helvetica, sans-serif'>DATA 
                    DOCUMENTO<br>
                    </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                    {datadoc}</font></b></td>
                  <td width='121'><font size='1' face='Arial, Helvetica, sans-serif'>NUM 
                    DO DOC<br>
                    </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                    {numerodoc}</font></b></td>
                  <td width='83'><font size='1' face='Arial, Helvetica, sans-serif'>ESPECIE 
                    DOC<br>
                    </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                    Duplicata</font></b></td>
                  <td width='79'><font size='1' face='Arial, Helvetica, sans-serif'>ACEITE<br>
                    </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                    Sim</font></b></td>
                  <td width='92'><font size='1' face='Arial, Helvetica, sans-serif'>DATA 
                    PROCES.<br>
                    </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                    {datadoc}</font></b></td>
                  <td width='141' valign='top'><font face='Arial, Helvetica, sans-serif' size='1'>NOSSO 
                    N&Uacute;MERO<br>
                    </font><font face='Arial, Helvetica, sans-serif' size='1'> 
                    <div align='right'> <font face='Verdana, Arial, Helvetica, sans-serif'><b> 
                      {nossonum}-{dvnosso}</b></font></div>
                    </font></td>
                </tr>
                <tr valign='top'> 
                  <td width='110'> <font face='Arial, Helvetica, sans-serif' size='1'>USO 
                    DO BANCO </font></td>
                  <td width='121'><font size='1' face='Arial, Helvetica, sans-serif'>CARTEIRA<br>
                    </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                  {carteira}</font></b></td>
                  <td width='83'><font face='Arial, Helvetica, sans-serif' size='1'>ESP&Eacute;CIE<br>
                    </font><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                  {especie}</font></b></td>
                  <td width='79'><font size='1' face='Arial, Helvetica, sans-serif'>QUANTIDADE</font></td>
                  <td width='92'><font size='1' face='Arial, Helvetica, sans-serif'>VALOR</font></td>
                  <td width='141' valign='top'><font face='Arial, Helvetica, sans-serif' size='1'>(=)VALOR 
                    DOCUMENTO<br>
                    </font><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>&nbsp; 
                    </font><font face='Arial, Helvetica, sans-serif' size='1'> 
                    <div align='right'> <font face='Verdana, Arial, Helvetica, sans-serif'><b> 
                      {valor} </b></font></div>
                    </font></td>
                </tr>
                <tr valign='top'> 
                  <td rowspan='5' colspan='5'> <font face='Arial, Helvetica, sans-serif' size='1'>INSTRU&Ccedil;OES 
                      (Todas as informa&ccedil;&otilde;es deste bloqueto s&atilde;o 
                      de exclusiva responsabilidade do cedente)</font><br>
                      <b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                      ###################################################<br />
                      {instrucoes}<br />
                      ###################################################<br>
                      <br />
                      </font></b><b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'>OBS:<br>
                      {obs}</font></b>
                  </td>
                  <td width='141' valign='top'><font face='Arial, Helvetica, sans-serif' size='1'>(-)DESCONTO/ABATIMENTO<br>
                    &nbsp; </font></td>
                </tr>
                <tr> 
                  <td width='141' valign='top'> <div align='left'><font face='Arial, Helvetica, sans-serif' size='1'> 
                      (-)OUTRAS DEDU&Ccedil;&Otilde;ES&nbsp;<br>
                      &nbsp; </font></div></td>
                </tr>
                <tr> 
                  <td width='141' valign='top'><font face='Arial, Helvetica, sans-serif' size='1'>(+)MORA 
                    / MULTA<br>
                    &nbsp; </font></td>
                </tr>
                <tr> 
                  <td width='141' valign='top'> <font face='Arial, Helvetica, sans-serif' size='1'>(+)OUTROS 
                      ACR&Eacute;CIMOS<br>
                      &nbsp; </font></td>
                </tr>
                <tr> 
                  <td width='141' valign='top'><font face='Arial, Helvetica, sans-serif' size='1'>(=)VALOR 
                    COBRADO<br>
                    &nbsp; </font></td>
                </tr>
              </table></td>
          </tr>
          <tr> 
            <td valign='top' colspan='2'> <table width='640' border='1' cellspacing='0' cellpadding='0'>
                <tr> 
                  <td valign='top'> <font size='1' face='Arial, Helvetica, sans-serif'>SACADO</font><br> 
                    <b><font face='Verdana, Arial, Helvetica, sans-serif' size='1'> 
                {sacado} - {cpfcnpj} <br>
                    {endereco} - {cep}<br>
                {cidade} - {estado}
                    </font></b> <table width='100%' border='0' cellspacing='0' cellpadding='0'>
                      <tr> 
                        <td width='482'><font size='1' face='Arial, Helvetica, sans-serif'>SACADOR 
                          / AVALISTA</font></td>
                        <td width='141'> <font size='1' face='Arial, Helvetica, sans-serif'>C&Oacute;DIGO 
                          DE BAIXA</font></td>
                      </tr>
                    </table></td>
                </tr>
              </table></td>
          </tr>
          <tr> 
            <td valign='top' colspan='2'> <table width='640' border='0' cellspacing='0' cellpadding='0'>
                <!--DWLayoutTable-->
                <tr valign='top'> 
                  <td height="12" colspan='2'> <div align='right'><font size='1' face='Arial, Helvetica, sans-serif'>Autentica&ccedil;&atilde;o 
                      mec&acirc;nica - </font><font size='1' face='Verdana, Arial, Helvetica, sans-serif'>FICHA 
                      DE COMPENSA&Ccedil;&Atilde;O</font></div></td>
                </tr>
                <tr valign='top'> 
                  <td width='428' height="18" valign="top"><font face='Arial, Helvetica, sans-serif' size='1'> 
                    {imgcodebar}</font></td>
                  <td width='212'></td>
                </tr>
                <tr valign='top'> 
                  <td height="4"></td>
                  <td></td>
                </tr>
                <tr valign='top'> 
                  <td height="12" colspan='2' valign="top"> <div align='right'><font face='Arial, Helvetica, sans-serif' size='1'><img src='{url_tpl}/images/linha_pontilhada.gif' width='639' height='7'><br>
                      </font></div></td>
                </tr>
              </table></td>
          </tr>
        </table>
        </font> </div>
    </td>
  </tr>
</table>
</body>
</html>
<SCRIPT language=JavaScript>
var da = (document.all) ? 1 : 0;
var pr = (window.print) ? 1 : 0;
var mac = (navigator.userAgent.indexOf("Mac") != -1); 

function x86(){
if (pr) // NS4, IE5
window.print()
else if (da && !mac) // IE4 (Windows)
vbx86()
else // outros browsers
alert("Desculpe seu browser não suporta esta função. Por favor utilize a barra de trabalho para imprimir a página.");
return false;}
if (da && !pr && !mac) with (document) {
writeln('<OBJECT ID="WB" WIDTH="0" HEIGHT="0" CLASSID="clsid:8856F961-340A-11D0-A96B-00C04FD705A2"></OBJECT>');
writeln('<' + 'SCRIPT LANGUAGE="VBScript">');
writeln('Sub window_onunload');
writeln('  On Error Resume Next');
writeln('  Set WB = nothing');
writeln('End Sub');
writeln('Sub vbx86');
writeln('  OLECMDID_PRINT = 6');
writeln('  OLECMDEXECOPT_DONTPROMPTUSER = 2');
writeln('  OLECMDEXECOPT_PROMPTUSER = 1');
writeln('  On Error Resume Next');
writeln('  WB.ExecWB OLECMDID_PRINT, OLECMDEXECOPT_DONTPROMPTUSER');
writeln('End Sub');
writeln('<' + '/SCRIPT>');}
</SCRIPT>
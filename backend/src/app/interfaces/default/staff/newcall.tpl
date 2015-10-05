<script language="JavaScript">
<!--
function MM_jumpMenu(targ,selObj,restore){ //v3.0
 /* Old
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
 */
 var comment = document.getElementById('description');
 if (comment.value != "") {
 	comment.value = comment.value + ' ' + selObj.options[selObj.selectedIndex].value;
 } else {
	 comment.value = selObj.options[selObj.selectedIndex].value;
 }
 if (restore) selObj.selectedIndex=0;
}
//-->
</script><style type="text/css">
<!--
-->
</style>

<form action="staff.cgi" method="post">
    
  <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
    <tr> 
      <td width="22%"> 
      <td width="78%" colspan="2"> 
    <tr> 
      <td colspan="5"> </td>
    </tr>
    <tr valign="middle">
      <td valign="top"> <table width="145" border="0" align="right" cellpadding="4" cellspacing="0">
          <tr> 
            <td width="53"> <div align="center"><strong><img src="{imgbase}/icons/ticket3.jpg" border="0"></strong></div></td>
            <td width="107" valign="top"><br>
              TICKETS</td>
          </tr>
          <tr> 
            <td colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
          <tr> 
            <td colspan="2">Nesta se&ccedil;&atilde;o voc&ecirc; pode criar pedidos e enviar e-mails.<br>
              <br>
            Para enviar um e-mail, deixe o campo username em branco e preencha somente o campo<br>            &quot;E-mail do Contato&quot; </td>
          </tr>
          <tr> 
            <td height="27" colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
        </table>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p></td>
      <td height="42" colspan="2" valign="top">
<table width="95%" border="0" align="center">
          <tr> 
            <td> 
          <tr> 
            <td colspan="3"> </td>
          </tr>
          <tr valign="middle"> 
            <td height="42"> <table width="90%" border="1" cellspacing="0" cellpadding="3" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
              <tr>
                <td width="19%">M&eacute;todo de Suporte</td>
                <td width="72%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">
                  <select name="metodo" style="font-size: 12px">
                    <option value="em">E-mail</option>
                    <option value="cc" selected>Telefone</option>
                    <option value="hd">HelpDesk</option>
                  </select>
                </font></td>
              </tr>
              <tr>
                <td valign="middle">Submi&ccedil;&atilde;o de E-mail </td>
                <td>
                  <input checked="checked" name="email_user" type="radio" value="s">
                  Sim
                  <input name="email_user" type="radio" value="n">
                  N&atilde;o</td>
              </tr>
              </table>
              &nbsp; 
              <table width="90%" border="1" cellspacing="0" cellpadding="3" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                <tr>
                  <td>Username<span style="font-size: x-small; font-style: italic;"> (Ou)</span></td>
                  <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">
                    <input type="text" style="font-size: 12px" name="username" size="30" value="{username}">
    (<a href="staff.cgi?do=lookup"><font size="1">Procurar Username</font></a>) </font></td>
                </tr>
                <tr>
                  <td>Servi&ccedil;o <span style="font-size: x-small; font-style: italic;">(Ou)</span></td>
                  <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">
                    <input type="text" style="font-size: 12px" name="service" size="30" value="{service}">
    (<a href="staff.cgi?do=lookup&area=serv"><font size="1">Procurar Servi&ccedil;o e Username </font></a>)</font></td>
                </tr>
                <tr> 
                  <td width="19%"> Email de Contato</td>
                  <td width="72%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                    <input name="email" type="text" id="email" style="font-size: 12px" value="{email}" size="30">
(<a href="staff.cgi?do=lookup&area=mail"><font size="1">Procurar E-mail </font></a>) </font></td>
                </tr>
              </table>
              <font size="2" face="Verdana, Arial, Helvetica, sans-serif"><br>
              </font>              <table width="90%" border="1" cellspacing="0" cellpadding="3" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                <tr>
                  <td height="5">Departamento</td>
                  <td height="5"><select name="category" style="font-size: 12px">
                    
                    
                {category}
              
                
                
                  
                  </select></td>
                </tr>
                <tr>
                  <td height="5">Empresa</td>
                  <td height="5"><select name="level" style="font-size: 10px">
                    
                    <option value=""></option>
                    
                {level}
              
                
                
                  
                  
                  </select>
                    <span style="font-size: x-small; font-style: italic;">(Opcional para usu&aacute;rios cadastrados)</span></td>
                </tr>
                <tr> 
                  <td width="25%" height="2">N&iacute;vel</td>
                  <td width="72%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                    <select name="priority" style="font-size: 12px">
                      <option value="1"  selected>1</option>
                      <option value="2">2</option>
                      <option value="3">3</option>
                      <option value="4">4</option>
                      <option value="5">5</option>
                    </select>
                    </font> </td>
                </tr>
                <tr> 
                  <td height="2">Status</td>
                  <td height="2"><select name="status" class="gbox" id="status">
                      <option value="F">Fechado</option>
                      <option value="A" selected>Aberto</option>
                      <option value="H">Aguardando</option>
                    </select></td>
                </tr>
                <tr> 
                  <td width="25%" height="2">Assunto</td>
                  <td width="72%" height="2"> <input type="text" name="subject" style="font-size: 12px" size="40">                  </td>
                </tr>
 <tr> 
                  <td width="25%" height="2"> 
                    <font size="1" face="Verdana, Arial, Helvetica, sans-serif">Respostas Pr&eacute;-definidas </font>
                  </td>
                    <td width="72%" height="2"> 
                      <select name="menu" onChange="MM_jumpMenu('parent',this,1)" class="tbox">
                        <option value="" selected>--- Templates ---</option>
                     {preans} </select>
                    </td>
                  </tr>
                <tr> 
                  <td width="25%" valign="top">Mensagem</td>
                  <td width="72%"> <textarea name="description" id="description" style="font-size: 12px" cols="40" rows="12"></textarea>                  </td>
                </tr>
            </table></td>
          </tr>
          <tr valign="middle"> 
            <td height="42"> <div align="center"> 
                <table width="90%" border="0" cellspacing="1" cellpadding="0" align="center">
                  <tr> 
                    <td height="19"> <div align="right"> 
                        <input type="hidden" name="hidden">
                        <input type="hidden" name="do" value="logsave">
                        <input type="image" border="0" name="imageField" src="{imgbase}/log_request.gif">
                      </div></td>
                  </tr>
                </table>
              </div></td>
          </tr>
          <tr> 
            <td>&nbsp;</td>
          </tr>
        </table> </td>
    </tr>
    <tr valign="middle"> 
      <td><p>&nbsp;</p>
        </td>
      <td colspan="2" height="42">&nbsp;</td>
    </tr>
    <tr> 
      <td>&nbsp;</td>
      <td colspan="2">&nbsp;</td>
    </tr>
  </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

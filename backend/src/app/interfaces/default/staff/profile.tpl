<script language="JavaScript" type="text/JavaScript">
<!--
function MM_jumpMenu(targ,selObj,restore){ //v3.0
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
}
//-->
</script>

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
            <td width="53"> <div align="center"><strong><img src="{imgbase}/icons/folder1.jpg" border="0"></strong></div></td>
            <td width="107" valign="top"><br>
              PROFILE<br> </td>
          </tr>
          <tr> 
            <td colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
          <tr> 
            <td colspan="2">Aqui voc&ecirc; poder&aacute; alterar seu perfil e configura&ccedil;&otilde;es de STAFF. </td>
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
      <td colspan="2" height="42"> <table width="90%" border="0" align="center" cellpadding="5">
          <!--DWLayoutTable-->
          <tr> 
            <td width="14" height="0"> 
            <td width="100">
            <td width="377"> 
          <tr valign="middle"> 
            <td colspan="3" height="26"><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>{name} 
              - Configura&ccedil;&otilde;es Pessoais</b></font></td>
          </tr>
          <tr valign="middle"> 
            <td height="29">&nbsp;</td>
            <td>&nbsp;</td>
            <td>&nbsp;</td>
          </tr>
          <tr valign="middle"> 
            <td height="29"><img src="{imgbase}/dot.gif" width="13" height="11"></td>
            <td colspan="2"><b><font color="#000066">Respostas Pr&eacute;-Definidas 
              </font></b></td>
          </tr>
          <tr valign="middle"> 
            <td height="37" colspan="3"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Respostas 
              padronizadas salvas para quest&otilde;es frequentes. </font></td>
          </tr>
          <tr> 
            <td height="34" colspan="2" valign="middle"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Templates</font></td>
            <td> <select name="menu" class="gbox" onChange="MM_jumpMenu('parent',this,0)">
                <option value="staff.cgi?do=profile" selected>--- Seus Templates 
                ---</option>
				{preans}
              </select> <font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
              (<a href="staff.cgi?do=profile&goto=add_pre">Adicionar</a>) </font></td>
          </tr>
          <tr> 
            <td colspan="3" valign="top" height="48"><br> <hr size="1"> </td>
          </tr>
          <tr> 
            <td width="4%" valign="middle"><img src="{imgbase}/dot.gif" width="13" height="11"></td>
            <td colspan="2" valign="middle">
<div align="left"><font color="#000066"><strong> Perfil</strong></font></div></td>
          </tr>
          <tr> 
            <td height="31" colspan="2" valign="top">Nome</td>
            <td> <input type="text" style="font-size: 12px" name="name" value="{name}" size="30"> 
            </td>
          </tr>
          <tr> 
            <td height="31" colspan="2" valign="top">E-Mail <br> </td>
            <td valign="top"> <input type="text" style="font-size: 12px" name="email" value="{email}" size="30"> 
            </td>
          </tr>
          <tr> 
            <td height="29" colspan="2" valign="top">Alerta Sonoro </td>
            <td valign="top"> <input name="sound" type="checkbox" id="sound" value="yes" {snd}> 
            </td>
          </tr>
          <tr> 
            <td height="34" valign="top">&nbsp;</td>
            <td valign="top">&nbsp;</td>
            <td valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Isso 
              far&aacute; com que um som toque quando um novo pedido for aberto 
              e a p&aacute;gina Home atualize.</font></td>
          </tr>
          <tr> 
            <td height="41" colspan="2" valign="top">Notifica&ccedil;&atilde;o</td>
            <td valign="top"> <input type="checkbox" name="notify" value="yes" {ncheck}> 
              <br> <font size="1" face="Verdana, Arial, Helvetica, sans-serif">(Notifique-me 
              de novos pedidos por email)</font> </td>
          </tr>
          <tr> 
            <td height="68" colspan="3" valign="top"><br> <hr size="1"> 
              <div align="left"><strong><font color="#000066"><img src="{imgbase}/dot.gif" width="13" height="11"> 
                &nbsp;&nbsp; Senha</font></strong><br>
              </div></td>
          </tr>
          <tr> 
            <td height="34" colspan="3" valign="top">Deixe este campo em branco 
              para n&atilde;o alterar sua senha.</td>
          </tr>
          <tr> 
            <td height="31" colspan="2" valign="top">Senha</td>
            <td> <input type="password" style="font-size: 12px" name="pass1"> 
            </td>
          </tr>
          <tr> 
            <td height="31" colspan="2" valign="top">Senha</td>
            <td> <input type="password" style="font-size: 12px" name="pass2"> 
            </td>
          </tr>
          <tr> 
            <td height="203" colspan="3" valign="top"> <br> <hr size="1"> <br> 
              <table width="100%" border="0" cellpadding="2" cellspacing="1">
                <tr> 
                  <td height="27" colspan="2"><b><font color="#000066"><strong><font color="#000066"><img src="{imgbase}/dot.gif" width="13" height="11"></font></strong>&nbsp;&nbsp; 
                    Assinatura</font></b></td>
                </tr>
                <tr> 
                  <td width="29%" height="22" rowspan="2" valign="top">Sua Assinatura:<br> 
                    <font size="1" face="Verdana, Arial, Helvetica, sans-serif">(Ser&aacute; 
                    adicionada &agrave;s respostas)</font></td>
                  <td rowspan="2" width="71%"> <div align="center"> 
                      <textarea class="gbox" name="sig" cols="40" rows="5">{sig}</textarea>
                    </div></td>
                </tr>
                <tr> </tr>
              </table></td>
          </tr>
          <tr> 
            <td height="29" valign="top">&nbsp; </td>
            <td valign="top">&nbsp;</td>
            <td valign="top">&nbsp;</td>
          </tr>
          <tr valign="middle"> 
            <td colspan="3" height="42"> <div align="center"> 
                <input type="hidden" name="hidden">
                <input type="hidden" name="do" value="profile">
                <input type="hidden" name="goto" value="updateprofile">
                <input type="submit" name="Submit2" value="Submit">
              </div></td>
          </tr>
          <tr> 
            <td height="29">&nbsp;</td>
            <td>&nbsp;</td>
            <td>&nbsp;</td>
          </tr>
        </table></td>
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

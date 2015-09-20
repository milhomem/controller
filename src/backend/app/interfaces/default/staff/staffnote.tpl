 
<script language="JavaScript">
<!--
function MM_jumpMenu(targ,selObj,restore){ //v3.0
 /* Old
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
 */
 var comment = document.getElementById('comments');
 if (comment.value != "") {
 	comment.value = comment.value + ' ' + selObj.options[selObj.selectedIndex].value;
 } else {
	 comment.value = selObj.options[selObj.selectedIndex].value;
 }
 if (restore) selObj.selectedIndex=0;
}
//-->
</script>


<form action="staff.cgi" method="post" enctype="multipart/form-data">
  <table width="85%" border="0" cellspacing="0" align="center" cellpadding="0">
    <tr> 
      <td colspan="4"> 
        
      </td>
    </tr>
    <tr> 
      <td colspan="4">  
        <font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp;        </font>        <div align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>{aviso}</strong></font></div>        
        <font size="2">
        <div align="center"><font face="Verdana, Arial, Helvetica, sans-serif"><br>
        </font></div>
        </font>	
        <div align="center">
          <table width="100%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
            <tr>
              <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">ID DO TICKET </font></td>
              <td height="2"><a href="?do=ticket&amp;cid={trackno}"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{trackno}</font></a></td>
            </tr>
            <tr>
              <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">STATUS ATUAL </font></td>
              <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{status}</font></td>
            </tr>
            <tr>
              <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">DEPARTAMENTO</font></td>
              <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{category} </font></td>
            </tr>
            <tr>
              <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">N&Iacute;VEL</font></td>
              <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{priority} </font></td>
            </tr>
            <tr> 
              <td width="46%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">STATUS 
                </font></td>
              <td width="54%" height="2"> 
                <font size="2" face="Verdana, Arial, Helvetica, sans-serif">
                <select name="newstatus" class="gbox">
                  <option value="Resolved">Fechado</option>
                  <option value="Unresolved" selected>Aberto</option>
                  <option value="Hold">Em Andamento</option>
                </select>
                </font></td>
            </tr>
            <tr> 
              <td width="46%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">RESPOSTA PRIVADA AOS STAFFS </font></td>
              <td width="54%"> 
                <font size="2" face="Verdana, Arial, Helvetica, sans-serif">
                <select name="private" class="gbox">
                  <option value="Yes">Sim</option>
                  <option value="No" selected>Não</option>
                </select>
                </font></td>
            </tr>
            <tr> 
              <td width="46%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">E-MAIL CC</font> </td>
              <td width="54%"> 
                <font size="2" face="Verdana, Arial, Helvetica, sans-serif">
                <input type="text" name="cc" class="gbox" size="30">
                </font></td>
            </tr>
            <tr>
              <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">TEMPO UTILIZADO </font></td>
              <td>
                <font size="2" face="Verdana, Arial, Helvetica, sans-serif">
                <input type="text" name="time" class="gbox" size="8">
                (mins) </font></td>
            </tr>
            <tr>
              <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">MODO DE ATENDIMENTO </font></td>
              <td>
                <font size="2" face="Verdana, Arial, Helvetica, sans-serif"> {modo} &nbsp;</font></td>
            </tr>
          </table>
        </div> 
        <table width="90%" border="0" align="center">
          <tr> 
            <td colspan="2" valign="top"><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><font size="1">Respostar privadas s&atilde;o vistas somente pelos STAFFs </font></font></td>
          </tr>
          <tr> 
            <td width="40%" valign="top">&nbsp;</td>
            <td width="60%">&nbsp;</td>
          </tr>
          <tr valign="middle"> 
            <td colspan="2" height="173"> 
              <div align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                <table width="100%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                  <tr> 
                    <td width="63%" height="2"> 
                      <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">RESPOSTAS PR&Eacute; DEFINIDAS </font></div>
                    </td>
                    <td width="37%" height="2"> 
                      <select name="menu" onChange="MM_jumpMenu('parent',this,1)" class="tbox">
                        <option value="" selected>--- Templates ---</option>
                     {preans} </select>
                    </td>
                  </tr>
                </table>
                </font> <br>
                <textarea name="comments" id="comments" cols="90" rows="12" class="gbox">{msg}{ifpre}{sig}</textarea>
                <br>
              </div>
              <div align="right"><font face=Verdana size=1><a href="#" onclick="Popup('staff.cgi?action=history&callid={trackno}', 'Window', 425, 400)">Ver 
                Hist&oacute;ria do Ticket </a><br>
                <br>
              </font></div>
            </td>
          </tr>
          <tr valign="middle"> 
            <td colspan="2" height="39"> <font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
              <table width="100%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                <tr>
                  <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">ARQUIVO</font></td>
                  <td height="2"><input type="file" class="gbox" name="file"></td>
                </tr>
                <tr> 
                  <td width="25%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">NOTIFICAR</font></td>
                  <td width="75%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                    <select name="notify" class="tbox">
                      <option value="Yes">Yes</option>
                      <option value="No">No</option>
                    </select>
                    </font> </td>
                </tr>
                <tr> 
                  <td colspan="2"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Enviar notifica&ccedil;&atilde;o por e-mail ?</font> 
                  </td>
                </tr>
              </table>
              </font> </td>
          </tr>
          <tr valign="middle"> 
            <td colspan="2" height="60"> 
              <div align="center"> 
                <table width="100%" border="0" cellspacing="0" cellpadding="2">
                  <tr> 
                    <td colspan="2" height="8"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                      <table width="100%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                        <tr>
                          <td width="25%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">TOMAR POSSE </font></td>
                          <td width="75%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">
                            <input type="checkbox" name="own" value="1" checked>
                            </font></td>
                        </tr>
                      </table>
                      </font></td>
                  </tr>
                </table>
                <input type="hidden" name="ticket" value="{trackno}">
				<input type="hidden" name="inc" value="{qt}">
                <input type="hidden" name="action" value="submitnote">
                <input type="submit" name="Submit" value="Responder">
              </div>
            </td>
          </tr>
          <tr>
            <td colspan="2">&nbsp;</td>
          </tr>
          <tr>
            <td colspan="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">
              <table width="100%" border="1" cellspacing="0" cellpadding="3" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                <tr>
                  <td height="2">
                    <div align="left"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>Ticket</strong></font></div></td>
                </tr>
                <tr>
                  <td height="2"><font size="2">{description}</font></td>
                </tr>
              </table>
            </font></td>
          </tr>
          <tr>
            <td colspan="2">&nbsp;</td>
          </tr>
          <tr>
            <td colspan="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">
              <table width="100%" border="1" cellspacing="0" cellpadding="3" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                <tr>
                  <td height="2">
                    <div align="left"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>Ultima Resposta</strong></font></div></td>
                </tr>
                <tr>
                  <td height="2"><font size="2"><font face="Verdana, Arial, Helvetica, sans-serif">{lastresp}</font></font></td>
                </tr>
              </table>
            </font></td>
          </tr>
          <tr>
            <td colspan="2">&nbsp;</td>
          </tr>
          <tr>
            <td colspan="2">&nbsp;</td>
          </tr>
      </table>      </td>
    </tr>
  </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

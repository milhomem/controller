 <script language="JavaScript" type="text/JavaScript">
<!--
function MM_jumpMenu(targ,selObj,restore){ //v3.0
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
}
//-->
</script>


<form action="staff.cgi" method="post">
    
  <table width="100%" border="0" align="center">
    <tr> 
      <td width="22%"> 
      <td width="78%" colspan="2"> 
    <tr> 
      <td colspan="5"> </td>
    </tr>
    <tr valign="middle">
      <td valign="top"> <table width="145" border="0" align="right" cellpadding="4" cellspacing="0">
          <tr> 
            <td width="53"> <div align="center"><strong><img src="{imgbase}/icons/search.jpg" border="0"></strong></div></td>
            <td width="107" valign="top"><br>
              Search<br> </td>
          </tr>
          <tr> 
            <td colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
          <tr> 
            <td colspan="2">Utilize esta ferramenta para pesquisar pedidos com os campos selecionados. </td>
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
        <p>&nbsp;</p>
        </td>
      <td height="42" colspan="2" valign="top"> 
        <table width="95%" border="0" align="center">
          <tr> 
            <td><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>Search 
              Requests</b></font></td>
          </tr>
          <tr> 
            <td><br>
            </td>
          </tr>
          <tr valign="middle"> 
            <td height="42"> <div align="center"> <font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                </font> 
                <table width="90%" border="0" cellspacing="0" cellpadding="2">
                  <tr> 
                    <td>Owner</td>
                    <td><select name="menu" class="gbox" onChange="MM_jumpMenu('parent',this,0)">
                        <option selected>Ver tickets por Ownership</option>
						{staff}
                      </select></td>
                  </tr>
                  <tr> 
                    <td>&nbsp;</td>
                    <td>&nbsp;</td>
                  </tr>
                  <tr> 
                    <td colspan="2"><hr size="1"></td>
                  </tr>
                  <tr> 
                    <td>&nbsp;</td>
                    <td>&nbsp;</td>
                  </tr>
                  <tr> 
                    <td width="27%">Palavra</td>
                    <td width="73%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                      <input type="text" class="gbox" name="query" size="30">
                      </font></td>
                  </tr>
                  <tr> 
                    <td width="27%">Campo</td>
                    <td width="73%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                      <select class="gbox" name="select">
                        <option value="id">Call ID</option>
                        <option value="Username">Usuário</option>
                        <option value="email">Email do Remetente</option>
                        <option value="subject">Assunto</option>
                        <option value="priority">Prioridade</option>
                        <option value="description">Texto</option>
                      </select>
                      </font></td>
                  </tr>
                  <tr> 
                    <td colspan="2">&nbsp;</td>
                  </tr>
                  <tr> 
                    <td>Resultados<font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp;</font></td>
                    <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                      <select class="gbox" name="pae">
                        <option value="10">10</option>
                        <option value="20">20</option>
                        <option value="30">30</option>
                        <option value="50">50</option>
                      </select>
                      </font></td>
                  </tr>
                  <tr> 
                    <td colspan="2"> <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=#000000> 
                        <input type="image" border="0" name="imageField" src="{imgbase}/search_button.gif">
                        </font></div></td>
                  </tr>
                  <tr> 
                    <td colspan="2">&nbsp;</td>
                  </tr>
                  <tr> 
                    <td colspan="2"><div align="right"> </div></td>
                  </tr>
                </table>
                <font size="2" face="Verdana, Arial, Helvetica, sans-serif"> </font></div></td>
          </tr>
          <tr valign="middle"> 
            <td height="42"> <div align="center"> 
                <input type="hidden" name="do" value="sresults">
              </div></td>
          </tr>
          <tr> 
            <td>&nbsp;</td>
          </tr>
        </table></td>
    </tr>
    <tr valign="middle"> 
      <td><p>&nbsp;</p>
        <p>&nbsp;</p></td>
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

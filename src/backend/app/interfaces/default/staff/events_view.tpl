
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
              EVENTS<br> </td>
          </tr>
          <tr> 
            <td colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
          <tr> 
            <td colspan="2">Aqui voc&ecirc; poder&aacute; manter informados todos os operadores dos &uacute;ltimos acontecimentos. </td>
          </tr>
          <tr> 
            <td height="27" colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
        </table>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>        </td>
      <td colspan="2" height="42"> <table width="95%" border="1" cellspacing="0" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC" cellpadding="7">
<tr bgcolor="#DBDBDB"><td><div align="center"><b><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="#333333">{id}</font></b></div></td>
</tr><tr><td> <table width="100%" height="125" border="0" cellpadding="3">
  <tr> <td height="90"><div align="center">
    <p><br>
      {desc}
        <br>
        <br>
        <input type="hidden" name="do"  value="eventsave" >
        <input type="hidden" name="id"  value="{id}" >
        <input type="submit" name="Submit" value="Alterar">
            </p>
    </div></td>
</tr></table></table>
        <div align="center"><font size="1"><br>
        <a href=staff.cgi?do=eventsrem&id={id}>[ REMOVER ]</a></font></div></td>
    </tr>
    <tr> 
      <td>&nbsp;</td>
      <td colspan="2">&nbsp;</td>
    </tr>
  </table>
</form>
<p>&nbsp;</p>

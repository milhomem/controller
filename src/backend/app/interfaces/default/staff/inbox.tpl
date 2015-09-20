<html><head><title>Instant Messanger</title>
</head><body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">

<form action="staff_log.pl?users" method="post">
  <tr> 
    <table width="100%" border="0" cellpadding="0" cellspacing="0" align="center">
      <tr> 
        <td colspan="2"> 
      <tr> 
        <td colspan="2" class ="toptab" height="29"> 
          <div align="center"><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>INSTANT 
            MESSENGER: INBOX</b></font></div>
        </td>
      </tr>
      <tr bgcolor="#333333"> 
        <td colspan="2" height="2"></td>
      </tr>
      <tr> 
        <td colspan="2">&nbsp;</td>
      </tr>
      <tr valign="middle"> 
        <td colspan="2" height="2"> 
          <table width="95%" border="0" cellspacing="0" cellpadding="0" align="center">
            <tr bgcolor="#778899"> 
              <td> 
                <table width="100%" border="0" cellspacing="1" cellpadding="3">
                  <tr bgcolor="#E1E0ED"> 
                    <td width="7%"><font size="1"><b><font face="Verdana, Arial, Helvetica, sans-serif">ID</font></b></font></td>
                    <td width="26%"><font size="1"><b><font face="Verdana, Arial, Helvetica, sans-serif">From</font></b></font></td>
                    <td width="28%"><font size="1"><b><font face="Verdana, Arial, Helvetica, sans-serif">Date</font></b></font></td>
                    <td width="39%"><font size="1"><b><font face="Verdana, Arial, Helvetica, sans-serif">Subject</font></b></font></td>
                  </tr>
                  {messages} 
                </table>
              </td>
            </tr>
          </table>
        </td>
      </tr>
      <tr valign="middle"> 
        <td colspan="2" height="50"> 
          <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">[ 
            <a href="staff.cgi?do=messanger&to=compose">COMPOSE NEW MESSAGE</a> 
            ]</font></div>
        </td>
      </tr>
      <tr> 
        <td colspan="2">&nbsp;</td>
      </tr>
    </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>
</body>
</html>

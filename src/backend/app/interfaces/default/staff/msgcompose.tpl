<title>Instant Messanger</title>
<body leftmargin="0" topmargin="0" marginwidth="0" marginheight="0">
<form action="staff.cgi" method="post">
  <tr> 
    <table width="100%" border="0" cellpadding="0" cellspacing="0">
      <tr> 
        <td colspan="2"> 
      <tr> 
        <td colspan="2" class ="toptab" height="29"> 
          <div align="center"><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>INSTANT 
            MESSENGER: COMPOSE</b></font></div>
        </td>
      </tr>
      <tr bgcolor="#333333"> 
        <td colspan="2" height="2"></td>
      </tr>
      <tr valign="middle"> 
        <td colspan="2" height="23"> 
          <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">[ 
            <a href="staff.cgi?do=messanger&to=inbox">INBOX</a> ]</font></div><br>
        </td>
      </tr>
      <tr valign="middle"> 
        <td colspan="2" height="50"> 
          <div align="center"> 
            <table width="90%" border="0" cellspacing="0" cellpadding="0">
              <tr bgcolor="#778899"> 
                <td colspan="3" height="66"> 
                  <table width="100%" border="0" cellspacing="1" cellpadding="2">
                    <tr bgcolor="#F1F1F8"> 
                      <td width="22%" bgcolor="#F1F1F8"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">From:</font></td>
                      <td width="78%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">{username}</font></td>
                    </tr>
                    <tr bgcolor="#F1F1F8"> 
                      <td width="22%" bgcolor="#F1F1F8"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">To:</font></td>
                      <td width="78%"> <font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
                        <select style="font-size: 12px" name="user">{ddlist}</select>
                        (username)</font> </td>
                    </tr>
                    <tr bgcolor="#F1F1F8"> 
                      <td width="22%" bgcolor="#F1F1F8"><font face="Verdana, Arial, Helvetica, sans-serif" size="1">Subject:</font></td>
                      <td width="78%"> <font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
                        <input type="text" style="font-size: 12px" name="subject" size="30">
                        </font></td>
                    </tr>
                    <tr bgcolor="#F1F1F8"> 
                      <td colspan="2" height="52"> 
                        <table width="100%" border="0" cellspacing="1" cellpadding="3">
                          <tr> 
                            <td colspan="2"> 
                              <div align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                                <textarea name="message" style="font-size: 11px" cols="45" rows="15"></textarea>
                                </font></div>
                            </td>
                          </tr>
                        </table>
                      </td>
                    </tr>
                  </table>
                </td>
              </tr>
            </table>
          </div>
        </td>
      </tr>
      <tr> 
        <td colspan="2"> 
          <div align="center"> 

            <input type="hidden" name="to" value="savenote">
            <input type="hidden" name="do" value="messanger">
            <input type="submit" name="Submit" value="Send Message">
          </div>
        </td>
      </tr>
    </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

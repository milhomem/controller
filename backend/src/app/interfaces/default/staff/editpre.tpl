
<form action="staff.cgi" method="post">
  <tr> 
    <table width="100%" border="0">
      <tr> 
        <td colspan="2"> 
      <tr> 
        <td colspan="4"> 
          
        </td>
      </tr>
      <tr valign="middle"> 
        <td colspan="2" height="42"> 
          <table width="80%" border="0" align="center">
            <tr> 
              <td colspan="2"> 
            <tr> 
              <td colspan="2" valign="top" height="192"> 
                <table width="100%" border="0" cellpadding="2" cellspacing="1">
                  <tr>
                    <td colspan="2"><div align="right"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">( <a href="staff.cgi?do=profile&goto=del_pre&id={id}">delete
                    template</a> ) </font></div></td>
                  </tr>
                  <tr> 
                    <td colspan="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif" color="#FFFFFF"><b><font color="#000000">Edit 
                      Pre-Defined Response </font></b></font></td>
                  </tr>
                  <tr> 
                    <td valign="middle" height="42"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Subject:</font></td>
                    <td width="71%" height="42"> 
                      <input type="text" class="query" name="subject" size="40" value="{subject}">
                    </td>
                  </tr>
                  <tr> 
                    <td valign="top" height="198"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Content: 
                      </font></td>
                    <td width="71%" height="198"> 
                      <textarea class="query" name="content" cols="55" rows="10">{content}</textarea>
                    </td>
                  </tr>
                </table>
              </td>
            </tr>
            <tr valign="middle"> 
              <td colspan="2" height="50"> 
                <div align="center"> <font size="1" face="Verdana, Arial, Helvetica, sans-serif">
                  <input type="hidden" name="id" value="{id}">
                  <input type="hidden" name="do" value="profile">
                  <input type="hidden" name="goto" value="editsave">
                  </font> 
                  <input type="submit" name="Submit" value="Edit This Response Template">
                </div>
              </td>
            </tr>
          </table>
        </td>
      </tr>
    </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

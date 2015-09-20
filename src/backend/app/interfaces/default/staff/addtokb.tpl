 


<form action="staff.cgi?{trackno}" method="post">
  <table width="90%" border="0" cellspacing="0" align="center" cellpadding="0">
    <tr> 
      <td colspan="4"> 
        
      </td>
    </tr>
    <tr>
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr class ="toptab"> 
      <td colspan="4"><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>ADD 
        RESPONSE TO KB</b></font></td>
    </tr>
    <tr> 
      <td colspan="4"> 
        <table width="90%" border="0" align="center">
          <tr> 
            <td colspan="2">&nbsp;</td>
          </tr>
          <tr valign="middle"> 
            <td colspan="2" height="173"> 
              <div align="center"> 
                <table width="65%" border="0" cellspacing="1" cellpadding="2">
                  <tr> 
                    <td colspan="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Thank 
                      you, your response has been saved. You have chosen to add 
                      this response to the KB. Please complete/modify the entry 
                      below.</font></td>
                  </tr>
                  <tr> 
                    <td width="38%">&nbsp;</td>
                    <td width="62%">&nbsp;</td>
                  </tr>
                  <tr> 
                    <td width="38%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>KB 
                      Category</b></font></td>
                    <td width="62%"> 
                      <select name="select">{category}
                      </select>
                    </td>
                  </tr>
                  <tr> 
                    <td width="38%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Subject</b></font></td>
                    <td width="62%"> 
                      <input type="text" name="subject">
                    </td>
                  </tr>
                  <tr> 
                    <td colspan="2"> 
                      <div align="center"> 
                        <textarea name="article" cols="70" rows="12" class="gbox">QUESTION
------------------------------------------------------
{q} 

ANSWER
------------------------------------------------------
{a}</textarea>
                      </div>
                    </td>
                  </tr>
                </table>
                <br>
                <font face=Verdana size=1><br>
                <br>
                </font></div>
            </td>
          </tr>
          <tr valign="middle"> 
            <td colspan="2" height="60"> 
              <div align="center"> 
                <input type="hidden" name="ticket" value="{trackno}">
                <input type="hidden" name="action" value="addtokb">
                <input type="submit" name="Submit" value="Submit">
              </div>
            </td>
          </tr>
          <tr> 
            <td colspan="2">&nbsp;</td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

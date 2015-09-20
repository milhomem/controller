 


<form action="staff.cgi" method="post">
  <table width="85%" border="0" cellspacing="0" align="center" cellpadding="0">
    <tr> 
      <td colspan="4"> 
        
      </td>
    </tr>
    <tr>
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr class ="toptab"> 
      <td colspan="4"><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>EDIT 
        REQUEST {trackno}</b></font></td>
    </tr>
    <tr> 
      <td colspan="4"> 
        <table width="90%" border="0" align="center">
          <tr> 
            <td colspan="2">&nbsp;</td>
          </tr>
          <tr valign="middle"> 
            <td colspan="2" height="173"> 
              <div align="center"> <br>
                <textarea name="comments" cols="65" rows="12" class="tbox">{call}</textarea>
                <br>
                <font face=Verdana size=1><br>
                </font></div>
            </td>
          </tr>
          <tr valign="middle"> 
            <td colspan="2" height="60"> 
              <div align="center"> 
                <input type="hidden" name="ticket" value="{trackno}">
                <input type="hidden" name="action" value="save_edit_call">
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

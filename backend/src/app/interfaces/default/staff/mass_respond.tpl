 


<form action="staff.cgi" method="post">
  <table width="85%" border="0" cellspacing="0" align="center" cellpadding="0">
    <tr> 
      <td colspan="4"> 
        
      </td>
    </tr>
    <tr> 
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr> 
      <td colspan="4"> <font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
        <br>
        <table width="90%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
          <tr> 
            <td width="46%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">STATUS 
              </font></td>
            <td width="54%" height="2"> 
              <select name="status" class="tbox">
                <option value="Resolved">Fechado</option>
                <option value="Unresolved" selected>Aberto</option>
                <option value="Hold">Em Andamento</option>
              </select>            </td>
          </tr>
          <tr>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">N&Iacute;VEL</font></td>
            <td height="2"><select name="priority" class="gbox"><option value="1" >1</option><option value="2" >2</option><option value="3">3</option><option value="4">4</option><option value="5">5</option></select></td>
          </tr>
        </table>
        </font> 
        <table width="90%" border="0" align="center">
          <tr valign="middle"> 
            <td colspan="3" height="173"> 
              <div align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                </font> <br>
                <textarea name="comments" cols="80" rows="12" class="tbox">
</textarea>
                <font face=Verdana size=1><br>
                </font></div>
              </td>
          </tr>
          <tr valign="middle"> 
            <td width="50%" height="39"> 
              <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Notifica&ccedil;&atilde;o: </font>
            </div></td>
            <td width="1%">&nbsp;</td>
            <td width="49%" height="39"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">
              <select name="notify" class="tbox">
                <option value="Yes">Yes</option>
                <option value="No">No</option>
              </select>
            </font></td>
          </tr>
          <tr valign="middle"> 
            <td colspan="3" height="60"> 
              <div align="center"> 
                <table width="100%" border="0" cellspacing="0" cellpadding="2">
                  <tr> 
                    <td colspan="2" height="8"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                      </font></td>
                  </tr>
                </table>{hidden}
                <input type="hidden" name="action" value="submitnote">
                <input type="submit" name="Submit" value="Submit">
              </div>
            </td>
          </tr>
          <tr> 
            <td colspan="3">&nbsp;</td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

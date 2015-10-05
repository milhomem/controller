 
<script language="JavaScript">
<!--
function MM_jumpMenu(targ,selObj,restore){ //v3.0
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
}
//-->
</script>


<form action="staff.cgi" method="post">
  <table width="100%" border="0" cellspacing="0" align="center" cellpadding="0">
          <tr> 
      <td colspan="4"> 
        
      </td>
    </tr>
    <tr> 
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr> 
      <td colspan="4"> 
        <div align="right"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b> 
          </b></font> </div>
      </td>
    </tr>
    <tr> 
      <td colspan="4"> 
        <table width="100%" border="0">
          <tr class ="toptab"> 
            <td colspan="2"><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>CHANGE 
              STATUS</b></font></td>
          </tr>
          <tr bgcolor="#F1F1F8"> 
            <td colspan="2">&nbsp;</td>
          </tr>
          <tr bgcolor="#F1F1F8"> 
            <td width="29%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Status 
              </font></td>
            <td width="71%"><font face="Verdana, Arial, Helvetica, sans-serif" size="2">{status}</font></td>
          </tr>
          <tr bgcolor="#F1F1F8"> 
            <td width="29%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Sub 
              Text</font></td>
            <td width="71%"> 
              <select name="subtext">
                <option value="completed">Completed</option>
                <option value="awaiting">Awaiting User Response</option>
                <option value="internal">Assign Internal</option>
              </select>
            </td>
          </tr>
          <tr bgcolor="#F1F1F8"> 
            <td width="29%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Assign 
              Internal</font></td>
            <td width="71%"> 
              <select name="assign">
                <option value="General Support">General Support</option>
                <option value="Billing">Billing</option>
              </select>
            </td>
          </tr>
          <tr bgcolor="#F1F1F8"> 
            <td width="29%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Comments</font></td>
            <td width="71%"> 
              <textarea name="comments" cols="35" rows="4"></textarea>
            </td>
          </tr>
          <tr bgcolor="#F1F1F8" valign="middle"> 
            <td colspan="2" height="42"> 
              <div align="center">
                <input type="hidden" name="action" value="modstatus">
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
    <tr> 
      <td colspan="4" valign="top">&nbsp; </td>
    </tr>
  </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

 
<script language="JavaScript">
<!--
function MM_jumpMenu(targ,selObj,restore){ //v3.0
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
}
//-->
</script>


<form action="staff.cgi" method="post">
  <table width="90%" border="0" cellspacing="0" align="center" cellpadding="0">
    <tr> 
      <td colspan="4"> 
        
      </td>
    </tr>
    <tr> 
      <td colspan="4">&nbsp;</td>
    </tr>
    <tr> 
      <td colspan="4" valign="top"> 
        <table width="100%" border="0">
          <tr> 
            <td colspan="2"> <table width="95%" border="0" cellspacing="0" cellpadding="0" align="center">
                <tr> 
                  <td width="43%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp;</font></td>
                  <td width="57%"><b></b></td>
                </tr>
                <tr bgcolor="#E3E2E9"> 
                  <td colspan="2"> <table width="100%" border="0" cellspacing="1" cellpadding="2">
                      <tr> 
                        <td bgcolor="#FFFFFF"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Create 
                          New Knowledge Base Entry</b></font></td>
                      </tr>
                      <tr> 
                        <td bgcolor="#FFFFFF"> <table width="90%" border="0" cellspacing="1" cellpadding="4" align="center">
                            <tr> 
                              <td width="31%">&nbsp;</td>
                              <td width="69%">&nbsp;</td>
                            </tr>
                            <tr> 
                              <td width="31%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Category 
                                </font></td>
                              <td width="69%"> <select name="select" class="gbox">{category}
                                </select> </td>
                            </tr>
                            <tr> 
                              <td width="31%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Subject</font></td>
                              <td width="69%"> <input name="subject" type="text" class="gbox" size="40"> 
                              </td>
                            </tr>
                            <tr valign="bottom"> 
                              <td height="40" colspan="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>Article</strong></font></td>
                            </tr>
                            <tr> 
                              <td colspan="2" valign="top"><div align="right"></div></td>
                            </tr>
                            <tr> 
                              <td colspan="2" valign="top"> <textarea name="description" cols="85" class="gbox" rows="15"></textarea> 
                              </td>
                            </tr>
                            <tr> 
                              <td width="31%">&nbsp;</td>
                              <td width="69%">&nbsp;</td>
                            </tr>
                            <tr> 
                              <td colspan="2" height="32"> <div align="center"> 
                                  <input type="submit" name="Submit" value="Submit" class="forminput">
                                </div></td>
                            </tr>
                            <tr> 
                              <td colspan="2" height="32"> <input type="hidden" name="do" value="kb"> 
                                <input type="hidden" name="goto" value="addsave"> 
                              </td>
                            </tr>
                          </table></td>
                      </tr>
                    </table></td>
                </tr>
                <tr> 
                  <td width="43%">&nbsp;</td>
                  <td width="57%">&nbsp;</td>
                </tr>
                <tr> 
                  <td width="43%">&nbsp;</td>
                  <td width="57%">&nbsp;</td>
                </tr>
              </table></td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

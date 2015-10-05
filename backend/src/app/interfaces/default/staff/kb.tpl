 
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
            <td colspan="2"><font face="Verdana, Arial, Helvetica, sans-serif" size="2"><b>            Knowledge
                  Base Management</b></font></td>
          </tr><tr> 
            <td colspan="2"> 
              <table width="90%" border="0" cellspacing="0" cellpadding="0" align="center">
                <tr> 
                  <td colspan="2" height="60"> 
                    <div align="right"><font color="#000066" size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                      <strong>[ <a href="staff.cgi?do=kb&amp;goto=add">Add a
                      new article</a> | <a href="staff.cgi?do=kb&amp;goto=cat">Manage
                      Categories</a> 
                  ]</strong></font></div></td>
                </tr>
                <tr> 
                  <td width="43%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
                    <input type="hidden" name="do" value="kb">
                    <input type="hidden" name="goto" value="search">
                    </font></td>
                  <td width="57%"><b></b></td>
                </tr>
                <tr> 
                  <td colspan="2" bgcolor="#E3E2E9"> 
                    <table width="100%" border="0" cellspacing="1" cellpadding="2">
                     
                      <tr> 
                        <td bgcolor="#FFFFFF"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Search
                          Articles</b></font></td>
                      </tr>
                      <tr> 
                        <td bgcolor="#FFFFFF"> 
                          <table width="90%" border="0" cellspacing="1" cellpadding="2" align="center">
                            <tr> 
                              <td width="31%">&nbsp;</td>
                              <td width="69%">&nbsp;</td>
                            </tr>
                            <tr> 
                              <td width="31%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Query 
                                </font></td>
                              <td width="69%"> 
                                <input type="text" name="query" class="tbox" size="50">
                              </td>
                            </tr>
                            <tr> 
                              <td width="31%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Category 
                                </font></td>
                              <td width="69%"> 
                                <select name="select" class="tbox">{category}
                                </select>
                              </td>
                            </tr>
                            <tr> 
                              <td colspan="2" height="32"> 
                                <div align="center"> 
                                  <input type="submit" name="Submit" value="Submit" class="forminput">
                                </div>
                              </td>
                            </tr>
                          </table>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr> 
                  <td width="43%">&nbsp;</td>
                  <td width="57%">&nbsp;</td>
                </tr>
                <tr> 
                  <td colspan="2"> 
                    <table width="100%" border="0" cellspacing="1" cellpadding="0" align="center">
                      <tr> 
                        <td>&nbsp;</td>
                      </tr>
                      <tr> 
                        <td> 
                          <table width="100%" border="0" cellspacing="0" cellpadding="0">
                            <tr bgcolor="#6C7CA2"> 
                              <td height="22"> 
                                <table width="100%" border="0" cellpadding="1">
                                  <tr> 
                                    <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b><font color="#FFFFFF">Recent 
                                      Articles</font></b></font></td>
                                  </tr>
                                </table>
                              </td>
                            </tr>
                            <tr bgcolor="#CCCCCC"> 
                              <td> 
                                <table width="100%" border="0" cellspacing="1" callpadding="0">
                                  {list} 
                                </table>
                              </td>
                            </tr>
                          </table>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
                <tr> 
                  <td width="43%">&nbsp;</td>
                  <td width="57%">&nbsp;</td>
                </tr>
                <tr> 
                  <td width="43%">&nbsp;</td>
                  <td width="57%">&nbsp;</td>
                </tr>
              </table>
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

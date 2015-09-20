
  <form method="post" name="Checkform"><table width="100%" border="0" cellspacing="0" align="center" cellpadding="0">
    <tr>
      <td><div align="right">
        <table width="100%" border="0" cellspacing="0" cellpadding="2">
          <tr>
            <td height="39">
<select name="select" class="ibox" onChange="MM_jumpMenu('parent',this,0)">
                <option selected>Department Filter</option>
                
               {departments}
			   
              </select></td>
            <td><div align="right">
                <select name="menu" class="gbox" onChange="MM_jumpMenu('parent',this,0)">
                  <option selected>Auto Refresh Page</option>
                  <option value="staff.cgi?do=listcalls&status={status}&timer=60000">Every 
                  Minute </option>
                  <option value="staff.cgi?do=listcalls&status={status}&timer=180000">Every 
                  3 Minutes </option>
                  <option value="staff.cgi?do=listcalls&status={status}&timer=300000">Every 
                  5 Minutes </option>
                  <option value="staff.cgi?do=listcalls&status={status}&timer=900000">Every 
                  15 Minutes </option>
                  <option value="staff.cgi?do=listcalls&status={status}&timer=1800000">Every 
                  30 Minutes </option>
                </select>
              </div></td>
          </tr>
        </table>
        
      </div></td>
    </tr>
    <tr> 
      <td><font face="Verdana, Arial, Helvetica, sans-serif" size="1">{cc}</font></td>
    </tr>
    <tr> 
      <td height="32"> 
        <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">{nav}</font></div>
      </td>
    </tr>
    <tr bgcolor="#336633"> 
      <td height="18"> 
        <div align="left">
          <table width="100%" border="0" cellspacing="0" cellpadding="4">
            <tr>
              <td><font color="#FFFFFF" size="2" face="Verdana, Arial, Helvetica, sans-serif">{type}
              Requests </font></td>
            </tr>
          </table>
        </div></td>
    </tr>
    <tr> 
      <td> 
        <table width="100%" border="0" cellpadding="0" cellspacing="0">
          <tr> 
            <td> 
              <table width="100%" border="0" cellspacing="1" align="center" height="19" cellpadding="0">
                <tr> 
                  <td width="13%" bgcolor="#D1D1D1"> 
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr> 
                        <td><font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
                          ID</font></td>
                      </tr>
                      <tr> 
                        <td height="5"> 
                          <div align="right"><font size="1"><a href="{path}&sort=id&method=asc"><img src="{imgbase}/up.gif" width="8" height="5" border="0"></a> 
                            <a href="{path}&sort=id&method=desc"><img src="{imgbase}/down.gif" width="8" height="5" border="0"></a></font></div>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td width="17%" bgcolor="#D1D1D1"> 
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr> 
                        <td><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Logged 
                          By </font></td>
                      </tr>
                      <tr> 
                        <td height="5"> 
                          <div align="right"><font size="1"><a href="{path}&sort=username&method=asc"><img src="{imgbase}/up.gif" width="8" height="5" border="0"></a> 
                            <a href="{path}&sort=username&method=desc"><img src="{imgbase}/down.gif" width="8" height="5" border="0"></a></font></div>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td width="21%" bgcolor="#D1D1D1"> 
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr> 
                        <td><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Subject</font></td>
                      </tr>
                      <tr> 
                        <td height="5"> 
                          <div align="right"><font size="1"><a href="{path}&sort=subject&method=asc"><img src="{imgbase}/up.gif" width="8" height="5" border="0"></a> 
                            <a href="{path}&sort=subject&method=desc"><img src="{imgbase}/down.gif" width="8" height="5" border="0"></a></font></div>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td width="22%" bgcolor="#D1D1D1"> 
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr> 
                        <td><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Department</font></td>
                      </tr>
                      <tr> 
                        <td height="5"> 
                          <div align="right"><font size="1"><a href="{path}&sort=category&method=asc"><img src="{imgbase}/up.gif" width="8" height="5" border="0"></a> 
                            <a href="{path}&sort=category&method=desc"><img src="{imgbase}/down.gif" width="8" height="5" border="0"></a></font></div>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td width="8%" bgcolor="D1D1D1"> 
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr> 
                        <td><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Status</font></td>
                      </tr>
                      <tr> 
                        <td height="5"> 
                          <div align="right"><font size="1"><a href="{path}&sort=status&method=asc"><img src="{imgbase}/up.gif" width="8" height="5" border="0"></a> 
                            <a href="{path}&sort=status&method=desc"><img src="{imgbase}/down.gif" width="8" height="5" border="0"></a></font></div>
                        </td>
                      </tr>
                    </table>
                  </td>
                  <td width="19%" bgcolor="#D1D1D1"> 
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr> 
                        <td><font size="1" face="Verdana, Arial, Helvetica, sans-serif">When 
                          Logged </font></td>
                      </tr>
                      <tr> 
                        <td height="5"> 
                          <div align="right"><font size="1"><a href="{path}&sort=id&method=asc"><img src="{imgbase}/up.gif" width="8" height="5" border="0"></a> 
                            <a href="{path}&sort=id&method=desc"><img src="{imgbase}/down.gif" width="8" height="5" border="0"></a></font></div>
                        </td>
                      </tr>
                    </table>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr> 
            <td>{listcalls}</td>
          </tr>
          <tr> 
            <td height="52"><table width="100%" border="0" cellpadding="5" cellspacing="1">
              <tr>
                <td colspan="4">&nbsp;</td>
                </tr>
              <tr>
                <td width="3%">&nbsp;</td>
                  <td width="6%"> <div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
                      <input name=all_c type=checkbox id="all_c" onClick="CheckBox(this);" >
                      </font></div></td>
                <td width="22%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=#000000>
                  <div align="center">
                    <select name="action_call" class="query">
                    <option value="delete">Delete Selected
                    <option value="respond">Respond to Selected                    
                    <option value="own">Take Ownership</option>
                    </select>
                  </div>
                </font></td>
                <td width="69%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=#000000>
                  <input type="image" border="0" name="imageField" src="{imgbase}/staff/save_changes.gif">
                  <input type="hidden" name="status" value="{status}">
                  <input type="hidden" name="do" value="update_list_calls">
  </font></td>
                </tr>
            </table> 
            </td>
          </tr>
          <tr> 
            <td> 
              <div align="center">
                
              <table width="400" border="0" cellpadding="0" cellspacing="1" align="left">
                <tr> 
                  <td colspan="4">&nbsp;</td>
                </tr>
                <tr> 
                  <td width="37%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Web 
                    Desk Submission</font></td>
                  <td width="14%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src="{imgbase}/ticket.gif"></font></td>
                  <td width="37%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Awaiting 
                    User Response</font></td>
                  <td width="12%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src="{imgbase}/offline.gif"></font></td>
                </tr>
                <tr> 
                  <td width="37%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">E-Mail 
                    Submission</font></td>
                  <td width="14%"> 
                    <div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="#000000"><img src="{imgbase}/mail.gif"></font> 
                    </div>
                  </td>
                  <td width="37%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Awaiting 
                    Staff Response</font></td>
                  <td width="12%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src="{imgbase}/online.gif"></font></td>
                </tr>
                <tr> 
                  <td width="37%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Staff 
                    Submission</font></td>
                  <td width="14%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src="{imgbase}/phone.gif"></font></td>
                  <td width="37%">&nbsp;</td>
                  <td width="12%">&nbsp;</td>
                </tr>
              </table>
              </div>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    <tr> 
      <td valign="top"> 
        <table width="99%" border="0" align="center" cellpadding="0" cellspacing="0">
          <tr> 
            <td> 
              <div align="center"> 
                
              <p>&nbsp;</p>
              <p>&nbsp;</p>
            </div>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    <tr> 
      <td valign="top"> 
        <div align="center"><br>
        </div>
      </td>
    </tr>
  </table>

<br>
  <br>
<p>&nbsp;</p>
</form>
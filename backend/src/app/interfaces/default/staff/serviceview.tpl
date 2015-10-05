<form action="staff.cgi" method="post">
  <table width="100%" border="0" align="center">
    <tr> 
      <td width="22%"> 
      <td width="78%" colspan="2"> 
    <tr> 
      <td colspan="5"> </td>
    </tr>
    <tr valign="middle">
      <td valign="top"> <table width="145" border="0" align="right" cellpadding="4" cellspacing="0">
          <tr> 
            <td width="53"> <div align="center"><strong><img src="{imgbase}/icons/ticket.jpg" border="0"></strong></div></td>
            <td width="107" valign="top"><br> 
            Servi&ccedil;os<br> </td>
          </tr>
          <tr> 
            <td colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
          <tr> 
            <td colspan="2">Utilize esta ferramenta para verificar os dados dos servi&ccedil;os.</td>
          </tr>
          <tr> 
            <td height="27" colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
        </table>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
        <p>&nbsp;</p>
      </td>
      <td height="42" colspan="2" valign="top"> 
        <table width="95%" border="0" align="center">
          <tr valign="middle"> 
            <td height="42"> <div align="center"> 
                <table width="90%" border="0" align="center" cellpadding="0" cellspacing="1">
                  <!--DWLayoutTable-->
                  <tr> 
                    <td width="882" height="19" valign="top"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                        <tr> 
                          <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b><a href="staff.cgi?do=services&id={username}">Staff</a>: 
                            Servi&ccedil;os: Perfil</b></font></td>
                        </tr>
                      </table></td>
                  </tr>
                  <tr > 
                    <td height="27" valign="top"><table width="100%" border="1" cellspacing="0" cellpadding="0" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                      <!--DWLayoutTable-->
                      <tr>
                        <td width="219" height="25" valign="middle"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Servi&ccedil;o:</font></td>
                        <td width="651" valign="middle"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{id}</font></td>
                  </tr>
                    </table></td>
                  </tr>
                  <tr >
                    <td height="19"></td>
                  </tr>
                  <tr>
                    <td height="102" valign="top"><table width="100%" border="1" cellspacing="0" cellpadding="0" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                      <tr valign="middle">
                        <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Cliente:</font></td>
                        <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">SN-{cliente}  
              ( <a href="staff.cgi?do=user_details&user={cliente}">ver perfil do usu&aacute;rio </a>)</font> </td>
                      </tr>
                      <tr valign="middle">
                        <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Nome:</font></td>
                        <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{nome}</font></td>
                      </tr>
                      <tr valign="middle">
                        <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Email:</font></td>
                        <td><a href="mailto:{mail}"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{mail}</font></a></td>
                      </tr>
                      <!--DWLayoutTable-->
                      <tr valign="middle">
                        <td width="219" height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Dom&iacute;nio:</font></td>
                        <td width="662"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{dominio}</font></td>
                  </tr>
                      <tr valign="middle">
                        <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Servidor:</font></td>
                        <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{servidor}</font></td>
                  </tr>
                    </table></td>
                  </tr>
                  <tr>
                    <td height="25">&nbsp;</td>
                  </tr>
                  <tr>
                    <td height="102" valign="top"><table width="100%" border="1" cellspacing="0" cellpadding="0" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                      <!--DWLayoutTable-->
                      <tr valign="middle">
                        <td width="219" height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Tipo de Servi&ccedil;o:</font></td>
                        <td width="662"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{tipo}</font></td>
                  </tr>
                      <tr valign="middle">
                        <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Plataforma:</font></td>
                        <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{plataforma}</font></td>
                  </tr>
                      <tr valign="middle">
                        <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Plano:</font></td>
                        <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{plano}</font></td>
                      </tr>
                      <tr valign="middle">
                        <td height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Descri&ccedil;&atilde;o:</font></td>
                        <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{pdescr}</font></td>
                  </tr>
				      {descr}
                    </table></td>
                  </tr>
                  <tr>
                    <td height="25">&nbsp;</td>
                  </tr>
                  <tr>
                    <td height="52" valign="top"><table width="100%" border="1" cellspacing="0" cellpadding="0" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                        <!--DWLayoutTable-->
                        <tr valign="middle">
                          <td width="219" height="25"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Status:</font></td>
                          <td width="662"><font size="2" color={color} face="Verdana, Arial, Helvetica, sans-serif"><strong>{status}</strong></font></td>
                        </tr>
                                        </table>                    </td>
                  </tr>
                  <tr>
                    <td height="32" valign="top"><div align="center"><a href="staff.cgi?do=log&user={cliente}&service={id}"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>Abrir um Ticket</strong></font></a>&nbsp;</div></td>
                  </tr>
                  </table>
              </div></td>
          </tr></table></td>
    </tr></table>
  </form>

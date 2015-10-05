 


<form action="staff.cgi?" method="post">
  <table width="100%" border="0" cellspacing="0" align="center" cellpadding="0">
    <!--DWLayoutTable-->
          <tr> 
      <td width="1340" height="19"> 
        
      </td>
    </tr>
    <tr> 
      <td height="19"> 
        <div align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b> 
          </b></font><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>{aviso}</strong></font></div></td>
    </tr>
    <tr> 
      <td height="78" valign="top"> <font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
        
        <table width="90%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
          <tr> 
            <td width="19%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Usu&aacute;rio</font></td>
            <td width="72%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{fusername} 
              ( ver tickets de <a href="staff.cgi?do=listbyuser&user={username}">{fusername}</a> 
              / <a href="staff.cgi?do=user_details&user={username}&cid={trackno}">ver perfil do usu&aacute;rio</a>)</font></td>
          </tr>
          <tr>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Email</font></td>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{email}</font></td>
          </tr>       
          <tr>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Modo de Atendimento</font></td>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><img src="{imgbase}/{method}" border="0" /></font></td>
          </tr>       
          {fields}
          <tr>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Chamados Abertos</font></td>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{tickets}</font></td>
          </tr>    
        </table>
		<br />
		<table width="90%" border="0" cellspacing="0" cellpadding="0" align="center">
          <tr>
            <td height="27">
              <div align="right">
			  
                <table width="100%" border="1" cellspacing="0" cellpadding="1" align="right" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                  <tr>
                    <td width="164" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="#666666">MUDAN&Ccedil;A DE N&Iacute;VEL </font></div>
                    </td>
                    <td width="20" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=1">1</a></font></div>
                    </td>
                    <td width="20" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=2">2</a></font></div>
                    </td>
                    <td width="20" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=3">3</a></font></div>
                    </td>
   					<td width="20" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=4">4</a></font></div>
                    </td>
					   <td width="40" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=5">Generalizados</a></font></div>
                    </td>					
					   <td width="60" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=6">Generalizados [2]</a></font></div>
                    </td>					
					   <td width="60" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=7">Generalizados [3]</a></font></div>
                    </td>					
					   <td width="60" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=8">Generalizados [4]</a></font></div>
                    </td>					

					   <td width="60" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=9">Generalizados [5]</a></font></div>
                    </td>					
					   <td width="60" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=mudar_nivel&id={trackno}&nivel=10">Generalizados [6]</a></font></div>
                    </td>					

                  </tr>
                </table>
              </div>
            </td>
          </tr>
        </table>
        </font></td>
    </tr>
    <tr>
      <td height="471" valign="top"><table width="80%" border="0" cellspacing="0" cellpadding="0" align="center">
          <tr>
            <td width="25%">&nbsp;</td>
            <td width="25%">&nbsp;</td>
            <td width="25%">&nbsp;</td>
            <td width="25%">&nbsp;</td>
          </tr>
          <tr bgcolor="#D1D1E0">
            <td width="25%"><table width="100%" border="0" cellspacing="1" cellpadding="2">
                <tr bgcolor="#E1E0ED">
                  <td bgcolor="#FAF7E4">
                    <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?action=assign&callid={trackno}">ENCAMINHAR TICKET</a></font></div>
                  </td>
                </tr>
                </table>
        </td>
            <td width="25%">
              <table width="100%" border="0" cellspacing="1" cellpadding="2">
                <tr bgcolor="#E1E0ED">
                  <td bgcolor="#FAF7E4">
                    <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=delete&cid={trackno}">REMOVER TICKET</a></font></div>
                  </td>
                </tr>
              </table>
            </td>
            <td width="25%">
              <table width="100%" border="0" cellspacing="1" cellpadding="2">
                <tr bgcolor="#E1E0ED">
                  <td bgcolor="#FAF7E4">
                    <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?action=print&amp;callid={trackno}">IMPRIMIR TICKET</a></font></div>
                  </td>
                </tr>
              </table>
            </td>
            <td width="25%">
              <table width="100%" border="0" cellspacing="1" cellpadding="2">
                <tr bgcolor="#E1E0ED">
                  <td bgcolor="#FAF7E4">
                    <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=own&cid={trackno}">TOMAR POSSE</a></font></div>
                  </td>
                </tr>
              </table>
            </td>
          </tr>

          </table>          <font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp; </font> <font size="2" face="Verdana, Arial, Helvetica, sans-serif"> 
          <table width="90%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
            <tr> 
              <td width="19%" height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">ID do Ticket </font></td>
              <td width="72%" height="2"><a href="?do=ticket&cid={trackno}"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{trackno}</font></a></td>
            </tr>
            <tr> 
              <td width="19%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Logado</font></td>
              <td width="72%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{date}</font>              </td>
            </tr>
            <tr>
              <td height="19"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Staff</font></td>
              <td height="19"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>{owned}</b></font></td>
            </tr>
            <tr>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Tempo Decorrido </font></td>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{ttime}</font></td>
            </tr>
            <tr>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">&Uacute;ltima Resposta </font></td>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{ltime}</font></td>
            </tr>
 			<tr>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Tempo &Uacute;til </font></td>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{time_s}</font></td>
            </tr>			
            <tr>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Status</font></td>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{status}</font></td>
            </tr>
            <tr>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Departamento</font></td>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{category} </font></td>
            </tr>
            <tr>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Nível</font></td>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{priority} </font></td>
            </tr>
            <tr>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Aguardando</font></td>
              <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{awt} </font></td>
            </tr>	            			
          </table>
                </font><font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp; </font> 
        <table width="90%" border="0" cellspacing="0" cellpadding="0" align="center">
          <tr>
            <td height="27">
              <div align="right">
			  
                <table width="566" border="1" cellspacing="0" cellpadding="1" align="right" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                  <tr>
                    <td width="136" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="#666666">MUDAN&Ccedil;A DE 
                          STATUS</font></div>                    </td>
                    <td width="75" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=change_status&id={trackno}&trackno={trackno}&status=A">ABERTO</a></font></div>                    </td>
                    <td width="75" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=change_status&id={trackno}&trackno={trackno}&status=H">ESPERA</a></font></div>                    </td>
                    <td width="75" height="2">
                      <div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="staff.cgi?do=change_status&id={trackno}&trackno={trackno}&status=F">FECHADO</a></font></div>                    </td>
                    <td width="89"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=change_status&id={trackno}&trackno={trackno}&status=AU">A. USUÁRIO</a></font></div></td>
                    <td width="90"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><a href="?do=change_status&id={trackno}&trackno={trackno}&status=AO">A. OPERADOR</a></font></div></td>
                  </tr>
                </table>
              </div>
            </td>
          </tr>
        </table>        <font size="2" face="Verdana, Arial, Helvetica, sans-serif"><br>
                </font> 
        <table width="90%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
          <tr>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Dom&iacute;nio</font></td>
            <td height="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{url} 
            ( <a href="{linktos}">ver status do servi&ccedil;o {servn} </a>)</font> </td>
          </tr>
          <tr>
            <td width="19%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Servidor</font></td>
            <td width="72%"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{servidor}</font></td>
          </tr>
{fields2}      
                </table>        
        <table width="90%" border="0" align="center" cellpadding="3" cellspacing="1">
              <tr>
                <td height="27">&nbsp;</td>
              </tr>
              <tr>
                <td>&nbsp;            </td>
              </tr>
        </table>          <table width="90%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#F2F2F2" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                <tr> 
                  <td colspan="2" height="29"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>{subject}</b></font></td>
                </tr>
                <tr> 
                  <td colspan="2" height="41"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp; 
                  </font> 
                    <table width="100%" border="0" cellspacing="1" cellpadding="3">
                      <tr> 
                        <td colspan="2"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{description}</font><font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp; 
                        </font></td>
                      </tr>
                      <tr> 
                        <td colspan="2">
                          <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">[ 
                          <a href="staff.cgi?action=editticket&amp;ticket={trackno}">EDITAR 
                          TICKET</a> ] </font></div>
                        </td>
                      </tr>
                    </table>
                      
            </td>
                </tr>
                <tr>
                  <td height="23" colspan="2" bgcolor="#E1E1E1"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><strong> Anexos: {filename}</strong></font></td>
                </tr>
                </table>            <font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp; </font><br>
        <table width="100%" border="0" align="center">
          <tr> 
            <td colspan="2"> 
              <table width="90%" border="1" cellspacing="0" cellpadding="1" align="center" bgcolor="#EAEAEA" bordercolor="#F7F7F7" bordercolorlight="#CCCCCC">
                <tr bgcolor="#E1E1E1"> 
                  <td colspan="2" height="22"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b> Respostas do User/Staff</b></font></td>
                </tr>
              {notes} </table>
                      
            </td>
          </tr>
        </table></td>
    </tr>
    <tr> 
      <td height="19" valign="top"> 
        <table width="99%" border="0" align="center" cellpadding="0" cellspacing="0">
          <tr> 
            <td> 
              <div align="center"></div>
            </td>
          </tr>
        </table>
      </td>
    </tr>
    <tr> 
      <td height="19" valign="top">&nbsp;</td>
    </tr>
    <tr> 
      <td height="154" valign="top"> 
        <div align="center">
          <table width="90%" border="0" align="center" cellpadding="3" cellspacing="1">
            <tr> 
              <td height="27">
                <div align="center"><a href="staff.cgi?action=addresponse&amp;ticket={trackno}"><img src="{imgbase}/staff/respond.gif" width="120" height="19" border="0"> 
                </a> </div></td>
            </tr>
            <tr> 
              <td>&nbsp; </td>
            </tr>
          </table>
          <table width="90%" border="0" align="center" cellpadding="3" cellspacing="1">
            <tr> 
              <td colspan="2"><table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
                  <tr> 
                    <td width="9%" valign="top"><img src="{imgbase}/icons/clock.jpg" width="50" height="53"></td>
                    <td width="91%" valign="top"> 
                      <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
                        <tr bgcolor="#CCCCCC"> 
                          <td height="2"> <table width="100%" border="0" align="center" cellpadding="4" cellspacing="1">
                              <tr bgcolor="#68977C"> 
                                <td colspan="5" height="24"> 
                                  <div align="left"><font size="2" face="Verdana, Arial, Helvetica, sans-serif" color="#FFFFFF">Log de Atividades</font></div></td>
                              </tr>
                              {log} </table></td>
                        </tr>
                        <tr> 
                          <td>&nbsp; </td>
                        </tr>
                      </table></td>
                  </tr>
                </table>
                <font size="2" face="Verdana, Arial, Helvetica, sans-serif">&nbsp; 
                </font> </td>
            </tr>
          </table>
          <input type="hidden" name="ticket" value="{trackno}">
          <input type="hidden" name="action" value="addresponse">
          <br>
        </div>
      </td>
    </tr>
  </table>
  <br>
  <br>
</form>
<p>&nbsp;</p>

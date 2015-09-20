<script language="JavaScript" type="text/JavaScript">
<!--
function MM_jumpMenu(targ,selObj,restore){ //v3.0
  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");
  if (restore) selObj.selectedIndex=0;
}
//-->
</script>
 <table width="100%" border="0" align="center" cellpadding="0" cellspacing="0">
   <!--DWLayoutTable-->
    <tr> 
      <td width="222" height="0"> 
      <td width="1159"> 
      <td width="1"></td>
   <tr valign="middle">
     <td rowspan="2" valign="top"> <table width="145" border="0" align="right" cellpadding="4" cellspacing="0">
        <!--DWLayoutTable-->
          <tr> 
            <td width="44"> <div align="center"><strong><img src="{imgbase}/icons/folder1.jpg" border="0"></strong></div></td>
            <td width="116" valign="top"><br>
              STAFF AREA</td>
          </tr>
          <tr> 
            <td colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
          <tr>
            <td colspan="2">Bem vindo {name} &agrave; &aacute;rea de Staffs, aqui voc&ecirc; responde aos pedidos, edita seu perfil, etc.</td>
          </tr>
          <tr>
            <td colspan="2"><div align="justify">Ultimos eventos:<br />
              <br />
            {events}<br />
            <font size="1"><a href="#"></a></font></div></td>
          </tr>
          <tr>
            <td height="57" colspan="2"><div align="right"><font size="1"><a href="?do=events">%more%...</a></font><font color="#999999"><br />
              ..........................................</font></div></td>
          </tr>		  
          <tr>
            <td height="27" colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
		  <tr>
            <td height="27" colspan="2"><font color="#999999" size="1">*A.O.-Aguardando Operador<br />*A.U.-Aguardando Usuário</font></td>					  
		  </tr>
          <tr>
            <td height="27" colspan="2"><table width="100%" border="0" cellspacing="1" cellpadding="3" align="center">
              <tr bgcolor="#F2F2F2">
                <td width="50%" bgcolor="#D8D8D8" height="14"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Departamento</font></div></td>
                <td width="25%" height="14" bgcolor="#E8E8E8"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">A.O.</font></div></td>
                <td width="25%" bgcolor="#E8E8E8"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">A.U.</font></div></td>
              </tr>
              {dep_stats}
              <tr bgcolor="#F2F2F2">
                <td width="50%" bgcolor="#D8D8D8" height="14"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Total Abertos</font></div></td>
                <td height="50%" colspan="2" bgcolor="#E8E8E8"><div align="center"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">{total}</font></div>                  </td>
</tr>
            </table></td>
          </tr>		  
          <tr>
            <td colspan="2"><font color="#999999">..........................................</font></td>
          </tr>
          
          
          
          
     </table>       
     <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p>       <p>&nbsp;</p></td>
    <form action="staff.cgi" target="_blank" method="post">  <td height="24" valign="top"><div align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">Servi&ccedil;os:
                  <input type="text" class="search"  name="query" size="25">&nbsp;
  
  <select name="select" class="search">
      <option value="dominio">Dom&iacute;nio</option>
      <option value="servicos`.`username">Username</option>
      <option value="email">Email</option>
  </select>
  <input name="do" type="hidden" value="lookupservice">&nbsp;<input type="image" border="0" src="{imgbase}/go1.gif" width="10" height="10">
  </font> 
      </div></td>
      <td></td>
    </form>
   </tr>
    <tr valign="middle"> <form method="post" name="Checkform">
      <td height="80%" valign="top"><table width="95%" border="0" align="center" cellpadding="0" cellspacing="0">
        <!--DWLayoutTable-->
        <tr>
          <td height="30" colspan="2" valign="top"><div align="left"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Filtrar Pedidos Empresa: {empresas}</font></div></td>
          <td>&nbsp;</td>
        </tr>
        <tr> 
          <td width="433" height="30" valign="top"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>Bem Vindo 
              {name}
                  
          </b></font></td>
          <td width="384" valign="top"><div align="right"><font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>
              <select name="menu" class="gbox" onChange="MM_jumpMenu('parent',this,0)">
                <option value="?do=main&timer=0&level={level}"{t0}>Manual Refresh </option>
                <option value="?do=main&timer=180000&level={level}"{t2}>3 Minutos                </option>
                <option value="?do=main&timer=300000&level={level}"{t3}>5 Minutos                </option>
                <option value="?do=main&timer=900000&level={level}"{t4}>15 Minutos                </option>
                <option value="?do=main&timer=1800000&level={level}"{t5}>30 Minutos                </option>
              </select>
            </b></font></div></td>
          <td>&nbsp;</td>
        </tr>
        <tr> 
          <td height="35" colspan="2" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Obrigado por se logar na &aacute;rea de staffs, {name}, abaixo est&atilde;o os pedidos dos departamentos concedidos &agrave; voc&ecirc;. </font><br />
                <font size="1" face="Verdana, Arial, Helvetica, sans-serif">&nbsp;</font><br />
                <font size="1" face="Verdana, Arial, Helvetica, sans-serif"><strong>Em negrito s&atilde;o os pedidos que est&atilde;o sob sua posse neste momento.</strong> </font><br />
                  <font size="1" face="Verdana, Arial, Helvetica, sans-serif">&nbsp; </font><br />
              <font size="1" face="Verdana, Arial, Helvetica, sans-serif"> Legenda:</font><br />
                  <table width="125" height="10"  border="0" align="left" cellpadding="0" cellspacing="1" bordercolor="#FFFFFF">
                  <tr>
                    <td width="76" ><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Hospedagem-</font></td>
                    <td width="40" bordercolor="#666666" bgcolor="{pri1}"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="{pri1}">.</font></td>
                  </tr>
              </table>
<table width="98" height="10"  border="0" align="left" cellpadding="0" cellspacing="1" bordercolor="#FFFFFF">
  <tr>
    <td width="49" ><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Revenda-</font></td>
    <td width="40" bgcolor="{pri2}" bordercolor="#666666"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="{pri2}">.</font></td>
  </tr>
</table>
<table width="96" height="10"  border="0" align="left" cellpadding="0" cellspacing="1" bordercolor="#FFFFFF">
  <tr>
    <td width="47" ><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Registro-</font></td>
    <td width="40" bgcolor="{pri3}" bordercolor="#666666"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="{pri3}">.</font></td>
  </tr>
</table>
<table width="103" height="10"  border="0" align="left" cellpadding="0" cellspacing="1" bordercolor="#FFFFFF">
  <tr>
    <td width="54" ><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Dedicado-</font></td>
    <td width="40" bgcolor="{pri4}" bordercolor="#666666"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="{pri4}">.</font></td>
  </tr>
</table>
<table width="101" height="10"  border="0" align="left" cellpadding="0" cellspacing="1" bordercolor="#FFFFFF">
  <tr>
    <td width="52" ><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Adicional-</font></td>
    <td width="40" bordercolor="#666666" bgcolor="{pri5}"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="{pri5}">.</font></td>
  </tr>
</table></td>
          <td>&nbsp;</td>
        </tr>
        </table>        
      <table width="95%" border="0" cellspacing="0" cellpadding="0" align="center">
          <tr> 
            <td> </td>
          </tr>
          <tr> 
            <td height="31"> <div align="right"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
              ( <a href="staff.cgi?do=listcalls&status=open">ver todos abertos</a> 
              )</font></div></td>
          </tr>
          <tr> 
            <td height="18" bgcolor="#990000"><table width="100%" border="0" cellspacing="0" cellpadding="3">
              <tr> 
                <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif" color="#FFFFFF"><strong>N&iacute;vel 1 </strong></font></td>
              </tr>
              </table></td>
          </tr>
          <tr> 
            <td> <table width="100%" border="0" cellspacing="1" align="center" height="19" cellpadding="0">
              <tr> 
                <td width="15%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
                        ID</font></td>
                    </tr>
                  </table></td>
                <td width="13%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Logado Por </font></td>
                    </tr>
                  </table></td>
                <td width="25%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Assunto</font></td>
                    </tr>
                  </table></td>
                <td width="25%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Departamento</font></td>
                    </tr>
                  </table></td>
                <td width="22%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Per&iacute;odo</font></td>
                    </tr>
                  </table></td>
              </tr>
              </table>
              <div align="center">{1_call}</div></td>
          </tr>
          <tr> 
            <td>&nbsp;</td>
          </tr>
          <tr> 
            <td bgcolor="#330099" height="18"><table width="100%" border="0" cellspacing="0" cellpadding="3">
              <tr> 
                <td><font size="2" face="Verdana, Arial, Helvetica, sans-serif" color="#FFFFFF"><strong>N&iacute;vel 2 </strong></font></td>
              </tr>
              </table></td>
          </tr>
          <tr> 
            <td> <table width="100%" border="0" cellspacing="1" align="center" height="19" cellpadding="0">
              <tr> 
                <td width="15%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
                        ID</font></td>
                    </tr>
                  </table></td>
                <td width="13%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Logado Por </font></td>
                    </tr>
                  </table></td>
                <td width="25%" bgcolor="#D1D1D1"> 
                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Assunto</font></td>
                    </tr>
                  </table></td>
                <td width="25%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Departamento</font></td>
                    </tr>
                  </table></td>
                <td width="22%" bgcolor="#D1D1D1"> 
                  <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Per&iacute;odo</font></td>
                    </tr>
                  </table></td>
              </tr>
              </table>
              <div align="center"></div>
              <div align="center">{2_call}</div></td>
          </tr>
          <tr>
            <td>&nbsp;</td>
          </tr>
          <tr>
            <td bgcolor="#336666" height="18"><table width="100%" border="0" cellspacing="0" cellpadding="3">
              <tr>
                <td><font color="#FFFFFF" size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>N&iacute;vel 3 </strong></font></td>
              </tr>
            </table></td>
          </tr>
          <tr>
            <td>
              <table width="100%" border="0" cellspacing="1" align="center" height="19" cellpadding="0">
                <tr>
                  <td width="15%" bgcolor="#D1D1D1">
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"> ID</font></td>
                      </tr>
                  </table></td>
                  <td width="13%" bgcolor="#D1D1D1">
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Logado Por </font></td>
                      </tr>
                  </table></td>
                  <td width="25%" bgcolor="#D1D1D1">
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Assunto</font></td>
                      </tr>
                  </table></td>
                  <td width="25%" bgcolor="#D1D1D1">
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Departamento</font></td>
                      </tr>
                  </table></td>
                  <td width="22%" bgcolor="#D1D1D1">
                    <table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Per&iacute;odo</font></td>
                      </tr>
                  </table></td>
                </tr>
              </table>
              <div align="center"></div>
              <div align="center">{3_call}</div></td>
          </tr>
          <tr>
            <td>&nbsp;</td>
          </tr>
          <tr>
            <td bgcolor="#666666" height="18"><table width="100%" border="0" cellspacing="0" cellpadding="3">
                <tr>
                  <td><font color="#FFFFFF" size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>N&iacute;vel 4 </strong></font></td>
                </tr>
            </table></td>
          </tr>
          <tr>
            <td><table width="100%" border="0" cellspacing="1" align="center" height="19" cellpadding="0">
                <tr>
                  <td width="15%" bgcolor="#D1D1D1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"> ID</font></td>
                      </tr>
                  </table></td>
                  <td width="13%" bgcolor="#D1D1D1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Logado Por </font></td>
                      </tr>
                  </table></td>
                  <td width="25%" bgcolor="#D1D1D1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Assunto</font></td>
                      </tr>
                  </table></td>
                  <td width="25%" bgcolor="#D1D1D1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Departamento</font></td>
                      </tr>
                  </table></td>
                  <td width="22%" bgcolor="#D1D1D1"><table width="100%" border="0" cellspacing="0" cellpadding="0">
                      <tr>
                        <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Per&iacute;odo</font></td>
                      </tr>
                  </table></td>
                </tr>
              </table>
                <div align="center"></div>
              <div align="center">{4_call}</div></td>
          </tr>
          <tr> 
            <td>&nbsp;</td>
          </tr>
          <tr> 
            <td bgcolor="#0066FF" height="18"><table width="100%" border="0" cellspacing="0" cellpadding="3">
              <tr> 
                <td><font color="#FFFFFF" size="2" face="Verdana, Arial, Helvetica, sans-serif"><strong>N&iacute;vel 5 </strong></font></td>
              </tr>
              </table></td>
          </tr>
          <tr> 
            <td> <table width="100%" border="0" cellspacing="1" align="center" height="19" cellpadding="0">
              <tr> 
                <td width="15%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"> 
                        ID</font></td>
                    </tr>
                  </table></td>
                <td width="13%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Logado Por </font></td>
                    </tr>
                  </table></td>
                <td width="25%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Assunto</font></td>
                    </tr>
                  </table></td>
                <td width="25%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Departamento</font></td>
                    </tr>
                  </table></td>
                <td width="22%" bgcolor="#D1D1D1"> <table width="100%" border="0" cellspacing="0" cellpadding="0">
                    <tr> 
                      <td height="19" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Per&iacute;odo</font></td>
                    </tr>
                  </table></td>
              </tr>
              </table>
              <div align="center"></div>
              <div align="center">{5_call}</div></td>
          </tr>
        </table>        
        <table width="100%" border="0" cellpadding="0" cellspacing="0" align="center">
          <tr> 
            <td height="2"> <table width="100%" border="0" cellspacing="1" cellpadding="3">
              <tr> 
                <td colspan="2">&nbsp;</td>
              </tr>
              <tr> 
                <td colspan="2"> <table width="100%" border="0" cellpadding="5" cellspacing="1">
                  <!--DWLayoutTable-->
                    <tr> 
                      <td width="381" height="46" valign="top"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=#000000> 
                        <div align="center"> 
                          <select name="action_call" class="query" id="action_call">
                            <option value="delete">Deletar Selecionados 
                            <option value="respond" selected="selected">Responder Selecionados 
                            <option value="own">Tomar Posse</option>
                          </select>
                       &nbsp;</div>
                        </font></td>
                      <td width="65%"><font size="1" face="Verdana, Arial, Helvetica, sans-serif" color=#000000> 
                        <input type="image" border="0" name="imageField" src="{imgbase}/staff/save_changes.gif">
                        <input name="status" type="hidden" id="status" value="main">
                        <input name="do" type="hidden" id="do" value="update_list_calls">
                        Selecionar todos<font size="1" face="Verdana, Arial, Helvetica, sans-serif" color="#000000"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">
                        <input name="all_c" type="checkbox" id="all_c" onclick="CheckBox(this.checked);" />
                        </font></font></font></td>
                    </tr>
                  </table></td>
              </tr>
              </table></td>
          </tr>
          <tr> 
            <td> </td>
          </tr>
          <tr> 
            <td height="49"> <div align="right"> 
              <table width="350" border="0" cellspacing="1" cellpadding="0" align="right">
                <tr> 
                  <td width="25">&nbsp;</td>
                  <td width="150">&nbsp;</td>
                  <td width="25">&nbsp;</td>
                  <td width="150">&nbsp;</td>
                </tr>
                <tr> 
                  <td width="25"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src="{imgbase}/online.gif"></font></td>
                  <td width="150"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Resposta do Usu&aacute;rio </font></td>
                  <td width="25"><font size="1" face="Verdana, Arial, Helvetica, sans-serif"><img src="{imgbase}/offline.gif"></font></td>
                  <td width="150"><font size="1" face="Verdana, Arial, Helvetica, sans-serif">Resposta do Operador </font></td>
                </tr>
              </table>
              </div></td>
          </tr>
          <tr> 
            <td> <table width="100%" border="0" cellspacing="0" cellpadding="4">
              <tr> 
                <td width="100%" valign="top"> <table width="100%" border="0" cellspacing="0" cellpadding="7">
                    <tr> 
                      <td valign="top"> <table width="100%" border="0" cellspacing="1" cellpadding="2">
                          <tr> 
                            <td width="8%" rowspan="2" valign="top"><img src="{imgbase}/icons/ticket3.jpg" width="41" height="50"></td>
                            <td width="92%"> <div align="left"></div>
                              <font size="2" face="Verdana, Arial, Helvetica, sans-serif"><b>AN&Uacute;NCIOS</b></font></td>
                          </tr>
                          <tr> 
                            <td><div align="center"><font size="2" face="Verdana, Arial, Helvetica, sans-serif">{announcement}{soundb}</font></div></td>
                          </tr>
                        </table></td>
                    </tr>
                  </table></td>
              </tr>
              </table></td>
          </tr>
      </table></td></form>
      <td></td>
    </tr>
</table>
  
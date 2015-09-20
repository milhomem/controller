<iframe frameborder="0" scrolling="no" height="0" src="refresh.cgi" name="online" align="middle"></iframe>
<script type="text/javascript">var imgbase = '{imgbase}';</script> 
<script src="{url_tpl}/functions.js" type="text/javascript" language="javascript"></script>
<head>
<title>{title} - Suporte</title>
<style type="text/css">
BODY {
background: #FFFFFF;
margin-bottom:0px; 
margin-left:0px; 
margin-right:0px; 
margin-top:0px;
padding: 0px;
}

A:active  { COLOR: #006699; TEXT-DECORATION: none }
A:visited { COLOR: #334A9B; TEXT-DECORATION: none }
A:hover   { COLOR: #334A9B; TEXT-DECORATION: underline }
A:link    { COLOR: #334A9B; TEXT-DECORATION: none }
  .query    { BORDER-RIGHT: #666666 1px solid; PADDING-RIGHT: 2px; BORDER-TOP: #666666 1px solid; PADDING-LEFT: 2px; FONT-SIZE: 11px; PADDING-BOTTOM: 3px; BORDER-LEFT: #666666 1px solid; PADDING-TOP: 3px; BORDER-BOTTOM: #666666 1px solid }
  .tbox     { FONT-SIZE: 12px; FONT-FAMILY: Verdana,Arial,Helvetica,sans-serif; COLOR: #000000;	BACKGROUND-COLOR: #ffffff }
  .gbox     { FONT-SIZE: 11px; FONT-FAMILY: Verdana; COLOR: #000000; BACKGROUND-COLOR: #F7F7F7 }
  .ibox     { FONT-SIZE: 11px; FONT-FAMILY: Verdana; COLOR: #000000; BACKGROUND-COLOR: #C9C1DD }


td { font-family:Tahoma;font-size:11px;color:#000000 }
.normal {
	font-family: Tahoma, Verdana, Arial, Helvetica, sans-serif;
	font-size: 12px;
}
.small {
	font-family: Tahoma, Verdana, Arial, Helvetica, sans-serif;
	font-size: 9px;
	font-weight: bold;
}
A.nav:link { COLOR: #202E3E;
                    TEXT-DECORATION: none;}
A.nav:visited { COLOR: #202E3E;
                    TEXT-DECORATION: none;}
A.nav:active { COLOR: #202E3E;
                     TEXT-DECORATION: none;}
A.nav:hover { COLOR: #FF9400;
                      TEXT-DECORATION: none;}
.search {
	FONT-SIZE: 10px;
	FONT-FAMILY: Tahoma,Arial,Helvetica,sans-serif;
	COLOR: #F6F6F6;
    border-top:1px solid;
    border-bottom:1px solid;
    border-left: 1px solid;
    border-right:1px solid;
    BORDER-COLOR: #FFFFFF;
    width: 125px;
    height: 17px;
	BACKGROUND-COLOR: #3E4462
}
</style>
<script language="javascript"> 
if (document.images) { 
image1on = new Image(); 
image1on.src = "{imgbase}/resolved1.gif"; 
image1off = new Image(); 
image1off.src = "{imgbase}/resolved.gif";  
image2on = new Image(); 
image2on.src = "{imgbase}/unresolved1.gif"; 
image2off = new Image(); 
image2off.src = "{imgbase}/unresolved.gif";
image3on = new Image(); 
image3on.src = "{imgbase}/search1.gif"; 
image3off = new Image(); 
image3off.src = "{imgbase}/search.gif";
image4on = new Image(); 
image4on.src = "{imgbase}/profile1.gif"; 
image4off = new Image(); 
image4off.src = "{imgbase}/profile.gif";          
}  
</script> 
</head>
<script>
redirTime="{rtime}";
redirURL="{rurl}";
</script>
<body {rdirector}>

<a name="top"></a>



<!-- Main Outline Table Start -->
<table border="0" cellpadding="0" cellspacing="0" width="100%">
  <tr>
    <td width="100%">
<!-- //Main Outline Table Start -->


<!-- Header Outline Table Start -->
    <table border="0" cellpadding="0" cellspacing="0" width="100%">
      <tr>
        <td width="100%" background="{imgbase}/toprightbg.gif">
<!-- //Header Outline Table Start -->


<!-- Header Start -->
    <table border="0" cellpadding="0" cellspacing="0" width="758">
      <tr>
        <td width="100%" background="{imgbase}/topleftbg.gif">
        <p align="right">
        <img border="0" src="{imgbase}/topleftedge.gif" width="40" height="36"><a onMouseOver="changeImages('image2', 'image2on')" onMouseOut="changeImages('image2', 'image2off')" href="staff.cgi?do=listcalls&status=open"><img name="image2" border="0" src="{imgbase}/unresolved.gif" width="149" height="36" alt="Unresolved"></a><a onMouseOver="changeImages('image1', 'image1on')" onMouseOut="changeImages('image1', 'image1off')" href="staff.cgi?do=listcalls&status=closed"><img name="image1" border="0" src="{imgbase}/resolved.gif" width="149" height="36" alt="Resolved"></a><a onMouseOver="changeImages('image3', 'image3on')" onMouseOut="changeImages('image3', 'image3off')" href="staff.cgi?do=search"><img name="image3" border="0" src="{imgbase}/search.gif" width="149" height="36" alt="Search"></a><a onMouseOver="changeImages('image4', 'image4on')" onMouseOut="changeImages('image4', 'image4off')" href="staff.cgi?do=profile"><img name="image4" border="0" src="{imgbase}/profile.gif" width="149" height="36" alt="Profile"></a><img border="0" src="{imgbase}/toprightedge.gif" width="43" height="36"></td>
      </tr>
    </table>
<!-- Header End -->

<!-- Header Outline Table End -->    
    </td></tr></table>
<!-- //Header Outline Table End -->


<!-- Search Area Table Outline Start -->
     <table border="0" cellpadding="0" cellspacing="0" width="100%">
      <tr>
        <td width="100%" background="{imgbase}/searchbg.gif">
<!-- //Search Area Table Outline Start -->

<!-- Search Area -->
    <table border="0" cellpadding="4" cellspacing="0" width="100%" background="{imgbase}/searchbg.gif">
      <tr>
        <form action="staff.cgi" method="post"><td width="37%">
        <input type="text" name="query" class="search" size="15">&nbsp;<font size="2" face="Verdana, Arial, Helvetica, sans-serif">
        <select class="search" name="select">
           <option value="id">Call ID</option>
           <option value="Username">Usuário</option>
           <option value="email">Email do Remetente</option>
           <option value="subject">Assunto</option>
           <option value="priority">Prioridade</option>
           <option value="description">Texto</option>
        </select>
        </font>
        <input type="image" border="0" src="{imgbase}/go1.gif" width="10" height="10">
        <input type="hidden" name="do" value="sresults">
        <input name="pae" type="hidden" id="pae" value="25"></td>
        <td width="63%">
        <p align="left"><b><font class="small"><font color="#FFFFFF">|</font>&nbsp; <a href="staff.cgi?do=main"><font color="#000000">Home</font></a>&nbsp; <font color="#FFFFFF"></font><font color="#FFFFFF">|</font>&nbsp; <a href="staff.cgi?do=user_details"><font color="#000000">Usu&aacute;rios</font></a>&nbsp; <font color="#FFFFFF"></font><font color="#FFFFFF">|</font>&nbsp; <a href="staff.cgi?do=service_details"><font color="#000000">Servi&ccedil;os</font></a>&nbsp; <font color="#FFFFFF"></font><font color="#FFFFFF">|</font>&nbsp; <a href="staff.cgi?do=log"><font color="#000000">Abrir Ticket</font></a><font color="#FFFFFF">&nbsp;|</font>&nbsp;<a href="staff.cgi?do=navigator"><font color="#000000">Navegador</font></a><font color="#FFFFFF"> &nbsp;|</font> <a href="staff.cgi?do=myperformance"><font color="#000000">
         Performance</font></a><font color="#FFFFFF"> &nbsp;|</font>&nbsp; <a href="staff.cgi?do=logout"><font color="#000000">Logout</font></a>&nbsp;&nbsp;&nbsp; </font></b> </td>
      </form></tr>
    </table>
<!-- //Search Area -->

<!-- Search Area Table Outline End -->
</td></tr></table>
<!-- //Search Area Table Outline End -->
    
    <!-- Shadow Area -->
    <!-- //Shadow Area -->
    
    
<!-- Main Content Table -->
      <table width="87%" border="0" align="center" cellpadding="0" cellspacing="0">
        <tr>
    <td height="24">&nbsp;</td>
  </tr>
  <tr>
          <td height="14"> 
            <div align="center">
	{CONTENT}
	</div>
    </td>
  </tr>
</table>
    <!-- //Main Content Table -->
    
    <!-- Footer Top -->
    <!-- //Footer Nav Area Outline End -->
    
    <!-- Footer Bottom -->
    <!-- //Footer Bottom -->
    
    <!-- Main Table Outline Close -->
    </td>
  </tr>
</table>
<!-- //Main Table Outline Close -->

<p>&nbsp;</p>

</body>

</html>
// Define browser version
var useragent = new String(navigator.userAgent);
if (useragent.match(/IE/g)) var browser = "IE"
else if (useragent.match(/Firefox/g)) var browser = "FF"
else if (useragent.match(/Netscape/g)) var browser = "NS"
else var browser = ""

//Refresh by timer
//redirTime="{rtime}";
//redirURL="{baseurl}/staff.cgi?do=main{rurl}";
function redirTimer() {
	if (redirURL == "") { redirURL = self.location.href};
	if (redirTime != 0) {
		self.setTimeout("self.location.href=redirURL;",redirTime); 
	}
}

//OnLoad
function javaLoad() {
	document.body.onmousedown = hidemenuie5
}
/**

 * This array is used to remember mark status of rows in browse mode

 */

var marked_row = new Array;



/**

 * Sets/unsets the pointer and marker in browse mode

 *

 * @param   object    the table row

 * @param   interger  the row number

 * @param   string    the action calling this script (over, out or click)

 * @param   string    the default background color

 * @param   string    the color to use for mouseover

 * @param   string    the color to use for marking a row

 *

 * @return  boolean  whether pointer is set or not

 */

function setPointer(theRow, theRowNum, theAction, theDefaultColor, thePointerColor, theMarkColor)

{
//Remove /// To Debug
    var theCells = null;
	var Debug = '';
    // 1. Pointer and mark feature are disabled or the browser can't get the
    //    row -> exits
    if ((thePointerColor == '' && theMarkColor == '') || typeof(theRow.style) == 'undefined') {
///		Debug = Debug + 'Desabled\n';
		return false;
    }

	// 2. Gets the current row and exits if the browser can't get it
    if (typeof(document.getElementsByTagName) != 'undefined') {
        theCells = theRow.getElementsByTagName('td');
///		Debug = Debug + '1 theCells '+theCells+'\n';
	} else if (typeof(theRow.cells) != 'undefined') {
        theCells = theRow.cells;
///		Debug = Debug + '2 theCells '+theCells+'\n';
    } else {
        return false;
    }

    // 3. Gets the current color...
    var rowCellsCnt  = theCells.length;
	Debug = Debug + 'rowCellsCnt '+rowCellsCnt+'\n';
    var domDetect = null;
    var currentColor = null;
    var newColor = null;

    // 3.1 ... with DOM compatible browsers except Opera that does not return
    //         valid values with "getAttribute"
    if (typeof(window.opera) == 'undefined' && typeof(theCells[0].getAttribute) != 'undefined') {
        currentColor = theCells[0].getAttribute('bgcolor');
        domDetect    = true;
		Debug = Debug + 'Dom True, CurrentColor: '+currentColor+'\n';
    } else { 	// 3.2 ... with other browsers
        currentColor = theCells[0].style.backgroundColor;
        domDetect = false;
		Debug = Debug + 'Dom False, CurrentColor: '+currentColor+'\n';
    } // end 3

    // 3.3 ... Opera changes colors set via HTML to rgb(r,g,b) format so fix it
    if (currentColor.indexOf("rgb") >= 0) {
        var rgbStr = currentColor.slice(currentColor.indexOf('(') + 1, currentColor.indexOf(')'));
        var rgbValues = rgbStr.split(",");
        currentColor = "#";
        var hexChars = "0123456789ABCDEF";
        for (var i = 0; i < 3; i++) {
            var v = rgbValues[i].valueOf();
            currentColor += hexChars.charAt(v/16) + hexChars.charAt(v%16);
        }
		Debug = Debug + 'CurrentColorHex: '+currentColor+'\n';
    }

    // 4. Defines the new color
    // 4.1 Current color is the default one
	//alert('Current '+currentColor+', Default '+theDefaultColor+', Pointer '+thePointerColor); //DEBUG
	Debug = Debug + 'row marked? '+marked_row[theRowNum]+'\n';
	if (currentColor == '' || currentColor.toLowerCase() == theDefaultColor.toLowerCase()) {
		Debug = Debug + '-Current == Default ou Null\n';
        if (theAction == 'over' && thePointerColor != '') {
            newColor = thePointerColor;
			Debug = Debug + 'Action over, New=PointerColor: '+newColor+'\n';
        } else if (theAction == 'click' && theMarkColor != '') {
            newColor = theMarkColor;
            marked_row[theRowNum] = true;

			//alert(document.getElementById('id').value.indexOf(theRowNum));
			if (document.getElementById('sid').value.indexOf(theRowNum) == -1) {
				document.getElementById('sid').value = document.getElementById('sid').value + theRowNum + ','; //implemented is4web.com.br
			}
			Debug = Debug + 'Action click, New=MarkColor: '+newColor+'\n';
            // Garvin: deactivated onclick marking of the checkbox because it's also executed
            // when an action (like edit/delete) on a single item is performed. Then the checkbox
            // would get deactived, even though we need it activated. Maybe there is a way
            // to detect if the row was clicked, and not an item therein...
            // document.getElementById('id_rows_to_delete' + theRowNum).checked = true;
        }
    } else if (currentColor.toLowerCase() == thePointerColor.toLowerCase() && (typeof(marked_row[theRowNum]) == 'undefined' || !marked_row[theRowNum])) { // 4.1.2 Current color is the pointer one
		Debug = Debug + '-Current == Pointer ou not RowMarked\n';
		if (theAction == 'out') {
            newColor = theDefaultColor;
			Debug = Debug + 'Action out, New=DefaultColor: '+theDefaultColor+'\n';
        } else if (theAction == 'click' && theMarkColor != '') {
            newColor = theMarkColor;
            marked_row[theRowNum] = true;
			Debug = Debug + 'Action click, New=MarkColor: '+theMarkColor+'\n';
			//alert(document.getElementById('id').value.indexOf(theRowNum));
			if (document.getElementById('sid').value.indexOf(theRowNum) == -1) {
				document.getElementById('sid').value = document.getElementById('sid').value + theRowNum + ','; //implemented is4web.com.br
			}
            // document.getElementById('id_rows_to_delete' + theRowNum).checked = true;
        }
    } else if (currentColor.toLowerCase() == theMarkColor.toLowerCase()) {// 4.1.3 Current color is the marker one
		Debug = Debug + '-Current == MarkColor\n';
		if (theAction == 'click') {
            newColor = (thePointerColor != '') ? thePointerColor : theDefaultColor;
            marked_row[theRowNum] = (typeof(marked_row[theRowNum]) == 'undefined' || !marked_row[theRowNum]) ? true : null;
			// document.getElementById('id_rows_to_delete' + theRowNum).checked = false;
			if (!marked_row[theRowNum]) {
				document.getElementById('sid').value = document.getElementById('sid').value.replace(theRowNum+',',''); //implemented is4web.com.br
				//alert(document.getElementById('sid').value);
			}
			Debug = Debug + 'Action click, New=Point ou Default : '+thePointerColor+theDefaultColor+'\n';			
        }
    } // end 4

    // 5. Sets the new color...
    if (newColor) {
        var c = null;
        // 5.1 ... with DOM compatible browsers except Opera
        if (domDetect) {
            for (c = 0; c < rowCellsCnt; c++) {
                theCells[c].setAttribute('bgcolor', newColor, 0);
            } // end for
        } else {// 5.2 ... with other browsers
            for (c = 0; c < rowCellsCnt; c++) {
                theCells[c].style.backgroundColor = newColor;
            }
        }
    } // end 5

//	document.getElementById('logwindow').innerHTML = Debug;
    return true;
} // end of the 'setPointer()' function



function FormataCPF(Campo, teclapres){

	var tecla = teclapres.keyCode;

	

	var vr = new String(Campo.value);

	vr = vr.replace(".", "");

	vr = vr.replace(".", "");

	vr = vr.replace("-", "");

	vr = vr.replace("/", "");

'	vr = vr.replace(/[A-Za-z]/g, "");'

	vr = vr.replace(/\D/g, "");	



	tam = vr.length + 1;

	

	if (tecla != 8 && tecla != 9){

		if (tam <= 3)

			Campo.value = vr;

		if (tam > 3 && tam < 7)

			Campo.value = vr.substr(0, 3) + '.' + vr.substr(3, tam);

		if (tam >= 7 && tam <10)

			Campo.value = vr.substr(0,3) + '.' + vr.substr(3,3) + '.' + vr.substr(6,tam-6);

		if (tam >= 10 && tam < 12)

			Campo.value = vr.substr(0,3) + '.' + vr.substr(3,3) + '.' + vr.substr(6,3) + '-' + vr.substr(9,tam-9);

		if (tam >= 13 && tam < 14)

			Campo.value = vr.substr(0,2) + '.' + vr.substr(2,3) + '.' + vr.substr(5,3) + '/' + vr.substr(8,tam-8);

		if (tam >= 14 && tam < 19)

			Campo.value = vr.substr(0,2) + '.' + vr.substr(2,3) + '.' + vr.substr(5,3) + '/' + vr.substr(8,4) + '-' + vr.substr(12,tam-12);

		}

}



// confirmar redirecionamento

function confirma(action,url){

	var action;

	var url;

	if(confirm("Comfirmar "+action+"?")){
		if (action == "criar") {
			alert("Escolha entre as opções");
			if(confirm("Ativar o serviço imediatamente?")) {
				url=url+'yes';
			}else if(confirm("Ativar o serviço após quitar fatura?")) {
				url=url+'wait';
			}else if (confirm("Não ativar o serviço?")) {
				url=url+'no';
//como fazer um input dos dias gratis
//como colocar o confirm com sim e nao
			} else {
				return(false);
			}

			if (confirm("Cobrar taxa de setup?")) {
			} else {
				url=url+'&setup=no';
			}
			
			window.location=url;
		} else {
			window.location=url;	
		}
	}else{
		return(false);
	}

}



// marca todos os checkbox do form

function CheckBox(ckall) { 
//	var actVar = ckall.checked ;
	var actVar = ckall;
	for(i=0; i<Checkform.length; i++) {
		if (Checkform.elements[i].type == "checkbox") {
				Checkform.elements[i].checked = actVar;
		}
	}
}

function getChecked(radioObj) {
	if(!radioObj)
		return null;
	var radioLength = radioObj.length;
	if(radioLength == undefined)
		if(radioObj.checked)
			return radioObj;
		else
			return null;
	for(var i = 0; i < radioLength; i++) {
		if(radioObj[i].checked) {
			return radioObj[i];
		}
	}
	return null;
}


// display the tree id

function toggleDisp(nodeid) {

	layer = document.getElementById('treeElement' + nodeid);

	img = document.getElementById('treeIcon' + nodeid);	

	if(layer.style.display == 'none') {

		expand(0,1)

		layer.style.display = 'block';

		if (img) { img.src = imgbase+'/minusIcon.png'; }

	} else {

		layer.style.display = 'none';

		if (img) { img.src = imgbase+'/plusIcon.png';}

	}

}



// expand all tree

function expand(expand, force) {

	counter = 0;

	while(document.getElementById('treeElement' + counter)) {

		if(!expand) {

			//dont shrink if this element is the one passed in the URL

			arr = document.getElementById('treeElement' + counter).getElementsByTagName('a');

			txt = ''; found = 0;

			loc = new String(document.location);

			for(i=0; i < arr.length; i++) {

				txt = txt + arr.item(i).href;

				tmpHref = new String(arr.item(i).href);

				if(tmpHref.substr(tmpHref.indexOf('#')) == loc.substr(loc.indexOf('#'))) {

					//give this tree node the right icon

					document.getElementById('treeIcon' + counter).src = imgbase+'/minusIcon.png';

					found = 1;

				}

			}

			if(!found | force) {

				document.getElementById('treeIcon' + counter).src = imgbase+'/plusIcon.png';

				document.getElementById('treeElement' + counter).style.display = 'none';

			}

		} else {

			document.getElementById('treeElement' + counter).style.display = 'block';

			document.getElementById('treeIcon' + counter).src = imgbase+'/minusIcon.png';

		}

		counter++;

	}

}



//arrumar

if (document.images) { 

	image1on = new Image(); 

	image1on.src = imgbase+"/users1.gif"; 

	image1off = new Image(); 

	image1off.src = imgbase+"/users.gif";  

	image2on = new Image(); 

	image2on.src = imgbase+"/staff1.gif"; 

	image2off = new Image(); 

	image2off.src = imgbase+"/staff.gif";

	image3on = new Image(); 

	image3on.src = imgbase+"/requests1.gif"; 

	image3off = new Image(); 

	image3off.src = imgbase+"/requests.gif";

	image4on = new Image(); 

	image4on.src = imgbase+"/settings1.gif"; 

	image4off = new Image(); 

	image4off.src = imgbase+"/settings.gif";

	image5on = new Image(); 

	image5on.src = imgbase+"/profile1.gif"; 

	image5off = new Image(); 

	image5off.src = imgbase+"/profile.gif";             

}  



function changeImages() { 

	if (document.images) { 

		for (var i=0; i<changeImages.arguments.length; i+=2) { 

		document[changeImages.arguments[i]].src = eval(changeImages.arguments[i+1] + ".src"); 

		} 

	} 

} 



function Popup(url, window_name, window_width, window_height) 

{ 

    settings="toolbar=no,location=no,directories=no,"+ 

             "status=no,menubar=no,scrollbars=yes,"+ 

             "resizable=yes,width="+window_width+",height="+window_height; 

    NewWindow=window.open(url,window_name,settings); 

}



function DisableForm (formname)  {
<!-- Prevent The Form being submitted twice -->
     	for (i=1; i<formname.elements.length; i++){   
    		if (formname.elements[i].type.toLowerCase() == 'submit' || formname.elements[i].type.toLowerCase() == 'reset')  {  
    			formname.elements[i].disabled = true;
    			formname.elements[i].value = 'Processando...';  
    		}
    	}
    formname.submit();
}
		  

function Disable (formname)  

      {

	      for (i=1; i<formname.elements.length; i++)   {   if (formname.elements[i].type == 'text')  {  formname.elements[i].onFocus = blur;  }  }

	  }



function MM_jumpMenu(targ,selObj,restore){ //v3.0

  eval(targ+".location='"+selObj.options[selObj.selectedIndex].value+"'");

  if (restore) selObj.selectedIndex=0;

} 



//scrolling down/up

var sRepeat=null

function doScrollerIE(dir, src, amount) {

	if (amount==null) amount=10

	// Move the top of the contents up or down

	// in the viewport

	if (dir=="up")

		document.all[src].scrollTop-=amount

	else

		document.all[src].scrollTop+=amount



	// Check if to repeat

	if (sRepeat==null)

		sRepeat = setInterval("doScrollerIE('" + dir + "','" + src + "'," + amount + ")",100)

	return false

}



// Used to end repeating scrolling

window.document.onmouseup = new Function("clearInterval(sRepeat);sRepeat=null")

window.document.ondragstart = new Function("return false")



// fim de scroll


//sub menu
var menuskin = "skin1"; // skin0, or skin1
var display_url = 0; // Show URLs in status bar?

function showmenu() {
	var rightedge = document.body.clientWidth-event.clientX;
	var bottomedge = document.body.clientHeight-event.clientY;
	if (rightedge < menu.offsetWidth)
		menu.style.left = document.body.scrollLeft + event.clientX - menu.offsetWidth;
	else
		menu.style.left = document.body.scrollLeft + event.clientX;
	if (bottomedge < menu.offsetHeight)
		menu.style.top = document.body.scrollTop + event.clientY - menu.offsetHeight;
	else
		menu.style.top = document.body.scrollTop + event.clientY;
		menu.style.visibility = "visible";
	return false;
}

function hidemenu() {
	menu.style.visibility = "hidden";
}

function showmenuie5(objid) {
	div = document.getElementById('menu' + objid);
	var rightedge = document.body.clientWidth-event.clientX;
	var bottomedge = document.body.clientHeight-event.clientY;
	if (rightedge < div.offsetWidth)
		div.style.left = document.body.scrollLeft + event.clientX - div.offsetWidth;
	else
		div.style.left = document.body.scrollLeft + event.clientX;
	if (bottomedge < div.offsetHeight)
		div.style.top = document.body.scrollTop + event.clientY - div.offsetHeight;
	else
		div.style.top = document.body.scrollTop + event.clientY;
		div.style.visibility = "visible";
	return false;
}

function hidemenuie5() {
	counter = 1;
	while(document.getElementById('menu' + counter)) {
		if (document.getElementById('menu' + counter).style.visibility = "visible") {
			document.getElementById('menu' + counter).style.visibility = "hidden";
		}
		counter++;
	}
}

function highlightie5() {
	if (event.srcElement.className == "menuitems") {
		event.srcElement.style.backgroundColor = "highlight";
		oldcolor = event.srcElement.style.color;
		event.srcElement.style.color = "white";
	if (display_url)
		window.status = event.srcElement.url;
	}
}

function lowlightie5() {
	if (event.srcElement.className == "menuitems") {
		event.srcElement.style.backgroundColor = "";
		event.srcElement.style.color = oldcolor; //"black";
		window.status = "";
   }
}

function jumptoie5() {
	if (event.srcElement.className == "menuitems") {
	if (event.srcElement.getAttribute("target") != null)
		window.open(event.srcElement.url, event.srcElement.getAttribute("target"));
	else
		window.location = event.srcElement.url;
	}
}


/*
function addpg(invid)
{
	var htm = document.getElementById(invid).innerHTML
	var idx = htm.indexOf(invid);
	if (idx > -1) {
		htm = htm.replace( 'Fatura '+invid+": Valor pago R$<INPUT class=gbox name=pago><BR>Data pagamento:<INPUT class=gbox name=pagamento><BR>", '' );
	} else {
		htm = htm + 'Fatura '+invid+": Valor pago R$<input class=gbox type=text name=pago><br>Data pagamento:<INPUT class=gbox name=pagamento><BR>"
	}
	document.getElementById(invid).innerHTML = htm;
}
*/
//  End -->


// Drag and drop script
/**************************************************
 * dom-drag.js
 * 09.25.2001
 * www.youngpup.net
 * Script featured on Dynamic Drive (http://www.dynamicdrive.com) 12.08.2005
 **************************************************
 * 10.28.2001 - fixed minor bug where events
 * sometimes fired off the handle, not the root.
 **************************************************/

var Drag = {

	obj : null,

	init : function(o, oRoot, minX, maxX, minY, maxY, bSwapHorzRef, bSwapVertRef, fXMapper, fYMapper)
	{
		o.onmousedown	= Drag.start;

		o.hmode			= bSwapHorzRef ? false : true ;
		o.vmode			= bSwapVertRef ? false : true ;

		o.root = oRoot && oRoot != null ? oRoot : o ;

		if (o.hmode  && isNaN(parseInt(o.root.style.left  ))) o.root.style.left   = "0px";
		if (o.vmode  && isNaN(parseInt(o.root.style.top   ))) o.root.style.top    = "0px";
		if (!o.hmode && isNaN(parseInt(o.root.style.right ))) o.root.style.right  = "0px";
		if (!o.vmode && isNaN(parseInt(o.root.style.bottom))) o.root.style.bottom = "0px";

		o.minX	= typeof minX != 'undefined' ? minX : null;
		o.minY	= typeof minY != 'undefined' ? minY : null;
		o.maxX	= typeof maxX != 'undefined' ? maxX : null;
		o.maxY	= typeof maxY != 'undefined' ? maxY : null;

		o.xMapper = fXMapper ? fXMapper : null;
		o.yMapper = fYMapper ? fYMapper : null;

		o.root.onDragStart	= new Function();
		o.root.onDragEnd	= new Function();
		o.root.onDrag		= new Function();
	},

	start : function(e)
	{
		var o = Drag.obj = this;
		e = Drag.fixE(e);
		var y = parseInt(o.vmode ? o.root.style.top  : o.root.style.bottom);
		var x = parseInt(o.hmode ? o.root.style.left : o.root.style.right );
		o.root.onDragStart(x, y);

		o.lastMouseX	= e.clientX;
		o.lastMouseY	= e.clientY;

		if (o.hmode) {
			if (o.minX != null)	o.minMouseX	= e.clientX - x + o.minX;
			if (o.maxX != null)	o.maxMouseX	= o.minMouseX + o.maxX - o.minX;
		} else {
			if (o.minX != null) o.maxMouseX = -o.minX + e.clientX + x;
			if (o.maxX != null) o.minMouseX = -o.maxX + e.clientX + x;
		}

		if (o.vmode) {
			if (o.minY != null)	o.minMouseY	= e.clientY - y + o.minY;
			if (o.maxY != null)	o.maxMouseY	= o.minMouseY + o.maxY - o.minY;
		} else {
			if (o.minY != null) o.maxMouseY = -o.minY + e.clientY + y;
			if (o.maxY != null) o.minMouseY = -o.maxY + e.clientY + y;
		}

		document.onmousemove	= Drag.drag;
		document.onmouseup		= Drag.end;

		return false;
	},

	drag : function(e)
	{
		e = Drag.fixE(e);
		var o = Drag.obj;

		var ey	= e.clientY;
		var ex	= e.clientX;
		var y = parseInt(o.vmode ? o.root.style.top  : o.root.style.bottom);
		var x = parseInt(o.hmode ? o.root.style.left : o.root.style.right );
		var nx, ny;

		if (o.minX != null) ex = o.hmode ? Math.max(ex, o.minMouseX) : Math.min(ex, o.maxMouseX);
		if (o.maxX != null) ex = o.hmode ? Math.min(ex, o.maxMouseX) : Math.max(ex, o.minMouseX);
		if (o.minY != null) ey = o.vmode ? Math.max(ey, o.minMouseY) : Math.min(ey, o.maxMouseY);
		if (o.maxY != null) ey = o.vmode ? Math.min(ey, o.maxMouseY) : Math.max(ey, o.minMouseY);

		nx = x + ((ex - o.lastMouseX) * (o.hmode ? 1 : -1));
		ny = y + ((ey - o.lastMouseY) * (o.vmode ? 1 : -1));

		if (o.xMapper)		nx = o.xMapper(y)
		else if (o.yMapper)	ny = o.yMapper(x)

		Drag.obj.root.style[o.hmode ? "left" : "right"] = nx + "px";
		Drag.obj.root.style[o.vmode ? "top" : "bottom"] = ny + "px";
		Drag.obj.lastMouseX	= ex;
		Drag.obj.lastMouseY	= ey;

		Drag.obj.root.onDrag(nx, ny);
		return false;
	},

	end : function()
	{
		document.onmousemove = null;
		document.onmouseup   = null;
		Drag.obj.root.onDragEnd(	parseInt(Drag.obj.root.style[Drag.obj.hmode ? "left" : "right"]), 
									parseInt(Drag.obj.root.style[Drag.obj.vmode ? "top" : "bottom"]));
		Drag.obj = null;
	},

	fixE : function(e)
	{
		if (typeof e == 'undefined') e = window.event;
		if (typeof e.layerX == 'undefined') e.layerX = e.offsetX;
		if (typeof e.layerY == 'undefined') e.layerY = e.offsetY;
		return e;
	}
};

//Drag com root
//var theHandle = document.getElementById("handle");
//var theRoot = document.getElementById("root");
//Drag.init(theHandle, theRoot);



//Calendar Script
/***********************************************
 Fool-Proof Date Input Script with DHTML Calendar
 by Jason Moon - calendar@moonscript.com
 ************************************************/

// Customizable variables
var DefaultDateFormat = 'MM/DD/YYYY'; // If no date format is supplied, this will be used instead
var HideWait = 3; // Number of seconds before the calendar will disappear
var Y2kPivotPoint = 76; // 2-digit years before this point will be created in the 21st century
var UnselectedMonthText = ''; // Text to display in the 1st month list item when the date isn't required
var FontSize = 11; // In pixels
var FontFamily = 'Tahoma';
var CellWidth = 18;
var CellHeight = 16;
var ClearURL = imgbase + '/dot.gif';
var ImageURL = imgbase + '/calendar.jpg';
var NextURL = imgbase + '/next.gif';
var PrevURL = imgbase + '/prev.gif';
var CalBGColor = 'white';
var TopRowBGColor = 'buttonface';
var DayBGColor = 'lightgrey';

// Global variables
var ZCounter = 100;
var Today = new Date();
//var WeekDays = new Array('S','M','T','W','T','F','S');
var WeekDays = new Array('D','S','T','Q','Q','S','S');
var MonthDays = new Array(31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31);
//definir em script pela linguagem
var MonthNames = new Array('Janeiro','Fevereiro','Março','Abril','Maio','Junho','Julho','Agosto','Setembro','Outubro','Novembro','Dezembro');
//var MonthNames = new Array('January','February','March','April','May','June','July','August','September','October','November','December');

// Write out the stylesheet definition for the calendar
with (document) {
   writeln('<style>');
   writeln('td.calendarDateInput {letter-spacing:normal;line-height:normal;font-family:' + FontFamily + ',Sans-Serif;font-size:' + FontSize + 'px;}');
   writeln('select.calendarDateInput {letter-spacing:.06em;font-family:Verdana,Sans-Serif;font-size:11px;}');
   writeln('input.calendarDateInput {letter-spacing:.06em;font-family:Verdana,Sans-Serif;font-size:11px;}');
   writeln('</style>');
}

// Only allows certain keys to be used in the date field
function YearDigitsOnly(e) {
   var KeyCode = (e.keyCode) ? e.keyCode : e.which;
   return ((KeyCode == 8) // backspace
        || (KeyCode == 9) // tab
        || (KeyCode == 37) // left arrow
        || (KeyCode == 39) // right arrow
        || (KeyCode == 46) // delete
        || ((KeyCode > 47) && (KeyCode < 58)) // 0 - 9
   );
}

// Gets the absolute pixel position of the supplied element
function GetTagPixels(StartTag, Direction) {
   var PixelAmt = (Direction == 'LEFT') ? StartTag.offsetLeft : StartTag.offsetTop;
   while ((StartTag.tagName != 'BODY') && (StartTag.tagName != 'HTML')) {
      StartTag = StartTag.offsetParent;
      PixelAmt += (Direction == 'LEFT') ? StartTag.offsetLeft : StartTag.offsetTop;
   }
   return PixelAmt;
}

// Is the specified select-list behind the calendar?
function BehindCal(SelectList, CalLeftX, CalRightX, CalTopY, CalBottomY, ListTopY) {
   var ListLeftX = GetTagPixels(SelectList, 'LEFT');
   var ListRightX = ListLeftX + SelectList.offsetWidth;
   var ListBottomY = ListTopY + SelectList.offsetHeight;
   return (((ListTopY < CalBottomY) && (ListBottomY > CalTopY)) && ((ListLeftX < CalRightX) && (ListRightX > CalLeftX)));
}

// For IE, hides any select-lists that are behind the calendar
function FixSelectLists(Over) {
   if (navigator.appName == 'Microsoft Internet Explorer') {
      var CalDiv = this.getCalendar();
      var CalLeftX = CalDiv.offsetLeft;
      var CalRightX = CalLeftX + CalDiv.offsetWidth;
      var CalTopY = CalDiv.offsetTop;
      var CalBottomY = CalTopY + (CellHeight * 9);
      var FoundCalInput = false;
      formLoop :
      for (var j=this.formNumber;j<document.forms.length;j++) {
         for (var i=0;i<document.forms[j].elements.length;i++) {
            if (typeof document.forms[j].elements[i].type == 'string') {
               if ((document.forms[j].elements[i].type == 'hidden') && (document.forms[j].elements[i].name == this.hiddenFieldName)) {
                  FoundCalInput = true;
                  i += 3; // 3 elements between the 1st hidden field and the last year input field
               }
               if (FoundCalInput) {
                  if (document.forms[j].elements[i].type.substr(0,6) == 'select') {
                     ListTopY = GetTagPixels(document.forms[j].elements[i], 'TOP');
                     if (ListTopY < CalBottomY) {
                        if (BehindCal(document.forms[j].elements[i], CalLeftX, CalRightX, CalTopY, CalBottomY, ListTopY)) {
                           document.forms[j].elements[i].style.visibility = (Over) ? 'hidden' : 'visible';
                        }
                     }
                     else break formLoop;
                  }
               }
            }
         }
      }
   }
}

// Displays a message in the status bar when hovering over the calendar days
function DayCellHover(Cell, Over, Color, HoveredDay) {
   Cell.style.backgroundColor = (Over) ? DayBGColor : Color;
   if (Over) {
      if ((this.yearValue == Today.getFullYear()) && (this.monthIndex == Today.getMonth()) && (HoveredDay == Today.getDate())) self.status = 'Click to select today';
      else {
         var Suffix = HoveredDay.toString();
         switch (Suffix.substr(Suffix.length - 1, 1)) {
            case '1' : Suffix += (HoveredDay == 11) ? 'th' : 'st'; break;
            case '2' : Suffix += (HoveredDay == 12) ? 'th' : 'nd'; break;
            case '3' : Suffix += (HoveredDay == 13) ? 'th' : 'rd'; break;
            default : Suffix += 'th'; break;
         }
         self.status = 'Click to select ' + this.monthName + ' ' + Suffix;
      }
   }
   else self.status = '';
   return true;
}

// Sets the form elements after a day has been picked from the calendar
function PickDisplayDay(ClickedDay) {
   this.show();
//   var MonthList = this.getMonthList();
//   var DayList = this.getDayList();
//   var YearField = this.getYearField();
   var Data = this.getData();
//   FixDayList(DayList, GetDayCount(this.displayed.yearValue, this.displayed.monthIndex));
   // Select the month and day in the lists
//   for (var i=0;i<MonthList.length;i++) {
//      if (MonthList.options[i].value == this.displayed.monthIndex) MonthList.options[i].selected = true;
//   }
//   for (var j=1;j<=DayList.length;j++) {
//      if (j == ClickedDay) DayList.options[j-1].selected = true;
//   }
   this.setPicked(this.displayed.yearValue, this.displayed.monthIndex, ClickedDay);
   // Change the year, if necessary
//   YearField.value = this.picked.yearPad;
//   YearField.defaultValue = YearField.value;
   ClickedDay = ClickedDay < 10 ? '0'+ClickedDay : ClickedDay;
   ClickedMonth = (this.displayed.monthIndex + 1) < 10 ? '0'+(this.displayed.monthIndex + 1) : (this.displayed.monthIndex + 1);
   Data.value=ClickedDay+ this.delimiter + ClickedMonth + this.delimiter + this.picked.yearPad;
}

// Builds the HTML for the calendar days
function BuildCalendarDays() {
   var Rows = 5;
   if (((this.displayed.dayCount == 31) && (this.displayed.firstDay > 4)) || ((this.displayed.dayCount == 30) && (this.displayed.firstDay == 6))) Rows = 6;
   else if ((this.displayed.dayCount == 28) && (this.displayed.firstDay == 0)) Rows = 4;
   var HTML = '<table width="' + (CellWidth * 7) + '" cellspacing="0" cellpadding="1" style="cursor:default">';
   for (var j=0;j<Rows;j++) {
      HTML += '<tr>';
      for (var i=1;i<=7;i++) {
         Day = (j * 7) + (i - this.displayed.firstDay);
         if ((Day >= 1) && (Day <= this.displayed.dayCount)) {
            if ((this.displayed.yearValue == this.picked.yearValue) && (this.displayed.monthIndex == this.picked.monthIndex) && (Day == this.picked.day)) {
               TextStyle = 'color:white;font-weight:bold;'
               BackColor = DayBGColor;
            }
            else {
               TextStyle = 'color:black;'
               BackColor = CalBGColor;
            }
            if ((this.displayed.yearValue == Today.getFullYear()) && (this.displayed.monthIndex == Today.getMonth()) && (Day == Today.getDate())) TextStyle += 'border:1px solid darkred;padding:0px;';
            HTML += '<td align="center" class="calendarDateInput" style="cursor:default;height:' + CellHeight + ';width:' + CellWidth + ';' + TextStyle + ';background-color:' + BackColor + '" onClick="' + this.objName + '.pickDay(' + Day + ')" onMouseOver="return ' + this.objName + '.displayed.dayHover(this,true,\'' + BackColor + '\',' + Day + ')" onMouseOut="return ' + this.objName + '.displayed.dayHover(this,false,\'' + BackColor + '\')">' + Day + '</td>';
         }
         else HTML += '<td class="calendarDateInput" style="height:' + CellHeight + '">&nbsp;</td>';
      }
      HTML += '</tr>';
   }
   return HTML += '</table>';
}

// Determines which century to use (20th or 21st) when dealing with 2-digit years
function GetGoodYear(YearDigits) {
   if (YearDigits.length == 4) return YearDigits;
   else {
      var Millennium = (YearDigits < Y2kPivotPoint) ? 2000 : 1900;
      return Millennium + parseInt(YearDigits,10);
   }
}

// Returns the number of days in a month (handles leap-years)
function GetDayCount(SomeYear, SomeMonth) {
   return ((SomeMonth == 1) && ((SomeYear % 400 == 0) || ((SomeYear % 4 == 0) && (SomeYear % 100 != 0)))) ? 29 : MonthDays[SomeMonth];
}

// Highlights the buttons
function VirtualButton(Cell, ButtonDown) {
   if (ButtonDown) {
      Cell.style.borderLeft = 'buttonshadow 1px solid';
      Cell.style.borderTop = 'buttonshadow 1px solid';
      Cell.style.borderBottom = 'buttonhighlight 1px solid';
      Cell.style.borderRight = 'buttonhighlight 1px solid';
   }
   else {
      Cell.style.borderLeft = 'buttonhighlight 1px solid';
      Cell.style.borderTop = 'buttonhighlight 1px solid';
      Cell.style.borderBottom = 'buttonshadow 1px solid';
      Cell.style.borderRight = 'buttonshadow 1px solid';
   }
}

// Mouse-over for the previous/next month buttons
function NeighborHover(Cell, Over, DateObj) {
   if (Over) {
      VirtualButton(Cell, false);
      self.status = 'Click to view ' + DateObj.fullName;
   }
   else {
      Cell.style.border = 'buttonface 1px solid';
      self.status = '';
   }
   return true;
}

// Adds/removes days from the day list, depending on the month/year
function FixDayList(DayList, NewDays) {
   var DayPick = DayList.selectedIndex + 1;
   if (NewDays != DayList.length) {
      var OldSize = DayList.length;
      for (var k=Math.min(NewDays,OldSize);k<Math.max(NewDays,OldSize);k++) {
         (k >= NewDays) ? DayList.options[NewDays] = null : DayList.options[k] = new Option(k+1, k+1);
      }
      DayPick = Math.min(DayPick, NewDays);
      DayList.options[DayPick-1].selected = true;
   }
   return DayPick;
}

// Resets the year to its previous valid value when something invalid is entered
function FixYearInput(YearField) {
   var YearRE = new RegExp('\\d{' + YearField.defaultValue.length + '}');
   if (!YearRE.test(YearField.value)) YearField.value = YearField.defaultValue;
}

// Displays a message in the status bar when hovering over the calendar icon
function CalIconHover(Over) {
   var Message = (this.isShowing()) ? 'hide' : 'show';
   self.status = (Over) ? 'Click to ' + Message + ' the calendar' : '';
   return true;
}

// Starts the timer over from scratch
function CalTimerReset() {
   eval('clearTimeout(' + this.timerID + ')');
   eval(this.timerID + '=setTimeout(\'' + this.objName + '.show()\',' + (HideWait * 1000) + ')');
}

// The timer for the calendar
function DoTimer(CancelTimer) {
   if (CancelTimer) eval('clearTimeout(' + this.timerID + ')');
   else {
      eval(this.timerID + '=null');
      this.resetTimer();
   }
}

// Show or hide the calendar
function ShowCalendar() {
   if (this.isShowing()) {
      var StopTimer = true;
      this.getCalendar().style.zIndex = --ZCounter;
      this.getCalendar().style.visibility = 'hidden';
      this.fixSelects(false);
   }
   else {
      var StopTimer = false;
      this.fixSelects(true);
      this.getCalendar().style.zIndex = ++ZCounter;
      this.getCalendar().style.visibility = 'visible';
   }
   this.handleTimer(StopTimer);
   self.status = '';
}

// Hides the input elements when the "blank" month is selected
function SetElementStatus(Hide) {
   this.getDayList().style.visibility = (Hide) ? 'hidden' : 'visible';
   this.getYearField().style.visibility = (Hide) ? 'hidden' : 'visible';
   this.getCalendarLink().style.visibility = (Hide) ? 'hidden' : 'visible';
}

// Sets the date, based on the month selected
function CheckMonthChange(MonthList) {
   var DayList = this.getDayList();
   if (MonthList.options[MonthList.selectedIndex].value == '') {
      DayList.selectedIndex = 0;
      this.hideElements(true);
      this.setHidden('');
   }
   else {
      this.hideElements(false);
      if (this.isShowing()) {
         this.resetTimer(); // Gives the user more time to view the calendar with the newly-selected month
         this.getCalendar().style.zIndex = ++ZCounter; // Make sure this calendar is on top of any other calendars
      }
      var DayPick = FixDayList(DayList, GetDayCount(this.picked.yearValue, MonthList.options[MonthList.selectedIndex].value));
      this.setPicked(this.picked.yearValue, MonthList.options[MonthList.selectedIndex].value, DayPick);
   }
}

// Sets the date, based on the day selected
function CheckDayChange(DayList) {
   if (this.isShowing()) this.show();
   this.setPicked(this.picked.yearValue, this.picked.monthIndex, DayList.selectedIndex+1);
}

// Changes the date when a valid year has been entered
function CheckYearInput(YearField) {
   if ((YearField.value.length == YearField.defaultValue.length) && (YearField.defaultValue != YearField.value)) {
      if (this.isShowing()) {
         this.resetTimer(); // Gives the user more time to view the calendar with the newly-entered year
         this.getCalendar().style.zIndex = ++ZCounter; // Make sure this calendar is on top of any other calendars
      }
      var NewYear = GetGoodYear(YearField.value);
      var MonthList = this.getMonthList();
      var NewDay = FixDayList(this.getDayList(), GetDayCount(NewYear, this.picked.monthIndex));
      this.setPicked(NewYear, this.picked.monthIndex, NewDay);
      YearField.defaultValue = YearField.value;
   }
}

// Holds characteristics about a date
function dateObject() {
   if (Function.call) { // Used when 'call' method of the Function object is supported
      var ParentObject = this;
      var ArgumentStart = 0;
   }
   else { // Used with 'call' method of the Function object is NOT supported
      var ParentObject = arguments[0];
      var ArgumentStart = 1;
   }
   ParentObject.date = (arguments.length == (ArgumentStart+1)) ? new Date(arguments[ArgumentStart+0]) : new Date(arguments[ArgumentStart+0], arguments[ArgumentStart+1], arguments[ArgumentStart+2], 12, 0, 0); //Bug de daylight
   ParentObject.yearValue = ParentObject.date.getFullYear();
   ParentObject.monthIndex = ParentObject.date.getMonth();
   ParentObject.monthName = MonthNames[ParentObject.monthIndex];
   ParentObject.fullName = ParentObject.monthName + ' ' + ParentObject.yearValue;
   ParentObject.day = ParentObject.date.getDate();
   ParentObject.dayCount = GetDayCount(ParentObject.yearValue, ParentObject.monthIndex);
   var FirstDate = new Date(ParentObject.yearValue, ParentObject.monthIndex, 1);
   ParentObject.firstDay = FirstDate.getDay();
}

// Keeps track of the date that goes into the hidden field
function storedMonthObject(DateFormat, DateYear, DateMonth, DateDay) {
   (Function.call) ? dateObject.call(this, DateYear, DateMonth, DateDay) : dateObject(this, DateYear, DateMonth, DateDay);
   this.yearPad = this.yearValue.toString();
   this.monthPad = (this.monthIndex < 9) ? '0' + String(this.monthIndex + 1) : this.monthIndex + 1;
   this.dayPad = (this.day < 10) ? '0' + this.day.toString() : this.day;
   this.monthShort = this.monthName.substr(0,3).toUpperCase();
   // Formats the year with 2 digits instead of 4
   if (DateFormat.indexOf('YYYY') == -1) this.yearPad = this.yearPad.substr(2);
   // Define the date-part delimiter
   if (DateFormat.indexOf('/') >= 0) var Delimiter = '/';
   else if (DateFormat.indexOf('-') >= 0) var Delimiter = '-';
   else var Delimiter = '';
   // Determine the order of the months and days
   if (/DD?.?((MON)|(MM?M?))/.test(DateFormat)) {
      this.formatted = this.dayPad + Delimiter;
      this.formatted += (RegExp.$1.length == 3) ? this.monthShort : this.monthPad;
   }
   else if (/((MON)|(MM?M?))?.?DD?/.test(DateFormat)) {
      this.formatted = (RegExp.$1.length == 3) ? this.monthShort : this.monthPad;
      this.formatted += Delimiter + this.dayPad;
   }
   // Either prepend or append the year to the formatted date
   this.formatted = (DateFormat.substr(0,2) == 'YY') ? this.yearPad + Delimiter + this.formatted : this.formatted + Delimiter + this.yearPad;
}

// Object for the current displayed month
function displayMonthObject(ParentObject, DateYear, DateMonth, DateDay) {
   (Function.call) ? dateObject.call(this, DateYear, DateMonth, DateDay) : dateObject(this, DateYear, DateMonth, DateDay);
   this.displayID = ParentObject.hiddenFieldName + '_Current_ID';
   this.ydisplayID = ParentObject.hiddenFieldName + '_YCurrent_ID';
   this.getDisplay = new Function('return document.getElementById(this.displayID)');
   this.ygetDisplay = new Function('return document.getElementById(this.ydisplayID)');   
   this.dayHover = DayCellHover;
   this.goCurrent = new Function(ParentObject.objName + '.getCalendar().style.zIndex=++ZCounter;' + ParentObject.objName + '.setDisplayed(Today.getFullYear(),Today.getMonth());');
   if (ParentObject.formNumber >= 0) this.getDisplay().innerHTML = this.monthName;
   if (ParentObject.formNumber >= 0) this.ygetDisplay().innerHTML = this.yearValue;   
}

// Object for the previous/next buttons
function neighborMonthObject(ParentObject, IDText, DateMS) {
   (Function.call) ? dateObject.call(this, DateMS) : dateObject(this, DateMS);
   this.buttonID = ParentObject.hiddenFieldName + '_' + IDText + '_ID';
   this.hover = new Function('C','O','NeighborHover(C,O,this)');
   this.getButton = new Function('return document.getElementById(this.buttonID)');
   this.go = new Function(ParentObject.objName + '.getCalendar().style.zIndex=++ZCounter;' + ParentObject.objName + '.setDisplayed(this.yearValue,this.monthIndex);');
   if (ParentObject.formNumber >= 0) this.getButton().title = this.monthName;
}

// Sets the currently-displayed month object
function SetDisplayedMonth(DispYear, DispMonth) {
   this.displayed = new displayMonthObject(this, DispYear, DispMonth, 1);
   // Creates the previous and next month objects
   this.previous = new neighborMonthObject(this, 'Previous', this.displayed.date.getTime() - 86400000);
   this.next = new neighborMonthObject(this, 'Next', this.displayed.date.getTime() + (86400000 * (this.displayed.dayCount + 1)));
   this.yprevious = new neighborMonthObject(this, 'YPrevious', this.displayed.date.getTime() - 31104000000);
   this.ynext = new neighborMonthObject(this, 'YNext', this.displayed.date.getTime() + 31104000000 + (86400000 * (this.displayed.dayCount + 1)));   
   // Creates the HTML for the calendar
   if (this.formNumber >= 0) this.getDayTable().innerHTML = this.buildCalendar();
}

// Sets the current selected date
function SetPickedMonth(PickedYear, PickedMonth, PickedDay) {
   this.picked = new storedMonthObject(this.format, PickedYear, PickedMonth, PickedDay);
   this.setHidden(this.picked.formatted);
   this.setDisplayed(PickedYear, PickedMonth);
}

// The calendar object
function calendarObject(DateName, DateFormat, DefaultDate) {

   /* Properties */
   this.hiddenFieldName = DateName;
   this.dateID = DateName + '_Date_ID';
   this.monthListID = DateName + '_Month_ID';
   this.dayListID = DateName + '_Day_ID';
   this.yearFieldID = DateName + '_Year_ID';
   this.monthDisplayID = DateName + '_Current_ID';
   this.yearDisplayID = DateName + '_YCurrent_ID';
   this.calendarID = DateName + '_ID';
   this.dayTableID = DateName + '_DayTable_ID';
   this.calendarLinkID = this.calendarID + '_Link';
   this.timerID = this.calendarID + '_Timer';
   this.objName = DateName + '_Object';
   this.format = DateFormat;
   this.formNumber = -1;
   this.picked = null;
   this.displayed = null;
   this.previous = null;
   this.next = null;
   this.yprevious = null;
   this.ynext = null;
   this.delimiter = this.format.indexOf('/') >= 0 ? '/' : '-';
   
   /* Methods */
   this.setPicked = SetPickedMonth;
   this.setDisplayed = SetDisplayedMonth;
   this.checkYear = CheckYearInput;
   this.fixYear = FixYearInput;
   this.changeMonth = CheckMonthChange;
   this.changeDay = CheckDayChange;
   this.resetTimer = CalTimerReset;
   this.hideElements = SetElementStatus;
   this.show = ShowCalendar;
   this.handleTimer = DoTimer;
   this.iconHover = CalIconHover;
   this.buildCalendar = BuildCalendarDays;
   this.pickDay = PickDisplayDay;
   this.fixSelects = FixSelectLists;
   this.setHidden = new Function('D','if (this.formNumber >= 0) this.getHiddenField().value=D');
   // Returns a reference to these elements
   this.getHiddenField = new Function('return document.forms[this.formNumber].elements[this.hiddenFieldName]');
   this.getData = new Function('return document.getElementById(this.dateID)');
   this.getMonthList = new Function('return document.getElementById(this.monthListID)');
   this.getDayList = new Function('return document.getElementById(this.dayListID)');
   this.getYearField = new Function('return document.getElementById(this.yearFieldID)');
   this.getCalendar = new Function('return document.getElementById(this.calendarID)');
   this.getDayTable = new Function('return document.getElementById(this.dayTableID)');
   this.getCalendarLink = new Function('return document.getElementById(this.calendarLinkID)');
   this.getMonthDisplay = new Function('return document.getElementById(this.monthDisplayID)');
   this.getYearDisplay = new Function('return document.getElementById(this.yearDisplayID)');
   this.isShowing = new Function('return !(this.getCalendar().style.visibility != \'visible\')');
   this.clear = new Function('document.getElementById(this.dateID).value=""; document.getElementById(this.hiddenFieldName).value="";');

   /* Constructor */
   // Functions used only by the constructor
   function getMonthIndex(MonthAbbr) { // Returns the index (0-11) of the supplied month abbreviation
      for (var MonPos=0;MonPos<MonthNames.length;MonPos++) {
         if (MonthNames[MonPos].substr(0,3).toUpperCase() == MonthAbbr.toUpperCase()) break;
      }
      return MonPos;
   }
   function SetGoodDate(CalObj, Notify) { // Notifies the user about their bad default date, and sets the current system date
      CalObj.setPicked(Today.getFullYear(), Today.getMonth(), Today.getDate());
      if (Notify) alert('WARNING: The supplied date is not in valid \'' + DateFormat + '\' format: ' + DefaultDate + '.\nTherefore, the current system date will be used instead: ' + CalObj.picked.formatted);
   }
   // Main part of the constructor
   if (DefaultDate != '') {
      if ((this.format == 'YYYYMMDD') && (/^(\d{4})(\d{2})(\d{2})$/.test(DefaultDate))) this.setPicked(RegExp.$1, parseInt(RegExp.$2,10)-1, RegExp.$3);
      else {
         // Get the year
         if ((this.format.substr(0,2) == 'YY') && (/^(\d{2,4})(-|\/)/.test(DefaultDate))) { // Year is at the beginning
            var YearPart = GetGoodYear(RegExp.$1);
            // Determine the order of the months and days
            if (/(-|\/)(\w{1,3})(-|\/)(\w{1,3})$/.test(DefaultDate)) {
               var MidPart = RegExp.$2;
               var EndPart = RegExp.$4;
               if (/D$/.test(this.format)) { // Ends with days
                  var DayPart = EndPart;
                  var MonthPart = MidPart;
               }
               else {
                  var DayPart = MidPart;
                  var MonthPart = EndPart;
               }
               MonthPart = (/\d{1,2}/i.test(MonthPart)) ? parseInt(MonthPart,10)-1 : getMonthIndex(MonthPart);
               this.setPicked(YearPart, MonthPart, DayPart);
            }
            else SetGoodDate(this, true);
         }
         else if (/(-|\/)(\d{2,4})$/.test(DefaultDate)) { // Year is at the end
            var YearPart = GetGoodYear(RegExp.$2);
            // Determine the order of the months and days
            if (/^(\w{1,3})(-|\/)(\w{1,3})(-|\/)/.test(DefaultDate)) {
               if (this.format.substr(0,1) == 'D') { // Starts with days
                  var DayPart = RegExp.$1;
                  var MonthPart = RegExp.$3;
               }
               else { // Starts with months
                  var MonthPart = RegExp.$1;
                  var DayPart = RegExp.$3;
               }           
               MonthPart = (/\d{1,2}/i.test(MonthPart)) ? parseInt(MonthPart,10)-1 : getMonthIndex(MonthPart);
               this.setPicked(YearPart, MonthPart, DayPart);
            }
            else SetGoodDate(this, true);
         }
         else SetGoodDate(this, true);
      }
   }
}

// Main function that creates the form elements
function DateInput(DateName, Required, DateFormat, DefaultDate) {
//alert(DefaultDate);
   this.delimiter = DateFormat.indexOf('/') >= 0 ? '/' : '-';
   if (arguments.length == 0) document.writeln('<span style="color:red;font-size:' + FontSize + 'px;font-family:' + FontFamily + ';">ERROR: Missing required parameter in call to \'DateInput\': [name of hidden date field].</span>');
   else {
      // Handle DateFormat
      if (arguments.length < 3) { // The format wasn't passed in, so use default
         DateFormat = DefaultDateFormat;
         if (arguments.length < 2) Required = false;
      }
      else if (/^(Y{2,4}(-|\/)?)?((MON)|(MM?M?)|(DD?))(-|\/)?((MON)|(MM?M?)|(DD?))((-|\/)Y{2,4})?$/i.test(DateFormat)) DateFormat = DateFormat.toUpperCase();
      else { // Passed-in DateFormat was invalid, use default format instead
         var AlertMessage = 'WARNING: The supplied date format for the \'' + DateName + '\' field is not valid: ' + DateFormat + '\nTherefore, the default date format will be used instead: ' + DefaultDateFormat;
         DateFormat = DefaultDateFormat;
         if (arguments.length == 4) { // DefaultDate was passed in with an invalid date format
            var CurrentDate = new storedMonthObject(DateFormat, Today.getFullYear(), Today.getMonth(), Today.getDate());
            AlertMessage += '\n\nThe supplied date (' + DefaultDate + ') cannot be interpreted with the invalid format.\nTherefore, the current system date will be used instead: ' + CurrentDate.formatted;
            DefaultDate = CurrentDate.formatted;
         }
         alert(AlertMessage);
      }
      // Define the current date if it wasn't set already
      if (!CurrentDate) var CurrentDate = new storedMonthObject(DateFormat, Today.getFullYear(), Today.getMonth(), Today.getDate());
      // Handle DefaultDate
      if (arguments.length < 4) { // The date wasn't passed in
         DefaultDate = (Required) ? CurrentDate.formatted : ''; // If required, use today's date
      }
      // Creates the calendar object!
      eval(DateName + '_Object=new calendarObject(\'' + DateName + '\',\'' + DateFormat + '\',\'' + DefaultDate + '\')');
      // Determine initial viewable state of day, year, and calendar icon
      if (DefaultDate) {
         var InitialStatus = '';
         var InitialDate = eval(DateName + '_Object.picked.formatted');
      } else {
         var InitialStatus = '';
//         var InitialStatus = ' style="visibility:hidden"';
         var InitialDate = '';
         eval(DateName + '_Object.setPicked(' + Today.getFullYear() + ',' + Today.getMonth() + ',' + Today.getDate() + ')');
      }
      // Create the form elements
      with (document) {
         writeln('<input type="hidden" name="' + DateName + '" id="' + DateName + '" value="' + InitialDate + '">');
         // Find this form number
         for (var f=0;f<forms.length;f++) {
            for (var e=0;e<forms[f].elements.length;e++) {
               if (typeof forms[f].elements[e].type == 'string') {
                  if ((forms[f].elements[e].type == 'hidden') && (forms[f].elements[e].name == DateName)) {
                     eval(DateName + '_Object.formNumber='+f);
                     break;
                  }
               }
            }
         }
         writeln('<table cellpadding="0" cellspacing="2"><tr>' + String.fromCharCode(13) + '<td valign="middle">');
//         writeln('<select' + InitialStatus + ' class="calendarDateInput" id="' + DateName + '_Day_ID" onChange="' + DateName + '_Object.changeDay(this)">');
         write('<input size=12 disabled class="small" id="' + DateName + '_Date_ID"');
         if (DefaultDate == '') { 
		 	 write('value="">');
//            writeln('<option value=""' + NoneSelected + '>' + UnselectedMonthText + '</option>');
         } else {
			 DayNow = eval(DateName + '_Object.picked.day') < 10 ? '0'+eval(DateName + '_Object.picked.day') : eval(DateName + '_Object.picked.day');
			 write('value="' + DayNow + this.delimiter);			 
			 MonthNow = eval(DateName + '_Object.picked.monthIndex')+1 < 10 ? '0'+eval(eval(DateName + '_Object.picked.monthIndex')+1) : eval(DateName + '_Object.picked.monthIndex')+1;
			 write( MonthNow + this.delimiter);
			 write(eval(DateName + '_Object.picked.yearPad') + '">');
		 }
		 
 		 writeln('<td valign="middle">' + String.fromCharCode(13) + '<a' + InitialStatus + ' id="' + DateName + '_ID_Link" href="javascript:' + DateName + '_Object.show()" onMouseOver="return ' + DateName + '_Object.iconHover(true)" onMouseOut="return ' + DateName + '_Object.iconHover(false)"><img src="' + ImageURL + '" align="baseline" title="Calendar" border="0"></a>' + String.fromCharCode(13) + '<a' + InitialStatus + ' href="javascript:' + DateName + '_Object.clear()" ><img src="' + ClearURL + '" align="baseline" title="Clear" border="0"></a>&nbsp;');
         writeln('<span id="' + DateName + '_ID" style="position:absolute;visibility:hidden;width:' + (CellWidth * 7) + 'px;background-color:' + CalBGColor + ';border:1px solid dimgray;" onMouseOver="' + DateName + '_Object.handleTimer(true)" onMouseOut="' + DateName + '_Object.handleTimer(false)">');
         writeln('<table width="' + (CellWidth * 7) + '" cellspacing="0" cellpadding="1">' + String.fromCharCode(13) + '<tr style="background-color:' + TopRowBGColor + ';">');
         writeln('<td id="' + DateName + '_Previous_ID" style="cursor:default" align="center" class="calendarDateInput" style="height:' + CellHeight + '" onClick="' + DateName + '_Object.previous.go()" onMouseDown="VirtualButton(this,true)" onMouseUp="VirtualButton(this,false)" onMouseOver="return ' + DateName + '_Object.previous.hover(this,true)" onMouseOut="return ' + DateName + '_Object.previous.hover(this,false)" title="' + eval(DateName + '_Object.previous.monthName') + '"><img src="' + PrevURL + '"></td>');
         writeln('<td id="' + DateName + '_Current_ID" style="cursor:pointer" align="center" class="calendarDateInput" style="height:' + CellHeight + '" colspan="5" onClick="' + DateName + '_Object.displayed.goCurrent()" onMouseOver="self.status=\'Click to view ' + CurrentDate.fullName + '\';return true;" onMouseOut="self.status=\'\';return true;" title="Show Current Month">' + eval(DateName + '_Object.displayed.monthName') + '</td>');
         writeln('<td id="' + DateName + '_Next_ID" style="cursor:default" align="center" class="calendarDateInput" style="height:' + CellHeight + '" onClick="' + DateName + '_Object.next.go()" onMouseDown="VirtualButton(this,true)" onMouseUp="VirtualButton(this,false)" onMouseOver="return ' + DateName + '_Object.next.hover(this,true)" onMouseOut="return ' + DateName + '_Object.next.hover(this,false)" title="' + eval(DateName + '_Object.next.monthName') + '"><img src="' + NextURL + '"></td></tr>' + String.fromCharCode(13) + '<tr>');
		 writeln('<tr style="background-color:' + TopRowBGColor + ';">');
         writeln('<td id="' + DateName + '_YPrevious_ID" style="cursor:default" align="center" class="calendarDateInput" style="height:' + CellHeight + '" onClick="' + DateName + '_Object.yprevious.go()" onMouseDown="VirtualButton(this,true)" onMouseUp="VirtualButton(this,false)" onMouseOver="return ' + DateName + '_Object.yprevious.hover(this,true)" onMouseOut="return ' + DateName + '_Object.yprevious.hover(this,false)" title="' + eval(DateName + '_Object.yprevious.monthName') + '"><img src="' + PrevURL + '"></td>');
         writeln('<td id="' + DateName + '_YCurrent_ID" style="cursor:pointer" align="center" class="calendarDateInput" style="height:' + CellHeight + '" colspan="5" onClick="' + DateName + '_Object.displayed.goCurrent()" onMouseOver="self.status=\'Click to view ' + CurrentDate.yearValue + '\';return true;" onMouseOut="self.status=\'\';return true;" title="Show Current Year">' + eval(DateName + '_Object.displayed.yearValue') + '</td>');
         writeln('<td id="' + DateName + '_YNext_ID" style="cursor:default" align="center" class="calendarDateInput" style="height:' + CellHeight + '" onClick="' + DateName + '_Object.ynext.go()" onMouseDown="VirtualButton(this,true)" onMouseUp="VirtualButton(this,false)" onMouseOver="return ' + DateName + '_Object.ynext.hover(this,true)" onMouseOut="return ' + DateName + '_Object.ynext.hover(this,false)" title="' + eval(DateName + '_Object.ynext.monthName') + '"><img src="' + NextURL + '"></td></tr>' + String.fromCharCode(13) + '<tr>');         
         for (var w=0;w<7;w++) writeln('<td width="' + CellWidth + '" align="center" class="calendarDateInput" style="height:' + CellHeight + ';width:' + CellWidth + ';font-weight:bold;border-top:1px solid dimgray;border-bottom:1px solid dimgray;">' + WeekDays[w] + '</td>');
         writeln('</tr>' + String.fromCharCode(13) + '</table>' + String.fromCharCode(13) + '<span id="' + DateName + '_DayTable_ID">' + eval(DateName + '_Object.buildCalendar()') + '</span>' + String.fromCharCode(13) + '</span>' + String.fromCharCode(13) + '</td>' + String.fromCharCode(13) + '</tr>' + String.fromCharCode(13) + '</table>');
      }
   }
}


//AJAX
//Basic Ajax Routine- Author: Dynamic Drive (http://www.dynamicdrive.com)
//Last updated: Jan 15th, 06'

function createAjaxObj(){
	var httprequest=false
	if (window.XMLHttpRequest){ // if Mozilla, Safari etc
		httprequest=new XMLHttpRequest()
		if (httprequest.overrideMimeType)
			httprequest.overrideMimeType('text/xml')
	}
	else if (window.ActiveXObject){ // if IE
		try {
			httprequest=new ActiveXObject("Msxml2.XMLHTTP");
		} 
		catch (e){
			try{
				httprequest=new ActiveXObject("Microsoft.XMLHTTP");
			}
			catch (e){}
		}
	}
	return httprequest
}

var ajaxpack=new Object()
ajaxpack.basedomain="http://"+window.location.hostname
//alert(ajaxpack.basedomain);
//window.location.href.match(/^(.*)(\/)(.*)$/);
//window.location.href.match(/^http:\/\/.*(\/.*\/.*)\?.*/);
window.location.href.match(/^(.+?\/{2}.+?)(\/.*\.\w*)(\W.*)?$/);
path=RegExp.$2;
//path = '';
ajaxpack.ajaxobj=createAjaxObj()
ajaxpack.filetype="txt"
ajaxpack.addrandomnumber=1 //Set to 1 or 0. See documentation.

ajaxpack.getAjaxRequest=function(url, parameters, callbackfunc, filetype){
						ajaxpack.ajaxobj=createAjaxObj() //recreate ajax object to defeat cache problem in IE
						if (ajaxpack.addrandomnumber==1) //Further defeat caching problem in IE?
						var parameters=parameters+"&ajaxcachebust="+new Date().getTime()
						if (this.ajaxobj){
							this.filetype=filetype
							this.ajaxobj.onreadystatechange=callbackfunc
							//alert('GET '+path+url+"?"+parameters);
							this.ajaxobj.open('GET', path+url+"?"+parameters, true)
							this.ajaxobj.send(null)
						}
					}

ajaxpack.postAjaxRequest=function(url, parameters, callbackfunc, filetype){
							ajaxpack.ajaxobj=createAjaxObj() //recreate ajax object to defeat cache problem in IE
							if (this.ajaxobj){
								this.filetype=filetype
								this.ajaxobj.onreadystatechange = callbackfunc;
								this.ajaxobj.open('POST', url, true);
								this.ajaxobj.setRequestHeader("Content-type", "application/x-www-form-urlencoded");
								this.ajaxobj.setRequestHeader("Content-length", parameters.length);
								this.ajaxobj.setRequestHeader("Connection", "close");
								this.ajaxobj.send(parameters);
							}
						}

//Reload the objects on page
function loadobjs(){
	if (!document.getElementById)
		return
	for (i=0; i<arguments.length; i++){
		var file=arguments[i]
		var fileref=""
		if (loadedobjects.indexOf(file)==-1){ //Check to see if this object has not already been added to page before proceeding
			if (file.indexOf(".js")!=-1){ //If object is a js file
				fileref=document.createElement('script')
				fileref.setAttribute("type","text/javascript");
				fileref.setAttribute("src", file);
			}
			else if (file.indexOf(".css")!=-1){ //If object is a css file
				fileref=document.createElement("link")
				fileref.setAttribute("rel", "stylesheet");
				fileref.setAttribute("type", "text/css");
				fileref.setAttribute("href", file);
			}
		}
		if (fileref!=""){
			document.getElementsByTagName("head").item(0).appendChild(fileref)
			loadedobjects+=file+" " //Remember this object as being already added to page
		}
	}
}

//Validacao
function validaCPF()
	{
		validate = 0;
		var CPFCNPJ = document.signupForm.CPFCNPJ.value;
		var cpf = CPFCNPJ;
		var a = [];
		var b = new Number;
		var c = 11;
		for (i=0; i<11; i++){
			a[i] = cpf.charAt(i);
			if (i < 9) b += (a[i] * --c);
		}
		if ((x = b % 11) < 2) { a[9] = 0 } else { a[9] = 11-x }
		b = 0;
		c = 11;
		for (y=0; y<10; y++) b += (a[y] * c--); 
		if ((x = b % 11) < 2) { a[10] = 0; } else { a[10] = 11-x; }
		if (cpf == "00000000000" || cpf == "11111111111" || cpf == "22222222222" || cpf == "33333333333" || cpf == "44444444444" || cpf == "55555555555" || cpf == "66666666666" || cpf == "77777777777" || cpf == "88888888888" || cpf == "99999999999")		{
			span1.innerHTML ='[CPF inválido. Favor informar um CPF válido.]';
			document.signupForm.submitForm.title='Botão Desabilitado. Favor confira seu CPF';
			document.signupForm.submitForm.style.cursor='default';
			document.signupForm.CPFCNPJ.value = "";
			turnOffSubmit();
		}else if ((cpf.charAt(9) != a[9]) || (cpf.charAt(10) != a[10])){
			span1.innerHTML ='[CPF inválido. Favor informar um CPF válido.]';
			document.signupForm.submitForm.title='Botão Desabilitado. Favor confira seu CPF';
			document.signupForm.submitForm.style.cursor='default';
			document.signupForm.CPFCNPJ.value = "";
			turnOffSubmit();			
		}else{
			span1.innerHTML='';
			document.signupForm.submitForm.title='Clique para continuar';
			document.signupForm.submitForm.style.cursor='default';
			turnOnSubmit();
		}
	}	

function validaCNPJ() {	
	var CPFCNPJ = document.signupForm.CPFCNPJ.value;
	var CNPJ = CPFCNPJ;
	var a = [];
	var b = new Number;
    var c = [6,5,4,3,2,9,8,7,6,5,4,3,2];
    for (i=0; i<12; i++){
		a[i] = CNPJ.charAt(i);
		b += a[i] * c[i+1];
	}
	if ((x = b % 11) < 2) { a[12] = 0 } else { a[12] = 11-x }
	b = 0;
	for (y=0; y<13; y++) {
		b += (a[y] * c[y]); 
	}
	if ((x = b % 11) < 2) { a[13] = 0; } else { a[13] = 11-x; }
	if (CNPJ.length != 14){
		span1.innerHTML ='[CNPJ inválido. O CNPJ deve possuir 14 dígitos no formato(112223330001XX).]';
		document.signupForm.submitForm.title='Botão Desabilitado. Favor confira seu CPF';
		document.signupForm.submitForm.style.cursor='default';
		document.signupForm.CPFCNPJ.value = "";
		turnOffSubmit();		
	}else if ((CNPJ.charAt(12) != a[12]) || (CNPJ.charAt(13) != a[13])){
		span1.innerHTML ='[CNPJ inválido. Favor informar um CNPJ válido.]';
		document.signupForm.submitForm.title='Botão Desabilitado. Favor confira seu CPF';
		document.signupForm.submitForm.style.cursor='default';
		document.signupForm.CPFCNPJ.value = "";
		turnOffSubmit();
	}else{
		span1.innerHTML='';
		document.signupForm.submitForm.title='Clique para continuar';
		document.signupForm.submitForm.style.cursor='default';
		turnOnSubmit();
	}
}

//Check for cookies
function SetCookie(cookieName,cookieValue,nDays) {
 var today = new Date();
 var expire = new Date();
 if (nDays==null || nDays==0) nDays=1;
 expire.setTime(today.getTime() + 3600000*24*nDays);
 document.cookie = cookieName+"="+escape(cookieValue)
                 + ";expires="+expire.toGMTString();
}

function ReadCookie(cookieName) {
 var theCookie=""+document.cookie;
 var ind=theCookie.indexOf(cookieName);
 if (ind==-1 || cookieName=="") return ""; 
 var ind1=theCookie.indexOf(';',ind);
 if (ind1==-1) ind1=theCookie.length; 
 return unescape(theCookie.substring(ind+cookieName.length+1,ind1));
}


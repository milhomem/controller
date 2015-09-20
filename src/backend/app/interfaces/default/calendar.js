var isV5Up = true;//(isIE || isNN6up || isGecko || isOpera5up);
var isNNLayers = false;//(isNN && propertyExists('layers', document) && (document.layers != null));
var isDocAll = true;//(propertyExists('all', document) && (document.all != null));
var isDocEl = true;//(propertyExists('getElementById', document) && (document.getElementById != null));

var ppcX = 4;
var ppcY = 4;
var howManyDigits;
var todayDate = new Date;
var curDate = new Date;
var curImg;
var curDateBox;
var minDate = new Date;
var maxDate = new Date;
var IsUsingMinMax;
var FuncsToRun;

var minYearList = todayDate.getFullYear() - 10;
var maxYearList = todayDate.getFullYear() + 10;
var isCVisible = false;

function getOffsetLeft (el) {
  var ol = el.offsetLeft;
  while ((el = el.offsetParent) != null)
    ol += el.offsetLeft;
  return ol;
}

function getOffsetTop (el) {
  var ot = el.offsetTop;
  while((el = el.offsetParent) != null)
    ot += el.offsetTop;
  return ot;
}

function showCalendar(frmName, dteBox, btnImg, posX, posY, hmd, runFuncs) {
  if (isCVisible) {
    hideCalendar();
  } else {
    curDateBox = document.forms[frmName].elements[dteBox];
    curImg = btnImg;
    howManyDigits = hmd;
    FuncsToRun = runFuncs;
    IsUsingMinMax = false;
    setImgSrc('close', img_close_src);
    setImgSrc('prev', img_prev_src);
    setImgSrc('next', img_next_src);

    if (isNNLayers) {
      ppcX = document.images[btnImg].x + posX;
      ppcY = document.images[btnImg].y + document.images[btnImg].height
			+ posY;
    } else {
      ppcX = getOffsetLeft(document.images[btnImg]) + posX;
      ppcY = getOffsetTop(document.images[btnImg])
			+ document.images[btnImg].height + posY;
    }
    domlay('popupcalendar',1,ppcX,ppcY,Calendar(todayDate.getMonth(), todayDate.getFullYear()));
    isCVisible = true;
  }
}

function hideCalendar(){
  domlay('popupcalendar',0,ppcX,ppcY);
  if (!isCVisible) setImgSrc(curImg, img_calendar_src);
  isCVisible = false;
}

function calClick() {
  window.focus();
}

function domlay(id,trigger,lax,lay,content) {
  if (content){
    if (isNNLayers) {
      sprite=document.layers[''+id].document;
      sprite.open();
      sprite.writeln(content);
      document.close();
    } else if (isDocAll) {
      document.all[''+id].innerHTML = content;
    } else if (isDocEl) {
      var rng = document.createRange();
      var el = document.getElementById(''+id);
      rng.setStartBefore(el);
      var htmlFrag = rng.createContextualFragment(content)
      while(el.hasChildNodes()) el.removeChild(el.lastChild);
      el.appendChild(htmlFrag);
    }
  }
  if (trigger=="1") {
    if (isNNLayers) {
      document.layers[''+id].visibility = "show";
    } else if (isDocAll) {
      document.all[''+id].style.visibility = "visible";
    } else if (isDocEl) {
      document.getElementById(''+id).style.visibility = "visible";
    }
  } else {
    if (isNNLayers) {
      document.layers[''+id].visibility = "hide";
    } else if (isDocAll) {
      document.all[''+id].style.visibility = "hidden";
    } else if (isDocEl) {
      document.getElementById(''+id).style.visibility = "hidden";
    }
  }
  if (lax) {
    if (isNNLayers) {
      document.layers[''+id].left = lax;
    } else if (isDocAll) {
      document.all[''+id].style.left=lax;
    } else if (isDocEl) {
      document.getElementById(''+id).style.left=lax+"px";
    }
  }
  if (lay) {
    if (isNNLayers) {
      document.layers[''+id].top = lay;
    } else if (isDocAll) {
      document.all[''+id].style.top = lay;
    } else if (isDocEl) {
      document.getElementById(''+id+'').style.top=lay+"px";
    }
  }
}

function Calendar(whatMonth,whatYear) {
  var datecolwidth;
  var i;
  var startMonth = whatMonth;
  var startYear = whatYear;
  curDate.setMonth(whatMonth);
  curDate.setFullYear(whatYear);
  curDate.setDate(todayDate.getDate());
  var mainCForm = '<form name="f_Calendar">';
  var mainCTable = '<table border="3" bgcolor="' + cal_bg_color
    + '" class="cal-Table" cellspacing="0" cellpadding="0">';
  var output;
  if (isV5Up) {
      output = mainCForm + mainCTable;
  } else {
      output = mainCTable + mainCForm;
  }

  output += '<tr><td width="185" bgcolor="' + header_bg
    + '"><table width=\"100%\" cellspacing="1" cellpadding="1" border="0">'
    + '<tr valign="middle"><td width="15%" align="right">';
  output += isNN4Old ? '&nbsp;'
	: '<a href="#" onClick="javascript:scrollMonth(-1); return false;">'
		+ str_img_prev + '</a>';
  output += '</td><td width="15%" style="' + header_style
    + '">' + '<SELECT style="' + select_style
    + '" name="cboMonth" onChange="changeMonth();">';
  for (var month=0; month<12; month++) {
    if (month == whatMonth) {
      output += '<OPTION VALUE="' + month + '" SELECTED>'
	    + m_names[month] + '</OPTION>';
    } else {
      output += '<OPTION VALUE="' + month + '">'
	    + m_names[month] + '</OPTION>';
    }
  }
  output += '</SELECT></td><td width="15%"  style="' + header_style
    + '">' + '<SELECT style="' + select_style
    + '" name="cboYear" onChange="changeYear();">';
  for (var year=minYearList; year<maxYearList; year++) {
    if (year == whatYear) {
      output += '<OPTION VALUE="' + year + '" SELECTED>' + year + '</OPTION>';
    } else {
      output += '<OPTION VALUE="' + year + '">'	+ year + '</OPTION>';
    }
  }
  output += '</SELECT></td><td align="left" width="15%">'
  output += isNN4Old ? '&nbsp;'
    : '<a href="#" onClick="javascript:scrollMonth(1); return false;">'
	+ str_img_next + '</a>';
  output += '</td><td align="right" valign="top">'
    + '<a href="#" onClick="javascript:hideCalendar(); return false;">'
    + str_img_close + '</a></td></tr></table></td></tr>'
    + '<tr><td width="185" class="control_submit" bgcolor="' + cell_border + '">';
  var firstDay = new Date(whatYear,whatMonth,1);
  var startDay = firstDay.getDay();
  if (((whatYear % 4 == 0) && (whatYear % 100 != 0)) || (whatYear % 400 == 0)) {
    days[1] = 29;
  } else {
    days[1] = 28;
  }
  output += '<table width="100%" cellspacing="1" cellpadding="2" border="0"><tr>';
  for (i=0; i<7; i++) {
    if (i == 0 || i == 6) {
      datecolwidth = "15%";
    } else {
      datecolwidth = "14%";
    }
    output += '<td width="' + datecolwidth + '" bgcolor="' + header_bg
	+ '" class="control_submit" valign="middle"><span style="'
	+ header_style +'">' + dow[i] +'</span></td>';
  }
  output += '</tr><tr>';

  var column = 0;
  var lastMonth = whatMonth - 1;
  var lastYear = whatYear;
  if (lastMonth == -1) { lastMonth = 11; lastYear=lastYear-1;}
  for (i = 0; i < startDay; i++, column++) {
    output += getDayLink((days[lastMonth]-startDay+i+1),true,lastMonth,lastYear);
  }
  for (i = 1; i <= days[whatMonth]; i++, column++) {
    output += getDayLink(i,false,whatMonth,whatYear);
    if (column == 6) {
      output += '</tr><tr>';
      column = -1;
    }
  }

  var nextMonth = whatMonth+1;
  var nextYear = whatYear;
  if (nextMonth==12) {
    nextMonth=0; nextYear=nextYear+1;
  }
  if (column > 0) {
    for (i=1; column<7; i++, column++) {
      output +=  getDayLink(i,true,nextMonth,nextYear);
    }
    output += '</tr></table></td></tr>';
  } else {
    output = output.substr(0,output.length-4);
    output += '</table></td></tr>';
  }

  if (isV5Up) {
    output += '</table></form>';
  } else {
    output += '</form></table>';
  }
  curDate.setDate(1);
  curDate.setMonth(startMonth);
  curDate.setFullYear(startYear);
  return output;
}

function getDayLink(linkDay,isGreyDate,linkMonth,linkYear) {
  var templink;
  if (!(IsUsingMinMax)) {
    if (isGreyDate) {
      templink = '<td class="control_submit" bgcolor="' + day_cell_bg
	+ '" class="cal-DayCell"><span style="'
	+ grey_date_style +'" class="cal-GreyDate">'
	+ linkDay+'</span></td>';
    } else {
      if (isDayToday(linkDay)) {
	templink='<td class="control_submit" bgcolor="' + day_cell_bg
	  + '" class="cal-DayCell"><a style="'+important_link_style
	  + '" class="cal-TodayLink" onmouseover="self.status=\' \';'
	  + ' return true;" href="#" onclick="javascript:changeDay('
	  + linkDay + '); return false;">' + linkDay + '</a></td>';
      } else {
	templink='<td class="control_submit" bgcolor="' + day_cell_bg
	  + '" class="cal-DayCell"><a style="' + base_link_style
	  + '" class="cal-DayLink" onmouseover="self.status=\' \';'
	  + ' return true;" href="#" onclick="javascript:changeDay('
	  + linkDay + '); return false;">' + linkDay + '</a></td>';
      }
    }
  } else {
    if (isDayValid(linkDay,linkMonth,linkYear)) {
      if (isGreyDate){
	templink = '<td class="control_submit" bgcolor="' + day_cell_bg
	  + '" class="cal-DayCell"><span style="'
	  + grey_date_style +'" class="cal-GreyDate">'
	  +linkDay+'</span></td>';
      } else {
	if (isDayToday(linkDay)) {
	   templink='<td class="control_submit" bgcolor="' + day_cell_bg
	      + '" class="cal-DayCell"><a style="'+important_link_style
	      + '" class="cal-TodayLink" onmouseover="self.status=\' \';'
	      + ' return true;" href="#" onclick="javascript:changeDay('
	      + linkDay + '); return false;">' + linkDay + '</a></td>';
	} else {
	  templink='<td class="control_submit" bgcolor="' + day_cell_bg
	      + '" class="cal-DayCell"><a style="' + base_link_style
	      + '" class="cal-DayLink" onmouseover="self.status=\' \';'
	      + ' return true;" href="#" onclick="javascript:changeDay('
	      + linkDay + '); return false;">' + linkDay + '</a></td>';
	}
      }
    } else {
      templink = '<td class="control_submit" bgcolor="' + day_cell_bg
	+ '" class="cal-DayCell"><span style="'
	+ grey_date_style + '" class="cal-GreyDate">'
	+ linkDay + '</span></td>';
    }
  }
  return templink;
}

function isDayToday(isDay) {
  return ((curDate.getFullYear() == todayDate.getFullYear())
	&& (curDate.getMonth() == todayDate.getMonth())
	&& (isDay == todayDate.getDate())) ;
}

function isDayValid(validDay, validMonth, validYear) {
  curDate.setDate(validDay);
  curDate.setMonth(validMonth);
  curDate.setFullYear(validYear);
  return ((curDate >= minDate) && (curDate <= maxDate));
}

function padout(number) {
 return (number < 10) ? '0' + number : number;
}

function changeDay(whatDay) {
  curDate.setDate(whatDay);
  var year;
  if(howManyDigits==4){
    year = curDate.getFullYear();
  } else {
    year = (""+curDate.getFullYear()).substring(2,4);
  }
  hideCalendar();
  if (curDateBox) curDateBox.value = padout(curDate.getMonth()+1) + '/'
				+ padout(curDate.getDate())+ '/' + year;
  if (FuncsToRun!=null) eval(FuncsToRun);
}

function scrollMonth(amount) {
  var monthCheck;
  var yearCheck;
  if (isV5Up) {
    monthCheck = document.forms["f_Calendar"].cboMonth.selectedIndex + amount;
  } else if (isNNLayers) {
    monthCheck = document.popupcalendar.document.forms["f_Calendar"].cboMonth.selectedIndex
	+ amount;
  }
  if (monthCheck < 0) {
    yearCheck = curDate.getFullYear() - 1;
    if ( yearCheck < minYearList ) {
      yearCheck = minYearList;
      monthCheck = 0;
    } else {
      monthCheck = 11;
    }
    curDate.setFullYear(yearCheck);
  } else if (monthCheck >11) {
    yearCheck = curDate.getFullYear() + 1;
    if ( yearCheck > maxYearList-1 ) {
      yearCheck = maxYearList-1;
      monthCheck = 11;
    } else {
      monthCheck = 0;
    }
    curDate.setFullYear(yearCheck);
  }
  if (isV5Up) {
    curDate.setMonth(document.forms["f_Calendar"].cboMonth.options[monthCheck].value);
  } else if (isNNLayers) {
    curDate.setMonth (document.popupcalendar.document.forms["f_Calendar"].cboMonth
		.options[monthCheck].value);
  }
  domlay('popupcalendar', 1, "", "", Calendar(curDate.getMonth(),curDate.getFullYear()));
}

function changeMonth() {
  if (isV5Up) {
    curDate.setMonth (document.forms["f_Calendar"].cboMonth
	.options[document.forms["f_Calendar"].cboMonth.selectedIndex].value);
    domlay('popupcalendar', 1, "", "", Calendar(curDate.getMonth(),curDate.getFullYear()));
  } else if (isNNLayers) {
    curDate.setMonth(document.popupcalendar.document.forms["f_Calendar"].cboMonth
	.options[document.popupcalendar.document.forms["f_Calendar"].cboMonth.selectedIndex]
	.value);
    domlay('popupcalendar', 1, "", "", Calendar(curDate.getMonth(),curDate.getFullYear()));
  }
}

function changeYear() {
  if (isV5Up) {
    curDate.setFullYear(document.forms["f_Calendar"].cboYear
	.options[document.forms["f_Calendar"].cboYear.selectedIndex].value);
    domlay('popupcalendar',1, "", "", Calendar(curDate.getMonth(),curDate.getFullYear()));
  }
  else if (isNNLayers) {
    curDate.setFullYear(document.popupcalendar.document.forms["f_Calendar"].cboYear
	.options[document.popupcalendar.document.forms["f_Calendar"].cboYear.selectedIndex]
	.value);
    domlay('popupcalendar', 1, "", "", Calendar(curDate.getMonth(),curDate.getFullYear()));
  }
}

function makeArray0() {
  var args = isV5Up ? arguments : makeArray0.arguments;
  for (var i = 0; i < args.length; i++)
    this[i] = args[i];
}

function setImgSrc(imgName, newSrc) {
  if (propertyExists("images", document) && propertyExists(imgName, document.images)) {
    var img = document.images[imgName];
    if (isIE && isWinPlatform
	 && (img.src.toLowerCase().lastIndexOf("spacer.gif") >= 0)) {
      img.style.filter = "progid:DXImageTransform.Microsoft.AlphaImageLoader(src='"
	+ newSrc + "', sizingMethod='scale')";
      img.style.visibility = "visible";
    } else {
      img.src = newSrc;
    }
  }
}

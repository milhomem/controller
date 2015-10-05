#!/usr/bin/perl

#       .Copyright (C)  1999-2002 TUCOWS.com Inc.
#       .Created:       11/19/1999
#       .Contactid:     <admin@opensrs.org>
#       .Url:           http://www.opensrs.org
#       .Originally Developed by:
#                       Tucows/OpenSRS
#       .Authors:       Evgeniy Pirogov
#
#
#       This program is free software; you can redistribute it and/or
#       modify it under the terms of the GNU Lesser General Public 
#       License as published by the Free Software Foundation; either 
#       version 2.1 of the License, or (at your option) any later version.
#
#       This program is distributed in the hope that it will be useful, but
#       WITHOUT ANY WARRANTY; without even the implied warranty of
#       MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
#       Lesser General Public License for more details.
#
#       You should have received a copy of the GNU Lesser General Public
#       License along with this program; if not, write to the Free Software
#       Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

package OpenSRS::Util::Canada;
require Exporter;
@ISA = qw(Exporter);

use strict;

use vars qw(
    @EXPORT_OK 
    %canada_legal_types 
    @canada_legal_types 
    %canada_province 
    %legal_types
    %legal_type_groups 
    %lang_pref 
    @municipal_prefix);

@EXPORT_OK = qw(
    %canada_province 
    %canada_legal_types 
    @canada_legal_types
    %lang_pref 
    municipal_format 
    @municipal_prefix
    legal_type_list
    help_icon
    %legal_type_groups
    %legal_types);

 
%canada_province = (
		   AB =>'Alberta',
		   BC =>'British Columbia',
		   MB =>'Manitoba',
		   NB =>'New Brunswick',
		   NF =>'Newfoundland',
		   NL =>'Newfoundland and Labrador',
		   NS =>'Nova Scotia',
		   NT =>'Northwest Territories',
		   NU =>'Nunavut',
		   ON =>'Ontario',
		   PE =>'Prince Edward Island',
		   QC =>'Quebec',
		   SK =>'Saskatchewan',
		   YK =>'Yukon',
		   );

@municipal_prefix = qw(
        city
        ville
        town
        village
        hamlet
        hameau
        municipality
        municipalite
);

%lang_pref= ( EN =>'English',
	      FR =>'Français',
	      );

%legal_types = (
    'ABO' =>
	    {
		long => 'Aboriginal Peoples (individuals or groups) indigenous to Canada',
		desc => q{
Any Inuit, First Nation, Metis or other people indigenous to Canada, and any collectivity of such Aboriginal peoples.
		},
		valid => q{
For individual:<br>
<ul>
<li>John Doe</li></ul>
For a group:<br>
<ul>
<li>Carrier Sekani Tribal Council</li></ul>
<br>
		},
		invalid => q{
<ul>
<li>Acme Sales Inc.</li><br>
<li>Helping Spirit Lodge Society</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'ASS' => 
	    {
		long => 'Canadian Unincorporated Association',
		desc => q{
This Registrant Type is principally intended for religious congregations, social and sports clubs and community groups which are based and operating in Canada. An unincorporated organization, association or club: (i) at least 80% of whose members: (A) are ordinarily resident in Canada (if such members are individuals); or (B) meet the requirements of any one of the following Registrant Types: Corporation or Registered Charity  (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, Partnership Registered in Canada, Trust established in Canada, Legal Representative of a Canadian Citizen or Permanent Resident; and (ii) at least 80% of whose directors, officers, employees, managers, administrators or other representatives are ordinarily resident in Canada.
		},
		valid => q{
<ul>
<li>St-Albans Reformed Church of Victoria</li><br>
<li>Archdiocese of Montreal</li><br>
<li>Sun Youth Montreal</li><br>
<li>Citizens for the Protection of the Red River</li><br>
<li>Toronto Junior Soccer Association</li>
</ul>
		},
		invalid => q{

<ul>
<li>ACDEN</li><br>
<li>St-Patricks</li><br>
<li>Dartmouth Soccer Club Limited</li><br>
<li>John Doe</li>
</ul>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'CCO' => 
	    {
		long => 'Corporation or Registered Charity  (Canada or Canadian province or territory)',
		desc => 'A corporation or charity under the laws of Canada or any province or territory of Canada',
		valid => q#
For corporation:<br>
<ul>
<li>12375 Canada inc</li><br>
<li>Smith Corp. of Ontario</li>
</ul><br>
For a charity:<br>
<ul>
<li>John Doe Foundation, Ontario - (NFP)</li><BR>
</ul>
#,

		invalid => q#
<ul>
<li>Smiths</li><br>
<li>Smiths Consulting</li><br>
<li>Smiths Kennel</li><br>
<li>Smiths Corp.</li><br>
<li>Leatra SP</li>
</ul><BR>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.#,

	    },
    'CCT' => 
	    {
		long => 'Canadian citizen',
		desc => 'A canadian citizen of the age of majority under the laws of the province or territory in Canada in which he or she resides or last resided',
		valid => q{
<ul>
<li>John Doe <font color="green" size=-1><i>(full name)</i></font></li><BR>
<li>Fred-Albert Doon PhD <font color="green" size=-1><i>(full name followed by degree information)</i></font></li><BR>
<li>Bernard St-James o/a St-James Services <font color="green" size=-1><i>(full name followed by "operating as" and description)</i></font></li>
</ul>

		},
		invalid => q{
<ul>
<li>John <font color="red" size=-1><i>(full name is required)</i></font></li><br>
<li>J. Doe  <font color="red" size=-1><i>(abbreviations are not allowed)</i></font></li><br>
<li>"None" or "Personal" or blank <font color="red" size=-1><i>(full name is required)</i></font></li><br>
<li>Cool Gal <font color="red" size=-1><i>(nicknames are not allowed)</i></font></li><br>
<li>Domain Administrator <font color="red" size=-1><i>(role names are not allowed)</i></font></li><br>
<li>St-James Services or Acme Sales Inc. <font color="red" size=-1><i>(name must be of an individual)</i></font><br><BR>
</ul>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'EDU' => 
	    {
		long => 'Canadian Educational Institution',
		desc => q{
(i) a university or college which is located in Canada and which is authorized or recognized as a university or college under an Act of the legislature of a province or territory of Canada; or <br>
(ii) a college, post-secondary school, vocational school, secondary school, pre-school or other school or educational institution which is located in Canada and which is recognized by the educational authorities of a province or territory of Canada or licensed under or maintained by an Act of Parliament of Canada or of the legislature of a province or territory of Canada.
		},
		valid => q{
<ul>
<li>University of British Columbia (UBC)</li><br>
<li>St-Johns Middle School of Ottawa</li><br>
<li>Advanced Languages Institute of Ontario (ALI)(Ontario)</li>
</ul><br>
		},
		invalid => q{

<ul>
<li>Sandhill Secondary School</li><br>
<li>Sales Are Us Inc.</li><br>
<li>UBC Student Association</li><br>
<li>Professional Association of Teaching Professionals of UdeM</li><br>
<li>Joe Smith</li>
</ul><BR>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'GOV' => 
	    {
		long => 'Government or government entity in Canada',
		desc => 'Her Majesty the Queen in right of Canada, a province or a territory; an agent of Her Majesty the Queen in right of Canada, of a province or of a territory; a federal, provincial or territorial Crown corporation, government agency or government entity; or a regional, municipal or local area government.',
		valid => q{
<ul>
<li>Government of Alberta</li><br>
<li>Export Development Corporation (EDC) (Canada)</li><br>
<li>Deposit Insurance Corporation of Ontario (DCIO)</li><br>
<li>The Corporation of the City of Toronto</li><br>
</ul>
		},
		invalid => q{
<ul>
<li>Toronto Sales Are Us Inc.</li><br>
<li>DCIOPEI</li><br>
<li>John Doe</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'HOP' => 
	    {
		long => 'Canadian Hospital',
		desc => q{
A hospital which is located in Canada and which is licensed, authorized or approved to operate as a hospital under an Act of the legislature of a province or territory of Canada
		},
		valid => q{
<ul>
<li>Royal Victoria Hospital Quebec</li><br>
<li>Sick Childrens Hospital of Ontario</li><br>
<li>Veterans Hospital Canada, Pointe Claire</li>
</ul><br>
		},
		invalid => q{
<ul>
<li>Dr. John Doe</li><br>
<li>Jane Doe</li><br>
<li>John Doe Inc.</li><br>
<li>SHUL</li><br>
<li>Nurses Union Local 1455 NHCWA</li><br>
<li>Manitoba Doctors Against Drugs (MDAD)</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'INB' => 
	    {
		long => 'Indian Band recognized by the Indian Act of Canada',
		desc => q{
Any Indian band as defined in the Indian Act, R.S.C. 1985, c. I-5, as amended from time to time, and any group of Indian bands;
		},
		valid => q{
<ul>
<li>Lac la Ronge Indian Band</li></ul><br>
		},
		invalid => q{
<ul>
<li>Mohawk Motors</li><br>
<li>Sioux Sales Inc.</li><br>
<li>Sales Are Us Inc.</li><br>
<li>Jean Gallant</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'LAM' => 
	    {
		long => 'Canadian Library, Archive or Museum',
		desc => q{
An institution, whether or not incorporated, that:<br><br>

(i) is located in Canada; and<br>
(ii) is not established or conducted for profit or does not form part of, or is not administered or directly or indirectly controlled by, a body that is established or conducted for profit in which is held and maintained a collection of documents and other materials that is open to the public or to researchers.
		},
		valid => q{
<ul>
<li>Royal Ontario Museum</li><BR>
<li>Muse des Beaux Arts de Montreal</li><BR>
</ul>
		},
		invalid => q{
<ul>
<li>John Doe</li><br>
<li>Sales Are Us Inc.</li><br>
<li>My site</li><br>
<li>Domain Administrator</li><br>
<li>Biggs Bargain Books</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'LGR' => 
	    {
		long => 'Legal Representative of a Canadian Citizen or Permanent Resident',
		desc => q{
An executor, administrator or other legal representative of a Person listed as a Canadian Citizen or Permanent Resident of Canada.<br><br>
Note: This registrant type is only available to a person or entity that has been appointed by legal process to represent an individual who is not competent to represent him or herself. It is not available to anyone who represents a Canadian or foreign corporation in any capacity.
		},
		valid => q{
<ul>
<li>John Smith (Jayne Smith, executor)</li></ul><br>
		},
		invalid => q{
<ul>
<li>Sales Are Us Inc.</li><br>
<li>Arlenza SP</li><br>
<li>Shingle LLP</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'MAJ' => 
	    {
		long => 'Her Majesty the Queen',
		desc => q{
Her Majesty Queen Elizabeth the Second and her successors.
		},
	    },
    'OMK' => 
	    {
		long => 'Official mark registered in Canada',
		desc => q{
A Person which does not meet the requirements for any other Registrant Type, but which is a Person intended to be protected by Subsection 9(1) of the Trade-Marks Act (Canada) at whose request the Registrar of Trade-marks has published notice of adoption of any badge, crest, emblem, official mark or other mark pursuant to Subsection 9(1), but in this case such permission is limited to a request to register a .ca domain name consisting of or including the exact word component of such badge, crest, emblem, official mark or other mark in respect of which such Person requested publications.<br>
Notes: This registrant type is only intended for Registrants which do not meet the requirements associated with any other registrant type but which have an Official Mark registered in Canada.<br><br>

The domain name must include the official mark (eg. If the official mark is WIPO, the registrant can register wipo.ca but not intellectual-property.ca)
		},
		valid => q{
<ul>
<li>
The United Nations Educational, Scientific and Cultural Organization (UNESCO)</li>
<li>0970388</li>
</ul>
		},
		invalid => q{
<ul>
<li>John Doe Inc.</li><br>
<li>Arcuros SPA</li><br>
</ul>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'PLT' => 
	    {
		long => 'Canadian Political Party',
		desc => q{
 A political party registered under a relevant electoral law of Canada or any province or territory of Canada
		},
		valid => q{
<ul>
<li>Progressive Conservative Party of Canada (PC)</li><br>
<li>Union Nationale du Quebec</li><br>
<li>Reform Party of Alberta</li>
</ul><BR>
		},
		invalid => q{
<ul>
<li>John Doe</li><br>
<li>Sales Are Us Inc.</li><br>
<li>Liberal Party</li><br>
<li>ACCULD Ontario</li><br>
<li>National Liberation Front of Mexico</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'PRT' => 
	    {
		long => 'Partnership Registered in Canada',
		desc => q{
A partnership, more than 66 2/3 % of whose partners meet the requirements of one of the following Registrant Types: Corporation or Registered Charity  (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, Trust established in Canada or a Legal Representative of a Canadian Citizen or Permanent Resident, which is registered as a partnership under the laws of any province or territory of Canada.
		},
		valid => q{
<ul>
<li>Xenon Partnership (Ontario)</li><br>
<li>Blake, Cassels and Graydon LLP (Ontario)</li><br>
<li>John Doe Partnership, British Columbia</li>
</ul><br>
		},
		invalid => q{

<ul>
<li>John Doe Partnership</li><br>
<li>Mybusiness Inc.</li><br>
<li>Fred Smith</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'RES' => 
	    {
		long => 'Permanent Resident of Canada',
		desc => q{
A permanent resident as defined in the Immigration Act (Canada) R.S.C. 1985, c.I-2, as amended from time to time, who is ordinarily resident in Canada and of the age of majority under the laws of the province or territory in Canada in which he or she resides or last resided. (Ordinarily resident in Canada means an individual who resides in Canada for more than 183 days in the twelve month period immediately preceding the date of the applicable request for registration of the .ca domain name or sub-domain name and in each twelve month period thereafter for the duration of the domain name registration.)
		},
		valid => q{
<ul>
<li>John Doe</li><br>
<li>Fred-Albert Doon DDS</li><br>
<li>Bernard St-James o/a St-James Services</li>
</ul><br>
		},
		invalid => q{
<ul>
<li>John</li><br>
<li>John 7</li><br>
<li>J. Doe</li><br>
<li>F.A.D</li><br>
<li>Cool Gal</li><br>
<li>St-James Services</li><br>
<li>Acme Sales Inc.</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'TDM' => 
	    {
		long => 'Trade-mark registered in Canada (by a non-Canadian owner)',
		desc => q{
A Person which does not fall under any other registrant type, but which is the owner of a trade-mark which is the subject of a registration under the Trade-marks Act (Canada) R.S.C. 1985, c.T-13 as amended from time to time, but in this case such permission is limited to a request to register a .ca domain name consisting of or including the exact word component of that registered trade-mark.<br><br>
This Registrant Type is only intended for Registrants which do not meet the requirements associated with any other registrant type but which have a trade-mark registered in Canada. (Trade-marks subject of trade-mark applications and trade-marks registered in other jurisdictions, such as the United States, do not qualify.)<br><br>
The domain name to be registered must include the trade-mark. (eg. If the trade-mark is AVEA this type of registrant can register avea.ca or aveaisus.ca but not xyz.ca).
		},
		valid => q{
<ul>
<li>Arcuros SPA - TMA1762466</li></ul><BR>
		},
		invalid => q{
<ul>
<li>Arcuros SPA</li></ul><BR>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'TRD' => 
	    {
		long => 'Canadian Trade Union',
		desc => q{
A trade union which is recognized by a labour board under the laws of Canada or any province or territory of Canada and which has its head office in Canada.
		},
		valid => q{
<ul>
<li>Confederation des syndicats nationaux (CSN) Quebec</li><br>
<li>Canadian Union of Postal Workers (CUPW)</li>
</ul><br>
		},
		invalid => q{

<ul>
<li>ZZCEUL local 237</li><br>
<li>Jean Smith</li><br>
<li>Sales Are Us Inc.</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
    'TRS' => 
	    {
		long => 'Trust established in Canada',
		desc => q{
A trust established and subsisting under the laws of a province or territory of Canada, more than 66 2/3 % of whose trustees meet the requirements of one of thefollowing Registrant Types: Corporation or Registered Charity  (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, or a Legal Representative of a Canadian Citizen or Permanent Resident.
		},
		valid => q{
<ul>
<li>Marie Daigle Trust  (100%)</li><br>
<li>Arbeit Trust  (70%)</li>
</ul><br>
		},
		invalid => q{
<ul>
<li>John Doe</li><br>
<li>Sales Are Us Inc.</li><br>
<li>Arbeit Trust (10%)</li>
</ul><br>
<p>
If the Registrant Name is not correct, you may correct it above and go
to the NEXT screen, or you can go BACK to the previous screen to select
a new legal type.
		},
	    },
);

#order is very important
@canada_legal_types = qw (CCO CCT RES GOV EDU ASS HOP PRT TDM TRD PLT LAM TRS ABO INB LGR OMK MAJ);

%canada_legal_types = map {$_ => $legal_types{$_}{long}} @canada_legal_types;


%legal_type_groups = (
    all => {
	    list =>[ qw(CCO CCT RES GOV EDU ASS HOP PRT TDM TRD PLT LAM TRS ABO INB LGR OMK) ],
	    intro => q#
<p>The registrant of the domain, must match one of the following legal types: 
<ul>
<li>Canadian Citizen 
<li>Permanent Resident of Canada 
<li>Corporation or Registered Charity (Canada or Canadian province or territory) 
<li>Partnership Registered in Canada 
<li>Trust established in Canada 
<li>Official mark registered in Canada
<li>Trade-mark registered in Canada (by a non-Canadian owner)
<li>Canadian Unincorporated Association 
<li>Government or Government Entity in Canada
<li>Political Party
<li>Educational Institution
<li>Hospital 
<li>Library, Archive or Museum
<li>Trade Union
<li>Aboriginal Peoples (individual or groups) indigenous to Canada
<li>Indian Band recognized by the Indian Act of Canada
</ul>
<p>Since these legal types have strict naming regulations, please ensure that the registrant name adheres to CIRA guidelines outlined in the ? sections. 
<p>
Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 
<p>
	    #,
	    help => q#
<table border=1 width=100%>
<tr><td>

<table border=0>
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  <tr bgcolor="e0e0e0">
   <td><br>
    <ul>
     <li><b>Canadian citizen:</b> A Canadian citizen of the age of majority under the laws of the 
     	province or territory in Canada in which he or she resides or last resided.
     <li><b>Permanent Resident of Canada:</b> A permanent resident as defined in the Immigration Act 
	(Canada) R.S.C. 1985, c.I-2, as amended from time to time, who is "ordinarily resident in Canada"
	 and of the age of majority under the laws of the province or territory in Canada in which he or 
	 she resides or last resided. ("Ordinarily resident in Canada" means an individual who resides in
	  Canada for more than 183 days in the twelve month period immediately preceding the date of the 
	 applicable request for registration of the .ca domain name or sub-domain name and in each twelve
	  month period thereafter for the duration of the domain name registration.) 
     <li><b>Legal Representative of a Canadian Citizen or Permanent Resident:</b> 
	An executor, administrator or other legal representative of a Person listed as a Canadian 
	Citizen or Permanent Resident of Canada.

     <p>Note: This registrant type is only available to a person or entity that has been appointed by legal 
	process to represent an individual who is not competent to represent him or herself. 
	It is not available to anyone who represents a Canadian or foreign corporation in any capacity. 

     <li><b>Corporation (Canada or Canadian province or territory):</b> A corporation under the laws of Canada or any province or territory of Canada

     <li><b>Registered Charity:</b> A charity which is registered with the Canada Customs and Revenue Agency.  The website <a href="http://www.ccra-adrc.gc.ca/tax/charities/online_listings/canreg_interim-e.html">http://www.ccra-adrc.gc.ca/tax/charities/online_listings/canreg_interim-e.html</a> displays registered charities.  The legal type for the charity will actually be stored as a "corporation".  However, the abbreviation "(NFP)" (Not for Profit) must be added to the registrant name to identify the registrant as a charity.

     <li><b>Partnership Registered in Canada:</b> A partnership, more than 66 2/3 % of whose partners meet the requirements of one of the following Registrant Types: Corporation (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, Trust established in Canada or a Legal Representative of a Canadian Citizen or Permanent Resident, which is registered as a partnership under the laws of any province or territory of Canada.

     <li><b>Trust established in Canada:</b> A trust established and subsisting under the laws of a province or territory of Canada, more than 66 2/3 % of whose trustees meet the requirements of one of the following Registrant Types: Corporation (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, or a Legal Representative of a Canadian Citizen or Permanent Resident. 

     <li><b>Official mark registered in Canada:</b> A Person which does not meet the requirements for any other Registrant Type, but which is a Person intended to be protected by Subsection 9(1) of the Trade-Marks Act (Canada) at whose request the Registrar of Trade-marks has published notice of adoption of any badge, crest, emblem, official mark or other mark pursuant to Subsection 9(1), but in this case such permission is limited to a request to register a .ca domain name consisting of or including the exact word component of such badge, crest, emblem, official mark or other mark in respect of which such Person requested publications.   Note: This registrant type is only intended for Registrants which do not meet the requirements associated with any other registrant type but which have an Official Mark registered in Canada.
      <p>The domain name must include the official mark (eg. If the official mark is WIPO, the registrant can register wipo.ca but not intellectual-property.ca)

     <li><b>Trade-mark registered in Canada (by a non-Canadian owner):</b> A Person which does not fall under any other registrant type, but which is the owner of a trade-mark which is the subject of a registration under the Trade-marks Act (Canada) R.S.C. 1985, c.T-13 as amended from time to time, but in this case such permission is limited to a request to register a .ca domain name consisting of or including the exact word component of that registered trade-mark.
       <p> This Registrant Type is only intended for Registrants which do not meet the requirements associated with any other registrant type but which have a trade-mark registered in Canada. (Trade-marks subject of trade-mark applications and trade-marks registered in other jurisdictions, such as the United States, do not qualify.)
       <p> The domain name to be registered must include the trade-mark. (eg. If the trade-mark is AVEA this type of registrant can register avea.ca or aveaisus.ca but not xyz.ca).

     <li><b>Canadian Unincorporated Association</b> is principally intended for religious congregations, social and sports clubs and community groups which are based and operating in Canada. An unincorporated organization, association or club where: 
     <ol type='i'>
      <li>at least 80% of whose members: 
       <ol type='A'>
        <li>are ordinarily resident in Canada (if such members are individuals); or
        <li>meet the requirements of any one of the following Registrant Types: Corporation (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, Partnership Registered in Canada, Trust established in Canada, Legal Representative of a Canadian Citizen or Permanent Resident; and 
       </ol>
      <li>at least 80% of whose directors, officers, employees, managers, administrators or other representatives are ordinarily resident in Canada. 
     </ol>

     <li><b>Government or government entity in Canada:</b> Her Majesty the Queen in right of Canada, a province or a territory; an agent of Her Majesty the Queen in right of Canada, of a province or of a territory; a federal, provincial or territorial Crown corporation, government agency or government entity; or a regional, municipal or local area government.

     <li><b>Canadian Political Party:</b> A political party registered under a relevant electoral law of Canada or any province or territory of Canada 

     <li><b>Canadian Educational Institution:</b> 
      (i) a university or college which is located in Canada and which is authorized or recognized as a university or college under an Act of the legislature of a province or territory of Canada; or 
      (ii) a college, post-secondary school, vocational school, secondary school, pre-school or other school or educational institution which is located in Canada and which is recognized by the educational authorities of a province or territory of Canada or licensed under or maintained by an Act of Parliament of Canada or of the legislature of a province or territory of Canada.

     <li><b>Canadian Hospital:</b> A hospital which is located in Canada and which is licensed, authorized or approved to operate as a hospital under an Act of the legislature of a province or territory of Canada.

     <li><b>Canadian Library, Archive or Museum:</b> An institution, whether or not incorporated, that is:  (i) located in Canada; and  (ii)   not established or conducted for profit or does not form part of, or is not administered or directly or indirectly controlled by, a body that is established or conducted for profit in which is held and maintained a collection of documents and other materials that is open to the public or to researchers. 

     <li><b>Canadian Trade Union:</b> A trade union which is recognized by a labour board under the laws of Canada or any province or territory of Canada and which has its head office in Canada.

     <li><b>Aboriginal Peoples (individuals or groups) indigenous to Canada:</b> Any Inuit, First Nation, Metis or other people indigenous to Canada, and any collectivity of such Aboriginal peoples.

     <li><b>Indian Band recognized by the Indian Act of Canada:</b> Any Indian band as defined in the Indian Act, R.S.C. 1985, c. I-5, as amended from time to time, and any group of Indian bands;
    </ul>	
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>
  <tr bgcolor="e0e0e0">
   <td><br>
    <p>When registering a domain with the legal type: 
    <ol type="a">
     <li> Canadian Citizen, or 
     <li>Permanent Resident
    </ol> The Registrant Name must be the <b>FULL LEGAL NAME</b> 
	of the individual who will hold the domain name registration as the name would appear on a 
	passport, drivers license or other identification document issued by a government.    
    <p><blockquote><i>Example: "John Doe".</i></blockquote> 
    
    <p>The name may be followed by a space and "o/a xxxx" where "o/a" stands for "Operating As" and "xxxx" can be any alphanumeric string designated by the applicant. <p>When registering the domain for a small business, or a non-incorporated business, the "xxxx" field should be used to indicate this business.
    <p><blockquote><i>Example: "John Doe o/a Doe Consulting Group"</i></blockquote> 
    
    <p>The name may be followed by a space and a degree granted to the registrant by a recognized degree 
     granting institution or a recognized professional designation, which the registrant has the right to 
     use (e.g. PhD, MD, DDS).
    
    <p><b>Legal Representative of a Canadian Citizen or Permanent Resident: </b>
     The individual's name must be followed by the full legal name and capacity of at least one of the official representatives. 
    <p><blockquote><i>Example: "John Doe o/a Jayne Smith -  executor"</i></blockquote> 
    <p>
    <p><b>Corporation (Canada or Canadian province or territory)</b>:  
     The Registrant name must be the full legal name of corporation and must be followed by the jurisdiction of incorporation (eg. Canada, Ontario, NWT....).   The keywords: Corporation, Corp., Incorporated, Inc., Limited, LTD etc. are typically included in the registrant name. 
    <p><blockquote><i>Example:  "Smith Corporation of Ontario"</i></blockquote>
    
    <p><b>Charity:</b> The Registrant name must be the full legal name of charity (as noted at the website <a href="http://www.ccra-adrc.gc.ca/tax/charities/online_listings/canreg_interim-e.html">http://www.ccra-adrc.gc.ca/tax/charities/online_listings/canreg_interim-e.html</a>) and must be followed by the jurisdiction of incorporation (eg. Canada, Ontario, NWT....).   The abbreviation "(NFP)" (Not For Profit) must be added to the end of the registrant name.
    <p><blockquote><i>Example:  "John Doe Foundation, British Columbia - (NFP)"</i></blockquote>
    
    <p><b>Partnership Registered in Canada</b>: The Registrant name must be the registered name of the partnership that will hold the domain name registration. The Registrant name must be followed by the jurisdiction of registration (eg. Alberta) and the registration number.  (NOTE: partnerships can only have a provincial jurisdiction - they cannot be federally registered).  The keywords: Partnership or LLP are typically included in the registrant name.
    <p><blockquote><i>Example:  "John Doe Partnership, British Columbia"</i></blockquote>
    
    <p><b>Trust established in Canada</b>: The Registrants name must be the complete official name of the trust, without any abbreviations. (A common abbreviation may follow the official name in parentheses.) The Registrant name must also indicate the total percentage of the trustees that meet one or more of the following requirements: Canadian citizen, permanent resident, Canadian corporation, or legal representative.
    <p><blockquote><i>Example:  "John Doe Trust - (100%)"</i></blockquote>
    
    <p><b>Official mark registered in Canada</b>: The Registrant's name must be the complete official name of the entity holding the domain name registration without any abbreviations. (A common abbreviation may follow the complete name in parentheses).  The registration number of the official mark must follow the Registrant name.
    <p><blockquote><i>Example:  "The United Nation Educational, Scientific and Cultural Organization (UNESCO) - 0970388"</i></blockquote>
    
    <p><b>Trade-mark registered in Canada (by a non-Canadian owner)</b>: The Registrant's name must be the complete legal name of the trade-mark owner (not the trade-mark agent) holding the domain name registration without any abbreviations. (A common abbreviation may follow the complete name in parentheses).  The applicant must also insert the Canadian registration number of the trade-mark following the Registrant name.
    <p><blockquote><i>Example:  "Arcuros SPA - TMA1762466"</i></blockquote>
    
    <p><b>Canadian Unincorporated Association:</b> The Registrant's name must be the complete name of the association that will hold the domain name registration, without any abbreviations. (A common abbreviation may follow the complete name in parentheses).   If the geographic location of the association is not obvious from the registrant name, the location should be added to the domain (eg. "of Winnipeg")
    <p><blockquote><i>Example:  "St-Alban's Reformed Church of Victoria"</i></blockquote>
    
    <p><b>Government or government entity in Canada:</b> The Registrant's name must be the complete official name of the entity that will hold the domain name registration,without any abbreviations. (A common abbreviation may follow the official name in parentheses). If the Registrant is not a government, the Registrants name must be followed by the name of the jurisdiction (eg. Canada, province, territory, municipality, etc) to which the Registrant is related. 
    <p><blockquote><i>Example:  "Government of Alberta"</i></blockquote>
    
    <p><b>Canadian Political Party:</b> The Registrant's name must be the complete official name of the political party holding the domain name registration, without abbreviations. (A common abbreviation may follow the official name in parentheses.) The Registrant name must also by followed by the jurisdiction in Canada in which it is registered (if it is not obvious from the official name). 
    <p><blockquote><i>Example:  "Reform Party - Alberta"</i></blockquote>
    
    <p><b>Canadian Educational Institution:</b> The Registrant's name must be the complete official name of the institution that will hold the domain name registration, without any abbreviations. A common abbreviation may follow the official name in parentheses. The Registrant name must be followed by the jurisdiction (e.g. name of province, municipality) in which the institution is accredited if not obvious from the Registrants name. 
    <p><blockquote><i>Example:  "University of British Columbia (UBC)"</i></blockquote>
    
    <p><b>Canadian Hospital:</b> The Registrant's name must be the complete official name of the hospital that will hold the domain name registration, without any abbreviations. (A common abbreviation may follow the complete name in parentheses.) The Registrants name must be followed by the jurisdiction (e.g. name of province) in which accredited the hospital if not obvious from the Registrants name. <p><blockquote><i>Example:  "Veteran's Hospital Canada, Pointe Claire"</i></blockquote>

    <p><b>Canadian Library, Archive or Museum:</b> The Registrant's name must be the complete legal name of the institution which will hold the domain name registration without abbreviations. (A common abbreviation may follow the complete name in parentheses.) 
    <p><blockquote><i>Example:  "Royal Ontario Museum"</i></blockquote>

    <p><b>Canadian Trade Union:</b> The Registrants name must be the complete official name of the trade union that will hold the domain name registration, without abbreviations. (A common abbreviation may follow the official name in parentheses.) The Registrant name must be followed by the jurisdiction in Canada which recognizes it (if it is not obvious from the Registrants name.) 
    <p><blockquote><i>Example:  "Canadian Union of Postal Workers (CUPW)"</i></blockquote>

    <p><b>Aboriginal Peoples - Individual:</b> the Registrant Name must be the <b>FULL LEGAL NAME</b> of the individual who will hold the domain name registration as the name would appear on a passport, drivers license or other identification document issued by a government. 
    <p><blockquote><i>Example: "John Doe".</i></blockquote> 
    <p>Initials or nicknames are not allowed. Full legal names may only consist of alphabetic characters and the special characters: single quote mark('), hyphen(-), period(.). 

    <p>The name may be followed by a space and "o/a xxxx" where "o/a" stands for "Operating As" and "xxxx" can be any alphanumeric string designated by the applicant. 
    <p><blockquote><i>Example: "John Doe o/a Doe Group"</i></blockquote> 

    <p><b>Aboriginal Peoples - Group:</b> The Registrants name must be the complete official name of the indigenous people a collectivity of Aboriginal Persons or, if there is no official name, the name by which the collectivity is commonly known. 
    <p><blockquote><i>Example: "Carrier Sekani Tribal Council"</i></blockquote>

    <p><b>Indian Band recognized by the Indian Act of Canada:</b> The name of Registrant must be the Indian Band Name as registered with the Department of Indian and Northern Affairs, Canada. 
    <p><blockquote><i>Example: "Lac la Ronge Indian Band"</i></blockquote> 
  
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="desc">Registrant Description</font></th>
  </tr>
  <tr bgcolor="e0e0e0">
   <td>
    <p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered.
   </td>
  </tr>
  
</table>

</td></tr>
</table> 

	    #,
    },
    personal => {
	    list => [qw/CCT RES LGR/],
	    intro => qq#
<p>
If the domain is for an individual who wishes to have a domain name for personal use, one of the following legal types may be appropriate: 
<ul>
<li>Canadian Citizen 
<li>Permanent Resident of Canada 
<li>Legal Representative of a Canadian Citizen or Permanent Resident 
</ul>
<p>
The "registrant name" must be the full legal name of the individual, as it would appear on a passport, drivers license or other government issued identification documents, such as: "John Doe".
<p>
Once the domain is registered, you cannot easily change the registrant name, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 
<p>
#,
	help => qq#
<table border=1 width=100%>
<tr><td>

<table border=0>
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  
  <tr bgcolor="e0e0e0">
   <td><br>
    <p>Domains being registered for personal use, must be registered by a Canadian with one of the following legal types: 
    <ul>
     <li><b>Canadian citizen</b>: A Canadian citizen of the age of majority under the laws of the province or territory in Canada in which he or she resides or last resided 
     <li><b>Permanent Resident of Canada</b>: A permanent resident as defined in the Immigration Act (Canada) R.S.C. 1985, c.I-2, as amended from time to time, who is "ordinarily resident in Canada" and of the age of majority under the laws of the province or territory in Canada in which he or she resides or last resided. ("Ordinarily resident in Canada" means an individual who resides in Canada for more than 183 days in the twelve month period immediately preceding the date of the applicable request for registration of the .ca domain name or sub-domain name and in each twelve month period thereafter for the duration of the domain name registration.) 
     <li><b>Legal Representative of a Canadian Citizen or Permanent Resident</b>: An executor, administrator or other legal representative of a Person listed as a Canadian Citizen or Permanent Resident of Canada.
    </ul>
    <p>Note: This registrant type is only available to a person or entity that has been appointed by legal process to represent an individual who is not competent to represent him or herself. It is not available to anyone who represents a Canadian or foreign corporation in any capacity. 
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>
    
  <tr bgcolor="e0e0e0">
   <td><br>
    <p>When registering a domain with the legal type: 
    <ol type="a">
     <li> Canadian Citizen, or 
     <li>Permanent Resident
    </ol> The Registrant Name must be the <b>FULL LEGAL NAME</b>  
       of the individual who will hold the domain name registration as the name would appear on a passport, drivers license or other identification document issued by a government. 
    <p><blockquote><i>Example: "John Doe".</i></blockquote> 

    <p>When registering a domain with the legal type, Legal Representative of a Canadian Citizen or Permanent Resident, the individual's name must be followed by the full legal name and capacity of at least one of the official representatives. 
    <p><blockquote><i>Example: "John Doe o/a Jayne Smith -  executor"</i></blockquote> 
    
    <p>Initials or nicknames are not allowed. Full legal names may only consist of alphabetic characters and the special characters: single quote mark('), hyphen(-), period(.). 
    
    <p>The name may be followed by a space and "o/a xxxx" where "o/a" stands for "Operating As" and "xxxx" can be any alphanumeric string designated by the applicant. 
    <p><blockquote><i>Example: "John Doe o/a Doe Consulting Group"</i></blockquote> 
    
    <p>The name may be followed by a space and a degree granted to the registrant by a recognized degree granting institution or a recognized professional designation, which the registrant has the right to use (e.g. PhD, MD, DDS). 
    <p>Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.
    </td>
  </tr>
    
    <tr bgcolor="90c0ff">
     <th align=center colspan=2><font size=+1><a name="desc">Registrant Description</font></th>
    </tr>
  
  <tr bgcolor="e0e0e0">
   <td>
    <p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered.
   </td>
  </tr>
  
</table>

</td></tr>
</table>
#,
    },
    trust => {
	    list => [qw/CCO OMK PRT TDM TRS/],
	    intro => q#
<p>
If the domain is for a <b>registered</b> business, charity, trust or trade-mark, you must select one of the following types:
<ul>
<li>Corporation or Registered Charity (Canada or Canadian province or territory) 
<li>Partnership Registered in Canada 
<li>Trust established in Canada 
<li>Official mark registered in Canada
<li>Trade-mark registered in Canada (by a non-Canadian owner)
</ul>
<p>
The "registrant name" must clearly reflect the organization name and the jurisdiction for the <b>REGISTERED</b> entity.   Since these legal types have strict naming regulations, please ensure that the registrant name adheres to CIRA guidelines outlined in the ? sections.
<p> 
Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 
<p>
	    #,
	    help => q#
<table border=1 width=100%>
<tr><td>

<table border=0>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  
  <tr bgcolor="e0e0e0">
   <td><br>
    <p>If the domain is for a registered business, charity, trust or trade-mark, and you have selected one of the following types:
    
    <ol type='a'>
     <li>Corporation or Registered Charity (Canada or Canadian province or territory)<li>Partnership Registered in Canada
     <li>Trust established in Canada
     <li>Official mark registered in Canada
     <li>Trade-mark registered in Canada (by a non-Canadian owner)
    </ol>
    
    <p>The registrant must meet the requirements for the specific legal types as follows:
    <p><b>Corporation (Canada or Canadian province or territory)</b>
    A corporation under the laws of Canada or any province or territory of Canada

    <p><b>Registered Charity:</b> 
     A charity which is registered with the Canada Customs and Revenue Agency.  The website <a href="http://www.ccra-adrc.gc.ca/tax/charities/online_listings/canreg_interim-e.html">http://www.ccra-adrc.gc.ca/tax/charities/online_listings/canreg_interim-e.html</a> displays registered charities.  The legal type for the charity will actually be stored as a "corporation".  However, the abbreviation "(NFP)" (Not for Profit) must be added to the registrant name to identify the registrant as a charity.

    <p><b>Partnership Registered in Canada:</b> 
     A partnership, more than 66 2/3 % of whose partners meet the requirements of one of the following Registrant Types: Corporation (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, Trust established in Canada or a Legal Representative of a Canadian Citizen or Permanent Resident, which is registered as a partnership under the laws of any province or territory of Canada.

    <p><b>Trust established in Canada:</b> 
     A trust established and subsisting under the laws of a province or territory of Canada, more than 66 2/3 % of whose trustees meet the requirements of one of the following Registrant Types: Corporation (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, or a Legal Representative of a Canadian Citizen or Permanent Resident.
    
    <p><b>Official mark registered in Canada:</b> 
     A Person which does not meet the requirements for any other Registrant Type, but which is a Person intended to be protected by Subsection 9(1) of the Trade-Marks Act (Canada) at whose request the Registrar of Trade-marks has published notice of adoption of any badge, crest, emblem, official mark or other mark pursuant to Subsection 9(1), but in this case such permission is limited to a request to register a .ca domain name consisting of or including the exact word component of such badge, crest, emblem, official mark or other mark in respect of which such Person requested publications.   Note: This registrant type is only intended for Registrants which do not meet the requirements associated with any other registrant type but which have an Official Mark registered in Canada.

    <p>The domain name must include the official mark 
     (eg. If the official mark is WIPO, the registrant can register wipo.ca but not intellectual-property.ca)

    <p><b>Trade-mark registered in Canada (by a non-Canadian owner):</b> 
     A Person which does not fall under any other registrant type, but which is the owner of a trade-mark which is the subject of a registration under the Trade-marks Act (Canada) R.S.C. 1985, c.T-13 as amended from time to time, but in this case such permission is limited to a request to register a .ca domain name consisting of or including the exact word component of that registered trade-mark.
     This Registrant Type is only intended for Registrants which do not meet the requirements associated with any other registrant type but which have a trade-mark registered in Canada. (Trade-marks subject of trade-mark applications and trade-marks registered in other jurisdictions, such as the United States, do not qualify.)

    <p>The domain name to be registered must include the trade-mark. (eg. If the trade-mark is AVEA this type of registrant can register avea.ca or aveaisus.ca but not xyz.ca).
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>
    
  <tr bgcolor="e0e0e0">
   <td><br>
   
   <p>The "registrant name" must clearly reflect the organization name and the jurisdiction for the 
    <b>REGISTERED</b> entity.   Since these legal types have strict naming regulations, please ensure that the registrant name adheres to CIRA guidelines outlined below.
   
   <p><b>Corporation (Canada or Canadian province or territory)</b>:  
    The Registrant name must be the full legal name of corporation and must be followed by the jurisdiction of incorporation (eg. Canada, Ontario, NWT....).   The keywords: Corporation, Corp., Incorporated, Inc., Limited, LTD etc. are typically included in the registrant name. 
   <p><blockquote><i>Example:  "Smith Corporation of Ontario"</i></blockquote>

   <p><b>Charity:</b> The Registrant name must be the full legal name of charity (as noted at the website <a href="http://www.ccra-adrc.gc.ca/tax/charities/online_listings/canreg_interim-e.html">http://www.ccra-adrc.gc.ca/tax/charities/online_listings/canreg_interim-e.html</a>) and must be followed by the jurisdiction of incorporation (eg. Canada, Ontario, NWT....).   The abbreviation "(NFP)" (Not For Profit) must be added to the end of the registrant name.
   <p><blockquote><i>Example:  "John Doe Foundation, British Columbia - (NFP)"</i></blockquote>

   <p><b>Partnership Registered in Canada</b>: The Registrant name must be the registered name of the partnership that will hold the domain name registration. The Registrant name must be followed by the jurisdiction of registration (eg. Alberta) and the registration number.  (NOTE: partnerships can only have a provincial jurisdiction - they cannot be federally registered).  The keywords: Partnership or LLP are typically included in the registrant name.
   <p><blockquote><i>Example:  "John Doe Partnership, British Columbia"</i></blockquote>

   <p><b>Trust established in Canada</b>: The Registrants name must be the complete official name of the trust, without any abbreviations. (A common abbreviation may follow the official name in parentheses.) The Registrant name must also indicate the total percentage of the trustees that meet one or more of the following requirements: Canadian citizen, permanent resident, Canadian corporation, or legal representative.
   <p><blockquote><i>Example:  "John Doe Trust - (100%)"</i></blockquote>

   <p><b>Official mark registered in Canada</b>: The Registrant's name must be the complete official name of the entity holding the domain name registration without any abbreviations. (A common abbreviation may follow the complete name in parentheses).  The registration number of the official mark must follow the Registrant name.
   <p><blockquote><i>Example:  "The United Nation Educational, Scientific and Cultural Organization (UNESCO) - 0970388"</i></blockquote>

   <p><b>Trade-mark registered in Canada (by a non-Canadian owner)</b>: The Registrant's name must be the complete legal name of the trade-mark owner (not the trade-mark agent) holding the domain name registration without any abbreviations. (A common abbreviation may follow the complete name in parentheses).  The applicant must also insert the Canadian registration number of the trade-mark following the Registrant name.
   <p><blockquote><i>Example:  "Arcuros SPA - TMA1762466"</i></blockquote>
  
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
    <th align=center colspan=2><font size=+1><a name='desc'>Registrant Description</font></th>
  </tr>
  
  <tr bgcolor="e0e0e0">
   <td>
    <p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered.
   </td>
  </tr>
  
</table>

</td></tr>
</table> 	        
	    #,
    },
    sole => {
	    list => [qw/CCT RES/],
	    intro => q#
<p>
If the domain is for a non-incorporated business which is owned by an individual, one of the following legal types is appropriate: 
<ul>
<li>Canadian Citizen 
<li>Permanent Resident of Canada 
</ul>
<p>
The "registrant name" must be the full legal name of the individual, as it would appear on a passport, drivers license or other government issued identification documents, followed by the characters "o/a" and then the Business name (where o/a stands for "operating as"), such as "John Doe o/a Doe Consulting Group".
<p>
Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 
<p>
	    #,
	    help => q#
<table border=1 width=100%>
<tr><td>

<table border=0>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  
  <tr bgcolor="e0e0e0">
   <td><br>
    <p>Domains being registered for a small business or a non-incorporated business, must be registered by the Canadian owner with one of the following legal types: 
    <ul>
     <li><b>Canadian citizen:</b> A Canadian citizen of the age of majority under the laws of the province or territory in Canada in which he or she resides or last resided 
     <li><b>Permanent Resident of Canada:</b> A permanent resident as defined in the Immigration Act (Canada) R.S.C. 1985, c.I-2, as amended from time to time, who is "ordinarily resident in Canada" and of the age of majority under the laws of the province or territory in Canada in which he or she resides or last resided. ("Ordinarily resident in Canada" means an individual who resides in Canada for more than 183 days in the twelve month period immediately preceding the date of the applicable request for registration of the .ca domain name or sub-domain name and in each twelve month period thereafter for the duration of the domain name registration.) 
    </ul>

   <p>The registrant name can be altered to reflect that the domain is being used for a business operation rather then for personal use.
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>

  <tr bgcolor="e0e0e0">
   <td><br>
    <p>When registering a domain with the legal type: 
    <ol type="a">
     <li>Canadian Citizen, or 
     <li>Permanent Resident 
    </ol>

    the Registrant Name must be the <b>FULL LEGAL NAME</b> of the individual who will hold the domain name registration as the name would appear on a passport, drivers license or other identification document issued by a government. 
    <p><blockquote><i>Example: "John Doe".</i></blockquote> 

    <p>The name may be followed by a space and "o/a xxxx" where "o/a" stands for "Operating As" and "xxxx" can be any alphanumeric string designated by the applicant. 
    <p>When registering the domain for a small business, or a non-incorporated business, the "xxxx" field should be used to indicate this business.
    <p><blockquote><i>Example: "John Doe o/a Doe Consulting Group"</i></blockquote> 

    <p>The name may be followed by a space and a degree granted to the registrant by a recognized degree granting institution or a recognized professional designation, which the registrant has the right to use (e.g. PhD, MD, DDS). 
    <p>Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
    <th align=center colspan=2><font size=+1><a name='desc'>Registrant Description</font></th>
  </tr>
  
  <tr bgcolor="e0e0e0">
   <td> 
    <p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered. 
   </td>
  </tr>
  
</table>

</td></tr>
</table>	
	    #,
    },
    social => {
	    list => [qw/ASS/],
	    intro => q#
<p>
If the domain is for a religious congregation, social or sports club, or a community group the following legal type is appropriate: 
<ul>
<li>Canadian Unincorporated Association 
</ul>
<p>The "registrant name" must be the complete name of the association that will hold the domain registration, without any abbreviations.  (A common abbreviation may follow the complete name in parentheses.)  If the geographic location of the association is not obvious from the registrant name, the location should be added to the domain (eg. "of Winnipeg")
<p>
Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 
<p>
	    #,
	    help => q#
<table border=1 width=100%>
<tr><td>

<table border=0>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  
  <tr bgcolor="e0e0e0">
   <td><br>
    <p>The Registrant Type: <b>Canadian Unincorporated Association</b> is principally intended for religious congregations, social and sports clubs and community groups which are based and operating in Canada. An unincorporated organization, association or club where: 
    <ol type='i'>
     <li>at least 80% of whose members: 
      <ol type='A'>
       <li>are ordinarily resident in Canada (if such members are individuals); or
       <li>meet the requirements of any one of the following Registrant Types: Corporation (Canada or Canadian province or territory), Canadian citizen, Permanent Resident of Canada, Partnership Registered in Canada, Trust established in Canada, Legal Representative of a Canadian Citizen or Permanent Resident; and 
      </ol>
     <li>at least 80% of whose directors, officers, employees, managers, administrators or other representatives are ordinarily resident in Canada. 
    </ol>
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>
    
  <tr bgcolor="e0e0e0">
   <td><br>
    <p>The Registrant's name must be the complete name of the association that will hold the domain name registration, without any abbreviations. (A common abbreviation may follow the complete name in parentheses).   If the geographic location of the association is not obvious from the registrant name, the location should be added to the domain (eg. "of Winnipeg")
    <p><blockquote><i>Example:  "St-Alban's Reformed Church of Victoria"</i></blockquote>
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
    <th align=center colspan=2><font size=+1><a name='desc'>Registrant Description</font></th>
  </tr>
  
  <tr bgcolor="e0e0e0">
   <td>
    <p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered.
   </td>
  </tr>
  
</table>

</td></tr>
</table>   
	    #,
    },
    entity => {
	    list => [qw/GOV PLT EDU HOP LAM TRD/],
	    intro => qq#
<p>If the domain is for government office, political party, educational institution, library, hospital or trade union, you must select one of the following types:
<ul>
<li>Government or Government Entity in Canada
<li>Political Party
<li>Educational Institution
<li>Hospital 
<li>Library, Archive or Museum
<li>Trade Union
</ul>
<p>The "registrant name" must be the complete name of the organization that will hold the domain registration, without any abbreviations.  (A common abbreviation may follow the complete name in parentheses.)  If the geographic location of the association is not obvious from the registrant name, the location should be added to the domain (eg. "of Winnipeg")
<p>
Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 
<p>
	    #,
	    help => q#
<table border=1 width=100%>
<tr><td>

<table border=0>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  
  <tr bgcolor="e0e0e0">
   <td><br>
    <p>If the domain is for government office, political party, educational institution, library, hospital or trade union, you have selected one of the following types:
<ul>
<li>Government or Government Entity in Canada
<li>Political Party
<li>Educational Institution
<li>Hospital 
<li>Library, Archive or Museum
<li>Trade Union
</ul>
<p>The registrant must meet the requirements for the specific legal types as follows:
<p><b>Government or government entity in Canada:</b> Her Majesty the Queen in right of Canada, a province or a territory; an agent of Her Majesty the Queen in right of Canada, of a province or of a territory; a federal, provincial or territorial Crown corporation, government agency or government entity; or a regional, municipal or local area government.

<p><b>Canadian Political Party:</b>A political party registered under a relevant electoral law of Canada or any province or territory of Canada

<p><b>Canadian Educational Institution:</b> i) a university or college which is located in Canada and which is authorized or recognized as a university or college under an Act of the legislature of a province or territory of Canada; or 
(ii) a college, post-secondary school, vocational school, secondary school, pre-school or other school or educational institution which is located in Canada and which is recognized by the educational authorities of a province or territory of Canada or licensed under or maintained by an Act of Parliament of Canada or of the legislature of a province or territory of Canada. 

<p><b>Canadian Hospital:</b> A hospital which is located in Canada and which is licensed, authorized or approved to operate as a hospital under an Act of the legislature of a province or territory of Canada.

<p><b>Canadian Library, Archive or Museum:</b> An institution, whether or not incorporated, that is:  (i) located in Canada; and  (ii)   not established or conducted for profit or does not form part of, or is not administered or directly or indirectly controlled by, a body that is established or conducted for profit in which is held and maintained a collection of documents and other materials that is open to the public or to researchers. 

<p><b>Canadian Trade Union:</b> A trade union which is recognized by a labour board under the laws of Canada or any province or territory of Canada and which has its head office in Canada. 

</td></tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>

  <tr bgcolor="e0e0e0">
   <td><br>

<p>The "registrant name" must be the complete name of the organization that will hold the domain registration, without any abbreviations.  (A common abbreviation may follow the complete name in parentheses.)  If the geographic location of the association is not obvious from the registrant name, the location should be added to the domain (eg. "of Winnipeg").   Specific details for a particular legal type are outlined below. 

<p><b>Government or government entity in Canada:</b> The Registrant's name must be the complete official name of the entity that will hold the domain name registration,without any abbreviations. (A common abbreviation may follow the official name in parentheses). If the Registrant is not a government, the Registrants name must be followed by the name of the jurisdiction (eg. Canada, province, territory, municipality, etc) to which the Registrant is related. 
<p><blockquote><i>Example:  "Government of Alberta"</i></blockquote>

<p><b>Canadian Political Party:</b> The Registrant's name must be the complete official name of the political party holding the domain name registration, without abbreviations. (A common abbreviation may follow the official name in parentheses.) The Registrant name must also by followed by the jurisdiction in Canada in which it is registered (if it is not obvious from the official name). 
<p><blockquote><i>Example:  "Reform Party - Alberta"</i></blockquote>

<p><b>Canadian Educational Institution:</b> The Registrant's name must be the complete official name of the institution that will hold the domain name registration, without any abbreviations. A common abbreviation may follow the official name in parentheses. The Registrant name must be followed by the jurisdiction (e.g. name of province, municipality) in which the institution is accredited if not obvious from the Registrants name. 
<p><blockquote><i>Example:  "University of British Columbia (UBC)"</i></blockquote>

<p><b>Canadian Hospital:</b> The Registrant's name must be the complete official name of the hospital that will hold the domain name registration, without any abbreviations. (A common abbreviation may follow the complete name in parentheses.) The Registrants name must be followed by the jurisdiction (e.g. name of province) in which accredited the hospital if not obvious from the Registrants name. 
<p><blockquote><i>Example:  "Veteran's Hospital Canada, Pointe Claire"</i></blockquote>

<p><b>Canadian Library, Archive or Museum:</b> The Registrant's name must be the complete legal name of the institution which will hold the domain name registration without abbreviations. (A common abbreviation may follow the complete name in parentheses.) 
<p><blockquote><i>Example:  "Royal Ontario Museum"</i></blockquote>

<p><b>Canadian Trade Union:</b> The Registrants name must be the complete official name of the trade union that will hold the domain name registration, without abbreviations. (A common abbreviation may follow the official name in parentheses.) The Registrant name must be followed by the jurisdiction in Canada which recognizes it (if it is not obvious from the Registrants name.) 
<p><blockquote><i>Example:  "Canadian Union of Postal Workers (CUPW)"</i></blockquote>


   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
    <th align=center colspan=2><font size=+1><a name='desc'>Registrant Description</font></th>
  </tr>
  
  <tr bgcolor="e0e0e0">
   <td> 

<p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered.
   </td>
  </tr>
  
</table>

</td></tr>
</table>

	    #,
    },
    government => {
	    list => [qw/GOV/],
	    intro => q#
<p>To register a municipal domain the registrant's Legal Type must be 'Government'.Government has been preselected in this form on your behalf. The registrant's name must be complete official name of the city, without any abbreviation, such as "City of Ottawa". 
<p>
Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 
<p>
	    #,
	    help => q#
<table border=1 width=100%>
<tr><td>

<table border=0>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  
  <tr bgcolor="e0e0e0">
   <td><br>

<p>The registrant must meet the requirements for "Government or government
entity in Canada" as a regional, municipal or local area government.

</td>
  </tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>
    
  <tr bgcolor="e0e0e0">
   <td><br>
<p>The Registrant's name must be the complete official name of the entity that
will hold the domain name registration, without any abbreviations. (A common
abbreviation may follow the official name in parentheses).

<p><blockquote><i>Example:  "City of Ottawa"</i></blockquote>

</td>
  </tr>
  
  <tr bgcolor="90c0ff">
    <th align=center colspan=2><font size=+1><a name='desc'>Registrant Description</font></th>
  </tr>
  
  <tr bgcolor="e0e0e0">
   <td>
<p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered.
</td>
  </tr>
  
</table>

</td></tr>
</table>

	    #,
    },
    
    indian => {
	    list => [qw/ABO INB/],
	    intro => q#
<p>If the domain is for an aboriginal individual or a group of aboriginal persons, one of the following legal types may be appropriate: 
<ul>
<li>Aboriginal Peoples (individual or groups) indigenous to Canada
<li>Indian Band recognized by the Indian Act of Canada
</ul>
<p>If the domain is for individual use, the "registrant name" must be the full legal name of the individual, as it would appear on a passport, drivers license or other government issued identification documents, such as: "John Doe".
<p>
If the domain is for group use, the "registrant name" must be the Indian Band Name or complete official name of the collectivity, or if there is no official name, the commonly known name.
<p>
Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 
<p>
	    #,
	    help => q#
<table border=1 width=100%>
<tr><td>

<table border=0>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  
  <tr bgcolor="e0e0e0">
   <td><br>
<p>Domains being registered for use by Aboriginal Peoples, must be registered by a Canadian with one of the following legal types: 
<ul>
<li><b>Aboriginal Peoples (individuals or groups) indigenous to Canada:</b> Any Inuit, First Nation, Metis or other people indigenous to Canada, and any collectivity of such Aboriginal peoples. 
<li> <b>Indian Band recognized by the Indian Act of Canada:</b> Any Indian band as defined in the Indian Act, R.S.C. 1985, c. I-5, as amended from time to time, and any group of Indian bands;
</ul>

</td></tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>

  <tr bgcolor="e0e0e0">
   <td><br>

<p><b>Aboriginal Peoples - Individual:</b> the Registrant Name must be the <b>FULL LEGAL NAME</b> of the individual who will hold the domain name registration as the name would appear on a passport, drivers license or other identification document issued by a government. 
<p><blockquote><i>Example: "John Doe".</i></blockquote> 

<p>Initials or nicknames are not allowed. Full legal names may only consist of alphabetic characters and the special characters: single quote mark('), hyphen(-), period(.). 

<p>The name may be followed by a space and "o/a xxxx" where "o/a" stands for "Operating As" and "xxxx" can be any alphanumeric string designated by the applicant. 
<p><blockquote><i>Example: "John Doe o/a Doe Group"</i></blockquote> 
<p>The name may be followed by a space and a degree granted to the registrant by a recognized degree granting institution or a recognized professional designation, which the registrant has the right to use (e.g. PhD, MD, DDS). 

<p><b>Aboriginal Peoples - Group:</b> The Registrants name must be the complete official name of the indigenous people a collectivity of Aboriginal Persons or, if there is no official name, the name by which the collectivity is commonly known. 
<p><blockquote><i>Example: "Carrier Sekani Tribal Council"</i></blockquote>

<p><b>Indian Band recognized by the Indian Act of Canada:</b> The name of Registrant must be the Indian Band Name as registered with the Department of Indian and Northern Affairs, Canada. 
<p><blockquote><i>Example: "Lac la Ronge Indian Band"</i></blockquote> 

</td>
  </tr>
  
  <tr bgcolor="90c0ff">
    <th align=center colspan=2><font size=+1><a name='desc'>Registrant Description</font></th>
  </tr>
  
  <tr bgcolor="e0e0e0">
   <td> 

<p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered.
</td>
  </tr>
  
</table>

</td></tr>
</table>

	    #,
    },
    other => {
	    list => [qw/CCT RES/],
	    intro => q#
<p>If you were not able to find the appropriate "grouping" from the list, the registrant MAY NOT BE CANADIAN.    In this case, the domain cannot be registered UNLESS it is a registered trademark in Canada.  If it is registered trademark, please go back and register this domain using the trademark legal type.

<p>Otherwise, the registrant most likely is representing an informal group like a musical group or fan club.  In this case the domain should be registered by an individual and use one of the following legal types:
<ul>
<li>Canadian Citizen
<li>Permanent Resident of Canada
</ul>
<p>The "registrant name" must be the full legal name of the individual, as it would appear on a passport, drivers license or other government issued identification documents, followed by the characters "o/a" and then the "informal group" name (where o/a stands for "operating as"), such as <i>"John Doe o/a Heavy Metal"</i>.

<p>Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.   Please select the appropriate Legal Type and enter the appropriate Registrant Name below. 

<p>
	    #,
	    help => q#
<table border=1 width=100%>
<tr><td>

<table border=0>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="legal_type">Legal Type</font></th>
  </tr>

  <p>
  
  <tr bgcolor="e0e0e0">
   <td><br>

<p>Domains being registered for a small business or a non-incorporated business, must be registered by the Canadian owner with one of the following legal types:
<ul> 
<li> <b>Canadian citizen:</b> A Canadian citizen of the age of majority under the laws of the province or territory in Canada in which he or she resides or last resided 

<li> <b>Permanent Resident of Canada:</b> A permanent resident as defined in the Immigration Act (Canada) R.S.C. 1985, c.I-2, as amended from time to time, who is "ordinarily resident in Canada" and of the age of majority under the laws of the province or territory in Canada in which he or she resides or last resided. ("Ordinarily resident in Canada" means an individual who resides in Canada for more than 183 days in the twelve month period immediately preceding the date of the applicable request for registration of the .ca domain name or sub-domain name and in each twelve month period thereafter for the duration of the domain name registration.) 
</ul>
<p>The registrant name can be altered to reflect that the domain is being used for a business operation rather then for personal use.

   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
   <th align=center colspan=2><font size=+1><a name="name">Registrant Name</font></th>
  </tr>
    
  <tr bgcolor="e0e0e0">
   <td><br>

<p>When registering a domain with the legal type: 
<ol type='a'>
<li>Canadian Citizen, or
<li>Permanent Resident 
</ol>
<p>The Registrant Name must be the <b>FULL LEGAL NAME</b> of the individual who will hold the domain name registration as the name would appear on a passport, drivers license or other identification document issued by a government. 
<p><blockquote><i>Example: "John Doe".</i></blockquote>

<p>The name may be followed by a space and "o/a xxxx" where "o/a" stands for "Operating As" and "xxxx" can be any alphanumeric string designated by the applicant.   When registering the domain for a small business, or a non-incorporated business, the "xxxx" field should be used to indicate this business.
<p><blockquote><i>Example: "John Doe o/a Doe Consulting Group"</i></blockquote> 
 
<p>The name may be followed by a space and a degree granted to the registrant by a recognized degree granting institution or a recognized professional designation, which the registrant has the right to use (e.g. PhD, MD, DDS). 

<p>Once the domain is registered, <b>you cannot easily change the registrant name</b>, so please ensure that this name is correct.
 
   </td>
  </tr>
  
  <tr bgcolor="90c0ff">
    <th align=center colspan=2><font size=+1><a name='desc'>Registrant Description</font></th>
  </tr>
  
  <tr bgcolor="e0e0e0">
   <td>

<p>The registrant description is a free form field where additional information about the registrant or the purpose of the domain can be entered.
   </td>
  </tr>
  
</table>

</td></tr>
</table>
	    #,
    },
);

sub legal_type_list{
    my $group = shift;
    unless (exists $legal_type_groups{$group}){
	$group = 'all';
    }
    my @list = map {
		    {
			legal_type => $_,
			%{$legal_types{$_}},
			
		    }
		   } @{$legal_type_groups{$group}{list}};
    return (%{$legal_type_groups{$group}},list=>\@list);
}


sub municipal_format{
    my $domain_name=shift;
    #4th level with previx and province 
    return 1 if $domain_name =~ /^
	    ( city|
	      ville|
	      town|
	      village|
	      hamlet|
	      hameau|
	      municipality|
	      municipalite
	    )
	    \.([^.]+)\.
	    ( ab|bc|mb|nb|nl|ns|nt|nu|on|pe|qc|sk|yk)
	    \.ca$/xi;

    #2nd level only and real name is not a province
    return 1 if $domain_name =~ /^([^.]+)\.ca$/i 
	        and $1 !~ /^(ab|bc|mb|nb|nl|ns|nt|nu|on|pe|qc|sk|yk)$/i;
    return 0; 
}

sub help_icon{
    print "Content-type: image/gif\n\n",
    "GIF89a\24\0\24\0\263\16\0\373\347^\375\357\225\240\225&\371\336!\353\322\"UjPeY\r\301\255\36\373\342=\322\303/\31?b\335\304\35A:\b\207|\e\0\0\0\0\0\0!\371\4\1\0\0\16\0,\0\0\0\0\24\0\24\0\0\4\240\320\311\31\252\r`jz-\370\310&] b\226\233\207\$\205\342\26\2049\f\34\266\272\270\2\317\3042\332\203V\316%\230-\16\216\n\0001\313\tu\306\203\340\3\230\5\13\5\201\0W0\n\32 \353,1lx\301Kq\320I\360\32\226L\361\263h]4\f\246\270U\200m,\304\aw2jO\tV\4\a\6\fjcNu\r\f\f\16\13\13m3\a\216\3\13\2\212\22\a\a\224\226O\a\232\234\221\23Z\240\4\253\251=\246\222\32\r\262\2\237\265_\221\260\e\6\273\274\273\270\271\"\16\277\277\"\21\0;";
    return ();
}

1;


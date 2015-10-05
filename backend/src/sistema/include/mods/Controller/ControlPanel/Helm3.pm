#!/usr/bin/perl
# Use: Module
# Controller - is4web.com.br
# 2008
package Controller::ControlPanel::Helm3;

require 5.008;
require Exporter;

use Controller::Services;
use Controller::WebSpider;

@ISA = qw(Controller::Services Controller::WebSpider Exporter);

use constant {
	SYS_ADMIN => 'ADMIN',
	ACL_ADMIN => 0,
	ACL_RESELLER => 1,
	ACL_USER => 2,
};

sub new {
	my $proto = shift;
    my $class = ref($proto) || $proto;
    
	my $self = new Controller::Services( @_ );
	my $agent = new Controller::WebSpider;
	%$self = (
		%$self,
		%$agent,
		'ERR' => undef,
	);

	bless($self, $class);
	$self->Controller::WebSpider::refer2me;

	return $self;
}

sub baseurl {
	my ($self) = shift;
	return $self->{_helm3}{$self->srvid}{baseurl} if $self->{_helm3}{$self->srvid}{baseurl};
	
	my $protocol = $self->server('ssl') ? 'https' : 'http';
	my $port = $self->server('port') || 80; 
	$self->{_helm3}{$self->srvid}{baseurl} = sprintf('%s://%s:%d',$protocol,$self->server('host'),$port);
	
	return $self->{_helm3}{$self->srvid}{baseurl};
}

sub raise_error {
	my ($self) = shift;
	$self->set_error($self->content);
	return 0;	
}

sub login {
	my ($self) = shift;
	return if $self->error;
	
	$self->{_helm3} = undef; #reset
	my $url = $self->baseurl;
	$self->get($url);
	return $self->raise_error unless $self->forms;
	
	#logon
	$self->form_name('frmLogon');
	$self->field('txtUsername',$self->server('username'));
	$self->field('txtPassword',$self->server('key'));
	$self->select('selLanguageCode','EN');
	$self->select('selInterface','standard_XP');
	$self->click('btnProcess');
	$self->redirect; #Helm 3 redirects
	
	my $pattern = $self->server('username');
	unless ($self->success and $pattern and $self->content =~ m/Logged in: $pattern\<\/option/si) {
		$self->{ERR} = $self->lang(200,'login',$url);		
	} elsif ($pattern and $self->content =~ /UserAccNum=(.+?)"/) {
		$self->{_helm4}{$self->srvid}{id} = $1;
	}
	$self->{ERR} = $self->lang(9,'login') unless $pattern; 
	
	return $self->error ? 0 : 1;
}

sub list_customers {
	my ($self) = shift;
	return if $self->error;

	my $type = uc "ACL_".$_[0];
	$self->{_helm3}{$self->srvid}{$type} = undef unless $_[1];
	my $url = $self->baseurl . '/interfaces/standard/users.asp?AccountType=' . eval $type;
	$url .= '&page='.$self->{_page};
	$url .= '&UserAccNum='.$self->{_helm3}{$self->srvid}{'UserAccNum'};
	$self->get($url);
	
	if ($self->success) {
		my $context = $self->content;
		$self->{_helm3}{$self->srvid}{$type}{$1} = $2
		while $context =~ m/document\.location\.href\=\'user\.asp\?UserAccNum=(.+?)\'\".*?\<span class=\"(.+?)\">\2\<\/span\>\<\/font\>\<\/td\>\<\/tr\>/gs;
		#se tiver pagina abrir outra
		if ($context =~ m/\| \<a href\=\"\?page\=(\d+?).*\" class\=\"linkColour\"\>\1\<\/a\>\<\/font\>/gs && $self->{_page} < $1) {
			$self->{_page}++;
			$self->list_customers($_[0],1);
		}
	} else {
		$self->{ERR} = $self->lang(202,'list_customers');
	}
	
	return $self->error ? 0 : 1;
}

sub helm_resellers {
	my ($self) = shift;
	return %{ $self->{_helm3}{$self->srvid}{'ACL_RESELLER'} };
}

sub helm_users {
	my ($self) = shift;
	return %{ $self->{_helm3}{$self->srvid}{'ACL_USER'} };
}

sub list_domains {
	my ($self) = shift;
	return if $self->error;

	my $type = uc "ACL_DOMAIN";
	$self->{_helm3}{$self->srvid}{$type} = undef unless $_[0];
	my $url = $self->baseurl . '/interfaces/standard/domains.asp?';
	$url .= 'page='.$self->{_page};
	$self->get($url);
	
	if ($self->success) {
		my $context = $self->content;
		$self->{_helm3}{$self->srvid}{$type}{ Controller::unhtml($2) } = { 'id' => $1, 'owner' => $3, 'status' => $4 }
		while $context =~ m/\<script.*?document\.write\(\'\<a href=\"Domain\.asp\?UserAccNum=.+?\&DomainID=(\d+?)\".*?document\.write\(\'(.+?)\'\).*?<\/script\>\<\/font\>.*?\<font class=\"normalFont\"\>\&nbsp\;Hosted Domain\<\/font\>.*?\<font class=\"normalFont\"\>\&nbsp\;(.+?)\<\/font\>.*?\<span class=\"(.+?)\"\>\4\<\/span\>\<\/font\>\<\/td\>\<\/tr\>/gs;
		#se tiver pagina abrir outra
		if ($context =~ m/\| \<a href\=\"\?page\=(\d+?).*\" class\=\"linkColour\"\>\1\<\/a\>\<\/font\>/gs && $self->{_page} < $1) {
			$self->{_page}++;
			$self->list_domains(1);
		}
	} else {
		$self->{ERR} = $self->lang(202,'list_domains');
	}
	
	return $self->error ? 0 : 1;
}

sub helm_domains {
	my ($self) = shift;
	return %{ $self->{_helm3}{$self->srvid}{'ACL_DOMAIN'} };
}

sub list_ftps {
	my ($self) = shift;
	return if $self->error;

	my $type = uc "ACL_FTP";
	$self->{_helm3}{$self->srvid}{$type} = undef unless $_[0];
	my $url = $self->baseurl . '/interfaces/standard/FTPs.asp?DomainID=' . $self->{_helm3}{$self->srvid}{'DomainID'};
	$url .= '&page='.$self->{_page};
	$self->get($url);
	
	if ($self->success) {
		my $context = $self->content;
		$self->{_helm3}{$self->srvid}{$type}{Controller::unhtml($2)} = { 'id' => $1, 'Read' => $3, 'Write' => $4, 'Folder' => $5 }
		while $context =~ m/\<script.*?document\.write\(\'\<a href=\"FTP\.asp\?DomainID=\d+?\&FTPAccountID=(\d+?)\".*?document\.write\(\'(.+?)\'\).*?\<\/script\>\<\/font\>.*?\<font class=\"normalFont\"\>\&nbsp\;(\w+?)\<\/font\>.*?\<font class=\"normalFont\"\>\&nbsp\;(\w+?)\<\/font\>.*?\<font class=\"SmallFont2\"\>\&nbsp\;(.+?)\<\/font\>\<\/td\>\<\/tr\>/gs;
		#se tiver pagina abrir outra
		if ($context =~ m/\| \<a href\=\"\?page\=(\d+?).*\" class\=\"linkColour\"\>\1\<\/a\>\<\/font\>/gs && $self->{_page} < $1) {
			$self->{_page}++;
			$self->list_ftps(1);
		}
	} else {
		$self->{ERR} = $self->lang(202,'list_ftps');
	}
	
	return $self->error ? 0 : 1;
}

sub helm_ftps {
	my ($self) = shift;
	return %{ $self->{_helm3}{$self->srvid}{'ACL_FTP'} };
}

sub list_dbs {
	my ($self) = shift;
	return if $self->error;

	my $type = uc "ACL_DB";
	$self->{_helm3}{$self->srvid}{$type} = undef unless $_[0];
	my $url = $self->baseurl . '/interfaces/standard/Databases.asp?DomainID=' . $self->{_helm3}{$self->srvid}{'DomainID'};
	$url .= '&page='.$self->{_page};
	$self->get($url);
	
	if ($self->success) {
		my $context = $self->content;
		$self->{_helm3}{$self->srvid}{$type}{Controller::unhtml($2)} = { 'id' => $1, 'type' => $3 }
		while $context =~ m/\<script.*?document\.write\(\'\<a href=\"Database\.asp\?DomainID=\d+?\&DatabaseID=(\d+?)\".*?document\.write\(\'(.+?)\'\).*?\<\/script\>\<\/font\>.*?\<font class=\"normalFont\"\>\&nbsp\;.*?\<\/font\>.*?\<font class=\"normalFont\"\>\&nbsp\;(\w+?)\<\/font\>\<\/td\>\<\/tr\>/gs;
		#se tiver pagina abrir outra
		if ($context =~ m/\| \<a href\=\"\?page\=(\d+?).*\" class\=\"linkColour\"\>\1\<\/a\>\<\/font\>/gs && $self->{_page} < $1) {
			$self->{_page}++;
			$self->list_ftps(1);
		}
		#Get Details
		unless ($_[0]) {
			my %dbs = $self->helm_dbs;
			foreach (keys %dbs) {
				$self->{_helm3}{$self->srvid}{'DatabaseID'} = $dbs{$_}{'id'};
				$self->db_details;
			}			
		}		
		#$self->{ERR} = $self->lang(204,$_[0]);ignore error
	} else {
		$self->{ERR} = $self->lang(202,'list_dbs');
	}
	
	return $self->error ? 0 : 1;
}

sub helm_dbs {
	my ($self) = shift;
	return %{ $self->{_helm3}{$self->srvid}{'ACL_DB'} };
}

sub db_details {
	my ($self) = shift;
	return if $self->error;

	my $type = uc "ACL_DB";
	$self->{_helm3}{$self->srvid}{$type} = undef unless $_[0];
	my $url = $self->baseurl . '/interfaces/standard/Databases.asp?DomainID=' . $self->{_helm3}{$self->srvid}{'DomainID'};
	$url .= '&DatabaseID=' . $self->{_helm3}{$self->srvid}{'DatabaseID'};	
	$self->get($url);
	
	if ($self->success) {
		my $context = $self->content;
		$self->{_helm3}{$self->srvid}{$type}{Controller::unhtml($2)} = { 'id' => $1, 'Read' => $3, 'Write' => $4, 'Folder' => $5 }
		while $context =~ m/\<script.*?document\.write\(\'\<a href=\"FTP\.asp\?DomainID=\d+?\&FTPAccountID=(\d+?)\".*?document\.write\(\'(.+?)\'\).*?\<\/script\>\<\/font\>.*?\<font class=\"normalFont\"\>\&nbsp\;(\w+?)\<\/font\>.*?\<font class=\"normalFont\"\>\&nbsp\;(\w+?)\<\/font\>.*?\<font class=\"SmallFont2\"\>\&nbsp\;(.+?)\<\/font\>\<\/td\>\<\/tr\>/gs;
		#se tiver pagina abrir outra
		if ($context =~ m/\| \<a href\=\"\?page\=(\d+?).*\" class\=\"linkColour\"\>\1\<\/a\>\<\/font\>/gs && $self->{_page} < $1) {
			$self->{_page}++;
			$self->list_ftps(1);
		}
	} else {
		$self->{ERR} = $self->lang(202,'list_ftps');
	}
	
	return $self->error ? 0 : 1;
}
#===========TODO Helm4 -> Helm3
sub quicksearch {#verifica se já existe
	my ($self) = shift;
	return if $self->error;
	
	my $quest = $_[0] eq 'DOMAINS' ? $self->service('dominio') : $self->service('useracc');
	$self->form_name('frmMain');
	$self->field('txtQuickSearch',$quest);
	$self->tick('chxIncludeCustomers','on');
	$self->select('cbxQuickSearch',$_[0]);
	$self->field('__EVENTTARGET','_ctl3$grid$Pager'); #show all
	$self->field('__EVENTARGUMENT','Page,-1');
	$self->click('btnQuickSearch');
	
	my @matches;
	unless ($self->success and @matches = $self->content =~ m/No Items Found/gsi) {
		if ($_[0] eq 'CUSTOMERS') {
			my ($id) = $self->content =~ m/\<a href="\/Interface\/Default\.aspx\?AccountId=(\d+?)"\>$quest\<\/a\>/is;
			$self->{_helm3}{$self->srvid}{customers}{lc $quest} = $id if $id;
		} else {
			my ($id) = $self->content =~ m/\<a href="\/Interface\/Domains\/Domain\.aspx\?DomainId=(\d+?)\&amp\;AccountId=(\d+?)"\>$quest\<\/a\>/is;
			$self->{_helm3}{$self->srvid}{domains}{lc $quest} = $id if $id;
		}
		$self->{ERR} = $self->lang(203,$quest) unless $_[1];
	}
	$self->{ERR} = $self->lang(202,'quicksearch') if scalar @matches > 1;
	$self->{ERR} = $self->lang(9,'quicksearch') unless $quest;
	
	return $self->error ? 0 : scalar @matches;
}


sub chooseuser {
	my ($self) = shift;
	
	my $user = $self->service('dominio');
    $user =~ s/[^a-zA-Z0-9]//g;
    $user = lc $user;
	$user =~ s/^test/tst/; 
	$user =~ s/^(\d+)//g;	
	$user =~ s/^virtfs$/virtf/;
	$user =~ s/^all$/allctrl/;
	$user =~ s/assword//g;
    $user = substr($user,0,8);
    $self->service('useracc',$user);

    $self->list_customers;
    my $i;
	while ($self->{_helm3}{$self->srvid}{customers}{$user}) {
		$user = substr($user,0,8-length($i++)) . $i;
		$self->{ERR} = $self->lang(250,'chooseuser') and return if length($i) > 7;
	}
	$self->service('useracc',$user) if $i > 0;
	$self->{ERR} = $self->lang(9,'chooseuser') unless $user;
	
	return $self->error ? 0 : 1;
}

sub search_role {
	my ($self) = shift;
	return if $self->error;

	my $url = $self->baseurl . '/Interface/AccountRoles/AccountRoles.aspx?AccountId='.$self->{_helm3}{$self->srvid}{id};
	$self->get($url);
	
	$self->form_name('frmMain');
	$self->field('_ctl3:RoleName:txtRoleName',$_[0]);
	$self->select('_ctl3:IsPublic:cbxIsPublic','True');
	$self->click('_ctl3:btnButton1');
	
	my @matches;
	$self->{ERR} = $self->lang(9,'search_role') unless $_[0];	
	if ($self->success and $_[0] and @matches = $self->content =~ m/\>$_[0]\</gsi) {
		return $self->error ? 0 : 1;
	}
	$self->{ERR} = $self->lang(202,'search_role') if scalar @matches > 1;

	return 0;
}

sub create_role {
	my ($self) = shift;
	return if $self->error;

	my $url = $self->baseurl . '/Interface/AccountRoles/AccountRole.aspx?AccountId='.$self->{_helm3}{$self->srvid}{id};
	$self->get($url);
	
	$self->form_name('frmMain');
	$self->field('_ctl3:FormItem_RoleName:txtRoleName',$_[0]);
	$self->field('_ctl3:FormItem_Description:txtDescription',$self->lang(8));
	$self->tick('_ctl3:FormItem_IsPublic:cboIsPublic','on');
	$self->select('_ctl3:_ctl0:Template:FormItem_PredefinedPermissions:cbxPredefinedAccountRoles',$_[1]);		
	$self->click('_ctl3:btnButton1');
		
	my @matches;
	unless ($self->success and @matches = $self->content =~ m/The following are account roles that have been set up in your account/si) {
		$self->{ERR} = $self->lang(202,'create_role');
		$self->get_helmerror;
	}

	return $self->error ? 0 : 1;		
}

sub create_customer {
	my ($self) = shift;
	return if $self->error;

	my $url = $self->baseurl . '/Interface/Customers/CustomerAdd.aspx?AccountId='.$self->{_helm3}{$self->srvid}{id};
	$self->get($url);
	$url .= '&__EVENTTARGET=_ctl3$FormCategory_Contact$FormItem_Country$cbxCountry&__EVENTARGUMENT='.$self->user('cc'); #show all
	
	$self->form_name('frmMain');
	$self->field('_ctl3:FormCategory_AccountDetails:FormItem_AccountName:txtAccountName',$self->service('useracc'));
	$self->select('_ctl3:FormCategory_AccountDetails:FormItem_AccountRole:cbxAccountRole',$_[0]);
	my ($firstn,$lastn) = split(" ",$self->user('name'),2); 
	$self->field('_ctl3:FormCategory_LoginDetails:FormItem_LoginFirstName:txtLoginFirstName',$firstn);
	$self->field('_ctl3:FormCategory_LoginDetails:FormItem_LoginLastName:txtLoginLastName',$lastn);
	$self->field('_ctl3:FormCategory_LoginDetails:FormItem_Email:txtEmail',${$self->user('email')}[0]);
	my %dados = %{$self->service('dados')};
	$self->field('_ctl3:FormCategory_LoginDetails:FormItem_LoginPassword:txtLoginPassword',$dados{'Senha'});
	$self->field('_ctl3:FormCategory_LoginDetails:FormItem_ConfirmLoginPassword:txtConfirmLoginPassword',$dados{'Senha'});
	$self->field('_ctl3:FormCategory_Contact:FormItem_CompanyName:txtCompanyName',$self->user('empresa'));
	$self->field('_ctl3:FormCategory_Contact:FormItem_CompanyEmail:txtCompanyEmail',${$self->user('email')}[0]);
	$self->field('_ctl3:FormCategory_Contact:FormItem_Address1:txtAddress1',$self->user('endereco'));
	$self->field('_ctl3:FormCategory_Contact:FormItem_Address2:txtAddress2',$self->user('numero'));
	$self->field('_ctl3:FormCategory_Contact:FormItem_Address3:txtAddress3','');
	$self->field('_ctl3:FormCategory_Contact:FormItem_PostCode:txtPostCode',$self->user('cep'));
	$self->field('_ctl3:FormCategory_Contact:FormItem_Town:txtTown',$self->user('cidade'));

	$self->click('_ctl3:btnButton1');
		
	my @matches;
	unless ($self->success and @matches = $self->content =~ m/The following are users that are held within this account/si) {
		$self->{ERR} = $self->lang(202,'create_customer');
		$self->get_helmerror;
	}

	return $self->error ? 0 : 1;	
}

sub create_package {
	my ($self) = shift;
	return if $self->error;

	$self->quicksearch('CUSTOMERS',1) unless $self->{_helm3}{$self->srvid}{customers}{$self->service('useracc')};
	my $url = $self->baseurl . '/Interface/Packages/AddPackage.aspx?AccountId='.$self->{_helm3}{$self->srvid}{customers}{$self->service('useracc')};;
	$self->get($url);
	
	$self->form_name('frmMain');
	$self->field('_ctl3:FormItem_PackageName:txtPackageName',$_[0]);
	$self->select('_ctl3:FormItem_Plan:cbxPlan',$self->plan('auto'));
	$self->click('_ctl3:btnButton1');
		
	my @matches;
	unless ($self->success and @matches = $self->content =~ m/Below is a list of the packages that have been set up for this account/si) {
		$self->{ERR} = $self->lang(202,'create_package');
		$self->get_helmerror;
	}

	return $self->error ? 0 : 1;	
}

sub create_domain {
	my ($self) = shift;
	return if $self->error;

	$self->quicksearch('CUSTOMERS',1) unless $self->{_helm3}{$self->srvid}{customers}{$self->service('useracc')};
	my $url = $self->baseurl . '/Interface/Domains/DomainCreate.aspx?AccountId='.$self->{_helm3}{$self->srvid}{customers}{$self->service('useracc')};;
	$self->get($url);
	
	$self->form_name('frmMain');
	$self->field('_ctl3:FormItem_DomainName:txtDomainName',$self->service('dominio'));
	$self->select('_ctl3:FormItem_IsParked:cbxType',$_[0]);
	$self->select('_ctl3:FormItem_Package:cbxPackage',$_[1]);
	$self->click('_ctl3:btnButton1');
	$self->form_name('frmMain'); #submit confirmation page
	$self->click('_ctl3:btnButton1');
		
	my @matches;
	unless ($self->success and @matches = $self->content =~ m/The following are domains available for you to control/si) {
		$self->{ERR} = $self->lang(202,'create_domain');
		$self->get_helmerror;
	}

	return $self->error ? 0 : 1;	
}

sub nameserver_mask {
	my ($self) = shift;
	return if $self->error;

	$self->quicksearch('CUSTOMERS',1) unless $self->{_helm3}{$self->srvid}{customers}{$self->service('useracc')};
	my $url = $self->baseurl . '/Interface/Account/AccountSettings.aspx?AccountId='.$self->{_helm3}{$self->srvid}{customers}{$self->service('useracc')};
	$self->get($url);
	
	$self->form_name('frmMain');
	$self->field('_ctl3:_ctl2:FormCategory_PersonalDNS:FormItem_NameServer:txtNameServer',$self->service('dominio'));
	$self->click('_ctl3:btnButton1');
		
	my @matches;
	unless ($self->success and @matches = $self->content =~ m/The Account Settings have been successfully saved/si) {
		$self->{ERR} = $self->lang(202,'nameserver_mask');
		$self->get_helmerror;
	}

	return $self->error ? 0 : 1;	
}

sub create_nameserver {
	my ($self) = shift;
	return if $self->error;

	my $url = $self->baseurl . '/Interface/Servers/Servers.aspx?AccountId='.$self->{_helm3}{$self->srvid}{id};
	$url .= '&__EVENTTARGET=_ctl3$grid$Pager&__EVENTARGUMENT=Page,-1'; #show all
	$self->get($url);
	
	$self->follow_link( text => $self->server('nome') );#requisito que 	
	$self->follow_link( text => 'Services');
	$self->follow_link( text => 'Show All');
	$self->follow_link( text_regex => qr/DNS/i);#exigencia de nome
	
	#ignore if already exist
	my $ns1 = 'ns1.' . $self->service('dominio');
	my $ns2 = 'ns2.' . $self->service('dominio');
	
	if ($self->content !~ m/\>$ns1\</si) {
		$self->form_name('frmMain');
		$self->click('_ctl5:btnButton1');
		
		$self->form_name('frmMain');	
		$self->field('_ctl3:FormItem_NameServer:txtNameServer', $ns1);
		my @ip1 = split(/\./,$self->server('ns1'));
		$self->field('_ctl3:FormItem_IPAddress:ipNameServer:TextBox1',$ip1[0]);
		$self->field('_ctl3:FormItem_IPAddress:ipNameServer:TextBox2',$ip1[1]);
		$self->field('_ctl3:FormItem_IPAddress:ipNameServer:TextBox3',$ip1[2]);
		$self->field('_ctl3:FormItem_IPAddress:ipNameServer:TextBox4',$ip1[3]);
		$self->click('_ctl3:btnButton1');
	
		my @matches;
		$self->{ERR} = $self->lang(9,'create_nameserver') unless @ip1 == 4;#ipv4
		unless ($self->success and @matches = $self->content =~ m/Use the following form to edit the details for a service/si) {
			$self->{ERR} = $self->lang(202,'create_nameserver');
			$self->get_helmerror;
		}
	}
	if ($self->content !~ m/\>$ns2\</si && !$self->error) {
		$self->form_name('frmMain');
		$self->click('_ctl5:btnButton1');
		$self->form_name('frmMain');
		$self->field('_ctl3:FormItem_NameServer:txtNameServer', $ns2);
		my @ip2 = split(/\./,$self->server('ns2'));
		$self->field('_ctl3:FormItem_IPAddress:ipNameServer:TextBox1',$ip2[0]);
		$self->field('_ctl3:FormItem_IPAddress:ipNameServer:TextBox2',$ip2[1]);
		$self->field('_ctl3:FormItem_IPAddress:ipNameServer:TextBox3',$ip2[2]);
		$self->field('_ctl3:FormItem_IPAddress:ipNameServer:TextBox4',$ip2[3]);
		$self->click('_ctl3:btnButton1');
			
		my @matches;
		$self->{ERR} = $self->lang(9,'create_nameserver') unless @ip2 == 4;
		unless ($self->success and @matches = $self->content =~ m/Use the following form to edit the details for a service/si) {
			$self->{ERR} = $self->lang(202,'create_nameserver');
			$self->get_helmerror;
		}
	}
		
	return $self->error ? 0 : 1;	
}

sub search_resources {
	my ($self) = shift;
	return if $self->error; 

	$self->quicksearch('DOMAINS',1);
	my $pattern = $self->service('dominio');
	$self->follow_link( text_regex => qr/^$pattern$/i);
	if ($self->success) {
		$self->service('MultiWEB',$self->search_srvid('nome',$1)) if ($self->content =~ m/Web \[\<A .+?\>(.+?) -/si);
		$self->service('MultiDNS',$self->search_srvid('nome',$1)) if ($self->content =~ m/DNS \[\<A .+?\>(.+?) -/si);
		$self->service('MultiMAIL',$self->search_srvid('nome',$1)) if ($self->content =~ m/Mail \[\<A .+?\>(.+?) -/si);
		$self->service('MultiDB',$self->search_srvid('nome',$1)) if ($self->content =~ m/MySQL . \[\<A .+?\>(.+?) -/si);
		$self->service('MultiFTP',$self->search_srvid('nome',$1)) if ($self->content =~ m/FTP \[\<A .+?\>(.+?) -/si);
		$self->service('MultiSTATS',$self->search_srvid('nome',$1)) if ($self->content =~ m/AWStats \[\<A .+?\>(.+?) -/si);
	}
	$self->{ERR} = $self->lang(9,'search_resources') unless $pattern;
	
	return $self->error ? 0 : 1;
}

sub create_ftpaccount {
	my ($self) = shift;
	return if $self->error;

	$self->quicksearch('DOMAINS',1);
	my $pattern = $self->service('dominio');
	$self->follow_link( text_regex => qr/^$pattern$/i);
	$self->follow_link( text_regex => qr/^FTP Accounts$/i);
	$self->form_name('frmMain');
	$self->click('_ctl3:btnButton1');
	
	$self->form_name('frmMain');
	$self->field('_ctl3:FormItem_tbAccountName:ctbAccountName',$_[0]);
	my %dados = %{$self->service('dados')};
	$self->field('_ctl3:FormItem_pbPassword:cpbPassword',$dados{'Senha'});
	$self->field('_ctl3:FormItem_pbConfirmPassword:_ctl0',$dados{'Senha'});
	$self->click('_ctl3:btnButton1');
	
	my @matches;
	unless ($self->success and @matches = $self->content =~ m/This is a list of all of the FTP accounts that have been setup for this domain/si) {
		$self->{ERR} = $self->lang(202,'create_ftpaccount');
		$self->get_helmerror;
	}
	$self->{ERR} = $self->lang(9,'search_resources') unless $pattern;
	
	return $self->error ? 0 : 1;
}

sub create_dns {
	my ($self) = shift;
	return if $self->error;

	$self->quicksearch('DOMAINS',1);
	my $pattern = $self->service('dominio');
	$self->follow_link( text_regex => qr/^$pattern$/i);
	$self->follow_link( text_regex => qr/^DNS Zone Editor$/i);

	if ($_[0] =~ m/A Record/i) {	
		if ($self->content !~ m/\>ns1\</si) {
			$self->form_name('frmMain');
			$self->click('_ctl3:btnButton1'); #Click ADD
			$self->form_name('frmMain');
			$self->field('_ctl3:FormItem_RecordType:cbxRecordType',$_[0]);
			$self->click('_ctl3:btnButton1');
	
			my @ip1 = split(/\./,$self->server('ns1'));
			$self->form_name('frmMain');
			$self->field('_ctl3:FormItem_HostName:txtHostName','ns1');
			$self->field('_ctl3:FormItem_IPAddress:ipARecord:TextBox1',$ip1[0]);
			$self->field('_ctl3:FormItem_IPAddress:ipARecord:TextBox2',$ip1[1]);
			$self->field('_ctl3:FormItem_IPAddress:ipARecord:TextBox3',$ip1[2]);
			$self->field('_ctl3:FormItem_IPAddress:ipARecord:TextBox4',$ip1[3]);
			$self->click('_ctl3:btnButton1');
	
			my @matches;
			$self->{ERR} = $self->lang(9,'create_dns') unless @ip1 == 4;#ipv4
			unless ($self->success and @matches = $self->content =~ m/The following shows the contents of the DNS zone for this domain name/si) {
				$self->{ERR} = $self->lang(202,'create_dns');
				$self->get_helmerror;
			}
		}
		if ($self->content !~ m/\>ns2\</si) {
			$self->form_name('frmMain');
			$self->click('_ctl3:btnButton1'); #Click ADD			
			
			$self->form_name('frmMain');
			$self->field('_ctl3:FormItem_RecordType:cbxRecordType',$_[0]);
			$self->click('_ctl3:btnButton1');
	
			my @ip2 = split(/\./,$self->server('ns2'));
			$self->form_name('frmMain');
			$self->field('_ctl3:FormItem_HostName:txtHostName','ns2');
			$self->field('_ctl3:FormItem_IPAddress:ipARecord:TextBox1',$ip2[0]);
			$self->field('_ctl3:FormItem_IPAddress:ipARecord:TextBox2',$ip2[1]);
			$self->field('_ctl3:FormItem_IPAddress:ipARecord:TextBox3',$ip2[2]);
			$self->field('_ctl3:FormItem_IPAddress:ipARecord:TextBox4',$ip2[3]);
			$self->click('_ctl3:btnButton1');
		
			my @matches;
			$self->{ERR} = $self->lang(9,'create_dns') unless @ip2 == 4;#ipv4
			unless ($self->success and @matches = $self->content =~ m/The following shows the contents of the DNS zone for this domain name/si) {
				$self->{ERR} = $self->lang(202,'create_dns');
				$self->get_helmerror;
			}
		}
	}
	
	return $self->error ? 0 : 1;
}

sub alter_customer {
	my ($self) = shift;
	return if $self->error;

	$self->quicksearch('CUSTOMERS',1);
	my $pattern = $self->service('useracc');
	$self->follow_link( text_regex => qr/^$pattern$/i);
	
	$self->form_name('frmMain');
	$self->field('_ctl3:FormItem_AccountStatus:cbxStatus',$_[0]);
	$self->tick('_ctl3:FormItem_AccountStatus:chkIncludeCustomers','on') if $_[1];
	$self->click('_ctl3:btnButton1');
	
	$self->form_name('frmMain');
	$self->click('_ctl3:btnConfirm');
	
	$self->form_name('frmMain');
	unless ($self->success and $self->value_name('_ctl3:FormItem_AccountStatus:cbxStatus') eq $_[0] ) {
		$self->{ERR} = $self->lang(202,'alter_customer');
		$self->get_helmerror;
	}
	$self->{ERR} = $self->lang(9,'alter_customer') unless $pattern;
	
	return $self->error ? 0 : 1;
}

sub creseller {
	my ($self) = shift;
	return if $self->error;
	
	$self->login;
	$self->quicksearch('DOMAINS');
	$self->chooseuser;
	$self->create_role('CTRL_RROLE','Reseller') unless $self->search_role('CTRL_RROLE');
	$self->{_undo}{customer} = $self->create_customer('CTRL_RROLE');
	$self->nameserver_mask;
	$self->{_undo}{nameserver} = $self->create_nameserver;
	$self->create_package('Default');
	$self->create_domain('Active','Default');
	$self->search_resources;
	$self->create_ftpaccount('default'); #default@domain.com
	$self->create_dns('A Record');
	$self->undo;
	$self->create_service;
	
	return $self->error ? 0 : 1;
}

sub rreseller {
	my ($self) = shift;
	return if $self->error;
	
	$self->login;
	$self->remove_customer;
	$self->remove_nameserver;
	$self->remove_service;
	
	return $self->error ? 0 : 1;
}

sub chosting {
	my ($self) = shift;
	return if $self->error;
	
	$self->login;
	$self->quicksearch('DOMAINS');	
	$self->service('useracc',$self->setting('user_host_win'));
	$self->quicksearch('CUSTOMERS',1);
	$self->{_helm3}{$self->srvid}{id} = $self->{_helm3}{$self->srvid}{customers}{lc $self->setting('user_host_win')};
	$self->create_role('CTRL_UROLE','User') unless $self->search_role('CTRL_UROLE');
	$self->chooseuser;
	$self->{_undo}{customer} = $self->create_customer('CTRL_UROLE');
	$self->create_package('Default');
	$self->create_domain('Active','Default');
	$self->search_resources;
	$self->create_ftpaccount('default'); #default@domain.com
	$self->undo;
	$self->create_service;
	
	return $self->error ? 0 : 1;
}

sub rhosting {
	my ($self) = shift;
	return if $self->error;
	
	$self->login;
	$self->remove_customer;
	$self->remove_service;
	
	return $self->error ? 0 : 1;
}

sub suspend {
	my ($self) = shift;
	return if $self->error;

	$self->login;
	my $include = $_[0] ? 1 : 0;
	$self->alter_customer('Suspended',$include);
	$self->suspend_service($include);
	
	return $self->error ? 0 : 1;
}

sub unsuspend {
	my ($self) = shift;
	return if $self->error;

	$self->login;
	my $include = $_[0] ? 1 : 0;
	$self->alter_customer('Active',$include);
	$self->activate_service;
	
	return $self->error ? 0 : 1;
}

sub updowngrade {
	my ($self) = shift;
	return if $self->error;

	$self->login;
	$self->quicksearch('CUSTOMERS',1);
	my $include = $_[0] ? 1 : 0;
	$self->alter_package;
	$self->grade_service;
	
	return $self->error ? 0 : 1;
}

sub alter_package {
	my ($self) = shift;
	return if $self->error;

	$self->quicksearch('CUSTOMERS',1);
	my $pattern = $self->service('useracc');
	$self->follow_link( text_regex => qr/^$pattern$/i);
	$self->follow_link( text_regex => qr/^Packages$/i);
	$self->follow_link( text_regex => qr/^Default$/i);

	$self->form_name('frmMain');
	$self->select('_ctl3:FormCategory_PackageMigration:FormItem_Upgrade:cbxUpgrade',$self->plan('auto'));
	$self->click('_ctl3:btnButton1');
	
	my @matches;
	unless ($self->success and @matches = $self->content =~ m/The package has been successfully saved/si) {
		$self->{ERR} = $self->lang(202,'alter_package');
		$self->get_helmerror;
	}
	$self->{ERR} = $self->lang(9,'alter_package') unless $pattern;
	
	return $self->error ? 0 : 1;
}

sub undo {
	my ($self) = shift;
	return unless $self->error;
	
	my $err = $self->{'ERR'} and $self->clear_error;
	$self->remove_customer if $self->{_undo}{customer} == 1;
	$self->remove_nameserver if $self->{_undo}{nameserver} == 1;
	
	$self->set_error($self->error . $err) and $self->{_undo} = undef;
	return 1;
}

sub remove_nameserver {	
	my ($self) = shift;
	return if $self->error;

	my $url = $self->baseurl . '/Interface/Servers/Servers.aspx?AccountId='.$self->{_helm3}{$self->srvid}{id};
	$url .= '&__EVENTTARGET=_ctl3$grid$Pager&__EVENTARGUMENT=Page,-1'; #show all
	$self->get($url);
	
	$self->follow_link( text => $self->server('nome') );#requisito que 	
	$self->follow_link( text => 'Services');
	$self->follow_link( text => 'Show All');
	$self->follow_link( text_regex => qr/DNS/i);#exigencia de nome
	
	#ignore if not exist
	my $ns1 = 'ns1.' . $self->service('dominio');
	my $ns2 = 'ns2.' . $self->service('dominio');
	
	$self->{ERR} = $self->lang(9,'remove_customer') unless $self->service('dominio');
	if ($self->content =~ m/\>$ns1\</si && !$self->error) {
		$self->follow_link( text => $ns1 );
		$self->form_name('frmMain');
		$self->click('_ctl3:btnButton2');
		
		my @matches;
		if ($self->success and @matches = $self->content =~ m/>$ns1</si) {
			$self->form_name('frmMain');
			$self->click('_ctl3:btnConfirm');
			my @matches;
			unless ($self->success and @matches = $self->content =~ m/Use the following form to edit the details for a service/si) {
				$self->{ERR} = $self->lang(202,'remove_nameserver');
				$self->get_helmerror;
			}
		}
	}
	if ($self->content =~ m/\>$ns2\</si && !$self->error) {
		$self->follow_link( text => $ns2 );
		$self->form_name('frmMain');
		$self->click('_ctl3:btnButton2');
		
		my @matches;
		if ($self->success and @matches = $self->content =~ m/>$ns2</si) {
			$self->form_name('frmMain');
			$self->click('_ctl3:btnConfirm');
			my @matches;
			unless ($self->success and @matches = $self->content =~ m/Use the following form to edit the details for a service/si) {
				$self->{ERR} = $self->lang(202,'remove_nameserver');
				$self->get_helmerror;
			}
		}
	}
		
	return $self->error ? 0 : 1;	
}

sub remove_customer {
	my ($self) = shift;
	return if $self->error;

	$self->quicksearch('CUSTOMERS',1) unless $self->{_helm3}{$self->srvid}{customers}{$self->service('useracc')};
	my $url = $self->baseurl . '/Interface/default.aspx?AccountId='.$self->{_helm3}{$self->srvid}{customers}{$self->service('useracc')};
	$self->get($url);
	
	$self->form_name('frmMain');
	$self->click('_ctl3:btnButton2');

	my @matches;
	my $pattern = $self->service('useracc');
	if ($self->success and $pattern and @matches = $self->content =~ m/>$pattern</si) {
		$self->form_name('frmMain');
		$self->click('_ctl3:btnConfirm');
		my @matches;
		unless ($self->success and @matches = $self->content =~ m/The following are users that are held within this account/si) {
			$self->{ERR} = $self->lang(202,'remove_customer');
			$self->get_helmerror;
		}
	}
	$self->{ERR} = $self->lang(9,'remove_customer') unless $pattern;
	
	return $self->error ? 0 : 1;
}

sub get_helmerror {
	my ($self) = shift;
	
	my $error = $1 if $self->content =~ /<td Class="ErrorMessage">(.+?)<\/td>/si;
	Controller::html2text(\$error);
	$self->{ERR} = $error if $error;
	
	return 1;
}
1;
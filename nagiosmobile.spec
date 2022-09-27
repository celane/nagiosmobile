%define version 1.03
%define relnum 5
%define NVdir %{name}-%{version}

Name:           nagiosmobile
Version:        %{version}
Release:        %{relnum}%{?dist}
Summary:        Nagios for mobile devices

License:        GNU 2.0
URL:            https://github.com/celane/nagiosmobile
#URL:            http://www.nagios.com/products/nagios-mobile

BuildRequires:  perl
BuildRequires:  git
Requires:       php >= 8.0
Requires:       nagios
Requires:       httpd

%description
Web interface from mobile devices to Nagios

%prep
### build from git ###
rm -rf %{NVdir}
git clone %{url}.git %{NVdir}


%build

%install
cd %{NVdir}
if [ "$RPM_BUILD_ROOT" != "/" ]; then
   rm -rf $RPM_BUILD_ROOT
fi 

install -d $RPM_BUILD_ROOT%{_datadir}/nagios/nagiosmobile
cp -r class includes jquery.mobile-1.0 js \
   $RPM_BUILD_ROOT%{_datadir}/nagios/nagiosmobile/
install *.php *.png *.gif $RPM_BUILD_ROOT%{_datadir}/nagios/nagiosmobile/
rm $RPM_BUILD_ROOT%{_datadir}/nagios/nagiosmobile/INSTALL.php
install -d $RPM_BUILD_ROOT%{_sysconfdir}/httpd/conf.d/
install nagiosmobile_apache.conf $RPM_BUILD_ROOT%{_sysconfdir}/httpd/conf.d/
install -d $RPM_BUILD_ROOT%{_sysconfdir}/nagios
install update_nagiosmobile_config.pl $RPM_BUILD_ROOT%{_sysconfdir}/nagios/
install -d $RPM_BUILD_ROOT%{_defaultdocdir}/%{name}
install LICENSE README CHANGES TODO.txt $RPM_BUILD_DIR%{_defaultdocdir}/%{name}


%files
%doc README CHANGES TODO.txt
%{_datadir}/nagios/nagiosmobile/*
%{_sysconfdir}/httpd/conf.d/*
%{_sysconfdir}/nagios/update_nagiosmobile_config.pl

%post
cd %{_sysconfdir}/nagios
perl update_nagiosmobile_config.pl %{_datadir}/nagios/nagiosmobile/include.inc.php

%changelog
* Wed Aug 10 2022 lane@duphy4.physics.drexel.edu
- 

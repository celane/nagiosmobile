# build from .tar.gz version
#
%define version 1.03
%define relnum 10
%define NVdir %{name}-%{version}

Name:           nagiosmobile
Version:        %{version}
Release:        %{relnum}%{?dist}
Summary:        Nagios for mobile devices

License:        GNU 2.0

URL:            https://github.com/celane/nagiosmobile
#URL:            http://www.nagios.com/products/nagios-mobile
Source:         https://github.com/celane/nagiosmobile/archive/refs/tags/%{version}.tar.gz

BuildRequires:  perl
BuildRequires:  help2man
Requires:       php >= 8.0
Requires:       nagios
Requires:       httpd

%description
Web interface from mobile devices to Nagios

%prep
%setup 

%build
help2man ./nagiosmobile_transurl -N -o nagiosmobile_transurl.man --version-string=%{version}

%install
if [ "$RPM_BUILD_ROOT" != "/" ]; then
   rm -rf $RPM_BUILD_ROOT
fi 

install -d $RPM_BUILD_ROOT%{_datadir}/nagios/nagiosmobile
cp -r class includes jquery.mobile-1.0 js \
   $RPM_BUILD_ROOT%{_datadir}/nagios/nagiosmobile/
install *.php *.png *.gif $RPM_BUILD_ROOT%{_datadir}/nagios/nagiosmobile/
install -d $RPM_BUILD_ROOT%{_sysconfdir}/nagios
install update_nagiosmobile_config.pl $RPM_BUILD_ROOT%{_sysconfdir}/nagios/
install -d $RPM_BUILD_ROOT%{_sbindir}
install nagiosmobile_transurl $RPM_BUILD_ROOT%{_sbindir}
install -d $RPM_BUILD_ROOT%{_mandir}/man1
install nagiosmobile_transurl $RPMBUILDROOT%{_mandir}/man1
install -d $RPM_BUILD_ROOT%{_defaultdocdir}/%{name}
install LICENSE README CHANGES TODO.txt sms_notification.cfg nagiosmobile_apache.conf $RPM_BUILD_ROOT%{_defaultdocdir}/%{name}


%files
%doc LICENSE README CHANGES TODO.txt sms_notification.cfg nagiosmobile_apache.conf
%{_datadir}/nagios/nagiosmobile/*
%{_mandir}/man1/*
%attr(0755,root,-) %{_sysconfdir}/nagios/update_nagiosmobile_config.pl
%attr(0755,root,-) %{_sbindir}nagiosmobile_transurl


%post
cd %{_sysconfdir}/nagios
perl update_nagiosmobile_config.pl %{_datadir}/nagios/nagiosmobile/include.inc.php
echo "Example Apache config file for nagiosmobile is in %{_defaultdocdir}/%{name}"


%changelog
* Sat Sep 6 2025 lane@dchooz.org
- minor updates, plus add util for translating 'main' nagios urls
- to nagiosmobile urls, for notification purposes

* Wed Aug 10 2022 lane@dchooz.org
- 

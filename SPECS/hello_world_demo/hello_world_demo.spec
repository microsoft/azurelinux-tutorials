Summary:        A demonstration package that creates a "Hello-World" application
Name:           hello_world_demo
Version:        1.0.0
Release:        2%{?dist}
License:        MIT
URL:            https://dev.azure.com/mariner-org/mariner/_git/samples?path=%2Fhello_world_sample.html
Group:          Applications/Text
Vendor:         Microsoft
Distribution:   Mariner
Source0:        http://dev.azure.com/mariner-org/mariner/_git/samples/%{name}-%{version}.tar.gz

BuildRequires: gcc
# add non toolchain pkg as build requires (for testing purpose)
BuildRequires: words

%description
A simple hello-world application

%prep
%setup -q

%build
make %{?_smp_mflags}

%install
make DESTDIR=%{buildroot} install

%files
%defattr(-,root,root)
%{_bindir}

%changelog
* Mon Jun 15 2020 Pawel Winogrodzki <pawelwi@microsoft.com> 1.0.0-2
- Adding 'BuildRequires' for the sake of demonstrating external, build-time dependencies.
* Wed Oct 09 2019 Jonathan Slobodzian <joslobo@microsoft.com> 1.0.0-1
- Initial version of demo package


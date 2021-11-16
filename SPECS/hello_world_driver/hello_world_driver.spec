Summary:        A demonstration package that creates a "Hello-World" driver
Name:           hello_world_driver
Version:        1.0.0
Release:        1%{?dist}
License:        MIT
URL:            https://github.com/rlmenge/hello-world-kernel-driver
Group:          Applications/Text
Vendor:         Microsoft
Distribution:   Mariner
Source0:        %{name}-%{version}.tar.gz

%global debug_package %{nil}

BuildRequires: kernel-devel
BuildRequires: kernel-headers
BuildRequires: kmod
BuildRequires: make
Requires: kernel

%define kver 5.10.74.1-1.cm1
%define ksrc %{_libdir}/modules/%{kver}/build
%define moddestdir %{buildroot}%{_libdir}/modules/%{kver}/kernel/drivers/misc

%description
A simple hello-world application

%prep
%setup -q -n hello_world_driver

%build
make KVER=%{kver} 

%install
mkdir -p %{moddestdir}
xz -z hello-world.ko
install -p -m 644 hello-world.ko.xz %{moddestdir}
/sbin/depmod -a %{kver}

%post
/sbin/depmod -a %{kver}

%postun
/sbin/depmod -a %{kver}

%files
%defattr(-,root,root)
%{_libdir}/modules/%{kver}/kernel/drivers/misc/hello-world.ko.xz

%changelog
* Mon Nov 15 2021 Rachel Menge <rachelmenge@microsoft.com> 1.0.0-1
- Create hello_world_driver producing hello-world.ko.xz


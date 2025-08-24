# os-subrelease data:
%global _builder_name   My Builder Name
%global _id             my-product-id
%global _version_id     my-version-id
%global _name           My Product Name
%global _version        %{_version_id}
   

Summary:        Product OS Subrelease Information
Name:           os-subrelease
Version:        1.0
Release:        1%{?dist}
License:        Apache License
Group:          System Environment/Base
URL:            https://my-company-or-product-url
Vendor:         My Company Name
Distribution:   Azure Linux
BuildArch:      noarch

%description
This package creates a sample os subrelease file: /etc/os-subrelease.  Replace contents as needed for your Azure Linux based product information

%install
rm -rf $RPM_BUILD_ROOT
install -d $RPM_BUILD_ROOT/etc

cat > %{buildroot}/etc/os-subrelease << EOF
BUILDER_NAME=%{_builder_name}
BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
ID=%{_id}
VERSION_ID=%{_version_id}
NAME="%{_name}"
VERSION="%{_version}"
EOF


%clean
rm -rf $RPM_BUILD_ROOT

%files
%config(noreplace) /etc/os-subrelease

%changelog
* Thu Mar 26 2020 Jon Slobodzian <joslobo@microsoft.com> 1.0-1
- Replace this changelog entry for your specific needs

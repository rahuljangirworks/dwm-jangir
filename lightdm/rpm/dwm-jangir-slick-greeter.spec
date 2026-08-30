Name:           dwm-jangir-slick-greeter
Version:        2.2.6
Release:        1%{?dist}
Summary:        Patched Slick Greeter binary for dwm-jangir
License:        GPL-3.0-or-later
URL:            https://github.com/linuxmint/slick-greeter
Source0:        slick-greeter-2.2.6.tar.gz
Patch0:         0001-dwm-jangir-greeter-ui.patch

BuildRequires:  meson
BuildRequires:  desktop-file-utils
BuildRequires:  gettext-devel
BuildRequires:  intltool
BuildRequires:  patch
BuildRequires:  pkgconfig(liblightdm-gobject-1)
BuildRequires:  pkgconfig(gtk+-3.0)
BuildRequires:  pkgconfig(libcanberra)
BuildRequires:  pkgconfig(xapp)
BuildRequires:  vala
Requires:       slick-greeter = %{version}

%description
The dwm-jangir visual overlay for Slick Greeter 2.2.6. It installs only the
patched executable and reuses the matching Fedora slick-greeter package for
schemas, translations, and shared assets.

%prep
%setup -q -n slick-greeter-%{version}
patch --batch -l -p1 < %{PATCH0}

%build
%meson
%meson_build

%install
install -Dm755 redhat-linux-build/src/slick-greeter \
    %{buildroot}%{_libexecdir}/dwm-jangir-slick-greeter-bin

%files
%{_libexecdir}/dwm-jangir-slick-greeter-bin

%changelog
* Sun Aug 30 2026 Rahul Jangir <rahul@example.invalid> - 2.2.6-1
- Add the dwm-jangir Slick Greeter visual overlay

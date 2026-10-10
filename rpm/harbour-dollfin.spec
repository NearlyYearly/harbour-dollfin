Name: harbour-dollfin

Summary: Local-first medication tracking for trans people

Version: 0.3
Release: 1
Group: Qt/Qt
License: GPLv3+
URL: https://github.com/lillelilje/harbour-dollfin
Source0: %{name}-%{version}.tar.bz2
Requires: sailfishsilica-qt5 >= 0.10.9
BuildRequires: pkgconfig(sailfishapp) >= 1.0.2
BuildRequires: pkgconfig(Qt5Core)
BuildRequires: pkgconfig(Qt5Qml)
BuildRequires: pkgconfig(Qt5Quick)
BuildRequires: pkgconfig(Qt5Sql)
BuildRequires: desktop-file-utils

%description
Dollfin is a private, local-first medication tracker for trans people on
Sailfish OS. Track medications, schedules and stock, and get dose reminders
through your local calendar. No account, no network, no telemetry.

%prep
%autosetup -n %{name}-%{version}

%build
%qmake5
%make_build

%install
%qmake5_install

desktop-file-install --delete-original \
    --dir %{buildroot}%{_datadir}/applications \
    %{buildroot}%{_datadir}/applications/*.desktop

%files
%{_bindir}/%{name}
%{_datadir}/%{name}
%{_datadir}/applications/%{name}.desktop
%{_datadir}/icons/hicolor/*/apps/%{name}.png

%changelog
* Sat Oct 10 2026 lillelilje <lillelilje@users.noreply.github.com> - 0.3-1
- Reliable calendar sync, export and "open in Calendar" prompt
* Sat Oct 10 2026 lillelilje <lillelilje@users.noreply.github.com> - 0.2-1
- Medications and schedules, Today and history, calendar reminders
* Sat Oct 10 2026 lillelilje <lillelilje@users.noreply.github.com> - 0.1-1
- Initial project skeleton

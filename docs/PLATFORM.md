# Platform notes — Sailfish OS (researched 2026-10-10)

Facts and links behind the decisions in `DECISIONS.md`. Update when the platform changes.

## OS versions & devices

- Release trains, newest first:
  - **Finlayson 5.2.0.x** — Jolla Phone first (5.2.0.15 … 5.2.0.18). 5.2 is being rolled
    out to other supported devices "a bit later".
  - **Pispala 5.1.0.11** — broad release (2026-06-16).
  - Tampella 5.0.0.x — previous train, wide device support.
- **Jolla Phone 2026** is the current reference/community device and runs 5.2.
- Architecture: older Xperia XA2 / Xperia 10 are `armv7hl`; 10 II+, Jolla C2 and the Jolla
  Phone 2026 are `aarch64`. "No legacy support" ⇒ target **aarch64 only**.
- Source: forum release notes
  [5.2.0.18](https://forum.sailfishos.org/t/34279),
  [5.1.0.11](https://forum.sailfishos.org/t/29751).

## App framework

- Apps are **Qt 5.6 + QML + Sailfish Silica**. Silica is still on Qt 5.6 (upstream-unsupported
  since 2023) but is the only stable native toolkit.
- Native components: `Sailfish.Silica`, `libsailfishapp`, `SailfishApp` booster.
- **Keel** (beta, 2026) is a Qt 6 reimplementation of the Silica API, so Silica-style apps
  run on Qt 6. **MIT-licensed**, source at
  [github.com/patrickjquinn/shipwright-open](https://github.com/patrickjquinn/shipwright-open)
  (`keel/`, with RPM specs). Distributed through the **Reef** store
  ([reefstore.app](https://reefstore.app)), which is beta and tested only on Jolla Phone
  2026 / 5.2.0.18. Reef only serves builds for the exact OS release on the phone.
- **Keel grades** (A = everything the app uses from Silica runs on Keel) let a normal
  Silica app be ported later. Keel's own porting guide is in `shipwright-open/docs/developers/`.
- **Consequence:** "Qt 6 today" effectively means "Reef today", not Storeman. See D-002.
- Harbours discourages new language runtimes; C++ + QML is the recommended combination.
- Sources: [docs/Develop/Apps](https://docs.sailfishos.org/Develop/Apps/),
  [Reef/Keel thread](https://forum.sailfishos.org/t/34763).

## Tooling

- **Sailfish SDK**: Qt Creator-derived IDE + `sfdk` CLI + build-engine VM + emulator.
  Runs on Linux/macOS/Windows. Installs via official installer.
- `sfdk build` produces the RPM; `sfdk build --sign` GPG-signs it; `sfdk deploy` pushes to
  device/emulator.
- Build targets are `SailfishOS-<version>-<arch>`. Confirm what your SDK currently offers
  with `sfdk target list`; SDK targets can lag the newest OS release. As of SDK 3.13.5
  (latest), the bundled targets are Sailfish OS **5.1.0.11**; newer OS versions arrive as
  **Early Access** targets via the SDKMaintenanceTool.
- Step-by-step setup for this machine (Bazzite, no Docker/VirtualBox) is in
  [`BUILD.md`](BUILD.md).
- Sources: [docs/Tools](https://docs.sailfishos.org/Tools/),
  [docs/Apps/Packaging](https://docs.sailfishos.org/Develop/Apps/Packaging/).

## Sandboxing (Sailjail)

- Every app runs sandboxed. Permissions are declared in the desktop file:

  ```ini
  [X-Sailjail]
  Permissions=Documents
  OrganizationName=org.dollfin
  ApplicationName=Dollfin
  ```

- Harbour-allowed permissions include: `Audio`, `Bluetooth`, `Camera`, `Internet`,
  `Location`, `MediaIndexing`, `Microphone`, `NFC`, `RemovableMedia`, `UserDirs`, `WebView`,
  `Documents`, `Downloads`, `Music`, `Pictures`, `PublicDir`, `Videos`, `Compatibility`,
  `Secrets`, `Contacts`, `Accounts`.
- dollfin needs **no `Internet`**. File backup/restore probably needs `Documents` (or
  `Downloads`/`PublicDir`) — decide during P6.
- Sandbox is disabled when run from IDE/terminal; test with `sailjail /usr/bin/harbour-dollfin`.
- Sources: [Application Permissions](https://docs.sailfishos.org/Develop/Apps/Application_Permissions/),
  [Allowed Permissions](https://docs.sailfishos.org/Develop/Apps/Harbour/Allowed_Permissions/),
  [sailjail-permissions](https://github.com/sailfishos/sailjail-permissions).

## Storage & data APIs

Allowed and relevant to us:

- `libQt5Core/Quick/Qml/Gui` — base
- `libQt5Sql.so.5` + `libsqlite3.so.0` — SQLite storage
- `QtQuick.LocalStorage 2.0` — QML-side SQLite (alternative to C++ QtSql)
- `Nemo.Notifications 1.0` (`nemo-qml-plugin-notifications-qt5`) — persistent user notifications
- `Nemo.Configuration 1.0`, `Nemo.DBus 2.0`
- `Sailfish.Secrets` — secure storage (for a future app lock / PIN)
- Calendar read/write via nemo-qml-plugin-calendar (needs the `Calendar` permission) — see
  the reminders section.
- Asset: [Allowed APIs](https://docs.sailfishos.org/Develop/Apps/Harbour/Allowed_APIs/).

## Reminders & alarms (highest-risk area)

- `timed` is the OS time daemon. It supports **hardware-RTC alarms** that wake the device;
  clock alarms and calendar reminders are implemented as `timed` events. `ngfd` provides
  non-graphical feedback (vibration, sound, LEDs).
- App notifications while running go through `Nemo.Notifications`; they can carry a
  `timestamp`/`countdown` and persist, but a **suspended app cannot reschedule them**. This is
  why reminders are the hard part.

Options evaluated (see D-006):

1. **Calendar integration (preferred).** Sailfish's calendar stack is KCalendarCore/mKCal,
   with QML bindings in
   [nemo-qml-plugin-calendar](https://github.com/sailfishos/nemo-qml-plugin-calendar) that
   can read/write events, plus import/export tools. The app can create a dedicated **local**
   calendar of repeating dose events, and `timed` delivers the alarms reliably because it is
   the OS calendar doing it.
   - Needs the **`Calendar`** sailjail permission ("Display and editing of calendar events"),
     which exists but is **not** on the Harbour-allowed list (fine for Storeman).
   - **Privacy caveat:** if the target calendar is a synced CalDAV/Google account, HRT
     medication events would upload to a server. Only ever write to a **local** notebook and
     warn if that is not possible.
2. **`.ics` / iCalendar export.** Generate a standard `.ics` file; the user imports it into
   a calendar of their choice. No automatic sync, no `Calendar` permission for the app, but
   one-way and manual (re-export when the schedule changes). Forum history shows the import
   UX on older releases was buggy; re-test on 5.2.
3. **Separate background-service package.** A companion RPM (systemd user service / `timed`
   client) installed alongside the app. Most powerful and fully app-controlled, but adds a
   second package to build, sign, publish and keep in sync — and is unverified for sandboxed
   third-party use. Treat as backlog unless 1 and 2 fail.

Real in-app notifications (`Nemo.Notifications`) still exist for while the app is open and
for one-off "log now" taps.

Sources: [Alarms reference](https://docs.sailfishos.org/Reference/Core_Areas_and_APIs/Apps_and_MW/Alarms/),
[Calendar reference](https://docs.sailfishos.org/Reference/Core_Areas_and_APIs/Apps_and_MW/Calendar/),
[timed](https://github.com/sailfishos/timed), [ngfd](https://github.com/sailfishos/ngfd).

## Packaging & distribution channels

- RPM built by `sfdk` from a `.spec` (SDK ≥ 3.10) or legacy `.yaml`. Package name
  `harbour-dollfin`.
- Signed with GPG (`sfdk config package.signing.*`, then `sfdk build --sign`).
- Channels:
  | Channel | Model | Validator | Reach |
  |---------|-------|-----------|-------|
  | **OpenRepos + Storeman** | developer uploads RPM | no | community, all devices | 
  | **SailfishOS:Chum** | OBS builds from source | some | reproducible, all devices |
  | **Harbour / Jolla Store** | curated submission | yes (allowed APIs/permissions) | all Jolla devices |
  | **Reef** (beta 2026) | store for Keel/Qt6 apps | signature checks | Jolla Phone 2026 |
- Primary target is OpenRepos/Storeman. Chum is the natural next step (OBS, reproducible).
  Harbour only if the validator passes.
- Sources: [Harbour](https://docs.sailfishos.org/Develop/Apps/Harbour/),
  [Signing](https://docs.sailfishos.org/Develop/Apps/Packaging/Signing_Packages/),
  [Chum](https://github.com/sailfishos-chum/main), [OpenRepos](https://openrepos.net/).

## UI guidelines

- Use Silica components and `Theme.*` for every color, margin, font and duration.
- Respect platform gestures: edge swipes, pulley menus, cover actions on the home screen.
- Definition of Done also expects: no dummy/unfinished states, recovery actions for errors,
  translation hooks, unit tests, reasonable memory, smooth animation, scales with data.
- Test on real hardware.
- Source: [UI Definition of Done](https://docs.sailfishos.org/Develop/Apps/UI/Definition_of_Done/).

## Deprecations to avoid (since 5.1)

- Libraries: `libssl.so.1.1`, `libcrypto.so.1.1` deprecated; `libpng15`, `libssl.so.10`,
  `libcrypto.so.10` dropped.
- QML imports renamed: `org.nemomobile.notifications 1.0` → `Nemo.Notifications 1.0`,
  `org.nemomobile.dbus 2.0` → `Nemo.DBus 2.0`,
  `org.nemomobile.configuration 1.0` → `Nemo.Configuration 1.0`.
- Use the renamed imports in new code.

## Reference app

- [mona (Android/iOS)](https://github.com/mona-hrt/mona) — fully local, open source HRT
  tracker. Feature set to learn from: regimens, per-dose detail (quantity, side, missed),
  notifications, stock auto-decrement, estradiol monotherapy level simulation.

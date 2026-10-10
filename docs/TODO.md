# TODO — dollfin

Ordered task list. Check items off as they land. Keep one "Now" section at the top.
New tasks go in the phase they belong to.

## Now

- [x] Reminder spike — done, `spikes/reminders/` (D-019)
- [x] P2 — data layer (schema, models, schedule engine, tests)
- [ ] P3 — core UI (medications/regimens, Today, history, cover)
- [ ] Fold the confirmed reminder design into P4 (see below)

## P0 — Research & decisions

- [x] Platform research (`docs/PLATFORM.md`)
- [x] Plan, todo and decision log
- [x] aarch64 only, Jolla Phone 2026 + emulator (D-001)
- [x] Storeman only for v1 (D-007)
- [x] GPL-3.0-or-later (D-008)
- [x] Languages `en`, `nl`, `nb` (D-014)
- [x] Application-site tracking and all-analyte graphs deferred (D-015)
- [x] Qt 5.6/Silica on Storeman, Keel-grade code (D-002)
- [x] Local-calendar reminders + `.ics` fallback (D-006)
- [x] Free-text custom medications, no built-in catalog (D-017)

## P1 — Skeleton

- [x] `git init` + initial commit
- [x] Scaffold from the official `sfdk init` template
- [x] Rename to `harbour-dollfin` (project, desktop, icon, RPM spec)
- [x] Desktop file: `Name=Dollfin`, `OrganizationName=org.dollfin`, `ApplicationName=Dollfin`,
      no permissions declared yet
- [x] `.gitignore` for build artefacts (`RPMS/`, `*.o`, `Makefile`, …)
- [x] `lupdate`/`lrelease` wiring + `en`/`nl`/`nb` translation scaffolds (D-014)
- [x] `LICENSE` (GPL-3.0-or-later)
- [x] Build the RPM in the Platform SDK container (`scripts/build-rpm.sh`, 0 rpmlint errors)
- [x] Reconcile the scaffold with the official `sfdk init` template (files copied from the SDK source)
- [x] Deploy to the Jolla Phone 2026; app launches from the app grid (`scripts/deploy-device.sh`)
- [x] Cover renders
- [x] Note the Keel porting guide so new code stays Keel-grade (D-002)
- [ ] (optional) Install the full Sailfish SDK for the emulator / `sfdk deploy` (`docs/BUILD.md`)

## P2 — Data layer

- [x] Create the SQLite schema (medication, regimen, intake, stock, level, schema_version)
- [x] Medication name is **free text** with optional form/strength/unit fields (D-017)
- [x] Implement connection + `schema_version` migration runner
- [x] Medication model (CRUD)
- [x] Regimen model with schedule expansion (times + interval)
- [x] Intake model (log / edit / delete), generic `site` column for later
- [x] Schedule engine: given a date range, produce scheduled doses
- [x] Unit tests for schema, migration and schedule expansion (`scripts/run-tests.sh`)
- [x] Unit tests for edge cases: DST, month/year boundaries, paused regimens

## P3 — Core UI

- [x] Medications list page + empty state
- [x] Add/edit medication page (free-text name; optional quick-pick deferred, D-017)
- [x] Add/edit regimen page (dose, route, times, interval, weekly days, dates)
- [x] Today page: today's doses with taken/skipped actions
- [x] History page: list of logged intakes with delete
- [x] Cover: today's doses with a status symbol (tapping the cover opens the app; no cover action)
- [ ] Next-dose countdown on Today
- [ ] Calendar/month view of intakes
- [ ] Fuller error states (DB open failure and save failures surfaced in the UI)
- [x] All user-facing strings wrapped in `qsTr()`

## P4 — Reminders

Spike done (`spikes/reminders/FINDINGS.md`, D-019/D-020/D-021). Mechanism: the app generates
**iCalendar** and hands it to the Calendar UI via `com.jolla.calendar.ui.importIcsData`;
`.ics` file export is the fallback. Reminders are opt-in (D-020).

- [x] iCalendar builder: VEVENT + VALARM, `RRULE` for daily / every N days / weekly, stable
      `UID` per regimen, 1-minute duration, alarm at event start (D-021)
- [x] Consent screen + persisted setting, warning that the chosen calendar may sync (D-020)
- [x] Settings page: reminders on/off, "update calendar reminders", `.ics` export
- [x] Reminder sync calling `com.jolla.calendar.ui.importIcsData` (via `QDBusInterface`)
- [x] `.ics` file export to `~/Downloads/dollfin-reminders.ics`
- [x] Unit tests for the iCalendar builder (`tests/tst_core`)
- [ ] Manual test: alarm fires with the app closed, and after a reboot
- [ ] Document that turning reminders off does not remove events already in the calendar
      (we cannot delete them; the user removes them in the Calendar app)
- [x] Probe removed from `main` (kept on `spike/reminders`); `Calendar` + `Downloads`
      permissions added back

## P5 — Stock

- [x] Stock editor per medication (quantity, unit, low threshold, expiry, **source**)
- [x] Migration to schema v2 (adds `stock.source`)
- [x] Auto-decrement on a taken dose; restore on undo/delete
- [x] Low-stock flag (`quantity <= lowThreshold`) shown in the medications list
- [x] Unit tests for stock + backup (89 checks)
- [ ] Optional low-stock *notification* (currently in-app only)

## P6 — Backup, file access & i18n

- [x] JSON export of all data (generic table dump, future-proof)
- [x] JSON import (replace-all, in a transaction, validated)
- [x] File access via the `Downloads` sailjail permission (D-013)
- [x] Export/import round-trip test
- [ ] Translate the UI to Dutch (`nl`) and Norwegian Bokmål (`nb`)

## P7 — Polish

- [ ] Run through the UI Definition of Done checklist
- [ ] Device test matrix (emulator × Jolla Phone 2026 / 5.2): reminders, DST, reboot, low storage
- [ ] Performance: page load, smooth animations, memory (test with `smem`)
- [ ] Accessibility: contrast, tap targets, screen-reader labels
- [ ] Wording review for neutrality and safety
- [ ] Remove or gate the development message log (`dollfin.log`) before release — it writes
      Qt/QML messages to disk and isn't appropriate for a privacy app in production
- [ ] Icon and store screenshots

## P8 — Publish (Storeman)

- [ ] Finalise `.spec`, `.changes` and version
- [ ] Generate/import a GPG key, configure `sfdk`, `sfdk build --sign`
- [ ] Verify package with `rpm -K`
- [ ] Install on a clean Jolla Phone 2026 via RPM and verify
- [ ] Create the OpenRepos project and upload the RPM
- [ ] Add screenshots and a description
- [ ] Install through Storeman and confirm the listing
- [ ] Tag the release in git

## P9 — Distribution+ (post-v1)

- [ ] Evaluate a Qt 6 / Keel build via Reef (D-002)
- [ ] Submit source to OBS for SailfishOS:Chum
- [ ] Run the Harbour RPM validator; fix what fails
- [ ] Decide whether to submit to the Jolla Store

## Backlog (post-v1)

- [ ] Hormone graphs for **all** tracked analytes
- [ ] Application-site tracking (gel / patch / injection)
- [ ] Adherence statistics
- [ ] App lock (PIN via `Sailfish.Secrets`)
- [ ] More languages
- [ ] Import from a mona export
- [ ] Cover quick-actions
- [ ] Optional companion background-service package if calendar reminders prove insufficient

# TODO — dollfin

Ordered task list. Check items off as they land. Keep one "Now" section at the top.
New tasks go in the phase they belong to.

## Now

- [ ] `git init` and first commit of the planning docs
- [ ] Install the Sailfish SDK
- [ ] Start P1

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
- [ ] Install the full Sailfish SDK for the emulator / `sfdk deploy` (optional, `docs/BUILD.md`)
- [ ] Deploy to the Jolla Phone 2026 and verify it launches from the app grid
      (`scripts/deploy-device.sh`; enable Developer mode + Remote connection first)
- [ ] Verify the cover renders
- [ ] Note the Keel porting guide so new code stays Keel-grade (D-002)

## P2 — Data layer

- [ ] Create the SQLite schema (medication, regimen, intake, stock, level, schema_version)
- [ ] Implement connection + `schema_version` migration runner
- [ ] Medication model (CRUD)
- [ ] Regimen model with schedule expansion (times + interval)
- [ ] Intake model (log / edit / delete), generic `site` column for later
- [ ] Schedule engine: given a date range, produce scheduled doses
- [ ] Unit tests for schema, migration and schedule expansion
- [ ] Unit tests for edge cases: DST, month/year boundaries, paused regimens

## P3 — Core UI

- [ ] Medications list page + empty state
- [ ] Add/edit medication page
- [ ] Add/edit regimen page (dose, route, times, interval, dates)
- [ ] Today page: due/upcoming doses, taken/skipped actions, next-dose countdown
- [ ] History page: list of intakes with edit
- [ ] Calendar/month view of intakes
- [ ] Cover page: next dose summary + quick action
- [ ] Error and empty states for every page
- [ ] All strings wrapped in `qsTr()`

## P4 — Reminders (highest risk)

- [ ] **Spike:** write a repeating event into a **local** calendar via
      `nemo-qml-plugin-calendar` with the `Calendar` permission; confirm the alarm fires when
      the app is closed, after reboot, and across a DST change
- [ ] **Spike:** generate an `.ics` file and import it into Sailfish Calendar on 5.2; note how
      well repeats/updates work
- [ ] Record the exact file permission chosen for `.ics` export/backup as an update to D-013
- [ ] Implement `ReminderService` + `ReminderBackend`
- [ ] Create/maintain a dedicated **local** calendar; refuse or warn on synced calendars
- [ ] Update calendar events when a regimen or intake changes
- [ ] `.ics` export as an always-available fallback
- [ ] “Taken” / “Snooze” actions where the platform allows
- [ ] Reschedule on boot / timezone change / OS upgrade
- [ ] Unit tests for event generation; manual test for closed-app delivery
- [ ] Document any OS limitation to the user in-app

## P5 — Stock

- [ ] Stock table UI (quantity, unit, low threshold, expiry)
- [ ] Auto-decrement on intake; correct on edit/delete
- [ ] Low-stock warning (in-app + optional notification)
- [ ] Unit tests for stock arithmetic

## P6 — Backup, file access & i18n

- [ ] JSON export of all data to a user-chosen file
- [ ] JSON import with validation and merge/replace choice
- [ ] Add the minimal sailjail permission for file access (D-013)
- [ ] Test export/import round-trip
- [ ] Translate the UI to Dutch (`nl`) and Norwegian Bokmål (`nb`)

## P7 — Polish

- [ ] Run through the UI Definition of Done checklist
- [ ] Device test matrix (emulator × Jolla Phone 2026 / 5.2): reminders, DST, reboot, low storage
- [ ] Performance: page load, smooth animations, memory (test with `smem`)
- [ ] Accessibility: contrast, tap targets, screen-reader labels
- [ ] Wording review for neutrality and safety
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

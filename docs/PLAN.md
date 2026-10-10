# Plan — dollfin

See `PLATFORM.md` for the platform facts this plan is based on.

## One-liner

A native Sailfish OS app to track HRT medication: what to take, when, whether you took it,
what's left, and how your levels trend — entirely on-device.

## Users & jobs

Trans people on HRT (estradiol, testosterone, anti-androgens, progesterone, …) across all
routes (oral, sublingual, gel, patch, injection). They need to:

- never miss or miscount a dose,
- see today's schedule at a glance,
- know how much supply is left so they don't run out,
- keep a history they can show a clinician,
- keep all of it private.

## Scope

### v0.1 — reliable core (MVP)

- Medications and **regimens**: medication (**free-text name**, no built-in catalog — D-017),
  dose, route, times of day, day interval, start/end date, active flag.
- **Today** screen: due/upcoming doses, one-tap *taken* / *skipped*, countdown to next dose.
- **Reminders**: reliable dose alarms via the OS calendar/`timed` — the app writes repeating
  events into a dedicated **local** calendar (or exports `.ics`) rather than relying on a
  suspended app timer. See D-006.
- **History**: list + calendar view of intakes, editable.
- **Stock**: quantity per medication, auto-decrement on intake, low-stock warning.
- **Backup**: export/import all data as a JSON file; manual, never networked.
- **Languages**: English, Dutch and Norwegian.
- **Cover**: today's doses with per-dose status (emoji); tapping the cover opens the app.
- No `Internet` permission. No account.

### v1.2 — Labs (blood results)

- **Labs**: record blood results with a draw date, value, unit, lab and notes. Hormones first
  (estradiol, testosterone, prolactin, LH/FSH, SHBG ·), plus liver, kidney, blood count,
  lipids and the like; any other analyte via **Custom** (D-024).
- **Generic reference ranges** from Dutch standards, shown neutrally, HRT hormones descriptive
  only (D-025).
- List + add/edit/delete. Graphs are the next v1.x step (D-026).

### v0.2+ (backlog, not now)

- **Hormone graphs for all tracked analytes** (estradiol, testosterone, and anything else the
  user records), clearly labelled illustrative only — the next v1.x step (D-026).
- **Application-site tracking** for gel, patch and injection (rotation, last-used site).
- Adherence statistics.
- App lock (PIN via `Sailfish.Secrets`).
- More languages.
- Import from a mona export.
- Cover actions (e.g. log dose from the home screen).

### Non-goals

Cloud sync, accounts, social features, ads, telemetry, dosing or medical advice,
diagnosis, pregnancy tracking.

### How dollfin differs from mona

- **Custom medications (D-017/D-022).** A list of common HRT medications plus a Custom option
  for anything else; mona only allows its predefined list.
- Reminders ride on the OS **local calendar / `timed`** rather than a background service.
- Fully offline by design: no `Internet` permission at all.

## Architecture

```
QML UI (Sailfish Silica)
        │  bindings / signals
C++ models & controllers  (MedicationModel, ScheduleEngine, ReminderService, StockService)
        │
SQLite (QtSql / QSQLITE)
```

- Business logic lives in C++ so it can be unit-tested; QML stays thin.
- `ReminderService` writes schedule changes out through a `ReminderBackend` interface
  (calendar integration and/or `.ics` export, per D-006).
- Database file: `~/.local/share/harbour-dollfin/dollfin.db` inside the sandbox.

## Data model (v1)

| Table | Key fields |
|-------|-----------|
| `medication` | id, name (free text), form, strength, unit, notes, active |
| `regimen` | id, medication_id, dose, route, times(json), interval_days, start, end, active |
| `intake` | id, regimen_id, scheduled_at, taken_at, status(taken/skipped/missed), amount, site, notes |
| `stock` | medication_id, quantity, unit, low_threshold, last_refill, expires |
| `level` | id, taken_at, analyte, value, unit, lab, notes |
| `schema_version` | version, applied_at |

Rules: UTC timestamps stored, local time rendered; `intake.site` and the `level` table stay
route/analyte-agnostic so application-site tracking and all-analyte graphs can be added later
without a breaking migration. Every schema change gets a migration and a `DECISIONS.md` entry.

`level` is used as-is for Labs (v1.2, D-024): `analyte` stores a catalogue **key** for a known
analyte or the user's text for a Custom one, `taken_at` is the draw date, `unit` is the fixed
dropdown value. Because no UI wrote to `level` before v1.2 there is no data to migrate; the
generic backup dump already covers it.

## Phases & milestones

| Phase | Outcome |
|-------|---------|
| **P0 Research & decisions** | Platform notes, plan, decision log. *(in progress)* |
| **P1 Skeleton** | SDK installed, project template builds, deploys and runs on a real device. |
| **P2 Data layer** | Schema + migrations + C++ models, with unit tests. |
| **P3 Core UI** | Medication/regimen editing, Today screen, History. |
| **P4 Reminders** | Spike (**calendar write vs `.ics`**), then implement the chosen path. **Highest risk.** |
| **P5 Stock** | Quantity tracking, decrement, low-stock warning. |
| **P6 Backup & i18n** | JSON export/import, `en`/`nl`/`nb` translations. |
| **P7 Polish** | Device test matrix, covers, empty/error states, accessibility, performance. |
| **P8 Publish** | Signed RPM, changelog, OpenRepos project page, Storeman instructions. |
| **P9 Distribution+** | OBS/Chum build; evaluate Harbour submission. |
| **P10 Labs (v1.2)** | Labs list + add/edit/delete, analyte catalogue, generic reference ranges. |

A phase is done only when its tasks in `TODO.md` are checked and the change meets the
definition of done in `AGENTS.md`.

## Risks

| ID | Risk | Mitigation |
|----|------|-----------|
| R1 | Reminders don't fire while the app is closed | Use the OS calendar/`timed` via calendar integration or `.ics` (D-006); validate in the P4 spike; if unavailable, document the limit |
| R2 | SDK has no 5.2 target yet | Build against the newest available 5.1 target; test the RPM on Jolla Phone 2026 / 5.2 |
| R3 | Qt 5.6 limits QML features | Accept; check imports against the allowed list; code Keel-grade for a later Qt 6 port |
| R4 | Sensitive health data / domain harm | Strict local-only, minimal data collected, neutral wording, safety review before release |
| R5 | Storeman discoverability & maintenance | Clear OpenRepos listing, screenshots, changelog, versioned releases |
| R6 | Level graph seen as medical guidance | Graphs cover all analytes, simulation/labels only, opt-in, disclaimers; never a dosing recommendation |
| R7 | Calendar reminders leak to a synced account | Only write to a local calendar; warn otherwise; keep `.ics` export |
| R8 | Lab reference ranges read as medical guidance | Generic ranges only, `M/F` shown neutrally, descriptive (not targeted) for HRT hormones, no alarm colour, clinical review before release (D-025) |

## Release & publishing (Storeman)

1. Version `MAJOR.MINOR.PATCH`, RPM release `-1`; update `rpm/*.changes`.
2. `sfdk build --sign` → `harbour-dollfin-<ver>-1.aarch64.rpm`.
3. Publish on OpenRepos; install/verify through Storeman on a clean Jolla Phone 2026.
4. Changelog in the OpenRepos package and in the repo.
5. Later (not v1): Reef/Keel (Qt 6), SailfishOS:Chum (OBS), Harbour if the validator passes.

## Quality bar

- Unit tests for DB, schedule expansion and reminder logic.
- Manual test matrix: each supported OS version × device, plus emulator.
- No data loss across app updates; export always available.
- Reminder path tested including timezone/DST changes and device reboot.

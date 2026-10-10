# Decision log — dollfin

A running record of decisions and *why* they were made, so future contributors (and future
us) don't relitigate settled questions. **Append-only:** once a decision is `Accepted`, never
edit it; add a new one that supersedes it. (Draft `Proposed`/`Open` entries may be finalised
in place.)

## How to use this log

1. Copy the template below to the end of the list.
2. Give it the next `D-0NN` id and today's date.
3. Set a status:
   - `Open` — raised, not decided
   - `Proposed` — recommendation on the table, awaiting confirmation
   - `Accepted` — current decision
   - `Rejected` — considered and declined
   - `Superseded by D-0NN` — replaced
4. Keep it to a few lines: Context / Decision / Consequences.
5. If a decision touches the schema, code or scope, also update `PLAN.md` / `TODO.md`.

Template:

```md
### D-0NN — Title
- **Date:** YYYY-MM-DD
- **Status:** Proposed
- **Context:** why this came up
- **Decision:** what we chose
- **Consequences:** what follows, including the downside
```

---

## Decisions

### D-001 — Platform target
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Sailfish OS 5.2 is only on the Jolla Phone 2026; 5.1 is broad. Older Xperia
  devices are `armv7hl`.
- **Decision:** Target Sailfish OS 5.x, **aarch64 only**. Test on a **Jolla Phone 2026** and
  in the **emulator**. No `armv7hl` build and no legacy device support.
- **Consequences:** Smaller build and test matrix; unsupported on old Xperia XA2/10.

### D-002 — UI toolkit / Qt version
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Sailfish OS still runs Silica on **Qt 5.6**. **Keel** is a new Qt 6
  reimplementation of Silica, but it is beta, tested only on Jolla Phone 2026 / 5.2.0.18, and
  its apps are distributed through the **Reef** store. Storeman/OpenRepos does not deliver the
  Keel runtime. So "Qt 6 today" effectively means "Reef today".
- **Decision:** Build v1 on **Qt 5.6 + Sailfish Silica** and publish on **Storeman**, which
  gives the best visibility now. Write the code **Keel-grade** (only Silica features Keel
  supports) so a Qt 6 / Keel build can be added later for Reef without a rewrite.
- **Consequences:** We live with Qt 5.6's older feature set for v1. A Qt 6 / Keel / Reef
  release is a post-v1 task (P9), not a rewrite.

### D-003 — Implementation language
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** QML-only is quick but hard to test; Python is discouraged for new Harbour apps.
- **Decision:** **C++ backend + QML UI.** Business logic in C++, testable with QtTest.
- **Consequences:** Slightly more setup; unit-testable data and reminder logic.

### D-004 — Storage
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Options: QML `QtQuick.LocalStorage`, QtSql/QSQLITE, or raw `libsqlite3`.
- **Decision:** **SQLite via QtSql (QSQLITE)** in C++, file in the sandboxed app dir
  (`~/.local/share/harbour-dollfin/dollfin.db`).
- **Consequences:** Straightforward migrations and tests; both `libQt5Sql` and `libsqlite3`
  are Harbour-allowed.

### D-005 — Local-first, no network
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** The data is highly sensitive.
- **Decision:** The app never connects to a network and never declares the `Internet`
  sailjail permission. No accounts, telemetry or crash reporting.
- **Consequences:** No cloud sync or remote backup. This is a feature, not a limitation.

### D-006 — Reminder delivery mechanism
- **Date:** 2026-10-10 · **Status:** Accepted (reliability verified in P4)
- **Context:** Normal apps are suspended in the background, so an in-app timer cannot fire a
  dose reminder while the app is closed. Options researched in `PLATFORM.md`:
  1. **Calendar integration** — write repeating dose events into a dedicated **local**
     calendar via `nemo-qml-plugin-calendar`; the OS calendar/`timed` delivers the alarms.
  2. **`.ics` export** — the user imports a generated calendar file; no automatic sync.
  3. **Separate background-service package** — a companion RPM using `timed`.
- **Decision:** Primary = **1**, writing to a dedicated **local** calendar. Always offer
  **2** as a fallback and for users who don't want the app touching their calendar. Keep
  **3** as backlog unless both fail.
- **Consequences / hard rule:** Calendar events could sync to a CalDAV/Google account and
  leak HRT medication data. Only write to a **local** calendar; warn the user if that is not
  possible. The P4 spike confirms closed-app delivery, reboot and DST handling.

### D-007 — Distribution channels
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** OpenRepos/Storeman, SailfishOS:Chum, Harbour, Reef.
- **Decision:** **OpenRepos / Storeman only for v1.** Chum, Harbour and Reef are future
  options, not v1 work.
- **Consequences:** No Harbour API validator gate, but keep the code inside the allowed APIs
  where practical so Harbour stays possible.

### D-008 — License
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** mona is open source; we want the same transparency.
- **Decision:** **GPL-3.0-or-later.**
- **Consequences:** Copyleft. Add a `LICENSE` file before the first public release.

### D-009 — v1 scope
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Scope creep is the main risk to shipping.
- **Decision:** v1 = medications, regimens, Today, reminders (per D-006), history, stock, JSON
  backup, and English/Dutch/Norwegian. Everything else is backlog (see `PLAN.md`).
- **Consequences:** See D-015 for what is explicitly deferred.

### D-010 — Naming and identifiers
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Need a stable binary, package, sandbox identity and author name.
- **Decision:** Display name **Dollfin**; project/repo **dollfin**; binary/package
  **`harbour-dollfin`**; `OrganizationName=org.dollfin`, `ApplicationName=Dollfin`; author
  **lillelilje** (GitHub `lillelilje`).
- **Consequences:** Changing the binary/app name later breaks sailjail data paths and updates.

### D-011 — Backup format
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Users must be able to move or restore their data.
- **Decision:** Plain-text **JSON** export/import of all tables, versioned.
- **Consequences:** Human-readable and future-proof; import must validate and handle version
  mismatches.

### D-012 — No medical advice
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Health apps can cause harm by implying dosing guidance.
- **Decision:** The app records what the user configures. It never recommends doses,
  schedules or medication changes, and presents level simulations as illustrative only.
- **Consequences:** Any feature that computes or visualises levels must carry a clear
  disclaimer and stay opt-in.

### D-013 — Calendar / file access permission
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** The chosen reminder path (D-006) uses calendar integration plus `.ics`
  export, and backup (D-011) needs file access.
- **Decision:** Declare the **`Calendar`** permission for local-calendar reminders, plus the
  **narrowest file permission** (`Documents` or `Downloads`) for `.ics` export and JSON
  backup/import. Never `Internet`.
- **Consequences:** Two extra permissions in the desktop file, both outside the
  Harbour-allowed list — fine for Storeman. Exact file permission finalised in P6.

### D-014 — Languages
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Want multi-language support from the start.
- **Decision:** Ship **English (`en`), Dutch (`nl`) and Norwegian Bokmål (`nb`)** in v1. All
  strings go through `qsTr()` and the `lupdate`/`lrelease` workflow from P1 so adding a
  language is cheap. Nynorsk is not planned.
- **Consequences:** Slightly slower UI work; no hardcoded user-facing strings.

### D-015 — Deferred features (backlog, not v1)
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Keep v1 shippable; separate "nice to have" from "must have".
- **Decision:** Defer to backlog:
  - **Application-site tracking** for **gel, patch and injection** (replaces the old
    "injection-site" idea — it should cover every route that has a site).
  - **Hormone graphs for all tracked analytes**, not just estradiol (e.g. testosterone,
    E2, prolactin, as entered), with clear "illustrative, not medical advice" handling.
  - App lock, adherence stats, more languages, mona import, cover quick-actions.
- **Consequences:** Not designed into the v1 schema unless cheap; keep `intake.site` and the
  `level` table generic enough to support them later without a breaking migration.

---

### D-016 — Build environment
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** This host is immutable Bazzite with no Docker/VirtualBox and password-gated
  sudo, so installing the full Sailfish SDK (or Platform SDK chroot) is awkward. Meanwhile the
  community Platform SDK **container** image provides a **5.2.0.15 aarch64** target that the
  official SDK lacks.
- **Decision:** Build RPMs with `scripts/build-rpm.sh` using the
  `coderus/sailfishos-platform-sdk` podman image. The full SDK is optional and only needed for
  the emulator or `sfdk deploy`.
- **Consequences:** No emulator; test installs are pushed to the phone by `scp` + `pkcon`.
  We depend on a third-party image (pin the tag) and on rootless podman working
  (needs `ignore_chown_errors = true` for the image's UID 100000). ~6 GB of disk for the image.

---

### D-017 — Custom medications (free text, no built-in catalog)
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** HRT regimens vary widely and include compounded or uncommon preparations. The
  reference app (mona) only allows a predefined list, which locks people out. Every user must
  be able to track exactly what they take.
- **Decision:** Medication entry is **free text**. v1 ships **no bundled medication catalog**.
  A medication is a name plus optional form, strength, unit and notes. A small optional
  quick-pick of common names may be added later as a convenience, but custom entry is always
  available and never hidden.
- **Consequences:** One of our differences from mona. Nothing to maintain, translate or go
  stale, and no implied dosing advice. If a quick-pick is added it must not gate or replace
  free-text entry.

---

### D-018 — Reminder mechanism, refined after device recon
- **Date:** 2026-10-10 · **Status:** Accepted
- **Context:** Recon on 5.2.0.18 (`spikes/reminders/FINDINGS.md`) found that `Base.permission`
  already lets every sandboxed app talk to `timed` (`com.nokia.time`), and the `Nemo.Alarms`
  QML plugin can create alarms with no permission. But those alarms are weekday-only
  (no "every N days") and appear in the **Clock app**, leaking medication data to a very
  visible place.
- **Decision:** Keep **D-006** as-is: reminders are OS calendar events in a dedicated **local**
  notebook (full recurrence) with **`.ics` export** as the fallback. Do **not** use
  `Nemo.Alarms` as the default. It may return later as an optional "simple daily alarm" mode.
  The probe in `spikes/reminders/` confirms the calendar path before P4.
- **Consequences:** We still take the `Calendar` permission. If the probe shows the calendar
  write is unreliable, `Nemo.Alarms` (no permission) becomes the fallback before a companion
  background service is considered.

---

## Open questions

Nothing is blocking. Deferred admin:

| # | Question | When |
|---|----------|------|
| Q3 | Name + email for the GPG release-signing key and OpenRepos account | P8 |

Resolved: Q1 → D-002 (Qt 5.6/Silica on Storeman); Q2 → D-014 (Bokmål only);
Q4 → D-006 (local calendar + `.ics` fallback).

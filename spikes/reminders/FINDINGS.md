# Reminder spike — findings (device recon, 2026-10-10)

Device: Jolla Phone 2026, Sailfish OS **5.2.0.18 (Finlayson)**.

## Revised understanding (probe run 1)

First probe run: `Calendar.defaultNotebook` was **blank**, `NotebookQuery` empty, and an
`ImportModel.save()` "succeeded" but nothing appeared in the Calendar app.

Cause: the real calendar DB lives in `~/.local/share/system/privileged/Calendar/mkcal/`,
owned by group `privileg` with mode `770`. A sandboxed third-party app cannot see it, so
`org.nemomobile.calendar` falls back to an empty per-user DB (see mKCal `sqlitestorage.cpp`:
it uses the privileged dir only if it exists **and** is writable). **Direct calendar writes from
a third-party app are therefore not viable.** We also cannot create a notebook: the API has no
notebook-creation method.

## Supported path: Calendar UI import via D-Bus

The Calendar app exposes `com.jolla.calendar.ui` (`/com/jolla/calendar/ui`,
`/usr/share/jolla-calendar/DbusInvoker.qml`), and `Calendar.permission` grants exactly
`dbus-user.talk com.jolla.calendar.ui`. Relevant methods:

- `importIcsData(icsString)` — open the import UI with **in-memory iCalendar text** (no file)
- `importFile(fileName)` — import from a file path
- `viewEventByIdentifier(id, startDate)`, `viewDate(dateTime)`, `openUrl(args)`

The user picks the notebook and confirms; the Calendar app (with real access) writes the event
and the OS registers the alarm with `timed`. `Nemo.DBus 2.0` (`DBusInterface.call`) is
installed for making the call.

Consequences for the design:

- We author the iCalendar ourselves, so **recurrence is unlimited** (any `RRULE`).
- **No direct DB writes, no notebook creation, no `NotebookQuery`.**
- The notebook choice is the user's, shown in the import UI (transparent; no silent sync leak).
- Updates: re-import the same event `UID` — the ImportPage detects duplicates.
- Still no background service needed.

Probe v2 (`SpikePage.qml`) tests `importIcsData` from the sandboxed app.

### Probe v2 result — works

Confirmed on the Jolla Phone 2026 / 5.2.0.18: tapping the button opened the Calendar import
screen with the Dollfin event, and it could be saved to a calendar. The reminder design is
settled (D-019).

### Event rendering constraint

The Calendar app renders an event's description as `plainText` and exposes no `URL` field
(`Sailfish/Calendar/CalendarEventView.qml`), and only `location` is clickable (opens a map).
So we **cannot** put a clickable "open Dollfin / mark as taken" link inside the event. Logging
stays manual; the description can only carry a plain hint.

### Chosen event defaults

- `DURATION:PT1M` — a 1-minute event at the dose time (was 15 minutes).
- Alarm `TRIGGER:PT0S` — fire at the event start, not before. A pre-alarm can be skipped if
  the user takes longer than that between generating and confirming the import.
- `SUMMARY`/`DESCRIPTION` carry a plain "Open Dollfin to log this dose" hint.
- `UID` is stable per regimen (`dollfin-<regimenId>@dollfin`), so re-importing updates it.

## Original findings (still valid)

- `timed` **is running**: `/usr/bin/timed --systemd`. Calendar alarms and Clock alarms both
  ride on it, so it is the single reliable wake-up mechanism.
- **A sandboxed app may talk to `timed` with no special permission.** `Base.permission`
  (implicitly granted to every app) contains:
  ```
  dbus-system.talk com.nokia.time
  whitelist /var/lib/timed
  blacklist /var/lib/timed/shared_events
  blocklist /var/lib/timed/shared_settings
  ```
  The D-Bus policy `/etc/dbus-1/system.d/timed.conf` also allows the default context to
  `send_destination="com.nokia.time"`.
- **`Nemo.Alarms`** QML plugin (`nemo-qml-plugin-alarms-qt5`) is installed:
  - `AlarmsBackendModel.createAlarm()` → `AlarmObject`
  - `AlarmObject`: `title`, `hour`, `minute`, `second`, `daysOfWeek`, `enabled`, `countdown`,
    `save()`, `deleteAlarm()`.
  - `daysOfWeek` is a string of `mtwTfsS` (Mon–Sun). **Weekly recurrence only** — no
    "every N days". Empty = single-shot.
  - It creates timed events typed `clock` / `countdown`, so they **appear in the Clock app**
    and are handled by `jolla-alarm-ui` (full-screen alarm + snooze).
- **`org.nemomobile.calendar`** QML plugin (`nemo-qml-plugin-calendar-qt5` 0.7.11) is
  installed: `CalendarApi`, `CalendarEventModification`, `CalendarEvent`, `CalendarNotebookModel`,
  `CalendarImportModel`, … It reads/writes the mKCal storage.
- The **`Calendar` sailjail permission** does *not* grant a calendar D-Bus API. It grants:
  ```
  whitelist /usr/share/jolla-calendar
  mkdir ${PRIVILEGED}/Calendar
  privileged-data Calendar
  dbus-user.talk com.jolla.calendar.ui   # open the Calendar UI (view/import)
  ```
  i.e. access to the privileged calendar data dir plus the ability to trigger the Calendar UI.
- `timed`'s own recurrence API (`Event::Recurrence`) exposes **`daysOfWeek` only** — no
  arbitrary interval either.

## Candidate mechanisms (revised)

| Mechanism | Permission | Recurrence | Where it shows | Silent? | Fires closed |
|-----------|-----------|-----------|----------------|---------|--------------|
| Calendar UI import (`importIcsData`) | `Calendar` (D-Bus grant) | full RRULE | Calendar app | no — user confirms | yes |
| `.ics` file export | none | full | user's calendar | no — user imports | yes |
| `Nemo.Alarms` (clock alarms) | none | weekdays only | Clock app | yes | yes |
| direct calendar write | `Calendar` | — | — | — | **not viable** |

## Trade-offs

- The **Calendar UI import** path is the supported one, handles any schedule, and puts
  reminders where people already look. Cost: a one-time user confirmation per regimen (and
  again on schedule changes).
- **`Nemo.Alarms`** is silent and permission-free but weekly-only and leaks into the Clock app.
- **`.ics` export** stays as the fallback/backup — and it is the exact string we hand to the
  Calendar UI, so one code path serves both.

## What the probe must confirm

1. A sandboxed app can call `importIcsData` and the Calendar import UI opens with our event.
2. After the user confirms, the event lands in the chosen calendar and the alarm fires with the
   app closed (and after a reboot).
3. Re-importing the same `UID` updates rather than duplicates.

## Recommendation

Primary: **generate iCalendar in-app and hand it to the Calendar UI via `importIcsData`**;
always also offer `.ics` file export. No direct DB writes, no notebook creation, no background
service. `Nemo.Alarms` stays a possible future "simple daily alarm" mode.

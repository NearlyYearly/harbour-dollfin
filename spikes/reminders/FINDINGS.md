# Reminder spike — findings (device recon, 2026-10-10)

Device: Jolla Phone 2026, Sailfish OS **5.2.0.18 (Finlayson)**.

## Confirmed facts

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

## Candidate mechanisms

| Mechanism | Permission | Recurrence | Where it shows | Fires closed | Sync risk |
|-----------|-----------|-----------|----------------|--------------|-----------|
| `Nemo.Alarms` (clock alarms) | none | weekdays only | **Clock app** + alarm UI | yes | none |
| `org.nemomobile.calendar` (local notebook) | `Calendar` | full RRULE (daily / every N days / end date) | Calendar app | yes | only if notebook synced |
| `.ics` export | none | full | user's chosen calendar | yes | user-controlled |
| companion service | n/a | full | custom | yes | none |

## Trade-offs

- **Alarms** are the least-permission option and survive reboot, but they leak into the Clock
  app (anyone glancing sees "Dollfin: estradiol 2 mg") and cannot express "every 5 days",
  which real HRT schedules use.
- **Calendar** supports the schedules we actually need and shows reminders where people
  already look. Privacy depends on writing to a **local** notebook only (D-006 hard rule).
- **`.ics`** stays as the always-available fallback.

## What the probe must test

1. Can a sandboxed app with `Permissions=Calendar` use `org.nemomobile.calendar` to create a
   **local** notebook and a repeating event with an alarm?
2. Does that alarm fire with the app closed, and after a reboot?
3. Can we reliably tell a local notebook from a synced one?
4. (compare) `Nemo.Alarms` creation with no permission; confirm it appears in the Clock app.

## Preliminary recommendation

Keep **calendar-in-a-local-notebook as primary, `.ics` as fallback** (D-006). Treat
`Nemo.Alarms` as a possible future "simple daily schedule" mode, not the default, because of
the Clock-app visibility and the weekday-only recurrence.

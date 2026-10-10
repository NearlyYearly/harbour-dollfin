# Reminder spike — run before P2

Throwaway experiment. It answers **D-006** (reminder mechanism) and **D-013** (permission)
*before* the data layer is built, because the answer changes the schema and the UI.

## Questions to answer

1. Do OS calendar alarms fire reliably with the app closed, after a reboot, and across a DST
   change?
2. Does `.ics` import into Sailfish Calendar on 5.2 work, with repeats and alarms?
3. Can a sandboxed app write a repeating event into a **local** calendar via
   `nemo-qml-plugin-calendar` under the `Calendar` permission? Can we keep it local-only?

## Step 0 — native baseline (no app, no files)

In the phone's Calendar app, create a **daily repeating event** with a reminder set ~3 minutes
ahead. Lock the phone. Does it ring? Reboot the phone. Does the next one ring?

If native repeating calendar alarms are not dependable, nothing we build on top of them is, and
we fall straight to `.ics` plus a documented limitation.

## Step 1 — `.ics` import (no app)

Push `dollfin-reminder-test.ics` to the phone and open it (Files app → import). Check:

- does the event import at all?
- is the daily repeat preserved?
- does the alarm fire with the app closed?

## Step 2 — app-driven calendar write (only if 0 and 1 pass)

Smallest possible probe: a temporary page that

- declares `Permissions=Calendar` in the `.desktop`,
- creates/uses a **local** notebook (never a synced one),
- writes a repeating event with an alarm,
- reports whether the notebook is local or synced.

Delete it once P4 is implemented properly.

## Decision

Pick one and update `docs/DECISIONS.md` (D-006/D-013) and `docs/PLATFORM.md`:

- **(a)** direct local-calendar write as primary,
- **(b)** `.ics` export only (simplest, no `Calendar` permission, no sync risk),
- **(c)** both — write the calendar, always offer `.ics` as a fallback.

## Cleanup

Remove this whole directory when P4 is done.

# Working instructions — dollfin

Instructions for anyone (human or AI agent) changing this repository. Follow these
unless a decision in `docs/DECISIONS.md` says otherwise.

## Project facts

- App / binary / package name: `harbour-dollfin`
- Stack: Qt 5.6 QML + Sailfish Silica UI + C++ backend
- Target: Sailfish OS 5.x (aarch64), primary device Jolla Phone 2026
- Data: SQLite in the sandboxed app dir. Local only.
- Distribution: OpenRepos / Storeman

## Golden rules

1. **Local-first.** Never open a network connection. Do not add the `Internet` sailjail
   permission. No analytics, crash reporting or remote config.
2. **Reminders are critical.** Prefer correctness over speed. A silently dropped reminder
   is a bug of the highest severity.
3. **No dosing advice.** The app records what the user configures; it never recommends a
   dose, schedule or medication. Use neutral language and never assume a route or gender.
4. **Schema changes need a decision + migration.** Append to `docs/DECISIONS.md` and add a
   migration; never mutate existing columns in place.
5. **UI uses platform tokens.** Silica components and `Theme.*` values only — no hardcoded
   colors, sizes or fonts.
6. **All user-visible text is translatable** via `qsTr()`.
7. **Use allowed APIs.** If something is not in `docs/PLATFORM.md` / the Sailfish allowed
   API list, record a decision before adding it.

## Definition of done (per change)

- [ ] Builds with `sfdk build` for the aarch64 target
- [ ] Deploys and runs on a device or emulator via `sfdk deploy`
- [ ] New logic has a QtTest unit test (data layer, schedule and reminder logic especially)
- [ ] Strings wrapped for translation
- [ ] No new permission, library or dependency without a `docs/DECISIONS.md` entry
- [ ] `docs/TODO.md` and/or `docs/DECISIONS.md` updated if scope changed
- [ ] No data loss on app update; export still works

## Repo layout (planned)

```
harbour-dollfin.pro          # main project file
src/                         # C++: models, database, reminder engine
qml/                         # QML: pages, components, cover
  pages/
  cover/
tests/                       # QtTest unit tests
rpm/                         # .spec, .changes for packaging
translations/                # .ts / .qm
harbour-dollfin.desktop      # launcher + [X-Sailjail] permissions
docs/                        # plan, todo, decisions, platform notes
```

## Build & run

One-time setup (container image or full SDK) is in [`docs/BUILD.md`](docs/BUILD.md).
Day-to-day builds need **no SDK** — just podman:

```sh
scripts/build-rpm.sh            # -> RPMS/harbour-dollfin-<ver>-1.aarch64.rpm
```

With the full Sailfish SDK installed (for the emulator / one-command deploy):

```sh
sfdk tools list                 # installed toolchains/targets
sfdk target list                # available OS targets
sfdk config target <TARGET>     # e.g. an aarch64 SailfishOS 5.x target
sfdk build
sfdk build --sign               # GPG-signed RPM for release
sfdk deploy --device <name>     # to a real device
sfdk deploy --manual            # to emulator
```

Sandboxing is **off** when launched from the IDE or terminal. To test real permissions:

```sh
sailjail /usr/bin/harbour-dollfin
```

## Conventions

- QML in `qml/`, C++ in `src/`, tests in `tests/`.
- User-facing strings are translated into English, Dutch and Norwegian (D-014) — always
  `qsTr()`, never hardcode.
- Commit messages: `area: short summary` (e.g. `reminders: handle DST transition`).
- Branching: `main` + short-lived feature branches.
- Versioning: `MAJOR.MINOR.PATCH`, RPM release `-1`.

## Where things go

| You have... | Put it in... |
|-------------|--------------|
| A new or reversed decision | `docs/DECISIONS.md` |
| A task to do | `docs/TODO.md` |
| A platform fact / API behaviour | `docs/PLATFORM.md` |
| A scope change | `docs/PLAN.md` |

## Do not

- Add dependencies for a few lines of code.
- Add networking, analytics or crash reporting.
- Store data outside the app's sandboxed directory.
- Log or notify more health data than the screen already shows.

## Escalation points

- **Closed-app reminders** — the OS suspends normal apps, so dose alarms go through the OS
  calendar/`timed`: write repeating events into a dedicated **local** calendar, with `.ics`
  export as a fallback (D-006). Never write reminders into a synced calendar.
- **Harbour validation** — if we later target the Jolla Store, the RPM validator restricts
  allowed APIs and permissions. Keep the code inside the allowed list where practical.
- **Qt 6 path** — code stays Keel-grade so a future Qt 6/Keel build is possible (D-002).

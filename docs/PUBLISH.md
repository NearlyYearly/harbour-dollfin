# Publishing — Storeman / OpenRepos

The v1 target is **OpenRepos**, installed through **Storeman** (D-007). No Harbour/Jolla Store
submission yet.

## Versioning

Bump `Version:` in `rpm/harbour-dollfin.spec` and add a `%changelog` entry for each release.
Version scheme is `MAJOR.MINOR` for now (`0.5`), RPM release `-1`.

## Build

```sh
scripts/build-rpm.sh
# -> RPMS/harbour-dollfin-<version>-1.aarch64.rpm
```

Sanity check before uploading:

```sh
rpm -qip RPMS/harbour-dollfin-*.rpm    # name, version, licence, summary
rpm -qlp RPMS/harbour-dollfin-*.rpm    # files
```

## Signing (optional, recommended)

OpenRepos accepts unsigned packages, but Storeman will warn about untrusted software. To sign
with a GPG key:

```sh
gpg --gen-key
cat >> ~/.rpmmacros <<EOF
%_signature gpg
%_gpg_name <the key's name or id>
EOF
rpm --addsign RPMS/harbour-dollfin-*.aarch64.rpm
rpm -K RPMS/harbour-dollfin-*.aarch64.rpm   # digests signatures OK
```

Publish the public key so people can verify: `gpg --armor --export <id>`.

## OpenRepos listing

1. Create an account / project at <https://openrepos.net>.
2. Package name **harbour-dollfin**; category *Applications* (or *Utilities*).
3. Upload the `.rpm` for `aarch64`.
4. Paste the description below, add screenshots, and a changelog.

### Summary

> Local-first medication tracking for trans people

### Description

> Dollfin is a private medication tracker for trans people on Sailfish OS.
>
> Track medications, schedules and stock, and get dose reminders through your own calendar.
> Medications are free text — no fixed list — so compounded or unusual preparations work too.
>
> Everything stays on your phone: no account, no network access, no telemetry. Reminders are
> added to a calendar you choose, so if you pick one that syncs to a cloud service, only you
> decide that.
>
> Open source, GPL-3.0-or-later.

## Storeman

Users either add the OpenRepos repository in Storeman and install **Dollfin**, or install the
RPM directly. In both cases the app must be installed from `aarch64`.

## Checklist

- [ ] version bumped and `%changelog` updated
- [ ] `scripts/build-rpm.sh` succeeds (0 rpmlint errors)
- [ ] `scripts/run-tests.sh` green
- [ ] installed and launched on a clean Jolla Phone 2026
- [ ] (optional) RPM signed and key published
- [ ] OpenRepos project created, RPM + description + screenshots uploaded
- [ ] git tag for the release

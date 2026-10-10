# Building dollfin

How to produce the `harbour-dollfin` RPM. The default path needs **no SDK install and no
sudo** — just podman. The full Sailfish SDK is only needed for the emulator or one-command
`sfdk deploy`.

## Option 1 — container build (default)

```sh
scripts/build-rpm.sh              # 5.2.0.15 aarch64
scripts/build-rpm.sh 5.1.0.11     # a different target release
```

Output: `RPMS/harbour-dollfin-<version>-1.aarch64.rpm`.

The script runs the community **Sailfish Platform SDK** image
([`coderus/sailfishos-platform-sdk`](https://hub.docker.com/r/coderus/sailfishos-platform-sdk/tags),
the same image behind the `coderus/github-sfos-build` action) in podman and calls
`mb2 -t SailfishOS-<release>-aarch64 build`.

Requirements:

- `podman` (already on this host).
- ~6 GB free for the image (first run pulls ~5 GB) plus the extracted layers.
- The host user's rootless `storage.conf` must allow unmappable UIDs, because the image
  contains files owned by UID 100000, which is outside the default subuid range. This repo's
  setup added `~/.config/containers/storage.conf`:

  ```toml
  [storage]
  driver = "overlay"

  [storage.options.overlay]
  ignore_chown_errors = "true"
  ```

Why the script does odd things: the image's build user (`mersdk`, UID 100000) is outside the
rootless subuid range, so podman cannot run as it directly, and `mb2` refuses to run as root.
The script starts the container as root, moves `mersdk` into the subuid range
(`usermod -u 1000`), and drops to it with `chroot --userspec` (no PAM, unlike `su`).

### Targets

The container ships **5.2.0.15** and **5.1.0.11** targets for `aarch64`, `armv7hl` and `i486`.
We build **aarch64 only** (decision D-001). The official Sailfish SDK (Option 2) currently
only ships 5.1 targets, so the container is ahead here.

## Deploying to the phone

There is no `sfdk deploy` without the SDK. Test installs can be pushed by hand:

```sh
scp RPMS/harbour-dollfin-*-1.aarch64.rpm defaultuser@<phone-ip>:
ssh defaultuser@<phone-ip> "devel-su pkcon install-local harbour-dollfin-*-1.aarch64.rpm"
```

Developer mode must be enabled on the phone. Real users install from Storeman.

## Option 2 — full Sailfish SDK (emulator / GUI deploy)

Needed only if you want the Sailfish emulator or `sfdk deploy`.

```sh
cd ~/Downloads
curl -LO https://releases.sailfishos.org/sdk/installers/3.13.5/SailfishSDK-3.13.5-linux64-online.run
echo "20fbb809a4ad27b71444a2081d56ca84  SailfishSDK-3.13.5-linux64-online.run" | md5sum -c -
chmod +x SailfishSDK-3.13.5-linux64-online.run && ./SailfishSDK-3.13.5-linux64-online.run
```

It needs Docker or VirtualBox as the build engine, and the emulator needs VirtualBox. On this
immutable Bazzite host that means `rpm-ostree install …` and a reboot. Day-to-day commands:

```sh
sfdk tools list
sfdk config target SailfishOS-5.1.0.11-aarch64
sfdk build
sfdk deploy --device <name>
```

## Option 3 — Platform SDK chroot (CLI, sudo)

The official CLI-only SDK. Needs `sudo` and ~3 GB. See
[docs.sailfishos.org/Tools/Platform_SDK](https://docs.sailfishos.org/Tools/Platform_SDK/).

## Test the sandbox

Sandboxing is off when launched from the IDE. On a device/emulator, exercise the real profile:

```sh
sailjail /usr/bin/harbour-dollfin
```

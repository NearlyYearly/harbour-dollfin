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

## Testing on the phone

### One-time: prepare the phone

In **Settings > Developer tools**:

1. Turn on **Developer mode** (asks for your security code).
2. Turn on **Remote connection**.
3. Tap **Set password for SSH and root access** and set a password. This is both the SSH
   password and the `devel-su` password.

The phone must be awake and unlocked for SSH to work.

### Connect

- **USB (recommended):** plug the cable in and choose **Developer mode** in the USB dialog
  on the phone. The phone is always at **192.168.2.15**.
- **WLAN:** join the same network as the computer; the phone's IP is shown in
  Settings > Developer tools.

```sh
ssh defaultuser@192.168.2.15        # USB
ssh defaultuser@192.168.x.y         # WLAN
```

The user is `defaultuser` on Sailfish OS 5.x (`nemo` only on very old releases).

### Build, copy, install

```sh
scripts/build-rpm.sh
scripts/deploy-device.sh                              # USB default
scripts/deploy-device.sh defaultuser@192.168.x.y      # WLAN
```

That is `scp` plus `devel-su rpm -Uvh --force` under the hood. Real users install from
Storeman.

### Logs

Launch the app, then follow its journal from the computer:

```sh
ssh defaultuser@192.168.2.15 "devel-su journalctl -f _COMM=harbour-dollfin"
```

### Notes

- USB on Linux should just work — the phone runs a DHCP server on the USB link. If the
  interface doesn't come up, check `ip a` / `nmcli device`; WLAN is the fallback.
- Installing an unsigned locally-built RPM is fine; `rpm -Uvh` doesn't do repository
  signature checks.
- If you later install the full SDK, `sfdk deploy --device <name>` does all of this.

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

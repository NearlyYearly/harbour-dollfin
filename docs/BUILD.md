# Building dollfin

How to get a working Sailfish SDK and build/deploy this app. Once the SDK is set up, the
day-to-day commands live in `AGENTS.md`.

## Host notes (this machine)

- Host: Bazzite (immutable Fedora / `rpm-ostree`), x86_64, `podman` installed, **no Docker
  or VirtualBox**, and `sudo` requires a password.
- That means the SDK install is a manual step: it either needs a virtualization backend
  (Docker/VirtualBox) or `sudo` for the chroot. Pick one of the options below.

## Which build environment?

| Option | Effort | Gives you |
|--------|--------|-----------|
| **A. Sailfish SDK (GUI)** | 2.4 GB download + an engine (Docker or VirtualBox) | `sfdk`, the emulator, one-command deploy to the phone |
| **B. Platform SDK chroot (CLI)** | `sudo`, ~3 GB | `mb2` command-line builds only, deploy by hand |

Recommendation: try **A** with VirtualBox. If the immutable host fights you, fall back to **B**
for CLI builds (you have a real Jolla Phone, so the emulator is optional).

### A. Sailfish SDK (full)

```sh
cd ~/Downloads
curl -LO https://releases.sailfishos.org/sdk/installers/3.13.5/SailfishSDK-3.13.5-linux64-online.run
echo "20fbb809a4ad27b71444a2081d56ca84  SailfishSDK-3.13.5-linux64-online.run" | md5sum -c -
chmod +x SailfishSDK-3.13.5-linux64-online.run
./SailfishSDK-3.13.5-linux64-online.run
```

The installer asks where to install (default `~/SailfishOS`) and which virtualization backend
to use. On Bazzite you must add that backend first, e.g. `rpm-ostree install VirtualBox` (or a
Docker package) and reboot. Then use the **SDKMaintenanceTool** to add build targets.

### B. Platform SDK chroot (CLI)

Follow the official quick start, adapting `PLATFORM_SDK_ROOT` to a path you control:

```sh
export PLATFORM_SDK_ROOT=$HOME/sailfishos
curl -k -O https://releases.sailfishos.org/sdk/installers/latest/Jolla-latest-SailfishOS_Platform_SDK_Chroot-i486.tar.bz2
sudo mkdir -p $PLATFORM_SDK_ROOT/sdks/sfossdk
sudo tar --numeric-owner -p -xjf Jolla-latest-SailfishOS_Platform_SDK_Chroot-i486.tar.bz2 -C $PLATFORM_SDK_ROOT/sdks/sfossdk
$PLATFORM_SDK_ROOT/sdks/sfossdk/sdk-chroot
```

Inside, add a build target and build with `mb2`. See
[docs.sailfishos.org/Tools/Platform_SDK](https://docs.sailfishos.org/Tools/Platform_SDK/).

## Build targets

SDK 3.13.5 ships Sailfish OS **5.1.0.11** targets (including `aarch64`). There is no 5.2 target
yet — build against 5.1 and test the RPM on the Jolla Phone 2026 / 5.2 (risk R2 in `PLAN.md`).
Newer OS targets appear as **Early Access** components in the SDKMaintenanceTool.

```sh
sfdk tools list          # see what is installed
sfdk target list         # see available OS targets
sfdk config target SailfishOS-5.1.0.11-aarch64
```

aarch64 only (decision D-001). Do not add armv7hl.

## Build and deploy

```sh
sfdk build                 # produces RPMS/harbour-dollfin-<ver>-1.aarch64.rpm
sfdk build --sign          # GPG-signed (release only)
sfdk deploy --device <name>   # install onto the phone
sfdk deploy --manual          # emulator
```

The device must have **Developer mode** enabled and be reachable over USB/WLAN SSH. Set it up
once in **Tools → Options → Devices** (or Qt Creator → Preferences → Devices).

## Test the sandbox

Sandboxing is off when the app is launched from the IDE. To exercise the real sailjail profile:

```sh
sailjail /usr/bin/harbour-dollfin
```

## Manual install (no SDK deploy)

Copy the RPM to the phone and install it there:

```sh
scp RPMS/harbour-dollfin-*-1.aarch64.rpm defaultuser@<phone-ip>:
ssh defaultuser@<phone-ip> "devel-su pkcon install-local harbour-dollfin-*-1.aarch64.rpm"
```

Only do this for testing — for users, the app is installed from Storeman.

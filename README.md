# EDORP Gentoo Overlay

Personal Gentoo overlay for packages maintained or tested by Edo.

## Setup

Register the overlay by copying the repo config:

```bash
doas cp metadata/edorp.conf /etc/portage/repos.conf/edorp.conf
```

The config is:

```ini
[edorp]
location = /var/db/repos/edorp
sync-type = git
sync-uri = https://github.com/firesand/edorp-overlay.git
auto-sync = yes
masters = gentoo
priority = 70
```

Then sync it:

```bash
emerge --sync edorp
```

## Scope

This repository should contain ebuilds, metadata, small package files, and
patches only. Source trees, ROMs, CHDs, build outputs, caches, binaries, and
local machine configuration do not belong in the overlay.

## Packages

### General

- `net-misc/fluxcast`: imported from the existing FluxCast portable overlay
  bundle.
- `dev-python/pystray`: Fluxcast dependency.
- `dev-python/upnpclient`: Fluxcast dependency.
- `app-portage/equery-gui`: graphical front-end for `equery`
  ([source](https://github.com/firesand/equery-gui)).
- `app-emulation/linuxmameui`: imported from the local LinuxMAMEUI Gentoo
  packaging. This currently uses a local `linuxmameui-0.1.0.tar.gz` distfile
  with `RESTRICT=fetch`, so it is not fully portable across machines until a
  release tarball or Git source URI exists.
- `app-emulation/mame`: MAME 0.288 ebuild imported from local LinuxMAMEUI
  packaging.
- `app-emulation/hbmame`: HBMAME 0.288.2 ebuild imported from local LinuxMAMEUI
  packaging.
- `app-emulation/mameuix`: modern Rust/egui frontend for MAME
  ([source](https://github.com/firesand/MAMEUIx)). Versioned ebuild `0.1.6`
  fetches GitHub tag `v0.1.6` plus crates via `CRATES`; live ebuild `9999`
  uses `cargo_live_src_unpack`. Requires `app-emulation/mame` from this
  overlay. Portable **AppImage** builds live in the MAMEUIx repo
  (`./build-appimage.sh`); GitHub Releases may attach `MAMEUIx-*-x86_64.AppImage`
  (MAME not bundled — same RDEPEND model as the ebuild).
- `app-benchmarks/unigine-superposition`: UNIGINE Superposition benchmark.
  Hardware-agnostic; no systemd requirement.
- `net-wireless/wiflux`: terminal-based wireless security auditor
  ([source](https://github.com/Leadrogue/Wiflux)). The versioned ebuild builds
  the official source distribution through PEP 517; it does not use `pip` or
  the upstream Debian-oriented installer.

### Wiflux

The current Gentoo `aircrack-ng` defaults enable two unrelated Python tools
whose ebuild supports Python 3.11/3.12, but not 3.13/3.14. On a system whose
enabled Python targets are only 3.13/3.14, disable those tools before installing
Wiflux:

```bash
echo "net-wireless/aircrack-ng -airdrop-ng -airgraph-ng" | doas tee /etc/portage/package.use/edorp-wiflux
echo "=net-wireless/wiflux-1.0.5 ~amd64" | doas tee /etc/portage/package.accept_keywords/edorp-wiflux
doas emerge -av net-wireless/wiflux
```

Wiflux requires root for monitor mode and packet injection. Use it only on
networks you own or have explicit permission to audit. It will not unpack a
compressed dictionary into `/usr`; decompress it to a writable location and
select it with `--dict FILE`.

### ASUS laptop (systemd only)

Imported from the local `asus-gentoo-overlay` bundle. These packages target
**ASUS ROG / hybrid-GPU laptops running Gentoo with systemd**. They are not
intended for OpenRC profiles or non-ASUS hardware:

- `sys-power/asusctl`: asus-linux daemon, CLI, and optional rog-control-center.
- `sys-power/supergfxctl`: hybrid-GPU mode switching daemon.

After install, enable the services:

```bash
systemctl enable --now asusd.service asus-shutdown.service supergfxd.service
```

Accept keywords for live ebuilds:

```bash
echo "=sys-power/asusctl-9999 **" | doas tee /etc/portage/package.accept_keywords/edorp-asus
echo "=sys-power/supergfxctl-9999 **" | doas tee -a /etc/portage/package.accept_keywords/edorp-asus
echo "sys-power/asusctl gui" | doas tee /etc/portage/package.use/edorp-asus
```

## Validation

Basic ebuild parse checks can be run without using system `/var/tmp/portage`:

```bash
mkdir -p .portage-tmp
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild net-misc/fluxcast/fluxcast-9999.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-portage/equery-gui/equery-gui-0.1.0.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-emulation/linuxmameui/linuxmameui-0.1.0.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-emulation/mame/mame-0.288.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-emulation/hbmame/hbmame-0.288.2.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-emulation/mameuix/mameuix-0.1.6.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-emulation/mameuix/mameuix-9999.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild net-wireless/wiflux/wiflux-1.0.5.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild sys-power/asusctl/asusctl-9999.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild sys-power/supergfxctl/supergfxctl-9999.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-benchmarks/unigine-superposition/unigine-superposition-1.1.ebuild clean
rm -rf .portage-tmp
```

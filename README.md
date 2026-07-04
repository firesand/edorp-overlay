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
- `app-benchmarks/unigine-superposition`: UNIGINE Superposition benchmark.
  Hardware-agnostic; no systemd requirement.

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
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild sys-power/asusctl/asusctl-9999.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild sys-power/supergfxctl/supergfxctl-9999.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-benchmarks/unigine-superposition/unigine-superposition-1.1.ebuild clean
rm -rf .portage-tmp
```

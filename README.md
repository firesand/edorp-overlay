# EDORP Gentoo Overlay

Personal Gentoo overlay for packages maintained or tested by Edo.

## Setup

Register the overlay in `/etc/portage/repos.conf/edorp.conf`:

```ini
[edorp]
location = /var/db/repos/edorp
sync-type = git
sync-uri = git@github.com:USERNAME/edorp-overlay.git
auto-sync = yes
masters = gentoo
```

Then sync it:

```bash
emerge --sync edorp
```

## Scope

This repository should contain ebuilds, metadata, small package files, and
patches only. Source trees, ROMs, CHDs, build outputs, caches, binaries, and
local machine configuration do not belong in the overlay.

Initial package targets:

- Fluxcast
- MAME
- HBMAME
- LinuxMAMEUI

## Packages

- `net-misc/fluxcast`: imported from the existing FluxCast portable overlay
  bundle.
- `dev-python/pystray`: Fluxcast dependency.
- `dev-python/upnpclient`: Fluxcast dependency.
- `app-emulation/linuxmameui`: imported from the local LinuxMAMEUI Gentoo
  packaging. This currently uses a local `linuxmameui-0.1.0.tar.gz` distfile
  with `RESTRICT=fetch`, so it is not fully portable across machines until a
  release tarball or Git source URI exists.
- `app-emulation/mame`: MAME 0.288 ebuild imported from local LinuxMAMEUI
  packaging.
- `app-emulation/hbmame`: HBMAME 0.288.2 ebuild imported from local LinuxMAMEUI
  packaging.

## Validation

Basic ebuild parse checks can be run without using system `/var/tmp/portage`:

```bash
mkdir -p .portage-tmp
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild net-misc/fluxcast/fluxcast-9999.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-emulation/linuxmameui/linuxmameui-0.1.0.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-emulation/mame/mame-0.288.ebuild clean
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild app-emulation/hbmame/hbmame-0.288.2.ebuild clean
rm -rf .portage-tmp
```

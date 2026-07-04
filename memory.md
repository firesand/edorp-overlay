# EDORP Memory

This file is the durable working memory for this workspace. Read it at the
start of future sessions before making assumptions.

## User Preferences

- Challenge ideas before agreeing. Look for weak assumptions, hidden risks,
  vague logic, and likely failure points early.
- Be direct and concise. Avoid empty praise, filler validation, and vague
  encouragement.
- Agreement should be earned: agree only after testing the idea and add useful
  reasoning.
- Prefer practical implementation over long theory when the direction is clear.

## Current Goal

Create a personal Gentoo overlay that can be synced and updated across machines.
The overlay is intended for personal packages and experiments, starting with:

- Fluxcast, currently associated with SSH PC GenX.
- MAME-related work under `/home/edo/mame`, including MAME, HBMAME, and
  LinuxMAMEUI.
- Future applications can be added later.

Status as of 2026-07-04:

- `/home/edo/EDORP` has been initialized as the EDORP overlay root.
- Git has been initialized locally on branch `main`, but there is no commit yet
  because local `user.name` and `user.email` are not configured.
- `/home/edo/mame` does not exist. Existing related paths found:
  `/home/edo/MAME` is a symlink to `/home/edo/ArcadeDev/LinuxMAMEUI`, and
  `/home/edo/ArcadeDev/MAME` is empty.
- Fluxcast overlay content was imported from
  `/home/edo/Fluxcast/fluxcast-overlay-bundle.tar.gz`.
- LinuxMAMEUI/MAME/HBMAME ebuilds were imported from
  `/home/edo/ArcadeDev/LinuxMAMEUI/packaging/gentoo`.

## Overlay Direction

The overlay should be a real Gentoo ebuild repository, not a raw dump of source
trees or local working directories.

Recommended repository name:

```text
edorp-overlay
```

Minimal structure:

```text
edorp-overlay/
  metadata/
    layout.conf
  profiles/
    repo_name
  games-emulation/
    fluxcast/
      fluxcast-9999.ebuild
      metadata.xml
    linuxmameui/
      linuxmameui-9999.ebuild
      metadata.xml
```

Minimal metadata:

```text
metadata/layout.conf: masters = gentoo
profiles/repo_name: edorp
```

Actual `metadata/layout.conf` now uses:

```text
masters = gentoo
thin-manifests = true
sign-manifests = false
```

Actual categories currently listed:

```text
app-misc
app-emulation
dev-python
games-emulation
net-misc
```

## Sync Model

The overlay should be hosted on GitHub and registered through
`/etc/portage/repos.conf/edorp.conf`, for example:

```ini
[edorp]
location = /var/db/repos/edorp
sync-type = git
sync-uri = git@github.com:USERNAME/edorp-overlay.git
auto-sync = yes
masters = gentoo
```

Sync command:

```bash
emerge --sync edorp
```

If the GitHub repo is private, root must have SSH access to GitHub, usually via
a deploy key or root-readable SSH configuration. This is a likely failure point.

## Repository Hygiene

Do not commit:

- ROMs, CHDs, samples, BIOS dumps, or other copyrighted emulator content.
- Build outputs, cache directories, binaries, large archives, or generated logs.
- Local machine configuration that is not portable.
- Secrets, SSH keys, tokens, private URLs, or credentials.

Commit only:

- Ebuilds.
- `metadata.xml`.
- Small patches required by ebuilds.
- Small helper files under package `files/` directories.
- Documentation that explains package choices and local policy.

## Package Placement

- Use `-9999` live ebuilds for Git-based packages while they are still moving.
  Add versioned ebuilds later when the source release model is stable.

Actual imported package placement:

- `net-misc/fluxcast`
- `dev-python/pystray`
- `dev-python/upnpclient`
- `app-emulation/linuxmameui`
- `app-emulation/mame`
- `app-emulation/hbmame`

Do not move LinuxMAMEUI/MAME/HBMAME categories casually. The existing local
packaging uses `app-emulation`, and that category exists in the local Gentoo
tree.

Known portability issue:

- `app-emulation/linuxmameui` currently uses `SRC_URI="${P}.tar.gz"` with
  `RESTRICT=fetch`, so every machine needs the same local distfile unless the
  project gets a real release tarball or Git-based live ebuild.

## Future Session Checklist

1. Read this file before proposing or changing overlay structure.
2. Check whether an overlay repo already exists locally or on GitHub.
3. Inspect source locations before writing ebuilds.
4. Keep source code repos separate from the Gentoo overlay unless there is a
   deliberate reason to vendor a small patch or helper file.
5. Run relevant Gentoo checks when available, such as `pkgcheck`, `repoman`, or
   `ebuild ... manifest`, depending on the installed tooling.

Validation already performed:

```bash
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-misc/fluxcast/fluxcast-9999.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-emulation/linuxmameui/linuxmameui-0.1.0.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-emulation/mame/mame-0.288.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-emulation/hbmame/hbmame-0.288.2.ebuild clean
```

All four basic parse checks passed after enabling thin manifests and using a
local `PORTAGE_TMPDIR`.

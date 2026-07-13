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
- Git has been initialized locally on branch `main`.
- Local Git identity is configured as `firesand <firesand@gmail.com>`.
- Initial commit exists: `51f128b Initial EDORP Gentoo overlay`.
- Remote `origin` is configured as `git@github.com:firesand/edorp-overlay.git`.
- Push to GitHub is complete. `main` tracks `origin/main`, and GitHub remote
  head is `2d8abb54f657fa6497d5d90cd0b86f6ea239e730`.
- `/home/edo/mame` does not exist. Existing related paths found:
  `/home/edo/MAME` is a symlink to `/home/edo/ArcadeDev/LinuxMAMEUI`, and
  `/home/edo/ArcadeDev/MAME` is empty.
- Fluxcast overlay content was imported from
  `/home/edo/Fluxcast/fluxcast-overlay-bundle.tar.gz`.
- LinuxMAMEUI/MAME/HBMAME ebuilds were imported from
  `/home/edo/ArcadeDev/LinuxMAMEUI/packaging/gentoo`.
- ASUS laptop ebuilds (`asusctl`, `supergfxctl`, `unigine-superposition`) were
  imported from `/home/edo/Downloads/Asus-Gentoo/asus-gentoo-overlay` on the
  Intel Gentoo laptop (`192.168.0.10`). Only the overlay packages were imported;
  local setup scripts from that directory were excluded.
- `equery-gui` source lives at `https://github.com/firesand/equery-gui`. The
  overlay ebuild is `app-portage/equery-gui/equery-gui-0.1.0.ebuild`.

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
app-benchmarks
app-emulation
app-misc
app-portage
dev-python
games-emulation
net-analyzer
net-misc
net-wireless
sys-power
```

## Sync Model

The overlay should be hosted on GitHub and registered through
`/etc/portage/repos.conf/edorp.conf`, for example:

```ini
[edorp]
location = /var/db/repos/edorp
sync-type = git
sync-uri = https://github.com/firesand/edorp-overlay.git
auto-sync = yes
masters = gentoo
priority = 70
```

Sync command:

```bash
emerge --sync edorp
```

The repo is public, so use HTTPS for Portage sync. Do not use SSH for
`sync-uri` unless the repo becomes private and root has GitHub SSH access.

`metadata/edorp.conf` contains the ready-to-copy Portage config. Installing it
requires root:

```bash
doas cp metadata/edorp.conf /etc/portage/repos.conf/edorp.conf
```

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
- `app-emulation/mameuix`
- `app-portage/equery-gui`
- `sys-power/asusctl` (ASUS ROG laptop, systemd only)
- `sys-power/supergfxctl` (ASUS hybrid-GPU laptop, systemd only)
- `app-benchmarks/unigine-superposition` (general benchmark, not ASUS-specific)
- `net-wireless/wiflux` (wireless security auditor; versioned upstream release)
- `net-wireless/hcxtools` (capture conversion and hash-analysis tools)
- `net-wireless/hcxdumptool` (monitor-mode capture and PMKID collection)
- `net-wireless/pixiewps` (offline Pixie-Dust analysis)
- `net-wireless/mdk4` (additional IEEE 802.11/deauthentication backend)
- `net-wireless/bully` (alternative WPS backend)
- `net-analyzer/bettercap` (modular network and wireless auditing framework)

ASUS laptop scope:

- `sys-power/asusctl` and `sys-power/supergfxctl` require `sys-apps/systemd` and
  are intended for ASUS laptops running Gentoo with systemd.
- `app-benchmarks/unigine-superposition` has no ASUS or systemd requirement.

Do not move LinuxMAMEUI/MAME/HBMAME categories casually. The existing local
packaging uses `app-emulation`, and that category exists in the local Gentoo
tree.

Known portability issue:

- `app-emulation/linuxmameui` currently uses `SRC_URI="${P}.tar.gz"` with
  `RESTRICT=fetch`, so every machine needs the same local distfile unless the
  project gets a real release tarball or Git-based live ebuild.

## MAMEUIx (Jul 2026)

- Source repo: `/home/edo/MAMEUIx` → https://github.com/firesand/MAMEUIx
- Overlay ebuilds: `app-emulation/mameuix/mameuix-0.1.6.ebuild` (GitHub tag
  `v0.1.6`, with `CRATES` + `CARGO_CRATE_URIS`) and `mameuix-9999.ebuild`
  (live: `git-r3` + `cargo_live_src_unpack`).
- RDEPEND on `>=app-emulation/mame-0.200` from this overlay. Rust 1.88.0 is
  the minimum because the application uses stabilized `let` chains; edition
  2024 alone would misleadingly suggest Rust 1.85.
- Tag `v0.1.6` exists on GitHub. Manifest for `0.1.6` has 594 DIST entries
  (app tarball + crates). Regenerating Manifest is slow (~593 crate fetches);
  use a writable `DISTDIR` if system `/var/cache/distfiles` is not writable:
  `DISTDIR="$PWD/.distfiles" PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild ... manifest`
- Prefer versioned `=app-emulation/mameuix-0.1.6` when keywords allow; live `9999` still
  works for tracking `main`.

Validation completed on 2026-07-12:

- All 593 registry crates match `Cargo.lock`; size, BLAKE2B, and SHA512 match
  every corresponding Manifest entry. The v0.1.6 source digest also matches.
- Release compile and image install passed. The ebuild uses system xz and zstd
  libraries where supported instead of the crates' bundled copies.
- The ebuild test phase passed all 44 tests. A separate run with the official
  Rust 1.88.0 toolchain also passed 44/44, confirming the declared minimum.
- `desktop-file-validate` passed; all six PNG icon sizes and the scalable SVG
  were installed.
- `cargo.eclass` warns because the package lists 593 crates. A release-provided
  crate tarball would be preferable in the future, but none currently exists.

Install (versioned):

```bash
emerge --sync edorp
echo "=app-emulation/mameuix-0.1.6 ~amd64" | doas tee /etc/portage/package.accept_keywords/edorp-mameuix
doas emerge -av app-emulation/mameuix
```

Install (live):

```bash
echo "=app-emulation/mameuix-9999 **" | doas tee /etc/portage/package.accept_keywords/edorp-mameuix
doas emerge -av =app-emulation/mameuix-9999
```

Portable AppImage (non-Gentoo / no emerge):

- Built from `/home/edo/MAMEUIx` via **CI** `appimage.yml` (ubuntu-22.04, glibc 2.35) — **jangan** build release di Gentoo langsung
- Lokal: `./build-appimage-docker.sh` (butuh docker/podman) atau
  `gh workflow run appimage.yml -f build_tag=v0.1.6 -f upload_to_release=true`
- Asset: `MAMEUIx-<ver>-x86_64.AppImage` di https://github.com/firesand/MAMEUIx/releases
- Bundles MAMEUIx + GUI libs only; **MAME tetap eksternal** (sama model ebuild `RDEPEND`)
- Debian/Ubuntu: MAME biasanya di `/usr/games/mame` — AppImage v0.1.6+
  auto-detect (commit `f7ea45d`).

## Wiflux (Jul 2026)

- Upstream: https://github.com/Leadrogue/Wiflux
- Overlay package: `net-wireless/wiflux/wiflux-1.0.5-r3.ebuild`, keyword
  `~amd64`, based on upstream release `v1.0.5` (2026-07-10).
- Fetch the official sdist `wiflux-1.0.5.tar.gz`, not the wheel or Linux
  installer. Upstream SHA256 is
  `062dcd5ef1caf93890c7e7f055dee117432d6e7d58de2ca40ffdc59185091d7a`.
- Build model: `distutils-r1` + PEP 517/setuptools. `dev-python/pip` is not an
  ebuild dependency. Python runtime dependency is only `dev-python/rich`;
  Python itself must provide `sqlite` and `ssl`.
- Required external tools are `net-wireless/aircrack-ng`,
  `net-wireless/hcxtools`, `net-wireless/iw`, and `sys-apps/iproute2`.
  `hcxtools` became a hard dependency in `-r1` because Wiflux's primary
  handshake detection path has no effective fallback without
  `hcxpcapngtool`.
- Available optional integrations are advertised after install:
  `app-crypt/hashcat`, `net-wireless/reaver`, and
  `net-analyzer/wireshark[tshark]`, plus EDORP packages
  `net-wireless/hcxdumptool`, `net-wireless/pixiewps`,
  `net-wireless/mdk4`, `net-wireless/bully`, and
  `net-analyzer/bettercap`. Do not turn these optional executable backends
  into USE-controlled dependencies merely to remove startup warnings.
- Downstream patch `wiflux-1.0.5-no-apt-prompt-on-non-debian.patch` prevents
  Wiflux from offering its Debian `apt-get` auto-installer on Gentoo. Keep this
  patch until upstream provides distribution-neutral package handling.
- Downstream patch `wiflux-1.0.5-no-runtime-write-to-usr.patch` prevents the
  privileged process from auto-unpacking `rockyou.txt.gz` into package-manager-
  owned `/usr`. Decompress a dictionary to a writable location and pass it via
  `--dict FILE`.
- Downstream test-only patch
  `wiflux-1.0.5-fix-environment-dependent-tests.patch` skips inaccessible
  developer captures under `/root` and mocks the external `airodump-ng`
  process. It does not alter installed runtime behavior.
- Revision `-r2` adds `wiflux-1.0.5-runtime-recovery.patch`. The Python
  runtime identifies itself as `1.0.5.post1+edorp` and includes stable-device
  interface recovery after driver reprobes, Airodump output diagnostics and
  renamed-interface synchronization, newest-CAP selection, Reaver/Bully/Wash
  fatal-signal circuit breakers, Bully PIN flag/routing fixes, a shared WPS
  deadline, and terminal-output sanitization. Its added regression tests bring
  the suite to 143 tests (130 pass, 13 environment-dependent skips).
- The installed `/usr/bin/wiflux` is Portage-owned and intentionally has no
  pip `RECORD`. Never run the upstream `install.sh`, `pip --ignore-installed`,
  or create a fake RECORD against `/usr`; update it with `emerge`. The patched
  standalone installer now detects package-manager ownership and exits safely.
- Revision `-r3` adds `wiflux-1.0.5-restore-network-services.patch`; the
  runtime reports `1.0.5.post2+edorp`. Before `airmon-ng check kill`, Wiflux
  snapshots only active systemd/OpenRC network services, runs conflict cleanup
  once, and restarts that exact set after interface cleanup when `--restore` is
  requested. It refuses destructive cleanup when a required snapshot fails,
  restores on SIGTERM/SIGHUP and setup failures, and uses the current
  post-reprobe interface name. Managed-mode restoration is verified with a
  direct `iw` fallback. Explicit `--dict` paths now fail fast when missing,
  empty, directories, or unreadable instead of silently falling back.
- Wiflux is a privileged wireless auditing tool. Use it only on owned or
  explicitly authorized networks.
- Current Gentoo `net-wireless/aircrack-ng` defaults enable `airdrop-ng` and
  `airgraph-ng`, whose ebuild supports Python 3.11/3.12 but not 3.13/3.14. On
  systems with only Python 3.13/3.14 targets, set
  `net-wireless/aircrack-ng -airdrop-ng -airgraph-ng` in package.use.

Install:

```bash
echo "net-wireless/aircrack-ng -airdrop-ng -airgraph-ng" | doas tee /etc/portage/package.use/edorp-wiflux
echo "=net-wireless/wiflux-1.0.5-r3 ~amd64" | doas tee /etc/portage/package.accept_keywords/edorp-wiflux
echo "=net-wireless/hcxtools-7.1.2 ~amd64" | doas tee -a /etc/portage/package.accept_keywords/edorp-wiflux
doas emerge -av net-wireless/wiflux
```

Validation completed on 2026-07-12:

- Manifest generation and upstream SHA256 comparison passed.
- PEP 517 compile and image install passed for Python 3.13 and 3.14.
- All 116 upstream tests ran on both Python versions; 103 passed and 13 were
  skipped per version because they require local captures or a rockyou
  installation.
- The staged image's `wiflux --help` returned status 0 on both Python versions.
- Dependency resolution passed with the documented `aircrack-ng` USE flags.
- Direct unprivileged `ebuild` runs on this machine need
  `PORTAGE_USERNAME=edo PORTAGE_GRPNAME=edo` because user `edo` is not in the
  `portage` group. The `/etc/gitconfig` permission warning comes from the local
  Portage environment and does not fail the ebuild.

Revision `-r2` validation completed on 2026-07-13:

- The complete `-r1` patch stack plus the runtime-recovery patch applied cleanly
  to the official 1.0.5 sdist.
- The real Portage `test` phase passed for Python 3.13 and 3.14. Each ran all
  143 tests: 130 passed and 13 were skipped for unavailable local captures or
  wordlists.
- The Portage image-install phase passed for both Python implementations. Both
  staged imports, distribution metadata, and `wiflux --help` report
  `1.0.5.post1+edorp` successfully.
- Manifest regeneration and `git diff --check` passed. `pkgcheck`/`repoman`
  were not installed in the active environment for this validation run.
- The failed wheel attempt did not modify the installed package: Portage still
  owned and verified all 396 files of `net-wireless/wiflux-1.0.5`.

Revision `-r3` validation completed on 2026-07-13:

- Unit tests mock all systemd, OpenRC, NetworkManager, `airmon-ng`, and radio
  mutations. The host service state is never changed by the test suite.
- A clean Portage test passed under both Python 3.13 and 3.14: 166 tests per
  implementation, with 153 passing and 13 intentionally skipped.
- The staged Portage image imports successfully and displays CLI help under
  Python 3.13 and 3.14. Package code and installed metadata both report
  `1.0.5.post2+edorp`.
- The standalone post2 wheel passed ZIP/RECORD, isolated import, entry-point,
  CLI-help, and compile checks. SHA256 is
  `578baedd44bc00fec0f07f37c74316eee91c5e05e20a7f9d53d2fb1be90e0d89`.
  The matching installer archive SHA256 is
  `be428e5e8c9061b9b9a5a6d709d2ff9b3493c43ab22dbd7cd1eabdd6756ebb3d`;
  its preflight refuses to overwrite the Portage-owned installation and points
  to `>=net-wireless/wiflux-1.0.5-r3`.
- Active-service snapshot on the affected host identifies both
  `wpa_supplicant.service` and `NetworkManager.service`, in that restore order.
- Thin Manifest regeneration and the final staged diff check passed;
  `pkgcheck`/`repoman` were not installed in the active environment.

## Wiflux support packages (Jul 2026)

- `net-wireless/hcxtools-7.1.2` uses the official release asset and provides
  `hcxpcapngtool`; it is a Wiflux hard dependency.
- `net-wireless/hcxdumptool-7.1.2` uses the matching official release and
  advertises the same-version hcxtools package for capture conversion.
- `net-wireless/pixiewps-1.4.2` uses the official `.tar.xz` release asset and
  exposes an enabled-by-default `openssl` USE flag. Its bundled crypto fallback
  remains buildable with `USE=-openssl`.
- `net-wireless/mdk4-4.2_p20260529` is pinned to upstream commit
  `3e214fc90710c9185f3783783b3b3c6c4e3098c2`. The old 4.2 tag lacks modern
  compiler fixes and has build/data-path defects, so do not replace the
  snapshot with that tag merely because it is labeled a release.
- `net-wireless/bully-2.0_p20260622` is pinned to upstream commit
  `a9ab51b2d66dfd318db9448f25f93b0397e10cf6`. The source snapshot contains a
  tracked prebuilt `src/bully`; the ebuild must remove it before compilation.
  Bully is only used by Wiflux when the operator selects `--bully`.
- `net-analyzer/bettercap-2.41.7` is built from source using `go-module` with
  module distfiles declared in the Manifest so compilation remains offline.
  Bettercap is an alternative deauthentication backend, not a Wiflux hard
  dependency. Its embedded web UI includes Font Awesome assets, so package
  license metadata must include their CC-BY-4.0, OFL-1.1, and MIT terms in
  addition to Bettercap's GPL-3 code.
- Bettercap caplets are pinned to commit
  `eb626871ad99ea8c4f9771f216caa2290e06a058` and installed under
  `/usr/share/bettercap/caplets`. A downstream patch disables
  `caplets.update` and corrects its help text because Portage owns those files;
  keep the patch unless upstream gains a package-manager-safe update mode.
- The Bettercap ebuild temporarily uses deprecated `EGO_SUM`/
  `go-module_set_globals` because EDORP has no immutable location for a
  generated dependency tarball. This is known packaging debt, not a clean
  long-term design. Migrate to a pinned dependency tarball before the eclass
  turns the deprecation into a fatal error.
- Bettercap's `iptables`, `net-tools`, `iproute2`, `iw`, `wireless-tools`, and
  `wpa_supplicant` integrations are runtime capabilities and remain
  `optfeature` suggestions. Do not add stale `libnetfilter_queue` or
  `libnfnetlink` dependencies: the built ELF does not link either library.
- Keep these tools optional by capability. Installing every backend does not
  improve every Wiflux run, and several operations still require a compatible
  monitor-mode adapter, full-frame injection support, and root privileges.

Validation completed on 2026-07-12:

- Bully built and installed through Portage with both `USE=-lua` and
  `USE=lua`. Both staged binaries reported `v2.0-00`; linkage matched the USE
  selection and neither image had an RPATH/RUNPATH. Upstream provides no test
  suite, so validation was limited to build, install, smoke, and ELF checks.
- Bettercap completed a fresh offline Portage build, all `go test ./...`
  tests, and image installation with the downstream caplets patch applied.
  The staged binary reported `v2.41.7`, installed 182 caplet files, linked only
  `libpcap`, `libusb-1.0`, and libc, and had no RPATH/RUNPATH.
- The Bettercap patch passed both `gpatch --dry-run` and `git apply --check`.
  Dependency resolution for Wiflux, hcxtools, Bully, and Bettercap completed
  without backtracking.
- Targeted `pkgcheck scan` found no package-specific issues outside the known
  Bettercap Go-eclass deprecations and Wiflux's informational Python 3.15
  compatibility suggestion.
- No live WPS, PMKID, deauthentication, injection, Bluetooth, or HID operation
  was attempted. Those checks require compatible hardware and an explicitly
  authorized test network.

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
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-portage/equery-gui/equery-gui-0.1.0.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-emulation/linuxmameui/linuxmameui-0.1.0.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-emulation/mame/mame-0.288.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-emulation/hbmame/hbmame-0.288.2.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-emulation/mameuix/mameuix-0.1.6.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-emulation/mameuix/mameuix-9999.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-wireless/hcxtools/hcxtools-7.1.2.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-wireless/hcxdumptool/hcxdumptool-7.1.2.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-wireless/pixiewps/pixiewps-1.4.2.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-wireless/mdk4/mdk4-4.2_p20260529.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-wireless/bully/bully-2.0_p20260622.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-analyzer/bettercap/bettercap-2.41.7.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-wireless/wiflux/wiflux-1.0.5-r1.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-wireless/wiflux/wiflux-1.0.5-r2.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild net-wireless/wiflux/wiflux-1.0.5-r3.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild sys-power/asusctl/asusctl-9999.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild sys-power/supergfxctl/supergfxctl-9999.ebuild clean
PORTAGE_TMPDIR=/home/edo/EDORP/.portage-tmp ebuild app-benchmarks/unigine-superposition/unigine-superposition-1.1.ebuild clean
```

All listed basic parse checks passed after enabling thin manifests and using a
local `PORTAGE_TMPDIR`.

# EDORP Gentoo Overlay

Personal Gentoo overlay for packages maintained or tested by Edo.

## Setup

Register the overlay by copying the repo config:

```bash
doas eselect repository enable guru
doas emerge --sync guru
doas cp metadata/edorp.conf /etc/portage/repos.conf/edorp.conf
```

GURU is a declared master because MarkItDown has mandatory dependencies there.
Existing EDORP installations should copy the updated `metadata/edorp.conf`
again so the active Portage configuration does not override this master list.

The config is:

```ini
[edorp]
location = /var/db/repos/edorp
sync-type = git
sync-uri = https://github.com/firesand/edorp-overlay.git
auto-sync = yes
masters = gentoo guru
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
- `net-misc/plexo`: Plexo download manager with parallel downloads across
  multiple network connections ([source](https://github.com/anmolkapil/plexo)).
  Reuses the upstream application's portable resources with the matching
  official amd64 Electron runtime. Requires glibc and `~amd64` keywording.
- `app-portage/equery-gui`: graphical front-end for `equery`
  ([source](https://github.com/firesand/equery-gui)).
- `gui-apps/walker`: Walker 2.17.0, the Rust/GTK4 rewrite of the Wayland
  application launcher. The ebuild builds entirely from pinned Cargo sources
  and replaces the obsolete Go-based package from GURU.
- `gui-apps/elephant`: Elephant 2.21.0 backend for Walker, built with its Go
  provider plugins in one package to preserve Go plugin ABI compatibility.
- `app-text/markitdown`: Microsoft MarkItDown command-line tool and Python
  library for converting supported documents to Markdown. The base package
  includes HTML, plain text, CSV, JSON, XML/RSS, EPUB, Jupyter notebook, and
  recursive ZIP handling; PDF, DOCX, PPTX, Outlook, and Excel support are
  optional USE flags.
- `dev-python/magika`: AI-based content-type detector required by MarkItDown.
  Both `0.6.3` and `1.0.3` are packaged: MarkItDown pins `magika~=0.6.1`, so
  it keeps resolving to `0.6.3`, while `1.0.3` is available on its own.
- `dev-python/cobble`, `dev-python/mammoth`, `dev-python/pdfplumber`, and
  `dev-python/python-pptx`: optional MarkItDown dependencies for DOCX, PDF,
  and PPTX conversion. `dev-python/mammoth` is packaged at both `1.11.0` and
  `1.12.2` for the same reason (MarkItDown pins `mammoth~=1.11.0`).
- `app-emulation/linuxmameui`: imported from the local LinuxMAMEUI Gentoo
  packaging. This currently uses a local `linuxmameui-0.1.0.tar.gz` distfile
  with `RESTRICT=fetch`, so it is not fully portable across machines until a
  release tarball or Git source URI exists.
- `app-emulation/mame`: MAME 0.288 ebuild imported from local LinuxMAMEUI
  packaging.
- `app-emulation/hbmame`: HBMAME 0.288.2 ebuild imported from local LinuxMAMEUI
  packaging.
- `app-emulation/mameuix`: modern Rust/egui frontend for MAME
  ([source](https://github.com/firesand/MAMEUIx)). Versioned ebuild `0.1.8`
  fetches GitHub tag `v0.1.7` plus crates via `CRATES`; live ebuild `9999`
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
- `net-wireless/hcxtools`: wireless capture conversion and hash-analysis tools,
  including `hcxpcapngtool` required by Wiflux's handshake workflow.
- `net-wireless/hcxdumptool`: monitor-mode capture tool used by Wiflux for
  clientless PMKID collection.
- `net-wireless/pixiewps`: offline WPS Pixie-Dust analysis tool with optional
  OpenSSL acceleration.
- `net-wireless/mdk4`: additional IEEE 802.11 testing and deauthentication
  backend. The ebuild uses a pinned 2026 upstream snapshot because the 4.2
  release tag predates required modern-compiler fixes.
- `net-wireless/bully`: alternative WPS backend. The ebuild uses a pinned
  `2.0_p20260622` snapshot because the last tagged release predates major
  bounds checks, nl80211 support, and current compiler fixes.
- `net-analyzer/bettercap`: modular network reconnaissance and auditing
  framework, built reproducibly from source with offline Go module distfiles.
- `sys-firmware/ds5dongle`: DualSense wireless bridge firmware for the
  Raspberry Pi Pico 2 W
  ([source](https://github.com/awalol/DS5Dongle)). Installs the upstream
  prebuilt UF2 plus the `ds5dongle-config` HID helper. Enable `other-boards`
  for Pico W and Waveshare RP2350B-Plus-W builds.
- `app-emulation/winboat`: WinBoat 0.9.2 prebuilt Electron app that runs
  Windows apps on Linux via Docker/Podman + FreeRDP
  ([upstream](https://www.winboat.app/)).
- `media-gfx/opencadstudio`: OpenCADStudio 2026.37, a Rust/iced 2D/3D CAD
  application with DWG/DXF support
  ([source](https://github.com/HakanSeven12/OpenCADStudio)). The ebuild builds
  from the pinned git tag; Cargo dependencies (crates.io plus the iced/acadrust
  git patches) are fetched and vendored in `src_unpack` because upstream pins
  git revisions that the `CRATES` mechanism cannot express. Requires Rust
  >= 1.92 and `~amd64` keywording (`metadata/package.accept_keywords/edorp-opencadstudio`).
- `app-misc/chatgpt-desktop`: OpenAI's ChatGPT desktop app for Linux,
  repackaged from the upstream `.deb`
  ([upstream](https://developers.openai.com/codex/app)). Bundles the Codex
  agent, its own Node runtime, and ripgrep under
  `/opt/chatgpt-desktop/resources`. Proprietary, so it needs `~amd64`
  keywording plus an `all-rights-reserved` license entry
  (`metadata/package.accept_keywords/edorp-chatgpt-desktop`,
  `metadata/package.license/edorp-chatgpt-desktop`).
- `app-misc/claude-desktop`: Claude Desktop, Anthropic's prebuilt Electron app
  for Claude.ai (Chat, Cowork, and Claude Code)
  ([upstream](https://code.claude.com/docs/en/desktop-linux)). Unpacks the
  upstream `amd64`/`arm64` `.deb` into `/opt/claude-desktop`. Proprietary
  (`LICENSE="Anthropic"`), needs `~amd64` keywording
  (`metadata/package.accept_keywords/edorp-claude-desktop`).
- `app-misc/unsloth-desktop`: Unsloth Desktop (beta), a Tauri app for running
  and training LLMs and diffusion models locally
  ([upstream](https://unsloth.ai/docs/desktop)). Only the desktop shell is
  packaged; the app bootstraps its own PyTorch environment into
  `~/.unsloth/studio` on first launch. Needs `~amd64` keywording
  (`metadata/package.accept_keywords/edorp-unsloth-desktop`).
- `app-text/md2hd`: point it at a markdown file or a folder of notes and it
  draws them as a graph, frontmatter becoming nodes and wikilinks becoming
  edges, served on loopback and read in a browser
  ([source](https://github.com/evan-steinhilb/md2hd)). No npm dependencies;
  needs `~amd64` keywording (`metadata/package.accept_keywords/edorp-md2hd`).
- `media-video/wolfcut`: WolfCut (formerly Concat), a free CapCut-style
  multi-track video editor built on Tauri
  ([source](https://github.com/jub0t/Concat)). Repackaged from the upstream
  release `.deb`; the default USE `system-ffmpeg` swaps the bundled nonfree
  FFmpeg for the system one. Needs `~amd64` keywording
  (`metadata/package.accept_keywords/edorp-wolfcut`).

### Plexo

Plexo `1.0.0_rc7` packages upstream `v1.0.0-rc.7`, a release candidate.
Upstream began publishing native Linux amd64 builds at this release, so the
ebuild now installs the upstream `amd64` `.deb` as shipped, with its own
bundled Electron `39.8.10`, instead of repacking ARM64 resources onto a
separately downloaded runtime. That repack is no longer possible in any case:
`rc.7` added the `koffi` native addon, and the ARM64 `.deb` carries only an
`aarch64` build of it. Requires an amd64/glibc system; musl is not supported.
Before installation the ebuild verifies the bundle against the upstream
lockfile and checks that the runtime and every loadable native addon really
are x86-64.

```bash
sudo cp metadata/package.accept_keywords/edorp-plexo \
  /etc/portage/package.accept_keywords/edorp-plexo
sudo emerge -av net-misc/plexo
```

Launch `plexo` or select Plexo from the desktop menu. The Chromium sandbox
requires unprivileged user namespaces (`CONFIG_USER_NS=y`); the launcher does
not disable the sandbox. Each selected network needs a working route to the
download server. Multiple interfaces alone do not guarantee combined bandwidth.
Updates are managed by Portage.

### WinBoat

WinBoat packages the upstream `winboat-*-x64.tar.gz` release (not a from-source
Electron build). Default USE `docker` pulls in Docker Engine, CLI, and Compose
v2; enable `podman` for the Podman path instead (or in addition). FreeRDP 3.x
with `client`, `X`, and `pulseaudio` is required for RemoteApp windows.

```bash
# If this machine uses the local checkout instead of /var/db/repos/edorp:
doas cp metadata/edorp.local.conf /etc/portage/repos.conf/edorp.conf
doas cp metadata/package.accept_keywords/edorp-winboat \
  /etc/portage/package.accept_keywords/edorp-winboat
doas cp metadata/package.use/edorp-winboat \
  /etc/portage/package.use/edorp-winboat
doas emerge -av app-emulation/winboat
```

After install, ensure Docker is running, add your user to the `docker` group,
re-login, and confirm `docker compose version` works before launching
`winboat`. KVM must be available (`/dev/kvm`). WinBoat does not provide a
Windows license. This package conflicts with `app-emulation/winboat-bin` from
gentoo-zh.

### DS5Dongle

This package ships the upstream release firmware; it does not cross-compile
with the Pico SDK. Flash the Pico 2 W by holding BOOTSEL, connecting USB, and
copying `/usr/share/ds5dongle/ds5-bridge-pico2w.uf2` onto the mounted drive.

```bash
echo "sys-firmware/ds5dongle ~amd64" | doas tee /etc/portage/package.accept_keywords/edorp-ds5dongle
doas emerge -av sys-firmware/ds5dongle
```

After the DualSense is connected through the dongle, adjust settings with
`ds5dongle-config get` / `ds5dongle-config set ...`, or use the upstream web
UI at https://ds5.awalol.eu.org.

### ChatGPT Desktop

Sourced from the versioned APT pool rather than the advertised
`linux/deb/latest/chatgpt_amd64.deb`, which changes in place and so cannot be
pinned by a Manifest. The APT repository and signing key that the upstream
`.deb` installs for background self-updates are deliberately dropped; bump the
ebuild to update instead.

```bash
doas cp metadata/package.accept_keywords/edorp-chatgpt-desktop \
  /etc/portage/package.accept_keywords/edorp-chatgpt-desktop
doas cp metadata/package.license/edorp-chatgpt-desktop \
  /etc/portage/package.license/edorp-chatgpt-desktop
doas emerge -av app-misc/chatgpt-desktop
```

This build ships no setuid `chrome-sandbox`, so the Chromium sandbox relies on
unprivileged user namespaces (`CONFIG_USER_NS=y`). Enable USE `apparmor` to
install the upstream profile that grants the matching `userns` rule. The
bundled Codex agent is separate from `dev-util/codex`.

### Unsloth Desktop

Built from the upstream `.deb` rather than the AppImage so the Tauri binary
keeps its FHS layout: it resolves resources as `<exe dir>/../lib/Unsloth`, and
that `lib` is literal, never `$(get_libdir)`.

```bash
echo "app-misc/unsloth-desktop ~amd64" | doas tee \
  /etc/portage/package.accept_keywords/edorp-unsloth-desktop
doas emerge -av app-misc/unsloth-desktop
```

This installs the GUI only. On first launch the app downloads a private Python
environment (uv, PyTorch, the unsloth wheels — several GB) into
`~/.unsloth/studio`, which portage neither tracks nor removes on unmerge. Its
built-in system-dependency installer only drives `apt`, so on Gentoo it asks
you to install anything missing yourself. Upstream publishes beta releases
several times a day, so expect frequent bumps.

### md2hd

Installed from the npm tarball rather than a git snapshot: upstream publishes
no tags or GitHub releases, and the visualizer under `dist/` is built in a
separate unpublished repository, so the published bundle is the only form
there is to ship.

```bash
echo "app-text/md2hd ~amd64" | doas tee \
  /etc/portage/package.accept_keywords/edorp-md2hd
doas emerge -av app-text/md2hd
```

`md2hd notes/` serves the map on 127.0.0.1:4173 and opens a browser with
`xdg-open`; `--no-open` skips that and `--port N` moves it. Nothing is offered
to the network. `bin/` and `dist/` install under `/usr/share/md2hd` with only a
launcher symlink on PATH, and they have to stay siblings because the script
resolves the app as `<script dir>/../dist`.

### WolfCut

Repackaged from the upstream release `.deb`. Every release so far is an
alpha; tag `v0.2.0-alpha.17` maps to version `0.2.0_alpha17`, and each alpha
reuses the same asset filename, so only the tagged download URL pins the
payload. With the default USE `system-ffmpeg` the bundled FFmpeg build —
nonfree (DeckLink SDK, OpenSSL with GPL) and self-reported unredistributable
— is dropped, and the app falls back to `ffmpeg`/`ffprobe` on PATH, an
upstream-supported mode. The default export preset encodes with libx264, so
`media-video/ffmpeg` needs `x264`. Disabling `system-ffmpeg` keeps upstream's
binaries and additionally requires accepting `all-rights-reserved`
(`metadata/package.license/edorp-wolfcut`).

```bash
sudo cp metadata/package.accept_keywords/edorp-wolfcut \
  /etc/portage/package.accept_keywords/edorp-wolfcut
sudo emerge -av media-video/wolfcut
```

Auto-captions and voice features run through the bundled whisper.cpp CLI and
a statically linked sherpa-onnx runtime; they download Whisper and Kokoro
models on demand at first use, outside portage's control.

### Walker

Walker 2 is a frontend for the separately released Elephant daemon and its
provider modules. Walker 2.17.0 pins Elephant 2.21.0, so the Walker ebuild
depends on that matching Elephant version from EDORP. Elephant always includes
the five providers needed for Walker's normal default query and common
prefixes: desktop applications, calculator, web search, provider list, and
command runner. Standalone dmenu mode still works without a running Elephant
daemon.

Walker 2 is a Rust/GTK4 rewrite, not an in-place update of the Go-based
0.13.26 release in GURU. Back up `~/.config/walker` before upgrading. If Walker
reports configuration or theme errors after the upgrade, temporarily move that
directory aside and rebuild the custom configuration from the installed
defaults in `/etc/xdg/walker`.

Install Walker with:

```bash
echo "gui-apps/walker ~amd64" | doas tee /etc/portage/package.accept_keywords/edorp-walker
echo "gui-apps/elephant ~amd64" | doas tee -a /etc/portage/package.accept_keywords/edorp-walker
doas emerge -av gui-apps/walker
```

Elephant must run with the graphical session's environment. On systemd, enable
the installed user unit without root:

```bash
systemctl --user enable --now elephant.service
```

On a non-systemd desktop, add `/usr/bin/elephant` to the compositor or desktop
session autostart instead. Do not run it as a system-wide service.

Additional Elephant providers are selectable with USE flags. For example,
enable file search, clipboard history, and bookmarks with:

```bash
echo "gui-apps/elephant files clipboard bookmarks" | doas tee /etc/portage/package.use/edorp-elephant
doas emerge -av gui-apps/elephant
```

The `files` provider indexes the home directory when Elephant starts, while
the `clipboard` provider runs a Wayland clipboard watcher. Other optional flags
cover `1password`, `bitwarden`, `bluetooth`, `menus`, `niri`, `playerctl`,
`snippets`, `symbols`, `todo`, `unicode`, `windows`, and `wireplumber`.

Video previews are optional because they require GTK's GStreamer backend and
additional plugins:

```bash
echo "gui-apps/walker gstreamer" | doas tee /etc/portage/package.use/edorp-walker
doas emerge -av gui-apps/walker
```

### Wiflux

The current Gentoo `aircrack-ng` defaults enable two unrelated Python tools
whose ebuild supports Python 3.11/3.12, but not 3.13/3.14. On a system whose
enabled Python targets are only 3.13/3.14, disable those tools before installing
Wiflux:

```bash
echo "net-wireless/aircrack-ng -airdrop-ng -airgraph-ng" | doas tee /etc/portage/package.use/edorp-wiflux
echo "net-wireless/wiflux ~amd64" | doas tee /etc/portage/package.accept_keywords/edorp-wiflux
echo "net-wireless/hcxtools ~amd64" | doas tee -a /etc/portage/package.accept_keywords/edorp-wiflux
doas emerge -av net-wireless/wiflux
```

Wiflux now pulls in `hcxtools` because its primary handshake validation path
does not have a working fallback without `hcxpcapngtool`. `hcxdumptool`,
`pixiewps`, `mdk4`, `bully`, and `bettercap` remain optional capability
packages; install only the workflows you need and accept their `~amd64`
keywords explicitly. Bully is only selected when Wiflux is run with
`--bully`; Bettercap is an alternative deauthentication backend.

Wiflux requires root for monitor mode and packet injection. Use it only on
networks you own or have explicit permission to audit. It will not unpack a
compressed dictionary into `/usr`; decompress it to a writable location and
select it with `--dict FILE`.

### MarkItDown

The versioned `app-text/markitdown-0.1.6` ebuild builds the GitHub release with
Hatchling. It supports Python 3.12 through 3.14. Python 3.14 was smoke-tested
with the CLI, Magika detection, HTML, CSV, and the targeted upstream core tests.

This is deliberately not equivalent to `pip install markitdown[all]`. The
`docx`, `outlook`, `pdf`, `pptx`, `xls`, and `xlsx` USE flags are available.
Audio transcription, YouTube transcription, and Azure converters are not
packaged. They remain excluded to avoid network-backed transcription services
and additional dependency stacks that are outside this overlay's current
scope.

HTML, plain text, CSV, JSON, XML, and ZIP conversion are built into the base
package and need no USE flags. RSS and Atom XML feeds are converted into
structured Markdown; JSON and other XML documents are preserved as plain text.
CSV is converted into a Markdown table, although the upstream converter does
not escape pipes or multiline cells. ZIP entries are converted recursively and
unsupported entries are skipped. Because the upstream ZIP converter reads each
entry fully into memory and has no archive-size or nesting limit, do not process
untrusted or potentially malicious archives.

The overlay's `pdfplumber` package supports the text, word, form, and table
extraction paths used by MarkItDown. Page rasterization through
`Page.to_image()` is deliberately disabled because it requires pypdfium2 and
a bundled PDFium binary; MarkItDown does not use that rendering path.

The mandatory Magika dependency uses ONNX Runtime. `dev-python/markdownify` and
`sci-libs/onnxruntime` currently come from GURU, which is therefore declared as
an EDORP repository master. Enable it before installing or syncing EDORP:

```bash
doas eselect repository enable guru
doas emerge --sync guru
echo "sci-libs/onnxruntime python" | doas tee /etc/portage/package.use/edorp-markitdown
echo "sci-ml/onnx disableStaticReg" | doas tee -a /etc/portage/package.use/edorp-markitdown
doas emerge -av app-text/markitdown
```

Enable optional document formats only when needed:

```bash
echo "app-text/markitdown docx outlook pdf pptx xls xlsx" | doas tee -a /etc/portage/package.use/edorp-markitdown
doas emerge -av app-text/markitdown
```

On a stable-keyword system, review and accept the `~amd64` keywords Portage
requests for MarkItDown, Magika, ONNX Runtime, and its GURU dependencies. The
ONNX Runtime source stack is substantial; a dependency preview currently
reports roughly 453 MiB of source downloads for the base package, or 517 MiB
with `docx pdf pptx` enabled, on amd64.

### Claude Desktop

`app-misc/claude-desktop` repackages Anthropic's official Linux `.deb`
(published in their apt repository) into `/opt/claude-desktop`, with a
`/usr/bin/claude-desktop` launcher, the `com.anthropic.Claude.desktop` menu
entry, and the hicolor icons. The Debian maintainer-script behaviour (writing
an AppArmor profile and registering Anthropic's apt repo + unattended-upgrades
snippet) is intentionally dropped — Portage manages updates. `chrome-sandbox`
is installed setuid-root for the Chromium sandbox helper.

```bash
# Accept keywords and install:
sudo cp metadata/package.accept_keywords/edorp-claude-desktop \
  /etc/portage/package.accept_keywords/edorp-claude-desktop
sudo emerge -av app-misc/claude-desktop
```

Linux support is upstream **beta** and only `amd64`/`arm64` are published.
Optional: `virtual/secret-service` for keyring storage, and `app-emulation/qemu`
plus KVM (`/dev/kvm`, hardware virtualization) for Cowork's sandboxed VM. Sign
in with a Claude.ai subscription or organization SSO (no Console API key); the
app shares `~/.claude` with Claude Code.

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

Install `pkgcheck` and `pkgdev` for local maintenance. Scan the whole overlay
before starting work:

```bash
pkgcheck scan --color false
```

Regenerate only manifests affected by uncommitted ebuild changes. Review the
result before staging it; fetch-restricted packages still require their source
archive to exist in `DISTDIR`:

```bash
pkgdev manifest --if-modified
```

Then stage the complete package change and run the commit-level checks. Include
`.github/upstream-old.json` only when the packaged upstream version changed:

```bash
git diff --check
git add path/to/changed/package
git add .github/upstream-old.json  # only for an accepted upstream bump
pkgcheck scan --staged --color false
pkgdev commit --dry-run
```

For a changed ebuild, parsing is only the minimum check. Run the phases the
package supports, using a local temporary directory when desired:

```bash
mkdir -p .portage-tmp
PORTAGE_TMPDIR="$PWD/.portage-tmp" ebuild category/package/package-version.ebuild clean test install
```

## Maintenance automation

The practical target is detection within 24 hours, a reviewed simple bump
within 72 hours, and a complex bump within seven days. Security fixes and
missing or checksum-changing distfiles are handled immediately.

- Every pull request and push to `main` runs the non-network `pkgcheck`
  Gentoo CI gate against Gentoo and GURU masters.
- Every day at 03:17 WIB, `nvchecker` updates one issue named
  `Overlay update dashboard`. It never changes ebuilds or merges releases.
- Every Sunday at 03:37 WIB, the QA workflow also enables network-backed
  checks. These checks are scheduled rather than required on pull requests
  because upstream availability is not deterministic.
- Dependabot checks the pinned GitHub Actions and the hashed Python watcher
  environment every Monday. The daily dashboard also reports a newer
  `pkgcheck` release so the pinned container digest can be refreshed manually.

After the first successful run on GitHub, protect `main` with a repository
ruleset that requires pull requests plus the `Overlay QA / pkgcheck` and
`Overlay QA / watcher-tests` status checks. Workflow files cannot make their
own checks mandatory.

This CI validates repository metadata; it does not compile every package.
Smoke-build the `9999` ebuilds on a trusted Gentoo host weekly, and
build every changed versioned ebuild before merging it.
GitHub may disable scheduled workflows in an inactive public repository after
60 days, so check the Actions page if the dashboard stops changing.

Treat detections as review work, not mechanical version substitutions.
Walker and Elephant belong in one pull request, as do paired hcxdumptool and
hcxtools releases. Snapshot packages, downstream patches, Cargo/Go dependency
lists, licenses, and Python compatibility require manual inspection. Once a
bump has passed its build tests and QA, update `.github/upstream-old.json` in
the same pull request so the dashboard closes only after the packaged version
really catches up.

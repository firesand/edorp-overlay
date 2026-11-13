# EDORP Gentoo Overlay

Personal Gentoo overlay for packages maintained or tested by Edo.

## Setup

Register the overlay by copying the repo config:

```bash
sudo eselect repository enable guru
sudo emerge --sync guru
sudo cp metadata/edorp.conf /etc/portage/repos.conf/edorp.conf
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

- `games-emulation/shadps4-bin`: official shadPS4 0.21.0 stable amd64 core.
- `games-emulation/shadps4-qtlauncher-bin`: official QtLauncher snapshot
  from 2026-11-06 (`ecc8507`), packaged separately from the emulator core.
  Both packages extract the verified upstream AppImages under `/opt`, so
  neither FUSE nor an AppImage runtime is needed. See the shadPS4 section.
- `net-misc/fluxcast`: imported from the existing FluxCast portable overlay
  bundle.
- `dev-python/pystray`: Fluxcast dependency.
- `dev-python/upnpclient`: Fluxcast dependency.
- `net-misc/plexo`: Plexo download manager with parallel downloads across
  multiple network connections ([source](https://github.com/anmolkapil/plexo)).
  Installs the upstream amd64 `.deb` with its matching bundled Electron
  runtime. Requires glibc and `~amd64` keywording.
- `net-misc/misterdownloadmanager`: Mister Download Manager, the Rust/egui
  download manager laid out like Internet Download Manager, from the
  [firesand fork](https://github.com/firesand/misterdownloadmanager) of
  [upstream](https://github.com/anefzaoui/misterdownloadmanager). The fork's
  `combined` branch adds Plexo's Combine networks and Usenet (NZB) downloads
  to upstream's `main` branch. Live ebuild `9999` only (`git-r3` +
  `cargo_live_src_unpack`); building needs Rust >= 1.98, CMake and clang.
  See the Mister Download Manager section.
- `games-util/dlss-updater`: DLSS, XeSS and FSR DLL updater for Linux games
  ([source](https://github.com/Recol/DLSS-Updater#linux)). Repackages the
  upstream amd64 Flatpak executable with its Flet client for native Gentoo
  use; no Flatpak runtime is installed. Requires glibc and `~amd64`.
- `games-util/goverlay`: Goverlay 1.9.4 Qt6 GUI for configuring MangoHud,
  vkBasalt, vkSumi, OptiScaler, Lossless Scaling (`lsfg-vk`), per-game `bgmod`
  wrappers, and the integrated PasCube Vulkan/CPU benchmark with PascubeDB
  leaderboard uploads ([source](https://github.com/benjamimgois/goverlay)).
  Built from source with Lazarus/FPC and replaces the older 1.2 package in
  GURU. Needs `~amd64` keywording
  (`metadata/package.accept_keywords/edorp-goverlay`).
- `app-portage/equery-gui`: graphical front-end for `equery`
  ([source](https://github.com/firesand/equery-gui)).
- `sys-kernel/kernelsmith`: guided, hardware-aware custom kernel builder with
  a Steam-style GUI ([source](https://github.com/firesand/kernelsmith)).
  Live ebuild `9999` only (`git-r3` + `cargo_live_src_unpack`); see the
  Kernelsmith section.
- `gui-apps/walker`: Walker 2.17.2, the Rust/GTK4 rewrite of the Wayland
  application launcher. The ebuild builds entirely from pinned Cargo sources
  and replaces the obsolete Go-based package from GURU.
- `gui-apps/elephant`: Elephant 2.22.1 backend for Walker, built with its Go
  provider plugins in one package to preserve Go plugin ABI compatibility.
  Builds with Go >= 1.26 (see the Walker section).
- `app-text/markitdown`: Microsoft MarkItDown command-line tool and Python
  library for converting supported documents to Markdown. The base package
  includes HTML, plain text, CSV, JSON, XML/RSS, EPUB, Jupyter notebook, and
  recursive ZIP handling; PDF, DOCX, PPTX, Outlook, and Excel support are
  optional USE flags.
- `dev-python/magika`: AI-based content-type detector required by MarkItDown.
  Both `0.6.3` and `1.0.3` are packaged. MarkItDown 0.1.9 widened its pin to
  `magika<2`, so either satisfies it; `0.6.3` is kept because it is the
  version in use on existing installs.
- `dev-python/cobble`, `dev-python/mammoth`, `dev-python/pdfplumber`, and
  `dev-python/python-pptx`: optional MarkItDown dependencies for DOCX, PDF,
  and PPTX conversion. `dev-python/mammoth` is packaged only at `1.13.0`:
  MarkItDown 0.1.9 raised its pin to `mammoth>=1.12.2`, so the previously
  retained `1.11.0` could no longer satisfy anything and was dropped.
- `app-emulation/linuxmameui`: imported from the local LinuxMAMEUI Gentoo
  packaging. This currently uses a local `linuxmameui-0.1.0.tar.gz` distfile
  with `RESTRICT=fetch`, so it is not fully portable across machines until a
  release tarball or Git source URI exists.
- `app-emulation/mame`: MAME 0.289-r1 ebuild imported from local LinuxMAMEUI
  packaging.
- `app-emulation/hbmame`: HBMAME 0.289.4 ebuild imported from local LinuxMAMEUI
  packaging.
- `app-emulation/mameuix`: modern Rust/egui frontend for MAME
  ([source](https://github.com/firesand/MAMEUIx)). Versioned ebuild `0.1.8`
  fetches GitHub tag `v0.1.8` plus crates via `CRATES`; live ebuild `9999`
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
- `media-gfx/opencadstudio`: OpenCADStudio 2026.43, a Rust/iced 2D/3D CAD
  (held: upstream's `acadrust` git dependency is no longer reachable, so no
  version currently builds from source — see memory.md for the 2026-11-06 audit)
  application with DWG/DXF support
  ([source](https://github.com/HakanSeven12/OpenCADStudio)). The ebuild builds
  from the pinned git tag; Cargo dependencies (crates.io plus the iced and
  opencadcodec/opencadkernel/opencadgraph git dependencies) are fetched and
  vendored in `src_unpack` because upstream pins git revisions that the
  `CRATES` mechanism cannot express. Requires Rust >= 1.92 and `~amd64`
  keywording (`metadata/package.accept_keywords/edorp-opencadstudio`).
- `media-gfx/photocraft-ai`: PhotoCraft AI 0.19.0 beta 2 (`v0.19.0-ai-beta.2`),
  an unofficial community fork of the Rust PhotoCraft image editor with AI
  editing built into the interface
  ([source](https://github.com/BLEZZ0102/photocraft-ai)). Upstream only
  publishes Windows binaries, so the ebuild builds the pinned git tag from
  source; Cargo dependencies come from `CRATES` plus `GIT_CRATES` for
  upstream's egui, winit, craft-libs and winprint forks. Requires Rust >= 1.95
  and `~amd64` keywording
  (`metadata/package.accept_keywords/edorp-photocraft-ai`). The live `9999`
  ebuild builds the `ai-main` branch of the
  [firesand fork](https://github.com/firesand/photocraft-ai), which adds
  OpenAI-compatible and ComfyUI image services. See the PhotoCraft AI section.
- `media-gfx/photon-studio`: Photon Studio 0.1.69, Tenzen Studio's offline image
  editor with layers, retouching and PSD support
  ([upstream](https://tenzen.studio/photon/)). The ebuild extracts the pinned
  Linux x64 Flatpak release and launches its bundled Electron application
  natively. It bundles local AI models for background removal, object and sky
  selection plus HEIF, JPEG XL and RAW decoders, so it installs to about
  1.1 GB. Requires glibc, `~amd64` keywording and acceptance of the
  proprietary app and bundled model licenses.
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
- `app-misc/comfy-desktop`: Comfy Desktop, Comfy Org's official app for
  installing and running ComfyUI
  ([upstream](https://www.comfy.org/download)). Unpacks the upstream amd64
  `.deb` into `/opt/comfy-desktop`; the ComfyUI environments it provisions
  live in your home directory, outside Portage. AGPL-3.0-or-later (upstream
  also sells a commercial licence), needs `~amd64` keywording
  (`metadata/package.accept_keywords/edorp-comfy-desktop`).
- `app-misc/grok-bot`: Grok Bot, SpaceXAI's desktop client for persistent cloud
  AI agents ([docs](https://docs.x.ai/grok-bot/get-started)). Repackages the
  immutable-build `amd64`/`arm64` `.deb` from the vendor's release feed into
  `/opt/grok-bot`. Proprietary: needs `~amd64` keywording, an
  `all-rights-reserved` licence entry
  (`metadata/package.accept_keywords/edorp-grok-bot`,
  `metadata/package.license/edorp-grok-bot`) and an eligible Cursor or SuperGrok
  account. `USE=suid` installs the setuid Chromium sandbox helper and
  `USE=apparmor` the vendor's profile.
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
- `net-im/zapfast`: ZapFast 0.21.1, an unofficial native WhatsApp client
  built with Rust and egui ([source](https://github.com/crmne/zapfast)).
  Built from pinned Cargo and git sources; needs `~amd64` keywording
  (`metadata/package.accept_keywords/edorp-zapfast`). Using an unofficial
  client may violate WhatsApp's terms and could put the linked account at risk.
- `media-video/wolfcut`: Concat (formerly WolfCut), a multi-track video
  editor built with Slint ([source](https://github.com/jub0t/Concat)).
  Repackaged from the upstream amd64 `.deb`; the default `system-ffmpeg`
  USE flag selects matching FFmpeg 8.1 libraries. The package atom remains
  `wolfcut` for existing installations; the application now launches as
  `concat`, with `wolfcut-desktop` retained as an alias.

### Packages shared with other overlays

A few EDORP packages use the same category and name as ebuilds in other
repositories: `app-misc/claude-desktop` and `app-misc/chatgpt-desktop`
(gentoo-zh), and `gui-apps/walker` and `games-util/goverlay` (GURU, where GURU
carries older releases lacking the Rust rewrite or the integrated PasCube
benchmark and `bgmod` wrapper). That is deliberate and needs no per-version
pinning, because Portage compares versions across all repositories before it
looks at priority:

- When EDORP carries the newer version, `emerge -u` moves an existing
  gentoo-zh or GURU install over to EDORP's ebuild. When the other overlay
  publishes a newer release, Portage switches back.
- Priority only breaks ties between identical versions. EDORP's
  `priority = 70` beats overlays that set none, such as gentoo-zh, so with
  equal versions EDORP's ebuild is the one installed. Giving the other overlay
  a higher priority does not let its older version win.

To keep the other overlay's copy instead, mask the EDORP one with a
repository-qualified atom:

```bash
echo "app-misc/chatgpt-desktop::edorp" | sudo tee -a \
  /etc/portage/package.mask/edorp-overlap
```

Portage then resolves to the other overlay's ebuild, as a downgrade if a newer
EDORP build is already installed.

### DLSS Updater

```bash
sudo cp metadata/package.accept_keywords/edorp-dlss-updater \
  /etc/portage/package.accept_keywords/edorp-dlss-updater
sudo emerge -av games-util/dlss-updater
```

Run `dlss-updater` or use the desktop entry. The GUI client is installed with
the package; the game DLL catalogue and selected DLLs are fetched by the app
into your user cache on first use.

### Goverlay

```bash
sudo cp metadata/package.accept_keywords/edorp-goverlay \
  /etc/portage/package.accept_keywords/edorp-goverlay
sudo emerge -av games-util/goverlay
```

Run `goverlay` or launch it from the desktop entry. Click **Preview (PasCube)**
to open the integrated PasCube Vulkan/CPU benchmark and submit scores to
[PascubeDB](https://benjamimgois.github.io/PascubeDB/).

### Photon Studio

```bash
sudo cp metadata/package.accept_keywords/edorp-photon-studio \
  /etc/portage/package.accept_keywords/edorp-photon-studio
sudo cp metadata/package.license/edorp-photon-studio \
  /etc/portage/package.license/edorp-photon-studio
sudo emerge -av media-gfx/photon-studio
```

Run `photon-studio` or use the Photon Studio menu entry. This package uses
host libraries with the upstream Electron application; it does not install a
Flatpak runtime. Application updates are delivered through Portage. Its
background-removal model is **Built with DINOv3**; the DINOv3 agreement is
installed with the package. The other bundled models (SAM 2.1, DETR, Depth
Anything V2 Small and the LaMa inpainting model behind Remove and Content-Aware
Fill) are Apache-2.0, and HEIF decoding uses LGPL-3 libheif and libde265,
whose source archives ship inside the app directory. The native RAW decoder
needs glibc 2.39 or newer.

### PhotoCraft AI

```bash
sudo cp metadata/package.accept_keywords/edorp-photocraft-ai \
  /etc/portage/package.accept_keywords/edorp-photocraft-ai
sudo emerge -av media-gfx/photocraft-ai
```

PhotoCraft AI is a community fork of PhotoCraft by BLEZZ0102, not an official
ArtCraft release. Upstream publishes Windows MSI/portable builds only, so this
package compiles the tagged source with Rust >= 1.95. The `heif` USE flag is
on by default to match the official builds; it uses the pure-Rust `heic-rs`
decoder and adds no system library.

It installs `photocraft`, `photocraft-cli` (with man pages and bash, zsh and
fish completions), the `ai.storyteller.photocraft` desktop entry, MIME types,
AppStream metadata and icons. Those are the same names an official PhotoCraft
package would use, so the two cannot be installed together; no such package
exists in any configured repository today.

AI editing has two paths:

- ChatGPT subscription: runs through the Codex CLI, found via `PATH` or
  `PHOTOCRAFT_CODEX_PATH`. Upstream only validates this path on Windows.
- Gemini (Nano Banana), FLUX and Seedream: use your own API keys, stored
  through the Secret Service API (KWallet or GNOME Keyring).

Both send the image and prompt to the selected online service.

The live ebuild builds the `ai-main` branch of
[firesand/photocraft-ai](https://github.com/firesand/photocraft-ai), which adds
two more services:

- OpenAI-compatible / local server: the OpenAI Images edit API, or any gateway
  or local server that speaks it.
- ComfyUI (local workflow): runs a workflow exported from ComfyUI with
  Export (API), with `{{image}}` and `{{prompt}}` placeholders, saved under
  `~/.config/photocraft-ai/comfyui-workflows/<name>.json`.

API keys are optional for `localhost`/`127.0.0.1` addresses. See
`docs/ai-beta.md` in the fork for the details.

```bash
echo "=media-gfx/photocraft-ai-9999 **" | \
  sudo tee /etc/portage/package.accept_keywords/edorp-photocraft-ai-live
sudo emerge -av =media-gfx/photocraft-ai-9999
```

The fork's one-click updater only runs on Windows, so Portage handles updates. Windowing
and GPU libraries (X11/Wayland, xkbcommon, Vulkan or EGL) are loaded at runtime;
start with `photocraft --safe-gpu` to fall back to CPU rendering if the GPU
path fails.

Claude cannot generate or edit pixels, so it is not an image backend here. It
can drive the editor instead (crop, select, adjust, mask, export) through
PhotoCraft's MCP server. Start the app with its control server, which also
makes it a separate process from the normal launcher:

```bash
photocraft --control 47219 \
  --control-token-file ~/.config/photocraft-ai/control.token \
  --automation-read-root ~/Pictures --automation-write-root ~/Pictures
```

Then register the bridge in Claude Code (Claude Desktop takes the same command
and arguments under `mcpServers` in `~/.config/Claude/claude_desktop_config.json`):

```bash
claude mcp add --scope user photocraft -- /usr/bin/photocraft-cli mcp \
  --bridge 127.0.0.1:47219 \
  --control-token-file ~/.config/photocraft-ai/control.token
```

The app creates the token file with mode 0600 on first start. Automation can
only open and save files under the read and write roots.

### Plexo

Plexo `1.0.0_rc15` packages upstream `v1.0.0-rc.15`, a release candidate.
Upstream began publishing native Linux amd64 builds at rc7, so the
ebuild installs the upstream `amd64` `.deb`, with its own
bundled Electron `44.4.4`, instead of repacking ARM64 resources onto a
separately downloaded runtime. That repack is no longer possible in any case:
`rc.7` added the `koffi` native addon, and the ARM64 `.deb` carries only an
`aarch64` build of it. Requires an amd64/glibc system; musl is not supported.
Before installation the ebuild verifies the bundle against the upstream
lockfile and checks that the runtime and every loadable native addon really
are x86-64. The torrent engine added in `rc.13` ships its native addons
(`bufferutil`, `utf-8-validate`, `utp-native`, `fs-native-extensions`) for
every platform; only the glibc `linux-x64` builds are installed.

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

### Mister Download Manager

Live-only: the ebuild builds the `combined` branch of
[firesand/misterdownloadmanager](https://github.com/firesand/misterdownloadmanager)
and fetches its crates during unpack. The fork's `main` mirrors upstream
[Mister Download Manager](https://github.com/anefzaoui/misterdownloadmanager);
`combined` is upstream's `main` branch, its development between releases
(0.5.2 plus 114 commits on 2026-11-13, so newer than any release), plus:

- Combine networks (Downloads → Combine networks…): a file download goes
  through several networks at once, such as Ethernet and Wi-Fi, each with its
  own connections, name, speed limit and data allowance per day, week or
  month. A video that comes as one file is combined too. Also
  `misterdownloadmanager-cli get <url> --combine eno2,wlan0`, and
  `video-get` with the same option.
- Usenet: Tasks → Open NZB file… downloads an NZB's files from the news
  server set in Tasks → Usenet server….
- One fix: the clipboard watch's log warning each second.

```bash
echo "=net-misc/misterdownloadmanager-9999 **" | sudo tee \
  /etc/portage/package.accept_keywords/edorp-misterdownloadmanager
sudo emerge -av net-misc/misterdownloadmanager
```

It installs `misterdownloadmanager`, `misterdownloadmanager-cli`,
`misterdownloadmanager-mcp` and the browsers' helper
`misterdownloadmanager-nmhost`, a desktop entry (magnet links, `.torrent` and
`.nzb` files) and the icon. The native messaging manifests for Chrome,
Chromium, Edge and Firefox are installed for every user, as upstream's `.deb`
and `.rpm` do, so the store's extension finds the program; an unpacked copy of
the extension is in `/usr/share/misterdownloadmanager/`. These are the names
an upstream package would use, so the two cannot be installed together; no
such package exists in this overlay or its masters. Updates come through
Portage: the program's own Update now leaves a copy in `/usr/bin` alone.

The release profile uses fat LTO in one codegen unit: the build took about
eight minutes on an i9-14900K and needs about 4 GiB of disk. It builds
BoringSSL from source for the engine's browser-like connection, which is why
CMake and clang (for libclang, one of LLVM 20 to 22: `llvm_slot_*`) are build
dependencies. yt-dlp, ffmpeg, gallery-dl and Node.js are optional;
`pkg_postinst` lists what each one unlocks.

Combine networks covers file downloads and videos that come as one file. A
video in pieces (HLS, DASH), a gallery's pictures, FTP and a site that only
lets a browser-like connection through use the first ticked network;
torrents, and what yt-dlp and gallery-dl fetch themselves, use the single
adapter of Options → Proxy / Socks. Each combined network needs its own
working route to the server.

### WinBoat

WinBoat packages the upstream `winboat-*-x64.tar.gz` release (not a from-source
Electron build). Default USE `docker` pulls in Docker Engine, CLI, and Compose
v2; enable `podman` for the Podman path instead (or in addition). FreeRDP 3.x
with `client`, `X`, and `pulseaudio` is required for RemoteApp windows.

```bash
# If this machine uses the local checkout instead of /var/db/repos/edorp:
sudo cp metadata/edorp.local.conf /etc/portage/repos.conf/edorp.conf
sudo cp metadata/package.accept_keywords/edorp-winboat \
  /etc/portage/package.accept_keywords/edorp-winboat
sudo cp metadata/package.use/edorp-winboat \
  /etc/portage/package.use/edorp-winboat
sudo emerge -av app-emulation/winboat
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
echo "sys-firmware/ds5dongle ~amd64" | sudo tee /etc/portage/package.accept_keywords/edorp-ds5dongle
sudo emerge -av sys-firmware/ds5dongle
```

After the DualSense is connected through the dongle, adjust settings with
`ds5dongle-config get` / `ds5dongle-config set ...`, or use the upstream web
UI at https://ds5.awalol.eu.org.

### ChatGPT Desktop

Sourced from the versioned APT pool rather than the advertised
`linux/deb/latest/chatgpt_amd64.deb`, which changes in place and so cannot be
pinned by a Manifest. The APT repository and signing key that the upstream
`.deb` installs for background self-updates are deliberately dropped; bump the
ebuild to update instead. gentoo-zh ships an ebuild with the same name; see
[Packages shared with other overlays](#packages-shared-with-other-overlays).

```bash
sudo cp metadata/package.accept_keywords/edorp-chatgpt-desktop \
  /etc/portage/package.accept_keywords/edorp-chatgpt-desktop
sudo cp metadata/package.license/edorp-chatgpt-desktop \
  /etc/portage/package.license/edorp-chatgpt-desktop
sudo emerge -av app-misc/chatgpt-desktop
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
echo "app-misc/unsloth-desktop ~amd64" | sudo tee \
  /etc/portage/package.accept_keywords/edorp-unsloth-desktop
sudo emerge -av app-misc/unsloth-desktop
```

This installs the GUI only. On first launch the app downloads a private Python
environment (uv, PyTorch, the unsloth wheels — several GB) into
`~/.unsloth/studio`, which portage neither tracks nor removes on unmerge. Its
built-in system-dependency installer only drives `apt`, so on Gentoo it asks
you to install anything missing yourself. Upstream publishes beta releases
several times a day, so expect frequent bumps.

### Comfy Desktop

Sourced from ToDesktop's immutable per-build URL
(`comfyui-desktop-<version>-build-<id>-amd64.deb`) rather than the advertised
`download.comfy.org/linux/deb/x64`, which is a redirect to whatever is newest
and so cannot be pinned by a Manifest. Each release changes the build id, which
the ebuild keeps in `BUILD_ID`; `latest-linux.yml` in the same directory lists
the current one together with a sha512 for the `.deb`.

```bash
sudo cp metadata/package.accept_keywords/edorp-comfy-desktop \
  /etc/portage/package.accept_keywords/edorp-comfy-desktop
sudo emerge -av app-misc/comfy-desktop
```

This installs the desktop shell only. On first launch the app downloads a
standalone ComfyUI environment (about 5 GB with PyTorch) into
`~/ComfyUI-Installs`, with settings under `~/.config/comfyui-desktop-2` and
`~/.local/share/comfyui-desktop-2`; Portage neither tracks nor removes them.
In-app updating is disabled for non-AppImage installs, so update the shell by
bumping the ebuild. The launcher is `comfyui-desktop-2`, upstream's name.

### md2hd

Installed from the npm tarball rather than a git snapshot: upstream publishes
no tags or GitHub releases, and the visualizer under `dist/` is built in a
separate unpublished repository, so the published bundle is the only form
there is to ship.

```bash
echo "app-text/md2hd ~amd64" | sudo tee \
  /etc/portage/package.accept_keywords/edorp-md2hd
sudo emerge -av app-text/md2hd
```

`md2hd notes/` serves the map on 127.0.0.1:4173 and opens a browser with
`xdg-open`; `--no-open` skips that and `--port N` moves it. Nothing is offered
to the network. `bin/` and `dist/` install under `/usr/share/md2hd` with only a
launcher symlink on PATH, and they have to stay siblings because the script
resolves the app as `<script dir>/../dist`.

### Concat (media-video/wolfcut)

Since version 0.2.3, Concat's Slint interface replaces WolfCut's Tauri
interface.
The application is now AGPL-3.0-or-later with an upstream plugin exception;
its Slint component uses GPL-3.0, the embedded font uses OFL-1.1, and effect
preview photographs use the Unsplash license. License texts and upstream
notices are installed with the package.

The prebuilt amd64 application requires glibc >=2.35. If your license policy
excludes Unsplash, review `/var/db/repos/gentoo/licenses/Unsplash` before
copying the supplied acceptance entry below.

The binary links FFmpeg libraries directly. With the default `system-ffmpeg`
USE flag, it uses system FFmpeg >=8.1 with ABI `60.62.62` and `x264` enabled.
Disabling that flag retains upstream's GPL FFmpeg libraries. The earlier
nonfree FFmpeg bundle and its `all-rights-reserved` acceptance are no longer
needed. ONNX Runtime remains bundled beside the application.

```bash
sudo cp metadata/package.accept_keywords/edorp-wolfcut \
  /etc/portage/package.accept_keywords/edorp-wolfcut
sudo cp metadata/package.license/edorp-wolfcut \
  /etc/portage/package.license/edorp-wolfcut
sudo emerge -av media-video/wolfcut
```

Launch `concat` or the Concat menu entry; `wolfcut-desktop` is a compatibility
alias. Back up existing projects before opening them in this rewritten
application. Speech and cutout features download models on demand, outside
Portage's control.

### Walker

Walker 2 is a frontend for the separately released Elephant daemon and its
provider modules. EDORP pairs Walker 2.17.2 with Elephant 2.22.1, which upstream
released together; the Walker ebuild pins that packaged Elephant version.
Elephant always includes
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
echo "gui-apps/walker ~amd64" | sudo tee /etc/portage/package.accept_keywords/edorp-walker
echo "gui-apps/elephant ~amd64" | sudo tee -a /etc/portage/package.accept_keywords/edorp-walker
sudo emerge -av gui-apps/walker
```

Elephant 2.22.1's `go.mod` asks for Go 1.27.1, which Gentoo only offers as
`~amd64` and whose upgrade would rebuild every Go package on the system. The
ebuild relaxes that directive to 1.26.0 instead and builds with Go 1.26: the
vendored dependencies need nothing newer, and the main binary, all provider
plugins and the test suite build and pass there. That is not a toolchain
upstream ships, so each bump re-checks it, and the ebuild stops with an error
if the directive ever changes.

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
echo "gui-apps/elephant files clipboard bookmarks" | sudo tee /etc/portage/package.use/edorp-elephant
sudo emerge -av gui-apps/elephant
```

The `files` provider indexes the home directory when Elephant starts, while
the `clipboard` provider runs a Wayland clipboard watcher. Other optional flags
cover `1password`, `bitwarden`, `bluetooth`, `menus`, `niri`, `playerctl`,
`snippets`, `symbols`, `todo`, `unicode`, `windows`, and `wireplumber`.

Video previews are optional because they require GTK's GStreamer backend and
additional plugins:

```bash
echo "gui-apps/walker gstreamer" | sudo tee /etc/portage/package.use/edorp-walker
sudo emerge -av gui-apps/walker
```

### Wiflux

The current Gentoo `aircrack-ng` defaults enable two unrelated Python tools
whose ebuild supports Python 3.11/3.12, but not 3.13/3.14. On a system whose
enabled Python targets are only 3.13/3.14, disable those tools before installing
Wiflux:

```bash
echo "net-wireless/aircrack-ng -airdrop-ng -airgraph-ng" | sudo tee /etc/portage/package.use/edorp-wiflux
echo "net-wireless/wiflux ~amd64" | sudo tee /etc/portage/package.accept_keywords/edorp-wiflux
echo "net-wireless/hcxtools ~amd64" | sudo tee -a /etc/portage/package.accept_keywords/edorp-wiflux
sudo emerge -av net-wireless/wiflux
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

The versioned `app-text/markitdown-0.1.8` ebuild builds the GitHub release with
Hatchling. It supports Python 3.13 and 3.14. Python 3.14 was smoke-tested
with the CLI, Magika detection, HTML, CSV, and the targeted upstream core tests.

MarkItDown 0.1.8 still requires Magika below 0.7 and, for DOCX, Mammoth below
1.12. The overlay keeps Magika 0.6.3 and Mammoth 1.11.0 for those dependencies.
Let Portage select the compatible versions; do not force the newest Magika
or Mammoth into the same installation as MarkItDown.

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
sudo eselect repository enable guru
sudo emerge --sync guru
echo "sci-libs/onnxruntime python" | sudo tee /etc/portage/package.use/edorp-markitdown
echo "sci-ml/onnx disableStaticReg" | sudo tee -a /etc/portage/package.use/edorp-markitdown
sudo emerge -av app-text/markitdown
```

Enable optional document formats only when needed:

```bash
echo "app-text/markitdown docx outlook pdf pptx xls xlsx" | sudo tee -a /etc/portage/package.use/edorp-markitdown
sudo emerge -av app-text/markitdown
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
is installed setuid-root for the Chromium sandbox helper. gentoo-zh ships an
ebuild with the same name; see
[Packages shared with other overlays](#packages-shared-with-other-overlays).

```bash
# Accept keywords and install:
sudo cp metadata/package.accept_keywords/edorp-claude-desktop \
  /etc/portage/package.accept_keywords/edorp-claude-desktop
sudo emerge -av app-misc/claude-desktop
```

Linux support is upstream **beta** and only `amd64`/`arm64` are published.
Since 2.19675.1 the native addon links `media-video/pipewire` for Wayland
screen sharing, and since 2.31226.1 it needs glibc 2.34 or newer. Optional: `virtual/secret-service`
for keyring storage, `media-libs/libpulse` for microphone capture, and
`app-emulation/qemu` plus KVM (`/dev/kvm`, hardware virtualization) for
Cowork's sandboxed VM. Sign
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
echo "=sys-power/asusctl-9999 **" | sudo tee /etc/portage/package.accept_keywords/edorp-asus
echo "=sys-power/supergfxctl-9999 **" | sudo tee -a /etc/portage/package.accept_keywords/edorp-asus
echo "sys-power/asusctl gui" | sudo tee /etc/portage/package.use/edorp-asus
```

### shadPS4

The core package follows stable upstream releases (currently **0.21.0**).
QtLauncher publishes rolling prerelease snapshots; its ebuild pins the
2026-10-26 release commit and includes the full UTC commit timestamp in its
version. Both packages require glibc >= 2.38; the core requires an
x86-64-v3 (AVX2-era) CPU. A Vulkan-capable GPU
and driver are required; game compatibility varies.

```bash
sudo cp metadata/package.accept_keywords/edorp-shadps4 /etc/portage/package.accept_keywords/
# Review licenses/FraunhoferFDK in the Gentoo repository, then accept if appropriate:
sudo cp metadata/package.license/edorp-shadps4 /etc/portage/package.license/
sudo emerge -av games-emulation/shadps4-qtlauncher-bin::edorp
```

The launcher pulls in `games-emulation/shadps4-bin`. Run `shadps4`, open
**Version Manager**, add a custom version pointing to `/usr/bin/shadps4-core`,
and select it. `shadps4-core -b` starts the core's Big Picture interface.
Use Portage to update these packages and disable automatic AppImage update
checks in the launcher. Versions downloaded separately through Version
Manager remain outside Portage's control.

Existing games, modules, saves and settings stay in the user's directories.
No firmware or games are downloaded by the ebuilds. They preserve the upstream
binary and private runtime, fetch pinned source archives for available notices,
and disable mirroring/binary-package redistribution; those archives are not a
complete corresponding-source bundle for all linked libraries.

If migrating from a manual installation, check `command -v shadps4` and
`command -v shadps4-core`: older `~/.local/bin` wrappers and user desktop
entries can take precedence over the system package. Keep the previous
core available until the games you use have been checked on the new version.

### Kernelsmith

Live-only for now: there is no tagged release yet, so the ebuild builds `main`
of `firesand/kernelsmith` and fetches its crates during unpack.

```bash
echo "=sys-kernel/kernelsmith-9999 **" | sudo tee \
  /etc/portage/package.accept_keywords/edorp-kernelsmith
sudo emerge -av sys-kernel/kernelsmith
```

It needs full kernel sources (`sys-kernel/gentoo-sources`, or
`sys-kernel/cachyos-sources` from the CachyOS-kernels overlay); the `*-dist`
trees that distribution kernels install only hold headers. Builds, installs
and uninstalls run as root through `pkexec` (the package installs a polkit
action for a clear prompt), `installkernel` generates the initramfs and updates
the bootloader, and every kernel it installs is recorded in
`/var/lib/kernelsmith/kernels`. Unmerging the package leaves those kernels in
place, so remove them from the app's Library page first if you want them gone.
Clang/LLD, pahole, perf, modprobed-db and scx are optional; `pkg_postinst`
lists what each one unlocks.

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

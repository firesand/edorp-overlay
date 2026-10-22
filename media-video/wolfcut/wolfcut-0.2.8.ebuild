# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop optfeature unpacker xdg

DESCRIPTION="Concat multi-track video editor (formerly WolfCut)"
# Upstream has renamed this repository twice (Concat -> concat -> Concat), and
# the capitalisation decides the tag archive's top-level directory. Pin the
# canonical name rather than relying on GitHub's rename redirect, and keep the
# unpacked directory in MY_S so a future flip is a one-line change.
HOMEPAGE="https://github.com/jub0t/Concat"
MY_S="Concat-${PV}"
SRC_URI="
	https://github.com/jub0t/Concat/releases/download/v${PV}/Concat-${PV}-linux-x86_64.deb
		-> ${P}.deb
	https://github.com/jub0t/Concat/archive/refs/tags/v${PV}.tar.gz
		-> concat-${PV}.tar.gz
"
S="${WORKDIR}"

# Concat switched from Tauri/MPL to Slint/AGPL. Slint uses its GPL option;
# the embedded fonts and effect-preview photograph have separate licenses.
# 0.2.8 grew the bundled font set from one to 37 faces: 35 carry the SIL Open
# Font License and two the Apache License, both already listed below, so the
# identifiers are unchanged. 0.2.8 also dropped LICENSE-EXCEPTIONS.md.
# The new bundled FFmpeg reports GPL-3+, without --enable-nonfree.
LICENSE="AGPL-3+ Apache-2.0 BSD BSD-2 GPL-3 GPL-3+ ISC MIT OFL-1.1 Unsplash"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="+system-ffmpeg"
RESTRICT="bindist mirror strip"

# The binary links FFmpeg 8.1 libraries directly. Pin the ABI instead of
# relying on ffmpeg/ffprobe executables as the old Tauri application did.
RDEPEND="
	dev-libs/wayland
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/libglvnd
	media-libs/mesa
	media-libs/vulkan-loader
	sys-apps/xdg-desktop-portal
	>=sys-libs/glibc-2.35
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-misc/xdg-utils
	system-ffmpeg? ( >=media-video/ffmpeg-8.1:0/60.62.62[x264] )
"
BDEPEND="$(unpacker_src_uri_depends)"

QA_PREBUILT="*"

src_unpack() {
	unpack_deb "${P}.deb"
	unpack "concat-${PV}.tar.gz"
}

src_prepare() {
	default

	if use system-ffmpeg; then
		rm opt/concat/lib/lib{avcodec,avdevice,avfilter,avformat,avutil,swresample,swscale}.so* || die
	fi
}

src_install() {
	# Preserve $ORIGIN/lib and ONNX Runtime's dlopen path.
	insinto /opt/concat
	doins -r opt/concat/lib
	exeinto /opt/concat
	doexe opt/concat/concat
	dobin usr/bin/concat
	# Keep existing command-line launchers working through the upstream rename.
	dosym concat /usr/bin/wolfcut-desktop
	domenu usr/share/applications/concat.desktop
	doicon -s 256 usr/share/icons/hicolor/256x256/apps/concat.png

	dodoc "${MY_S}"/{LICENSE,THIRD_PARTY_NOTICES.md}
	# 0.2.8 bundles 37 font faces; install every face's licence, not just one.
	docinto fonts
	dodoc "${MY_S}"/src/crates/concat-text/fonts/LICENSE-*.txt
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "WolfCut is now Concat; launch it with concat or wolfcut-desktop."
	elog "This release replaces the Tauri interface with Slint. Back up existing"
	elog "projects before opening them in the new application."
	if use system-ffmpeg; then
		elog "Uses system FFmpeg 8.1 libraries with the matching 60.62.62 ABI."
	else
		elog "Uses upstream's bundled GPL FFmpeg libraries."
	fi
	elog "Speech and cutout models are downloaded by the app on demand."
	optfeature "audio playback on a PipeWire/PulseAudio desktop" \
		"media-plugins/alsa-plugins[pulseaudio]"
}

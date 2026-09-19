# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop optfeature unpacker xdg

# Upstream tags v0.2.0-alpha.17, but the release asset only carries 0.2.0.
MY_PV="$(ver_rs 3 - 4 . "${PV}")"

DESCRIPTION="Free multi-track video editor built on Tauri (formerly Concat)"
HOMEPAGE="https://github.com/jub0t/Concat"

# Alpha releases reuse the same asset filename, so the tag in the URL is the
# only thing pinning the payload; both files move together on a bump.
SRC_URI="
	https://github.com/jub0t/Concat/releases/download/v${MY_PV}/WolfCut_$(ver_cut 1-3)_amd64.deb
		-> ${P}.deb
	https://raw.githubusercontent.com/jub0t/Concat/v${MY_PV}/THIRD_PARTY_NOTICES.md
		-> ${P}-THIRD_PARTY_NOTICES.md
"
S="${WORKDIR}"

# MPL-2.0 covers WolfCut itself. The Tauri binary statically links sherpa-onnx
# (Apache-2.0) together with its espeak-ng component (GPL-3+), onnxruntime
# (MIT), and the usual permissive Rust crate set; the bundled whisper.cpp CLI
# is MIT. Upstream's FFmpeg pair is a nonfree build (DeckLink SDK, OpenSSL
# with GPL) that self-reports "nonfree and unredistributable", hence
# all-rights-reserved whenever it is installed.
LICENSE="
	Apache-2.0 BSD BSD-2 GPL-3+ ISC MIT MPL-2.0
	!system-ffmpeg? ( all-rights-reserved )
"
SLOT="0"
# Upstream publishes Linux builds for amd64 only.
KEYWORDS="-* ~amd64"
IUSE="+system-ffmpeg"
RESTRICT="bindist mirror strip"

# NEEDED entries of the Tauri binary, plus xdg-utils for link opening. The
# default export preset encodes with libx264, so the system FFmpeg needs it.
RDEPEND="
	dev-libs/glib:2
	media-libs/alsa-lib
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1
	sys-apps/dbus
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-misc/xdg-utils
	system-ffmpeg? ( media-video/ffmpeg[x264] )
"
BDEPEND="$(unpacker_src_uri_depends)"

QA_PREBUILT="*"

src_unpack() {
	# The notices file is plain documentation; only the deb unpacks.
	unpack_deb "${P}.deb"
}

src_prepare() {
	default

	# Upstream ships an empty Categories key, which leaves the entry out of
	# every desktop menu and trips desktop-file-validate.
	sed -i -e 's/^Categories=$/Categories=AudioVideo;AudioVideoEditing;/' \
		usr/share/applications/WolfCut.desktop || die

	# Without its bundled pair the app runs ffmpeg/ffprobe from PATH, an
	# upstream-supported mode: the launcher only registers the bundled
	# binaries when both files exist.
	if use system-ffmpeg; then
		rm usr/lib/WolfCut/ffmpeg/{ffmpeg,ffprobe} || die
	fi
}

src_install() {
	exeinto /usr/bin
	doexe usr/bin/wolfcut-desktop

	# Tauri resolves its resource directory as <exe dir>/../lib/WolfCut, so
	# this layout has to survive intact. The "lib" here is literal and must
	# not become $(get_libdir).
	exeinto /usr/lib/WolfCut/whisper
	doexe usr/lib/WolfCut/whisper/whisper-cli

	if ! use system-ffmpeg; then
		exeinto /usr/lib/WolfCut/ffmpeg
		doexe usr/lib/WolfCut/ffmpeg/ffmpeg usr/lib/WolfCut/ffmpeg/ffprobe
	fi

	domenu usr/share/applications/WolfCut.desktop

	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor

	newdoc "${DISTDIR}/${P}-THIRD_PARTY_NOTICES.md" THIRD_PARTY_NOTICES.md
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "WolfCut is alpha software; expect project format and feature"
	elog "changes between releases."
	elog
	if use system-ffmpeg; then
		elog "The bundled FFmpeg was dropped in favour of ffmpeg/ffprobe from"
		elog "PATH. The default export preset encodes with libx264, so keep"
		elog "the x264 flag enabled on media-video/ffmpeg."
	else
		elog "This install keeps upstream's own FFmpeg build (DeckLink SDK,"
		elog "OpenSSL with GPL: nonfree and unredistributable). Enable USE"
		elog "system-ffmpeg to use the system FFmpeg instead."
	fi
	elog
	elog "Auto-captions and voice features download Whisper/Kokoro models on"
	elog "demand at first use; portage neither installs nor removes them."

	# The engine opens the default ALSA PCM directly; on a PipeWire or
	# PulseAudio desktop that device usually routes through the pulse plugin.
	optfeature "audio playback on a PipeWire/PulseAudio desktop" \
		"media-plugins/alsa-plugins[pulseaudio]"
}

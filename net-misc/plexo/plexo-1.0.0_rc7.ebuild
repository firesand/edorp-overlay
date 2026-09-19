# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..15} )
inherit desktop pax-utils python-any-r1 unpacker xdg

MY_PV="$(ver_rs 3 - 4 .)"
ELECTRON_PV="39.8.10"

DESCRIPTION="Download manager using multiple network connections in parallel"
HOMEPAGE="https://github.com/anmolkapil/plexo"

# Upstream's Linux releases (including the unlabelled AppImage) are arm64.
# Only the architecture-independent application resources are taken from the
# deb. Pair them with the official amd64 Electron pinned in package-lock.json.
SRC_URI="
	https://github.com/anmolkapil/plexo/releases/download/v${MY_PV}/plexo_${MY_PV}_arm64.deb
		-> ${P}-arm64.deb
	https://github.com/anmolkapil/plexo/archive/refs/tags/v${MY_PV}.tar.gz
		-> ${P}.gh.tar.gz
	https://github.com/electron/electron/releases/download/v${ELECTRON_PV}/electron-v${ELECTRON_PV}-linux-x64.zip
"
S="${WORKDIR}"

# Plexo and its bundled JS dependencies, plus Electron/Chromium/FFmpeg.
# Full dependency notices remain in app.asar and LICENSES.chromium.html.
LICENSE="Apache-2.0 BSD BSD-2 ISC LGPL-2.1+ MIT MPL-2.0"
SLOT="0"
KEYWORDS="-* ~amd64"
# This repack has no build-time test suite; it is smoke-tested after staging.
RESTRICT="mirror strip test"

RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	elibc_glibc? ( >=sys-libs/glibc-2.28 )
"
BDEPEND="
	${PYTHON_DEPS}
	$(unpacker_src_uri_depends)
"

QA_PREBUILT="opt/plexo/*"

pkg_pretend() {
	# The official Electron runtime requires glibc, not a musl compatibility shim.
	use elibc_glibc || die "Plexo's bundled Electron runtime requires glibc"
}

src_unpack() {
	unpack_deb "${P}-arm64.deb"
	unpack "${P}.gh.tar.gz"
	mkdir electron || die
	cd electron || die
	unpack "electron-v${ELECTRON_PV}-linux-x64.zip"
}

src_prepare() {
	default

	# Refuse future bumps with native addons or a mismatched Electron runtime.
	"${PYTHON}" "${FILESDIR}/verify-resources.py" \
		opt/Plexo/resources "plexo-${MY_PV}/package-lock.json" \
		"${MY_PV}" "${ELECTRON_PV}" || die "Application resource validation failed"

	rm electron/resources/default_app.asar electron/chrome-sandbox || die
	cp -a opt/Plexo/resources/. electron/resources/ || die
	mv electron/electron electron/plexo || die
}

src_install() {
	dodir /opt/plexo
	cp -a electron/. "${ED}/opt/plexo/" || die
	pax-mark m "${ED}/opt/plexo/plexo"
	dosym -r /opt/plexo/plexo /usr/bin/plexo

	local icon
	for icon in usr/share/icons/hicolor/*/apps/plexo.png; do
		local size=${icon#usr/share/icons/hicolor/}
		doicon -s "${size%%x*}" "${icon}"
	done
	make_desktop_entry plexo Plexo plexo "Network;FileTransfer;" \
		"StartupWMClass=Plexo"

	newdoc "plexo-${MY_PV}/LICENSE" LICENSE.plexo
	newdoc electron/LICENSE LICENSE.electron
	dodoc electron/LICENSES.chromium.html
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Plexo is a release candidate, packaged with Electron ${ELECTRON_PV}."
	elog "The Chromium sandbox requires unprivileged user namespaces."
	elog "Each selected network needs a working route to the download server;"
	elog "combined throughput depends on your routes and the remote server."
}

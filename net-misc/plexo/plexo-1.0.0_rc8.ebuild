# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..15} )
inherit desktop pax-utils python-any-r1 unpacker xdg

MY_PV="$(ver_rs 3 - 4 .)"
# The Electron revision upstream bundles, as pinned in package-lock.json.
ELECTRON_PV="39.8.10"

DESCRIPTION="Download manager using multiple network connections in parallel"
HOMEPAGE="https://github.com/anmolkapil/plexo"

# Upstream began publishing native Linux amd64 builds at 1.0.0_rc.7, so the
# bundle is installed as shipped. The source tarball supplies the licence and
# the lockfile the bundle is validated against.
SRC_URI="
	https://github.com/anmolkapil/plexo/releases/download/v${MY_PV}/plexo_${MY_PV}_amd64.deb
		-> ${P}-amd64.deb
	https://github.com/anmolkapil/plexo/archive/refs/tags/v${MY_PV}.tar.gz
		-> ${P}.gh.tar.gz
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
	unpack_deb "${P}-amd64.deb"
	unpack "${P}.gh.tar.gz"
}

src_prepare() {
	default

	# Refuse future bumps whose runtime or native addons are not really amd64.
	"${PYTHON}" "${FILESDIR}/verify-resources.py" \
		opt/Plexo/resources "plexo-${MY_PV}/package-lock.json" \
		"${MY_PV}" "${ELECTRON_PV}" opt/Plexo/plexo ||
		die "Application resource validation failed"

	# The amd64 bundle also carries an unused ARM64 Koffi addon. Keeping it
	# triggers foreign-architecture soname warnings in the installed image.
	rm -r opt/Plexo/resources/app.asar.unpacked/node_modules/koffi/build/koffi/linux_arm64 || die
}

src_install() {
	# Take the bundled notices before the tree is moved into the image.
	newdoc "plexo-${MY_PV}/LICENSE" LICENSE.plexo
	newdoc opt/Plexo/LICENSE.electron.txt LICENSE.electron
	dodoc opt/Plexo/LICENSES.chromium.html
	rm opt/Plexo/LICENSE.electron.txt opt/Plexo/LICENSES.chromium.html || die

	dodir /opt
	mv opt/Plexo "${ED}/opt/plexo" || die

	# chrome-sandbox must be setuid-root for the Chromium sandbox helper.
	fperms 4755 /opt/plexo/chrome-sandbox

	pax-mark m "${ED}/opt/plexo/plexo"
	dosym -r /opt/plexo/plexo /usr/bin/plexo

	local icon
	for icon in usr/share/icons/hicolor/*/apps/plexo.png; do
		local size=${icon#usr/share/icons/hicolor/}
		doicon -s "${size%%x*}" "${icon}"
	done
	make_desktop_entry plexo Plexo plexo "Network;FileTransfer;" \
		"StartupWMClass=Plexo"
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Plexo is a release candidate, packaged with Electron ${ELECTRON_PV}."
	elog "The Chromium sandbox requires unprivileged user namespaces."
	elog "Each selected network needs a working route to the download server;"
	elog "combined throughput depends on your routes and the remote server."
}

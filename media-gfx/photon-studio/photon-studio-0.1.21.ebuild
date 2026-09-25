# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop pax-utils xdg

# Commit embedded in the upstream Flatpak bundle. Reject changed payloads even
# when the CDN keeps the same versioned URL.
FLATPAK_COMMIT="de86c817e27f50c2a67ed009209187e1dd2e9a041f82f5d81b069e471b386ea4"

DESCRIPTION="Offline image editor with layers, retouching and PSD support"
HOMEPAGE="https://tenzen.studio/photon/"
SRC_URI="https://downloads.tenzen.studio/photon/stable/linux/${PV}/Photon-Studio-${PV}-linux-x64.flatpak -> ${P}.flatpak"
S="${WORKDIR}/flatpak-app/files/lib/com.tenzen.photon"

# Photon is proprietary. The bundled background-removal model includes DINOv3
# weights; Electron, Chromium and other libraries carry their own notices.
LICENSE="all-rights-reserved Apache-2.0 BSD BSD-2 CDDL CC-BY-SA-3.0 DINOv3 ISC LGPL-2.1+ MIT MPL-2.0 ZLIB"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="bindist mirror strip"

BDEPEND="dev-util/ostree"
RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret
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
	elibc_glibc? ( >=sys-libs/glibc-2.34 )
"

QA_PREBUILT="opt/${PN}/*"

pkg_pretend() {
	use elibc_glibc || die "Upstream's Electron and native image engine require glibc"
}

src_unpack() {
	local ostree_cmd=${OSTREE_CMD:-ostree}

	# Flatpak bundles are OSTree static deltas, not ordinary archives. Import
	# into a private build repository and check the exact application commit.
	"${ostree_cmd}" --repo="${WORKDIR}/ostree-repo" init --mode=archive-z2 || die
	"${ostree_cmd}" --repo="${WORKDIR}/ostree-repo" static-delta apply-offline \
		"${DISTDIR}/${P}.flatpak" || die
	"${ostree_cmd}" --repo="${WORKDIR}/ostree-repo" fsck || die
	"${ostree_cmd}" --repo="${WORKDIR}/ostree-repo" checkout -U \
		"${FLATPAK_COMMIT}" "${WORKDIR}/flatpak-app" || die
	[[ -x ${S}/photon-studio ]] || die "Missing Photon Studio executable"
	[[ -f ${S}/resources/app.asar ]] || die "Missing Photon Studio application"
}

src_install() {
	# The Flatpak's electron-wrapper uses zypak and /app paths. Install only
	# the Electron application, then launch it directly on the host.
	dodir /opt/${PN}
	cp -R "${S}/." "${ED}/opt/${PN}/" || die
	fperms 4755 /opt/${PN}/chrome-sandbox
	pax-mark m "${ED}/opt/${PN}/photon-studio"
	newbin "${FILESDIR}/photon-studio" photon-studio

	sed 's/^Exec=electron-wrapper /Exec=photon-studio /' \
		"${WORKDIR}/flatpak-app/files/share/applications/com.tenzen.photon.desktop" \
		> "${T}/photon-studio.desktop" || die
	grep -q '^Exec=photon-studio %U$' "${T}/photon-studio.desktop" || die
	domenu "${T}/photon-studio.desktop"
	newicon -s 512 \
		"${WORKDIR}/flatpak-app/files/share/icons/hicolor/512x512/apps/com.tenzen.photon.png" \
		com.tenzen.photon.png

	# The bundled background-removal model includes Meta DINOv3 weights.
	# Keep its agreement available directly without extracting app.asar.
	newdoc "${FILESDIR}/LICENSE-DINOv3.txt" LICENSE-DINOv3.txt
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "The app is launched natively from the upstream Flatpak payload."
	elog "Future updates are installed through Portage."
	elog "Background removal is built with DINOv3; see the installed license."
}

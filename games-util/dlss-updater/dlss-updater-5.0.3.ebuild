# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

FLET_PV="1.0.0"
# The commit stored in the upstream Flatpak bundle. Pinning it also makes an
# unexpected change to the release asset fail before anything is installed.
FLATPAK_COMMIT="56e2ac6ab4e2a1a6143da097ba7604b13473d2c31137f6854d06c649575189a3"

DESCRIPTION="Update DLSS, XeSS and FSR game DLLs with automatic backups"
HOMEPAGE="https://github.com/Recol/DLSS-Updater"
SRC_URI="
	https://github.com/Recol/DLSS-Updater/releases/download/V${PV}/DLSS_Updater-${PV}.flatpak
		-> ${P}.flatpak
	https://github.com/Recol/DLSS-Updater/archive/refs/tags/V${PV}.tar.gz
		-> ${P}.gh.tar.gz
	https://github.com/flet-dev/flet/releases/download/v${FLET_PV}/flet-linux-debian12-light-amd64.tar.gz
		-> ${P}-flet-${FLET_PV}.tar.gz
"
S="${WORKDIR}/DLSS-Updater-${PV}"

# The application is AGPL; the separately released Flet/Flutter client and
# its bundled plugins/fonts carry the other licenses. Its full third-party
# notices remain installed in data/flutter_assets/NOTICES.Z.
LICENSE="AGPL-3 Apache-2.0 BSD BSD-2 Boost-1.0 CC0-1.0 ISC MIT MPL-2.0 Unlicense ZLIB"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="strip"

BDEPEND="dev-util/ostree"
RDEPEND="
	app-accessibility/at-spi2-core:2
	app-crypt/libsecret
	dev-libs/glib:2
	media-libs/fontconfig
	media-libs/freetype
	media-libs/harfbuzz
	media-libs/libepoxy
	sys-apps/dbus
	virtual/zlib
	elibc_glibc? ( >=sys-libs/glibc-2.34 )
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXi
	x11-libs/pango
"

QA_PREBUILT="opt/${PN}/*"

pkg_pretend() {
	use elibc_glibc || die "Upstream's PyInstaller and Flet binaries require glibc"
}

src_unpack() {
	local ostree_cmd=${OSTREE_CMD:-ostree}
	unpack "${P}.gh.tar.gz" "${P}-flet-${FLET_PV}.tar.gz"

	# A .flatpak bundle is an OSTree static delta. Import it into a private
	# build repo, then check out only the matching application commit.
	"${ostree_cmd}" --repo="${WORKDIR}/ostree-repo" init --mode=archive-z2 || die
	"${ostree_cmd}" --repo="${WORKDIR}/ostree-repo" static-delta apply-offline \
		"${DISTDIR}/${P}.flatpak" || die
	"${ostree_cmd}" --repo="${WORKDIR}/ostree-repo" fsck || die
	"${ostree_cmd}" --repo="${WORKDIR}/ostree-repo" checkout -U \
		"${FLATPAK_COMMIT}" "${WORKDIR}/flatpak-app" || die
	[[ -f ${WORKDIR}/flatpak-app/files/bin/dlss_updater ]] || die "Missing upstream executable"
	[[ -f ${WORKDIR}/flet/flet ]] || die "Missing Flet desktop client"
}

src_install() {
	exeinto /opt/${PN}
	newexe "${WORKDIR}/flatpak-app/files/bin/dlss_updater" dlss_updater

	# FLET_VIEW_PATH points to this directory and prevents a first-run client
	# download. The game DLL catalogue itself is updated by the app at runtime.
	insinto /opt/${PN}/flet
	doins -r "${WORKDIR}/flet/data" "${WORKDIR}/flet/lib"
	exeinto /opt/${PN}/flet
	doexe "${WORKDIR}/flet/flet"

	newbin "${FILESDIR}/dlss-updater" dlss-updater
	# Keep a single main desktop category to avoid duplicate menu entries.
	sed 's/^Categories=Game;Utility;$/Categories=Game;/' \
		"${WORKDIR}/flatpak-app/files/share/applications/io.github.recol.dlss-updater.desktop" \
		> "${T}/io.github.recol.dlss-updater.desktop" || die
	domenu "${T}/io.github.recol.dlss-updater.desktop"
	doicon -s 256 "${WORKDIR}/flatpak-app/files/share/icons/hicolor/256x256/apps/io.github.recol.dlss-updater.png"
	insinto /usr/share/metainfo
	doins "${WORKDIR}/flatpak-app/files/share/metainfo/io.github.recol.dlss-updater.metainfo.xml"

	newdoc LICENSE LICENSE.dlss-updater
	dodoc release_notes.txt
}

pkg_postinst() {
	xdg_pkg_postinst
	if [[ ${REPLACING_VERSIONS} ]]; then
		elog "Open DLSS Updater to refresh its game DLL catalogue after this upgrade."
	else
		elog "The game DLL catalogue and selected DLLs are downloaded on first use."
	fi
}

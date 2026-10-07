# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

MY_COMMIT="29de8facf2348a1ffd461aa52b25cc23a488e255"
MY_DATE="2026-10-05"
MY_TAG="shadPS4QtLauncher-${MY_DATE}-${MY_COMMIT}"

DESCRIPTION="Official Qt launcher for the shadPS4 PlayStation 4 emulator"
HOMEPAGE="https://github.com/shadps4-emu/shadps4-qtlauncher"
SRC_URI="
	https://github.com/shadps4-emu/shadps4-qtlauncher/releases/download/${MY_TAG}/shadPS4QtLauncher-linux-qt-${MY_DATE}-${MY_COMMIT:0:7}.zip
		-> ${P}.zip
	https://github.com/shadps4-emu/shadps4-qtlauncher/archive/${MY_COMMIT}.tar.gz
		-> ${P}-source.tar.gz
"
S="${WORKDIR}/squashfs-root"

# Launcher and bundled Qt, audio/network libraries and GCC runtime.
LICENSE="Apache-2.0 BSD BSD-2 Boost-1.0 GPL-2+ ISC LGPL-2.1+ LGPL-3 MIT
	Unicode-DFS-2016 ZLIB gcc-runtime-library-exception-3.1 libgcc libstdc++"
SLOT="0"
KEYWORDS="-* ~amd64"
# Keep the official binary and bundled runtime together. Do not mirror or
# redistribute a binary package without its complete corresponding sources.
RESTRICT="bindist mirror strip"

# NEEDED entries not provided by the extracted bundle, including Qt plugins.
# Bundled libstdc++/libgcc keep the compiler ABI independent of the host GCC.
RDEPEND="
	>=games-emulation/shadps4-bin-0.19.0
	dev-libs/expat
	dev-libs/libgpg-error
	dev-libs/libpcre2
	dev-libs/wayland
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/freetype
	media-libs/libglvnd[X]
	media-libs/libpng:0=
	media-libs/vulkan-loader
	sys-fs/e2fsprogs
	elibc_glibc? ( >=sys-libs/glibc-2.38 )
	virtual/zlib
	x11-libs/libX11
	x11-libs/libdrm
	x11-libs/libxcb
"
BDEPEND="
	app-arch/unzip
	>=sys-fs/squashfs-tools-4.4[zstd]
"

QA_PREBUILT="*"

pkg_pretend() {
	use elibc_glibc || die "The official QtLauncher binary requires glibc >= 2.38"
}

src_unpack() {
	default
	# Offset of the SquashFS payload in this release. Recheck on every bump;
	# unpack without executing an upstream binary or requiring FUSE.
	unsquashfs -no-progress -offset 944632 -d "${S}" \
		"${WORKDIR}/shadPS4QtLauncher-qt.AppImage" || die
}

src_prepare() {
	default
	cp "${FILESDIR}/shadps4" "${T}/shadps4" || die
	sed -i "s|@EPREFIX@|${EPREFIX}|g" "${T}/shadps4" || die
}

src_install() {
	local apphome="/opt/${PN}"
	dodir "${apphome}"
	cp -a usr "${ED}${apphome}/" || die
	# AppImage extraction preserves private build-directory modes.
	find "${ED}${apphome}" -type d -exec chmod 0755 {} + || die
	rm "${ED}${apphome}/usr/optional/exec.so" || die

	dobin "${T}/shadps4"
	dosym shadps4 /usr/bin/shadPS4QtLauncher

	newicon -s scalable usr/share/icons/hicolor/scalable/apps/net.shadps4.shadPS4.svg \
		net.shadps4.qtlauncher.svg
	make_desktop_entry --eapi9 shadps4 -n "shadPS4 Qt Launcher" \
		-i net.shadps4.qtlauncher -c "Game;Emulator;" \
		-e "StartupWMClass=shadPS4QtLauncher" -d net.shadps4.qtlauncher

	dodoc "${WORKDIR}/shadps4-qtlauncher-${MY_COMMIT}/LICENSE"
	dodoc -r "${WORKDIR}/shadps4-qtlauncher-${MY_COMMIT}/LICENSES"
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "In Version Manager, add a custom emulator: /usr/bin/shadps4-core"
	elog "Select that entry to use the core managed by Portage."
	elog "Update both packages with Portage; the AppImage self-updater cannot"
	elog "replace this system installation. Turn off automatic update checks."
	elog "Versions downloaded with Version Manager remain user-managed."
	elog "Games, saves, firmware modules and per-user settings are not included."
}

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

# Commit behind upstream's annotated v.0.19.0 tag. The source archive supplies
# the core and embedded-data notices omitted from the binary release ZIP.
SOURCE_COMMIT="c7e065d1b415be16c23e260a21f1dd8bbfc4cb57"

DESCRIPTION="Experimental PlayStation 4 emulator, official prebuilt SDL core"
HOMEPAGE="https://shadps4.net/ https://github.com/shadps4-emu/shadPS4"
SRC_URI="
	https://github.com/shadps4-emu/shadPS4/releases/download/v.${PV}/shadps4-linux-sdl-${PV}.zip
		-> ${P}-linux-sdl.zip
	https://github.com/shadps4-emu/shadPS4/archive/${SOURCE_COMMIT}.tar.gz
		-> ${PN}-source-${SOURCE_COMMIT}.tar.gz
"
S="${WORKDIR}/squashfs-root"

# GPL-2+ core plus static third-party libraries/fonts, bundled libudev/libcap,
# and the optional upstream GCC runtimes. Preserve upstream's available notices;
# this repack is not a replacement for a complete corresponding-source bundle.
LICENSE="Apache-2.0 BSD BSD-2 Boost-1.0 CC0-1.0 FTL FraunhoferFDK GPL-2+
	ISC LGPL-2.1+ MIT OFL-1.1 openssl ZLIB gcc-runtime-library-exception-3.1
	libgcc libpng2 libstdc++"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="+X +wayland"
REQUIRED_USE="|| ( X wayland )"
RESTRICT="bindist mirror strip"

# readelf: the core, libudev, libcap and optional libstdc++ need GLIBC_2.38.
# libuuid is not bundled. SDL/OpenAL load display/audio backends at runtime;
# the Vulkan renderer requires an external loader and a Vulkan 1.3-capable ICD.
# SDL, OpenAL, FFmpeg and the GCC runtime are already inside the upstream bundle.
RDEPEND="
	media-libs/alsa-lib
	media-libs/libglvnd[X?]
	media-libs/libpulse
	>=media-libs/vulkan-loader-1.3[X?,wayland?]
	sys-apps/util-linux
	elibc_glibc? ( >=sys-libs/glibc-2.38 )
	X? (
		x11-libs/libX11
		x11-libs/libXcursor
		x11-libs/libXext
		x11-libs/libXfixes
		x11-libs/libXi
		x11-libs/libXrandr
		x11-libs/libXScrnSaver
		x11-libs/libXtst
		x11-libs/libxcb
	)
	wayland? (
		dev-libs/wayland
		gui-libs/libdecor
		x11-libs/libxkbcommon
	)
"
BDEPEND="
	app-arch/unzip
	>=sys-fs/squashfs-tools-4.4[zstd]
"

QA_PREBUILT="opt/shadps4-bin/*"

pkg_pretend() {
	use elibc_glibc || die "The official shadPS4 binary requires glibc >= 2.38"
}

src_unpack() {
	unpack "${P}-linux-sdl.zip" "${PN}-source-${SOURCE_COMMIT}.tar.gz"

	# ELF section-table end and SquashFS superblock offset of the verified
	# 0.19.0 AppImage. Re-audit this number on every version bump. Never run the
	# AppImage runtime during a build, and do not require a FUSE mount at runtime.
	unsquashfs -no-progress -offset 944632 -d "${S}" \
		"${WORKDIR}/Shadps4-sdl.AppImage" || die "AppImage extraction failed"
}

src_prepare() {
	default

	local required
	for required in usr/bin/shadps4 usr/lib/libudev.so.1 usr/lib/libcap.so.2 \
		usr/optional/libgcc_s.so.1/libgcc_s.so.1 \
		usr/optional/libstdc++.so.6/libstdc++.so.6; do
		[[ -f ${required} ]] || die "Unexpected upstream bundle: missing ${required}"
	done

	# Upstream AppRun probes ldconfig and can add an empty LD_LIBRARY_PATH
	# component. Our wrapper uses only verified bundle paths and no FUSE runtime.
	cp "${FILESDIR}/shadps4-core" "${T}/shadps4-core" || die
	sed -i "s|@EPREFIX@|${EPREFIX}|g" "${T}/shadps4-core" || die

	sed -i \
		-e 's|^Name=.*|Name=shadPS4 Core (Big Picture)|' \
		-e 's|^Exec=.*|Exec=shadps4-core -b|' \
		usr/share/applications/net.shadps4.shadPS4.desktop || die
}

src_install() {
	local source="${WORKDIR}/shadPS4-${SOURCE_COMMIT}"
	dodoc "${source}/LICENSE"
	dodoc -r "${source}/LICENSES"
	docinto bundled-libcap
	dodoc usr/share/doc/libcap2/copyright
	docinto bundled-libudev
	dodoc usr/share/doc/libudev1/copyright

	# Retain the exact native payload and its private shared libraries, but not
	# the obsolete AppRun/exec.so dispatch layer. No user data belongs in /opt.
	dodir /opt/shadps4-bin/usr
	cp -a usr/bin usr/lib usr/optional "${ED}/opt/shadps4-bin/usr/" || die
	rm "${ED}/opt/shadps4-bin/usr/optional/exec.so" || die
	dobin "${T}/shadps4-core"

	domenu usr/share/applications/net.shadps4.shadPS4.desktop
	doicon -s scalable usr/share/icons/hicolor/scalable/apps/net.shadps4.shadPS4.svg
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "Run shadps4-core -b for Big Picture, or shadps4-core /path/to/eboot.bin."
	elog "The upstream binary requires an x86-64-v3 CPU (including AVX2) and a"
	elog "Vulkan 1.3-capable GPU with its driver installed."
	elog "Firmware modules and games are not included. Existing per-user settings"
	elog "and saves are kept outside this package; update the core using Portage."
}

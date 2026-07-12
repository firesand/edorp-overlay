# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.88.0"

EGIT_REPO_URI="https://github.com/firesand/MAMEUIx.git"

inherit cargo desktop git-r3 xdg

DESCRIPTION="Modern GUI frontend for the MAME arcade emulator"
HOMEPAGE="https://github.com/firesand/MAMEUIx"

LICENSE="MIT"
# Dependent crate licenses (from Cargo.lock / cargo metadata)
LICENSE+="
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions Boost-1.0 BSD BSD-2
	BZIP2 CC0-1.0 ISC LGPL-2.1+ MIT MIT-0 MPL-2.0 OFL-1.1
	UbuntuFontLicense-1.0 Unicode-3.0 Unlicense UoI-NCSA ZLIB
"

SLOT="0"
KEYWORDS=""

BDEPEND="
	virtual/pkgconfig
"
DEPEND="
	app-arch/xz-utils:=
	app-arch/zstd:=
	dev-libs/wayland
	media-libs/libglvnd
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libXinerama
	x11-libs/libXrandr
	x11-libs/libxkbcommon[X]
"
RDEPEND="
	${DEPEND}
	>=app-emulation/mame-0.200
"

QA_FLAGS_IGNORED="usr/bin/mameuix"

export PKG_CONFIG_ALLOW_CROSS=1
export ZSTD_SYS_USE_PKG_CONFIG=1

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_configure() {
	cargo_src_configure --locked
}

src_install() {
	cargo_src_install

	domenu mameuix.desktop
	doman debian/mameuix.1

	local size
	for size in 16 32 48 64 128 256; do
		newicon -s "${size}" "assets/icons/${size}x${size}/mameuix.png" mameuix.png
	done
	newicon -s scalable assets/icons/scalable/mameuix.svg mameuix.svg

	dodoc README.md CHANGELOG.md
}

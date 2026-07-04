# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cargo

DESCRIPTION="Lightweight GUI front-end for Gentoo's equery package query tool"
HOMEPAGE="https://github.com/firesand/equery-gui"
SRC_URI="https://github.com/firesand/equery-gui/archive/refs/tags/v${PV}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${PV}"

LICENSE="GPL-2+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	app-portage/gentoolkit
	media-libs/mesa
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libxkbcommon
"

src_configure() {
	cargo_src_configure --locked
}

src_install() {
	cargo_src_install
}

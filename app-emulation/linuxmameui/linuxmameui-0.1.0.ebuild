# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit cmake xdg

DESCRIPTION="Native Qt frontend for MAME and HBMAME"
HOMEPAGE="https://github.com/linuxmameui/linuxmameui"
SRC_URI="${P}.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+hbmame +mame"
RESTRICT="fetch"

DEPEND="
	dev-qt/qtbase:6[gui,sql,widgets,xml]
"
RDEPEND="
	${DEPEND}
	hbmame? ( app-emulation/hbmame )
	mame? ( app-emulation/mame )
"

pkg_nofetch() {
	einfo "Create the local source archive from the LinuxMAMEUI repository root:"
	einfo
	einfo "  tar --transform 's,^,${P}/,' \\"
	einfo "      --exclude='./build' \\"
	einfo "      --exclude='./packaging/gentoo' \\"
	einfo "      -czf \"\${DISTDIR:-/var/cache/distfiles}/${P}.tar.gz\" \\"
	einfo "      CMakeLists.txt README.md LICENSE data docs src"
	einfo
	einfo "Then run:"
	einfo
	einfo "  ebuild packaging/gentoo/app-emulation/linuxmameui/${P}.ebuild manifest"
}

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit optfeature

DESCRIPTION="Capture packets from WLAN devices and test WPA protocol weaknesses"
HOMEPAGE="https://github.com/ZerBea/hcxdumptool"
SRC_URI="https://github.com/ZerBea/hcxdumptool/releases/download/${PV}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="net-libs/libpcap"
DEPEND="
	${RDEPEND}
	>=sys-kernel/linux-headers-5.15
"

DOCS=(
	README.md
	changelog
	docs
)

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install

	doman man/hcxdumptool.1
	einstalldocs

	docinto examples
	dodoc usefulscripts/*
}

pkg_postinst() {
	optfeature "matching capture conversion and analysis tools" "~net-wireless/hcxtools-${PV}"

	elog "Use hcxdumptool only on networks you own or are authorized to audit."
}

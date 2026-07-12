# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )
PYTHON_REQ_USE="sqlite,ssl(+)"

inherit distutils-r1 optfeature

DESCRIPTION="Modern wireless security auditor with a live terminal interface"
HOMEPAGE="https://github.com/Leadrogue/Wiflux"
SRC_URI="https://github.com/Leadrogue/Wiflux/releases/download/v${PV}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/rich-13[${PYTHON_USEDEP}]
	net-wireless/aircrack-ng
	net-wireless/iw
	sys-apps/iproute2
"
BDEPEND="
	>=dev-python/setuptools-68[${PYTHON_USEDEP}]
"

PATCHES=(
	"${FILESDIR}/${P}-no-apt-prompt-on-non-debian.patch"
	"${FILESDIR}/${P}-no-runtime-write-to-usr.patch"
	"${FILESDIR}/${P}-fix-environment-dependent-tests.patch"
)

DOCS=(
	CHANGELOG.md
	INSTALL.md
	README.md
	docs
)

distutils_enable_tests unittest

python_test() {
	eunittest -s tests -p 'test_*.py'
}

pkg_postinst() {
	optfeature "WPA/WPA2 password recovery" app-crypt/hashcat
	optfeature "WPS auditing" net-wireless/reaver
	optfeature "capture analysis via tshark" "net-analyzer/wireshark[tshark]"

	elog "Wiflux also supports hcxdumptool, hcxpcapngtool, pixiewps, bully,"
	elog "mdk3, mdk4, and bettercap when those commands are installed."
	elog "Compressed dictionaries under /usr are not unpacked automatically."
	elog "Decompress one to a writable path and select it with --dict FILE."
	elog "Use Wiflux only on networks you own or are authorized to audit."
}

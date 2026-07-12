# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Wireless testing tool for IEEE 802.11 protocol weaknesses"
HOMEPAGE="https://github.com/aircrack-ng/mdk4"

COMMIT="3e214fc90710c9185f3783783b3b3c6c4e3098c2"
SRC_URI="https://github.com/aircrack-ng/mdk4/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	dev-libs/libnl:3
	net-libs/libpcap
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_compile() {
	# The recursive upstream build races while generating attack objects.
	emake -j1 \
		CC="$(tc-getCC)" \
		AR="$(tc-getAR)" \
		RANLIB="$(tc-getRANLIB)"
}

src_test() {
	emake \
		CC="$(tc-getCC)" \
		AR="$(tc-getAR)" \
		RANLIB="$(tc-getRANLIB)" \
		test
	"${S}/test" || die "test suite failed"
}

src_install() {
	dosbin src/mdk4
	doman man/mdk4.8

	insinto /usr/share/${PN}
	doins -r src/pocs useful_files

	dodoc AUTHORS CHANGELOG README.md TODO
}

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit toolchain-funcs

DESCRIPTION="Offline brute-force tool for WPS PINs with weak or low-entropy PRNGs"
HOMEPAGE="https://github.com/wiire-a/pixiewps"
SRC_URI="https://github.com/wiire-a/pixiewps/releases/download/v${PV}/${P}.tar.xz"

LICENSE="BSD-4 GPL-3+ MIT public-domain"
SLOT="0"
KEYWORDS="~amd64"
IUSE="+openssl"

DEPEND="openssl? ( dev-libs/openssl:= )"
RDEPEND="${DEPEND}"

DOCS=( CHANGELOG.md README.md )

src_compile() {
	emake \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS}" \
		OPENSSL="$(usex openssl 1 0)"
}

src_install() {
	emake \
		CC="$(tc-getCC)" \
		CFLAGS="${CFLAGS}" \
		OPENSSL="$(usex openssl 1 0)" \
		DESTDIR="${D}" \
		PREFIX="${EPREFIX}/usr" \
		install
	einstalldocs
}

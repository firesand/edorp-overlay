# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Tools to convert wireless packet captures to hash formats"
HOMEPAGE="https://github.com/ZerBea/hcxtools"
SRC_URI="https://github.com/ZerBea/hcxtools/releases/download/${PV}/${P}.tar.gz"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-libs/openssl-3.0.0:=
	net-misc/curl[ssl]
	virtual/zlib:=
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_install() {
	emake DESTDIR="${D}" PREFIX="${EPREFIX}/usr" install
	doman man/hcxtools.1
	dodoc README.md changelog
}

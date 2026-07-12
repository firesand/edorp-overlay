# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit optfeature toolchain-funcs

DESCRIPTION="WPS brute-force and Pixie Dust attack tool"
HOMEPAGE="https://github.com/kimocoder/bully"

COMMIT="a9ab51b2d66dfd318db9448f25f93b0397e10cf6"
SRC_URI="https://github.com/kimocoder/bully/archive/${COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${COMMIT}"

LICENSE="GPL-3+ BSD public-domain"
SLOT="0"
KEYWORDS="~amd64"
IUSE="lua"

RDEPEND="
	dev-libs/libnl:3
	net-libs/libpcap
	lua? ( dev-lang/lua:5.4 )
"
DEPEND="${RDEPEND}"
BDEPEND="virtual/pkgconfig"

src_prepare() {
	default

	# The snapshot contains an upstream-built executable. Always rebuild it.
	rm -f src/bully || die

	# Respect the user's optimization level instead of appending -O2.
	sed -i -e '/^CFLAGS.*-DUSE_INTERNAL_CRYPTO/s/ -O2//' src/Makefile || die
}

src_compile() {
	local emakeargs=(
		CC="$(tc-getCC)"
		NL80211=1
		LUA="$(usex lua 1 0)"
	)

	use lua && emakeargs+=( LUA_PKG=lua5.4 )
	emake -C src "${emakeargs[@]}"
}

src_install() {
	dobin src/bully
	dodoc README.md
}

pkg_postinst() {
	optfeature "offline Pixie Dust attacks" net-wireless/pixiewps

	elog "Use Bully only on networks you own or are authorized to audit."
}

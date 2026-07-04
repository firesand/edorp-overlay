# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit multiprocessing pax-utils python-any-r1 toolchain-funcs

DESCRIPTION="HomeBrew MAME command-line emulator"
HOMEPAGE="https://hbmame.1emulation.com/ https://github.com/Robbbert/hbmame"

_COMMIT="e20204804c2808c101db85daa2cdcf5d97f1330b"
SRC_URI="https://github.com/Robbbert/hbmame/archive/${_COMMIT}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-${_COMMIT}"

LICENSE="GPL-2+ BSD LGPL-2.1 MIT CC0-1.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64"
IUSE="debug lto tools"

PATCHES=(
	"${FILESDIR}/${P}-cps1-unknown-regs.patch"
	"${FILESDIR}/${P}-cps2-input-include.patch"
)

BDEPEND="
	${PYTHON_DEPS}
	virtual/pkgconfig
"
DEPEND="
	media-libs/alsa-lib
	media-libs/fontconfig
	media-libs/libsdl2
	media-libs/sdl2-ttf
	virtual/opengl
	x11-libs/libXi
	x11-libs/libXinerama
"
RDEPEND="${DEPEND}"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_compile() {
	local args=(
		-j"$(makeopts_jobs)"
		TARGET=hbmame
		ARCH=
		NOWERROR=1
		PTR64=1
		TOOLS="$(usex tools 1 0)"
		SYMBOLS="$(usex debug 1 0)"
		NO_SYMBOLS="$(usex debug 0 1)"
		STRIP_SYMBOLS=0
		OVERRIDE_CC="$(tc-getCC)"
		OVERRIDE_CXX="$(tc-getCXX)"
		OVERRIDE_LD="$(tc-getCXX)"
		PYTHON_EXECUTABLE="${PYTHON}"
		ARCHOPTS="${CXXFLAGS}"
		LDOPTS="${LDFLAGS}"
	)

	use lto && args+=( LTO=1 )

	ARCH= emake "${args[@]}"
}

src_install() {
	local binary="./hbmame"

	if [[ ! -x ${binary} ]]; then
		binary="$(find . -type f -perm -111 -name hbmame -print -quit)"
	fi

	[[ -x ${binary} ]] || die "Unable to find built hbmame executable"

	exeinto /usr/libexec/${PN}
	doexe "${binary}"
	pax-mark m "${ED}/usr/libexec/${PN}/hbmame" || die

	insinto /usr/share/${PN}
	for dir in artwork bgfx ctrlr hash hlsl ini language plugins; do
		[[ -d ${dir} ]] && doins -r "${dir}"
	done
	keepdir /usr/share/${PN}/roms
	keepdir /usr/share/${PN}/samples

	cat > "${T}/${PN}" <<-EOF || die
		#!/bin/sh
		exec /usr/libexec/${PN}/hbmame \\
			-homepath "\${HOME}/.${PN}" \\
			-inipath "\${HOME}/.${PN};/etc/${PN};/usr/share/${PN}/ini" \\
			-artpath "\${HOME}/.${PN}/artwork;/usr/share/${PN}/artwork" \\
			-bgfx_path "/usr/share/${PN}/bgfx" \\
			-ctrlrpath "\${HOME}/.${PN}/ctrlr;/usr/share/${PN}/ctrlr" \\
			-hashpath "/usr/share/${PN}/hash" \\
			-languagepath "/usr/share/${PN}/language" \\
			-pluginspath "\${HOME}/.${PN}/plugins;/usr/share/${PN}/plugins" \\
			"\$@"
	EOF
	dobin "${T}/${PN}"

	if use tools; then
		local tool
		for tool in castool chdman floptool imgtool jedutil ldresample ldverify nltool nlwav pngcmp regrep romcmp split srcclean testkeys unidasm; do
			[[ -x ./${tool} ]] && dobin "./${tool}"
		done
	fi

	dodoc README.md COPYING
}

# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..14} )

inherit multiprocessing pax-utils python-any-r1 toolchain-funcs

DESCRIPTION="Multiple Arcade Machine Emulator"
HOMEPAGE="https://www.mamedev.org/ https://github.com/mamedev/mame"
SRC_URI="https://github.com/mamedev/mame/archive/refs/tags/mame${PV//.}.tar.gz -> ${P}.tar.gz"
S="${WORKDIR}/${PN}-mame${PV//.}"

LICENSE="GPL-2+ BSD LGPL-2.1 MIT CC0-1.0 ZLIB"
SLOT="0"
KEYWORDS="~amd64"
IUSE="debug lto qtdebug tools"

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
	qtdebug? ( dev-qt/qtbase:6[gui,widgets] )
"
RDEPEND="${DEPEND}"

pkg_setup() {
	python-any-r1_pkg_setup
}

src_compile() {
	local args=(
		-j"$(makeopts_jobs)"
		ARCH=
		NOWERROR=1
		PTR64=1
		TOOLS="$(usex tools 1 0)"
		USE_QTDEBUG="$(usex qtdebug 1 0)"
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
	local binary="./mame"

	if [[ ! -x ${binary} ]]; then
		binary="$(find . -type f -perm -111 -name mame -print -quit)"
	fi

	[[ -x ${binary} ]] || die "Unable to find built mame executable"

	exeinto /usr/libexec/${PN}
	doexe "${binary}"
	pax-mark m "${ED}/usr/libexec/${PN}/mame" || die

	insinto /usr/share/${PN}
	for dir in artwork bgfx ctrlr hash hlsl ini language plugins; do
		[[ -d ${dir} ]] && doins -r "${dir}"
	done
	keepdir /usr/share/${PN}/roms
	keepdir /usr/share/${PN}/samples

	cat > "${T}/${PN}" <<-EOF || die
		#!/bin/sh
		exec /usr/libexec/${PN}/mame \\
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

	dodoc README.md docs/legal/*
}

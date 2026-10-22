# Copyright 2020-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit flag-o-matic optfeature toolchain-funcs xdg

DESCRIPTION="Graphical UI to configure MangoHud, vkBasalt, OptiScaler, and PasCube"
HOMEPAGE="https://github.com/benjamimgois/goverlay"
SRC_URI="
	https://github.com/benjamimgois/${PN}/archive/refs/tags/${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

# Goverlay is GPL-3+; integrated PasCube is GPL-2+ on top of PasVulkan
# (ZLIB, with public-domain LzmaDec.c and embedded Hack [MIT/BitstreamVera]
# and Noto Sans [OFL-1.1] fonts); bgmod/fgmod templates are MIT; AppStream
# metadata is CC0-1.0.
LICENSE="GPL-3+ GPL-2+ BitstreamVera CC0-1.0 MIT OFL-1.1 public-domain ZLIB"
SLOT="0"
KEYWORDS="~amd64"
IUSE="test"
RESTRICT="!test? ( test )"

DEPEND="
	dev-libs/libqt6pas
	media-libs/libsdl2[vulkan,X]
	virtual/zlib:=
	x11-libs/libX11
"
RDEPEND="
	${DEPEND}
	|| (
		app-arch/7zip
		app-arch/p7zip
	)
	dev-vcs/git
	games-util/mangohud
	media-libs/fontconfig
	media-libs/vulkan-loader
	net-misc/curl
	sys-apps/coreutils
	sys-apps/which
	sys-process/psmisc
	x11-apps/mesa-progs
	x11-apps/xrandr
	x11-misc/xdg-utils
"
BDEPEND="
	>=dev-lang/fpc-3.2.2
	>=dev-lang/lazarus-3.0[qt6]
"

src_prepare() {
	default

	# Remove prebuilt LZMA decoder objects across architectures; we rebuild
	# the Linux x86_64 object from LzmaDec.c with the host C toolchain.
	rm -f pascube_src/pasvulkan/src/lzma_c/*.o || die

	# Keep DWARF debug info and let Portage strip/split symbols instead of
	# upstream's Release build mode pre-stripping the binary.
	sed -i \
		-e 's#<GenerateDebugInfo Value="False"/>#<GenerateDebugInfo Value="True"/><DebugInfoType Value="dsDwarf2Set"/>#' \
		-e 's#<StripSymbols Value="True"/>#<StripSymbols Value="False"/>#' \
		goverlay.lpi || die

	# Allow passing our FPC wrapper to bgmod and bgmod-uninstaller targets,
	# and backport the missing top-level data/*.png install rule from main.
	sed -i \
		-e 's/\tfpc /\t$(FPC) /g' \
		-e '/install -d $(DESTDIR)$(prefix)$(datadir)\/goverlay\/data\/icons/i\\tinstall -d $(DESTDIR)$(prefix)$(datadir)/goverlay/data\n\tcp data/*.png $(DESTDIR)$(prefix)$(datadir)/goverlay/data/' \
		Makefile || die

	# Terminate the Desktop Entry Keywords list with a semicolon.
	sed -i 's/^Keywords=\(.*[^;]\)$/Keywords=\1;/' \
		data/io.github.benjamimgois.goverlay.desktop || die
}

src_compile() {
	# FPC invokes ld directly without the GCC/Clang LTO linker plugin, so
	# LzmaDec.o must be a standard ELF object rather than GIMPLE bytecode.
	filter-lto

	local lzma_dir="pascube_src/pasvulkan/src/lzma_c"
	"$(tc-getCC)" ${CPPFLAGS} ${CFLAGS} -fPIC -Dlinux \
		-c "${lzma_dir}/LzmaDec.c" \
		-o "${lzma_dir}/lzmadec_linux_x86_64.o" || die

	cat > "${T}/fpc-wrapper" <<-EOF || die
		#!/bin/sh
		exec /usr/bin/fpc "\$@" -gw2 -Xs- -k"-z relro -z now $(raw-ldflags)"
	EOF
	chmod +x "${T}/fpc-wrapper" || die

	mkdir -p "${T}/lazarus-cfg" || die
	local lazopts=(
		"--lazarusdir=/usr/share/lazarus"
		"--primary-config-path=${T}/lazarus-cfg"
		"--ws=qt6"
		"--compiler=${T}/fpc-wrapper"
	)

	# Parallel lazbuild invocations race when compiling LCL units into the
	# shared --primary-config-path cache directory.
	emake -j1 \
		prefix=/usr \
		FPC="${T}/fpc-wrapper" \
		LAZBUILDOPTS="${lazopts[*]}" \
		all data/goverlay.sh
}

src_test() {
	local lazopts=(
		"--lazarusdir=/usr/share/lazarus"
		"--primary-config-path=${T}/lazarus-cfg"
		"--ws=qt6"
		"--compiler=${T}/fpc-wrapper"
	)
	emake -j1 \
		FPC="${T}/fpc-wrapper" \
		LAZBUILDOPTS="${lazopts[*]}" \
		test-logic
}

src_install() {
	emake DESTDIR="${D}" prefix=/usr install

	einstalldocs
	newdoc pascube_src/LICENSE LICENSE.pascube
	newdoc pascube_src/pasvulkan/LICENSE LICENSE.pasvulkan
	newdoc data/bgmod/LICENSE LICENSE.bgmod
}

pkg_postinst() {
	xdg_pkg_postinst
	optfeature "Feral GameMode integration" games-util/gamemode
	optfeature "Proton prefix management via Protontricks" app-emulation/protontricks
	optfeature "Nerd Font icons in overlay UI" media-fonts/symbols-nerd-font
}

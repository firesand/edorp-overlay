# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{12..14} )
inherit python-single-r1

DESCRIPTION="DualSense wireless bridge firmware for Raspberry Pi Pico 2 W"
HOMEPAGE="https://github.com/awalol/DS5Dongle"

# Upstream publishes the current 0.7.2 release under the v0.7.2-hotfix tag.
MY_PV="${PV}-hotfix"
SRC_URI="
	https://github.com/awalol/DS5Dongle/archive/refs/tags/v${MY_PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/awalol/DS5Dongle/releases/download/v${MY_PV}/ds5-bridge-v${MY_PV}.uf2
		-> ${P}-pico2w.uf2
	other-boards? (
		https://github.com/awalol/DS5Dongle/releases/download/v${MY_PV}/other.board.zip
			-> ${P}-other-boards.zip
	)
"
S="${WORKDIR}/DS5Dongle-${MY_PV}"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"
IUSE="other-boards"
REQUIRED_USE="${PYTHON_REQUIRED_USE}"

RDEPEND="
	${PYTHON_DEPS}
	$(python_gen_cond_dep '
		dev-python/hidapi[${PYTHON_USEDEP}]
	')
"
BDEPEND="
	other-boards? ( app-arch/unzip )
"

pkg_setup() {
	python-single-r1_pkg_setup
}

src_unpack() {
	unpack "${P}.tar.gz"
	if use other-boards; then
		mkdir -p "${S}/other-boards" || die
		pushd "${S}/other-boards" >/dev/null || die
		unpack "${P}-other-boards.zip"
		popd >/dev/null || die
	fi
}

src_prepare() {
	default
	sed -i \
		-e 's|Missing dependency. Install with:  pip install hidapi|Missing dependency: install dev-python/hidapi|' \
		tools/config_tool.py || die
}

src_compile() {
	:
}

src_install() {
	insinto /usr/share/ds5dongle
	newins "${DISTDIR}/${P}-pico2w.uf2" ds5-bridge-pico2w.uf2

	if use other-boards; then
		insinto /usr/share/ds5dongle/other-boards
		doins other-boards/*.uf2
	fi

	python_newscript tools/config_tool.py ds5dongle-config

	dodoc README.md README.CN.md LICENSE
}

pkg_postinst() {
	elog "Flash the Pico 2 W by copying this UF2 while the board is in BOOTSEL mode:"
	elog "  /usr/share/ds5dongle/ds5-bridge-pico2w.uf2"
	elog "Configure a connected DualSense bridge with:"
	elog "  ds5dongle-config get"
	elog "  ds5dongle-config set speaker_volume=90"
	elog "Web configuration UI: https://ds5.awalol.eu.org"
	if use other-boards; then
		elog "Pico W and Waveshare UF2 builds are in /usr/share/ds5dongle/other-boards/"
	fi
}

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.75.0"

EGIT_REPO_URI="https://gitlab.com/asus-linux/supergfxctl.git"

inherit cargo git-r3 systemd udev

DESCRIPTION="Graphics mode switching daemon for hybrid-GPU laptops"
HOMEPAGE="https://asus-linux.org/ https://gitlab.com/asus-linux/supergfxctl"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS=""
RESTRICT="test"

BDEPEND="virtual/pkgconfig"
DEPEND="
	sys-apps/systemd:=
"
RDEPEND="${DEPEND}
	sys-apps/dbus
	sys-apps/pciutils
	sys-process/lsof
"

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_configure() {
	local myfeatures=( daemon cli )
	cargo_src_configure --locked
}

src_compile() {
	export CARGO_PROFILE_RELEASE_LTO="thin"
	cargo_src_compile
}

src_install() {
	local target_dir="$(cargo_target_dir)"

	dobin "${target_dir}/supergfxctl" "${target_dir}/supergfxd"

	insinto /usr/share/dbus-1/system.d
	doins data/org.supergfxctl.Daemon.conf

	systemd_dounit data/supergfxd.service

	insinto /usr/lib/systemd/system-preset
	doins data/supergfxd.preset

	insinto /usr/lib/udev/rules.d
	newins data/90-supergfxd-nvidia-pm.rules \
		90-supergfxd-nvidia-pm.rules

	dodoc README.md
}

pkg_postinst() {
	udev_reload
	elog "Enable the daemon with:"
	elog "  systemctl enable --now supergfxd.service"
	elog "Do not request a GPU mode switch until --supported and --get"
	elog "have been checked for this AMD+AMD laptop."
}

pkg_postrm() {
	udev_reload
}

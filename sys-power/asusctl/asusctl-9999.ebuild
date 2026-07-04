# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.82.0"
LLVM_COMPAT=( 21 )

EGIT_REPO_URI="https://github.com/OpenGamingCollective/asusctl.git"

inherit cargo desktop git-r3 llvm-r2 systemd udev xdg

DESCRIPTION="Daemon, CLI and control center for ASUS ROG laptops"
HOMEPAGE="https://asus-linux.org/ https://github.com/OpenGamingCollective/asusctl"

LICENSE="MPL-2.0"
SLOT="0"
KEYWORDS=""
IUSE="+gui"
RESTRICT="test"

BDEPEND="
	dev-build/cmake
	virtual/pkgconfig
	$(llvm_gen_dep '
		llvm-core/clang:${LLVM_SLOT}=
		llvm-core/llvm:${LLVM_SLOT}=
	')
"
DEPEND="
	dev-libs/libusb:1
	sys-apps/systemd:=
	gui? (
		dev-libs/libinput
		dev-libs/wayland
		media-libs/fontconfig
		media-libs/freetype
		media-libs/mesa[wayland]
		sys-auth/seatd
		x11-libs/libxkbcommon[wayland]
	)
"
RDEPEND="${DEPEND}
	sys-apps/dbus
"

pkg_setup() {
	llvm-r2_pkg_setup
	rust_pkg_setup
}

src_unpack() {
	git-r3_src_unpack
	cargo_live_src_unpack
}

src_configure() {
	local packages=(
		--package asusctl
		--package asusd
		--package asusd-user
		--package asus-shutdown
	)

	use gui && packages+=( --package rog-control-center )
	cargo_src_configure --locked "${packages[@]}"
}

src_compile() {
	export LIBCLANG_PATH="$(get_llvm_prefix -b)/$(get_libdir)"
	# Upstream uses fat LTO. Thin LTO retains cross-crate optimization while
	# substantially reducing link time and peak heat on mobile CPUs.
	export CARGO_PROFILE_RELEASE_LTO="thin"
	cargo_src_compile
}

src_install() {
	local target_dir="$(cargo_target_dir)"

	dobin \
		"${target_dir}/asusctl" \
		"${target_dir}/asusd" \
		"${target_dir}/asusd-user" \
		"${target_dir}/asus-shutdown"

	insinto /usr/lib/udev/rules.d
	newins data/asusd.rules 99-asusd.rules
	insinto /usr/share/dbus-1/system.d
	doins data/asusd.conf

	systemd_dounit data/asusd.service data/asus-shutdown.service
	systemd_douserunit data/asusd-user.service

	insinto /usr/share/asusd
	doins rog-aura/data/aura_support.ron
	doins -r rog-anime/data/anime

	if use gui; then
		dobin "${target_dir}/rog-control-center"
		domenu rog-control-center/data/rog-control-center.desktop

		newicon -s 512 rog-control-center/data/rog-control-center.png \
			rog-control-center.png

		insinto /usr/share/metainfo
		doins \
			rog-control-center/data/org.opengamingcollective.rog-control-center.metainfo.xml

		insinto /usr/share/rog-gui/layouts
		doins -r rog-aura/data/layouts/*

		insinto /usr/share/icons/hicolor/512x512/apps
		doins data/icons/*.png

		insinto /usr/share/icons/hicolor/scalable/status
		doins data/icons/scalable/*.svg
	fi

	dodoc CHANGELOG.md README.md
}

pkg_postinst() {
	udev_reload
	use gui && xdg_icon_cache_update

	elog "Enable the system services with:"
	elog "  systemctl enable --now asusd.service asus-shutdown.service"
	elog "asusd-user is installed but intentionally not enabled: upstream 6.3.8"
	elog "still targets the legacy /xyz/ljones/Aura D-Bus object, while current"
	elog "asusd exposes per-device Aura paths."
	elog "Linux 6.19 or newer is required for the newer asus-armoury TDP controls."
}

pkg_postrm() {
	udev_reload
	use gui && xdg_icon_cache_update
}

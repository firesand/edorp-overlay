# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.75.0"

CRATES="
	addr2line@0.24.2
	adler2@2.0.0
	aho-corasick@1.1.3
	anstream@0.6.18
	anstyle-parse@0.2.6
	anstyle-query@1.1.2
	anstyle-wincon@3.0.6
	anstyle@1.0.10
	async-broadcast@0.7.1
	async-channel@2.3.1
	async-executor@1.13.1
	async-fs@2.1.2
	async-io@2.4.0
	async-lock@3.4.0
	async-process@2.3.0
	async-recursion@1.1.1
	async-signal@0.2.10
	async-task@4.7.1
	async-trait@0.1.83
	atomic-waker@1.1.2
	autocfg@1.4.0
	backtrace@0.3.74
	bitflags@2.6.0
	blocking@1.6.1
	bytes@1.8.0
	cfg-if@1.0.0
	cfg_aliases@0.2.1
	colorchoice@1.0.3
	concurrent-queue@2.5.0
	crossbeam-utils@0.8.20
	endi@1.1.0
	enumflags2@0.7.10
	enumflags2_derive@0.7.10
	env_filter@0.1.2
	env_logger@0.11.5
	equivalent@1.0.1
	errno@0.3.9
	event-listener-strategy@0.5.2
	event-listener@5.3.1
	fastrand@2.2.0
	futures-core@0.3.31
	futures-io@0.3.31
	futures-lite@2.6.0
	futures-macro@0.3.31
	futures-task@0.3.31
	futures-util@0.3.31
	gimli@0.31.1
	gumdrop@0.8.1
	gumdrop_derive@0.8.1
	hashbrown@0.15.2
	hermit-abi@0.3.9
	hermit-abi@0.4.0
	hex@0.4.3
	humantime@2.1.0
	indexmap@2.6.0
	io-lifetimes@1.0.11
	is_terminal_polyfill@1.70.1
	itoa@1.0.14
	libc@0.2.166
	libudev-sys@0.1.4
	linux-raw-sys@0.4.14
	log@0.4.22
	logind-zbus@5.2.0
	memchr@2.7.4
	memoffset@0.9.1
	miniz_oxide@0.8.0
	mio@1.0.2
	nix@0.29.0
	object@0.36.5
	once_cell@1.20.2
	ordered-stream@0.2.0
	parking@2.2.1
	pin-project-lite@0.2.15
	pin-utils@0.1.0
	piper@0.2.4
	pkg-config@0.3.31
	polling@3.7.4
	proc-macro-crate@3.2.0
	proc-macro2@1.0.92
	quote@1.0.37
	regex-automata@0.4.9
	regex-syntax@0.8.5
	regex@1.11.1
	rustc-demangle@0.1.24
	rustix@0.38.41
	ryu@1.0.18
	serde@1.0.215
	serde_derive@1.0.215
	serde_json@1.0.133
	serde_repr@0.1.19
	signal-hook-registry@1.4.2
	slab@0.4.9
	socket2@0.5.7
	static_assertions@1.1.0
	syn@1.0.109
	syn@2.0.89
	tempfile@3.14.0
	tokio-macros@2.4.0
	tokio@1.41.1
	toml_datetime@0.6.8
	toml_edit@0.22.22
	tracing-attributes@0.1.28
	tracing-core@0.1.33
	tracing@0.1.41
	udev@0.9.1
	uds_windows@1.1.0
	unicode-ident@1.0.14
	utf8parse@0.2.2
	wasi@0.11.0+wasi-snapshot-preview1
	winapi-i686-pc-windows-gnu@0.4.0
	winapi-x86_64-pc-windows-gnu@0.4.0
	winapi@0.3.9
	windows-sys@0.48.0
	windows-sys@0.52.0
	windows-sys@0.59.0
	windows-targets@0.48.5
	windows-targets@0.52.6
	windows_aarch64_gnullvm@0.48.5
	windows_aarch64_gnullvm@0.52.6
	windows_aarch64_msvc@0.48.5
	windows_aarch64_msvc@0.52.6
	windows_i686_gnu@0.48.5
	windows_i686_gnu@0.52.6
	windows_i686_gnullvm@0.52.6
	windows_i686_msvc@0.48.5
	windows_i686_msvc@0.52.6
	windows_x86_64_gnu@0.48.5
	windows_x86_64_gnu@0.52.6
	windows_x86_64_gnullvm@0.48.5
	windows_x86_64_gnullvm@0.52.6
	windows_x86_64_msvc@0.48.5
	windows_x86_64_msvc@0.52.6
	winnow@0.6.20
	winnow@0.7.2
	xdg-home@1.3.0
	zbus@5.5.0
	zbus_macros@5.5.0
	zbus_names@4.1.0
	zvariant@5.1.0
	zvariant_derive@5.1.0
	zvariant_utils@3.2.0
"

inherit cargo systemd udev

DESCRIPTION="Graphics mode switching daemon for hybrid-GPU laptops"
HOMEPAGE="https://asus-linux.org/ https://gitlab.com/asus-linux/supergfxctl"
SRC_URI="
	https://gitlab.com/asus-linux/supergfxctl/-/archive/${PV}/${P}.tar.bz2
	${CARGO_CRATE_URIS}
"

LICENSE="MPL-2.0"
# Dependent crate licenses
LICENSE+="
	MIT MPL-2.0 Unicode-3.0
	|| ( Apache-2.0 Boost-1.0 )
"
SLOT="0"
KEYWORDS="~amd64"
IUSE="systemd"

# The upstream tests need a GPU and root.
RESTRICT="test"

DEPEND="virtual/libudev:="
RDEPEND="
	${DEPEND}
	sys-apps/dbus
	sys-apps/pciutils
	sys-process/lsof
	!systemd? ( sys-auth/elogind )
"
BDEPEND="virtual/pkgconfig"

PATCHES=( "${FILESDIR}"/${P}-openrc-support.patch )

QA_FLAGS_IGNORED="usr/bin/.*"

src_configure() {
	cargo_src_configure --locked
}

src_install() {
	local target_dir="$(cargo_target_dir)"

	dobin "${target_dir}/supergfxctl" "${target_dir}/supergfxd"

	insinto /usr/share/dbus-1/system.d
	doins data/org.supergfxctl.Daemon.conf

	insinto /usr/lib/udev/rules.d
	doins data/90-supergfxd-nvidia-pm.rules

	insinto /usr/share/X11/xorg.conf.d
	doins data/90-nvidia-screen-G05.conf

	if use systemd; then
		systemd_dounit data/supergfxd.service
	else
		newinitd "${FILESDIR}"/supergfxd.initd supergfxd
		newconfd "${FILESDIR}"/supergfxd.confd supergfxd
	fi

	dodoc README.md CHANGELOG.md
}

pkg_postinst() {
	udev_reload

	if use systemd; then
		elog "Enable the daemon with:"
		elog "  systemctl enable --now supergfxd.service"
	else
		elog "Enable the daemon with:"
		elog "  rc-update add supergfxd default && rc-service supergfxd start"
		elog "Changing the GPU mode stops and starts the 'display-manager' OpenRC"
		elog "service (see /etc/conf.d/display-manager) and needs elogind to see"
		elog "when you have logged out."
	fi
	elog
	elog "No group is required: the D-Bus policy lets users in the groups"
	elog "wheel, users, adm and sudo talk to supergfxd."
	elog
	elog "supergfxd conflicts with other GPU switchers and power managers that"
	elog "bind, unbind or power the discrete GPU, such as envycontrol,"
	elog "optimus-manager, prime-select or bbswitch/bumblebee: use only one."
	elog "It rewrites /etc/modprobe.d/supergfxd.conf when the mode changes."
	elog "Check 'supergfxctl --supported' and 'supergfxctl --get' before"
	elog "requesting a mode switch."
}

pkg_postrm() {
	udev_reload
}

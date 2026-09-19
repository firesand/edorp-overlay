# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop xdg

DESCRIPTION="Run Windows apps on Linux with seamless FreeRDP integration"
HOMEPAGE="https://www.winboat.app/
	https://github.com/winboat-org/winboat/"
SRC_URI="
	https://github.com/winboat-org/winboat/releases/download/v${PV}/winboat-${PV}-x64.tar.gz
		-> ${P}-x64.tar.gz
"

S="${WORKDIR}/winboat-${PV}-x64"

LICENSE="MIT"
SLOT="0"
KEYWORDS="-* ~amd64"
IUSE="+docker podman"
REQUIRED_USE="|| ( docker podman )"
RESTRICT="bindist mirror strip"

# Electron runtime + FreeRDP 3.x (sound required by upstream).
# Container runtime is selected with USE flags.
RDEPEND="
	!app-emulation/winboat-bin
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret[crypt]
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa
	net-misc/curl
	|| (
		>=net-misc/freerdp-3:3[client,X,pulseaudio]
		>=net-misc/freerdp-3:3[client,X,alsa]
	)
	sys-apps/dbus
	sys-apps/usbutils
	virtual/libudev
	virtual/zlib:=
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	docker? (
		app-containers/docker
		>=app-containers/docker-cli-29.5.2
		>=app-containers/docker-compose-2
	)
	podman? (
		>=app-containers/podman-4
		app-containers/podman-compose
	)
"

QA_PREBUILT="*"

src_prepare() {
	default

	# Drop foreign native prebuilds from optional Node addons.
	local mode pre
	for mode in argon2 usb; do
		pre="${S}/resources/app.asar.unpacked/node_modules/${mode}/prebuilds"
		if [[ -d ${pre} ]]; then
			find "${pre}/" -mindepth 1 -maxdepth 1 ! -name 'linux-x64' -type d \
				-exec rm -rf {} + || die
			rm -f "${pre}/linux-x64/"*musl* || die
		fi
	done
}

src_install() {
	local apphome="/opt/${PN}"

	# Preserve upstream executable bits from the Electron unpack.
	mkdir -p "${ED}${apphome}" || die
	cp -a . "${ED}${apphome}/" || die

	dosym -r "${apphome}/winboat" "/usr/bin/${PN}"

	doicon -s scalable "${FILESDIR}/winboat.svg"
	make_desktop_entry "${PN} %U" WinBoat winboat "Utility;Emulator;" \
		"StartupWMClass=winboat"

	dodoc LICENSE.electron.txt LICENSES.chromium.html
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "WinBoat ${PV} is a prebuilt Electron app installed under /opt/winboat."
	elog
	elog "Hardware prerequisites:"
	elog "  - KVM enabled in BIOS/UEFI (/dev/kvm present)"
	elog "  - At least 4 GB RAM, 2 CPU threads, and ~32 GB free disk"
	elog
	elog "FreeRDP 3.x with sound support is required (xfreerdp3 or xfreerdp)."
	if use docker; then
		elog
		elog "Docker runtime:"
		elog "  1. Start and enable the daemon (OpenRC: rc-update add docker default)"
		elog "  2. Add your user to the docker group, then re-login:"
		elog "       usermod -aG docker \${USER}"
		elog "  3. Confirm: docker compose version && docker ps"
		elog "  Docker Desktop is unsupported."
	fi
	if use podman; then
		elog
		elog "Podman runtime: ensure 'podman compose --version' works."
		elog "USB passthrough via Podman is not supported upstream yet."
	fi
	elog
	elog "First launch creates ~/winboat (or a path you choose) and pulls"
	elog "ghcr.io/dockur/windows. Windows itself is not licensed by WinBoat."
}

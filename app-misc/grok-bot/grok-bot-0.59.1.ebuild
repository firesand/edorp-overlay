# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop optfeature pax-utils unpacker xdg

# The official release feed pins this version to a specific build. Its
# download URLs are immutable, unlike the latest-download endpoint.
GROK_BOT_BUILD="1d382f86e90289af505e2ce87b6be681aa8d2660"
GROK_BOT_URI="https://downloads.cursor.com/grokbot/stable/${GROK_BOT_BUILD}/linux"

DESCRIPTION="Grok Bot desktop client for persistent cloud AI agents"
HOMEPAGE="https://x.ai/bot https://docs.x.ai/grok-bot/get-started"
SRC_URI="
	amd64? ( ${GROK_BOT_URI}/x64/${PN}_${PV}_amd64.deb -> ${P}-amd64.deb )
	arm64? ( ${GROK_BOT_URI}/arm64/${PN}_${PV}_arm64.deb -> ${P}-arm64.deb )
"
S="${WORKDIR}"

# The desktop client is proprietary. Its bundled Electron and Chromium
# third-party notices remain in /opt/grok-bot after installation.
LICENSE="all-rights-reserved"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="apparmor suid"
RESTRICT="bindist mirror strip"

BDEPEND="$(unpacker_src_uri_depends)"
RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-crypt/libsecret
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	sys-apps/util-linux
	sys-apps/xdg-desktop-portal
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXScrnSaver
	x11-libs/libXtst
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	elibc_glibc? ( >=sys-libs/glibc-2.38 )
	apparmor? ( sys-apps/apparmor )
"

QA_PREBUILT="opt/${PN}/*"

pkg_pretend() {
	use elibc_glibc || die "The upstream Electron binary and native modules require glibc"
}

src_install() {
	local dest="/opt/${PN}"

	# Keep Electron's executable, resources and native addons together. The
	# space-free path also lets Chromium's optional setuid helper work.
	dodir /opt
	mv "opt/Grok Bot" "${ED}${dest}" || die
	# Upstream enables setuid only when unprivileged user namespaces fail.
	# Preserve the safer upstream 0755 mode unless the user opts in.
	if use suid; then
		fperms 4755 "${dest}/chrome-sandbox"
	fi
	pax-mark m "${ED}${dest}/grok-bot"

	# The .deb's APT repository registration is intentionally not installed.
	dosym -r "${dest}/grok-bot" /usr/bin/grok-bot
	domenu usr/share/applications/grok-bot.desktop
	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor

	if use apparmor; then
		sed 's|"/opt/Grok Bot/grok-bot"|"/opt/grok-bot/grok-bot"|' \
			"${ED}${dest}/resources/apparmor-profile" > "${T}/grok-bot.apparmor" || die
		insinto /etc/apparmor.d
		newins "${T}/grok-bot.apparmor" grok-bot
	fi
}

pkg_postinst() {
	xdg_pkg_postinst
	elog "Grok Bot requires an eligible Cursor or SuperGrok account."
	elog "The upstream APT updater is omitted; update this package through Portage."
	if ! use suid; then
		elog "If unprivileged user namespaces are blocked, enable USE=suid for Chromium's sandbox."
	fi
	if use apparmor; then
		elog "Load the profile with: apparmor_parser -r -T -W /etc/apparmor.d/grok-bot"
	fi
	optfeature "credential storage in a desktop keyring" virtual/secret-service
}

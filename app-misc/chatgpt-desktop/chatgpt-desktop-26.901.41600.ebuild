# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop optfeature pax-utils unpacker xdg

# Upstream names the package, the install prefix, and the launcher "chatgpt".
MY_PN="chatgpt"

DESCRIPTION="ChatGPT desktop app for Linux, bundling the Codex coding agent"
HOMEPAGE="https://openai.com/codex/
	https://developers.openai.com/codex/app"

# The advertised /linux/deb/latest/chatgpt_amd64.deb path is mutable and
# cannot be pinned by a Manifest. These are the same files, taken from the
# versioned APT pool that upstream's own postinst subscribes to.
MY_URI="https://persistent.oaistatic.com/codex-app-prod/linux/deb/pool/main/c/${MY_PN}"
SRC_URI="
	amd64? ( ${MY_URI}/${MY_PN}_${PV}_amd64.deb -> ${P}-amd64.deb )
	arm64? ( ${MY_URI}/${MY_PN}_${PV}_arm64.deb -> ${P}-arm64.deb )
"
S="${WORKDIR}"

# Proprietary OpenAI application, governed by the OpenAI Terms of Use
# (https://openai.com/policies/terms-of-use/). The remaining entries cover the
# bundled Electron/Chromium runtime, the Node runtime, and the vendored
# node_modules; see /opt/chatgpt-desktop/LICENSES.chromium.html.
LICENSE="all-rights-reserved Apache-2.0 BSD BSD-2 ISC MIT MPL-2.0"
SLOT="0"
KEYWORDS="-* ~amd64 ~arm64"
IUSE="apparmor"
RESTRICT="bindist mirror strip"

# Runtime libraries taken from the NEEDED entries of the Electron binary, plus
# the ones it dlopen()s (libGL, libnotify) and libusb for the bundled node-hid
# addon.
RDEPEND="
	>=app-accessibility/at-spi2-core-2.46.0:2
	app-misc/ca-certificates
	dev-libs/expat
	dev-libs/glib:2
	dev-libs/nspr
	dev-libs/nss
	media-libs/alsa-lib
	media-libs/libglvnd
	media-libs/mesa[gbm(+)]
	net-print/cups
	sys-apps/dbus
	virtual/libudev
	virtual/libusb:1
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXcomposite
	x11-libs/libXcursor
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libdrm
	x11-libs/libnotify
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	apparmor? ( sys-apps/apparmor )
"
BDEPEND="$(unpacker_src_uri_depends)"

QA_PREBUILT="*"

src_prepare() {
	default

	# Upstream ships native Node addons for every platform it targets. Keep
	# only the ABI this package installs. Matching on directories named
	# exactly "prebuilds" skips the unrelated "pkg-prebuilds" helper module,
	# whose bin/ and lib/ must survive.
	local keep
	use amd64 && keep="linux-x64"
	use arm64 && keep="linux-arm64"

	local dir
	while IFS= read -r -d '' dir; do
		find "${dir}" -mindepth 1 -maxdepth 1 -type d \
			! -name "*${keep}" -exec rm -rf {} + || die

		# Some addons ship their musl build as a sibling file inside the
		# kept directory instead of a directory of its own.
		find "${dir}" -name '*musl*.node' -delete || die
	done < <(find "usr/lib/${MY_PN}" -type d -name prebuilds -print0 || die)
}

src_install() {
	local dest="/opt/${PN}"

	dodir /opt
	mv "usr/lib/${MY_PN}" "${ED}${dest}" || die

	# V8 needs to map JIT pages on PaX/hardened kernels.
	pax-mark m "${ED}${dest}/ChatGPT"

	# codex-launcher resolves its own symlink, so a relative link works and
	# the desktop entry plus the codex:// handler both exec plain "chatgpt".
	dosym -r "${dest}/codex-launcher" "/usr/bin/${MY_PN}"

	domenu "usr/share/applications/${MY_PN}.desktop"
	doicon "usr/share/pixmaps/${MY_PN}.png"

	# Grants the "userns" rule the sandbox needs under an enforcing AppArmor.
	if use apparmor; then
		insinto /etc/apparmor.d
		doins "etc/apparmor.d/${MY_PN}"
	fi

	docinto licenses
	dodoc "usr/share/doc/${MY_PN}/copyright"
}

pkg_postinst() {
	xdg_pkg_postinst

	# This build ships no setuid chrome-sandbox; Chromium falls back to the
	# unprivileged user namespace sandbox instead.
	local max_userns="/proc/sys/user/max_user_namespaces"
	if [[ -r ${max_userns} ]] && [[ $(<"${max_userns}") -eq 0 ]]; then
		ewarn "User namespaces are disabled (${max_userns} is 0)."
		ewarn "ChatGPT ships no setuid chrome-sandbox, so it will not start"
		ewarn "until you enable them, or run it with --no-sandbox."
	fi

	elog "The upstream .deb installs an APT repository and signing key so it"
	elog "can update itself in the background. That is deliberately dropped"
	elog "here; update by bumping this package instead."
	if use apparmor; then
		elog
		elog "Load the bundled profile with:"
		elog "  apparmor_parser -r -T -W /etc/apparmor.d/${MY_PN}"
	fi
	elog
	elog "The bundled Codex agent, its Node runtime, and ripgrep live under"
	elog "/opt/${PN}/resources and are separate from dev-util/codex."

	optfeature "audio output via PulseAudio or PipeWire" media-libs/libpulse
	optfeature "repository operations in the Codex agent" dev-vcs/git
	optfeature "saving credentials to a keyring" virtual/secret-service
}

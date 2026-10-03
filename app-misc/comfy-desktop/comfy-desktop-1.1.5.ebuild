# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop optfeature pax-utils unpacker xdg

# ToDesktop publishes an immutable URL for every build next to the moving
# https://download.comfy.org/linux/deb/x64 redirect, which changes in place and
# so cannot be pinned by a Manifest. The build id changes with each release;
# the current one is listed in
# https://download.todesktop.com/241130tqe9q3y/latest-linux.yml
BUILD_ID="261002kr3dnlj4w"

DESCRIPTION="Official desktop application for installing and running ComfyUI"
HOMEPAGE="https://www.comfy.org/download
	https://github.com/Comfy-Org/Comfy-Desktop"

SRC_URI="
	https://download.todesktop.com/241130tqe9q3y/comfyui-desktop-2-${PV}-build-${BUILD_ID}-amd64.deb
		-> ${P}-amd64.deb
"
S="${WORKDIR}"

# Comfy Desktop is offered under AGPL-3.0-or-later or a commercial licence.
# The rest is the bundled Electron/Chromium/FFmpeg runtime and the Python
# bootstrap (CPython, Tcl/Tk, uv, pygit2/libgit2, OpenSSL, libssh2, PCRE).
# Full Chromium and Electron notices are installed under /usr/share/doc.
LICENSE="AGPL-3+ Apache-2.0 BSD BSD-2 GPL-2-with-linking-exception ISC
	LGPL-2.1+ MIT MPL-2.0 PSF-2 tcltk"
SLOT="0"
KEYWORDS="-* ~amd64"
RESTRICT="mirror strip test"

# NEEDED entries of the Electron binary, plus libsecret (credential storage),
# libXScrnSaver and libXtst, which Chromium dlopen()s and the upstream .deb
# lists in Depends.
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
	virtual/libudev
	x11-libs/cairo
	x11-libs/gtk+:3
	x11-libs/libnotify
	x11-libs/libX11
	x11-libs/libXScrnSaver
	x11-libs/libXcomposite
	x11-libs/libXdamage
	x11-libs/libXext
	x11-libs/libXfixes
	x11-libs/libXrandr
	x11-libs/libXtst
	x11-libs/libxcb
	x11-libs/libxkbcommon
	x11-libs/pango
	x11-misc/xdg-utils
	elibc_glibc? ( >=sys-libs/glibc-2.28 )
"
BDEPEND="$(unpacker_src_uri_depends)"

QA_PREBUILT="opt/comfy-desktop/*"

pkg_pretend() {
	# The bundled Electron and CPython builds target glibc.
	use elibc_glibc || die "Comfy Desktop's bundled runtimes require glibc"
}

src_prepare() {
	default

	# The amd64 .deb still carries 7-Zip helpers for other architectures and
	# for macOS. They can never run here and trigger foreign-architecture QA
	# warnings.
	local arch
	for arch in linux/arm linux/arm64 linux/ia32 mac; do
		rm -r "opt/Comfy Desktop/resources/app.asar.unpacked/node_modules/7zip-bin/${arch}" || die
	done

	# Upstream wraps the binary in a shell test for user namespaces and a
	# path with a space in it; the setuid sandbox installed below makes the
	# fallback unnecessary.
	sed -i \
		-e 's|^Exec=.*|Exec=comfyui-desktop-2 %U|' \
		-e 's|^Comment=.*|Comment=Install, run, and manage ComfyUI|' \
		-e 's|^Categories=.*|Categories=Graphics;ArtificialIntelligence;|' \
		usr/share/applications/comfyui-desktop-2.desktop || die
}

src_install() {
	# Take the bundled notices before the tree is moved into the image.
	newdoc "opt/Comfy Desktop/LICENSE.electron.txt" LICENSE.electron
	dodoc "opt/Comfy Desktop/LICENSES.chromium.html"
	rm "opt/Comfy Desktop/LICENSE.electron.txt" \
		"opt/Comfy Desktop/LICENSES.chromium.html" || die

	# Upstream installs to a directory with a space in its name; nothing in
	# the application refers to that path, so use a conventional one.
	dodir /opt
	mv "opt/Comfy Desktop" "${ED}/opt/comfy-desktop" || die

	# chrome-sandbox must be setuid-root for the Chromium sandbox helper
	# on kernels without unprivileged user namespaces.
	fperms 4755 /opt/comfy-desktop/chrome-sandbox

	# Allow V8's JIT to run under PaX/hardened kernels.
	pax-mark m "${ED}/opt/comfy-desktop/comfyui-desktop-2"

	dosym -r /opt/comfy-desktop/comfyui-desktop-2 /usr/bin/comfyui-desktop-2

	domenu usr/share/applications/comfyui-desktop-2.desktop
	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor

	# The AppArmor profile and APT repository setup in the upstream
	# maintainer scripts are Debian/Ubuntu specific and are not installed.
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "This package installs the Comfy Desktop shell only. On first launch the"
	elog "app provisions a standalone ComfyUI environment (about 5 GB, including"
	elog "PyTorch) under ~/ComfyUI-Installs, with settings in ~/.config/comfyui-desktop-2"
	elog "and ~/.local/share/comfyui-desktop-2. Portage neither tracks nor removes"
	elog "these; delete them by hand when unmerging."
	elog
	elog "Update the desktop shell with Portage. In-app updates and the Debian"
	elog "repository the upstream .deb configures do not apply on Gentoo."

	optfeature "NVIDIA GPU acceleration" x11-drivers/nvidia-drivers
	optfeature "custom nodes that call the git command line" dev-vcs/git
}

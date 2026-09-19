# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit desktop optfeature unpacker xdg

# Upstream spells the tag with dashes. The release assets carried the version
# in their names up to 0.1.800_beta; since 0.1.804_beta they are unversioned.
MY_PV="${PV/_/-}"

DESCRIPTION="Local desktop app to run and train LLMs and diffusion models"
HOMEPAGE="https://unsloth.ai/docs/desktop
	https://github.com/unslothai/unsloth"

SRC_URI="
	https://github.com/unslothai/unsloth/releases/download/v${MY_PV}/Unsloth-Desktop-Ubuntu.deb
		-> ${P}.deb
"
S="${WORKDIR}"

# The studio component shipped here is AGPL-3.0-only; the rest of the upstream
# repository is Apache-2.0, and the Tauri binary statically links vendored Rust
# crates under the usual permissive terms.
LICENSE="AGPL-3 Apache-2.0 BSD BSD-2 ISC MIT"
SLOT="0"
# Upstream builds no Linux arm64 desktop asset; ARM64 is macOS only.
KEYWORDS="-* ~amd64"
RESTRICT="strip"

# NEEDED entries of the Tauri binary, plus the tray library and libX11/libXi,
# which it dlopen()s. curl, git and lspci are used by the first-run installer.
RDEPEND="
	dev-libs/glib:2
	dev-libs/libayatana-appindicator
	dev-vcs/git
	net-libs/libsoup:3.0
	net-libs/webkit-gtk:4.1
	net-misc/curl
	sys-apps/dbus
	sys-apps/pciutils
	x11-libs/cairo
	x11-libs/gdk-pixbuf:2
	x11-libs/gtk+:3
	x11-libs/libX11
	x11-libs/libXi
"
BDEPEND="$(unpacker_src_uri_depends)"

QA_PREBUILT="*"

src_prepare() {
	default

	# Upstream ships an empty Categories key, which leaves the entry out of
	# every desktop menu and trips desktop-file-validate.
	sed -i -e 's/^Categories=$/Categories=Science;ArtificialIntelligence;/' \
		usr/share/applications/Unsloth.desktop || die
}

src_install() {
	# Tauri resolves its resource directory as <exe dir>/../lib/Unsloth, so
	# upstream's layout has to survive intact. The "lib" here is literal and
	# must not become $(get_libdir).
	exeinto /usr/bin
	doexe usr/bin/unsloth-studio

	exeinto /usr/lib/Unsloth
	doexe usr/lib/Unsloth/install.sh

	domenu usr/share/applications/Unsloth.desktop

	insinto /usr/share/icons
	doins -r usr/share/icons/hicolor
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "This package installs the desktop shell only. On first launch it"
	elog "bootstraps a private Python environment into ~/.unsloth/studio with"
	elog "uv, downloading PyTorch and the unsloth wheels (several GB). That"
	elog "tree is not managed by portage; remove it by hand when unmerging."
	elog
	elog "The bundled installer can only add missing system packages through"
	elog "apt, so on Gentoo it will ask you to install them yourself."

	optfeature "building Python extensions during the first-run setup" \
		sys-devel/gcc dev-build/cmake
	optfeature "NVIDIA GPU acceleration" x11-drivers/nvidia-drivers
	optfeature "AMD ROCm GPU acceleration" dev-libs/rocm-opencl-runtime
}

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

# iced (git dependency) declares rust-version 1.92
RUST_MIN_VER="1.92.0"

inherit cargo desktop git-r3 xdg

DESCRIPTION="A CAD application built with Rust — 2D/3D drawing, DWG/DXF support"
HOMEPAGE="https://github.com/HakanSeven12/OpenCADStudio"

EGIT_REPO_URI="https://github.com/HakanSeven12/OpenCADStudio.git"
if [[ ${PV} != *9999* ]]; then
	EGIT_COMMIT="v${PV}"
	KEYWORDS="~amd64"
fi

LICENSE="GPL-3+"
# Dependent crate licenses
LICENSE+="
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions Boost-1.0 BSD BSD-2
	CC0-1.0 CDLA-Permissive-2.0 ISC LGPL-2.1+ MIT MPL-2.0 OFL-1.1 Unicode-3.0
	Unlicense UoI-NCSA ZLIB
"

SLOT="0"

BDEPEND="
	virtual/pkgconfig
"
DEPEND="
	dev-libs/wayland
	media-libs/libglvnd
	x11-libs/libX11
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libXrandr
	x11-libs/libxcb
	x11-libs/libxkbcommon[X]
"
RDEPEND="
	${DEPEND}
	media-libs/vulkan-loader
"

# Upstream's release profile (strip = true) pre-strips the binary
QA_PRESTRIPPED="usr/bin/OpenCADStudio"

src_unpack() {
	git-r3_src_unpack

	# cargo_live_src_unpack is restricted to 9999 ebuilds, so replicate it
	# here: fetch all dependencies (crates.io + git) into a shared registry
	# and vendor them for the offline build done by the cargo eclass.
	mkdir -p "${ECARGO_VENDOR}" "${ECARGO_HOME}" || die

	local registry_dir="${ECARGO_REGISTRY_DIR:-${PORTAGE_ACTUAL_DISTDIR:-${DISTDIR}}/cargo-registry}"
	addwrite "${registry_dir}"
	mkdir -p "${registry_dir}" || die

	# This export must stay in the global scope so that portage carries it
	# into later phases via the saved environment; src_compile runs with no
	# network access and depends on the offline config in ${ECARGO_HOME}.
	export CARGO_HOME="${registry_dir}"
	pushd "${S}" > /dev/null || die
	"${CARGO}" fetch --locked || die
	"${CARGO}" vendor --locked "${ECARGO_VENDOR}" || die
	popd > /dev/null || die
	unset CARGO_HOME

	# cargo vendor copies the crate sources, but the git checkouts of the
	# git dependencies must stay reachable from the offline CARGO_HOME.
	if [[ -d ${registry_dir}/git && ! -L ${ECARGO_HOME}/git ]]; then
		ln -s "${registry_dir}/git" "${ECARGO_HOME}/git" || die
	fi

	cargo_gen_config
}

src_install() {
	# --locked: plain "cargo install" ignores Cargo.lock and re-resolves the
	# git branch dependencies (iced_aw), which needs network access that the
	# sandbox blocks; the lockfile pins them to the fetched revisions instead.
	# --bin: 2026.37 added src/bin/ocs_launcher.rs, a macOS-only helper that
	# compiles to an empty main() everywhere else; without this it would land
	# in /usr/bin as a do-nothing binary.
	cargo_src_install --locked --bin OpenCADStudio

	dodoc README.md

	# Upstream's metainfo references this desktop file id
	newmenu packaging/OpenCADStudio.desktop io.github.HakanSeven12.OpenCadStudio.desktop
	insinto /usr/share/metainfo
	doins packaging/io.github.HakanSeven12.OpenCadStudio.metainfo.xml
	newicon -s scalable assets/logo.svg io.github.HakanSeven12.OpenCadStudio.svg
	insinto /usr/share/icons/hicolor/scalable/mimetypes
	doins assets/mimetypes/image-vnd.dwg.svg assets/mimetypes/image-vnd.dxf.svg
}

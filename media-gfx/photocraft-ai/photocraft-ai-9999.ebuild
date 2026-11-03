# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

inherit cargo desktop git-r3 shell-completion xdg

DESCRIPTION="PhotoCraft image editor fork with built-in AI editing"
HOMEPAGE="https://github.com/firesand/photocraft-ai"
# The firesand fork adds OpenAI-compatible and local image services. Its
# main branch mirrors official PhotoCraft, so follow the AI integration branch.
EGIT_REPO_URI="https://github.com/firesand/photocraft-ai.git"
EGIT_BRANCH="ai-main"

# PhotoCraft code and app icon are MIT OR Apache-2.0. Embedded assets: Inter
# and JetBrains Mono fonts (OFL-1.1), Lucide/Feather icons (ISC, MIT), the
# SCOWL word list (myspell-en_CA-KevinAtkinson) and libfacedetection weights
# (BSD). The ArtCraft brand artwork under docs/brand is not installed.
LICENSE="|| ( Apache-2.0 MIT ) BSD ISC MIT OFL-1.1 myspell-en_CA-KevinAtkinson"
# Dependent crate licenses
LICENSE+="
	Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD-2 BSD Boost-1.0
	CDLA-Permissive-2.0 IJG ISC MIT MPL-2.0 UoI-NCSA Unicode-3.0 ZLIB
"
SLOT="0"
IUSE="+heif"
# The upstream suite has thousands of tests, many of which need a GPU.
RESTRICT="test"

BDEPEND="
	virtual/pkgconfig
"
# winit, wgpu and xkbcommon load these with dlopen() at runtime
# (packaging/linux/nfpm.yaml), so they are not ELF NEEDED entries.
RDEPEND="
	dev-libs/wayland
	|| (
		media-libs/vulkan-loader
		media-libs/libglvnd
	)
	sys-apps/xdg-desktop-portal
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libxkbcommon[X]
"

src_unpack() {
	git-r3_src_unpack
	# Vendors crates.io and the egui, winit, craft-libs and winprint git
	# dependencies; the git checkouts stay reachable for the offline build.
	cargo_live_src_unpack

	# zbus-lockstep's validate macro prefers ../xml over atspi-common's own
	# xml/ directory, and cargo vendor names the xml crate's directory plain
	# "xml". The macro then panics on that crate's extensionless files.
	# Cargo finds vendored crates by their manifests, not directory names.
	if [[ -d ${ECARGO_VENDOR}/xml ]]; then
		mv "${ECARGO_VENDOR}"/xml{,-crate} || die
	fi
}

src_compile() {
	export PHOTOCRAFT_BUILD_SHA="${EGIT_VERSION}"
	export PHOTOCRAFT_BUILD_DATE="$(date -u +%Y-%m-%d)"

	cargo_src_compile -p photocraft -p photocraft-cli --bins \
		$(usev heif "--features heif")
	# Upstream builds this example in its own cargo run so its
	# dev-dependencies' features are not unified into the binaries.
	cargo_src_compile -p photocraft-cli --example man-and-completions \
		$(usev heif "--features heif")

	"$(cargo_target_dir)"/examples/man-and-completions "${T}"/cli-docs || die
}

src_install() {
	dobin "$(cargo_target_dir)"/{photocraft,photocraft-cli}

	doman "${T}"/cli-docs/*.1
	newbashcomp "${T}"/cli-docs/photocraft-cli.bash photocraft-cli
	newzshcomp "${T}"/cli-docs/_photocraft-cli _photocraft-cli
	newfishcomp "${T}"/cli-docs/photocraft-cli.fish photocraft-cli.fish

	local app_id=ai.storyteller.photocraft version
	version=$(sed -n '/^\[workspace\.package\]/,/^\[/s/^version = "\(.*\)"$/\1/p' Cargo.toml) || die
	[[ -n ${version} ]] || die "Could not read the workspace version"
	domenu packaging/linux/${app_id}.desktop
	insinto /usr/share/mime/packages
	newins packaging/linux/${app_id}.mime.xml ${app_id}.xml
	# Send bug reports for this fork to the fork, not to official PhotoCraft.
	sed -e "s/@VERSION@/${version}/g" -e "s/@DATE@/${PHOTOCRAFT_BUILD_DATE}/g" \
		-e "s|https://github.com/storytold/photocraft/issues|${HOMEPAGE}/issues|" \
		packaging/linux/${app_id}.metainfo.xml.in > "${T}"/${app_id}.metainfo.xml || die
	insinto /usr/share/metainfo
	doins "${T}"/${app_id}.metainfo.xml
	insinto /usr/share/icons
	doins -r assets/app-icon/hicolor

	dodoc README.md NOTICE ATTRIBUTION.md
}

pkg_postinst() {
	xdg_pkg_postinst

	elog "This is an unofficial community fork of PhotoCraft; it installs the"
	elog "same 'photocraft' command and desktop ID as upstream PhotoCraft."
	elog
	elog "AI services: Codex (ChatGPT subscription, via PATH or"
	elog "PHOTOCRAFT_CODEX_PATH), Gemini, Seedream, FLUX, any OpenAI-compatible"
	elog "image API, and ComfyUI workflows saved in API format under"
	elog "~/.config/photocraft-ai/comfyui-workflows/. Keys are stored through the"
	elog "Secret Service API; local addresses (localhost, 127.0.0.1) need no key."
	elog "Generation sends the image and prompt to the selected service."
}

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

RUST_MIN_VER="1.95.0"

inherit cargo desktop git-r3 optfeature xdg

DESCRIPTION="Mister Download Manager with Plexo's network combining and Usenet downloads"
HOMEPAGE="https://github.com/firesand/misterdownloadmanager"
# The firesand fork's main branch mirrors upstream Mister Download Manager.
# Its combined branch adds Combine networks and Usenet (NZB) downloads.
EGIT_REPO_URI="https://github.com/firesand/misterdownloadmanager.git"
EGIT_BRANCH="combined"

# The programs are GPL-3+. Embedded assets (ATTRIBUTION.md): Lucide (ISC),
# flag-icons and Fluent UI icons (MIT), Tango icons (public domain), Silk
# icons (CC-BY-2.5), Adwaita and Breeze icons (LGPL-3, LGPL-3+) and the DB-IP
# country database (CC-BY-4.0).
LICENSE="GPL-3+ CC-BY-2.5 CC-BY-4.0 ISC LGPL-3 LGPL-3+ MIT public-domain"
# Dependent crate licenses
LICENSE+="
	0BSD Apache-2.0 Apache-2.0-with-LLVM-exceptions BSD BSD-2 Boost-1.0
	CDLA-Permissive-2.0 ISC MIT MPL-2.0 OFL-1.1 UbuntuFontLicense-1.0
	Unicode-3.0 Unlicense ZLIB
"
SLOT="0"
# The suite has some 850 tests that start local HTTP, FTP and news servers,
# and the release profile links every test program with fat LTO.
RESTRICT="test"

BDEPEND="
	app-arch/zip
	virtual/imagemagick-tools[png]
	virtual/pkgconfig
"
# winit, glutin, xkbcommon and the tray load these with dlopen() at run time,
# so they are not ELF NEEDED entries. File dialogs go through the desktop
# portal, and downloads need the system's CA certificates.
RDEPEND="
	app-misc/ca-certificates
	dev-libs/wayland
	media-libs/libglvnd
	sys-apps/dbus
	sys-apps/xdg-desktop-portal
	x11-libs/libX11
	x11-libs/libxcb
	x11-libs/libXcursor
	x11-libs/libXi
	x11-libs/libXrender
	x11-libs/libxkbcommon[X]
"

QA_FLAGS_IGNORED="usr/bin/misterdownloadmanager.*"

src_unpack() {
	git-r3_src_unpack
	# Vendors crates.io and the egui, rqbit and craft-libs git dependencies.
	# cargo.eclass fetches from the current directory, which is still
	# ${WORKDIR} in this phase.
	cd "${S}" || die
	cargo_live_src_unpack
}

src_configure() {
	cargo_src_configure --locked
}

src_compile() {
	# One cargo run for the four programs, as upstream's packages are built
	# (tools/installer/build-linux.sh).
	cargo_src_compile -p mdm-app -p mdm-nmhost -p mdm-cli -p mdm-mcp

	local version
	version=$(sed -n '/^\[workspace\.package\]/,/^\[/s/^version = "\(.*\)"$/\1/p' Cargo.toml) || die
	[[ -n ${version} ]] || die "Could not read the workspace version"

	# The browser extension, as tools/extension/pack.ps1 packs it (that
	# script needs PowerShell): each browser family's manifest with the
	# program's version, so an extension and its program always match.
	local kind manifest dir
	for kind in chromium firefox; do
		dir="${T}"/extension/extension-${kind}
		mkdir -p "${dir}" || die
		cp -r extension/{background.js,video.js,page.js,popup.html,popup.css,popup.js} \
			extension/{icons,_locales} "${dir}"/ || die
		manifest=manifest.json
		[[ ${kind} == firefox ]] && manifest=manifest.firefox.json
		sed -E "0,/(\"version\"[[:space:]]*:[[:space:]]*)\"[^\"]*\"/s//\1\"${version}\"/" \
			extension/${manifest} > "${dir}"/manifest.json || die
	done
	# Chrome takes Norwegian only as "no"; Firefox looks for "nb".
	dir="${T}"/extension/extension-firefox/_locales
	if [[ -d ${dir}/no ]]; then
		cp -r "${dir}"/no "${dir}"/nb || die
	fi
	pushd "${T}"/extension/extension-firefox >/dev/null || die
	zip -q -r -X ../mdm-firefox.xpi . || die
	popd >/dev/null || die

	# The browsers' native messaging manifests for every user, naming
	# /usr/bin/misterdownloadmanager-nmhost, as upstream's .deb and .rpm
	# carry them: /etc/opt/chrome, /etc/chromium, /etc/opt/edge and
	# /usr/lib{,64}/mozilla.
	"$(cargo_target_dir)"/misterdownloadmanager-nmhost \
		--package-manifests "${T}"/system || die

	convert "art/Mister Download Manager.png" -resize 256x256 \
		"${T}"/${PN}.png || die

	cat > "${T}"/${PN}.desktop <<-EOF || die
		[Desktop Entry]
		Type=Application
		Name=Mister Download Manager
		Comment=Download manager
		Exec=misterdownloadmanager %U
		Icon=misterdownloadmanager
		Terminal=false
		Categories=Network;FileTransfer;
		MimeType=x-scheme-handler/magnet;application/x-bittorrent;application/x-nzb;
	EOF
}

src_install() {
	dobin "$(cargo_target_dir)"/misterdownloadmanager{,-cli,-mcp,-nmhost}

	insinto /usr/share/${PN}
	doins -r "${T}"/extension/extension-chromium
	doins "${T}"/extension/mdm-firefox.xpi

	insinto /
	doins -r "${T}"/system/{etc,usr}

	domenu "${T}"/${PN}.desktop
	doicon -s 256 "${T}"/${PN}.png

	dodoc README.md CHANGELOG.md ATTRIBUTION.md
	dodoc docs/combine-networks.md docs/usenet.md docs/browser-integration.md
}

pkg_postinst() {
	xdg_pkg_postinst

	optfeature "video downloads from YouTube and other sites" net-misc/yt-dlp
	optfeature "joining a video with its separate sound" media-video/ffmpeg
	optfeature "image gallery downloads" net-misc/gallery-dl
	optfeature "YouTube formats that need a JavaScript runtime" net-libs/nodejs

	elog "This is the firesand fork of Mister Download Manager: upstream's"
	elog "program plus Combine networks (Downloads -> Combine networks...) and"
	elog "Usenet downloads (Tasks -> Open NZB file...). It installs the same"
	elog "commands and desktop entry an upstream package would."
	elog
	elog "Browsers: add the extension from the Chrome Web Store or"
	elog "addons.mozilla.org (the program offers to at its first start), or"
	elog "load ${EPREFIX}/usr/share/${PN}/extension-chromium unpacked."
}

# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Draw a map of a folder of markdown notes and read it in a browser"
HOMEPAGE="https://md2hd.com/
	https://github.com/evan-steinhilb/md2hd"

# Upstream publishes no git tags or GitHub releases, and the visualizer in
# dist/ is built from a separate unpublished repository, so the npm tarball is
# both the only versioned artifact and the only source of the bundled app.
SRC_URI="https://registry.npmjs.org/${PN}/-/${P}.tgz"
S="${WORKDIR}/package"

LICENSE="MIT"
SLOT="0"
# Pure JavaScript; nothing here is architecture specific.
KEYWORDS="~amd64"

# The CLI has no npm dependencies and runs on the Node standard library alone.
# xdg-open launches the browser unless --no-open is passed.
RDEPEND="
	>=net-libs/nodejs-18
	x11-misc/xdg-utils
"

src_install() {
	# bin/md2hd.mjs resolves the bundled app as <script dir>/../dist, so the
	# two have to stay siblings. Node resolves the launcher symlink to its
	# real path, which keeps that lookup landing here.
	insinto "/usr/share/${PN}"
	doins -r dist skills

	exeinto "/usr/share/${PN}/bin"
	doexe bin/md2hd.mjs

	dosym -r "/usr/share/${PN}/bin/md2hd.mjs" "/usr/bin/${PN}"

	dodoc README.md
}

pkg_postinst() {
	elog "Point md2hd at a note or a folder of notes:"
	elog "  md2hd notes/"
	elog "  md2hd map.md --port 8080 --no-open"
	elog
	elog "It serves the map from 127.0.0.1 only (default port 4173) and opens"
	elog "your browser with xdg-open; pass --no-open to skip that. Files are"
	elog "re-read on every request, so refreshing the tab picks up your edits."
	elog
	elog "The authoring guide upstream ships for coding agents is installed at"
	elog "/usr/share/${PN}/skills/writing-md2hd-maps/SKILL.md"
}

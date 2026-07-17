# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module systemd

DESCRIPTION="Plugin-based data provider service for application launchers"
HOMEPAGE="https://github.com/abenz1267/elephant"
SRC_URI="
	https://github.com/abenz1267/elephant/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.tar.gz
	https://github.com/firesand/edorp-overlay/releases/download/elephant-vendor-${PV}/${P}-vendor.tar.xz
"

LICENSE="Apache-2.0 BSD BSD-2 GPL-3 HPND ISC MIT Unicode-3.0 Unicode-DFS-2016"
SLOT="0"
KEYWORDS="~amd64"
IUSE="
	1password bitwarden bluetooth bookmarks clipboard files menus niri
	playerctl snippets symbols test todo unicode windows wireplumber
"
RESTRICT="!test? ( test )"

# These providers cover Walker's default query plus its provider and runner
# prefixes. Keeping them in this ebuild is required by Go's exact plugin ABI.
ELEPHANT_CORE_PROVIDERS=(
	calc
	desktopapplications
	providerlist
	runner
	websearch
)

SQLITE_DEP="
	files? ( dev-db/sqlite:3= )
"

DEPEND="
	${SQLITE_DEP}
	test? ( dev-db/sqlite:3 )
"
RDEPEND="
	${SQLITE_DEP}
	gui-apps/wl-clipboard
	sci-libs/libqalculate
	x11-misc/xdg-utils
	1password? (
		|| (
			app-admin/op-cli-bin
			app-misc/1password-cli
		)
		x11-libs/libnotify
	)
	bitwarden? (
		app-admin/rbw
		gui-apps/wtype
		x11-libs/libnotify
	)
	bluetooth? ( net-wireless/bluez[readline] )
	bookmarks? (
		app-misc/jq
		dev-db/sqlite:3
	)
	clipboard? ( virtual/imagemagick-tools[png] )
	files? ( sys-apps/fd )
	menus? ( dev-vcs/git )
	niri? ( gui-wm/niri )
	playerctl? ( media-sound/playerctl )
	snippets? ( gui-apps/wtype )
	todo? (
		media-sound/playerctl
		x11-libs/libnotify
	)
	wireplumber? (
		media-video/pipewire
		media-video/wireplumber
	)
"
BDEPEND+=" >=dev-lang/go-1.25.0:="

DOCS=(
	BREAKING.md
	README.md
)

src_compile() {
	local -x CGO_ENABLED=1
	local -a build_flags=(
		-buildvcs=false
		-mod=vendor
		-trimpath
		-tags=libsqlite3
	)
	local -a providers=( "${ELEPHANT_CORE_PROVIDERS[@]}" )

	use 1password && providers+=( 1password )
	use bitwarden && providers+=( bitwarden )
	use bluetooth && providers+=( bluetooth )
	use bookmarks && providers+=( bookmarks )
	use clipboard && providers+=( clipboard )
	use files && providers+=( files )
	use menus && providers+=( menus )
	use niri && providers+=( niriactions nirisessions )
	use playerctl && providers+=( playerctl )
	use snippets && providers+=( snippets )
	use symbols && providers+=( symbols )
	use todo && providers+=( todo )
	use unicode && providers+=( unicode )
	use windows && providers+=( windows )
	use wireplumber && providers+=( wireplumber )

	mkdir -p build/providers || die

	ego build "${build_flags[@]}" -o build/elephant ./cmd/elephant

	local provider
	for provider in "${providers[@]}"; do
		ego build "${build_flags[@]}" -buildmode=plugin \
			-o "build/providers/${provider}.so" \
			"./internal/providers/${provider}"
	done
}

src_test() {
	local -x CGO_ENABLED=1
	ego test -mod=vendor -tags=libsqlite3 ./...

	mkdir -p "${T}/config" "${T}/cache" "${T}/runtime" || die
	chmod 0700 "${T}/runtime" || die

	local output provider
	local -a loaded
	output=$(
		XDG_CONFIG_HOME="${T}/config" \
		XDG_CONFIG_DIRS="${T}/config" \
		XDG_CACHE_HOME="${T}/cache" \
		XDG_RUNTIME_DIR="${T}/runtime" \
		ELEPHANT_PROVIDER_DIR="${S}/build/providers" \
			./build/elephant listproviders
	) || die "provider ABI smoke test failed"
	readarray -t loaded <<< "${output}"

	for provider in "${ELEPHANT_CORE_PROVIDERS[@]}"; do
		has "${provider}" "${loaded[@]}" ||
			die "core provider ${provider} failed to load"
	done
}

src_install() {
	dobin build/elephant

	exeinto "/usr/$(get_libdir)/elephant/providers"
	doexe build/providers/*.so

	systemd_douserunit assets/elephant.service

	einstalldocs
}

pkg_postinst() {
	elog "Elephant must run inside the graphical user environment."
	elog "On systemd, enable its user service with:"
	elog "  systemctl --user enable --now elephant.service"
	elog "On non-systemd sessions, autostart /usr/bin/elephant from the compositor"
	elog "or desktop session. Do not run Elephant as a system-wide service."

	if use files; then
		ewarn "The files provider indexes your home directory when Elephant starts."
		ewarn "Review its ignored_dirs setting before enabling the service."
	fi
}

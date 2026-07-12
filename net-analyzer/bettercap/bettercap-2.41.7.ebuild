# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit go-module optfeature

# Upstream caplets snapshot from 2026-07-07.
CAPLETS_COMMIT="eb626871ad99ea8c4f9771f216caa2290e06a058"

EGO_SUM=(
	"github.com/acarl005/stripansi v0.0.0-20180116102854-5a71ef0e047d"
	"github.com/acarl005/stripansi v0.0.0-20180116102854-5a71ef0e047d/go.mod"
	"github.com/adrianmo/go-nmea v1.10.0"
	"github.com/adrianmo/go-nmea v1.10.0/go.mod"
	"github.com/antchfx/jsonquery v1.3.6"
	"github.com/antchfx/jsonquery v1.3.6/go.mod"
	"github.com/antchfx/xpath v1.3.2/go.mod"
	"github.com/antchfx/xpath v1.3.4"
	"github.com/antchfx/xpath v1.3.4/go.mod"
	"github.com/bettercap/gatt v0.0.0-20240808115956-ec4935e8c4a0"
	"github.com/bettercap/gatt v0.0.0-20240808115956-ec4935e8c4a0/go.mod"
	"github.com/bettercap/nrf24 v0.0.0-20190219153547-aa37e6d0e0eb"
	"github.com/bettercap/nrf24 v0.0.0-20190219153547-aa37e6d0e0eb/go.mod"
	"github.com/bettercap/readline v0.0.0-20210228151553-655e48bcb7bf"
	"github.com/bettercap/readline v0.0.0-20210228151553-655e48bcb7bf/go.mod"
	"github.com/bettercap/recording v0.0.0-20190408083647-3ce1dcf032e3"
	"github.com/bettercap/recording v0.0.0-20190408083647-3ce1dcf032e3/go.mod"
	"github.com/cenkalti/backoff v2.2.1+incompatible"
	"github.com/cenkalti/backoff v2.2.1+incompatible/go.mod"
	"github.com/chzyer/logex v1.2.1"
	"github.com/chzyer/logex v1.2.1/go.mod"
	"github.com/chzyer/test v1.0.0"
	"github.com/chzyer/test v1.0.0/go.mod"
	"github.com/creack/pty v1.1.9/go.mod"
	"github.com/davecgh/go-spew v1.1.0/go.mod"
	"github.com/davecgh/go-spew v1.1.1"
	"github.com/davecgh/go-spew v1.1.1/go.mod"
	"github.com/dustin/go-humanize v1.0.1"
	"github.com/dustin/go-humanize v1.0.1/go.mod"
	"github.com/elazarl/goproxy v1.7.2"
	"github.com/elazarl/goproxy v1.7.2/go.mod"
	"github.com/evilsocket/islazy v1.11.0"
	"github.com/evilsocket/islazy v1.11.0/go.mod"
	"github.com/florianl/go-nfqueue/v2 v2.0.0"
	"github.com/florianl/go-nfqueue/v2 v2.0.0/go.mod"
	"github.com/gobwas/glob v0.0.0-20181002190808-e7a84e9525fe"
	"github.com/gobwas/glob v0.0.0-20181002190808-e7a84e9525fe/go.mod"
	"github.com/golang/groupcache v0.0.0-20210331224755-41bb18bfe9da/go.mod"
	"github.com/golang/groupcache v0.0.0-20241129210726-2c02b8208cf8"
	"github.com/golang/groupcache v0.0.0-20241129210726-2c02b8208cf8/go.mod"
	"github.com/golang/mock v1.6.0"
	"github.com/golang/mock v1.6.0/go.mod"
	"github.com/google/go-cmp v0.5.2/go.mod"
	"github.com/google/go-cmp v0.7.0"
	"github.com/google/go-cmp v0.7.0/go.mod"
	"github.com/google/go-github v17.0.0+incompatible"
	"github.com/google/go-github v17.0.0+incompatible/go.mod"
	"github.com/google/go-querystring v1.1.0"
	"github.com/google/go-querystring v1.1.0/go.mod"
	"github.com/google/gousb v1.1.3"
	"github.com/google/gousb v1.1.3/go.mod"
	"github.com/gopacket/gopacket v1.3.1"
	"github.com/gopacket/gopacket v1.3.1/go.mod"
	"github.com/gorilla/mux v1.8.1"
	"github.com/gorilla/mux v1.8.1/go.mod"
	"github.com/gorilla/websocket v1.5.3"
	"github.com/gorilla/websocket v1.5.3/go.mod"
	"github.com/hashicorp/go-bexpr v0.1.14"
	"github.com/hashicorp/go-bexpr v0.1.14/go.mod"
	"github.com/inconshreveable/go-vhost v1.0.0"
	"github.com/inconshreveable/go-vhost v1.0.0/go.mod"
	"github.com/josharian/native v1.1.0"
	"github.com/josharian/native v1.1.0/go.mod"
	"github.com/jpillora/go-tld v1.2.1"
	"github.com/jpillora/go-tld v1.2.1/go.mod"
	"github.com/kr/binarydist v0.1.0"
	"github.com/kr/binarydist v0.1.0/go.mod"
	"github.com/kr/pretty v0.2.1"
	"github.com/kr/pretty v0.2.1/go.mod"
	"github.com/kr/pty v1.1.1/go.mod"
	"github.com/kr/text v0.1.0/go.mod"
	"github.com/kr/text v0.2.0"
	"github.com/kr/text v0.2.0/go.mod"
	"github.com/malfunkt/iprange v0.9.0"
	"github.com/malfunkt/iprange v0.9.0/go.mod"
	"github.com/mattn/go-colorable v0.1.8/go.mod"
	"github.com/mattn/go-colorable v0.1.14"
	"github.com/mattn/go-colorable v0.1.14/go.mod"
	"github.com/mattn/go-isatty v0.0.12/go.mod"
	"github.com/mattn/go-isatty v0.0.20"
	"github.com/mattn/go-isatty v0.0.20/go.mod"
	"github.com/mdlayher/dhcp6 v0.0.0-20190311162359-2a67805d7d0b"
	"github.com/mdlayher/dhcp6 v0.0.0-20190311162359-2a67805d7d0b/go.mod"
	"github.com/mdlayher/netlink v1.7.2"
	"github.com/mdlayher/netlink v1.7.2/go.mod"
	"github.com/mdlayher/socket v0.5.1"
	"github.com/mdlayher/socket v0.5.1/go.mod"
	"github.com/mgutz/ansi v0.0.0-20200706080929-d51e80ef957d"
	"github.com/mgutz/ansi v0.0.0-20200706080929-d51e80ef957d/go.mod"
	"github.com/mgutz/logxi v0.0.0-20161027140823-aebf8a7d67ab"
	"github.com/mgutz/logxi v0.0.0-20161027140823-aebf8a7d67ab/go.mod"
	"github.com/miekg/dns v1.1.67"
	"github.com/miekg/dns v1.1.67/go.mod"
	"github.com/mitchellh/go-homedir v1.1.0"
	"github.com/mitchellh/go-homedir v1.1.0/go.mod"
	"github.com/mitchellh/mapstructure v1.4.1/go.mod"
	"github.com/mitchellh/mapstructure v1.5.0"
	"github.com/mitchellh/mapstructure v1.5.0/go.mod"
	"github.com/mitchellh/pointerstructure v1.2.1"
	"github.com/mitchellh/pointerstructure v1.2.1/go.mod"
	"github.com/phin1x/go-ipp v1.6.1"
	"github.com/phin1x/go-ipp v1.6.1/go.mod"
	"github.com/pkg/errors v0.9.1"
	"github.com/pkg/errors v0.9.1/go.mod"
	"github.com/pmezard/go-difflib v1.0.0"
	"github.com/pmezard/go-difflib v1.0.0/go.mod"
	"github.com/robertkrimen/otto v0.5.1"
	"github.com/robertkrimen/otto v0.5.1/go.mod"
	"github.com/stratoberry/go-gpsd v1.3.0"
	"github.com/stratoberry/go-gpsd v1.3.0/go.mod"
	"github.com/stretchr/objx v0.1.0/go.mod"
	"github.com/stretchr/objx v0.4.0/go.mod"
	"github.com/stretchr/objx v0.5.0/go.mod"
	"github.com/stretchr/testify v1.5.1/go.mod"
	"github.com/stretchr/testify v1.7.0/go.mod"
	"github.com/stretchr/testify v1.7.1/go.mod"
	"github.com/stretchr/testify v1.8.0/go.mod"
	"github.com/stretchr/testify v1.8.4/go.mod"
	"github.com/stretchr/testify v1.10.0"
	"github.com/stretchr/testify v1.10.0/go.mod"
	"github.com/tarm/serial v0.0.0-20180830185346-98f6abe2eb07"
	"github.com/tarm/serial v0.0.0-20180830185346-98f6abe2eb07/go.mod"
	"github.com/thoj/go-ircevent v0.0.0-20210723090443-73e444401d64"
	"github.com/thoj/go-ircevent v0.0.0-20210723090443-73e444401d64/go.mod"
	"github.com/vishvananda/netlink v1.1.0"
	"github.com/vishvananda/netlink v1.1.0/go.mod"
	"github.com/vishvananda/netns v0.0.0-20211101163701-50045581ed74"
	"github.com/vishvananda/netns v0.0.0-20211101163701-50045581ed74/go.mod"
	"github.com/yuin/goldmark v1.3.5/go.mod"
	"go.einride.tech/can v0.14.0"
	"go.einride.tech/can v0.14.0/go.mod"
	"go.uber.org/goleak v1.3.0"
	"go.uber.org/goleak v1.3.0/go.mod"
	"golang.org/x/crypto v0.0.0-20190308221718-c2843e01d9a2/go.mod"
	"golang.org/x/crypto v0.0.0-20191011191535-87dc89f01550/go.mod"
	"golang.org/x/mod v0.4.2/go.mod"
	"golang.org/x/mod v0.26.0"
	"golang.org/x/mod v0.26.0/go.mod"
	"golang.org/x/net v0.0.0-20190310074541-c10a0554eabf/go.mod"
	"golang.org/x/net v0.0.0-20190404232315-eb5bcb51f2a3/go.mod"
	"golang.org/x/net v0.0.0-20190620200207-3b0461eec859/go.mod"
	"golang.org/x/net v0.0.0-20210405180319-a5a99cb37ef4/go.mod"
	"golang.org/x/net v0.0.0-20210614182718-04defd469f4e/go.mod"
	"golang.org/x/net v0.0.0-20220225172249-27dd8689420f/go.mod"
	"golang.org/x/net v0.42.0"
	"golang.org/x/net v0.42.0/go.mod"
	"golang.org/x/sync v0.0.0-20190423024810-112230192c58/go.mod"
	"golang.org/x/sync v0.0.0-20210220032951-036812b2e83c/go.mod"
	"golang.org/x/sync v0.16.0"
	"golang.org/x/sync v0.16.0/go.mod"
	"golang.org/x/sys v0.0.0-20190215142949-d0b11bdaac8a/go.mod"
	"golang.org/x/sys v0.0.0-20190412213103-97732733099d/go.mod"
	"golang.org/x/sys v0.0.0-20200116001909-b77594299b42/go.mod"
	"golang.org/x/sys v0.0.0-20200223170610-d5e6a3e2c0ae/go.mod"
	"golang.org/x/sys v0.0.0-20201119102817-f84b799fce68/go.mod"
	"golang.org/x/sys v0.0.0-20210330210617-4fbd30eecc44/go.mod"
	"golang.org/x/sys v0.0.0-20210403161142-5e06dd20ab57/go.mod"
	"golang.org/x/sys v0.0.0-20210423082822-04245dca01da/go.mod"
	"golang.org/x/sys v0.0.0-20210510120138-977fb7262007/go.mod"
	"golang.org/x/sys v0.0.0-20210615035016-665e8c7367d1/go.mod"
	"golang.org/x/sys v0.0.0-20211216021012-1d35b9e2eb4e/go.mod"
	"golang.org/x/sys v0.6.0/go.mod"
	"golang.org/x/sys v0.34.0"
	"golang.org/x/sys v0.34.0/go.mod"
	"golang.org/x/term v0.0.0-20201126162022-7de9c90e9dd1/go.mod"
	"golang.org/x/term v0.0.0-20210927222741-03fcf44c2211/go.mod"
	"golang.org/x/text v0.3.0/go.mod"
	"golang.org/x/text v0.3.3/go.mod"
	"golang.org/x/text v0.3.6/go.mod"
	"golang.org/x/text v0.3.7/go.mod"
	"golang.org/x/text v0.27.0"
	"golang.org/x/text v0.27.0/go.mod"
	"golang.org/x/tools v0.0.0-20180917221912-90fa682c2a6e/go.mod"
	"golang.org/x/tools v0.0.0-20191119224855-298f0cb1881e/go.mod"
	"golang.org/x/tools v0.1.1/go.mod"
	"golang.org/x/tools v0.35.0"
	"golang.org/x/tools v0.35.0/go.mod"
	"golang.org/x/xerrors v0.0.0-20190717185122-a985d3407aa7/go.mod"
	"golang.org/x/xerrors v0.0.0-20191011141410-1b5146add898/go.mod"
	"golang.org/x/xerrors v0.0.0-20191204190536-9bdfabe68543/go.mod"
	"golang.org/x/xerrors v0.0.0-20200804184101-5ec99f83aff1/go.mod"
	"gopkg.in/check.v1 v0.0.0-20161208181325-20d25e280405/go.mod"
	"gopkg.in/check.v1 v1.0.0-20201130134442-10cb98267c6c"
	"gopkg.in/check.v1 v1.0.0-20201130134442-10cb98267c6c/go.mod"
	"gopkg.in/sourcemap.v1 v1.0.5"
	"gopkg.in/sourcemap.v1 v1.0.5/go.mod"
	"gopkg.in/yaml.v2 v2.2.2/go.mod"
	"gopkg.in/yaml.v3 v3.0.0-20200313102051-9f266ea9e77c/go.mod"
	"gopkg.in/yaml.v3 v3.0.0-20210107192922-496545a6307b/go.mod"
	"gopkg.in/yaml.v3 v3.0.1"
	"gopkg.in/yaml.v3 v3.0.1/go.mod"
	"gotest.tools/v3 v3.5.1"
	"gotest.tools/v3 v3.5.1/go.mod"
)
go-module_set_globals

DESCRIPTION="Modular framework for WiFi, Bluetooth, Ethernet, and MITM testing"
HOMEPAGE="https://www.bettercap.org/ https://github.com/bettercap/bettercap"
SRC_URI="
	https://github.com/bettercap/bettercap/archive/v${PV}.tar.gz -> ${P}.tar.gz
	https://github.com/bettercap/caplets/archive/${CAPLETS_COMMIT}.tar.gz
		-> ${P}-caplets-${CAPLETS_COMMIT}.tar.gz
	${EGO_SUM_SRC_URI}
"

LICENSE="
	GPL-3
	Apache-2.0 BSD BSD-2 MIT MPL-2.0
	CC-BY-4.0 OFL-1.1
"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	net-libs/libpcap
	virtual/libusb:1
"
DEPEND="${RDEPEND}"
BDEPEND+=" virtual/pkgconfig"

PATCHES=(
	"${FILESDIR}/${P}-portage-managed-caplets.patch"
)

DOCS=(
	README.md
	SECURITY.md
)

export GOTOOLCHAIN=local

src_prepare() {
	default

	# Respect Gentoo's /usr layout instead of searching /usr/local at runtime.
	sed -e "s:/usr/local/share/bettercap/:${EPREFIX}/usr/share/bettercap/:" \
		-i caplets/env.go caplets/env_test.go || die
}

src_compile() {
	ego build -trimpath -mod=readonly -o bettercap .
}

src_test() {
	ego test -mod=readonly ./...
}

src_install() {
	dobin bettercap
	einstalldocs

	insinto /usr/share/bettercap/caplets
	doins -r "${WORKDIR}/caplets-${CAPLETS_COMMIT}"/*

	docinto licenses
	newdoc modules/ui/ui/assets/fontawesome/LICENSE.txt fontawesome-LICENSE.txt
}

pkg_postinst() {
	optfeature "firewall redirection and packet proxy modules" net-firewall/iptables
	optfeature "network route and interface discovery" sys-apps/net-tools
	optfeature "Linux link management" sys-apps/iproute2
	optfeature "nl80211 wireless interface management" net-wireless/iw
	optfeature "wireless frequency discovery and fallback controls" net-wireless/wireless-tools
	optfeature "WiFi brute-force module" net-wireless/wpa_supplicant

	elog "The bundled caplets are managed by Portage; caplets.update is disabled."
	elog "Bettercap performs packet capture, injection, and network reconfiguration."
	elog "Run it with sufficient privileges, and only on systems you are authorized to test."
}

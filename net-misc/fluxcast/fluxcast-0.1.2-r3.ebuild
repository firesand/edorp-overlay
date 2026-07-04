EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{10..14} )

inherit desktop distutils-r1 xdg

PATCHES=(
	"${FILESDIR}/fluxcast-0.1.2-portal-before-wfd.patch"
)

DESCRIPTION="Stream your Linux desktop to a Smart TV via Miracast/WFD, DLNA, or Chromecast"
HOMEPAGE="https://github.com/IlyaP358/fluxcast https://pypi.org/project/fluxcast/"
SRC_URI="https://github.com/IlyaP358/fluxcast/archive/refs/tags/v${PV}.tar.gz -> ${P}.gh.tar.gz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	dev-libs/libayatana-appindicator
	dev-libs/glib
	dev-python/dbus-next[${PYTHON_USEDEP}]
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/pychromecast[${PYTHON_USEDEP}]
	dev-python/pygobject[${PYTHON_USEDEP}]
	dev-python/pystray[${PYTHON_USEDEP}]
	dev-python/python-dateutil[${PYTHON_USEDEP}]
	dev-python/upnpclient[${PYTHON_USEDEP}]
	media-libs/gst-plugins-bad
	media-libs/gst-plugins-base
	media-libs/gst-plugins-good
	media-libs/gstreamer
	media-libs/libpulse
	media-plugins/gst-plugins-hls
	media-plugins/gst-plugins-libav
	media-plugins/gst-plugins-pulse
	media-plugins/gst-plugins-x264
	media-video/ffmpeg[x264]
	media-video/pipewire[gstreamer]
	net-misc/networkmanager[tools,wifi]
	net-wireless/iw
	net-wireless/wpa_supplicant[dbus,p2p,wps]
	sys-apps/xdg-desktop-portal
	x11-apps/xrandr
	x11-libs/libnotify
"

src_install() {
	distutils-r1_src_install

	domenu meta/fluxcast.desktop
	newicon -s 512 src/assets/flcast_logo_512x512.png fluxcast.png

	insinto /usr/share/dbus-1/system.d
	doins meta/zz-dev.fluxcast.wpa-supplicant.conf
}

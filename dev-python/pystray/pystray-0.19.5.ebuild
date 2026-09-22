EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{10..14} )

inherit distutils-r1

DESCRIPTION="This library allows you to create a system tray icon"
HOMEPAGE="https://github.com/moses-palmer/pystray https://pypi.org/project/pystray/"
# Upstream stopped publishing sdists on PyPI after 0.19.3, so use the tag
# archive; it carries the same setup.py the old sdist was generated from.
SRC_URI="
	https://github.com/moses-palmer/pystray/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="LGPL-3"
SLOT="0"
KEYWORDS="~amd64 ~x86"

RDEPEND="
	dev-python/pillow[${PYTHON_USEDEP}]
	dev-python/python-xlib[${PYTHON_USEDEP}]
	dev-python/six[${PYTHON_USEDEP}]
"

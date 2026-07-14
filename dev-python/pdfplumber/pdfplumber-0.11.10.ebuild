# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1

DESCRIPTION="Extract text, tables, and layout details from PDF files"
HOMEPAGE="
	https://github.com/jsvine/pdfplumber
	https://pypi.org/project/pdfplumber/
"
SRC_URI="
	https://github.com/jsvine/pdfplumber/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	~app-text/pdfminer-20260107[${PYTHON_USEDEP}]
	>=dev-python/pillow-12.2.0[${PYTHON_USEDEP}]
"

PATCHES=(
	"${FILESDIR}/${P}-optional-pypdfium2.patch"
)

DOCS=( CHANGELOG.md CONTRIBUTING.md README.md )

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

python_test() {
	# Rendering tests require pypdfium2.  Exercise the supported text and
	# table extraction paths against the upstream PDF fixtures instead.
	epytest -o addopts= \
		tests/test_basics.py \
		tests/test_table.py
}

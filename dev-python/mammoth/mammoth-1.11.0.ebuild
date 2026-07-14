# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1

DESCRIPTION="Convert DOCX documents to simple and clean HTML"
HOMEPAGE="
	https://github.com/mwilliamson/python-mammoth
	https://pypi.org/project/mammoth/
"
SRC_URI="
	https://github.com/mwilliamson/python-mammoth/archive/refs/tags/${PV}.tar.gz
		-> ${P}.gh.tar.gz
"
S="${WORKDIR}/python-${P}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/cobble-0.1.3[${PYTHON_USEDEP}]
	<dev-python/cobble-0.2[${PYTHON_USEDEP}]
"

DOCS=( NEWS README.md )

# The full upstream suite needs several test-only libraries absent from Gentoo.
# Exercise an actual DOCX conversion using the fixture shipped in the release.
distutils_enable_tests unittest

python_prepare_all() {
	cp README.md README || die
	distutils-r1_python_prepare_all
}

python_test() {
	"${EPYTHON}" -c '
from io import BytesIO
from pathlib import Path
import mammoth

document = Path("tests/test-data/single-paragraph.docx").read_bytes()
result = mammoth.convert_to_html(BytesIO(document))
assert result.value == "<p>Walking on imported air</p>"
assert result.messages == []
	' || die "DOCX conversion smoke test failed with ${EPYTHON}"
}

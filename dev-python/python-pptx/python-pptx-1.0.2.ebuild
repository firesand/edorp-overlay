# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="Create, read, and update PowerPoint 2007+ files"
HOMEPAGE="
	https://github.com/scanny/python-pptx
	https://pypi.org/project/python-pptx/
"

LICENSE="MIT"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/lxml-3.1.0[${PYTHON_USEDEP}]
	>=dev-python/pillow-3.3.2[${PYTHON_USEDEP}]
	>=dev-python/typing-extensions-4.9.0[${PYTHON_USEDEP}]
	>=dev-python/xlsxwriter-0.5.7[${PYTHON_USEDEP}]
"
BDEPEND="
	test? ( dev-python/pyparsing[${PYTHON_USEDEP}] )
"

DOCS=( HISTORY.rst README.rst )

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

src_prepare() {
	distutils-r1_src_prepare

	# The test helpers use pyparsing aliases that now emit deprecation
	# warnings, while upstream promotes all warnings to errors.
	sed -i \
		-e 's/dblQuotedString/dbl_quoted_string/g' \
		-e 's/delimitedList/DelimitedList/g' \
		-e 's/removeQuotes/remove_quotes/g' \
		-e 's/stringEnd/string_end/g' \
		-e 's/parseWithTabs/parse_with_tabs/g' \
		-e 's/parseString/parse_string/g' \
		-e 's/setParseAction/set_parse_action/g' \
		tests/unitutil/cxml.py || die

	# pytest 9 requires class-scoped fixtures implemented as methods to be
	# explicit class methods.  These changes affect tests only.
	sed -i \
		-e '/@pytest.fixture(scope="class")/a\    @classmethod' \
		-e 's/def content_type_map(self):/def content_type_map(cls):/' \
		tests/opc/test_package.py || die
	sed -i \
		-e '/@pytest.fixture(scope="class")/a\    @classmethod' \
		-e 's/def dir_pkg_reader(self):/def dir_pkg_reader(cls):/' \
		-e 's/def zip_pkg_reader(self):/def zip_pkg_reader(cls):/' \
		tests/opc/test_serialized.py || die
}

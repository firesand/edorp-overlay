# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=setuptools
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1

DESCRIPTION="Library for defining immutable Python data objects"
HOMEPAGE="
	https://github.com/mwilliamson/python-cobble
	https://pypi.org/project/cobble/
"
SRC_URI="
	https://github.com/mwilliamson/python-cobble/archive/refs/tags/${PV}.tar.gz
		-> ${P}.gh.tar.gz
"
S="${WORKDIR}/python-${P}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64"

DOCS=( README.rst )

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

python_test() {
	# CPython 3.13 changed the wording of abstract-class TypeError messages.
	epytest tests.py \
		--deselect tests.py::test_error_if_visitor_is_missing_methods \
		--deselect tests.py::test_sub_sub_classes_are_included_in_abc
}

# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 pypi

DESCRIPTION="AI-powered content-type detection"
HOMEPAGE="
	https://github.com/google/magika
	https://pypi.org/project/magika/
"

LICENSE="Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"

RDEPEND="
	>=dev-python/click-8.1.7[${PYTHON_USEDEP}]
	>=dev-python/numpy-2.1[${PYTHON_USEDEP}]
	>=dev-python/python-dotenv-1.0.1[${PYTHON_USEDEP}]
	>=sci-libs/onnxruntime-1.17[python,${PYTHON_USEDEP}]
"

DOCS=( CHANGELOG.md README.md )

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

python_test() {
	# The sdist omits tests_data, so run the self-contained model smoke test.
	epytest tests/test_magika_python_module.py::test_magika_module_check_version
}

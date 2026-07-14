# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DISTUTILS_USE_PEP517=hatchling
PYTHON_COMPAT=( python3_{12..14} )

inherit distutils-r1 optfeature

DESCRIPTION="Utility for converting files and documents to Markdown"
HOMEPAGE="
	https://github.com/microsoft/markitdown
	https://pypi.org/project/markitdown/
"
SRC_URI="
	https://github.com/microsoft/markitdown/archive/refs/tags/v${PV}.tar.gz
		-> ${P}.gh.tar.gz
"
S="${WORKDIR}/${P}/packages/markitdown"

LICENSE="MIT Apache-2.0"
SLOT="0"
KEYWORDS="~amd64"
IUSE="docx outlook pdf pptx xls xlsx"

RDEPEND="
	dev-python/beautifulsoup4[${PYTHON_USEDEP}]
	dev-python/charset-normalizer[${PYTHON_USEDEP}]
	dev-python/defusedxml[${PYTHON_USEDEP}]
	>=dev-python/magika-0.6.1[${PYTHON_USEDEP}]
	<dev-python/magika-0.7[${PYTHON_USEDEP}]
	dev-python/markdownify[${PYTHON_USEDEP}]
	dev-python/requests[${PYTHON_USEDEP}]
	docx? (
		>=dev-python/mammoth-1.11[${PYTHON_USEDEP}]
		<dev-python/mammoth-1.12[${PYTHON_USEDEP}]
		dev-python/lxml[${PYTHON_USEDEP}]
	)
	outlook? ( dev-python/olefile[${PYTHON_USEDEP}] )
	pdf? (
		>=app-text/pdfminer-20251230[${PYTHON_USEDEP}]
		>=dev-python/pdfplumber-0.11.9[${PYTHON_USEDEP}]
	)
	pptx? ( dev-python/python-pptx[${PYTHON_USEDEP}] )
	xls? (
		dev-python/pandas[${PYTHON_USEDEP}]
		dev-python/xlrd[${PYTHON_USEDEP}]
	)
	xlsx? (
		dev-python/openpyxl[${PYTHON_USEDEP}]
		dev-python/pandas[${PYTHON_USEDEP}]
	)
"

EPYTEST_PLUGINS=()
distutils_enable_tests pytest

DOCS=( README.md ThirdPartyNotices.md )

python_test() {
	local -x GITHUB_ACTIONS=1
	local -x OPENAI_API_KEY=
	local tests=(
		tests/test_module_misc.py::test_stream_info_operations
		tests/test_module_misc.py::test_data_uris
		tests/test_module_misc.py::test_file_uris
		tests/test_module_misc.py::test_input_as_strings
		tests/test_module_misc.py::test_deeply_nested_html_fallback
		'tests/test_module_vectors.py::test_convert_local[test_vector6]'
		'tests/test_module_vectors.py::test_convert_local[test_vector9]'
		'tests/test_module_vectors.py::test_convert_local[test_vector10]'
		'tests/test_module_vectors.py::test_convert_local[test_vector11]'
	)

	if use docx; then
		tests+=(
			'tests/test_module_vectors.py::test_convert_local[test_vector0]'
			tests/test_module_misc.py::test_docx_comments
			tests/test_module_misc.py::test_docx_equations
		)
	fi
	if use pdf; then
		tests+=(
			'tests/test_module_vectors.py::test_convert_local[test_vector5]'
			tests/test_pdf_tables.py::TestPdfTableExtraction::test_borderless_table_extraction
		)
	fi
	if use pptx; then
		tests+=(
			'tests/test_module_vectors.py::test_convert_local[test_vector3]'
			tests/test_module_misc.py::test_exceptions
		)
	fi
	if use docx && use pptx && use xls && use xlsx; then
		tests+=(
			'tests/test_module_vectors.py::test_convert_local[test_vector13]'
		)
	fi

	epytest "${tests[@]}"

	local cli_version
	cli_version=$("${EPYTHON}" -m markitdown --version) || die
	[[ ${cli_version} == *"${PV}"* ]] || die "unexpected CLI version: ${cli_version}"
}

pkg_postinst() {
	optfeature "image and media metadata extraction" ">=media-libs/exiftool-12.24"
}

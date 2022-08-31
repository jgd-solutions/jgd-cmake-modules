# Example usage:
#
# find_package(Sphinx)
# find_package(Sphinx REQUIRED)
#
# If successful, the following variables will be defined
# Sphinx_FOUND
# Sphinx_EXECUTABLE
# Sphinx_VERSION
#
# And, the following targets will be defined
# Sphinx::build
#
include(FindPackageHandleStandardArgs)

# use python interpreter path as a base of search
find_package(PythonInterp)
if(PYTHONINTERP_FOUND)
  get_filename_component(_pyinterp_dir "${PYTHON_EXECUTABLE}" DIRECTORY)
  set(_sphinx_hints  "${_pyinterp_dir}" "${_pyinterp_dir}/bin" "${_pyinterp_dir}/Scripts")
  unset(_pyinterp_dir)
endif()

find_program(
  Sphinx_EXECUTABLE
  NAMES sphinx-build sphinx-build2 sphinx-build3
  HINTS "${_sphinx_hints}"
  DOC "Path to Sphinx documentation builder executable"
)
unset(_sphinx_hints)
mark_as_advanced(Sphinx_EXECUTABLE)

find_package_handle_standard_args(Sphinx
  FOUND_VAR Sphinx_FOUND
  REQUIRED_VARS Sphinx_EXECUTABLE
  VERSION_VAR Sphinx_VERSION
)

if (Sphinx_FOUND AND NOT TARGET Sphinx::build)
  add_executable(Sphinx::build IMPORTED)
  set_target_properties(Sphinx::build PROPERTIES IMPORTED_LOCATION "${Sphinx_EXECUTABLE}")
endif()

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/conf.py.in" "conf.py")

set(_sphinx_build_dir "${CMAKE_CURRENT_BINARY_DIR}/sphinx")
message(STATUS "SOURCEDIR: ${CMAKE_CURRENT_SOURCE_DIR} OUTPUTDIR: ${_sphinx_build_dir} FILENAMES: thing.cmake")
add_custom_target(sphinx-docs
  COMMAND Sphinx::build -c "${CMAKE_CURRENT_BINARY_DIR}" "${CMAKE_CURRENT_SOURCE_DIR}" "${_sphinx_build_dir}" "${CMAKE_CURRENT_SOURCE_DIR}/another.rst"
)

cmake_minimum_required(VERSION 3.20)
project(libsingle VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
if (LIBSINGLE_BUILD_DOCS)
  find_package(Doxygen REQUIRED COMPONENTS doxygen)
endif ()

include(JgdAllModules)

jgd_setup_project()
jgd_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR WITH_DOCS_DIR)
jgd_configure_config_header_file()
jgd_install_config_file_package(CONFIGURE_PACKAGE_CONFIG_FILES TARGETS libsingle::libsingle)
jgd_create_clang_format_targets(TARGETS libsingle::libsingle)

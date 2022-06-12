cmake_minimum_required(VERSION 3.20)
project(libsingle VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
if (LIBSINGLE_BUILD_DOCS)
  find_package(Doxygen REQUIRED COMPONENTS doxygen)
endif ()

include(JcmAllModules)

jcm_setup_project()
jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR WITH_DOCS_DIR)
jcm_configure_config_header_file()
jcm_install_config_file_package(CONFIGURE_PACKAGE_CONFIG_FILES TARGETS libsingle::libsingle)
jcm_create_clang_format_targets(TARGETS libsingle::libsingle)

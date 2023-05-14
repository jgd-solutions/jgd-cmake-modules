cmake_minimum_required(VERSION 3.24)
project(libcomponents VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
include(JcmAllModules)

# a very large project may want to omit the expensive configuration of a component
# targets can always be selectively with `--target <target>` option to `cmake --build`
# this is mostly easy to test for
jcm_add_option(
  NAME LIBCOMPONENTS_BUILD_EXTRA
  DESCRIPTION "Allows omitting the expensive configuration of libcomponents::extra target"
  TYPE BOOL
  DEFAULT ON)

if(LIBCOMPONENTS_BUILD_EXTRA)
  set(libcomponents_components core extra)
  set(libcomponents_targets libcomponents::core libcomponents::extra)
else()
  set(libcomponents_components core)
  set(libcomponents_targets libcomponents::core)
endif()

find_package(ClangFormat)

jcm_setup_project()
jcm_source_subdirectories(
  ADD_SUBDIRS
  WITH_TESTS_DIR
  LIB_COMPONENTS ${libcomponents_components})

jcm_create_clang_format_targets(
  EXCLUDE_REGEX "libcomponents_config.hpp$"
  SOURCE_TARGETS ${libcomponents_targets})

jcm_install_config_file_package(
  INSTALL_LICENSES
  CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS ${libcomponents_targets})

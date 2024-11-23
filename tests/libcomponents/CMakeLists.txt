cmake_minimum_required(VERSION 3.24)
project(libcomponents VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
include(JcmAllModules)
jcm_setup_project()

# Although targets can always be selectively built with `--target <target>` option to `cmake
# --build`, a very large project may want to omit the expensive configuration of a component.
jcm_add_component_options(
  REQUIRED_COMPONENTS "core"
  OPTIONAL_COMPONENTS "extra"
  OUT_COMPONENTS libcomponents_components
  OUT_TARGETS libcomponents_targets)

if(PROJECT_IS_TOP_LEVEL)
  find_package(ClangFormat)
endif()

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

# Testing jcm_collect_subdirectory_targets:
jcm_collect_subdirectory_targets(OUT_VAR targets)
set(expected_targets "libcomponents_libcomponents-core")
if(LIBCOMPONENTS_ENABLE_EXTRA)
  list(APPEND expected_targets "libcomponents_libcomponents-extra")
endif()
if(LIBCOMPONENTS_ENABLE_TESTS AND LIBCOMPONENTS_ENABLE_EXTRA)
  list(APPEND expected_targets "components-test")
endif()
if(ClangFormat_FOUND AND PROJECT_IS_TOP_LEVEL)
  list(APPEND expected_targets "clang-format" "clang-format-check")
endif()
list(SORT targets)
list(SORT expected_targets)
if(NOT targets STREQUAL expected_targets)
  message(FATAL_ERROR "jcm_collect_subdirectory_targets failed. \n"
    "Found targets:\n\t'${targets}'.\n\n Expected targets:\n\t'${expected_targets}'")
endif()

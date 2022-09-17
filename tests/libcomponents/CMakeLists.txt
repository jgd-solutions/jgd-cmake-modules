cmake_minimum_required(VERSION 3.20)
project(libcomponents VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
find_package(ClangFormat)
include(JcmAllModules)

jcm_setup_project()
jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR LIB_COMPONENTS core extra)

set(libcomponent_targets libcomponents::core libcomponents::extra)
list(REMOVE_ITEM libcomponent_targets ${LIBCOMPONENTS_OMIT_TARGETS})

jcm_create_clang_format_targets(
  EXCLUDE_REGEX "libcomponents_config.hpp$"
  SOURCE_TARGETS ${libcomponent_targets}
)

jcm_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS ${libcomponent_targets}
)

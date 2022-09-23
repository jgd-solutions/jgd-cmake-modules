cmake_minimum_required(VERSION 3.23)
project(many-exec VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
find_package(ClangFormat)

include(JcmAllModules)
jcm_setup_project()
jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR)

jcm_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS
    many-exec::formatter
    many-exec::compiler
)
jcm_create_clang_format_targets(
  SOURCE_TARGETS
    many-exec::formatter
    many-exec_many-exec-formatter-library
    many-exec::compiler
    many-exec_many-exec-compiler-library
)

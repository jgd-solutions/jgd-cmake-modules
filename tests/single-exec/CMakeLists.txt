cmake_minimum_required(VERSION 3.20)
project(single-exec VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
find_package(ClangFormat)

include(JcmAllModules)
jcm_setup_project()
jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR)

jcm_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS single-exec::single-exec)

jcm_create_clang_format_targets(
  SOURCE_TARGETS
    single-exec::single-exec
    single-exec::single-exec-library)

jcm_create_message_target(
  ALL
  NAME single-exec_message-target
  LEVEL STATUS 
  MESSAGES "Always ensure " "message \\( \n \t \" \\)" "target works")


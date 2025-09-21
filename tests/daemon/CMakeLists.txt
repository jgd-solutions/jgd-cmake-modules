cmake_minimum_required(VERSION 3.28)
project(daemon VERSION 0.0.0 LANGUAGES CXX)

find_package(jgd-cmake-modules CONFIG REQUIRED)
if(PROJECT_IS_TOP_LEVEL)
  find_package(ClangFormat)
endif()

include(JcmAllModules)
jcm_setup_project()
jcm_source_subdirectories(ADD_SUBDIRS)

jcm_install_config_file_package(
  CONFIGURE_PACKAGE_CONFIG_FILES
  TARGETS 
    daemon::daemon
    daemon::libdaemon)

jcm_create_clang_format_targets(
  SOURCE_TARGETS
    daemon::daemon
    daemon::daemon-library
    daemon::libdaemon)


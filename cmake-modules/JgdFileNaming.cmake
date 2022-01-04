include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdCanonicalStructure)

# non-package-config cmake modules
set(JGD_CMAKE_MODULE_REGEX "^([A-Z][a-z]*)+\.cmake")

set(JGD_LIB_PREFIX "lib")

# create regexs of file names based on file extensions from
# JgdCanonicalStructure. Variables of the same name, but with _EXTENSION
# replaced with _REGEX
foreach(ext_var
        JGD_HEADER_EXTENSION;JGD_SOURCE_EXTENSION;JGD_TEST_SOURCE_EXTENSION
        JGD_MODULE_EXTENSION;JGD_IN_FILE_EXTENSION)
  string(REPLACE "_EXTENSION" "_REGEX" regex_var "${ext_var}")
  string(REPLACE "." "\\." ${regex_var} "${${ext_var}}")
  set(${regex_var} "[a-z][a-z_0-9]*${${regex_var}}$")
endforeach()

#
# Private macro to the module. Constructs a consistent kebab-case file name
# based on the PROJECT argument or the PROJECT_NAME variable, the provided
# COMPONENT, and SUFFIX arguments. The resuling file name will be placed in the
# variable specified by OUT_VAR. Result will be
# <PROJECT_NAME>-[COMPONENT-]<suffix>, where suffix is the provided suffix with
# leading dashes removed.
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# SUFFIX: one-value arg; the suffix to append to the generated kebab-case file
# name. Ex. ".cmake"
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
macro(_JGD_KEBAB_FILE_NAME)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;SUFFIX;PROJECT;OUT_VAR"
                      ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "SUFFIX;OUT_VAR")

  set(project "${PROJECT_NAME}")
  if(ARGS_PROJECT)
    set(project "${ARGS_PROJECT}")
  endif()

  # remove leading '-' from suffix, if it was provided
  string(REGEX REPLACE "^-" "" suffix "${ARGS_SUFFIX}")

  # Empty component/no component provided or component is project
  if(NOT ARGS_COMPONENT OR ("${ARGS_COMPONENT}" STREQUAL "${project}"))
    set(${ARGS_OUT_VAR}
        "${project}-${suffix}"
        PARENT_SCOPE)
  else()
    set(${ARGS_OUT_VAR}
        "${project}-${ARGS_COMPONENT}-${suffix}"
        PARENT_SCOPE)
  endif()
endmacro()

#
# Constructs a consistent kebab-case package configuration file name based on
# the PROJECT argument or the PROJECT_NAME variable, and the provided COMPONENT.
# The The resuling file name will be placed in the variable specified by
# OUT_VAR. Result will be <PROJECT_NAME>-[COMPONENT-]config.cmake
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_pkg_config_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;PROJECT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  set(proj_keyword "")
  if(ARGS_PROJECT)
    set(proj_keyword "PROJECT")
  endif()

  _jgd_kebab_file_name(
    COMPONENT
    "${ARGS_COMPONENT}"
    SUFFIX
    "config.cmake"
    ${proj_keyword}
    "${ARGS_PROJECT}"
    OUT_VAR
    "${ARGS_OUT_VAR}")
endfunction()

#
# Constructs a consistent kebab-case input package configuration file name based
# on the PROJECT argument or the PROJECT_NAME variable, and the provided
# COMPONENT. The resuling file name will be placed in the variable specified by
# OUT_VAR. Result will be
# <PROJECT_NAME>-[COMPONENT-]config.cmake.<JGD_IN_FILE_EXTENSION>, ex.
# proj-comp-config.cmake.in
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_pkg_config_in_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;PROJECT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  set(proj_keyword "")
  if(ARGS_PROJECT)
    set(proj_keyword "PROJECT")
  endif()

  jgd_pkg_config_file_name(COMPONENT "${ARGS_COMPONENT}" ${proj_keyword}
                           "${ARGS_PROJECT}" OUT_VAR config_file_name)
  set(${ARGS_OUT_VAR}
      "${config_file_name}${JGD_IN_FILE_EXTENSION}"
      PARENT_SCOPE)
endfunction()

#
# Constructs a consistent kebab-case package version file name based on the
# PROJECT argument or the PROJECT_NAME variable. These files are optionally
# installed alongside the package configuration file to provide version
# information for 'config-file' packages. The resuling file name will be placed
# in the variable specified by OUT_VAR. Result will be
# <PROJECT_NAME>-config-version.cmake
#
# Arguments:
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_pkg_version_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "PROJECT;OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  set(proj_keyword "")
  if(ARGS_PROJECT)
    set(proj_keyword "PROJECT")
  endif()

  _jgd_kebab_file_name(SUFFIX "config-version.cmake" ${proj_keyword}
                       "${ARGS_PROJECT}" OUT_VAR "${ARGS_OUT_VAR}")
endfunction()

#
# Constructs a consistent kebab-case targets file name based on the PROJECT
# argument or the PROJECT_NAME variable, and the provided COMPONENT. Targets
# files are part of 'config-file' pckages. The resuling file name will be placed
# in the variable specified by OUT_VAR. The result will be
# <PROJECT_NAME>-[COMPONENT-]targets.cmake
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_pkg_targets_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;PROJECT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  set(proj_keyword "")
  if(ARGS_PROJECT)
    set(proj_keyword "PROJECT")
  endif()

  _jgd_kebab_file_name(
    COMPONENT
    "${ARGS_COMPONENT}"
    SUFFIX
    "targets.cmake"
    ${proj_keyword}
    "${ARGS_PROJECT}"
    OUT_VAR
    "${ARGS_OUT_VAR}")
endfunction()

#
# Constructs a consistent snake-case config header file name based on the
# PROJECT argument or the PROJECT_NAME variable. The resuling file name will be
# placed in the variable specified by OUT_VAR. Result will be
# <PROJECT_NAME>_config.<JGD_HEADER_EXTENSION>, ex. proj_config.hpp
#
# Arguments:
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_config_header_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "PROJECT;OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")

  set(project "${PROJECT_NAME}")
  if(ARGS_PROJECT)
    set(project "${ARGS_PROJECT}")
  endif()

  set(${ARGS_OUT_VAR}
      "${project}_config${JGD_HEADER_EXTENSION}"
      PARENT_SCOPE)
endfunction()

#
# Constructs a consistent snake-case input config header file name based on the
# PROJECT argument or the PROJECT_NAME variable. The resuling file name will be
# placed in the variable specified by OUT_VAR. Result will be
# <PROJECT_NAME>_config.<JGD_HEADER_EXTENSION>.<JGD_IN_FILE_EXTENSION>, ex.
# proj_config.hpp.in
#
# Arguments:
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_config_header_in_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "PROJECT;OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  set(proj_keyword "")
  if(ARGS_PROJECT)
    set(proj_keyword "PROJECT")
  endif()

  jgd_config_header_file_name(${proj_keyword} "${ARGS_PROJECT}" OUT_VAR
                              header_file_name)

  set(${ARGS_OUT_VAR}
      "${header_file_name}${JGD_IN_FILE_EXTENSION}"
      PARENT_SCOPE)
endfunction()

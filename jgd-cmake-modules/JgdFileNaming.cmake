include_guard()

include(JgdParseArguments)
include(JgdCanonicalStructure)

# non-package-config cmake modules
set(JGD_CMAKE_MODULE_REGEX "^([A-Z][a-z]*)+\.cmake$")

# Create regexs of file names based on file extensions from
# JgdCanonicalStructure. Variables of the same name, but with _EXTENSION
# replaced with _REGEX
foreach (ext_var
  JGD_HEADER_EXTENSION;JGD_SOURCE_EXTENSION;JGD_TEST_SOURCE_EXTENSION
  JGD_MODULE_EXTENSION;JGD_IN_FILE_EXTENSION)
  string(REPLACE "_EXTENSION" "_REGEX" regex_var "${ext_var}")
  string(REPLACE "." "\\." ${regex_var} "${${ext_var}}")
  set(${regex_var} "^[a-z][a-z_0-9]*${${regex_var}}$")
endforeach ()

#
# Private macro to the module. Constructs a consistent file name based on the
# PROJECT argument or the PROJECT_NAME variable, the provided COMPONENT, and
# SUFFIX arguments. The resulting file name will be placed in the variable
# specified by OUT_VAR. Result will be <PROJECT_NAME>-[COMPONENT-]<suffix>,
# where 'suffix' is the provided suffix with any leading dashes removed.
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# A COMPONENT that matches PROJECT_NAME, or PROJECT, if provided, will be
# ignored. Optional.
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
macro(_JGD_JOINED_FILE_NAME)
  jgd_parse_arguments(
    ONE_VALUE_KEYWORDS "COMPONENT;DELIMITER;SUFFIX;PROJECT;OUT_VAR"
    REQUIRES_ALL "SUFFIX;OUT_VAR" ARGUMENTS "${ARGN}")
  # project name
  if (DEFINED ARGS_PROJECT)
    set(project ${ARGS_PROJECT})
  else ()
    set(project ${PROJECT_NAME})
  endif ()

  if (DEFINED ARGS_DELIMITER)
    set(delim ${ARGS_DELIMITER})
  else ()
    set(delim "-")
  endif ()

  # remove leading delimiters from suffix
  string(REGEX REPLACE "^${delim}" "" suffix "${ARGS_SUFFIX}")

  # compose file name
  if (NOT ARGS_COMPONENT OR (ARGS_COMPONENT STREQUAL project))
    set(${ARGS_OUT_VAR} "${project}${delim}${suffix}" PARENT_SCOPE)
  else ()
    set(${ARGS_OUT_VAR}
      "${project}${delim}${ARGS_COMPONENT}${delim}${suffix}"
      PARENT_SCOPE)
  endif ()

  unset(suffix)
  unset(delim)
  unset(project)
endmacro()

macro(_JGD_FILE_NAMING_ARGUMENTS with_component args)
  if (${with_component})
    set(comp_keyword COMPONENT)
  else()
    unset(comp_keyword)
  endif ()

  jgd_parse_arguments(ONE_VALUE_KEYWORDS "${comp_keyword};PROJECT;OUT_VAR"
    REQUIRES_ALL "OUT_VAR" ARGUMENTS "${args}")
  if (DEFINED ARGS_PROJECT)
    set(proj_arg PROJECT ${ARGS_PROJECT})
  else()
    unset(proj_arg)
  endif ()

  if (DEFINED ARGS_COMPONENT)
    set(comp_arg COMPONENT ${ARGS_COMPONENT})
  else()
    unset(comp_arg)
  endif ()
endmacro()

#
# Constructs a consistent kebab-case package configuration file name based on
# the PROJECT argument or the PROJECT_NAME variable, and the provided COMPONENT.
# The resulting file name will be placed in the variable specified by OUT_VAR.
# Result will be <PROJECT_NAME>-[COMPONENT-]config.cmake. Ex 1.
# proj-config.cmake Ex 2. proj-comp-config.cmake.
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# A COMPONENT that matches PROJECT_NAME or PROJECT will be ignored. Optional.
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_package_config_file_name)
  _jgd_file_naming_arguments(true "${ARGN}")
  _jgd_joined_file_name(${comp_arg} SUFFIX "config.cmake" ${proj_arg} OUT_VAR
    "${ARGS_OUT_VAR}")
endfunction()

#
# Constructs a consistent kebab-case package version file name based on the
# PROJECT argument or the PROJECT_NAME variable. These files are optionally
# installed alongside the package configuration file to provide version
# information for 'config-file' packages. The resulting file name will be placed
# in the variable specified by OUT_VAR. Result will be
# <PROJECT_NAME>-config-version.cmake
#
# Arguments:
#
# PROJECT: one-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_package_version_file_name)
  _jgd_file_naming_arguments(false "${ARGN}")
  _jgd_joined_file_name(SUFFIX "config-version.cmake" ${proj_arg} OUT_VAR
    ${ARGS_OUT_VAR})
endfunction()

#
# Constructs a consistent kebab-case targets file name based on the PROJECT
# argument or the PROJECT_NAME variable. Targets
# files are part of 'config-file' packages. The resulting file name will be
# placed in the variable specified by OUT_VAR. The result will be
# <PROJECT_NAME>-targets.cmake. Ex. proj-targets.cmake.
#
# Arguments:
#
# PROJECT: on-value arg; override of PROJECT_NAME. Optional - if not provided,
# PROJECT_NAME will be used, which is more common.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_package_targets_file_name)
  _jgd_file_naming_arguments(true "${ARGN}")
  _jgd_joined_file_name(${comp_arg} SUFFIX "targets.cmake" ${proj_arg} OUT_VAR ${ARGS_OUT_VAR})
endfunction()

#
# Constructs a consistent snake-case config header file name based on the
# PROJECT argument or the PROJECT_NAME variable. The resulting file name will be
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
  _jgd_file_naming_arguments(true "${ARGN}")
  _jgd_joined_file_name(
    ${comp_arg}
    DELIMITER "_"
    SUFFIX "config${JGD_HEADER_EXTENSION}"
    OUT_VAR ${ARGS_OUT_VAR})
endfunction()

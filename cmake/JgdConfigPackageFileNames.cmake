include(JgdParseArguments)
include(JgdValidateArguments)

macro(_JGD_KEBAB_FILE_NAME)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;SUFFIX;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "SUFFIX;OUT_VAR")

  # remove leading '-' from suffix, if it was provided
  string(REGEX REPLACE "^-" "" suffix "${ARGS_SUFFIX}")

  # Empty component/no component provided or component is project
  if(NOT ARGS_COMPONENT OR ("${ARGS_COMPONENT}" STREQUAL "${PROJECT_NAME}"))
    set(${ARGS_OUT_VAR} "${PROJECT_NAME}-${suffix}")
  else()
    set(${ARGS_OUT_VAR} "${PROJECT_NAME}-${ARGS_COMPONENT}-${suffix}")
  endif()
macro()

macro(JGD_CONFIG_FILE_NAME)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  _jgd_kebab_file_name(COMPONENT "${ARGS_COMPONENT}" SUFFIX "config.cmake" OUT_VAR
                       "${ARGS_OUT_VAR}")
endmacro()

macro(JGD_IN_CONFIG_FILE_NAME)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  _jgd_kebab_file_name(COMPONENT "${ARGS_COMPONENT}" SUFFIX "config.cmake.in" OUT_VAR
                       "${ARGS_OUT_VAR}")
endmacro()

macro(jgd_config_version_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  set(${ARGS_OUT_VAR} "${PROJECT_NAME}-config-version.cmake")
endmacro()

macro(JGD_CONFIG_TARGETS_FILE_NAME)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  _jgd_kebab_file_name(COMPONENT "${ARGS_COMPONENT}" SUFFIX "targets.cmake" OUT_VAR
                       "${ARGS_OUT_VAR}")
endmacro()

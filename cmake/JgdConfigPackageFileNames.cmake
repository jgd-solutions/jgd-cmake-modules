include(JgdParseArguments)
include(JgdValidateArguments)

#
# Private macro to the module. Constructs a consistent kebab-case file name
# based on the PROJECT_NAME, the provided COMPONENT, and SUFFIX arguments. The
# resuling file will be placed in the variable specified by OUT_VAR. Result will
# be <PROJECT_NAME>-[COMPONENT-]<suffix>, where suffix is the provided suffix
# with leading dashes removed.
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# SUFFIX: one-value arg; the suffix to append to the generated kebab-case file
# name. Ex. ".cmake"
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
macro(_JGD_KEBAB_FILE_NAME)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;SUFFIX;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "SUFFIX;OUT_VAR")

  # remove leading '-' from suffix, if it was provided
  string(REGEX REPLACE "^-" "" suffix "${ARGS_SUFFIX}")

  # Empty component/no component provided or component is project
  if(NOT ARGS_COMPONENT OR ("${ARGS_COMPONENT}" STREQUAL "${PROJECT_NAME}"))
    set(${ARGS_OUT_VAR}
        "${PROJECT_NAME}-${suffix}"
        PARENT_SCOPE)
  else()
    set(${ARGS_OUT_VAR}
        "${PROJECT_NAME}-${ARGS_COMPONENT}-${suffix}"
        PARENT_SCOPE)
  endif()
endmacro()

#
# Constructs a consistent kebab-case config file name based on the PROJECT_NAME
# and the provided COMPONENT. The resuling file will be placed in the variable
# specified by OUT_VAR. Result will be <PROJECT_NAME>-[COMPONENT-]config.cmake
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_config_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  _jgd_kebab_file_name(COMPONENT "${ARGS_COMPONENT}" SUFFIX "config.cmake"
                       OUT_VAR "${ARGS_OUT_VAR}")
endfunction()

#
# Constructs a consistent kebab-case input config file name based on the
# PROJECT_NAME and the provided COMPONENT. The resuling file will be placed in
# the variable specified by OUT_VAR. Result will be
# <PROJECT_NAME>-[COMPONENT-]config.cmake.in
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_in_config_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  _jgd_kebab_file_name(COMPONENT "${ARGS_COMPONENT}" SUFFIX "config.cmake.in"
                       OUT_VAR "${ARGS_OUT_VAR}")
endfunction()

#
# Constructs a consistent kebab-case config version file name based on the
# PROJECT_NAME and the provided COMPONENT. The resuling file will be placed in
# the variable specified by OUT_VAR. Result will be
# <PROJECT_NAME>-[COMPONENT-]config-version.cmake
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_config_version_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  set(${ARGS_OUT_VAR} "${PROJECT_NAME}-config-version.cmake")
endfunction()

#
# Constructs a consistent kebab-case config version file name based on the
# PROJECT_NAME and the provided COMPONENT. The resuling file will be placed in
# the variable specified by OUT_VAR. Result will be
# <PROJECT_NAME>-[COMPONENT-]targets.cmake
#
# Arguments:
#
# COMPONENT: one-value arg; specifies the component that the file will describe.
# Optional.
#
# OUT_VAR: one-value arg; the name of the output variable which will store the
# resulting file name.
#
function(jgd_config_targets_file_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  _jgd_kebab_file_name(COMPONENT "${ARGS_COMPONENT}" SUFFIX "targets.cmake"
                       OUT_VAR "${ARGS_OUT_VAR}")
endfunction()

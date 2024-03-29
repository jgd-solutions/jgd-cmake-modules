include(JcmParseArguments)

# 1.
# configuration of these components may be expensive, so provide options to avoid configuring them
# targets can always be selectively with `--target <target>` option to `cmake --build`
# these are mostly easy to test against
#
# 2. this could be acheived with jcm_add_component_options; maybe we prefer custom behaviour
#
# 3. with custom behaviour, installation and usage of separate CMake script is tested
jcm_add_option(
  NAME MANY_EXEC_ENABLE_COMPILER
  DESCRIPTION "Allows omitting configuring & building many-exec::compiler target"
  TYPE BOOL
  DEFAULT ON)

jcm_add_option(
  NAME MANY_EXEC_ENABLE_FORMATTER
  DESCRIPTION "Allows omitting configuring & building many-exec::formatter target"
  TYPE BOOL
  DEFAULT ON)


function(many_exec_get_enabled_targets)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_FORMAT_TARGETS" "OUT_BUILD_TARGETS"
    REQUIRES_ANY "OUT_FORMAT_TARGETS" "OUT_BUILD_TARGETS"
    ARGUMENTS "${ARGN}")

  set(many_exec_build_targets)
  set(many_exec_format_targets)

  if(MANY_EXEC_ENABLE_FORMATTER)
    list(APPEND many_exec_build_targets many-exec::formatter)
    list(APPEND many_exec_format_targets many-exec::formatter many-exec::formatter-library)
  endif()

  if(MANY_EXEC_ENABLE_COMPILER)
    list(APPEND many_exec_build_targets many-exec::compiler)
    list(APPEND many_exec_format_targets many-exec::compiler many-exec::compiler-library)
  endif()

  set(${ARGS_OUT_BUILD_TARGETS} ${many_exec_build_targets} PARENT_SCOPE)
  set(${ARGS_OUT_FORMAT_TARGETS} ${many_exec_format_targets} PARENT_SCOPE)
endfunction()

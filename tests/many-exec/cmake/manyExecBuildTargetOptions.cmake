include(JcmParseArguments)

option(
  MANY_EXEC_BUILD_COMPILER
  "Allows omitting configuring & building many-exec::compiler target" ON)

option(
  MANY_EXEC_BUILD_FORMATTER
  "Allows omitting configuring & building many-exec::formatter target" ON)


function(many_exec_get_enabled_targets)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_FORMAT_TARGETS" "OUT_BUILD_TARGETS"
    REQUIRES_ANY "OUT_FORMAT_TARGETS" "OUT_BUILD_TARGETS"
    ARGUMENTS "${ARGN}"
  )

  set(many_exec_build_targets)
  set(many_exec_format_targets)

  if(MANY_EXEC_BUILD_FORMATTER)
    list(APPEND many_exec_build_targets many-exec::formatter)
    list(APPEND many_exec_format_targets many-exec::formatter many-exec_many-exec-formatter-library)
  endif()

  if(MANY_EXEC_BUILD_COMPILER)
    list(APPEND many_exec_build_targets many-exec::compiler)
    list(APPEND many_exec_format_targets many-exec::compiler many-exec_many-exec-compiler-library)
  endif()

  set(${ARGS_OUT_BUILD_TARGETS} ${many_exec_build_targets} PARENT_SCOPE)
  set(${ARGS_OUT_FORMAT_TARGETS} ${many_exec_format_targets} PARENT_SCOPE)
endfunction()

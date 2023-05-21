include_guard()

#[=======================================================================[.rst:

JcmTargetSources
----------------

#]=======================================================================]

include(JcmParseArguments)


# classic absolute, normalized paths
# verifies files are placed correctly
# creates header file sets including the provided headers
function(jcm_target_sources)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "TARGET"
    MULTI_VALUE_KEYWORDS "SOURCES"
    REQUIRES_ALL "TARGET" "SOURCES"
    ARGUMENTS "${ARGN}")

  # transform arguments to normalized absolute paths
  foreach(source_type "" "_LIB")
    set(arg_name ARGS${source_type}_SOURCES)
    if(DEFINED ${arg_name})
      jcm_transform_list(ABSOLUTE_PATH INPUT "${${arg_name}}" OUT_VAR ${arg_name})
      jcm_transform_list(NORMALIZE_PATH INPUT "${${arg_name}}" OUT_VAR ${arg_name})
    endif()
  endforeach()



endfunction()

include_guard()

include(JcmParseArguments)
include(JcmCanonicalStructure)

function(jcm_header_file_set scope)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "TARGET"
    MULTI_VALUE_KEYWORDS "HEADERS"
    REQUIRES_ALL "HEADERS"
    ARGUMENTS "${ARGN}"
  )

  # Usage Guards

  if (NOT TARGET ${ARGS_TARGET})
    message(FATAL_ERROR "${ARGS_TARGET} is not a target and must be created before calling ${CMAKE_CURRENT_FUNCTION}")
  endif ()

  set(supported_scopes "INTERFACE|PUBLIC|PRIVATE")
  if (NOT scope MATCHES "${supported_scopes}")
    message(FATAL_ERROR "One of ${supported_scopes} must be provided as the scope to ${CMAKE_CURRENT_FUNCTION}")
  endif ()

  get_target_property(target_source_dir ${ARGS_TARGET} SOURCE_DIR)
  jcm_canonical_include_dirs(TARGET ${ARGS_TARGET} OUT_VAR include_dirs)

  foreach (header_path ${ARGS_HEADERS})
    if (NOT IS_ABSOLUTE "${header_path}")
      set(header_path "${target_source_dir}/${header_path}")
    endif ()

    set(shortest_relative_length 65000)
    set(base_dir)
    foreach (include_dir ${include_dirs})
      if (NOT header_path MATCHES "^${include_dir}")
        continue()
      endif ()

      string(REPLACE "${include_dir}" "" relative_path "${header_path}")
      string(LENGTH "${relative_path}" relative_length)

      if (relative_length LESS shortest_relative_length)
        set(shortest_relative_length ${relative_length})
        set(base_dir "${include_dir}")
      elseif (relative_length EQUAL shortest_relative_length)
        message(AUTHOR_WARNING "Multiple canonical include directories refer to the same path: "
          "${include_dir} & ${base_dir}")
      endif ()
    endforeach ()

    if (NOT base_dir)
      message(FATAL_ERROR "Could not resolve the canonical include directory for ${header_path}")
    endif ()

    string(MD5 base_dir_hash "${base_dir}")
    string(REPLACE "-" "_" file_set_name "${ARGS_TARGET}_${scope}_${base_dir_hash}")

    target_sources(${ARGS_TARGET} ${scope} FILE_SET "${file_set_name}"
      TYPE HEADERS BASE_DIRS "${base_dir}" FILES "${header_path}")
  endforeach ()
endfunction()

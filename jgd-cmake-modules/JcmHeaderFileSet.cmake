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

  # Transform headers to normalized absolute paths
  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_HEADERS}" OUT_VAR ARGS_HEADERS)
  jcm_transform_list(NORMALIZE_PATH INPUT "${ARGS_HEADERS}" OUT_VAR ARGS_HEADERS)

  # Resolve the canonical include directory to which each header belongs
  jcm_canonical_include_dirs(
    WITH_BINARY_INCLUDE_DIRS
    TARGET ${ARGS_TARGET}
    OUT_VAR available_include_dirs
  )

  foreach (header_path ${ARGS_HEADERS})
    set(shortest_distance_from_include_dir 65000)
    unset(chosen_include_dir)
    foreach (include_dir ${available_include_dirs})
      if (NOT header_path MATCHES "^${include_dir}")
        continue()
      endif ()

      string(REPLACE "${include_dir}" "" relative_to_include "${header_path}")
      string(LENGTH "${relative_to_include}" distance_from_include)

      if (distance_from_include LESS shortest_distance_from_include_dir)
        set(shortest_distance_from_include_dir ${distance_from_include})
        set(chosen_include_dir "${include_dir}")
      elseif (distance_from_include EQUAL shortest_distance_from_include_dir)
        message(AUTHOR_WARNING
          "Multiple canonical include directories refer to the same path: "
          "${include_dir} & ${chosen_include_dir}")
      endif ()
    endforeach ()

    if (NOT DEFINED chosen_include_dir)
      message(FATAL_ERROR "Could not resolve the canonical include directory for ${header_path}")
    endif ()

    # add the header to the header file set for its belonging include directory
    string(MD5 include_dir_hash "${chosen_include_dir}")
    string(REPLACE "-" "_" file_set_name "${ARGS_TARGET}_${scope}_${include_dir_hash}")

    target_sources(${ARGS_TARGET}
      ${scope}
      FILE_SET "${file_set_name}"
      TYPE HEADERS
      BASE_DIRS "${chosen_include_dir}"
      FILES "${header_path}"
    )
  endforeach ()
endfunction()

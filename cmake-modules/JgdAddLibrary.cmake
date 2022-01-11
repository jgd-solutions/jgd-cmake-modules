include_guard()

include(GenerateExportHeader)

# check to make sure we're under a source directory, check all file names,
# create build_shared option for component, if it's a component, set output
# name, set prefix

function(jgd_add_default_library)
  # generate_export_header(${library} PREFIX_NAME ${JGD_PROJECT_PREFIX_NAME}
  # EXPORT_FILE_NAME .)

  if(PROJECT_VERSION)
    set_target_properties(
      ${library} PROPERTIES VERSION ${PROJECT_VERSION} SOVERSION
                                                       ${PROJECT_VERSION_MAJOR})
  endif()

endfunction()

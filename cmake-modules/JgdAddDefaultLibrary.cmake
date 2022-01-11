include_guard()

include(GenerateExportHeader)

# check to make sure we're under a source directory, check all file names,
# create build_shared option for component, if it's a component, set output
# name, set prefix

function(jgd_add_default_library)

  generate_export_header(${library} [PREFIX_NAME ${}_
                         [CUSTOM_CONTENT_FROM_VARIABLE <variable>])

endfunction()

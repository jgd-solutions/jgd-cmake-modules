include_guard()

include(JgdCheckSet)
include(CheckIPOSupported)

function(jgd_setup_project)

  # PROJECT_IS_TOP_LEVEL

  # Variables Setting Default Target Properties

  # basic generation
  jgd_check_set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
  jgd_check_set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  jgd_check_set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  jgd_check_set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

  # hidden export visibility for shared & module libraries
  jgd_check_set(CMAKE_VISIBILITY_INLINES_HIDDEN TRUE)
  get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
  foreach(lang ${languages})
    jgd_check_set(CMAKE_${lang}_VISIBILITY_PRESET hidden)
  endforeach()

  # shared libraries' transitive runtime load path as current location
  if(NOT APPLE>)
    jgd_check_set(CMAKE_INSTALL_RPATH $ORIGIN)
  endif()

  # interprocedural/link-time optimization
  check_ipo_supported(RESULT ipo_supported OUTPUT err_msg)
  if(ipo_supported)
    jgd_check_set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
  else()
    message(NOTICE
            "Interprocedural linker optimization is not supported: ${err_msg}\n"
            "Continuing without it.")
    jgd_check_set(CMAKE_INTERPROCEDURAL_OPTIMIZATION FALSE CHECK "")
  endif()

endfunction()

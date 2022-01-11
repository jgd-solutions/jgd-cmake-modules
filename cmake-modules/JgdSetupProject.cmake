include_guard()

include(JgdCheckSet)
include(JgdParseArguments)
include(CheckIPOSupported)
include(GNUInstallDirs)

function(jgd_setup_project)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "PREFIX_NAME" REQUIRES_ALL
                      "PREFIX_NAME" ARGUMENTS "${ARGN}")

  set(prefix_temp)
  string(TOUPPER ${PROJECT_NAME} prefix_temp)
  string(REPLACE "-" "_" ${prefix_temp} JGD_PROJECT_PREFIX)

  # == Usage Guards ==

  # guard against running as script or forgetting project() command
  if(NOT PROJECT_NAME)
    message(
      FATAL_ERROR
        "A project must be defined to setup a default project. Call CMake's"
        "project() command prior to using jgd_setup_project.")
  endif()

  # guard against in-source builds
  if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    message(
      FATAL_ERROR
        "In-source builds not allowed. Please make and use a build directory.")
  endif()

  # == Variables Setting Default Target Properties ==

  # basic
  jgd_check_set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  jgd_check_set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  jgd_check_set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
  jgd_check_set(CMAKE_EXPORT_COMPILE_COMMANDS TRUE)
  jgd_check_set(CMAKE_OPTIMIZE_DEPENDENCIES TRUE)

  # hidden export visibility for shared & module libraries
  jgd_check_set(CMAKE_VISIBILITY_INLINES_HIDDEN TRUE)
  get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
  foreach(lang ${languages})
    jgd_check_set(CMAKE_${lang}_VISIBILITY_PRESET hidden)
  endforeach()

  # default transitive runtime search path (RPATH) for shared libraries
  if(NOT CMAKE_SYSTEM_NAME MATCHES "Apple|Windows")
    file(RELATIVE_PATH rel_path
         ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}
         ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
    set(CMAKE_INSTALL_RPATH $ORIGIN $ORIGIN/${rel_path})
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

  # == Variables Controlling CMake ==

  # keep object file paths within Windows' path length limit
  if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    set(CMAKE_OBJECT_PATH_MAX 260)
    message(
      STATUS
        "Windows: setting CMAKE_OBJECT_PATH_MAX to ${CMAKE_OBJECT_PATH_MAX}")
  endif()

  # default install prefix to Filesystem Hierarchy Standard's "add-on" path
  if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT
     AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows"
     AND PROJECT_IS_TOP_LEVEL)
    # todo: follow opt/ with provider, once registered with LANANA
    set(CMAKE_INSTALL_PREFIX
        "/opt/${PROJECT_NAME}"
        CACHE PATH "Base installation location." FORCE)
  endif()

endfunction()

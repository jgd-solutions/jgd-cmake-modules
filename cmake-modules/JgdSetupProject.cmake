include_guard()

include(JgdParseArguments)
include(CheckIPOSupported)
include(GNUInstallDirs)

macro(_jgd_warn_set variable value)
  # can only enforce the guard if we're sure that it was set by this CMake
  # project. If this project was absorbed into the build of another project, by
  # add_subdirectory(), the parent project may have set their own values. We
  # will still override these values, but this warning is for improper usage.
  if(PROJECT_IS_TOP_LEVEL AND DEFINED ${variable})
    message(
      WARNING
        "The variable ${variable} was set for project ${PROJECT_NAME} prior to "
        "calling jgd_setup_project. This variable will by overridden to the "
        "default value of ${value} in the project setup. If you wish to "
        "override the default value, set ${variable} after calling "
        "jgd_setup_project.")
  endif()
  set(${variable}
      ${value}
      PARENT_SCOPE)
endmacro()

macro(jgd_check_set variable value)
  if(NOT DEFINED ${variable})
    set(${variable}
        "${value}"
        PARENT_SCOPE)
  endif()
endmacro()

function(jgd_setup_project)
  jgd_parse_arguments(ARGUMENTS "${ARGN}")

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

  # ensure this function is called in the list file that defined the project
  if(NOT CMAKE_CURRENT_LIST_FILE STREQUAL
     "${PROJECT_SOURCE_DIR}/CMakeLists.txt")
    message(
      FATAL_ERROR
        "jgd_setup_project must be called in the same CMakeLists.txt file that "
        "the project was defined in, using CMake's project() command.")
  endif()

  # guard against in-source builds
  if(PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    message(
      FATAL_ERROR
        "In-source builds not allowed. Please make and use a build directory.")
  endif()

  # == Variables Setting Default Target Properties ==

  # basic
  _jgd_warn_set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
  _jgd_warn_set(CMAKE_OPTIMIZE_DEPENDENCIES ON)

  # build artifact destinations
  set(archive_out_dir "${CMAKE_BINARY_DIR}/lib")
  set(lib_out_dir "${CMAKE_BINARY_DIR}/lib")
  set(runtime_out_dir "${CMAKE_BINARY_DIR}/bin")
  if(PROJECT_IS_TOP_LEVEL)
    _jgd_warn_set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${archive_out_dir}")
    _jgd_warn_set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${lib_out_dir}")
    _jgd_warn_set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${runtime_out_dir}")
  else()
    # welcome parent project's values, if defined
    jgd_check_set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${archive_out_dir}")
    jgd_check_set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${lib_out_dir}")
    jgd_check_set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${runtime_out_dir}")
  endif()

  # language standard requirements
  get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
  foreach(lang ${languages})
    if(lang MATCHES "CXX")
      _jgd_warn_set(CMAKE_CXX_STANDARD 20)
    elseif(lang STREQUAL "C")
      _jgd_warn_set(CMAKE_C_STANDARD 17)
    elseif(lang STREQUAL "CUDA")
      _jgd_warn_set(CMAKE_CUDA_STANDARD 20)
    elseif(lang STREQUAL "OBJC")
      _jgd_warn_set(CMAKE_OBJC_STANDARD 11)
    elseif(lang STREQUAL "OBJCXX")
      _jgd_warn_set(CMAKE_OBJCXX_STANDARD 20)
    elseif(lang STREQUAL "HIP")
      _jgd_warn_set(CMAKE_HIP_STANDARD 20)
    endif()
    _jgd_warn_set(CMAKE_${lang}_STANDARD_REQUIRED ON)
    _jgd_warn_set(CMAKE_${lang}_EXTENSIONS OFF)
  endforeach()

  # export visibility for shared & module libraries
  _jgd_warn_set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
  foreach(lang ${languages})
    _jgd_warn_set(CMAKE_${lang}_VISIBILITY_PRESET hidden)
  endforeach()

  # default transitive runtime search path (RPATH) for shared libraries
  if(NOT CMAKE_SYSTEM_NAME MATCHES "Apple|Windows")
    file(RELATIVE_PATH rel_path
         ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}
         ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR})
    _jgd_warn_set(CMAKE_INSTALL_RPATH $ORIGIN $ORIGIN/"${rel_path}")
  endif()

  # interprocedural/link-time optimization
  check_ipo_supported(RESULT ipo_supported OUTPUT err_msg)
  if(ipo_supported)
    _jgd_warn_set(CMAKE_INTERPROCEDURAL_OPTIMIZATION ON)
  else()
    _jgd_warn_set(CMAKE_INTERPROCEDURAL_OPTIMIZATION OFF)
    message(NOTICE
            "Interprocedural linker optimization is not supported: ${err_msg}\n"
            "Continuing without it.")
  endif()

  # == Variables Controlling CMake ==

  # keep object file paths within Windows' path length limit
  if(CMAKE_SYSTEM_NAME STREQUAL "Windows")
    _jgd_warn_set(CMAKE_OBJECT_PATH_MAX 260)
    message(
      STATUS
        "Windows: setting CMAKE_OBJECT_PATH_MAX to ${CMAKE_OBJECT_PATH_MAX}")
  endif()

  # default install prefix to Filesystem Hierarchy Standard's "add-on" path
  if(CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT
     AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows"
     AND PROJECT_IS_TOP_LEVEL)
    # todo: follow opt/ with provider, once registered with LANANA
    _jgd_warn_set(CMAKE_INSTALL_PREFIX "/opt/${PROJECT_NAME}" CACHE PATH
                  "Base installation location." FORCE)
  endif()
endfunction()

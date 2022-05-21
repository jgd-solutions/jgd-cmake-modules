include_guard()

include(JgdParseArguments)
include(JgdFileNaming)
include(JgdStandardDirs)
include(CheckIPOSupported)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

define_property(
  TARGET
  PROPERTY COMPONENT
  BRIEF_DOCS "Component name."
  FULL_DOCS
  "The name of a library or executable component that the target represents.")

macro(_JGD_WARN_SET variable value)
  # Values that will be overridden by the project setup and should therefore not
  # be set prior to calling setup, unless it was explicity in the cache, which
  # occurs when variables are specified on the command line. This guard can only
  # be enforced if we're sure that it was set by this CMake project. If this
  # project was absorbed into the build of another project, by
  # add_subdirectory(), the parent project may have set their own values. We
  # will still override these values, nevertheless.
  if (PROJECT_IS_TOP_LEVEL
    AND DEFINED ${variable}
    AND NOT DEFINED CACHE{${variable}})
    message(
      AUTHOR_WARNING
      "The variable ${variable} was set for project ${PROJECT_NAME} prior to "
      "calling jgd_setup_project. This variable will by overridden to the "
      "default value of ${value} in the project setup. If you wish to "
      "override the default value, set ${variable} after calling "
      "jgd_setup_project.")
  endif ()
  set(${variable} "${value}" ${ARGN})
endmacro()

macro(_JGD_CHECK_SET variable value)
  if (NOT DEFINED ${variable})
    set(${variable} "${value}" ${ARGN})
  endif ()
endmacro()

# JGD_PROJECT_PREFIX_NAME, guards against basic project issues sets a bunch of
# CMAKE_ variables to set default target properties & configure cmake operation
# enables testing so it's never forgotten, even if there's no tests, it can
# still be run
macro(JGD_SETUP_PROJECT)
  # == Usage Guards ==

  # guard against running as script or forgetting project() command
  if (NOT PROJECT_NAME)
    message(
      FATAL_ERROR
      "A project must be defined to setup a default project. Call CMake's"
      "project() command prior to using ${CMAKE_CURRENT_FUNCTION}.")
  endif ()

  # ensure this function is called in the list file that defined the project
  if (NOT CMAKE_CURRENT_LIST_FILE STREQUAL
    "${PROJECT_SOURCE_DIR}/CMakeLists.txt")
    message(
      FATAL_ERROR
      "jgd_setup_project must be called in the same CMakeLists.txt file that "
      "the project was defined in, with CMake's project() command.")
  endif ()

  # guard against in-source builds
  if (PROJECT_SOURCE_DIR STREQUAL PROJECT_BINARY_DIR)
    message(
      FATAL_ERROR
      "In-source builds not allowed. Please make and use a build directory.")
  endif ()

  # malformed project name
  set(project_name_regex "^[a-z][a-z-]*[a-z]$")
  string(REGEX MATCH "${project_name_regex}" name_correct "${PROJECT_NAME}")
  if (NOT name_correct)
    message(
      FATAL_ERROR
      "The project ${PROJECT_NAME} does not meet the required regex "
      "${project_name_regex}. This should be the same name as the project's "
      "root directory, and is required because it influences things like "
      "target names and artifact output names.")
  endif ()
  unset(name_correct)
  unset(project_name_regex)

  # no project version specified
  if (NOT DEFINED PROJECT_VERSION)
    message(
      AUTHOR_WARNING
      "The project ${PROJECT_NAME} does not have a version defined. It's "
      "recommended to provide the VERSION argument to CMake's project() "
      "command, as it affects package installation and shared library "
      "versioning")
  endif ()

  # == Function Arguments Project Configuration  ==

  jgd_parse_arguments(ONE_VALUE_KEYWORDS "PREFIX_NAME" ARGUMENTS "${ARGN}")

  # project prefix name
  if (DEFINED ARGS_PREFIX_NAME)
    set(JGD_PROJECT_PREFIX_NAME ${ARGS_PREFIX_NAME})
  else ()
    string(TOUPPER ${PROJECT_NAME} prefix_temp)
    string(REPLACE "-" "_" JGD_PROJECT_PREFIX_NAME ${prefix_temp})
    unset(prefix_temp)
  endif ()

  # == Invariable Project Options ==

  option(${JGD_PROJECT_PREFIX_NAME}_BUILD_TESTS "Build all automated tests for ${PROJECT_NAME}" OFF)
  option(${JGD_PROJECT_PREFIX_NAME}_BUILD_DOCS "Build all documentation for ${PROJECT_NAME}" OFF)
  # note: build shared options provided by jgd_add_library, if called

  # == Variables Setting Default Target Properties ==

  # basic
  _jgd_warn_set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
  _jgd_warn_set(CMAKE_OPTIMIZE_DEPENDENCIES ON)

  # add project's cmake modules to path
  list(FIND CMAKE_MODULE_PATH "${JGD_PROJECT_CMAKE_DIR}" cmake_dir_idx)
  if (cmake_dir_idx EQUAL -1 AND EXISTS "${JGD_PROJECT_CMAKE_DIR}")
    list(APPEND CMAKE_MODULE_PATH "${JGD_PROJECT_CMAKE_DIR}")
  endif ()
  unset(cmake_dir_idx)

  # build artifact destinations
  if (PROJECT_IS_TOP_LEVEL)
    _jgd_warn_set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
    _jgd_warn_set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
    _jgd_warn_set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
  else ()
    # welcome parent project's values, if defined
    _jgd_check_set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
    _jgd_check_set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
    _jgd_check_set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
  endif ()

  # language standard requirements
  get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
  foreach (lang ${languages})
    if (lang MATCHES "CXX")
      _jgd_warn_set(CMAKE_CXX_STANDARD 20)
    elseif (lang STREQUAL "C")
      _jgd_warn_set(CMAKE_C_STANDARD 17)
    elseif (lang STREQUAL "CUDA")
      _jgd_warn_set(CMAKE_CUDA_STANDARD 20)
    elseif (lang STREQUAL "OBJC")
      _jgd_warn_set(CMAKE_OBJC_STANDARD 11)
    elseif (lang STREQUAL "OBJCXX")
      _jgd_warn_set(CMAKE_OBJCXX_STANDARD 20)
    elseif (lang STREQUAL "HIP")
      _jgd_warn_set(CMAKE_HIP_STANDARD 20)
    endif ()
    _jgd_warn_set(CMAKE_${lang}_STANDARD_REQUIRED ON)
    _jgd_warn_set(CMAKE_${lang}_EXTENSIONS OFF)
  endforeach ()

  # export visibility for shared & module libraries
  _jgd_warn_set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
  foreach (lang ${languages})
    _jgd_warn_set(CMAKE_${lang}_VISIBILITY_PRESET hidden)
  endforeach ()

  # default transitive runtime search path (RPATH) for shared libraries
  if ((NOT languages STREQUAL "NONE") AND (NOT CMAKE_SYSTEM_NAME STREQUAL "Windows"))
    if (CMAKE_SYSTEM_NAME STREQUAL "Apple")
      set(rpath_base @loader_path)
    else ()
      set(rpath_base $ORIGIN)
    endif ()
    file(RELATIVE_PATH rel_path
      "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_BINDIR}"
      "${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_INSTALL_LIBDIR}")

    _jgd_warn_set(CMAKE_INSTALL_RPATH ${rpath_base} ${rpath_base}/${rel_path})

    unset(rel_path)
    unset(rpath_base)
  endif ()

  # interprocedural/link-time optimization

  if ((NOT languages STREQUAL "NONE") AND (CMAKE_BUILD_TYPE MATCHES
    "Release|RelWithDepInfo"))
    check_ipo_supported(RESULT ipo_supported OUTPUT err_msg)
    if (ipo_supported)
      _jgd_warn_set(CMAKE_INTERPROCEDURAL_OPTIMIZATION $<IF:$<CONFIG:DEBUG>,OFF,ON>)
    else ()
      _jgd_warn_set(CMAKE_INTERPROCEDURAL_OPTIMIZATION OFF)
      message(
        NOTICE
        "Interprocedural linker optimization is not supported: ${err_msg}\n"
        "Continuing without it.")
    endif ()
    unset(ipo_supported)
    unset(err_msg)
  endif ()

  unset(languages)

  # == Variables Controlling CMake ==

  # keep object file paths within Windows' path length limit
  if (CMAKE_SYSTEM_NAME STREQUAL "Windows")
    _jgd_warn_set(CMAKE_OBJECT_PATH_MAX 260)
    message(STATUS "Windows: setting CMAKE_OBJECT_PATH_MAX to ${CMAKE_OBJECT_PATH_MAX}")
  endif ()

  # default install prefix to Filesystem Hierarchy Standard's "add-on" path
  if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT
    AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows"
    AND PROJECT_IS_TOP_LEVEL)
    # todo: follow opt/ with provider, once registered with LANANA
    _jgd_warn_set(CMAKE_INSTALL_PREFIX "/opt/${PROJECT_NAME}" CACHE PATH "Base installation location. " FORCE)
  endif ()

  # enable testing by default so invoking ctest always succeeds
  enable_testing()
endmacro()

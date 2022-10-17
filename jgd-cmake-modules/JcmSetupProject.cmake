include_guard()

#[=======================================================================[.rst:

JcmSetupProject
----------------

Offers utilities to properly setup a CMake project for consumption as both a sub-project and a
binary package. Creates target component, *COMPONENT*, and defines macro
:cmake:command:`jcm_setup_project` used to setup a CMake project.

--------------------------------------------------------------------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmFileNaming)
include(JcmStandardDirs)
include(CheckIPOSupported)
include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

define_property(
  TARGET
  PROPERTY COMPONENT
  BRIEF_DOCS "Component name."
  FULL_DOCS
  "The name of a library or executable component that the target represents.")

macro(_JCM_WARN_SET variable value)
  if (PROJECT_IS_TOP_LEVEL)
    if (DEFINED ${variable} AND NOT DEFINED CACHE{${variable}})
      message(
        AUTHOR_WARNING
        "The variable ${variable} was set for project ${PROJECT_NAME} prior to calling "
        "jcm_setup_project. This variable will by overridden to the default value of ${value} in "
		    "the project setup. If you wish to override the default value, set ${variable} after "
		    "calling jcm_setup_project or in the CMake cache, such as through the command-line.")
    endif ()

    set(${variable} "${value}" ${ARGN})
  endif()
endmacro()

macro(_JCM_CHECK_SET variable value)
  if (NOT DEFINED ${variable})
    set(${variable} "${value}" ${ARGN})
  endif ()
endmacro()

#[=======================================================================[.rst:

jcm_setup_project
^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_setup_project

  .. code-block:: cmake

    jcm_setup_project([PREFIX_NAME] <project-prefix>)

Sets up a CMake project in the top-level `CMakeLists.txt`.

This function will:
  - guard against misuse and malpractice, such as :cmake:variable:`PROJECT_NAME` being defined, the
    call-site is in the top-level CMakeLists.txt, preventing in-source builds, and ensuring project
    naming conventions.
  - set variable :cmake:variable:`JCM_PROJECT_PREFIX_NAME` to the upper-case project name, or
    :cmake:variable:`PREFIX_NAME`, if provided. This variable is used as the prefix name to subsequent
    macros, options, and variables.
  - create options:

      ${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS
        Enables/disables building project tests for this specific project. Default:
        :cmake:variable:`BUILD_TESTING`

      ${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS
        Enables/disables building project documentation for this specific project. Default:
        *OFF*

  - set default values for CMake variables controlling the build when the current project is the
    top-level project

    - :cmake:variable:`CMAKE_BUILD_TYPE`
    - :cmake:variable:`CMAKE_EXPORT_COMPILE_COMMANDS`
    - :cmake:variable:`CMAKE_LINK_WHAT_YOU_USE`
    - :cmake:variable:`CMAKE_COLOR_DIAGNOSTICS`
    - :cmake:variable:`CMAKE_INSTALL_PREFIX`
    - :cmake:variable:`CMAKE_DEBUG_POSTFIX`
    - :cmake:variable:`CMAKE_OBJECT_PATH_MAX` (Windows)

  - set values for variables CMake uses to initialize target properties, only when the current
    project is top-level

    - :cmake:variable:`CMAKE_INSTALL_RPATH` (runtime search path (RPATH) for shared object libraries)
    - :cmake:variable:`CMAKE_ARCHIVE_OUTPUT_DIRECTORY`
    - :cmake:variable:`CMAKE_LIBRARY_OUTPUT_DIRECTORY`
    - :cmake:variable:`CMAKE_RUNTIME_OUTPUT_DIRECTORY`
    - :cmake:variable:`CMAKE_<LANG>_STANDARD`
    - :cmake:variable:`CMAKE_<LANG>_STANDARD_REQUIRED`
    - :cmake:variable:`CMAKE_<LANG>_EXTENSIONS`
    - :cmake:variable:`CMAKE_<LANG>_VISIBILITY_PRESET`
    - :cmake:variable:`CMAKE_VISIBILITY_INLINES_HIDDEN`

  - enable interprocedural optimization in *Release* mode
  - always enable testing so testing never fails, even if there are no tests, and includes CTest
    when *${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS* is set.


Parameters
##########

One Value
~~~~~~~~~~

:cmake:variable:`PREFIX_NAME`
  Sets variable :cmake:variable:`JCM_PROJECT_PREFIX_NAME`, which is used as the prefix for
  variables, macros, options, etc. specific to this project.

Examples
########

.. code-block:: cmake

  jcm_setup_project()


.. code-block:: cmake

  jcm_setup_project(PREFIX_NAME STX)

#]=======================================================================]

macro(JCM_SETUP_PROJECT)
  # == Usage Guards ==

  # guard against running as script or forgetting project() command
  if (NOT PROJECT_NAME)
    message(
      FATAL_ERROR
      "A project must be defined to setup a default project. Call CMake's"
      "project() command prior to using ${CMAKE_CURRENT_FUNCTION}.")
  endif ()

  # ensure this function is called in the list file that defined the project
  if (NOT CMAKE_CURRENT_LIST_FILE STREQUAL "${PROJECT_SOURCE_DIR}/CMakeLists.txt")
    message(
      FATAL_ERROR
      "jcm_setup_project must be called in the same CMakeLists.txt file that "
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
      "'${project_name_regex}'. This should be the same name as the project's "
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

  jcm_parse_arguments(ONE_VALUE_KEYWORDS "PREFIX_NAME" ARGUMENTS "${ARGN}")

  # project prefix name
  if (DEFINED ARGS_PREFIX_NAME)
    set(JCM_PROJECT_PREFIX_NAME ${ARGS_PREFIX_NAME})
  else ()
    string(TOUPPER ${PROJECT_NAME} prefix_temp)
    string(REPLACE "-" "_" JCM_PROJECT_PREFIX_NAME ${prefix_temp})
    unset(prefix_temp)
  endif ()

  # == Invariable Project Options ==

  if(BUILD_TESTING AND PROJECT_IS_TOP_LEVEL)
    set(default_enable_tests ON)
  else()
    set(default_enable_tests OFF)
  endif()

  option(${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS "Build all automated tests for ${PROJECT_NAME}" ${default_enable_tests})
  unset(default_enable_tests)

  option(${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS "Build all documentation for ${PROJECT_NAME}" OFF)

  # == Variables Setting Default Target Properties ==

  # basic
  _jcm_check_set(CMAKE_BUILD_TYPE "Release")
  _jcm_warn_set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
  _jcm_warn_set(CMAKE_OPTIMIZE_DEPENDENCIES ON)
  _jcm_warn_set(CMAKE_LINK_WHAT_YOU_USE ON)
  _jcm_warn_set(CMAKE_COLOR_DIAGNOSTICS ON)
  _jcm_warn_set(CMAKE_DEBUG_POSTFIX "-debug")

  # add project's cmake modules to path
  list(FIND CMAKE_MODULE_PATH "${JCM_PROJECT_CMAKE_DIR}" cmake_dir_idx)
  if (cmake_dir_idx EQUAL -1 AND EXISTS "${JCM_PROJECT_CMAKE_DIR}")
    list(APPEND CMAKE_MODULE_PATH "${JCM_PROJECT_CMAKE_DIR}")
  endif ()
  unset(cmake_dir_idx)

  # build artifact destinations
  _jcm_warn_set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  _jcm_warn_set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  _jcm_warn_set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")

  # language standard requirements
  get_property(languages GLOBAL PROPERTY ENABLED_LANGUAGES)
  foreach (lang ${languages})
    if (lang STREQUAL "CXX")
      _jcm_warn_set(CMAKE_CXX_STANDARD 20)
    elseif (lang STREQUAL "C")
      _jcm_warn_set(CMAKE_C_STANDARD 17)
    elseif (lang STREQUAL "CUDA")
      _jcm_warn_set(CMAKE_CUDA_STANDARD 20)
    elseif (lang STREQUAL "OBJC")
      _jcm_warn_set(CMAKE_OBJC_STANDARD 11)
    elseif (lang STREQUAL "OBJCXX")
      _jcm_warn_set(CMAKE_OBJCXX_STANDARD 20)
    elseif (lang STREQUAL "HIP")
      _jcm_warn_set(CMAKE_HIP_STANDARD 20)
    endif ()
    _jcm_warn_set(CMAKE_${lang}_STANDARD_REQUIRED ON)
    _jcm_warn_set(CMAKE_${lang}_EXTENSIONS OFF)
  endforeach ()

  # export visibility for shared & module libraries
  _jcm_warn_set(CMAKE_VISIBILITY_INLINES_HIDDEN ON)
  foreach (lang ${languages})
    _jcm_warn_set(CMAKE_${lang}_VISIBILITY_PRESET hidden)
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

    _jcm_warn_set(CMAKE_INSTALL_RPATH ${rpath_base} ${rpath_base}/${rel_path})

    unset(rel_path)
    unset(rpath_base)
  endif ()

  # CMake default sets CMAKE_MACOSX_RPATH, so only warn about setting if it's been set to OFF
  if (NOT CMAKE_MACOSX_RPATH)
    _jcm_warn_set(CMAKE_MACOSX_RPATH ON)
  endif()

  # interprocedural/link-time optimization

  if ((NOT languages STREQUAL "NONE") AND (CMAKE_BUILD_TYPE MATCHES "Release|RelWithDepInfo"))
    check_ipo_supported(RESULT ipo_supported OUTPUT err_msg)
    if (ipo_supported)
      _jcm_warn_set(CMAKE_INTERPROCEDURAL_OPTIMIZATION $<IF:$<CONFIG:DEBUG>,OFF,ON>)
    else ()
      _jcm_warn_set(CMAKE_INTERPROCEDURAL_OPTIMIZATION OFF)
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
    _jcm_warn_set(CMAKE_OBJECT_PATH_MAX 260)
    message(STATUS "Windows: setting CMAKE_OBJECT_PATH_MAX to ${CMAKE_OBJECT_PATH_MAX}")
  endif ()

  # default install prefix to Filesystem Hierarchy Standard's "add-on" path
  if (CMAKE_INSTALL_PREFIX_INITIALIZED_TO_DEFAULT AND NOT CMAKE_SYSTEM_NAME STREQUAL "Windows")
    # can follow opt/ with provider, once registered with LANANA
    _jcm_warn_set(
      CMAKE_INSTALL_PREFIX "/opt/${PROJECT_NAME}" CACHE PATH "Base installation location. " FORCE)
  endif ()

  # enable testing by default so invoking ctest always succeeds
  enable_testing()

  # include CMake's CTest when testing
  if(${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS)
    if(DEFINED BUILD_TESTING)
      set(original_build_testing_value ${BUILD_TESTING})
    else()
      unset(original_build_testing_value)
    endif()

    # CTest needs BUILD_TESTING
    set(BUILD_TESTING ON)
    include(CTest)
    set(BUILD_TESTING ${original_build_testing_value})

  endif()
endmacro()

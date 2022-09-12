include_guard()

#[=======================================================================[.rst:

JcmAddExecutable
----------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmFileNaming)
include(JcmTargetNaming)
include(JcmListTransformations)
include(JcmCanonicalStructure)
include(JcmDefaultCompileOptions)


#[=======================================================================[.rst:

.. cmake:command:: jcm_add_executable

  .. code-block:: cmake

    jcm_add_executable(
      [WITHOUT_CANONICAL_PROJECT_CHECK]
      [COMPONENT <component>]
      [NAME <name>]
      [OUT_TARGET_NAME <out-var>]
      [LIB_SOURCES <source>...]
      SOURCES <source>...
    )

Adds an executable target to the project, similar to CMake's `add_executable`, but with enhancements
. It allows creating both the executable and, optionally, an associated object or interface library
to allow better automated testing of the executable's sources. This library will have the
same name as the executable, but with '-library' appended (*main* -> *main-library*).

This function will:

- ensure it's called within a canonical source subdirectory and verify the naming conventions of the
  input source files, transform  SOURCES and LIB_SOURCES to absolute paths.
- create an executable target with :cmake:command:`add_executable`, including an associated alias
  (<PROJECT_NAME>::<target>) - both following JCM's target naming conventions
- set target properties:

  - OUTPUT_NAME
  - EXPORT_NAME
  - COMPILE_OPTIONS
  - INCLUDE_DIRECTORIES
  - COMPONENT (custom property to JCM)

Parameters
##########

Options
~~~~~~~~~~

:cmake:variable:`WITHOUT_CANONICAL_PROJECT_CHECK`
  When provided, will forgo the default check that the function is called within an executable
  source subdirectory, as defined by the `Canonical Project Structure`_.

One Value
~~~~~~~~~~

:cmake:variable:`COMPONENT`
  Specifies the component that this executable represents. Used to set `COMPONENT` property and when
  naming the target

:cmake:variable:`NAME`
  Overrides the target name, output name, and exported name from those automatically created to
  conform to JCM's naming conventions

:cmake:variable:`OUT_TARGET_NAME`
  The variable named will be set to the created target's name

Multi Value
~~~~~~~~~~~

:cmake:variable:`LIB_SOURCES`
  Sources used to create the executable's associated object/interface library. When provided, an
  object or interface library will be created, it will be linked against the executable, and its
  include directories will be set instead of the executable's. An object library
  will be created when any of the files provided end in :cmake:variable:`JCM_SOURCE_EXTENSION`,
  while an interface library will be created otherwise (just header files).

:cmake:variable:`SOURCES`
  Sources used to create the executable

Examples
########

.. code-block:: cmake

  jcm_add_executable(SOURCES main.cpp)
  target_link_libraries(example::example PRIVATE libthird::party)

.. code-block:: cmake

  # PROJECT_NAME is xml
  # target will be xml::xml

  jcm_add_executable(
    OUT_TARGET_NAME target
    SOURCES main.cpp
    LIB_SOURCES xml.cpp
  )

  jcm_add_test_executable(
    NAME test_parser
    SOURCES test_parser.cpp
    LIBS ${target}-library Boost::ut
  )

.. code-block:: cmake

  # creates associated interface library, instead of object library

  jcm_add_executable(
    OUT_TARGET_NAME target
    SOURCES main.cpp
    LIB_SOURCES coffee.hpp
  )

#]=======================================================================]
function(jcm_add_executable)
  jcm_parse_arguments(
    OPTIONS "WITHOUT_CANONICAL_PROJECT_CHECK"
    ONE_VALUE_KEYWORDS "COMPONENT;NAME;OUT_TARGET_NAME"
    MULTI_VALUE_KEYWORDS "SOURCES;LIB_SOURCES"
    REQUIRES_ALL "SOURCES"
    ARGUMENTS "${ARGN}")

  # Set executable component
  if (DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(comp_arg COMPONENT ${ARGS_COMPONENT})
    set(comp_err_msg "n component (${ARGS_COMPONENT})")
  else()
    unset(comp_arg)
    unset(comp_err_msg)
  endif ()

  # == Usage Guards ==

  # ensure executable is created in the appropriate canonical directory
  # defining executable components within root executable directory is allowed
  if(NOT ARGS_WITHOUT_CANONICAL_PROJECT_CHECK)
    jcm_canonical_exec_subdir(${comp_arg} OUT_VAR canonical_dir)
    if (NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL canonical_dir)
      message(
        FATAL_ERROR
        "Creating a${comp_err_msg} executable for project ${PROJECT_NAME} must "
        "be done in the canonical directory ${canonical_dir}.")
    endif ()
  endif()

  # verify source naming
  set(regex "${JCM_HEADER_REGEX}|${JCM_SOURCE_REGEX}")
  jcm_separate_list(
    INPUT "${ARGS_SOURCES};${ARGS_LIB_SOURCES}"
    REGEX "${regex}"
    TRANSFORM "FILENAME"
    OUT_UNMATCHED incorrectly_named
  )
  if (incorrectly_named)
    message(
      FATAL_ERROR
      "Provided source files do not match the regex for executable sources, "
      "${regex}: ${incorrectly_named}.")
  endif ()

  # == Create Executable ==

  # resolve executable names
  if (DEFINED ARGS_NAME)
    set(target_name ${ARGS_NAME})
    set(export_name ${ARGS_NAME})
    set(output_name ${ARGS_NAME})
  else ()
    jcm_executable_naming(
      ${comp_arg}
      OUT_TARGET_NAME target_name
      OUT_EXPORT_NAME export_name
      OUT_OUTPUT_NAME output_name)
  endif ()

  if (DEFINED ARGS_OUT_TARGET_NAME)
    set(${ARGS_OUT_TARGET_NAME} ${target_name} PARENT_SCOPE)
  endif ()

  # create executable target
  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_SOURCES}" OUT_VAR abs_sources)
  add_executable(${target_name} "${abs_sources}")
  add_executable(${PROJECT_NAME}::${export_name} ALIAS ${target_name})

  # == Set Target Properties ==

  jcm_canonical_include_dirs(TARGET ${target_name} OUT_VAR include_dirs)

  # basic properties
  set_target_properties(${target_name}
    PROPERTIES OUTPUT_NAME ${output_name}
    EXPORT_NAME ${export_name}
    COMPILE_OPTIONS "${JCM_DEFAULT_COMPILE_OPTIONS}")

  # include directories, if no library will be created to provide them
  if (NOT DEFINED ARGS_LIB_SOURCES)
    target_include_directories(${target_name} PRIVATE "$<BUILD_INTERFACE:${include_dirs}>")
  endif ()

  # custom component property
  if (DEFINED comp_arg)
    set_target_properties(${target_name} PROPERTIES ${comp_arg})
  endif ()

  # == Associated Library ==

  # create library of exec's sources, allowing unit testing of exec's sources
  if (DEFINED ARGS_LIB_SOURCES)
    # check for actual source files
    jcm_regex_find_list(
      REGEX "${JCM_SOURCE_REGEX}"
      INPUT "${ARGS_LIB_SOURCES}"
      OUT_IDX found_source_idx
    )

    # absolute paths
    jcm_transform_list(
      ABSOLUTE_PATH
      INPUT "${ARGS_LIB_SOURCES}"
      OUT_VAR abs_lib_sources
    )

    message(STATUS "HHHHHHHHHHHHHH found source idx for ${target_name}: ${found_source_idx}")

    # create interface or object library
    if(found_source_idx EQUAL -1)
      add_library(${target_name}-library INTERFACE)
      target_include_directories(
        ${target_name}-library
        INTERFACE
        "$<BUILD_INTERFACE:${include_dirs}>"
      )
      message(STATUS "HHHHHHHHHHHHHH Adding interface lib: ${target_name}")
    else()
      add_library(${target_name}-library OBJECT "${abs_lib_sources}")
      target_compile_options(${target_name}-library PRIVATE "${JCM_DEFAULT_COMPILE_OPTIONS}")
      target_include_directories(${target_name}-library PUBLIC "$<BUILD_INTERFACE:${include_dirs}>")
      message(STATUS "HHHHHHHHHHHHHH Adding object lib: ${target_name}")
    endif()


    # link target to associated object files &/or usage requirements
    target_link_libraries(${target_name} PRIVATE ${target_name}-library)
  endif ()
endfunction()

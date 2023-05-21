include_guard()

#[=======================================================================[.rst:

JcmAddExecutable
----------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmFileNaming)
include(JcmTargetNaming)
include(JcmListTransformations)
include(JcmHeaderFileSet)
include(JcmCanonicalStructure)
include(JcmDefaultCompileOptions)


#[=======================================================================[.rst:

jcm_add_executable
^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_add_executable

  .. code-block:: cmake

    jcm_add_executable(
      [WITHOUT_CANONICAL_PROJECT_CHECK]
      [COMPONENT <component>]
      [NAME <name>]
      [OUT_TARGET <out-var>]
      [LIB_SOURCES <source>...]
      SOURCES <source>...)

Adds an executable target to the project, similar to CMake's `add_executable`, but with enhancements
. It allows creating both the executable and, optionally, an associated object or interface library
to allow better automated testing of the executable's sources. This library will have the
same name as the executable, but with '-library' appended (*main* -> *main-library*).

This function will:

- ensure it's called within a canonical source subdirectory, verify the naming conventions and
  locations of the input source files, and transform :cmake:variable:`SOURCES` and
  :cmake:variable:`LIB_SOURCES` to normalized absolute paths.
- create header sets with :cmake:command:`jcm_header_file_sets` for both the main executable target,
  and the optional library target. PRIVATE header sets will be added to the executable using header
  files found in :cmake:variable:`SOURCES`, while PUBLIC or INTERFACE header sets will be added to
  the object/interface library using header files found in :cmake:variable:`LIB_SOURCES`.
  This is what sets the *INCLUDE_DIRECTORIES* properties.
- create an executable target with :cmake:command:`add_executable`, including an associated alias
  (<PROJECT_NAME>::<EXPORT_NAME>) - both following JCM's target naming conventions
- set target properties:

  - OUTPUT_NAME
  - EXPORT_NAME
  - COMPILE_OPTIONS
  - INCLUDE_DIRECTORIES
  - COMPONENT (custom property to JCM)

Parameters
##########

Options
~~~~~~~

:cmake:variable:`WITHOUT_CANONICAL_PROJECT_CHECK`
  When provided, will forgo the default check that the function is called within an executable
  source subdirectory, as defined by the `Canonical Project Structure`_.

One Value
~~~~~~~~~~

:cmake:variable:`COMPONENT`
  Specifies the component that this executable represents. Used to set `COMPONENT` property and when
  naming the target.

:cmake:variable:`NAME`
  Overrides the target name, output name, and exported name from those automatically created to
  conform to JCM's naming conventions

:cmake:variable:`OUT_TARGET`
  The variable named will be set to the created target's name

Multi Value
~~~~~~~~~~~

:cmake:variable:`LIB_SOURCES`
  Sources used to create the executable's associated object/interface library. When provided, an
  object or interface library will be created, it will be linked against the executable, and its
  include directories will be set instead of the executable's. An object library
  will be created when any of the file names of :cmake:variable:`LIB_SOURCES` match
  :cmake:variable:`JCM_SOURCE_REGEX`, while an interface library will be created otherwise
  (just header files).

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
    OUT_TARGET target
    SOURCES main.cpp
    LIB_SOURCES xml.cpp)

  jcm_add_test_executable(
    NAME test_parser
    SOURCES test_parser.cpp
    LIBS ${target}-library Boost::ut)

.. code-block:: cmake

  # creates associated interface library, instead of object library

  jcm_add_executable(
    OUT_TARGET target
    SOURCES main.cpp
    LIB_SOURCES coffee.hpp)

#]=======================================================================]
function(jcm_add_executable)
  jcm_parse_arguments(
    OPTIONS "WITHOUT_CANONICAL_PROJECT_CHECK"
    ONE_VALUE_KEYWORDS "COMPONENT;NAME;OUT_TARGET"
    MULTI_VALUE_KEYWORDS "SOURCES;LIB_SOURCES"
    REQUIRES_ALL "SOURCES"
    ARGUMENTS "${ARGN}")

  # transform arguments to normalized absolute paths
  foreach(source_type "" "_LIB")
    set(arg_name ARGS${source_type}_SOURCES)
    if(DEFINED ${arg_name})
      jcm_transform_list(ABSOLUTE_PATH INPUT "${${arg_name}}" OUT_VAR ${arg_name})
      jcm_transform_list(NORMALIZE_PATH INPUT "${${arg_name}}" OUT_VAR ${arg_name})
    endif()
  endforeach()

  set(all_input_files "${ARGS_SOURCES}" "${ARGS_LIB_SOURCES}")

  # Set executable component
  if(DEFINED ARGS_COMPONENT AND NOT ARGS_COMPONENT STREQUAL PROJECT_NAME)
    set(comp_arg COMPONENT ${ARGS_COMPONENT})
    set(comp_err_msg "n component (${ARGS_COMPONENT})")
    set(add_parent_arg ADD_PARENT)
  else()
    unset(comp_arg)
    unset(comp_err_msg)
    unset(add_parent_arg)
  endif()

  # == Usage Guards ==

  # ensure executable is created in the appropriate canonical directory
  # defining executable components within root executable directory is allowed
  if(NOT ARGS_WITHOUT_CANONICAL_PROJECT_CHECK)
    jcm_canonical_exec_subdir(${comp_arg} OUT_VAR canonical_dir)
    if(NOT CMAKE_CURRENT_SOURCE_DIR STREQUAL canonical_dir)
      message(
        FATAL_ERROR
        "Creating a${comp_err_msg} executable for project ${PROJECT_NAME} must "
        "be done in the canonical directory ${canonical_dir}.")
    endif()
  endif()

  # verify source naming
  set(regex "${JCM_HEADER_REGEX}|${JCM_SOURCE_REGEX}")
  jcm_separate_list(
    INPUT "${ARGS_SOURCES};${ARGS_LIB_SOURCES}"
    REGEX "${regex}"
    TRANSFORM "FILENAME"
    OUT_MISMATCHED incorrectly_named)
  if(incorrectly_named)
    message(
      FATAL_ERROR
      "Provided source files do not match the regex for executable sources, ${regex}: "
      "${incorrectly_named}.")
  endif()

  # verify file locations
  _jcm_verify_source_locations(${add_parent_arg} SOURCES "${all_input_files}")

  # == Create Executable ==

  # resolve executable names
  if(DEFINED ARGS_NAME)
    set(target_name ${ARGS_NAME})
    set(export_name ${ARGS_NAME})
    set(output_name ${ARGS_NAME})
  else()
    jcm_executable_naming(
      ${comp_arg}
      OUT_TARGET target_name
      OUT_EXPORT_NAME export_name
      OUT_OUTPUT_NAME output_name)
  endif()

  if(DEFINED ARGS_OUT_TARGET)
    set(${ARGS_OUT_TARGET} ${target_name} PARENT_SCOPE)
  endif()

  # create executable target
  add_executable(${target_name} "${ARGS_SOURCES}")
  add_executable(${PROJECT_NAME}::${export_name} ALIAS ${target_name})

  # == Set Target Properties ==

  # basic properties
  set_target_properties(${target_name}
    PROPERTIES OUTPUT_NAME ${output_name}
    EXPORT_NAME ${export_name}
    COMPILE_OPTIONS "${JCM_DEFAULT_COMPILE_OPTIONS}")

  # include directories on the executable
  jcm_separate_list(
    REGEX "${JCM_HEADER_REGEX}"
    INPUT "${ARGS_SOURCES}"
    TRANSFORM "FILENAME"
    OUT_MATCHED executable_header_files)

  if(executable_header_files)
    jcm_header_file_sets(PRIVATE
      TARGET ${target_name}
      HEADERS "${executable_header_files}")
  endif()

  # custom component property
  if(DEFINED comp_arg)
    set_target_properties(${target_name} PROPERTIES ${comp_arg})
  endif()

  # == Associated Library ==

  # create library of exec's sources, allowing unit testing of exec's sources
  if(DEFINED ARGS_LIB_SOURCES)
    jcm_separate_list(
      REGEX "${JCM_HEADER_REGEX}"
      INPUT "${ARGS_LIB_SOURCES}"
      TRANSFORM "FILENAME"
      OUT_MATCHED library_header_files
      OUT_MISMATCHED library_source_files)

    # create object or interface library
    if(library_source_files)
      set(include_dirs_scope PUBLIC)
      add_library(${target_name}-library OBJECT "${ARGS_LIB_SOURCES}")
      target_compile_options(${target_name}-library PRIVATE "${JCM_DEFAULT_COMPILE_OPTIONS}")
    else()
      set(include_dirs_scope INTERFACE)
      add_library(${target_name}-library INTERFACE)
    endif()

    if(library_header_files)
      jcm_header_file_sets(${include_dirs_scope}
        TARGET ${target_name}-library
        HEADERS "${library_header_files}")
    endif()

    # link target to associated object files &/or usage requirements
    target_link_libraries(${target_name} PRIVATE ${target_name}-library)
  endif()
endfunction()

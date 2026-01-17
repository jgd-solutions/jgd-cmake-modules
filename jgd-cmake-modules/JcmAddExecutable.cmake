include_guard()

#[=======================================================================[.rst:

JcmAddExecutable
----------------

:github:`JcmAddExecutable`

#]=======================================================================]

include(JcmParseArguments)
include(JcmTargetNaming)
include(JcmHeaderFileSet)
include(JcmCanonicalStructure)
include(JcmDefaultCompileOptions)
include(JcmTargetSources)
include(JcmListTransformations)
include(JcmFileNaming)
include(JcmStandardDirs)
include(JcmCanonicalStructure) # JCM_CANONICAL_SUBDIR_PREFIX_REGEX


#[=======================================================================[.rst:

jcm_add_executable
^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_add_executable

  .. code-block:: cmake

    jcm_add_executable(
      [WITHOUT_CANONICAL_PROJECT_CHECK]
      [WITHOUT_FILE_NAMING_CHECK]
      [COMPONENT <component>]
      [NAME <name>]
      [OUT_TARGET <out-var>]
      [LIB_SOURCES <source>...]
      SOURCES <source>...)

Adds an executable target to the project, similar to CMake's :cmake:`add_executable`, but with
enhancements. It allows creating both the executable and, optionally, an associated object or
interface library to allow better automated testing of the executable's sources. This library
will have the same name as the executable, but with '-library' appended (*main* -> *main-library*).

This function will:

- ensure it's called within a canonical source subdirectory, verify the naming conventions and
  locations of the input source files, and transform :cmake:variable:`SOURCES` and
  :cmake:variable:`LIB_SOURCES` to normalized absolute paths.
- create an executable target with :cmake:command:`add_executable`, including an associated alias
- optionally create an object library, `<target>-library`, with an associated alias
  <PROJECT_NAME>::<EXPORT_NAME>-library
  (<PROJECT_NAME>::<EXPORT_NAME>) - both following JCM's target naming conventions
- optionally create an object library, `<target>-library`, with an associated alias
  <PROJECT_NAME>::<EXPORT_NAME>-library
  (<PROJECT_NAME>::<EXPORT_NAME>) - both following JCM's target naming conventions
- create header sets with :cmake:command:`jcm_header_file_sets` for both the main executable target,
  and the optional library target. PRIVATE header sets will be added to the executable using header
  files found in :cmake:variable:`SOURCES`, while PUBLIC or INTERFACE header sets will be added to
  the object/interface library using header files found in :cmake:variable:`LIB_SOURCES`.
  This is what sets the *INCLUDE_DIRECTORIES* properties.
- set target properties:

  - OUTPUT_NAME
  - EXPORT_NAME
  - COMPILE_OPTIONS
  - LINK_OPTIONS
  - INCLUDE_DIRECTORIES
  - COMPONENT (custom property to JCM)

Parameters
##########

Options
~~~~~~~

:cmake:variable:`WITHOUT_CANONICAL_PROJECT_CHECK`
  When provided, will forgo the default check that the function is called within an executable
  source subdirectory, as defined by the `Canonical Project Structure`_.

:cmake:variable:`WITHOUT_FILE_NAMING_CHECK`
  When provided, will forgo the default check that provided header and source files conform to JCM's
  file naming conventions

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
    LIB_SOURCES xml.hpp xml.cpp)

  jcm_add_test_executable(
    NAME test_parser
    SOURCES test_parser.cpp
    LIBS ${target}-library Boost::ut)

.. code-block:: cmake

  # creates associated interface library, instead of object library

  jcm_add_executable(
    OUT_TARGET target
    SOURCES main.cpp
    LIB_SOURCES coffee.hpp coffee.hpp)

#]=======================================================================]
function(jcm_add_executable)
  jcm_parse_arguments(
    OPTIONS "WITHOUT_CANONICAL_PROJECT_CHECK" "WITHOUT_FILE_NAMING_CHECK"
    ONE_VALUE_KEYWORDS "COMPONENT;NAME;OUT_TARGET"
    MULTI_VALUE_KEYWORDS "SOURCES;LIB_SOURCES"
    REQUIRES_ALL "SOURCES"
    ARGUMENTS "${ARGN}")

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


  if(ARGS_WITHOUT_FILE_NAMING_CHECK)
    set(verify_file_naming_arg "WITHOUT_FILE_NAMING_CHECK")
  else()
    unset(verify_file_naming_arg)
  endif()

  if(NOT target_component)
    set(verify_target_component_arg TARGET_COMPONENT ${target_component})
  else()
    unset(verify_target_component_arg)
  endif()

  jcm_verify_sources(
    ${verify_file_naming_arg}
    ${verify_target_component_arg}
    TARGET_TYPE "EXECUTABLE"
    SOURCES "${ARGS_SOURCES}"
    OUT_PRIVATE_HEADERS executable_headers
    OUT_SOURCES executable_sources)

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
  add_executable(${target_name} "${executable_sources}")
  add_executable(${PROJECT_NAME}::${export_name} ALIAS ${target_name})

  # == Set Target Properties ==

  # basic properties
  set_target_properties(${target_name}
    PROPERTIES OUTPUT_NAME ${output_name}
    EXPORT_NAME ${export_name}
    COMPILE_OPTIONS "${JCM_DEFAULT_COMPILE_OPTIONS}"
    LINK_OPTIONS "${JCM_DEFAULT_LINK_OPTIONS}")

  # include directories on the executable
  if(executable_headers)
    jcm_header_file_sets(PRIVATE
      TARGET ${target_name}
      HEADERS "${executable_headers}")
  endif()

  # custom component property
  if(DEFINED comp_arg)
    set_target_properties(${target_name} PROPERTIES ${comp_arg})
  endif()

  # == Associated Library ==

  # create library of exec's sources, allowing unit testing of exec's sources
  if(DEFINED ARGS_LIB_SOURCES)
    jcm_verify_sources(
      ${verify_file_naming_arg}
      ${verify_target_component_arg}
      TARGET_TYPE "EXECUTABLE"
      SOURCES "${ARGS_LIB_SOURCES}"
      OUT_PRIVATE_HEADERS library_headers
      OUT_SOURCES library_sources)

    # create object or interface library
    if(library_sources)
      set(include_dirs_scope PUBLIC)
      add_library(${target_name}-library OBJECT "${library_sources}")
      target_compile_options(${target_name}-library PRIVATE "${JCM_DEFAULT_COMPILE_OPTIONS}")
    else()
      set(include_dirs_scope INTERFACE)
      add_library(${target_name}-library INTERFACE)
    endif()

    add_library(${PROJECT_NAME}::${export_name}-library ALIAS ${target_name}-library)

    if(library_headers)
      jcm_header_file_sets(${include_dirs_scope}
        TARGET ${target_name}-library
        HEADERS "${library_headers}")
    endif()

    # link target to associated object files &/or usage requirements
    target_link_libraries(${target_name} PRIVATE ${target_name}-library)
  endif()
endfunction()



#[=======================================================================[.rst:

jcm_add_test_executable
^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_add_test_executable

  .. code-block:: cmake

    jcm_add_test_executable(
      NAME <name>
      [TEST_NAME <test-name>]
      [LIBS <lib>...]
      SOURCES <source>...)

A convenience function to create an executable and add it as a test in one command, while also
setting target properties. This function has no affect if
:cmake:`${JCM_PROJECT_PREFIX_NAME}_ENABLE_TESTS` is not set.

This function will:

- verify the input source files using :cmake:command:`jcm_verify_target_sources`, and use the
  cleaned sources produced by that function.
- create an executable with name :cmake:variable:`NAME` from :cmake:variable:`SOURCES`.
- register this executable as a test via CTest with name :cmake:variable:`TEST_NAME`, which
  defaults to :cmake:variable:`NAME`, if :cmake:variable:`TEST_NAME` isn't provided.
- creates a private header set
- set target properties:

  - OUTPUT_NAME
  - COMPILE_OPTIONS
  - LINK_LIBRARIES

Parameters
##########

One Value
~~~~~~~~~~

:cmake:variable:`NAME`
  Sets the target name and output name of the created executable. Used as the default test name if
  :cmake:variable:`TEST_NAME` is not provided.

:cmake:variable:`TEST_NAME`
  Sets the test name to be registered with CTest.


Multi Value
~~~~~~~~~~~

:cmake:variable:`LIBS`
  Libraries to privately link against the created executable. Commonly the library that the created
  executable will test, and a testing framework.

:cmake:variable:`SOURCES`
  Sources used to create the executable

Examples
########

.. code-block:: cmake

  jcm_add_test_executable(NAME my_test SOURCES my_test.cpp)

.. code-block:: cmake

  jcm_add_executable(
    OUT_TARGET target
    SOURCES main.cpp
    LIB_SOURCES engine.hpp engine.cpp)

  jcm_add_test_executable(
    NAME test_engine
    SOURCES test_engine.cpp
    LIBS ${target}-library Boost::ut)

#]=======================================================================]
function(jcm_add_test_executable)
  if(NOT ${JCM_PROJECT_PREFIX_NAME}_ENABLE_TESTS)
    return()
  endif()

  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "NAME;TEST_NAME"
    MULTI_VALUE_KEYWORDS "SOURCES;LIBS"
    REQUIRES_ALL "NAME;SOURCES"
    ARGUMENTS "${ARGN}")

  # Additional naming considerations for unit test sources
  jcm_separate_list(
    INPUT "${ARGS_SOURCES}"
    REGEX "${JCM_UTEST_SOURCE_REGEX}"
    TRANSFORM "FILENAME"
    OUT_MATCHED unit_test_sources
    OUT_MISMATCHED standard_sources)

  if(unit_test_sources AND
    NOT CMAKE_CURRENT_SOURCE_DIR MATCHES "${JCM_PROJECT_CANONICAL_SUBDIR_PREFIX_REGEX}")
    message(FATAL_ERROR
      "The '.test' file extension is reserved for unit test sources. ${CMAKE_CURRENT_FUNCTION} is "
      "being called to create target '${ARGS_NAME}' with unit test source files outside of a "
      "canonical target subdirectory: ${unit_test_sources}")
  endif()

  if(standard_sources)
    jcm_verify_sources(
      TARGET_TYPE "EXECUTABLE"
      TARGET_SOURCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}"
      TARGET_BINARY_DIR "${CMAKE_CURRENT_BINARY_DIR}"
      SOURCES "${standard_sources}"
      OUT_PRIVATE_HEADERS test_headers
      OUT_SOURCES standard_sources)
  else()
    unset(test_headers)
  endif()

  # Default test name
  if(DEFINED ARGS_TEST_NAME)
    set(test_name "${ARGS_TEST_NAME}")
  else()
    set(test_name "${ARGS_NAME}")
  endif()

  # Test executable
  add_executable(${ARGS_NAME} "${standard_sources}" "${unit_test_sources}")
  add_test(NAME ${test_name} COMMAND ${ARGS_NAME})

  if(test_headers)
    jcm_header_file_sets(PRIVATE
      TARGET ${target_name}
      HEADERS "${test_headers}")
  endif()

  # Default properties
  set_target_properties(
    ${ARGS_NAME}
    PROPERTIES OUTPUT_NAME ${ARGS_NAME}
    COMPILE_OPTIONS "${JCM_DEFAULT_COMPILE_OPTIONS}"
    LINK_LIBRARIES "${ARGS_LIBS}")
endfunction()

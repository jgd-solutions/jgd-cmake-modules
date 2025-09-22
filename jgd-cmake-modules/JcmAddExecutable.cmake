include_guard()

#[=======================================================================[.rst:

JcmAddExecutable
----------------

:github:`JcmAddExecutable`

#]=======================================================================]

include(JcmParseArguments)
include(JcmTargetNaming)
include(JcmFileSet)
include(JcmCanonicalStructure)
include(JcmDefaultCompileOptions)
include(JcmTargetSources)
include(JcmListTransformations)


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
- create file-sets with :cmake:command:`jcm_create_file_sets` for both the main executable target,
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

  jcm_separate_list(
    INPUT "${ARGS_SOURCES}"
    OUT_MATCHED pure_headers
    OUT_MISMATCHED remaining
    TRANSFORM FILENAME
    REGEX "${JCM_HEADER_REGEX}")

  jcm_separate_list(
    INPUT "${remaining}"
    OUT_MATCHED ARGS_SOURCES
    OUT_MISMATCHED pure_modules
    TRANSFORM FILENAME
    REGEX "${JCM_SOURCE_REGEX}")

  jcm_verify_sources(
    ${verify_file_naming_arg}
    ${verify_target_component_arg}
    TARGET_TYPE "EXECUTABLE"
    PRIVATE_HEADERS "${pure_headers}"
    PRIVATE_CXX_MODULES "${pure_modules}"
    SOURCES "${ARGS_SOURCES}"
    OUT_PRIVATE_HEADERS executable_headers
    OUT_PRIVATE_CXX_MODULES executable_modules
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
  add_executable(${target_name} "${executable_headers}" "${executable_sources}")
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
    jcm_create_file_sets(PRIVATE
      TYPE HEADERS
      TARGET ${target_name}
      FILES "${executable_headers}")
  endif()

  if(executable_modules)
    jcm_create_file_sets(PRIVATE
      TYPE CXX_MODULES
      TARGET ${target_name}
      FILES "${executable_modules}")
  endif()

  # custom component property
  if(DEFINED comp_arg)
    set_target_properties(${target_name} PROPERTIES ${comp_arg})
  endif()

  # == Associated Library ==

  # create library of exec's sources, allowing unit testing of exec's sources
  if(DEFINED ARGS_LIB_SOURCES)
    jcm_separate_list(
      INPUT "${ARGS_LIB_SOURCES}"
      OUT_MATCHED pure_headers
      OUT_MISMATCHED remaining
      TRANSFORM FILENAME
      REGEX "${JCM_HEADER_REGEX}")

    jcm_separate_list(
      INPUT "${remaining}"
      OUT_MATCHED ARGS_LIB_SOURCES
      OUT_MISMATCHED pure_modules
      TRANSFORM FILENAME
      REGEX "${JCM_SOURCE_REGEX}")

    jcm_verify_sources(
      ${verify_file_naming_arg}
      ${verify_target_component_arg}
      TARGET_TYPE "EXECUTABLE"
      PRIVATE_HEADERS "${pure_headers}"
      PRIVATE_CXX_MODULES "${pure_modules}"
      SOURCES "${ARGS_LIB_SOURCES}"
      OUT_PRIVATE_HEADERS library_headers
      OUT_PRIVATE_CXX_MODULES library_modules
      OUT_SOURCES library_sources)

    # create object or interface library
    if(library_sources OR library_modules)
      set(include_dirs_scope PUBLIC)
      add_library(${target_name}-library OBJECT "${library_headers}" "${library_sources}")
      target_compile_options(${target_name}-library PRIVATE "${JCM_DEFAULT_COMPILE_OPTIONS}")
    else()
      set(include_dirs_scope INTERFACE)
      add_library(${target_name}-library INTERFACE)
    endif()

    add_library(${PROJECT_NAME}::${export_name}-library ALIAS ${target_name}-library)

    if(library_headers)
      jcm_create_file_sets(${include_dirs_scope}
        TYPE HEADERS
        TARGET ${target_name}-library
        FILES "${library_headers}")
    endif()

    if(library_modules)
      jcm_create_file_sets(${include_dirs_scope}
        TYPE CXX_MODULES
        TARGET ${target_name}-library
        FILES "${library_modules}")
    endif()

    # link target to associated object files &/or usage requirements
    target_link_libraries(${target_name} PRIVATE ${target_name}-library)
  endif()
endfunction()

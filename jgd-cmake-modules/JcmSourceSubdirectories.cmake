include_guard()

#[=======================================================================[.rst:

JcmSourceSubdirectories
-----------------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmCanonicalStructure)
include(JcmStandardDirs)
include(JcmListTransformations)

#
# Private macro to the module. After checking that it's a directory, appends the
# given SUBDIR to the 'subdirs_added' variable, and if ADD_SUBDIRS is specified,
# adds the given SUBDIR as a subdirectory.
#
# Arguments:
#
# FATAL: indicates that errors are fatal
#
# ADD_SUBDIRS: option; specifies that SUBDIR should be added as a subdirectory.
#
# SUBDIR: one-value arg; the path of the subdirectory to add to 'subdirs_added'
# and, optionally add as a subdirectory with CMake's add_subdirectory() command.
# Can be absolute or relative to the current directory, as defined by
# add_subdirectory().
#
macro(_JCM_CHECK_ADD_SUBDIR out_added_subdirs)
  jcm_parse_arguments(
    OPTIONS "ADD_SUBDIRS" "FATAL"
    ONE_VALUE_KEYWORDS "SUBDIR"
    REQUIRES_ALL "SUBDIR"
    ARGUMENTS "${ARGN}"
  )

  function(on_fatal_message msg)
    if(ARGS_FATAL)
      message(FATAL_ERROR "${msg}")
    endif()
  endfunction()

  if(NOT IS_DIRECTORY "${ARGS_SUBDIR}")
    on_fatal_message(
      "${CMAKE_CURRENT_FUNCTION} could not add subdirectory '${ARGS_SUBDIR}' for project\
       '${PROJECT_NAME}'. The directory does not exist."
    )
  elseif(NOT EXISTS "${ARGS_SUBDIR}/CMakeLists.txt")
    on_fatal_message(
      "${CMAKE_CURRENT_FUNCTION} could not add subdirectory ${ARGS_SUBDIR} for project\
       ${PROJECT_NAME}. The directory does not contain a CMakeLists.txt file."
    )
  elseif(CMAKE_CURRENT_SOURCE_DIR STREQUAL ARGS_SUBDIR)
    on_fatal_message(
      "${CMAKE_CURRENT_SOURCE_DIR} tries to add itself as a subdirectory."
    )
  else()
    # directory and file exist, deal with subdirectory
    list(APPEND ${out_added_subdirs} "${ARGS_SUBDIR}")
    if(ARGS_ADD_SUBDIRS)
      message(VERBOSE "${CMAKE_CURRENT_FUNCTION}: Adding directory '${ARGS_SUBDIR}' to project\
                       '${PROJECT_NAME}'")
      add_subdirectory("${ARGS_SUBDIR}")
    endif()
  endif()
endmacro()


#[=======================================================================[.rst:

jcm_source_subdirectories
^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_source_subdirectories

  .. code-block:: cmake

    jcm_source_subdirectories(
      [WITH_TESTS_DIR]
      [WITH_DOCS_DIR]
      <[OUT_VAR <out-var>]
       [ADD_SUBDIRS] >
      [LIB_COMPONENTS <component>...]
      [EXEC_COMPONENTS <component>...])

Computes and optionally adds subdirectories following JGD's project structure, which includes the
`Canonical Project Structure`_, which pertains to source subdirectories. These canonical
subdirectories are provided by functions in `JcmCanonicalStructure`, while project directories are
provided by :cmake:variable:`JCM_PROJECT_TESTS_DIR` and :cmake:variable:`JCM_PROJECT_DOCS_DIR` from
`JcmStandardDirs`.

Executable and library subdirectories for non-components will be added first, if they exist. Then,
source subdirectories for library and executable components will be added for the components
specified, with errors if they don't exist. Then, the standard *tests* and *docs* directory will be
optionally added - see Options

This is a function, which prevents added subdirectories from populating variables in the calling
list-file's scope. Bubbling up variables from subdirectories is an anti-pattern to be avoided, and
is simply not supported by this function.

Parameters
##########

Options
~~~~~~~

:cmake:variable:`WITH_TESTS_DIR`
  Causes the :cmake:variable:`JCM_PROJECT_TESTS_DIR` directory to be added when the
  :cmake:variable:`${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS` option is set.

:cmake:variable:`WITH_DOCS_DIR`
  Causes the :cmake:variable:`JCM_PROJECT_DOCS_DIR` directory to be added when the
  :cmake:variable:`${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS` option is set.

:cmake:variable:`ADD_SUBDIRS`
  Causes this function to add each subdirectory to the project using CMake's
  :cmake:command:`add_subdirectory`


One Value
~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The named variable will be set to the list of resultant subdirectories

Multi Value
~~~~~~~~~~~

:cmake:variable:`LIB_COMPONENTS`
  A list of library components for which subdirectories will be computed. Components matching
  :cmake:variable:`PROJECT_NAME` will be ignored.

:cmake:variable:`EXEC_COMPONENTS`
  A list of executable components for which subdirectories will be computed. Components matching
  :cmake:variable:`PROJECT_NAME` will be ignored.

Examples
########

.. code-block:: cmake

  jcm_source_subdirectories(
    WITH_TESTS_DIR
    WITH_DOCS_DIR
    OUT_VAR mylib_subdirectories)

.. code-block:: cmake

  jcm_source_subdirectories(
    WITH_TESTS_DIR
    WITH_DOCS_DIR
    OUT_VAR mylib_subdirectories
    ADD_SUBDIRS
    LIB_COMPONENTS core extra more)

#]=======================================================================]
function(jcm_source_subdirectories)
  jcm_parse_arguments(
    OPTIONS "ADD_SUBDIRS" "WITH_TESTS_DIR" "WITH_DOCS_DIR"
    ONE_VALUE_KEYWORDS "OUT_VAR"
    MULTI_VALUE_KEYWORDS "LIB_COMPONENTS" "EXEC_COMPONENTS"
    REQUIRES_ANY "ADD_SUBDIRS" "OUT_VAR"
    ARGUMENTS "${ARGN}")

  # Setup
  set(subdirs_added)
  list(REMOVE_ITEM ARGS_LIB_COMPONENTS "${PROJECT_NAME}")

  if(ARGS_ADD_SUBDIRS)
    set(add_subdirs_arg ADD_SUBDIRS)
  else()
    unset(add_subdirs_arg)
  endif()

  # Add Subdirs

  # add single library subdirectory, if it exists
  jcm_canonical_lib_subdir(OUT_VAR lib_subdir)
  _jcm_check_add_subdir(subdirs_added ${add_subdirs_arg} SUBDIR "${lib_subdir}")

  # library component subdirectories
  if(DEFINED ARGS_LIB_COMPONENTS)
    # add all library components' subdirectories
    foreach(component ${ARGS_LIB_COMPONENTS})
      jcm_canonical_lib_subdir(COMPONENT ${component} OUT_VAR subdir_path)

      set(JCM_CURRENT_COMPONENT ${component})
      _jcm_check_add_subdir(subdirs_added FATAL ${add_subdirs_arg} SUBDIR "${subdir_path}")
      unset(JCM_CURRENT_COMPONENT)
    endforeach()
  endif()

  # add single executable subdirectory, if it exists
  jcm_canonical_exec_subdir(OUT_VAR exec_subdir)
  _jcm_check_add_subdir(subdirs_added ${add_subdirs_arg} SUBDIR "${exec_subdir}")

  # executable component subdirectories
  if(DEFINED ARGS_EXEC_COMPONENTS)
    # add all executable components' subdirectories
    foreach(component ${ARGS_EXEC_COMPONENTS})
      jcm_canonical_exec_subdir(COMPONENT ${component} OUT_VAR subdir_path)

      set(JCM_CURRENT_COMPONENT ${component})
      _jcm_check_add_subdir(subdirs_added FATAL ${add_subdirs_arg} SUBDIR "${subdir_path}")
      unset(JCM_CURRENT_COMPONENT)
    endforeach()
  endif()

  # Ensure at least one subdirectory was added
  if(NOT subdirs_added)
    message(
      FATAL_ERROR
      "${CMAKE_CURRENT_FUNCTION} could not add any subdirectories for "
      "project ${PROJECT_NAME}. The canonical subdirectories do not exist")
  endif()

  # Add supplementary source subdirectories
  if(ARGS_WITH_TESTS_DIR AND ${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS)
    _jcm_check_add_subdir(subdirs_added FATAL ${add_subdirs_arg} SUBDIR "${JCM_PROJECT_TESTS_DIR}")
  endif()

  if(ARGS_WITH_DOCS_DIR AND ${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS)
    _jcm_check_add_subdir(subdirs_added FATAL ${add_subdirs_arg} SUBDIR "${JCM_PROJECT_DOCS_DIR}")
  endif()

  # Set result variable
  if(DEFINED ARGS_OUT_VAR)
    set(${ARGS_OUT_VAR} "${subdirs_added}" PARENT_SCOPE)
  endif()
endfunction()


#[=======================================================================[.rst:

jcm_collect_subdirectory_targets
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_collect_subdirectory_targets

  .. code-block:: cmake

    jcm_collect_subdirectory_targets(
      [EXCLUDE_DIRECTORY_REGEX <regex>]
      [START_DIR <directory>]
      <[OUT_VAR <out-var>])

Collects all targets created in and under the current directory, or that named in
:cmake:variable:`START_DIR`, into a unique list.

This function recursively traverses directories, descending into all subdirectories provided by the
directory property :cmake:variable:`SUBDIRECTORIES` to collect the targets created in that
directory, as indicated by the directory property :cmake:variable:`BUILDSYSTEM_TARGETS`. The
directories can be optionally excluded from the search by providing a regular expression via
:cmake:variable:`EXCLUDE_DIRECTORY_REGEX` that will be applied to the directory's *normalized,
absolute path*. All targets created directly in the directories matching the regex will be omitted,
while targets from their subdirectories will still be collected should they *not* match the regex.
The result of this function will always be a unique list, even if the global property
:cmake:variable:`ALLOW_DUPLICATE_CUSTOM_TARGETS` is set.

Parameters
##########


One Value
~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The named variable will be set to the list of resultant targets

:cmake:variable:`START_DIR`
  An optional path to an existent directory that will be used as the starting directory in the
  traversal. A relative path will first be converted to its normalized, absolute form with respect to
  :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`. Should this be omitted, traversal will begin at
  :cmake:`${CMAKE_CURRENT_SOURCE_DIR}`.

:cmake:variable:`EXCLUDE_DIRECTORY_REGEX`
  An optional regular expression that will be used to filter directories from the search.

Examples
########

.. code-block:: cmake

  jcm_collect_subdirectory_targets(OUT_VAR all_project_targets)

  jcm_transform_list(ALIASED_TARGET
    INPUT "${all_project_targets}"
    OUT_VAR all_project_targets)

.. code-block:: cmake

  jcm_collect_subdirectory_targets(
    EXCLUDE_DIRECTORY_REGEX "build.*"
    OUT_VAR all_project_targets)

.. code-block:: cmake

  jcm_collect_subdirectory_targets(
    START_DIR "../code-gen"
    EXCLUDE_REGEX "${PROJECT_SOURCE_DIR}/.*code-gen/.*database"
    OUT_VAR code_gen_targets)

#]=======================================================================]
function(jcm_collect_subdirectory_targets)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_VAR" "EXCLUDE_DIRECTORY_REGEX" "START_DIR"
    REQUIRES_ALL "OUT_VAR"
    ARGUMENTS "${ARGN}")

  if(NOT EXISTS "${ARGS_START_DIR}")
    message(FATAL_ERROR
      "The 'START_DIR' provided to ${CMAKE_CURRENT_FUNCTION} does not exist: '${ARGS_START_DIR}'")
  endif()
  if(NOT DEFINED ARGS_START_DIR)
    set(ARGS_START_DIR "${CMAKE_CURRENT_SOURCE_DIR}")
  elseif(NOT IS_DIRECTORY "${ARGS_START_DIR}")
    message(FATAL_ERROR
      "The 'START_DIR' provided to ${CMAKE_CURRENT_FUNCTION} does not refer to a directory: "
      "'${ARGS_START_DIR}'")
  endif()

  function(impl directory out_targets)
    set(targets)
    cmake_path(ABSOLUTE_PATH directory NORMALIZE BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

    if(NOT DEFINED ARGS_EXCLUDE_DIRECTORY_REGEX OR
       NOT "${directory}" MATCHES "${ARGS_EXCLUDE_DIRECTORY_REGEX}")
      get_property(current_targets DIRECTORY ${directory} PROPERTY BUILDSYSTEM_TARGETS)
      list(APPEND targets ${current_targets})
    endif()

    # SUBDIRECTORIES property is read-only & populated by CMake with absolute, native paths
    get_property(subdirs DIRECTORY ${directory} PROPERTY SUBDIRECTORIES)
    foreach(subdir IN LISTS subdirs)
      impl(${subdir} subdir_targets)
      list(APPEND targets ${subdir_targets})
    endforeach()

    set(${out_targets} ${targets} PARENT_SCOPE)
  endfunction()

  impl("${ARGS_START_DIR}" targets)
  list(REMOVE_DUPLICATES targets)  # in case of ALLOW_DUPLICATE_CUSTOM_TARGETS
  set(${ARGS_OUT_VAR} ${targets} PARENT_SCOPE)
endfunction()

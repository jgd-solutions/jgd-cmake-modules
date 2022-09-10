include_guard()

#[=======================================================================[.rst:

JcmCanonicalStructure
---------------------

Specifications in `Canonical Project Structure`_, implemented in CMake. This modules concerns itself
with source subdirectories, include directories, the 'lib' prefix, and file extensions.  Actual file
naming is implemented in *JcmFileNaming*, which uses the file extensions defined here.

.. note::
  This module is often just an implementation detail of JCM, and doesn't need to be used directly.

Variables
#########

:cmake:variable:`JCM_LIB_PREFIX`
  The prefix used throughout JCM for libraries. Used in project names and when naming targets. Set
  as 'lib' from `Canonical Project Structure`_.

:cmake:variable:`JCM_HEADER_EXTENSION`
  File extension for header files. '.hpp' option selected from `Canonical Project Structure`_

:cmake:variable:`JCM_SOURCE_EXTENSION`
  File extension for source files. '.cpp' option selected from `Canonical Project Structure`_

:cmake:variable:`JCM_TEST_SOURCE_EXTENSION`
  File extension for unit testing source files. '.test.cpp' option selected from `Canonical Project
  Structure`_

:cmake:variable:`JCM_MODULE_EXTENSION`
  File extension for module interface files. '.mpp' option selected from `Canonical Project
  Structure`_

:cmake:variable:`JCM_IN_FILE_EXTENSION`
  File extension used for input files that will undergo substitution through some version of
  :cmake:command:`configure_file`. This is a custom file extension for JCM, placed here for unity.


#]=======================================================================]

include(JcmParseArguments)
include(JcmTargetNaming)


set(JCM_LIB_PREFIX "lib")

set(JCM_HEADER_EXTENSION ".hpp")
set(JCM_SOURCE_EXTENSION ".cpp")
set(JCM_TEST_SOURCE_EXTENSION ".test.cpp")
set(JCM_MODULE_EXTENSION ".mpp") # cmake doesn't support modules, but for future
set(JCM_IN_FILE_EXTENSION ".in")

#[=======================================================================[.rst:

.. cmake:command:: jcm_canonical_subdir

  .. code-block:: cmake

    jcm_canonical_subdir(
      OUT_VAR <out-var>
      [COMPONENT <component>]
    )

Sets the variable specified by :cmake:variable:`OUT_VAR` to the canonical source subdirectory for
either an executable or library of project :cmake:variable:`PROJECT_NAME`. Calls either
:cmake:command:`jcm_canonical_lib_subdir` or :cmake:command:`jcm_canonical_exec_subdir` based on the
target :cmake:variable:`TYPE` property, or the deduced type from the target name, if the target is
not yet created.

Parameters
##########

One Value
~~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to the computed subdirectory

:cmake:variable:`COMPONENT`
  The name of the library/executable component for which the path will be computed.

Examples
########

.. code-block:: cmake
  :caption: ssh/CMakeLists.txt

  project(ssh VERSION 0.0.0)
  ...
  jcm_canonical_subdir(OUT_VAR ssh_subdir TARGET ssh::ssh)
  message(STATUS "${ssh_subdir}") # ssh/ssh

.. code-block:: cmake
  :caption: ssh/CMakeLists.txt

  project(ssh VERSION 0.0.0)
  ...
  jcm_canonical_subdir(OUT_VAR cli_subdir TARGET ssh::cli)
  message(STATUS "${cli_subdir}") # ssh/ssh/cli

#]=======================================================================]
function(jcm_canonical_subdir)
  jcm_parse_arguments(ONE_VALUE_KEYWORDS "TARGET;OUT_VAR"
                      REQUIRES_ALL "TARGET;OUT_VAR" ARGUMENTS "${ARGN}")

  # Usage Guards
  if(NOT ARGS_TARGET MATCHES "^${PROJECT_NAME}(::|_)")
    set(mismatched_target_message
      "TARGET '${ARGS_TARGET}' provided to ${CMAKE_CURRENT_FUNCTION} does not "
      "start with '${PROJECT_NAME}::' or '${PROJECT_NAME}_' and is therefore not a target of "
      "project ${PROJECT_NAME} or does not follow the target naming structure."
    )
  else()
    unset(mismatched_target_message)
  endif()

  if (TARGET ${ARGS_TARGET})
    get_target_property(target_type ${ARGS_TARGET} TYPE)
    get_target_property(component ${ARGS_TARGET} COMPONENT)

    if(mismatched_target_message)
      message(NOTICE "${mismatched_target_message}")
    endif()

  else()
    if(mismatched_target_message)
      message(FATAL_ERROR "${mismatched_target_message}")
    endif()

    jcm_target_type_component_from_name(
      TARGET_NAME ${ARGS_TARGET}
      OUT_TYPE target_type
      OUT_COMPONENT component
    )
  endif()

  # Resolve subdir based on type
  if(component)
    set(comp_arg COMPONENT ${component})
  else()
    unset(comp_arg)
  endif()

  if(target_type STREQUAL "EXECUTABLE")
    jcm_canonical_exec_subdir(${comp_arg} OUT_VAR canonical_subdir)
  else()
    jcm_canonical_lib_subdir(${comp_arg} OUT_VAR canonical_subdir)
  endif()

  set(${ARGS_OUT_VAR} ${canonical_subdir} PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:

.. cmake:command:: jcm_canonical_lib_subdir

  .. code-block:: cmake

    jcm_canonical_lib_subdir(
      OUT_VAR <out-var>
      [COMPONENT <component>]
    )

Sets the variable specified by :cmake:variable:`OUT_VAR` to the canonical source subdirectory for a
library of project :cmake:variable:`PROJECT_NAME`.

When :cmake:variable:`COMPONENT` is omitted, the output will be the canonical project path for a
single library of :cmake:variable:`PROJECT_NAME`, regardless of if :cmake:variable:`PROJECT_NAME`
names a library or executable. The resulting path is absolute, and will be
`/<JCM_LIB_PREFIX><name>`, with respect to :cmake:variable:`PROJECT_SOURCE_DIR`, where 'name' is the
:cmake:variable:`PROJECT_NAME` without any lib prefix (*libproj* -> *proj*).

When :cmake:variable:`COMPONENT` is provided, the output will name a library component, considering
the :cmake:variable:`PROJECT_NAME` and the :cmake:variable:`COMPONENT` argument. The resulting path
is absolute, and will be `/<PROJECT_NAME>-<COMPONENT>/<PROJECT_NAME>/<COMPONENT>`, with respect to
the :cmake:variable:`PROJECT_SOURCE_DIR`.

Parameters
##########

One Value
~~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to the computed subdirectory

:cmake:variable:`COMPONENT`
  The name of the library component for which the path will be computed.

Examples
########

.. code-block:: cmake
  :caption: libdecorate/CMakeLists.txt

  project(libdecorate VERSION 0.0.0)
  ...
  jcm_canonical_lib_subdir(OUT_VAR main_library_subdir)
  message(STATUS "${main_library_subdir}") # libdecorate/libdecorate

.. code-block:: cmake
  :caption: libdecorate/CMakeLists.txt

  project(libdecorate VERSION 0.0.0)
  ...
  jcm_canonical_lib_subdir(OUT_VAR paint_subdir COMPONENT paint)
  message(STATUS "${paint_subdir}") # libdecorate/libdecorate-paint/libdecorate/paint

  jcm_canonical_lib_subdir(OUT_VAR restore_subdir COMPONENT restore)
  message(STATUS "${restore_subdir}") # libdecorate/libdecorate-restore/libdecorate/restore

#]=======================================================================]
function(jcm_canonical_lib_subdir)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_VAR;COMPONENT"
    REQUIRES_ALL "OUT_VAR"
    ARGUMENTS "${ARGN}"
  )

  if (DEFINED ARGS_COMPONENT)
    string(JOIN "-" comp_dir ${PROJECT_NAME} ${ARGS_COMPONENT})
    set(${ARGS_OUT_VAR} "${PROJECT_SOURCE_DIR}/${comp_dir}/${PROJECT_NAME}/${ARGS_COMPONENT}"
      PARENT_SCOPE)
  else ()
    string(REGEX REPLACE "^${JCM_LIB_PREFIX}" "" no_lib "${PROJECT_NAME}")
    set(${ARGS_OUT_VAR} "${PROJECT_SOURCE_DIR}/${JCM_LIB_PREFIX}${no_lib}" PARENT_SCOPE)
  endif ()
endfunction()

#[=======================================================================[.rst:

.. cmake:command:: jcm_canonical_exec_subdir

  .. code-block:: cmake

    jcm_canonical_exec_subdir(
      OUT_VAR <out-var>
      [COMPONENT <component>]
    )

Sets the variable specified by :cmake:variable:`OUT_VAR` to the canonical source subdirectory for an
executable of project :cmake:variable:`PROJECT_NAME`.

When COMPONENT is omitted, the output is the canonical project path for a single executable of
:cmake:variable:`PROJECT_NAME`, regardless of if :cmake:variable:`PROJECT_NAME` names a library or
executable. The resulting path is absolute, and will be `/<name>`, with respect to
:cmake:variable:`PROJECT_SOURCE_DIR`, where 'name' is the :cmake:variable:`PROJECT_NAME` without any
lib prefix.

When COMPONENT is provided, the output is the canonical project path for an executable component,
considering the :cmake:variable:`PROJECT_NAME` and the :cmake:variable:`COMPONENT` argument,
regardless of if :cmake:variable:`PROJECT_NAME` names a library or executable.  The resulting path
is absolute, and will be `/<name>/<COMPONENT>`, with respect to
:cmake:variable:`PROJECT_SOURCE_DIR`, where 'name' is :cmake:variable:`PROJECT_NAME` without any lib
prefix.

Parameters
##########

One Value
~~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to the computed subdirectory

:cmake:variable:`COMPONENT`
  The name of the executable component for which the path will be computed.

Examples
########

.. code-block:: cmake
  :caption: ssh/CMakeLists.txt

  project(ssh VERSION 0.0.0)
  ...
  jcm_canonical_exec_subdir(OUT_VAR ssh_subdir)
  message(STATUS "${ssh_subdir}") # ssh/ssh

.. code-block:: cmake
  :caption: libdecorate/CMakeLists.txt

  project(libdecorate VERSION 0.0.0)
  ...
  jcm_canonical_exec_subdir(OUT_VAR decorate_subdir)
  message(STATUS "${decorate_subdir}") # libdecorate/decorate

#]=======================================================================]
function(jcm_canonical_exec_subdir)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_VAR;COMPONENT"
    REQUIRES_ALL "OUT_VAR"
    ARGUMENTS "${ARGN}")
  if (DEFINED ARGS_COMPONENT)
    jcm_canonical_exec_subdir(OUT_VAR exec_subdir)
    set(exec_comp_subdir "${exec_subdir}/${ARGS_COMPONENT}")
    set(${ARGS_OUT_VAR} "${exec_comp_subdir}" PARENT_SCOPE)
  else ()
    string(REGEX REPLACE "^${JCM_LIB_PREFIX}" "" no_lib "${PROJECT_NAME}")
    set(${ARGS_OUT_VAR} "${PROJECT_SOURCE_DIR}/${no_lib}" PARENT_SCOPE)
  endif ()
endfunction()

#[=======================================================================[.rst:

.. cmake:command:: jcm_canonical_include_dirs

  .. code-block:: cmake

    jcm_canonical_include_dirs(
      OUT_VAR <out-var>
      TARGET <target>
    )

Sets the variable specified by :cmake:variable:`OUT_VAR` to the canonical include directories for
:cmake:variable:`TARGET`.

The provided target's :cmake:variable:`SOURCE_DIR`, :cmake:variable:`TYPE`, and
:cmake:variable:`COMPONENT` properties will be queried to resolve the target's include directory in
the source tree. This will be one or two parent directories from its canonical source directory.
This creates the include prefix of `<PROJECT_NAME>`, or `<PROJECT_NAME>/<COMPONENT>` when the target
is a component.  :cmake:variable:`PROJECT_BINARY_DIR` will then be appended to the source include
directory for generated headers.

Parameters
##########

One Value
~~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to a list of the computed include directories.

:cmake:variable:`TARGET`
  The name of the target to resolve the canonical include directories for.

Examples
########

.. code-block:: cmake
  :caption: ssh/CMakeLists.txt

  project(ssh VERSION 0.0.0)
  ...
  jcm_canonical_exec_subdir(OUT_VAR ssh_subdir)
  message(STATUS "${ssh_subdir}") # ssh/ssh

.. code-block:: cmake
  :caption: libdecorate/CMakeLists.txt

  project(libdecorate VERSION 0.0.0)
  ...
  jcm_canonical_exec_subdir(OUT_VAR decorate_subdir)
  message(STATUS "${decorate_subdir}") # libdecorate/decorate

#]=======================================================================]
function(jcm_canonical_include_dirs)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "TARGET;OUT_VAR"
    REQUIRES_ALL "TARGET;OUT_VAR"
    ARGUMENTS "${ARGN}"
  )

  # Usage guards
  if (NOT TARGET ${ARGS_TARGET})
    message(FATAL_ERROR "${ARGS_TARGET} is not a target and must first be created before calling "
      "${CMAKE_CURRENT_FUNCTION}.")
  endif ()

  # Target properties
  get_target_property(source_dir ${ARGS_TARGET} SOURCE_DIR)
  get_target_property(target_type ${ARGS_TARGET} TYPE)
  get_target_property(component ${ARGS_TARGET} COMPONENT)

  # Helpful macro to check & emit error
  macro(_CHECK_ERR subdir)
    if (NOT source_dir MATCHES "^${subdir}")
      message(
        FATAL_ERROR
        "Unable to resolve default include directory for target ${ARGS_TARGET}. The source "
        "subdirectory, ${source_dir}, is not a parent of its canonical include, ${subdir}.")
    endif ()
  endmacro()

  # Set include directory from canonical directories for respective target type
  jcm_canonical_subdir(TARGET ${ARGS_TARGET} OUT_VAR include_directory)
  _check_err("${source_subdirectory}")

  if (NOT target_type STREQUAL "EXECUTABLE" AND component)
    set(prefix_parents 2)
  else ()
    set(prefix_parents 1)
  endif ()

  # Set include dir up the canonical source path to create include prefix
  foreach (i RANGE 1 ${prefix_parents})
    cmake_path(GET include_directory PARENT_PATH include_directory)
  endforeach ()

  # Add appropriate binary dir for generated headers
  set(binary_dirs "${PROJECT_BINARY_DIR}")
  if (component)
    list(APPEND binary_dirs "${PROJECT_BINARY_DIR}/${PROJECT_NAME}-${component}")
  endif ()

  set(${ARGS_OUT_VAR} "${include_directory}" "${binary_dirs}" PARENT_SCOPE)
endfunction()

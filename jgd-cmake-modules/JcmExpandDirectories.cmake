include_guard()

#[=======================================================================[.rst:

JcmExpandDirectories
--------------------

#]=======================================================================]

include(JcmParseArguments)

#[=======================================================================[.rst:

jcm_expand_directories
^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_expand_directories

  .. code-block:: cmake

    jcm_expand_directories(
      OUT_VAR <out-var>
      GLOB <glob>
      PATHS <path>...
    )


For each path in :cmake:variable:`PATHS`, if the path is a directory, the enclosed files matching
:cmake:variable:`GLOB` will be expanded into the list specified by :cmake:variable:`OUT_VAR`. Paths
in :cmake:variable:`PATHS` that refer directly to files will be directly added to the result.
However, all of the resulting paths will be absolute with respect to
:cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`.

Parameters
##########

One Value
~~~~~~~~~

:cmake:variable:`OUT_VAR`
  The variable named will be set to the resultant list of file paths

:cmake:variable:`GLOB`
  The globbing expression for files within directory paths. The directory path currently being
  expanded will be prepended to this, such that only files within the current path are used.


Multi Value
~~~~~~~~~~~

:cmake:variable:`PATHS`
  List of file and directory paths to expand

Examples
########

.. code-block:: cmake

  jcm_expand_directories(
    OUT_VAR cmake_module_paths
    GLOB *.cmake
    PATHS "${JCM_PROJECT_CMAKE_DIR}" "additional/path/special.cmake"
  )

#]=======================================================================]
function(jcm_expand_directories)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_VAR;GLOB"
    MULTI_VALUE_KEYWORDS "PATHS"
    REQUIRES_ALL "PATHS;OUT_VAR;GLOB"
    ARGUMENTS "${ARGN}")

  # Fill list with all file paths
  set(file_paths)
  foreach (in_path ${ARGS_PATHS})
    # convert to abs path; if(IS_DIRECTORY) isn't well defined for rel. paths
    file(REAL_PATH "${in_path}" full_path)

    if (IS_DIRECTORY "${full_path}")
      # extract files within directory
      file(
        GLOB_RECURSE expand_files
        LIST_DIRECTORIES false
        "${full_path}/${ARGS_GLOB}")
      if (expand_files)
        list(APPEND file_paths "${expand_files}")
      endif ()
    else ()
      # directly add file
      list(APPEND file_paths "${full_path}")
    endif ()
  endforeach ()

  # Set out var
  set(${ARGS_OUT_VAR} "${file_paths}" PARENT_SCOPE)
endfunction()

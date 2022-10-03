include_guard()

#[=======================================================================[.rst:

JcmSourceSubdirectories
-----------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmCanonicalStructure)
include(JcmStandardDirs)

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

  macro(on_fatal_message msg)
    if(ARGS_FATAL)
      message(FATAL_ERROR "${msg}")
    endif()
  endmacro()

  if (ARGS_SUBDIR IN_LIST subdir_omissions)
    # skip subdirectory all together
    message(STATUS "Omitting subdirectory from project ${PROJECT_NAME}: ${ARGS_SUBDIR}")
    list(REMOVE_ITEM unused_subdir_omissions "${ARGS_SUBDIR}")
  else()
    if (NOT IS_DIRECTORY "${ARGS_SUBDIR}")
      on_fatal_message(
        "${CMAKE_CURRENT_FUNCTION} could not add subdirectory ${subdir_path} for project "
        "${PROJECT_NAME}. The directory does not exist."
      )
    elseif (NOT EXISTS "${ARGS_SUBDIR}/CMakeLists.txt")
      on_fatal_message(
        "${CMAKE_CURRENT_FUNCTION} could not add subdirectory ${subdir_path} for project "
        "${PROJECT_NAME}. The directory does not contain a CMakeLists.txt file."
      )
    elseif (CMAKE_CURRENT_SOURCE_DIR STREQUAL ARGS_SUBDIR)
      on_fatal_message(
        "${CMAKE_CURRENT_SOURCE_DIR} tries to add itself as a subdirectory."
      )
    else()
      # directory and file exist, deal with subdirectory
      list(APPEND ${out_added_subdirs} "${ARGS_SUBDIR}")
      if (ARGS_ADD_SUBDIRS)
        message(VERBOSE "${CMAKE_CURRENT_FUNCTION}: Adding directory ${ARGS_SUBDIR} to project "
          "${PROJECT_NAME}")
        add_subdirectory("${ARGS_SUBDIR}")
      endif()
    endif()

  endif()
endmacro()


#[=======================================================================[.rst:

jcm_source_subdirectories
^^^^^^^^^^^^^^^^^^^^^^^^^

.. cmake:command::jcm_source_subdirectories

  .. code-block:: cmake

    jcm_source_subdirectories(
      [WITH_TESTS_DIR]
      [WITH_DOCS_DIR]
      (OUT_VAR <out-var> | ADD_SUBDIRS)
      [LIB_COMPONENTS <component>...]
      [EXEC_COMPONENTS <component>...]
    )

Computes and possibly adds subdirectories following JGD's project layout conventions, which includes
the `Canonical Project Structure`_ source subdirectory structure. These canonical subdirectories are
provided by functions in `JcmCanonicalStructure`, while project directories are provided by
:cmake:variable:`JCM_PROJECT_TESTS_DIR` and :cmake:variable:`JCM_PROJECT_DOCS_DIR` from
`JcmStandardDirs`.

This is a function, which prevents added subdirectories from populating variables in the calling
list-file's scope. This is an anti-pattern to be avoided, and is simply not supported by this
function.

The source subdirectories for the targets named in
:cmake:variable:`${JCM_PROJECT_PREFIX_NAME}_OMIT_TARGETS` are computed and omitted from the output
and/or addition to the project. Warnings will be emitted for targets in this list that are not
connected to this project.

That is, the executable, executable components,
library, or library component subdirectories will be added, if they exist. The variable
JCM_CURRENT_COMPONENT will be set to the component before adding each component's subdirectory.
Options also exist to consider the standard tests and docs project directories as source
subdirectories.

#]=======================================================================]

#
#
# Arguments:
#
# LIB_COMPONENTS: multi-value arg; list of library components that the PROJECT
# encapsulates.  Optional and shouldn't be used if the project doesn't contain
# any library components. Components that match the PROJECT_NAME will be
# ignored.
#
# OUT_VAR: one-value arg; the name of the list that will contain the added
# subdirectories. This list will be populated regardless of if the ADD_SUBDIRS
# was provided, or not.
#
# ADD_SUBDIRS: option; when defined, will cause the function to add the
# source subdirectories as project subdirectories with CMake's
# add_subdirectory() command, in addition to adding them to the variable
# specified by OUT_VAR.
#
# WITH_TESTS_DIR: option; when defined, will cause JCM_PROJECT_TESTS_DIR to be
# considered as a source subdirectory when the
# <JCM_PROJECT_PREFIX_NAME>_BUILD_TESTS option is set.
#
# WITH_DOCS_DIR: option; when defined, will cause JCM_PROJECT_DOCS_DIR to be
# considered as a source subdirectory when the
# <JCM_PROJECT_PREFIX_NAME>_BUILD_DOCS option is set.
#
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

  if (ARGS_ADD_SUBDIRS)
    set(add_subdirs_arg ADD_SUBDIRS)
  else()
    unset(add_subdirs_arg)
  endif ()

  # Subdirectory Omissions
  set(subdir_omissions)
  set(unused_subdir_omissions)
  if(ARGS_ADD_SUBDIRS)
    foreach(target IN LISTS ${JCM_PROJECT_PREFIX_NAME}_OMIT_TARGETS)
      jcm_canonical_subdir(TARGET ${target} OUT_VAR subdir_omission)
      list(APPEND subdir_omissions ${subdir_omission})
    endforeach()

    set(unused_subdir_omissions "${subdir_omissions}")
  endif()

  # Add Subdirs

  # add single library subdirectory, if it exists
  jcm_canonical_lib_subdir(OUT_VAR lib_subdir)
  _jcm_check_add_subdir(subdirs_added ${add_subdirs_arg} SUBDIR "${lib_subdir}")

  # library component subdirectories
  if (DEFINED ARGS_LIB_COMPONENTS)
    # add all library components' subdirectories
    foreach (component ${ARGS_LIB_COMPONENTS})
      jcm_canonical_lib_subdir(COMPONENT ${component} OUT_VAR subdir_path)

      set(JCM_CURRENT_COMPONENT ${component})
      _jcm_check_add_subdir(subdirs_added FATAL ${add_subdirs_arg} SUBDIR "${subdir_path}")
      unset(JCM_CURRENT_COMPONENT)
    endforeach ()
  endif ()

  # add single executable subdirectory, if it exists
  jcm_canonical_exec_subdir(OUT_VAR exec_subdir)
  _jcm_check_add_subdir(subdirs_added ${add_subdirs_arg} SUBDIR "${exec_subdir}")

  # executable component subdirectories
  if (DEFINED ARGS_EXEC_COMPONENTS)
    # add all executable components' subdirectories
    foreach (component ${ARGS_EXEC_COMPONENTS})
      jcm_canonical_exec_subdir(COMPONENT ${component} OUT_VAR subdir_path)

      set(JCM_CURRENT_COMPONENT ${component})
      _jcm_check_add_subdir(subdirs_added FATAL ${add_subdirs_arg} SUBDIR "${subdir_path}")
      unset(JCM_CURRENT_COMPONENT)
    endforeach ()
  endif ()

  # Ensure at least one subdirectory was added
  if (NOT subdirs_added)
    message(
      FATAL_ERROR
      "${CMAKE_CURRENT_FUNCTION} could not add any subdirectories for "
      "project ${PROJECT_NAME}. The canonical subdirectories do not exist")
  endif ()

  # Add supplementary source subdirectories
  if (ARGS_WITH_TESTS_DIR AND ${JCM_PROJECT_PREFIX_NAME}_BUILD_TESTS)
    _jcm_check_add_subdir(subdirs_added FATAL ${add_subdirs_arg} SUBDIR "${JCM_PROJECT_TESTS_DIR}")
  endif ()

  if (ARGS_WITH_DOCS_DIR AND ${JCM_PROJECT_PREFIX_NAME}_BUILD_DOCS)
    _jcm_check_add_subdir(subdirs_added FATAL ${add_subdirs_arg} SUBDIR "${JCM_PROJECT_DOCS_DIR}")
  endif ()

  # Check for accidental entries in omissions option
  if(unused_subdir_omissions)
    message(WARNING "The following subdirectories are omitted based on the targets specified in "
                    "${JCM_PROJECT_PREFIX_NAME}_OMIT_TARGETS, but these subdirectories aren't "
                    "added by the project: ${unused_subdir_omissions}"
    )
  endif()

  # Set result variable
  if (DEFINED ARGS_OUT_VAR)
    set(${ARGS_OUT_VAR} "${subdirs_added}" PARENT_SCOPE)
  endif ()
endfunction()

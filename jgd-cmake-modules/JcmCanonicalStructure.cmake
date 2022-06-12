include_guard()

#
# Canonical project structure, refined for JGD
#
# Refinements:
#
# * from the list of appropriate file names file names, lower snake case is
#   chosen, enforced in JcmFileNaming

include(JcmParseArguments)

set(JCM_LIB_PREFIX "lib")

set(JCM_HEADER_EXTENSION ".hpp")
set(JCM_SOURCE_EXTENSION ".cpp")
set(JCM_TEST_SOURCE_EXTENSION ".test.cpp")
set(JCM_MODULE_EXTENSION ".mpp") # cmake doesn't support modules, but for future
set(JCM_IN_FILE_EXTENSION ".in")

#
# Sets the variable specified by OUT_VAR to the canonical project path for library.
# When COMPONENT is omitted, the output will be the canonical project path for a
# single library of PROJECT_NAME, regardless of if PROJECT_NAME names a library
# or executable. The resulting path is absolute, and will be
# /<JCM_LIB_PREFIX><name>, with respect to PROJECT_SOURCE_DIR, where 'name' is
# the PROJECT_NAME without any lib prefix. Ex.  .../libproj
#
# When COMPONENT is provided, the output will name a library component, considering
# the PROJECT_NAME and the COMPONENT argument. The resulting path is absolute, and
# will be /<PROJECT_NAME>-<COMPONENT>/<PROJECT_NAME>/<COMPONENT>, with respect to the
# PROJECT_SOURCE_DIR. Ex. .../proj-comp/proj/comp
#
# Arguments:
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# path.
#
# COMPONENT: one-value arg; the name of the component for which the path will be
# computed.
#
function(jcm_canonical_lib_subdir)
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "OUT_VAR;COMPONENT"
    REQUIRES_ALL "OUT_VAR"
    ARGUMENTS "${ARGN}")
  if (DEFINED ARGS_COMPONENT)
    string(JOIN "-" comp_dir ${PROJECT_NAME} ${ARGS_COMPONENT})
    set(${ARGS_OUT_VAR} "${PROJECT_SOURCE_DIR}/${comp_dir}/${PROJECT_NAME}/${component}"
      PARENT_SCOPE)
  else ()
    string(REGEX REPLACE "^${JCM_LIB_PREFIX}" "" no_lib "${PROJECT_NAME}")
    set(${ARGS_OUT_VAR} "${PROJECT_SOURCE_DIR}/${JCM_LIB_PREFIX}${no_lib}" PARENT_SCOPE)
  endif ()
endfunction()

#
# Sets the variable specified by OUT_VAR to the canonical project path for an
# executable.
# When COMPONENT is omitted, the output is the canonical project path for a
# single executable of PROJECT_NAME, regardless of if PROJECT_NAME names a
# library or executable. The resulting path is absolute, and will be /<name>,
# with respect to PROJECT_SOURCE_DIR, where 'name' is the PROJECT_NAME without
# any lib prefix. Ex. .../proj
#
# When COMPONENT is provided, the output is the canonical project path for an
# executable component, considering the PROJECT_NAME and the COMPONENT argument,
# regardless of if PROJECT_NAME names a library or executable.  The resulting
# path is absolute, and will be /<name>/<COMPONENT>, with respect to
# PROJECT_SOURCE_DIR, where 'name' is the PROJECT_NAME without any lib prefix.
# Ex. .../proj/comp
#
# Arguments:
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# path.
#
# COMPONENT: one-value arg; the name of the executable component for which the
# path will be computed.
#
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

#
# Sets the variable specified by OUT_VAR to the canonical include directory for
# the TARGET.
#
# The provided targets' SOURCE_DIR, TYPE, and COMPONENT properties will be
# queried to resolve the source tree include directory, which will be one or two
# parent directories of the canonical source directory. This creates the include
# prefix of <PROJECT_NAME>, or <PROJECT_NAME>/<COMPONENT> if the target is a
# component. PROJECT_BINARY_DIR will then be appended to the source include
# directory.
#
# Arguments:
#
# TARGET: one-value arg; the name of the target to resolve the canonical include
# directories for.
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# list.
#
function(jcm_canonical_include_dirs)
  jcm_parse_arguments(ONE_VALUE_KEYWORDS "TARGET;OUT_VAR" REQUIRES_ALL
    "TARGET;OUT_VAR" ARGUMENTS "${ARGN}")

  # Usage guard
  if (NOT TARGET ${ARGS_TARGET})
    message(FATAL_ERROR "${ARGS_TARGET} is not a target and must first be created before calling "
      "${CMAKE_CURRENT_FUNCTION}.")
  endif ()

  # Get the target's properties
  get_target_property(source_dir ${ARGS_TARGET} SOURCE_DIR)
  get_target_property(target_type ${ARGS_TARGET} TYPE)
  get_target_property(component ${ARGS_TARGET} COMPONENT)

  # Helpful macro to check & emit error
  macro(_CHECK_ERR subdir target_type_name)
    if (NOT source_dir MATCHES "^${subdir}")
      message(
        FATAL_ERROR
        "Unable to resolve default include directory for target "
        "${ARGS_TARGET}. The source directory, "
        "${source_dir}, is not within the ${target_type_name}'s canonical "
        "include directory of ${subdir}.")
    endif ()
  endmacro()

  # Set include directory from canonical directories for respective target type
  if (target_type STREQUAL "EXECUTABLE")
    # executable
    jcm_canonical_exec_subdir(OUT_VAR exec_subdir)
    _check_err("${exec_subdir}" "executable")
    set(prefix_parents 1)
    set(include_dir "${exec_subdir}")
  else ()
    if (component)
      # library component
      jcm_canonical_lib_subdir(COMPONENT ${component} OUT_VAR comp_subdir)
      _check_err("${comp_subdir}" "library component")
      set(prefix_parents 2)
      set(include_dir "${comp_subdir}")
    else ()
      # main library
      jcm_canonical_lib_subdir(OUT_VAR lib_subdir)
      _check_err("${comp_subdir}" "library")
      set(prefix_parents 1)
      set(include_dir "${lib_subdir}")
    endif ()
  endif ()

  # Set include dir up the canonical source path to create include prefix
  foreach (i RANGE 1 ${prefix_parents})
    cmake_path(GET include_dir PARENT_PATH include_dir)
  endforeach ()

  # Add appropriate binary dir for generated headers
  set(binary_dirs "${PROJECT_BINARY_DIR}")
  if (component)
    set(binary_dirs "${PROJECT_BINARY_DIR};${PROJECT_BINARY_DIR}/${PROJECT_NAME}-${component}")
  endif ()

  set(${ARGS_OUT_VAR} "${include_dir}" "${binary_dirs}" PARENT_SCOPE)
endfunction()
include_guard()

#
# Canonical project structure, refined for JGD
#
# Refinements:
#
# * from the list of appropriate file names file names, lower snake case is
#   chosen, enforced in JgdFileNaming

include(JgdParseArguments)

set(JGD_LIB_PREFIX "lib")

set(JGD_HEADER_EXTENSION ".hpp")
set(JGD_SOURCE_EXTENSION ".cpp")
set(JGD_TEST_SOURCE_EXTENSION ".test.cpp")
set(JGD_MODULE_EXTENSION ".mpp") # cmake doesn't support modules, but for future
set(JGD_IN_FILE_EXTENSION ".in")

#
# Sets the variable specified by OUT_VAR to the canonical project path for a
# single library of PROJECT_NAME, regardless of if PROJECT_NAME names a library
# or executable. The resulting path is absolute, and will be
# /<JGD_LIB_PREFIX><name>, with respect to PROJECT_SOURCE_DIR, where 'name' is
# the PROJECT_NAME without any lib prefix. Ex.  .../libproj
#
# Arguments:
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# path.
#
function(jgd_canonical_lib_subdir)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR" REQUIRES_ALL "OUT_VAR"
                      ARGUMENTS "${ARGN}")
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_lib "${PROJECT_NAME}")
  set(${ARGS_OUT_VAR}
      "${PROJECT_SOURCE_DIR}/${JGD_LIB_PREFIX}${no_lib}"
      PARENT_SCOPE)
endfunction()

#
# Sets the variable specified by OUT_VAR to the canonical project path for a
# library component, considering the PROJECT_NAME and the COMPONENT argument.
# The resulting path is absolute, and will be
# /<PROJECT_NAME>-<COMPONENT>/<PROJECT_NAME>/<COMPONENT>, with respect to the
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
function(jgd_canonical_lib_component_subdir)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR;COMPONENT" REQUIRES_ALL
                      "OUT_VAR;COMPONENT" ARGUMENTS "${ARGN}")
  string(JOIN "-" comp_dir ${PROJECT_NAME} ${ARGS_COMPONENT})
  set(${ARGS_OUT_VAR}
      "${PROJECT_SOURCE_DIR}/${comp_dir}/${PROJECT_NAME}/${component}"
      PARENT_SCOPE)
endfunction()

#
# Sets the variable specified by OUT_VAR to the canonical project path for a
# single executable of PROJECT_NAME, regardless of if PROJECT_NAME names a
# library or executable. The resulting path is absolute, and will be /<name>,
# with respect to PROJECT_SOURCE_DIR, where 'name' is the PROJECT_NAME without
# any lib prefix. Ex. .../proj
#
# Arguments:
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# path.
#
function(jgd_canonical_exec_subdir)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR" REQUIRES_ALL "OUT_VAR"
                      ARGUMENTS "${ARGN}")
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_lib "${PROJECT_NAME}")
  set(${ARGS_OUT_VAR}
      "${PROJECT_SOURCE_DIR}/${no_lib}"
      PARENT_SCOPE)
endfunction()

#
# Sets the variable specified by OUT_VAR to the canonical project path for an
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
function(jgd_canonical_exec_component_subdir)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "OUT_VAR;COMPONENT" REQUIRES_ALL
                      "OUT_VAR;COMPONENT" ARGUMENTS "${ARGN}")

  jgd_canonical_exec_subdir(OUT_VAR exec_subdir)
  set(exec_comp_subdir "${exec_subdir}/${ARGS_COMPONENT}")
  set(${ARGS_OUT_VAR}
      "${exec_comp_subdir}"
      PARENT_SCOPE)
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
function(jgd_canonical_include_dirs)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "TARGET;OUT_VAR" REQUIRES_ALL
                      "TARGET;OUT_VAR" ARGUMENTS "${ARGN}")

  # Get the target's properties
  get_target_property(source_dir ${ARGS_TARGET} SOURCE_DIR)
  get_target_property(target_type ${ARGS_TARGET} TYPE)
  get_target_property(component ${ARGS_TARGET} COMPONENT)

  # Helpful macro to check & emit error
  macro(_CHECK_ERR subdir target_type_name)
    if(NOT "${source_dir}" MATCHES "^${subdir}")
      message(
        FATAL_ERROR
          "Unable to resolve default include directory for target "
          "${ARGS_TARGET}. The source directory, "
          "${source_dir}, is not within the ${target_type_name}'s canonical "
          "include directory of ${subdir}.")
    endif()
  endmacro()

  # Set include directory from canonical directories for respective target type
  if("${target_type}" STREQUAL "EXECUTABLE")
    # executable
    jgd_canonical_exec_subdir(OUT_VAR exec_subdir)
    _check_err("${exec_subdir}" "executable")
    set(prefix_parents 1)
    set(include_dir "${exec_subdir}")
  else()
    if(component)
      # library component
      jgd_canonical_lib_component_subdir(COMPONENT ${component} OUT_VAR
                                         comp_subdir)
      _check_err("${comp_subdir}" "library component")
      set(prefix_parents 2)
      set(include_dir "${comp_subdir}")
    else()
      # main library
      jgd_canonical_lib_subdir(OUT_VAR lib_subdir)
      _check_err("${comp_subdir}" "library")
      set(prefix_parents 1)
      set(include_dir "${lib_subdir}")
    endif()
  endif()

  # Set include dir up the canonical source path to create include prefix
  foreach(i RANGE 1 ${prefix_parents})
    cmake_path(GET include_dir PARENT_PATH include_dir)
  endforeach()

  # Set result with PROJECT_BINARY_DIR - the root for generated headers
  set(${ARGS_OUT_VAR}
      "${include_dir};${PROJECT_BINARY_DIR}"
      PARENT_SCOPE)
endfunction()

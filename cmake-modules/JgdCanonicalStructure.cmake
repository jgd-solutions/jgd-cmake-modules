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

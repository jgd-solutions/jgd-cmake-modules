include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdCanonicalStructure)

# cmake-lint: disable=C0301
set(JGD_DEFAULT_COMPILE_OPTIONS
    $<$<OR:$<CXX_COMPILER_ID:Clang>,$<CXX_COMPILER_ID:AppleClang>,$<CXX_COMPILER_ID:GNU>>:
    -Wall
    -Wextra
    -Wpedantic
    -Wconversion
    -Wsign-conversion
    -Weffc++>
    $<$<CXX_COMPILER_ID:MSVC>:
    /W4>)

# Both a default target prop and part of canonical project structure
set(JGD_LIB_PREFIX "${JGD_LIB_PREFIX}")

#
# Sets the variable specified by OUT_VAR to the default library output name.
# This name will be <name>[-COMPONENT], where 'name' is PROJECT_NAME with any
# leading JGD_LIB_PREFIX removed. When combined with the target's PREFIX
# property, which should be set to JGD_LIB_PREFIX, the libraries file name on
# disk will be <PREFIX><name>[-COMPONENT].
#
# Arguments:
#
# COMPONENT: one-value arg; the library component that the library output name
# is naming.
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# output name.
#
function(jgd_default_lib_output_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "COMPONENT;OUT_VAR" ARGUMENTS
                      "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})

  set(${ARGS_OUT_VAR}
      "${no_prefix}"
      PARENT_SCOPE)
  if(ARGS_COMPONENT AND (NOT "${ARGS_COMPONENT}" STREQUAL "${PROJECT_NAME}"))
    set(${ARGS_OUT_VAR}
        "${ARGS_OUT_VAR}-${ARGS_COMPONENT}"
        PARENT_SCOPE)
  endif()
endfunction()

#
# Sets the variable specified by OUT_VAR to the default include paths within the
# CMAKE_CURRENT_SOURCE_DIR, following the canonical project structure.  First,
# the canonical subdirectories given by JgdCanonicalStructure are compared as
# prefixes against CMAKE_CURRENT_SOURCE_DIR to find which canonical subdirectory
# the current source directory is/is within. If matched, a resulting path will
# be set such that the include prefix is always <PROJECT_NAME>[/COMPONENT]/,
# plus the nested directories within the matched canonical directory that the
# current directory exists within. Second, the PROJECT_BINARY_DIR is added for
# any generated headers, which should be generated in
# PROJECT_BINARY_DIR/PROJECT_NAME/... . The result can be optionally wrapped in
# a BUILD_INTERFACE generator expression.
#
# Example: if CMAKE_CURRENT_SOURCE_DIR is path .../proj-comp/proj/comp/thing,
# with respect to PROJECT_SOURCE_DIR, where PROJECT_NAME is "proj" and COMPONENT
# is "comp", the source include directory will be proj/proj-comp. Then,
# PROJECT_BINARY_DIR will be added.
#
# Arguments:
#
# COMPONENT: one-value arg; the component in which the current directory exists.
# Used to compute the canonical component subdirectory. A COMPONENT matching
# PROJECT_NAME will be ignored. Optional.
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# path.
#
# BUILD_INTERFACE: option; if set, will cause the resulting path to be wrapped
# in a BUILD_INTERFACE expression. Ex. $<BUILD_INTERFACE:path> Optional - if
# omitted, the raw include directory path will be returned.
#
function(jgd_default_include_dirs)
  jgd_parse_arguments(OPTIONS "BUILD_INTERFACE" ONE_VALUE_KEYWORDS
                      "COMPONENT;OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")

  set(current_dir "${CMAKE_CURRENT_SOURCE_DIR}")
  set(include_dir)
  jgd_canonical_exec_subdir(OUT_VAR exec_subdir)
  jgd_canonical_lib_subdir(OUT_VAR lib_subdir)
  if(ARGS_COMPONENT AND (NOT "${ARGS_COMPONENT}" STREQUAL "${PROJECT_NAME}"))
    jgd_canonical_component_subdir(COMPONENT "${ARGS_COMPONENT}" OUT_VAR
                                   comp_subdir)
  endif()

  # Track which canonical subdir matches current location and the number of
  # parent traversals to create correct include prefix
  if(comp_subdir AND ("${current_dir}" MATCHES "^${comp_subdir}"))
    set(num_parents 2)
    set(include_dir "${comp_subdir}")
  elseif("${current_dir}" MATCHES "^${lib_subdir}")
    set(num_parents 1)
    set(include_dir "${lib_subdir}")
  elseif("${current_dir}" MATCHES "^${exec_subdir}")
    set(num_parents 1)
    set(include_dir "${exec_subdir}")
  else()
    if(comp_subdir)
      set(comp_err_msg " OR ${comp_subdir}")
    endif()
    message(
      FATAL_ERROR
        "Unable to resolve default include directory. The current directory, "
        "${current_dir}, is not within ${exec_subdir} OR ${lib_subdir}"
        "${comp_err_msg}.")
  endif()

  # set include dir up the canonical subdir path to create include prefix
  foreach(i RANGE 1 ${num_parents})
    cmake_path(GET include_dir PARENT_PATH include_dir)
  endforeach()

  set(include_dirs "${include_dir};${PROJECT_BINARY_DIR}")
  if(ARGS_BUILD_INTERFACE)
    set(${ARGS_OUT_VAR}
        "$<BUILD_INTERFACE:${include_dirs}>"
        PARENT_SCOPE)
  else()
    set(${ARGS_OUT_VAR}
        "${include_dirs}"
        PARENT_SCOPE)
  endif()
endfunction()

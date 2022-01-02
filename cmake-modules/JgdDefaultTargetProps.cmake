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
    -Wsign-conversion>
    $<$<CXX_COMPILER_ID:MSVC>:
    /W4>)

#
# Sets the variable specified by OUT_VAR to the default include path for the
# CMAKE_CURRENT_SOURCE_DIR, following the canonical project structure. The
# canonical subdirectories given by JgdCanonicalStructure are compared as
# prefixes against CMAKE_CURRENT_SOURCE_DIR to find which canonical subdirectory
# the current source directory is/is within. If matched, the resulting path will
# be set such that the include prefix is always <project>[/component]/, plus the
# nested directories within the matched canonical directory that the current
# directory exists within. The result can be optionally wrapped in a
# BUILD_INTERFACE generator expression.
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
function(jgd_default_include_dir)
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
  if("${current_dir}" MATCHES "^${exec_subdir}")
    set(num_parents 1)
    set(include_dir "${exec_subdir}")
  elseif("${current_dir}" MATCHES "^${lib_subdir}")
    set(num_parents 1)
    set(include_dir "${lib_subdir}")
  elseif(comp_subdir AND "${current_dir}" MATCHES "^${comp_subdir}")
    set(num_parents 2)
    set(include_dir "${comp_subdir}")
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

  if(ARGS_BUILD_INTERFACE)
    set(${OUT_VAR} "$<BUILD_INTERFACE:${include_dir}>")
  else()
    set(${OUT_VAR} "${include_dir}")
  endif()
endfunction()

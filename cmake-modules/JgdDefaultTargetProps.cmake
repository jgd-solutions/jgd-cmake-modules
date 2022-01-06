include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdCanonicalStructure)
include(JgdGetLibraryComponent)

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

set(JGD_LIB_POSITION_INDEPENDENT_CODE "${BUILD_SHARED_LIBS}")

# Both a default target prop and part of canonical project structure
set(JGD_LIB_PREFIX "${JGD_LIB_PREFIX}")

#
# Sets the variable specified by OUT_VAR to the default library output name for
# the provided LIBRARY.  This name will be <name>[-component], where 'name' is
# PROJECT_NAME with any leading JGD_LIB_PREFIX removed, and 'component' is the
# library component resolved from LIBRARY. When combined with the target's
# PREFIX property, which should be set to JGD_LIB_PREFIX, the libraries file
# name on disk will be <PREFIX><name>[-component].
#
# Arguments:
#
# LIBRARY: one-value arg; the library target name that produces the on-disk
# library of the resulting output name. LIBRARY must have been created by
# JgdGetDefaultLibraryTargetName, or at least follow its semantics.
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# output name.
#
function(jgd_default_library_output_name)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "LIBRARY;OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "LIBRARY;OUT_VAR")

  # Compute library component
  jgd_get_library_component(LIBRARY "${ARGS_LIBRARY}" OUT_VAR component)

  # Construct output name
  string(REGEX REPLACE "^${JGD_LIB_PREFIX}" "" no_prefix ${PROJECT_NAME})
  set(out_name "${no_prefix}")
  if(component)
    string(APPEND out_name "-${component}")
  endif()

  # Set result
  set(${ARGS_OUT_VAR}
      "${out_name}"
      PARENT_SCOPE)
endfunction()

#
# Sets the variable specified by OUT_VAR to the default include paths for the
# provided TARGET. If TARGET was properly created in or within one of the
# canonical subdirectories, provided by JgdCanonicalStructure, the resulting
# path will be set such that the include prefix is always
# <PROJECT_NAME>[/component]/, plus the nested directories within the canonical
# directory that the SOURCE_DIR exists within. Here, 'component' is the resolved
# component from TARGET, if TARGET is a component library. PROJECT_BINARY_DIR is
# also added for any generated headers, which should be generated in
# PROJECT_BINARY_DIR/PROJECT_NAME/... .  The result can be optionally wrapped in
# a BUILD_INTERFACE generator expression.
#
# Example: if TARGET was created in .../proj-comp/proj/comp/thing/, with respect
# to PROJECT_SOURCE_DIR, where PROJECT_NAME is "proj" and the target component
# is "comp", the source include directory will be proj/proj-comp. Then,
# PROJECT_BINARY_DIR will be added.
#
# Arguments:
#
# TARGET: one-value arg; the target to compute include directories for.
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
                      "TARGET;OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "OUT_VAR")

  # Get the target's properties
  get_target_property(source_dir ${ARGS_TARGET} SOURCE_DIR)
  get_target_property(target_type ${ARGS_TARGET} TYPE)

  # Helpful macro to check & emit error
  macro(_CHECK_ERR subdir lib_type)
    if(NOT "${source_dir}" MATCHES "^${subdir}")
      message(
        FATAL_ERROR
          "Unable to resolve default include directory. The source directory, "
          "${source_dir}, is not within the expected ${lib_type} subdirectory of "
          "${subdir}.")
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
    jgd_get_library_component(LIBRARY "${ARGS_TARGET}" OUT_VAR component)
    message(STATUS "libname: ${ARGS_TARGET} component: ${component}")
    if(component)
      # library component
      jgd_canonical_component_subdir(COMPONENT "${ARGS_COMPONENT}" OUT_VAR
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

  # Set include dir up the canonical subdir path to create include prefix
  foreach(i RANGE 1 ${prefix_parents})
    cmake_path(GET include_dir PARENT_PATH include_dir)
  endforeach()

  # Set result with binary directory
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

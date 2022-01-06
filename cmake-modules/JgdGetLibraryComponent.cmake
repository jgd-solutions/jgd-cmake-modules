include_guard()

include(JgdParseArguments)
include(JgdValidateArguments)
include(JgdCanonicalStructure)

#
# Resolves the component of the given library target provided by the LIBRARY
# argument. The provided LIBRARY must have been created by
# JgdGetDefaultLibraryTargetName or at least follow its semantics for the
# component to be correctly resolved. If the given LIBRARY doesn't constitute a
# component, including if the library is only part of the project's parent
# component, the result will be an empty string.
#
# Arguments:
#
# LIBRARY: one-value arg; the library target name for which the component will
# be resolved.
#
# OUT_VAR: one-value arg; the name of the variable that will store the resulting
# component.
#
function(jgd_get_library_component)
  jgd_parse_arguments(ONE_VALUE_KEYWORDS "LIBRARY;OUT_VAR" ARGUMENTS "${ARGN}")
  jgd_validate_arguments(KEYWORDS "LIBRARY;OUT_VAR")

  set(component)

  # Resolve component from library target name
  set(exe_comp_lib_prefix "^${JGD_LIB_PREFIX}${PROJECT_NAME}-")
  if("${ARGS_LIBRARY}" MATCHES "^${exe_comp_lib_prefix}")
    # libraries that start with the executable component library prefix are
    # followed by their component
    string(REPLACE "${exe_comp_lib_prefix}" "" component "${ARGS_LIBRARY}")

  elseif(NOT "${ARGS_LIBRARY}" MATCHES "^${JGD_LIB_PREFIX}")
    # libraries that don't start with JGD_LIB_PREFIX are component libraries of
    # the same name
    set(component "${ARGS_LIBRARY}")
  endif()

  # Set result
  set(${ARGS_OUT_VAR}
      "${component}"
      PARENT_SCOPE)
endfunction()

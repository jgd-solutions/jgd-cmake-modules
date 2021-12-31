include(JgdParseArguments)
include(JgdValidateArguments)

#
# Simple wrapper around CMake's find_package(), which is used for the common
# use-case of finding conan packages. When conan is used with the
# cmake_find_package_multi generator, config-files for the packages will be
# generated in the project's build directory. This function will search for a
# config-file package with PACKAGE_NAME and components COMPONENTS in the
# project's build directory (CMAKE_CURRENT_BINARY_DIR), or the paths specified
# in PATHS, if provided. NO_DEFAULT_PATH is provided to the inner find_package()
# so no other paths other than these are searched for the package. This avoids
# finding system packages.
#
# Arguments:
#
# OPTIONAL: option; the package is not required. Failing to find the package
# will not result in an error.
#
# PACKAGE_NAME: one value arg; the package name to find
#
# COMPONENTS: multi value arg; the specific components of PACKAGE_NAME to find.
# If not provided, all components that are found in the config-file will be
# available.
#
# PATHS: multi value arg; the paths to search for config-files for PACKAGE_NAME.
# When omitted, CMAKE_CURRENT_BINARY_DIR will be used.
#
function(jgd_find_conan_package)
  jgd_parse_arguments(
    OPTIONS
    "OPTIONAL"
    ONE_VALUE_KEYWORDS
    "PACKAGE_NAME"
    MULTI_VALUE_KEYWORDS
    "COMPONENTS;PATHS"
    ARGUMENTS
    "${ARGN}")

  jgd_validate_arguments(KEYWORDS "PACKAGE_NAME")

  set(req "REQUIRED")
  if(ARGS_OPTIONAL)
    set(req_msg "")
  endif()

  set(comps_arg "")
  if(ARGS_COMPONENTS)
    set(comps_arg "COMPONENTS ${ARGS_COMPONENTS}")
  endif()

  set(search_paths "${CMAKE_CURRENT_BINARY_DIR}")
  if(ARGS_PATHS)
    set(search_paths "${ARGS_PATHS}")
  endif()

  find_package(
    "${ARGS_PACKAGE_NAME}"
    CONFIG
    ${req}
    NO_DEFAULT_PATH
    ${comps_arg}
    PATHS
    ${search_paths})
endfunction()

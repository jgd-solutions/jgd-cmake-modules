# The goal is to have in-source versions of the test projects to consume via add_subdirectory().
# Using permanent sym-links from the contrib/ source directory to the above projects break on windows.
# Instead, create the source directories in the binary tree, and add them via add_subdirectory()
# by providing an explicit binary directory for them. On Windows, the projects will be created by
# copying the directories, while other systems will just use sym-links, again.

set(contrib_source "${PROJECT_SOURCE_DIR}/../${package_name}")
set(contrib_destination "${CMAKE_CURRENT_BINARY_DIR}/src")
set(contrib_bin_dir "${CMAKE_CURRENT_BINARY_DIR}")

if (CMAKE_SYSTEM_NAME STREQUAL "Windows")
  file(COPY "${contrib_source}" DESTINATION "${contrib_destination}" FOLLOW_SYMLINK_CHAIN)
else ()
  file(MAKE_DIRECTORY "${contrib_destination}")
  file(CREATE_LINK "${contrib_source}" "${contrib_destination}/${package_name}" SYMBOLIC)
endif ()

add_subdirectory("${contrib_destination}/${package_name}" "${contrib_bin_dir}/${package_name}")
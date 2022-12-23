# The goal is to have in-source versions of the test projects to consume via add_subdirectory().
# Using permanent symlinks from the contrib/ source dir to the above projects break on Windows.
# Instead, create the source directories in the binary tree, and add them via add_subdirectory()
# by providing an explicit binary directory for them. The projects will be created by copying the
# directories when symlinks aren't available, while other systems will just use symlinks, again.
# Symlinks within the directories will still exist.

set(contrib_source "${PROJECT_SOURCE_DIR}/../${package_name}")
set(contrib_destination "${CMAKE_CURRENT_BINARY_DIR}/src")
set(contrib_bin_dir "${CMAKE_CURRENT_BINARY_DIR}")

include(JcmSymlinks)
jcm_check_symlinks_available(SUCCESS_CACHE OUT_VAR symlinks_available)

if(symlinks_available)
  file(MAKE_DIRECTORY "${contrib_destination}")
  file(CREATE_LINK "${contrib_source}" "${contrib_destination}/${package_name}" SYMBOLIC)
else()
  file(COPY "${contrib_source}" DESTINATION "${contrib_destination}" FOLLOW_SYMLINK_CHAIN)
endif()

add_subdirectory("${contrib_destination}/${package_name}" "${contrib_bin_dir}/${package_name}")

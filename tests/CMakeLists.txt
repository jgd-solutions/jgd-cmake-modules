include("${CMAKE_CURRENT_SOURCE_DIR}/testingFunctions.cmake")

# Install jgd-cmake-modules to test its installation and for following test projects to find
add_test(
  NAME ${PROJECT_NAME}-install
  COMMAND
  "${CMAKE_COMMAND}"
  --install "${PROJECT_BINARY_DIR}"
  --verbose
  --prefix "${jgd-cmake-modules_ROOT}"
)


# == single-exec ==

_build_and_ctest("single-exec"
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check
  BUILD_OPTIONS -DSINGLE_EXEC_BUILD_TESTS=ON)

_build_and_ctest("single-exec"
  BUILD_OPTIONS -DSINGLE_EXEC_BUILD_TESTS=ON)


_install_project("single-exec")
_find_use_project("single-exec")
_add_use_project("single-exec")


# == many-exec ==

_build_and_ctest("many-exec"
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check
  BUILD_OPTIONS
  -DMANY_EXEC_BUILD_FORMATTER=ON # reset to ON from last test
  -DMANY_EXEC_BUILD_TESTS=ON)

_build_and_ctest("many-exec"
  BUILD_OPTIONS -DMANY_EXEC_BUILD_TESTS=ON)

_install_project("many-exec")
_find_use_project("many-exec")
_find_use_project("many-exec" COMPONENTS formatter)
_find_use_project("many-exec" COMPONENTS compiler formatter)
_add_use_project("many-exec")

_build_and_ctest("many-exec"
  NAME_SUFFIX -omit-formatter
  BUILD_OPTIONS
  -DMANY_EXEC_BUILD_TESTS=OFF
  -DMANY_EXEC_BUILD_FORMATTER=OFF)


# == libsingle ==

_build_and_ctest("libsingle"
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON)

_build_and_ctest("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON)

_build_and_ctest("libsingle"
  NAME_SUFFIX -shared
  BUILD_OPTIONS
  -DLIBSINGLE_BUILD_TESTS=ON
  -DLIBSINGLE_BUILD_SHARED_LIBS=ON)

_build_and_ctest("libsingle"
  NAME_SUFFIX -docs
  BUILD_TARGET doxygen-docs
  BUILD_OPTIONS
  -DLIBSINGLE_BUILD_TESTS=ON
  -DLIBSINGLE_BUILD_DOCS=ON)

_install_project("libsingle")
_find_use_project("libsingle")
_add_use_project("libsingle")


# == libcomponents ==

_build_and_ctest("libcomponents"
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check
  BUILD_OPTIONS
  -DLIBCOMPONENTS_BUILD_EXTRA=ON # reset to ON from last test
  -DLIBCOMPONENTS_BUILD_TESTS=ON)

_build_and_ctest("libcomponents"
  BUILD_OPTIONS -DLIBCOMPONENTS_BUILD_TESTS=ON)

_build_and_ctest("libcomponents"
  NAME_SUFFIX -shared
  BUILD_OPTIONS
  -DLIBCOMPONENTS_BUILD_TESTS=ON
  -DLIBCOMPONENTS_CORE_BUILD_SHARED=ON)

_install_project("libcomponents")
_find_use_project("libcomponents")
_find_use_project("libcomponents" COMPONENTS core)
_find_use_project("libcomponents" COMPONENTS extra)
_find_use_project("libcomponents" COMPONENTS core extra)
_add_use_project("libcomponents")

_build_and_ctest("libcomponents"
  NAME_SUFFIX -omit-extra
  BUILD_OPTIONS
  -DLIBCOMPONENTS_BUILD_TESTS=OFF
  -DLIBCOMPONENTS_BUILD_EXTRA=OFF)


# == libheaders ==

_build_and_ctest("libheaders"
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check
  BUILD_OPTIONS -DLIBHEADERS_BUILD_TESTS=ON)

_build_and_ctest("libheaders"
  BUILD_OPTIONS -DLIBHEADERS_BUILD_TESTS=ON)

_install_project("libheaders")
_find_use_project("libheaders")
_add_use_project("libheaders")

_file_exists("libheaders" -license-exists
  "${libheaders_ROOT}/share/doc/libheaders-0.0.0/LICENSE.md")


# == libcstr ==

_build_and_ctest("libcstr"
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check
  BUILD_OPTIONS -DLIBCSTR_BUILD_TESTS=ON)

_build_and_ctest("libcstr"
  BUILD_OPTIONS -DLIBCSTR_BUILD_TESTS=ON)

_install_project("libcstr")
_find_use_project("libcstr")
_add_use_project("libcstr")

set(licenses_dir "${libcstr_ROOT}/share/doc/libcstr-0.0.0/licenses")
_file_exists("libcstr" -license1-exists "${licenses_dir}/license1.txt")
_file_exists("libcstr" -license2-exists "${licenses_dir}/license2.txt")
include("${CMAKE_CURRENT_SOURCE_DIR}/testingFunctions.cmake")

# First, check for issues with symlinks so tests don't mysteriously fail on Windows
jcm_check_symlinks_cloned(
  PATHS
  "libcomponents/.clang-format" "libcstr/.clang-format" "libheaders/.clang-format"
  "libsingle/.clang-format" "many-exec/.clang-format" "single-exec/.clang-format"
  OUT_BROKEN_SYMLINK broken_symlink
  OUT_ERROR_MESSAGE symlink_message)

if (broken_symlink)
  message(WARNING "Project ${PROJECT_NAME} will not create any clang-format tests due to the "
    "following error:\n" ${symlink_message})
endif ()


# Install jgd-cmake-modules to test its installation and for following test projects to find
add_test(
  NAME ${PROJECT_NAME}-install
  COMMAND
  "${CMAKE_COMMAND}"
  --install "${PROJECT_BINARY_DIR}"
  --verbose
  --prefix "${jgd-cmake-modules_ROOT}")


# == single-exec ==

if (NOT broken_symlink)
  _build_and_ctest("single-exec"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check
    BUILD_OPTIONS -DSINGLE_EXEC_BUILD_TESTS=ON
    DEPENDS ${PROJECT_NAME}-install)
endif ()

_build_and_ctest("single-exec"
  BUILD_OPTIONS -DSINGLE_EXEC_BUILD_TESTS=ON
  DEPENDS single-exec-format)

_install_project("single-exec" DEPENDS single-exec)
_find_use_project("single-exec" OUT_TEST_NAME single-exec_find DEPENDS single-exec-install)
_add_use_project("single-exec")


# == many-exec ==

if (NOT broken_symlink)
  _build_and_ctest("many-exec"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check
    BUILD_OPTIONS -DMANY_EXEC_BUILD_TESTS=ON
    DEPENDS ${PROJECT_NAME}-install)
endif ()

_build_and_ctest("many-exec"
  NAME_SUFFIX -omit-formatter
  BUILD_OPTIONS
  -DMANY_EXEC_BUILD_TESTS=OFF
  -DMANY_EXEC_BUILD_FORMATTER=OFF
  DEPENDS many-exec-format)

_build_and_ctest("many-exec"
  BUILD_OPTIONS
  -DMANY_EXEC_BUILD_TESTS=ON
  -DMANY_EXEC_BUILD_FORMATTER=ON
  DEPENDS many-exec-omit-formatter)

_install_project("many-exec" DEPENDS many-exec)
_find_use_project("many-exec" DEPENDS many-exec-install)
_find_use_project("many-exec" COMPONENTS formatter DEPENDS many-exec-install)
_find_use_project("many-exec" COMPONENTS compiler formatter DEPENDS many-exec-install)
_add_use_project("many-exec")


# == libsingle ==

if (NOT broken_symlink)
  _build_and_ctest("libsingle"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check
    BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON
    DEPENDS ${PROJECT_NAME}-install)
endif ()

_build_and_ctest("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON
  DEPENDS libsingle-format)

_build_and_ctest("libsingle"
  NAME_SUFFIX -shared
  BUILD_OPTIONS
  -DLIBSINGLE_BUILD_TESTS=ON
  -DLIBSINGLE_BUILD_SHARED_LIBS=ON
  DEPENDS libsingle)

_build_and_ctest("libsingle"
  NAME_SUFFIX -docs
  BUILD_TARGET doxygen-docs
  BUILD_OPTIONS
  -DLIBSINGLE_BUILD_TESTS=ON
  -DLIBSINGLE_BUILD_DOCS=ON
  DEPENDS libsingle-shared)

_install_project("libsingle" DEPENDS libsingle-docs)
_find_use_project("libsingle" OUT_TEST_NAME libsingle_find DEPENDS libsingle-install)
_add_use_project("libsingle")


# == libcomponents ==

if (NOT broken_symlink)
  _build_and_ctest("libcomponents"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check
    BUILD_OPTIONS -DLIBCOMPONENTS_BUILD_TESTS=ON
    DEPENDS ${PROJECT_NAME}-install)
endif ()

_build_and_ctest("libcomponents"
  NAME_SUFFIX -omit-extra
  BUILD_OPTIONS
  -DLIBCOMPONENTS_BUILD_TESTS=OFF
  -DLIBCOMPONENTS_BUILD_EXTRA=OFF
  DEPENDS libcomponents-format)

_build_and_ctest("libcomponents"
  BUILD_OPTIONS
  -DLIBCOMPONENTS_BUILD_TESTS=ON
  -DLIBCOMPONENTS_BUILD_EXTRA=ON
  DEPENDS libcomponents-omit-extra)

_build_and_ctest("libcomponents"
  NAME_SUFFIX -shared
  BUILD_OPTIONS
  -DLIBCOMPONENTS_BUILD_TESTS=ON
  -DLIBCOMPONENTS_CORE_BUILD_SHARED=ON
  DEPENDS libcomponents)

_install_project("libcomponents" DEPENDS libcomponents-shared)
_find_use_project("libcomponents" DEPENDS libcomponents-install)
_find_use_project("libcomponents" COMPONENTS core DEPENDS libcomponents-install)
_find_use_project("libcomponents" COMPONENTS extra DEPENDS libcomponents-install)
_find_use_project("libcomponents" COMPONENTS core extra DEPENDS libcomponents-install)
_add_use_project("libcomponents")


# == libheaders ==

if (NOT broken_symlink)
  _build_and_ctest("libheaders"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check
    BUILD_OPTIONS -DLIBHEADERS_BUILD_TESTS=ON
    DEPENDS ${PROJECT_NAME}-install)
endif ()

_build_and_ctest("libheaders"
  BUILD_OPTIONS -DLIBHEADERS_BUILD_TESTS=ON
  DEPENDS libheaders-format)

_install_project("libheaders" DEPENDS libheaders)
_find_use_project("libheaders" DEPENDS libheaders-install)
_add_use_project("libheaders")

_file_exists("libheaders" -license-exists
  "${libheaders_ROOT}/share/doc/libheaders-0.0.0/LICENSE.md"
  DEPENDS libheaders-install)


# == libcstr ==

if (NOT broken_symlink)
  _build_and_ctest("libcstr"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check
    BUILD_OPTIONS -DLIBCSTR_BUILD_TESTS=ON
    DEPENDS ${PROJECT_NAME}-install)
endif ()

_build_and_ctest("libcstr"
  BUILD_OPTIONS -DLIBCSTR_BUILD_TESTS=ON
  DEPENDS libcstr-format)

_install_project("libcstr" DEPENDS libcstr)
_find_use_project("libcstr" DEPENDS libcstr-install)
_add_use_project("libcstr")

set(licenses_dir "${libcstr_ROOT}/share/doc/libcstr-0.0.0/licenses")
_file_exists("libcstr" -license1-exists "${licenses_dir}/license1.txt" DEPENDS libcstr-install)
_file_exists("libcstr" -license2-exists "${licenses_dir}/license2.txt" DEPENDS libcstr-install)

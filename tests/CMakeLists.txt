include("${CMAKE_CURRENT_SOURCE_DIR}/testingFunctions.cmake")

# First, check for issues with symlinks so tests don't mysteriously fail on Windows
file(GLOB_RECURSE format_files RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}" "*/.clang-format")
jcm_check_symlinks_cloned(
  PATHS "${format_files}"
  OUT_BROKEN_SYMLINK broken_symlink
  OUT_ERROR_MESSAGE symlink_message)

if(broken_symlink)
  message(WARNING "Project ${PROJECT_NAME} will not create any clang-format tests due to the "
    "following error:\n" ${symlink_message})
endif()


# Install jgd-cmake-modules to test its installation and for following test projects to find
add_test(
  NAME ${PROJECT_NAME}-install
  COMMAND
  "${CMAKE_COMMAND}"
  --install "${PROJECT_BINARY_DIR}"
  --prefix "${jgd-cmake-modules_ROOT}"
  --config $<CONFIG>
  --verbose)

set_tests_properties(${PROJECT_NAME}-install PROPERTIES
  FIXTURES_SETUP ${PROJECT_NAME}-install-fixture)

# == single-exec ==

if(NOT broken_symlink)
  _build_and_ctest("single-exec"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check)
endif()

_build_and_ctest("single-exec"
  NAME_SUFFIX -message-target
  BUILD_TARGET single-exec_message-target)

_build_and_ctest("single-exec"
  FIXTURES_SETUP "single-exec-fixture"
  DEPENDS single-exec-format)

_install_project("single-exec" FIXTURES_REQUIRED single-exec-fixture)
_find_use_project("single-exec")
_add_use_project("single-exec")


# == many-exec ==

if(NOT broken_symlink)
  _build_and_ctest("many-exec"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check)
endif()

_build_and_ctest("many-exec"
  NAME_SUFFIX -omit-formatter
  BUILD_OPTIONS
  -DMANY_EXEC_BUILD_TESTS=OFF
  -DMANY_EXEC_BUILD_FORMATTER=OFF
  DEPENDS many-exec-format)

_build_and_ctest("many-exec"
  FIXTURES_SETUP "many-exec-fixture"
  BUILD_OPTIONS
  -DMANY_EXEC_BUILD_TESTS=ON
  -DMANY_EXEC_BUILD_FORMATTER=ON
  DEPENDS many-exec-omit-formatter)

_install_project("many-exec" FIXTURES_REQUIRED many-exec-fixture)
_find_use_project("many-exec")
_find_use_project("many-exec" COMPONENTS formatter)
_find_use_project("many-exec" COMPONENTS compiler formatter)
_add_use_project("many-exec")


# == libsingle ==

if(NOT broken_symlink)
  _build_and_ctest("libsingle"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check)
endif()

_build_and_ctest("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_BUILD_TESTS=ON
  DEPENDS libsingle-format)

_build_and_ctest("libsingle"
  NAME_SUFFIX -docs
  BUILD_TARGET doxygen-docs
  BUILD_OPTIONS
  -DLIBSINGLE_BUILD_DOCS=ON
  DEPENDS libsingleshare)

_build_and_ctest("libsingle"
  NAME_SUFFIX -shared
  FIXTURES_SETUP "libsingle-fixture"
  BUILD_OPTIONS
  -DLIBSINGLE_BUILD_TESTS=ON
  -DLIBSINGLE_BUILD_SHARED_LIBS=ON
  DEPENDS libsingle-docs)

_install_project("libsingle" FIXTURES_REQUIRED libsingle-fixture)
_find_use_project("libsingle")
_add_use_project("libsingle")

set(licenses_dir "${test_install_dir}/share/doc/libsingle-0.0.0")
_file_exists("libsingle" -license-exists "${licenses_dir}/LICENSE.md")


# == libcomponents ==

if(NOT broken_symlink)
  _build_and_ctest("libcomponents"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check)
endif()

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
  FIXTURES_SETUP "libcomponents-fixture"
  BUILD_OPTIONS
  -DLIBCOMPONENTS_BUILD_TESTS=ON
  -DLIBCOMPONENTS_CORE_BUILD_SHARED=ON
  DEPENDS libcomponents)

_install_project("libcomponents" FIXTURES_REQUIRED libcomponents-fixture)
_find_use_project("libcomponents")
_find_use_project("libcomponents" COMPONENTS core)
_find_use_project("libcomponents" COMPONENTS extra)
_find_use_project("libcomponents" COMPONENTS core extra)
_add_use_project("libcomponents")


# == libheaders ==

if(NOT broken_symlink)
  _build_and_ctest("libheaders"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check)
endif()

_build_and_ctest("libheaders"
  FIXTURES_SETUP "libheaders-fixture"
  BUILD_OPTIONS -DLIBHEADERS_BUILD_TESTS=ON
  DEPENDS libheaders-format)

_install_project("libheaders" FIXTURES_REQUIRED libheaders-fixture)
_find_use_project("libheaders")
_add_use_project("libheaders")

_file_exists("libheaders" -license-exists
  "${test_install_dir}/share/doc/libheaders-0.0.0/LICENSE.md")


# == libcstr ==

if(NOT broken_symlink)
  _build_and_ctest("libcstr"
    NAME_SUFFIX -format
    BUILD_TARGET clang-format-check)
endif()

_build_and_ctest("libcstr"
  FIXTURES_SETUP "libcstr-fixture"
  BUILD_OPTIONS -DLIBCSTR_BUILD_TESTS=ON
  DEPENDS libcstr-format)

_install_project("libcstr" FIXTURES_REQUIRED libcstr-fixture)
_find_use_project("libcstr")
_add_use_project("libcstr")

set(licenses_dir "${test_install_dir}/share/doc/libcstr-0.0.0/licenses")
_file_exists("libcstr" -license1-exists "${licenses_dir}/license1.txt")
_file_exists("libcstr" -license2-exists "${licenses_dir}/license2.txt")

set_tests_properties("libcstr-license1-exists" "libcstr-license2-exists"
  PROPERTIES FIXTURES_REQUIRED libcstr-install-fixture)

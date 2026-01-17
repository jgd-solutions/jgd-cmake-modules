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

  set(disable_format_tests "DISABLED")
else()
  unset(disable_format_tests)
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

_build_and_ctest("single-exec"
  ${disable_format_tests}
  OUT_TEST_NAME single-exec-format-test
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)
ignore_clang_format_violations(${single-exec-format-test})


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

_build_and_ctest("many-exec"
  ${disable_format_tests}
  OUT_TEST_NAME many-exec-format-test
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)
ignore_clang_format_violations(${many-exec-format-test})

_build_and_ctest("many-exec"
  NAME_SUFFIX -omit-formatter
  BUILD_OPTIONS
  -DMANY_EXEC_ENABLE_TESTS=OFF
  -DMANY_EXEC_ENABLE_FORMATTER=OFF
  DEPENDS many-exec-format)

_build_and_ctest("many-exec"
  FIXTURES_SETUP "many-exec-fixture"
  BUILD_OPTIONS
  -DMANY_EXEC_ENABLE_TESTS=ON
  -DMANY_EXEC_ENABLE_FORMATTER=ON
  DEPENDS many-exec-omit-formatter)

_install_project("many-exec" FIXTURES_REQUIRED many-exec-fixture)
_find_use_project("many-exec")
_find_use_project("many-exec" COMPONENTS formatter)
_find_use_project("many-exec" COMPONENTS compiler formatter)
_add_use_project("many-exec")


# == libsingle ==

_build_and_ctest("libsingle"
  ${disable_format_tests}
  OUT_TEST_NAME libsingle-format-test
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)
ignore_clang_format_violations(${libsingle-format-test})

_build_and_ctest("libsingle"
  BUILD_OPTIONS -DLIBSINGLE_ENABLE_TESTS=ON
  DEPENDS libsingle-format)

_build_and_ctest("libsingle"
  NAME_SUFFIX -docs
  BUILD_TARGET doxygen-docs
  BUILD_OPTIONS
  -DLIBSINGLE_ENABLE_DOCS=ON
  DEPENDS libsingleshare)

_build_and_ctest("libsingle"
  NAME_SUFFIX -shared
  FIXTURES_SETUP "libsingle-fixture"
  BUILD_OPTIONS
  -DLIBSINGLE_ENABLE_TESTS=ON
  -DLIBSINGLE_BUILD_SHARED_LIBS=ON
  DEPENDS libsingle-docs)

_install_project("libsingle" FIXTURES_REQUIRED libsingle-fixture)
_find_use_project("libsingle")
_add_use_project("libsingle")

set(licenses_dir "${test_install_dir}/share/doc/libsingle-0.0.0")
_file_exists("libsingle" -license-exists "${licenses_dir}/LICENSE.md")


# == libcomponents ==

_build_and_ctest("libcomponents"
  ${disable_format_tests}
  OUT_TEST_NAME libcomponents-format-test
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)
ignore_clang_format_violations(${libcomponents-format-test})

_build_and_ctest("libcomponents"
  NAME_SUFFIX -omit-extra
  BUILD_OPTIONS
  -DLIBCOMPONENTS_ENABLE_TESTS=OFF
  -DLIBCOMPONENTS_ENABLE_EXTRA=OFF
  DEPENDS libcomponents-format)

_build_and_ctest("libcomponents"
  BUILD_OPTIONS
  -DLIBCOMPONENTS_ENABLE_TESTS=ON
  -DLIBCOMPONENTS_ENABLE_EXTRA=ON
  DEPENDS libcomponents-omit-extra)

_build_and_ctest("libcomponents"
  NAME_SUFFIX -shared
  FIXTURES_SETUP "libcomponents-fixture"
  BUILD_OPTIONS
  -DLIBCOMPONENTS_ENABLE_TESTS=ON
  -DLIBCOMPONENTS_CORE_BUILD_SHARED=ON
  DEPENDS libcomponents)

_install_project("libcomponents" FIXTURES_REQUIRED libcomponents-fixture)
_find_use_project("libcomponents")
_find_use_project("libcomponents" COMPONENTS core)
_find_use_project("libcomponents" COMPONENTS extra)
_find_use_project("libcomponents" COMPONENTS core extra)
_add_use_project("libcomponents")


# == libheaders ==

_build_and_ctest("libheaders"
  ${disable_format_tests}
  OUT_TEST_NAME libheaders-format-test
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)
ignore_clang_format_violations(${libheaders-format-test})

_build_and_ctest("libheaders"
  FIXTURES_SETUP "libheaders-fixture"
  BUILD_OPTIONS -DLIBHEADERS_ENABLE_TESTS=ON
  DEPENDS libheaders-format)

_install_project("libheaders" FIXTURES_REQUIRED libheaders-fixture)
_find_use_project("libheaders")
_add_use_project("libheaders")

_file_exists("libheaders" -license-exists
  "${test_install_dir}/share/doc/libheaders-0.0.0/LICENSE.md")


# == libcstr ==

_build_and_ctest("libcstr"
  ${disable_format_tests}
  OUT_TEST_NAME libcstr-format-test
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)
ignore_clang_format_violations(${libcstr-format-test})

_build_and_ctest("libcstr"
  FIXTURES_SETUP "libcstr-fixture"
  BUILD_OPTIONS -DLIBCSTR_ENABLE_TESTS=ON
  DEPENDS libcstr-format)

_install_project("libcstr" FIXTURES_REQUIRED libcstr-fixture)
_find_use_project("libcstr")
_add_use_project("libcstr")

set(licenses_dir "${test_install_dir}/share/doc/libcstr-0.0.0/licenses")
_file_exists("libcstr" -license1-exists "${licenses_dir}/license1.txt")
_file_exists("libcstr" -license2-exists "${licenses_dir}/license2.txt")

set_tests_properties("libcstr-license1-exists" "libcstr-license2-exists"
  PROPERTIES FIXTURES_REQUIRED libcstr-install-fixture)

# == daemon ==

_build_and_ctest("daemon"
  ${disable_format_tests}
  OUT_TEST_NAME daemon-format-test
  NAME_SUFFIX -format
  BUILD_TARGET clang-format-check)
ignore_clang_format_violations(${daemon-format-test})

_build_and_ctest("daemon"
  FIXTURES_SETUP "daemon-fixture"
  DEPENDS daemon-format)

_install_project("daemon" FIXTURES_REQUIRED daemon-fixture)
_find_use_project("daemon" COMPONENTS libdaemon)
_add_use_project("daemon")

set(cmake_install_dir "${test_install_dir}/share/daemon-0.0.0")
_file_exists("daemon" -project-config-exists "${cmake_install_dir}/daemon-config.cmake")
_file_exists("daemon" -project-targets-exists "${cmake_install_dir}/daemon-targets.cmake")
_file_exists("daemon" -lib-config-exists "${cmake_install_dir}/daemon-libdaemon-config.cmake")
_file_exists("daemon" -lib-targets-exists "${cmake_install_dir}/daemon-libdaemon-targets.cmake")

set_tests_properties(
  "daemon-project-config-exists" "daemon-project-targets-exists"
  "daemon-lib-config-exists" "daemon-lib-config-exists"
  PROPERTIES FIXTURES_REQUIRED daemon-install-fixture)

# == independent tests ==

# test that disabled component dependencies are automatically enabled when they're depended upon by
# other enabled components
set(JCM_ENABLE_EXTRA ON)
jcm_add_component_options(
  REQUIRED_COMPONENTS "core"
  OPTIONAL_COMPONENTS "io" "extra"
  DEFAULT_OFF_COMPONENTS "extra"
  OUT_COMPONENTS enabled_components
  MISSING_DEPENDENCY_ACTION "ENABLE"
  COMPONENT_DEPENDENCIES_JSON [[
    {
      "extra": [ "io", "core" ],
      "io": []
    }
  ]])
if(NOT JCM_ENABLE_IO)
  message(FATAL_ERROR "jcm_add_component_options failed to enable missing dependency")
endif()

unset(CACHE{JCM_ENABLE_IO})
unset(CACHE{JCM_ENABLE_EXTRA})
cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CANCEL_CALL id_JCM_ENABLE_IO)
cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CANCEL_CALL id_JCM_ENABLE_EXTRA)


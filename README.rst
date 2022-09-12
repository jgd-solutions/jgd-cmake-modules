jgd-cmake-modules
=================

A set of CMake modules to easily and consistently develop proper CMake based projects.
For a short overview of the project, see `Overview <docs/overview>`_.

Sample
------

.. code-block:: cmake
  :caption: libsample/CMakeLists.txt

  cmake_minimum_required(VERSION 3.24)
  project(libsample VERSION 4.2.0)

  find_package(jgd-cmake-modules CONFIG REQUIRED)

  include(JcmAllModules)
  jcm_setup_project()
  jcm_source_subdirectories(ADD_SUBDIRS WITH_TESTS_DIR WITH_DOCS_DIR)
  jcm_configure_config_header_file()
  jcm_create_clang_format_targets(TARGETS libsample::libsample)
  jcm_create_doxygen_target(README_MAIN_PAGE TARGETS libsample::libsample)
  jcm_install_config_file_package(CONFIGURE_PACKAGE_CONFIG_FILES TARGETS libsample::libsample)

.. code-block:: cmake
  :caption: libsample/libsample/CMakeLists.txt

  jcm_add_library(
    PUBLIC_HEADERS widget.hpp factory.hpp
    SOURCES widget.cpp factory.cpp
  )


Using jgd-cmake-modules
-----------------------

1. Acquire the project
~~~~~~~~~~~~~~~~~~~~~~

**Option 1:** From Source

  Clone source code and enter the project root

  .. code-block:: bash

    git clone https://gitlab.com/jgd-solutions/jgd-cmake-modules.git
    cd jgd-cmake-modules

  Configure, build, and install

  .. code-block:: bash

    cmake -B build -G Ninja
    cmake --build build
    cmake --install build

**Option 2:** From `vcpkg <https://vcpkg.io/en/index.html>`_

  Add *jgd-cmake-modules* as a project dependency in `vcpkg.json`

  .. code-block:: json

    "dependencies": [
      "jgd-cmake-modules"
    ]

  Add `vcpkg-registry <https://gitlab.com/jgd-solutions/vcpkg-registry>`_ as a registry in your
  `vcpkg-configurations.json`

  .. code-block:: json

    {
      "registries": [
        {
          "kind": "git",
          "baseline": "<desired-vcpkg-registry-ref>",
          "repository": "git@gitlab.com:jgd-solutions/vcpkg-registry.git",
          "packages": [
            "jgd-cmake-modules"
          ]
        }
      ]
    }

2. Locate jgd-cmake-modules
~~~~~~~~~~~~~~~~~~~~~~~~~~~

Find *jgd-cmake-modules* as an external package in your top-level *CMakeLists.txt*

.. code-block:: cmake

  find_package(jgd-cmake-modules CONFIG REQUIRED)

3. Include and Use Modules
~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  include(JcmClangFormat)
  jcm_create_clang_format_targets(TARGETS libexample::libexample)

Examples
--------

This project uses its own modules, and acts as its own example!

Additionally, the `tests/` directory has sample projects that use *jgd-cmake-modules*. These projects are
configured and built as part of *jgd-cmake-modules*'s automated tests. Each project also acts as an
example of using
*jgd-cmake-modules* and the `Canonical Project Structure <https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p1204r0.html#:~:text=The%20canonical%20structure%20is%20primarily,specific%20and%20well%2Ddefined%20function.>`_.
See `tests/README.rst <tests/README.rst>`_ for more information.

How to Build CMake Projects
===========================

`CMake <https://cmake.org/>`_ is a meta-buildsystem, meaning it generates buildsystem files from its
standardized, cross-platform scripting language. With this comes additional features, like
generating compilation databases, invoking custom commands, and installing projects.

This document describes how to use the `cmake` command line program to configure and build a
CMake-based project. For an introduction to creating CMake-based projects with their scripting
language, see Kitware's `CMake Tutorial
<https://cmake.org/cmake/help/latest/guide/tutorial/index.html>`_.

TL;DR
~~~~~

.. code-block:: bash

  cmake -B <build-dir> -G Ninja -DCMAKE_BUILD_TYPE=Release  # configure
  cmake --build <build-dir>                                 # build
  ctest --test-dir <build-dir> --output-on-failure          # test
  cmake --install <build-dir>                               # install

Installing CMake
~~~~~~~~~~~~~~~~

Install `cmake` with your system's package manager:

.. code-block:: bash

  sudo pacman -S cmake   # Arch
  sudo apt install cmake # Debian
  brew install cmake     # MacOS

CMake can be also downloaded from Kitware's `official download page <https://cmake.org/download/>`_.

Getting Started
~~~~~~~~~~~~~~~

For the following commands, `<build-dir>` is the directory where you would like CMake to generate
the native buildsystem and place its artifacts. Common names are `build`, `build-debug`, or
`build-release`.  Separate build directories can be simultaneously used to facilitate multiple
builds of a project. There are certain buildsystems, such as *Xcode* and *Visual Studio*, that
support multiple build configurations within a single build directory.

All of the following commands should be invoked from the project directory containing its
*top-level* `CMakeLists.txt` file, which is widely the project's root directory.

.. _configuringcmake:

Configuring
~~~~~~~~~~~

"Configuring" a project is the step where CMake will perform system introspection, interpret the
CMake scripts, and generate native build-system files. It's required before building a project or
performing any subsequent cmake steps.

Most simply, just the build directory can be specified, and the source directory will be implied as
the current directory.

.. code-block:: bash

  cmake -B <build-dir>

Commonly, the `buildsystem
generator <https://cmake.org/cmake/help/latest/manual/cmake-generators.7.html>`_, what generates the
native build-system files, will be specified using :code:`-G`.

.. code-block:: bash

  cmake -B <build-dir> -G Ninja
  cmake -B <build-dir> -G "Unix Makefiles"
  cmake -B <build-dir> -G Xcode
  cmake -B <build-dir> -G "Visual Studio 17 2022"

CMake variable definitions can be specified on the command line with :code:`-D`, which will override
or introduce CMake cache variables before CMake interprets the list files (`CMakeLists.txt`).
Command-line definitions are used to change `CMake's behaviour
<https://cmake.org/cmake/help/latest/manual/cmake-variables.7.html>`_ or to control custom features
of a project, since the project's list files will have access to their definitions. These cache
variables are preserved between CMake invocations, and are stored in the file
`<build-dir>/CMakeCache.txt`, as opposed to normal variables, which are internal to the CMake
scripts (`set() <https://cmake.org/cmake/help/latest/command/set.html>`_).

.. code-block:: bash

  cmake -B <build-dir> -G Ninja -D CMAKE_BUILD_TYPE=Release
  cmake -B <build-dir> -G Ninja -D BUILD_SHARED_LIBS=ON

Building
~~~~~~~~

Building executes the native buildsystem. Although the native buildsystem command-line programs can
be used for this (`make`, `ninja`, etc.), `cmake` can be used to do this in a cross-platform,
buildsystem agnostic manner.

All default build targets from :ref:`configuring <configuringcmake>` can be built with:

.. code-block:: bash

  cmake --build <build-dir>

Specific targets can be individually built with:

.. code-block:: bash

  cmake --build <build-dir> --target <target>
  # Ex. cmake --build build-release --target json-parser

For multi-configuration generators (Ninja Multi-Config, MSVC), those that correspond to
build-systems which support multiple build-types in a single build-directory, add the
:code:`--config flag` to build commands:

.. code-block:: bash

  cmake --build <build-dir> --config <config>
  # Ex. cmake --build build --config Release

.. note::

  All of the available targets can be listed with :code:`cmake --build <build-dir> --target help`

Installing
~~~~~~~~~~

By default, installing will install the build artifacts in `<build-dir>` to your system folders,
therefore requiring administrator permissions. The installation prefix depends on your system - for
Unix, the default is `/usr/local`. JCM's :cmake:`jcm_setup_project()` changes the default to
`/opt/<project>` to align better with `FHS
<https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html>`_, but particular projects can
override this default.

.. code-block:: bash

  cmake --install <build-dir>

The installation prefix can easily be changed with the :code:`--prefix` flag:

.. code-block:: bash

  cmake --install <build-dir> --prefix <install-prefix>
  # Ex. cmake --install build-release --prefix ./install
  # Ex. cmake --install build-release --prefix /opt/my-project

It's favourable to strip the binaries before installing with the :code:`--strip` flag. This will
remove any debug symbols or unneeded dynamic library links.

.. code-block:: bash

  cmake --install build-release --strip
  # Ex. cmake --install build-release --strip --prefix ./install

Like the build step, on multi-configuration generators (Ninja Multi-Config, MSVC), add the
:code:`--config` option to install commands. When unspecified, CMake will choose the first
configuration your buildsystem supports, which may or may not be the configuration built above:

.. code-block:: bash

  cmake --install <build-dir> --config <config>
  # Ex. cmake --install build --config Release


The installation can be limited to a specific subsection of a project's installation, called an
*install component*, using the :code:`--component` option. Install components are often used to
separate installed artifacts by their release and development artifacts, or  by license variants.
Additionally, an install component may not necessarily be installed by default (above), consequently
requiring explicit component-specific installation.

.. code-block:: bash

  cmake --install <build-dir> --component <component>
  # Ex. cmake --install build --component libimage_Release
  # Ex. cmake --install build --component libimage_free


Uninstalling
~~~~~~~~~~~~

#. If a custom installation prefix was chosen, you can simply remove the entire installation
   directory.
#. Upon installing, CMake will generate a file `<build-dir>/install_manifest.txt` listing all
   installed files. Removing these files and any generated parent directories will uninstall the
   project.

Testing
~~~~~~~

Testing is done with a tool called `CTest
<https://cmake.org/cmake/help/latest/manual/ctest.1.html>`_. In a project's list files, they can
register tests with CTest, then these tests will be invoked when *ctest* is invoked, and their
outcomes will be recorded and summarized by CTest.

Although CTest is a powerful tool which supports publishing to dashboards, test scripts, test
parallelization, and even building entire CMake projects, basic examples to test an existing project
are shown below - these options can be joined:

.. code-block:: bash

  ctest --test-dir <build-dir>                     # run all tests, and show summary at the end
  ctest --test-dir <build-dir> --output-on-failure # print output from failed tests
  ctest --test-dir <build-dir> --stop-on-failure   # stop all testing when a single failure occurs
  ctest --test-dir <build-dir> --rerun-failed      # only run tests that did not previously pass
  ctest --test-dir <build-dir> -R <regex>          # run all tests matching <regex>
  ctest --test-dir <build-dir> -E <regex>          # exclude all tests matching <regex>
  ctest --test-dir --output-junit <file>           # produce junit formatted test summary in <file>

  ctest --test-dir --build-config <cfg>            # Desired config for Multi-Config generators

Projects often require you to enable building tests in the configuration stage through a variable,
as they're off by default.

.. code-block:: bash

  cmake -B <build-dir> -D <enable-test-var>:BOOL=ON
  # Ex. cmake -B <build-dir> -D BUILD_TESTING:BOOL=ON

CMake Presets
~~~~~~~~~~~~~

CMake `presets <https://cmake.org/cmake/help/latest/manual/cmake-presets.7.html>`_ exist in the
files `CMakePresets.json` and `CMakeUserPresets.json`. The former is checked into version control,
while the latter is for personal use. These include JSON descriptions of settings for `cmake` (and
`ctest`), which can be invoked by simply naming the desired preset.

.. code-block:: bash

  cmake --preset <configure-preset>     # configure using preset
  cmake --build --preset <build-preset> # build using preset
  ctest --preset <test-preset>          # test using preset

For example, if a project's `CMakePresets.json` named a config preset called *debug-tests*, and
build preset called *unit-tests*, and a test preset called *core-tests*, a user's workflow could be
simplified to the following commands, instead of manually providing numerous command-line options.

.. code-block:: bash

  cmake --preset debug-tests        # configure using preset
  cmake --build --preset unit-tests # build using preset
  ctest --preset core-tests         # test using preset

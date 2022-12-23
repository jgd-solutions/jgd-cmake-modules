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
*install component* with the :code:`--component` option. Install components are often used to
separate installations by their release and development artifacts, or  by license variants. An
install component may also not necessarily be installed by default (above), therefore requiring a
component-specific explicit.

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
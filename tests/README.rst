tests
=====

This directory contains the automated tests for the CMake modules provided by this library.

Testing Operation
-----------------

Testing is performed by configuring, building, installing, testing, and consuming small test
projects that use
*jgd-cmake-modules* as part of the automated tests for *jgd-cmake-modules*. Specifically,
commands in ``tests/CMakeLists.txt`` invoke the *cmake* tool on these subprojects in the tests for
*jgd-cmake-modules*.

Directories within ``tests/`` are completely isolated projects that use *jgd-cmake-modules*
as any other project would. Each of these test projects is therefore an example of how to use the
provided CMake modules and how to structure a project.

Test Layout
-----------

.. explicitly defining hyperlinks such that links are properly rendered as RST without Sphinx.
.. _test-project-consumption_link: https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests/test-project-consumption
.. _single-exec_link:              https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests/single-exec
.. _libsingle_link:                https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests/libsingle
.. _libcomponents_link:            https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests/libcomponents
.. _libheaders_link:               https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests/libheaders
.. _many-exec_link:                https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests/many-exec
.. _libcstr_link:                  https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests/libcstr
.. _daemon_link:                   https://github.com/jgd-solutions/jgd-cmake-modules/tree/main/tests/daemon

- `test-project-consumption <test-project-consumption_link_>`__: A project that finds and consumes each of the following test projects.
  This ensures projects created with JCM can be consumed properly.
- `single-exec <single-exec_link_>`__: Produces a single executable.
- `libsingle <libsingle_link_>`__: Produces a single library, either static or shared. Also has Doxygen documentation generation.
- `libcomponents <libcomponents_link_>`__: Produces multiple libraries through a single project, offered as library
  components. Also shows a nested, private directory.
- `libheaders <libheaders_link_>`__: Produces a single header-only library.
- `many-exec <many-exec_link_>`__: Produces multiple executables through a single project, offered as executable components.
- `libcstr <libcstr_link_>`__: Produces a single library in C, in order to test and exemplify usage of a C project
- `daemon` <daemon_link_>`__: Produces an executable AND a supplementary library. C++ modules usage
  is also exemplified for both the executable and the library.

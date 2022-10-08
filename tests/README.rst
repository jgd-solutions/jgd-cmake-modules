tests
=====

This directory contains the automated tests for the CMake modules provided by this library.

Testing Operation
-----------------

Testing is performed by configuring, building, installing, testing, and consuming small test
projects that use
*jgd-cmake-modules* as part of the automated tests for *jgd-cmake-modules*. Specifically,
`tests/CMakeLists.txt`
invokes the CMake command for these subprojects in the tests for *jgd-cmake-modules*.

Directories within tests/ are completely isolated sample projects that use *jgd-cmake-modules*, just
as any other project would. Each of these test projects is therefore an example of how to use the
provided CMake modules and how to structure the project.

Test Layout
-----------

- **test-project-consumption:** A project that finds and consumes each of the following test projects.
- **single-exec:** Produces a single executable.
- **libsingle:** Produces a single library, either static or shared. Also has Doxygen documentation generation.
- **libcomponents:** Produces multiple libraries through a single project, offered as library
  components. Also shows a nested, private directory.
- **libheaders:** Produces a single header-only library.
- **many-exec:** Produces multiple executables through a single project, offered as executable components.
- **libcstr:** Produces a single library in C, in order to test and exemplify usage of a C project
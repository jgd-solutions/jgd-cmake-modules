# tests

This directory contains the tests for the CMake modules provided by this library.

## Testing Operation

Testing is performed by creating small test projects using *jgd-cmake-modules*,
then building and running the tests of those sub-projects to ensure they work as
expected. Additionally, they are each consumed by *test-project-consumption* to
test each projects' installation provided by *jgd-cmake-modules*.  Test projects
are housed as subdirectories in this *tests/* directory.  They are autonomouse
projects with their own build, artifacts, and installation.  Furthermore, each
of these test projects is an example of how to use the provided CMake modules
and structure the project.

## Test Layout

- **test-project-consumption:** A project that finds and consumes each of the following test projects.
- **single-exec:** Produces a single executable.
- **libsingle:** Produces a single library, either static or shared.
- **libcomponents:** Produces multiple libraries through a single project, offered as library components.
- **libheaders:** Produces a single header-only library.

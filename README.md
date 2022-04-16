# cmake-modules

## Concept

A set of CMake modules to easily and consistently develop CMake based projects.

## Design

The modules' interface are designed to be functional and clear.
Each function is designed to produce reproducible results in any invocation.

## External requirements

The provider of external requirements are not defined in CMake.
This keeps the project agnostic to C++ package managers, system package managers, etc.
All external requirements are to be found with find_package() and target_link_libraries()

## Components

Components are merely subsets of a project. In the vast majority of cases, these components represent libraries (one
library per component) but may rarely represent an executable. For example, if a project produces multiple executables
that are used together, such as a CLI and a daemon, these may be offered as components. By default, every project has
a parent component of the same name as the project that represents the entire project, and links to any
library components that may exist. Executable components are excluded, as executables simply aren't consumed together.
The parent component can be used to link against every library offered by the project - something that doesn't
make sense for

## Notes

### sub projects

Shouldn't be done but will try to support it.

## TODO

- set(CMAKE_INSTALL_DOCDIR \${CMAKE_INSTALL_DATAROOTDIR}/doc/\${PROJECT_NAME}) on each include of gnu install dirs

- for things like prefix and include paths, etc. (those that are calculated or
  change per target) should these be passed down through variables or with functions?

- how the f do we select lib types and how do the install components change those
- look into iinstall components
- configuration headers
- support usage as subproject
- include directories
- tests

- ensure cmake project name doesn't have spaces. Does project() even allow this?
  NO, project will fail

- verify CMAKE_SYSTEM_NAME w/ linux clang
  GOOD

- each executable has a private library

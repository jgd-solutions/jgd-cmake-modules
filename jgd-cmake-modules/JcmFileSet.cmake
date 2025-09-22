include_guard()

#[=======================================================================[.rst:

JcmFileSet
----------------

:github:`JcmFileSet`

#]=======================================================================]

include(JcmParseArguments)
include(JcmCanonicalStructure)
include(JcmTargetNaming)
include(JcmFileNaming)
include(JcmListTransformations)

#[=======================================================================[.rst:

jcm_create_file_sets
^^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_create_file_sets

  .. code-block:: cmake

    jcm_create_file_sets(
      <INTERFACE | PUBLIC | PRIVATE>
      TARGET <target>
      TYPE <HEADERS | CXX_MODULES>
      FILES <file-path>...)

Creates header or C++ module `file-sets
<https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets>`_ of the provided
`scope` containing the files in :cmake:variable:`FILES` for the possibly aliased target,
:cmake:variable:`TARGET`. This function layers the canonical include directory structure (`Canonical
Project Structure`_) onto `CMake's file-sets
<https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets>`_.

For each file-path, the closest canonical include directory, one of those provided by
:cmake:command:`jcm_canonical_include_dirs`, will be found. For each canonical include directory
matched, a file-set of type :cmake:variable:`TYPE` will be created or updated on the
:cmake:variable:`TARGET` using the provided `scope` to contain the matched file.

When the :cmake:variable:`TYPE` argument is *HEADERS*, all file paths in :cmake:variable:`FILES`
must conform to the regular expression :cmake:variable:`JCM_HEADER_REGEX`. When the
:cmake:variable:`TYPE` argument is *CXX_MODULES*, all file paths in :cmake:variable:`FILES` must
conform to the regular expression :cmake:variable:`JCM_CXX_MODULE_REGEX`. These regular expressions
are defined in *JcmFileNaming.cmake*.

Header `file-sets <https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets>`_ are
an excellent way to manage header files for libraries because they support installing INTERFACE and
HEADER files when the target is installed and support modifying the target's respective
`*INCLUDE_DIRECTORIES` properties, as is done by this function.  The subset of canonical include
directories that are matched by the provided :cmake:variable:`FILES` are added to the target'headers
respective `*INCLUDE_DIRECTORIES` properties, based on the `scope`, and are wrapped in the
:cmake:$<BUILD_INTERFACE:...> generator expression. Both public and private header files should be
managed through header file sets.

C++ module `file-sets <https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets>`_
must contain all source files that `export` a module; that is, module interface units and module
partitions. Module implementation units and sources that simply import modules are regarded as
standard sources and should not be added to a file set. 

:cmake:command:`jcm_add_library` and :cmake:command:`jcm_add_target_sources` use this function, and
it is often not necessary to use directly, unless supplementary file sets are to be added to a
target, like in a nested directory.

TODO: support separately creating header sets for integration tests, which are now rejected as a
consequence of an associated canonical include directory not being found.

.. note::
  Use a target's `HEADER_SETS` and `INTERFACE_HEADER_SETS` `properties
  <https://cmake.org/cmake/help/latest/prop_tgt/HEADER_SETS.html>`_ to query its header sets, and the 
  target's `CXX_MODULE_SETS` and `INTERFACE_CXX_MODULE_SETS` `properties
  <https://cmake.org/cmake/help/latest/prop_tgt/CXX_MODULE_SETS.html>`_ to query its C++ module sets.

Parameters
##########

Positional
~~~~~~~~~~

:cmake:variable:`scope`
  The desired scope of the created file-set. One of INTERFACE, PUBLIC, or PRIVATE

One Value
~~~~~~~~~

:cmake:variable:`TARGET`
  The target on which the created header file-sets will be created and `*INCLUDE_DIRECTORIES`
  properties will be manipulated.

:cmake:variable:`TYPE`
  The type of file-set to create; one of *HEADERS* or *CXX_MODULES*. These match the types provided
  by CMake's underlying :cmake:command:`target_sources` command to `create file-sets
  <https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets>`_.

Multi Value
~~~~~~~~~~~

:cmake:variable:`FILES`
  Header or C++ module file paths to add to the created file-sets. Each file path will be converted
  to a normalized, absolute path, with respect to :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`.

Examples
########

.. code-block:: cmake

  jcm_create_file_sets(
    PUBLIC
    TARGET libimage_libimage
    TYPE HEADERS
    FILES image.hpp)

  jcm_create_file_sets(
    PRIVATE 
    TARGET libimage_libimage
    TYPE HEADERS
    FILES internal_routines.hpp)

  # canonical include directory of image.hpp added PUBLICally to libimage_libimage
  # now it's available when linking against libimage_libimage:

  jcm_add_test_executable(
    NAME use_image_hpp
    SOURCES use_image_hpp.cpp
    LIBS libimage_libimage)

.. code-block:: cmake

  jcm_create_file_sets(
    PUBLIC
    TARGET libimage_libimage
    TYPE CXX_MODULES 
    FILES image.mpp io.mpp routines.mpp)

#]=======================================================================]
function(jcm_create_file_sets scope)
  # Positional Usage Guards
  set(supported_scopes "INTERFACE|PUBLIC|PRIVATE")
  if(NOT scope MATCHES "${supported_scopes}")
    message(FATAL_ERROR
      "One of ${supported_scopes} must be provided as the scope to ${CMAKE_CURRENT_FUNCTION}")
  endif()

  # Parse named arguments
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "TARGET" "TYPE"
    MULTI_VALUE_KEYWORDS "HEADERS" "CXX_MODULES"
    REQUIRES_ALL "TARGET" "TYPE"
    REQUIRES_ANY "HEADERS" "CXX_MODULES"
    MUTUALLY_EXCLUSIVE "HEADERS" "CXX_MODULES"
    ARGUMENTS "${ARGN}")

  # Usage Guards
  if(NOT TARGET ${ARGS_TARGET})
    message(FATAL_ERROR
      "${ARGS_TARGET} is not a target and must be created before calling"
      "${CMAKE_CURRENT_FUNCTION}")
  endif()

  if(ARGS_TYPE STREQUAL "HEADERS")
    set(file_regex "${JCM_HEADER_REGEX}")
  elseif(ARGS_TYPE STREQUAL "CXX_MODULES")
    set(file_regex "${JCM_CXX_MODULE_REGEX}")
  else()
    message(FATAL_ERROR
      "Invalid TYPE provided to ${CMAKE_CURRENT_FUNCTION}: ${ARGS_TYPE}. "
      "TYPE must be one of HEADERS or CXX_MODULES")
  endif()

  jcm_separate_list(
    INPUT "${ARGS_FILES}"
    OUT_MATCHED ARGS_FILES
    OUT_MISMATCHED invalid_files
    REGEX "${file_regex}")
  if(invalid_files)
    message(FATAL_ERROR
      "The FILES provided to ${CMAKE_CURRENT_FUNCTION} do not conform to the regular expression "
      "for a file-set of type '${ARGS_TYPE}': ${invalid_files}")
  endif()

  # Transform file pahts to normalized absolute paths
  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_FILES}" OUT_VAR ARGS_FILES)
  jcm_transform_list(NORMALIZE_PATH INPUT "${ARGS_FILES}" OUT_VAR ARGS_FILES)

  # Resolve the canonical include directory to which each header belongs
  jcm_canonical_include_dirs(
    WITH_BINARY_INCLUDE_DIRS
    TARGET ${ARGS_TARGET}
    OUT_VAR available_include_dirs)

  foreach(file_path IN LISTS ARGS_FILES)
    set(shortest_distance_from_include_dir 65000) # biggest int ?
    unset(chosen_include_dir)
    foreach(include_dir IN LISTS available_include_dirs)
      if(NOT file_path MATCHES "^${include_dir}")
        continue()
      endif()

      string(REPLACE "${include_dir}" "" relative_to_include "${file_path}")
      string(LENGTH "${relative_to_include}" distance_from_include)

      if(distance_from_include LESS shortest_distance_from_include_dir)
        set(shortest_distance_from_include_dir ${distance_from_include})
        set(chosen_include_dir "${include_dir}")
      elseif(distance_from_include EQUAL shortest_distance_from_include_dir)
        message(AUTHOR_WARNING
          "Multiple canonical include directories refer to the same path: "
          "${include_dir} & ${chosen_include_dir}")
      endif()
    endforeach()

    if(NOT DEFINED chosen_include_dir)
      message(FATAL_ERROR "Could not resolve the canonical include directory for ${file_path}")
    endif()

    # non-aliased both required by target_sources and provides basic chars for file set name
    jcm_aliased_target(TARGET "${ARGS_TARGET}" OUT_TARGET ARGS_TARGET)

    # add the file to the file-set for its belonging include directory
    string(MD5 include_dir_hash "${chosen_include_dir}")
    string(REPLACE "-" "_" file_set_name "jcm_${ARGS_TARGET}_${scope}_${ARGS_TYPE}_${include_dir_hash}")

    target_sources(${ARGS_TARGET}
      ${scope}
      FILE_SET "${file_set_name}"
      TYPE ${ARGS_TYPE} 
      BASE_DIRS "${chosen_include_dir}"
      FILES "${file_path}")
  endforeach()

  # remove duplicated include directories added by multiple calls to target_sources with same base
  foreach(property INCLUDE_DIRECTORIES INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(property_value ${ARGS_TARGET} ${property})
    if(NOT property_value)
      continue()
    endif()

    list(REMOVE_DUPLICATES property_value)
    set_target_properties(${ARGS_TARGET} PROPERTIES ${property} "${property_value}")
  endforeach()

endfunction()

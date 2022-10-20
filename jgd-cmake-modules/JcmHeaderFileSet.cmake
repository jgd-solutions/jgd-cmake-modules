include_guard()

#[=======================================================================[.rst:

JcmHeaderFileSet
----------------

#]=======================================================================]

include(JcmParseArguments)
include(JcmCanonicalStructure)

#[=======================================================================[.rst:

jcm_header_file_set
^^^^^^^^^^^^^^^^^^^

.. cmake:command:: jcm_header_file_set

  .. code-block:: cmake

    jcm_header_file_set(
      [TARGET <target>]
      [HEADERS <file-path>...]
    )

Creates header `file-sets
<https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets>`_ of the provided
`scope` containing the files in :cmake:variable:`HEADERS`.

For each header file-path, the closest canonical include directory, one of those provided by
:cmake:command:`jcm_canonical_include_dirs`, will be found. For each canonical include directory
matched, a new header file-set will be created on the :cmake:variable:`TARGET` using the provided
`scope` if it doesn't already exist. The original header file will be added to that file-set.

Header `file-sets <https://cmake.org/cmake/help/latest/command/target_sources.html#file-sets>`_ are
an excellent way to manage header files for libraries because they support installing INTERFACE and
HEADER files when the target is installed and support modifying the target's respective
`*INCLUDE_DIRECTORIES` properties, as is done by this function.  The subset of canonical include
directories that are matched by the provided :cmake:variable:`HEADERS` are added to the target's
respective `*INCLUDE_DIRECTORIES` properties, based on the `scope`, and are wrapped in the
:cmake:$<BUILD_INTERFACE:...> generator expression.

:cmake:command:`jcm_add_library` uses this function, and it is often not necessary to use directly,
unless supplementary headers sets are to be added to a target, like in a nested directory.

.. note::
  Use a target's `HEADER_SETS` and `INTERFACE_HEADER_SETS` `properties
  <https://cmake.org/cmake/help/latest/prop_tgt/HEADER_SETS.html>`_ to query its header sets.

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

Multi Value
~~~~~~~~~~~

:cmake:variable:`HEADERS`
  Header file paths to add to the created header file-sets. Each file path will be converted to a
  normalized, absolute path, with respect to :cmake:variable:`CMAKE_CURRENT_SOURCE_DIR`.

Examples
########

.. code-block:: cmake

  jcm_header_file_set(
    PUBLIC
    TARGET libimage_libimage
    HEADERS image.hpp
  )

  # canonical include directory of image.hpp added PUBLICally to libimage_libimage
  # now it's available when linking against libimage_libimage

  jcm_add_test_executable(
    NAME use_image_hpp
    SOURCES use_image_hpp.cpp
    LIBS libimage_libimage
  )

#]=======================================================================]
function(jcm_header_file_set scope)
  # Positional Usage Guards
  set(supported_scopes "INTERFACE|PUBLIC|PRIVATE")
  if (NOT scope MATCHES "${supported_scopes}")
    message(FATAL_ERROR
      "One of ${supported_scopes} must be provided as the scope to ${CMAKE_CURRENT_FUNCTION}")
  endif ()

  # Parse named arguments
  jcm_parse_arguments(
    ONE_VALUE_KEYWORDS "TARGET"
    MULTI_VALUE_KEYWORDS "HEADERS"
    REQUIRES_ALL "TARGET" "HEADERS"
    ARGUMENTS "${ARGN}"
  )

  # Usage Guards
  if (NOT TARGET ${ARGS_TARGET})
    message(FATAL_ERROR
      "${ARGS_TARGET} is not a target and must be created before calling"
      "${CMAKE_CURRENT_FUNCTION}")
  endif ()

  # Transform headers to normalized absolute paths
  jcm_transform_list(ABSOLUTE_PATH INPUT "${ARGS_HEADERS}" OUT_VAR ARGS_HEADERS)
  jcm_transform_list(NORMALIZE_PATH INPUT "${ARGS_HEADERS}" OUT_VAR ARGS_HEADERS)

  # Resolve the canonical include directory to which each header belongs
  jcm_canonical_include_dirs(
    WITH_BINARY_INCLUDE_DIRS
    TARGET ${ARGS_TARGET}
    OUT_VAR available_include_dirs
  )

  foreach (header_path ${ARGS_HEADERS})
    set(shortest_distance_from_include_dir 65000)
    unset(chosen_include_dir)
    foreach (include_dir ${available_include_dirs})
      if (NOT header_path MATCHES "^${include_dir}")
        continue()
      endif ()

      string(REPLACE "${include_dir}" "" relative_to_include "${header_path}")
      string(LENGTH "${relative_to_include}" distance_from_include)

      if (distance_from_include LESS shortest_distance_from_include_dir)
        set(shortest_distance_from_include_dir ${distance_from_include})
        set(chosen_include_dir "${include_dir}")
      elseif (distance_from_include EQUAL shortest_distance_from_include_dir)
        message(AUTHOR_WARNING
          "Multiple canonical include directories refer to the same path: "
          "${include_dir} & ${chosen_include_dir}")
      endif ()
    endforeach ()

    if (NOT DEFINED chosen_include_dir)
      message(FATAL_ERROR "Could not resolve the canonical include directory for ${header_path}")
    endif ()

    # add the header to the header file set for its belonging include directory
    string(MD5 include_dir_hash "${chosen_include_dir}")
    string(REPLACE "-" "_" file_set_name "${ARGS_TARGET}_${scope}_${include_dir_hash}")

    target_sources(${ARGS_TARGET}
      ${scope}
      FILE_SET "${file_set_name}"
      TYPE HEADERS
      BASE_DIRS "${chosen_include_dir}"
      FILES "${header_path}"
    )
  endforeach ()

  foreach(property INCLUDE_DIRECTORIES INTERFACE_INCLUDE_DIRECTORIES)
    get_target_property(property_value ${ARGS_TARGET} ${property})
    list(REMOVE_DUPLICATES property_value)
    set_target_properties(${ARGS_TARGET} PROPERTIES ${property} "${property_value}")
  endforeach()
endfunction()

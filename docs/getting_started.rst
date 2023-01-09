Getting Started
---------------

1. Acquire the project
~~~~~~~~~~~~~~~~~~~~~~

**Option 1:** From Source

  Clone source code and enter the project root

  .. code-block:: bash

    git clone https://github.com/jgd-solutions/jgd-cmake-modules.git
    cd jgd-cmake-modules

  Configure, build, and install

  .. code-block:: bash

    cmake -B build -G Ninja
    cmake --build build
    cmake --install build                        # install globally
    cmake --install build --prefix <install-dir> # install to directory

**Option 2:** From `vcpkg <https://vcpkg.io/en/index.html>`_

  Add *jgd-cmake-modules* as a project dependency in `vcpkg.json`

  .. code-block:: json

    "dependencies": [
      "jgd-cmake-modules"
    ]

  Add `vcpkg-registry <https://github.com/jgd-solutions/vcpkg-registry>`_ as a registry in your
  `vcpkg-configurations.json`

  .. code-block:: json

    {
      "registries": [
        {
          "kind": "git",
          "baseline": "<desired-vcpkg-registry-ref>",
          "repository": "https://github.com/jgd-solutions/vcpkg-registry.git",
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

  # Ex.
  find_package(ClangFormat)
  include(JcmCreateAccessoryTargets)
  jcm_create_clang_format_targets(SOURCE_TARGETS libexample::libexample)

# jgd-cmake-modules

A set of CMake modules to easily and consistently develop proper CMake based projects.

For a short overview of the project, see [Overview](docs/overview.md)

## Using jgd-cmake-modules

### 1. Acquire the project

**Option 1:** From Source

  Clone source code and enter project root

  ```bash
  git clone https://gitlab.com/jgd-solutions/jgd-cmake-modules.git 
  cd jgd-cmake-modules
  ```

  Configure, build, and install

  ```bash
  cmake -B build -G Ninja
  cmake --build build
  cmake --install build
  ```

**Option 2:** From [vcpkg](https://vcpkg.io/en/index.html)

  Add "jgd-cmake-modules" as a project dependency in `vcpkg.json`

  ```json
  "dependencies": [
    "jgd-cmake-modules"
  ]
  ```

  Add [vcpkg-registry](https://gitlab.com/jgd-solutions/vcpkg-registry) as a registry in your `vcpkg-configurations.json`

  ```json
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
  ```

### 2. Locate jgd-cmake-modules

Find *jgd-cmake-modules* as an external package in your top-level *CMakeLists.txt*

```cmake
find_package(jgd-cmake-modules CONFIG REQUIRED)
```

### 2. Include and Use Modules

```cmake
include(JcmClangFormat)
jcm_create_clang_format_targets(TARGETS libexample::libexample)
```

## Examples

This project uses its own modules, and acts as its own example!

Additionally, the `tests/` directory has sample projects that use *jgd-cmake-modules*. These projects are
configured and built as part of *jgd-cmake-modules*'s automated tests. Each project also acts as an
example of using *jgd-cmake-modules* and the [Canonical Project
Structure](https://www.open-std.org/jtc1/sc22/wg21/docs/papers/2018/p1204r0.html#:~:text=The%20canonical%20structure%20is%20primarily,specific%20and%20well%2Ddefined%20function.).
See [tests/README.md](tests/README.md) for more information.

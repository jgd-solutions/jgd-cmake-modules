from os import path

from conans import ConanFile, CMake, tools
from conan.tools.cmake import CMakeDeps


class CMakeModulesRecipe(ConanFile):
    name = "cmake-modules"
    version = "0.0.1"
    license = "Proprietary"
    author = "JGD Solutions"
    settings = ["build_type"]
    options = {"with_tests": [False, True]}
    default_options = {"with_tests": False}
    generators = "CMakeDeps"
    no_copy_source = True

    def _should_run_tests(self):
        return self.options.with_tests and not tools.cross_building(self)

    def export(self):
        print("Exporting")
        self.copy("project-infrastructure/project-infrastructure/conan/base_recipe.py")
        self.copy("LICENSE.md")

    def export_sources(self):
        print("Exporting Sources")
        self.copy("CMakeLists.txt")
        self.copy("f{self.name}/*")
        self.copy("tests/*")
        self.copy("cmake/*")

    def generate(self):
        print("Generating")
        cmake_deps = CMakeDeps(self)
        cmake_deps.generate()

    def _configure_cmake(self):
        cmake = CMake(self)
        cmake.verbose = True
        cmake.definitions["BUILD_TESTING"] = self._should_run_tests()
        cmake.configure()
        return cmake

    def build(self):
        print("building")
        cmake = self._configure_cmake()
        cmake.build()
        if self._should_run_tests():
            cmake.test()

    def package(self):
        cmake = self._configure_cmake()
        cmake.install()

    def package_id(self):
        self.info.header_only()

    def package_info(self):
        cmake_install_dest = path.join("share", "cmake", "f{self.name}")
        package_config_file = path.join(
            cmake_install_dest, "f{self.name}-config.cmake"
        )
        build_modules = [package_config_file]

        self.cpp_info.set_property("cmake_build_modules", build_modules)
        self.cpp_info.build_modules = build_modules

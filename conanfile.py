from conans import ConanFile, CMake, tools


class BaseRecipe(ConanFile):
    license = "Proprietary"
    author = "JGD Solutions"
    settings = "os", "compiler", "build_type", "arch"
    options = {"with_tests": [False, True]}
    default_options = {"with_tests": False}
    generators = "cmake_find_package_multi"
    no_copy_source = True

    def _should_run_tests(self):
        return self.options.with_tests and not tools.cross_building(self)

    def export(self):
        self.copy("project-infrastructure/project-infrastructure/conan/base_recipe.py")
        self.copy("LICENSE.md")

    def export_sources(self):
        self.copy("project-infrastructure/project-infrastructure/cmake/*.cmake")
        self.copy("CMakeLists.txt")
        self.copy("{}/*".format(self.name))
        self.copy("tests/*")
        self.copy("cmake/*")

    def requirements(self):
        if self._should_run_tests():
            self.requires("boost-ext-ut/1.1.8")

    def _configure_cmake(self):
        cmake = CMake(self)
        cmake.verbose = True
        cmake.definitions["BUILD_TESTING"] = self._should_run_tests()
        cmake.configure()
        return cmake

    def build(self):
        cmake = self._configure_cmake()
        cmake.build()
        if self._should_run_tests():
            cmake.test()

    def package(self):
        self.copy("{}/*.hpp".format(self.name), dst="include")
        self.copy("*{}.lib".format(self.name), dst="lib", keep_path=False)
        self.copy("{}.dll".format(self.name), dst="bin", keep_path=False)
        self.copy("{}.so".format(self.name), dst="lib", keep_path=False)
        self.copy("{}.dylib".format(self.name), dst="lib", keep_path=False)
        self.copy("{}.a".format(self.name), dst="lib", keep_path=False)

    def package_info(self):
        lib_name = self.name
        if self.name.startswith("lib") and len(self.name) > len("lib"):
            lib_name = lib_name[len("lib") :]

        self.cpp_info.libs = [lib_name]

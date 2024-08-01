from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout


class my_samv71_projectRecipe(ConanFile):
    name = "my-samv71-project"
    version = "1.0"
    package_type = "application"
    requires = "samv71-dfp/4.9.117", "harmony/3.0"
    settings = "build_type", "arch"
    generators = "CMakeToolchain", "CMakeDeps"

    # Sources are located in the same place as this recipe, copy them to the recipe
    exports_sources = "CMakeLists.txt", "src/*"

    def layout(self):
        cmake_layout(self)

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
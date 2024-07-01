from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps


class SAMV71BlinkyRecipe(ConanFile):
    name = "SAMV71-Conan-Blinky"
    version = "1.0"
    package_type = "application"

    # Optional metadata
    license = "MIT"
    author = "Grigoris Pavlakis <g.pavlakis@spacedot.gr>"
    url = "https://github.com/PeakSat/minimal_dev_setup"
    description = "Minimal bring-up (blinky) for ATSAMV71Q21B using CMake and Conan"
    # Binary configuration
    settings = "os", "compiler", "build_type", "arch"

    requires = "cmsis/5.4.0"

    # Sources are located in the same place as this recipe, copy them to the recipe
    exports_sources = "CMakeLists.txt", "src/*"

    def layout(self):
        cmake_layout(self)

    def generate(self):
        deps = CMakeDeps(self)
        deps.generate()
        tc = CMakeToolchain(self)
        tc.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()


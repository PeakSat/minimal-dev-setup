from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout


class BlinkyRecipe(ConanFile):
    name = "BlinkyExample"
    version = "1.0"
    package_type = "application"

    # Authorship metadata
    license = "MIT"
    author = "Grigoris Pavlakis <g.pavlakis@spacedot.gr>"
    url = "https://github.com/PeakSat/minimal_dev_setup"
    description = "Blinky example for Atmel SAMV71 Xplained Ultra"

    settings = "build_type", "arch"
    generators = "CMakeToolchain", "CMakeDeps"

    # Dependencies
    requires = "samv71-dfp/4.9.117", "harmony/3.0"

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


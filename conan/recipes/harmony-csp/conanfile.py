from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
from conan.tools.files import get, copy
from os.path import join

class harmony_cspRecipe(ConanFile):
    name = "harmony-csp"
    version = "3.19.0"

    license = "Proprietary"
    author = "Microchip Technology"
    url = "https://github.com/Microchip-MPLAB-Harmony/csp"
    description = "MPLAB® Harmony 3 Chip Support Package, in source form. Intended to be used via Harmony"
    topics = ("chip-support", "mplab")
    generators = "CMakeToolchain"

    # exclude apps/ and docs/ (we don't need them to build things)
    _src_contents = "arch/*", "peripheral/*", "plugins/*", "*.xml", "*.yml", "*.md"

    def source(self):
        get(self, **self.conan_data["sources"][self.version])

    def package(self):
        # "src" for consistency, despite technically being a bunch of
        # source templates and jars to fill them in
        for src_pattern in self._src_contents:
            copy(self, pattern=src_pattern, src=self.source_folder, dst=join(self.package_folder, "src"))

    def package_info(self):
        self.cpp_info.srcdirs = ["src"]

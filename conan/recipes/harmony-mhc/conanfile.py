from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
from conan.tools.files import get, copy
from os.path import join

class harmony_mhcRecipe(ConanFile):
    name = "harmony-mhc"
    version = "3.8.5"

    license = "Proprietary"
    author = "Microchip Technology"
    url = "https://github.com/Microchip-MPLAB-Harmony/mhc"
    description = "MPLAB® Harmony 3 Configurator (MHC), part of Harmony 3 framework"
    topics = ("chip-support", "mplab")

    # excluded: docs, favicon.ico, run scripts (runmhc.bat/sh) 
    _src_contents = "databases/*", "np_templates/*", "scripts/*", "*.yml", "*.md", "*.jar", "*.xml", "manifest.db"

    def source(self):
        get(self, **self.conan_data["sources"][self.version])

    def package(self):
        for src_pattern in self._src_contents:
            copy(self, pattern=src_pattern, src=self.source_folder, dst=join(self.package_folder, "src"))

    def package_info(self):
        self.cpp_info.srcdirs = ["src"]

from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
from conan.tools.files import get, copy

class cmsisRecipe(ConanFile):
    name = "cmsis"
    version = "5.4.0"

    license = "Apache-2.0"
    author = "ARM Limited"
    url = "https://packs.download.microchip.com/#collapse-Microchip-SAMV71-DFP-pdsc"
    description = "CMSIS (Common Microcontroller Software Interface Standard) support files"
    topics = ("device-support", "mplab")

    no_copy_source = True
    exports_sources = "CMSIS/Core/Include/*", "ARM.CMSIS.pdsc", "LICENSE.txt"

    def source(self):
        get(self, **self.conan_data["sources"][self.version])

    def package(self):
        for pattern in self.exports_sources:
            copy(self, pattern=pattern, src=self.source_folder, dst=self.package_folder)

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "CMSIS")
        self.cpp_info.components["Core"].includedirs = ["CMSIS/Core/Include/"]
        self.cpp_info.components["Core"].set_property("cmake_target_name", "CMSIS::Core")

        self.cpp_info.bindirs = []
        self.cpp_info.libdirs = []

from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
from conan.tools.files import get, copy
from os.path import join

class harmony_Recipe(ConanFile):
    name = "harmony"
    version = "3.0"

    license = "Proprietary"
    author = "Microchip Technology"
    url = "https://github.com/Microchip-MPLAB-Harmony/"
    description = "MPLAB® Harmony 3 Framework metapackage"
    topics = ("harmony", "framework", "mplab")

    requires = "cmsis/5.4.0", "samv71-dfp/4.9.117", "harmony-csp/3.19.0", "harmony-mhc/3.8.5"

    exports_sources = "cmake/*"

    def package(self):
        # Normally I'd like to make symlinks to the dependencies instead of full-blown copying,
        # but the CSP literally string-concatenates relative paths. These sometimes contain
        # '..' references, and when resolved point to Conan's package directory instead of
        # the fake framework root.
        # If we could somehow force Jython to resolve the symlinks without patching
        # and cannot be resolved correctly without patching (see issue #8) 
        copy(self, "cmake/*.cmake", self.source_folder, self.package_folder)
        copy(self, pattern="*", src=join(self.dependencies["cmsis"].package_folder), dst=join(self.package_folder, "dev_packs", "arm", "CMSIS", f"{self.dependencies['cmsis'].ref.version}"))
        copy(self, pattern="*", src=join(self.dependencies["samv71-dfp"].package_folder, "src"), dst=join(self.package_folder, "dev_packs", "Microchip", "SAMV71_DFP", f"{self.dependencies['samv71-dfp'].ref.version}"))
        copy(self, pattern="*", src=join(self.dependencies["harmony-csp"].package_folder, "src"), dst=join(self.package_folder, "csp"))
        copy(self, pattern="*", src=join(self.dependencies["harmony-mhc"].package_folder, "src"), dst=join(self.package_folder, "mhc"))

    def package_info(self):
        self.cpp_info.set_property("cmake_build_modules", ["cmake/MHCHelper.cmake"])


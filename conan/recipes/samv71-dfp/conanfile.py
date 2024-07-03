from conan import ConanFile
from conan.tools.cmake import CMakeToolchain, CMake, cmake_layout, CMakeDeps
from conan.tools.files import get, copy, save
from os.path import join

class samv71_dfpRecipe(ConanFile):
    name = "samv71-dfp"
    version = "4.9.117"

    # Optional metadata
    license = "Proprietary"
    author = "Microchip Technology"
    url = "https://packs.download.microchip.com/#collapse-Microchip-SAMV71-DFP-pdsc"
    description = "Microchip SAMV71 Series Device Support (DFP)"
    topics = ("device-support", "mplab")

    settings = "build_type"
    requires = "cmsis/5.4.0"
    _src_contents = "samv71b/*", "scripts/*", "Microchip.SAMV71_DFP.pdsc", "Microchip.SAMV71_DFP.sha1", "package.content"
    _mcu_variants = "J19", "J20", "J21", "N19", "N20", "N21", "Q19", "Q20", "Q21"

    def _gen_startup_cmake(self, variants):
        models = [f"SAMV71{variant}B" for variant in variants]
        header_section = (
            f"cmake_minimum_required(VERSION 3.20)\n"
            f"project(dfp_dummy)\n"
            f"set(CMAKE_C_OUTPUT_EXTENSION .obj)" # to enforce consistency
            f"\n"
        )
        find_package_section = (
            f"find_package(CMSIS COMPONENTS Core REQUIRED)\n"
            f"\n"
        )
        # NOTE: Startup code must always be passed as an object file and not as
        # a static library, otherwise the linker will omit it and programs
        # won't boot. This happens because the startup code is never explicitly
        # called from the program itself, thus from the linker's perspective it
        # is never used.
        # https://stackoverflow.com/a/39038795
        cmakelists_startup_target_template = lambda model: (
            f"add_library({model}DefaultGCCStartup OBJECT)\n"
            f"target_include_directories({model}DefaultGCCStartup PRIVATE samv71b/include)\n"
            f"target_sources({model}DefaultGCCStartup PRIVATE samv71b/gcc/gcc/startup_{model.lower()}.c)\n"
            f"target_link_libraries({model}DefaultGCCStartup PRIVATE CMSIS::Core)\n"
            f"\n"
        )
        cmakelists_install_target_template = lambda target: (
            f"install(FILES $<TARGET_OBJECTS:{target}> DESTINATION lib)\n"
        )
        cmakelists_targets = [cmakelists_startup_target_template(model) for model in models]
        cmakelists_installs = [cmakelists_install_target_template(f"{model}DefaultGCCStartup") for model in models]
        return header_section + find_package_section + "".join(cmakelists_targets) + "".join(cmakelists_installs)

    def export_sources(self):
        fake_cmakelists = self._gen_startup_cmake(self._mcu_variants)
        save(self, f"{self.export_sources_folder}/CMakeLists.txt", fake_cmakelists)

    def source(self):
        get(self, **self.conan_data["sources"][self.version])

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
        # create a standard prefix for our DFP here.
        # startup object files get installed by CMake
        cmake = CMake(self)
        cmake.install()
        # grab out the header files
        copy(self, "*.h", join(self.source_folder, "samv71b/include"), join(self.package_folder, "include"))
        # we only care about GCC linker scripts, place those under the lib/ldscripts canonical location
        copy(self, "*.ld", join(self.source_folder, "samv71b/gcc/gcc/"), join(self.package_folder, "lib/ldscripts"), keep_path=False)
        # original DFP source package contents under 'src/'. Do not remove,
        # this will be used from the Harmony conan package in order to spoof
        # MHC into believing that it sees a well-formed Harmony framework root,
        # whose contents are controlled by us.
        for pat in self._src_contents:
            copy(self, pattern=pat, src=self.source_folder, dst=join(self.package_folder, "src"))

    def package_info(self):
        self.cpp_info.set_property("cmake_file_name", "SAMV71-DFP")

        self.cpp_info.components["Core"].includedirs = ['include']
        self.cpp_info.components["Core"].requires = ['cmsis::Core']

        for variant in self._mcu_variants:
            model = f'SAMV71{variant}B'
            self.cpp_info.components[f'{model}::Startup'].requires = ['Core']
            self.cpp_info.components[f'{model}::Startup'].objects = [f"lib/startup_{model.lower()}.c.obj"]
            self.cpp_info.components[f'{model}::Linker::Flash'].exelinkflags = [f"-T{self.package_folder}/lib/ldscripts/{model.lower()}_flash.ld"]
            self.cpp_info.components[f'{model}::Linker::SRAM'].exelinkflags = [f"-T{self.package_folder}/lib/ldscripts/{model.lower()}_sram.ld"]


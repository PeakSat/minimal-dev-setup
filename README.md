# Minimal bring-up project for ATSAMV71Q21B

This repository contains all necessary components to start developing
software for the ATSAMV71Q21B MCU, using the Harmony 3 framework.

# Features

- Cross-platform: Builds work consistently out of the box on Windows and Linux.
- Reliable: No machine-specific configuration required for new dev setups.
- Standards-focused: Built around standard tools (ARM GCC, CMake and Conan 2). 
- IDE-agnostic: Works on any CMake-supporting IDE, as well as the terminal.
- Version-controllable: Dependency tracking is conducted by Conan, even
  for Harmony tools and components, allowing for consistent builds anywhere.
- Fully integrated: Harmony configuration (MHC) is entirely controlled from
  within CMake, both for the UI and for codegen. Generated components are mapped
  to modern CMake targets.
- Tooling-agnostic: Vendor-specific tools are isolated and can always be removed
  at any time with minimal disruption.
- Documented: All settings and scripts come with detailed explanations of
  purpose.

# Quick Start
Ensure that you have these tools installed and on your `PATH` before you start.

| **Tool**                              | **Version** |
|---------------------------------------|-------------|
| ARM GCC (arm-none-eabi-gcc --version) | 13.3        |
| CMake   (cmake --version)             | 3.30.1      |
| Ninja   (ninja --version)             | 1.12.1      |
| Conan   (conan -v)                    | 2.5.0       |
| OpenOCD (openocd -v)                  | 0.12.0      |
| Adoptium OpenJDK (java -version)      | >= 8        |

Download OpenJDK from https://adoptium.net

To verify if they are on PATH:
- **Windows**: open `Command Prompt (cmd.exe)`,
- **Linux**: open `Terminal`,

type the command in parentheses on the table and hit Enter. Do this for each
tool. You should get text indicating the version somewhere. 
If you get an error (not found) then look [here](https://superuser.com/a/284351)
for how to set up your PATH correctly.

## Step 0: Clone this repository

## Step 1: Install the Conan profile for SAMV71

All commands are run from the root directory. Assuming you have set up a default
Conan profile (with `conan profile detect`), run:
```shell
conan config install ./conan/config/
```
This will add a new Conan profile, named `baremetal-samv71-armv7`. The profile
includes global compiler and CMake settings necessary for building working code
for the SAMV71 platform. From now on, **pass the profile's name
(`-pr=baremetal-samv71-armv7`) whenever interacting with conan**. Refer to the
config's [README](./conan/config/README.md) file for more information.

## Step 2: Install the Harmony Conan packages
### Manual installation

Harmony consists of a set of interdependent components, which are individually
packaged for version control purposes. Install each of them with the following
command:
```shell
conan create ./conan/recipes/<package-name> -pr=baremetal-samv71-armv7
```
where `package-name` is the package's directory name. The correct order for
installation (higher on the list = first):
```
cmsis
samv71-dfp
harmony-csp
harmony-mhc
harmony
```
Deviating from this order will just cause Conan to throw an error of missing
dependencies. The process is completely automated; see 
`./conan/recipes/<package-name>/conanfile.py` for configuration details of each
package.

### Install from Artifactory
TODO.

# Usage
## Setting up a new project

Create a new `conanfile.py`:
```python
from conan import ConanFile
from conan.tools.cmake import CMake, cmake_layout


class my_samv71_projectRecipe(ConanFile):
    name = "my-samv71-project"
    version = "1.0"
    package_type = "application"
    requires = "samv71-dfp/4.9.117"
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
```

This is just a minimal Conan skeleton, with a declared dependency on the 
[DFP](#device-family-pack-dfp), which is essential for making anything work on
the SAMV71 and you'll be using it all the time. Refer to Conan docs for details
on how to make  Conanfiles.

Create a new `CMakeLists.txt` in your project dir:
```cmake
cmake_minimum_required(VERSION 3.30)
project(my-samv71-project LANGUAGES C CXX)

find_package(SAMV71-DFP COMPONENTS SAMV71Q21B REQUIRED)

add_executable(my-samv71-project src/main.cpp)

target_link_libraries(my-samv71-project PRIVATE samv71-dfp::Core samv71-dfp::SAMV71Q21B::Startup samv71-dfp::SAMV71Q21B::Linker::Flash)
```

**NOTE**: Always link a startup file and linker script in the final binary
(either the ones from the DFP used here, or your own with 
`target_link_options(my-samv71-project PRIVATE "-T/your/script.ld")`). Otherwise
you will get linker errors such as `undefined symbol '_sbss' referenced in
expression` which are defined in the startup files.

Create a source file (`src/main.cpp`):
```c++
int main() {
    while (true) {

    }
}
```

Build the project:
```shell
conan build . -pr=baremetal-samv71-armv7
```

The resulting binary should be at `build/Debug/my-samv71-project.elf`

## Using Harmony
conanfile.py: Add `"harmony/3.0"` in your `requires` line, as follows:
```
requires = "samv71-dfp/4.9.117", "harmony/3.0"
```

NOTE: Every time you modify your `conanfile.py`, you have to rerun
`conan build . -pr=baremetal-samv71-armv7` in order for CMake to be
updated with the freshest dependency info.

CMakeLists.txt: 
```cmake
find_package(Harmony REQUIRED)
```

### Configuring the MCU
**NOTE**: This will be available only after you have 
[enabled Harmony](#using-harmony).

The Harmony setup includes the Microchip Harmony Configurator (MHC) tool for
adjusting settings and generating peripheral drivers. **MHC needs Java**
installed and in your PATH to work. If your Java setting is incorrect, CMake
will notify you with an error.

To launch it, use
```shell
cd build/Debug \
ninja mcu_config
```

This MHC instance is under the control of CMake, and can only be used by issuing
this command. 

To create a new configuration, follow **exactly** this workflow:
1. Click `File -> New Configuration`. Even if editing existing settings, always
create a new configuration.
2. No need to set Location/Project Name/Configuration Name, they don't really
matter in this case. 
3. Select `ATSAMV71Q21B` under `Target Device`. The supporting files for other
devices are missing and thus will not work. Make sure this is correct; otherwise
you have to start the process all over.
4. Click `Finish`. On the `Configuration Database Setup` click `Launch`.
5. Configure away.
6. Click `File -> Save Configuration` (the disk icon), then `File -> Export`. At
the Export dialog, check all checkboxes and specify a folder where you'll get
your settings. **Always save before exporting**, otherwise you won't get files
back.

To edit an existing configuration, follow Steps 1-4, then click `File -> Import`
and specify the directory of your exported configuration files. When done, save
and export back.

**CAUTION**: Do NOT use the code generation feature, it will not work and cause
MHC to hang. Generation will be done automatically by CMake whenever needed, see
[this section](#adding-mhc-configuration-to-cmake).

### Generating peripheral driver code
**NOTE**: This will be available only after you have
[enabled Harmony](#using-harmony).

The Harmony package includes a helper script for MHC, which can be found under
`./conan/recipes/harmony/cmake/MHCHelper.cmake`. This script is implicitly
included after calling `find_package(Harmony)` and generates the code using
MHC at configure time.

In your CMakeLists.txt, add this:
```cmake
add_harmony_config(
        MCU_MODEL ATSAMV71Q21B
        YAML_FILES <list of MHC-exported yml files>
)
```

You can use the generated code by linking in your executable the targets:
- `Harmony::PeripheralDrivers`: generated peripheral drivers.
- `Harmony::Interrupts` : interrupt handler code
- `Harmony::SysInit`: the SYS_Initialize() function that does the clock init.

## Uploading code
You can upload compiled `.elf` binaries using [OpenOCD](https://openocd.org)
and a suitable configuration file (e.g. `atmel_samv71_xplained_ultra.cfg` for
the Atmel SAMV71 Xplained Ultra board) with the following command:

```shell
openocd -f /path/to/cfg/file -c "program /path/to/compiled/binary.elf reset"
```

## Attaching a debugger
OpenOCD automatically opens a debug server to which you can connect using
GDB if needed, as follows:
```shell
arm-none-eabi-gdb /path/to/compiled/binary_with_symbols.elf
```
Within GDB, run the following command to connect:
`target extended-remote localhost:3333`

## CLion integration

Many developers in the team prefer using CLion for day-to-day coding. Conan
generates CMake presets, which can be used for setting up CLion run
configurations as follows:

1. Generate CMake toolchains for `Debug` and `Release` builds using:
- `conan install . -pr=baremetal-samv71-armv7 -s build_type=Debug`
- `conan install . -pr=baremetal-samv71-armv7 -s build_type=Release`
This should have generated a `CMakeUserPresets.json` file in the project
directory.

2. Start CLion and open the project directory (`Open` button).
3. CLion should pop up a message in the lower right corner stating 
`Loaded XXXX CMake presets` and a window named `Open Project Wizard`. 
4. In the `Open Project Wizard`, disable the default `Debug` profile by
   unticking the `Enable profile` checkbox. Enable only the `conan-debug`
   and `conan-release` profiles.
5. Click `OK`. You should now have two options for `conan-debug`
and `conan-release`, so you can switch between them at will.
6. Add an OpenOCD run configuration via `Run -> Edit Configurations`.
   Click the `+` button on the upper left corner and select
   `OpenOCD Download and Run` from the list.
7. Set the `Executable binary` to your project's binary target, 
   the `Debugger` to `arm-none-eabi-gdb` and the 
   `Board config file` to OpenOCD's `cfg` file. Leave the rest of the
   settings at default.
8. Click `OK`. 

If everything went well, add a random breakpoint in your code (make sure
it's actually reachable) and try running the debugger from the "bug" icon.
CLion should build, upload and attach automatically, and when the breakpoint
is hit CLion's debug interface will start up, letting you step as always.

# Appendix: Conan package description
## Device Family Pack (DFP)
### Description
The DFP (packaged as `samv71-dfp`) is the most important component to include in
any SAMV71 project. It contains:
- headers describing the register layout of all SAMV71 devices
- startup code (default  `Reset_Handler` and interrupt vector table)
- default linker scripts (program code layout)

### Usage
Add `samv71-dfp/4.9.117` to your `conanfile.py`. 
Then, from your `CMakeLists.txt` use: 
```cmake
find_package(SAMV71-DFP COMPONENTS SAMV71Q21B REQUIRED)
# ...
```
Note that all devices are included, just change the COMPONENT name if so desired.
Publicly available targets (via `target_link_libraries`):
```
samv71-df::Core (headers for all devices)
samv71-dfp::SAMV71Q21B::Startup (default startup file)
samv71-dfp::SAMV71Q21B::Linker::Flash (default linker script for booting via NAND)
samv71-dfp::SAMV71Q21B::Linker::SRAM (default linker script for booting via SRAM)
```

## Chip Support Pack (CSP)
TODO

## Microchip Harmony Configurator (MHC)
TODO

# Examples
The repository includes example code under `examples/`. Refer to each example's
README files for details.

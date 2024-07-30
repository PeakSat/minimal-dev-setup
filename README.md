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
- to modern CMake targets.
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

To verify if they are on PATH:
- **Windows**: open `Command Prompt (cmd.exe)`,
- **Linux**: open `Terminal`,

type the command in parentheses on the table and hit Enter. Do this for each
tool. You should get text indicating the version somewhere. 
If you get an error (not found) then look [here](https://superuser.com/a/284351)
for how to set up your PATH correctly.

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
installation (higher on the list = first, slashes = order doesn't matter between
these two):
```
cmsis
samv71-dfp
harmony-csp/harmony-mhc
harmony
```
Deviating from this order will just cause Conan to throw an error of missing
dependencies. The process is completely automated; see 
`./conan/recipes/<package-name>/conanfile.py` for configuration details of each
package.

### Install from Artifactory
TODO.

# Usage
## Conan packages
TODO

## CMake integration
TODO

## Uploading code
You can upload compiled `.elf` binaries using OpenOCD. Assuming a common
development board (Atmel SAMV71 Xplained Ultra), OpenOCD can do this:
```shell
openocd -f /path/to/cfg/file -c "program /path/to/compiled/binary.elf reset"
```

## Attaching a debugger
OpenOCD automatically opens a GDB debug server to which you can connect if
needed, for complete control, as follows:
```shell
arm-none-eabi-gdb /path/to/compiled/binary_with_symbols.elf
```
Within GDB, run the following command to connect:
`target extended-remote localhost:3333`

## CLion integration
TODO

# Examples
The repository includes example code under `examples/`. Refer to each example's
README files for details on building.

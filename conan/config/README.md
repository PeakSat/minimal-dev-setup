## Conan/CMake configuration for SAMV71

This config is made up of two separate parts:
- a Conan profile for "baremetal-samv71-armv7" (to declare the GNU Arm compiler)
- a CMake toolchain file (samv71_toolchain.cmake) (to set up correct
  flags/linking details)

The toolchain file is automatically utilized by the Conan profile.
This split is made because of limitations of Conan's support for
cross-compilation/embedded use cases. Namely:
- Conan assumes that the linker script, if specified in the profile, will
  be located within the central profile directory and never change. This
  is not ideal, as the linker script can and will differ per-project
  depending on its needs (e.g. if MPU is enabled).
- Conan has no support for dynamically querying the compiler/tools for
  details (e.g. sysroot, or necessary flags), which complicates portability.

# Installation

Assuming you are located within this directory:
```
conan config install .
```
will place the configuration files in your Conan home directory.

# Usage

Pass `-pr baremetal-gcc13-armv7` to any Conan command (`build`/`install`/whatever)

# Maintenance info

Try to keep dynamism to the minimum (prefer `set`, `add_compile_definitions`) etc.,
avoid `execute_process`.
This file is **prepended** to the generated `conan_toolchain.cmake`, therefore
compilers (variables such as `CMAKE_C_COMPILER` etc. are not yet available
in here so you can't really use them.

Do not add flags/settings other than the *bare minimum* for a program to
boot here. That is, additional warnings, disabling of optimizations or
project-specific stuff have no place here. If possible, append extra
settings using the project's CMakeLists file.

Document extensively the reason of any addition, using comments on the
toolchain file. If you can, source your claims (e.g. using a StackOverflow
link)

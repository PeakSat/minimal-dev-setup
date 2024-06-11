# Minimal bring-up project for ATSAMV71Q21B

This project contains the bare-minimum settings for bringing up a
SAMV71-series MCU (ATSAMV71Q21B) using ARM GCC and CMake.

For now, only the core is working. No peripheral clock management,
FPU, TCM or other fancy stuff here.

## Purpose

Up until now, we have been using a dummy MPLAB X project and the
Microchip Code Configurator (MCC) to create startup code for any new
MCU project. However, this situation is untenable for the following
reasons:

- MPLAB and MCC require very specific setups to work correctly, (Java 8, yuck)
  which may not be easy to setup in development machines with newer OSes.
  Even if somehow one could make MPLAB and the rest run, the tools tend to be
  very buggy (even on the supported configuration of Ubuntu 18.04) 

- Relying on a black-box, undocumented tool such as Harmony and MPLAB to
  generate startup code leaves one unable to troubleshoot easily when things
  inevitably go wrong. 

- No way to use version control and dependency management with MPLAB-generated
  code, which inevitably breaks the build all the time, as MCC updates happen
  on their own schedule. It is a common occurrence that developer machines have
  slightly different versions of MCC, causing hard-to-debug errors.

- The team relies on standard tools like CMake and gcc-arm-none-eabi.
  Microchip advertises support for GCC, but some crucial generated code
  (linker scripts, startup file) from MCC is made for their own compiler
  (XC32). Although XC32 code can be made to work with GCC, this work is
  manual (see `startup_gcc.c`) and needs to be done on each and every new
  project.

## Architecture

This setup relies directly on the Microchip SAMV71 DFP (Device Family Pack),
the set of headers, startup code, drivers and support files that are used to
talk to the hardware. When generating code, MCC behind the scenes includes
from this package all the files pertaining to each peripheral driver,
as well as the XC32-specific linker script and startup file. However,
the DFP contains all those support files for GCC, ARM clang, and lots of
other compilers apart from XC32.

It is **not** an undocumented feature -- Microchip explicitly advertises
them on their developer website: https://developerhelp.microchip.com/xwiki/bin/view/software-tools/x/projects/packs/dfps-introduction/ 

The only thing reused from MCC is the peripheral initialization code
(`SYS_Initialize()`). This is only some generic clock configuration and
register-setting code representing the user's choices in the MCC project
file. These files are very simple and use no compiler-specific info that
can't be automatically ignored by GCC.

With this approach:
- we keep the nice UI from MCC to set up our clocks and peripherals
- using the provided CMake toolchain file, the developer doesn't need to
  know anything apart from Modern CMake usage. All the details of how to
  compile each source file to please the linker, or how to link them so
  the software boots, are included within.
- we can version-control everything, from DFPs to MCC configurations,
  and minimize
- we minimize the use of black boxes. Every setting can have a known,
  documented purpose.

## Preparing the DFP

Download the following packages from https://packs.download.microchip.com/:
- `Microchip SAMV71 Series Device Support` version 4.9.117
- `CMSIS (Common Microcontroller Software Interface Standard)` version 5.4.0
- If building for the radiation-tolerant version, download `Microchip SAMV71-RT Series Device Support`
  version 1.0.120. Haven't tested this, but it seems to be a bit different
  from the ordinary SAMV71 package.

These are on purpose not the latest versions. MPLAB uses these exact versions
as of 10 June 2024, and in case of any upgrades always use the versions that latest
MPLAB uses. Both packages (CMSIS and the DFP) depend on each other, so they must
always be upgraded in tandem.

These .atpack files are merely renamed zip files. Unzip their contents into the
following paths (create them if non existent):
- `$CWD/lib/CMSIS/` for the CMSIS library
- `$CWD/lib/SAMV71_DFP/` for the main DFP

## Building

To build this, run the following:
- `cmake . -Bbuild -DCMAKE_TOOLCHAIN_FILE=./cmake/samv71-toolchain.cmake`
- `cd build`
- `make`

## Uploading

Assuming a common development board (Atmel SAMV71 Xplained Ultra), OpenOCD
can do this:
- `openocd -f ./atmel_samv71_xplained_ultra.cfg -c "program build/OBC_SOFTWARE.elf verify reset"`

## Debugging

After uploading, OpenOCD opens a gdbserver to which you can connect as follows:
- `arm-none-eabi-gdb ./build/OBC_SOFTWARE.elf`
- `target extended-remote localhost:3333`


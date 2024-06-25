# Executables for bare-metal can't be linked or run with
# the host platform's default settings, thus the CMake compiler
# test will always fail. Telling it to build a static library 
# will not invoke the linker and the test will pass.
# (ref https://stackoverflow.com/a/53635241)
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# This define is used by the DFP to specify the exact SAMV71 variant
# used.
add_compile_definitions("__ATSAMV71Q21B__")

#
# -= General compiler and linker settings =-
# 
# IMHO these are the absolute bare minimum and should be always on
# by default in every new project. You can always disable specific warnings
# through CMakeLists compiler options.
set(BASIC_WARNING_FLAGS "-Wall -Wextra -pedantic")

# Flags for CMake's 'Debug' preset.
# Explanation:
#   -g3: enable ALL the debug information. Plain -g is equivalent to only -g2.
#   -Og: optimize for debuggability. Better than -O0 because some opt passes
#        that can actually improve debuggability get completely disabled at -O0.
#   __DEBUG: Microchip-specific macro that gets enabled by MPLAB on debug mode.
#        Seems to add some extra software breakpoints for convenience, but not
#        100% sure. Kept for accuracy, disable if any problems.
# Refs:
# - https://gcc.gnu.org/onlinedocs/gcc/Debugging-Options.html
# - https://gcc.gnu.org/onlinedocs/gcc/Optimize-Options.html
set(DEBUG_FLAGS "-g3 -Og -D__DEBUG")

# Flags for CMake's 'Release' preset.
# Explanation:
#   -O3: enable most aggressive performance optimizations
set(RELEASE_FLAGS "-O3")

# Flags for CMake's 'MinSizeRel' preset.
# Explanation:
#   -Os: optimize for minimum size instead of execution speed.
set(MINSIZEREL_FLAGS "-Os")

# Flags for CMake's 'RelWithDebInfo' preset.
# Explanation:
#   -O2: less aggressive optimization (intended to be faster than -Og)
#   -g: generate default debug info (less than -g3)
set(RELWITHDEBINFO_FLAGS "-g -O2")

# Device-specific flags.
# Explanation:
#   -mcpu=cortex-m7: of course we are working with ARM Cortex M7 
#   -mthumb: enable the Thumb instruction set (smaller, faster instructions)
#   -mfloat-abi=hard: TODO add float support
#   -mfpu=fpv5-d16: TODO add float support
set(DEVICE_FLAGS "-mcpu=cortex-m7 -mthumb")
#add_compile_definitions("ARM_MATH_CM7" "ARM_MATH_MATRIX_CHECK" "ARM_MATH_ROUNDING" "__FPU_PRESENT=1")

# General linker configuration flags
# Explanation: (-Wl tells GCC to pass this flag to the linker)
#   --print-memory-usage: After linking, print a summary of the program's
#   RAM and ROM footprint
#   -Map: generate a linker report (mapfile) for the program. This contains
#   info such as memory layout, list of symbols, linked libraries etc. Useful for
#   solving linker errors or finding who's hogging memory.
# Refs:
# - https://interrupt.memfault.com/blog/get-the-most-out-of-the-linker-map-file
set(BASIC_LINKER_FLAGS "-Wl,--print-memory-usage -Wl,-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map")

# -= Booting settings =-
#
# Background:
#
#   All the flags before this section merely configure the compiler to provide
#   the bare minimum defaults for compiling and linking objects for the SAMV71
#   platform. However, this is the primordial world of bare metal -- nothing is
#   a given here, the MCU has no idea of the C runtime environment or even where
#   main() is! 
#
#   (ref: https://interrupt.memfault.com/blog/arm-cortex-m-exceptions-and-nvic)
#   What the MCU *does* know, though, is interrupts, because these can be
#   triggered by hardware. Each interrupt is assigned a unique number known as
#   'exception number'. Numbers from 1-15 are fixed and assigned by ARM, the rest
#   are up to the device's maker (Microchip). For example, the well-known HardFault
#   interrupt that gets triggered on fault conditions has exception number 3.
#
#   When an interrupt is triggered, its exception number is used as an index in
#   an array of function pointers known as the IVT (interrupt vector table). To
#   handle the interrupt, the MCU merely reads off the address that corresponds
#   to the exception number from the IVT and jumps to it. The IVT is always
#   located at offset 0 (the very beginning) of the executable's '.text' section.
#
#   Thus, when power is applied, the MCU follows this procedure:
#   - SP (stack pointer) = IVT[0] (index 0 reserved for initial SP value)
#   - PC (program counter) = IVT[1], (index 1: Reset_Handler)
#   - Start execution
#
#   Given all the above, in order for any C or C++ programs to be loadable at all
#   we need to provide a very minimal environment that satisfies the above
#   constraints. This environment is made from the following essential components:
#   - startup file: This is a specially written, device-specific C file that:
#     i) describes the layout of the IVT (handlers sorted by exception number) for
#     the device in a special (.vectors) section of the executable, as well as the
#     signatures of all possible interrupt handlers
#     ii) provides default implementations of the interrupt handlers and, most
#     importantly, of the reset handler called on power-on.
#     iii) declares external "marker" symbols used by the IVT description, such as
#     the main() function or '_sstack'/'_estack' (start/end of stack), in order for
#     the linker to place each section at the correct addresses.
#     
#     We use the default (startup_samv71q21b.c) provided by the DFP for our MCU.
#
#   - linker script: This describes:
#     i) locations of all basic sections (.text, .bss, .data) within the MCU
#     address space. 
#     For example, depending on the configuration of GPNVM register (ref), the
#     .text section must be placed at:
#     - Bit 1 set: 0x00400000 (boot from internal flash)
#     - Bit 1 clr: 0x00000000 (boot from ROM, default).
#       (Note: the GPNVM1 bit *must* be set on every flash session for the MCU to
#        boot from the flash (ref). If using the SAMV71 Xplained Ultra devboard,
#        OpenOCD will do this for you but in the OBC EQM/FM where the bare chip is
#        used this might not be automatic, so be careful.)
#
#     ii) layout of the contents of each section. For example, .text must begin
#     with the .vectors subsection (the IVT) as described above.
#
#     We use the default (samv71q21b_flash.ld) script provided by the DFP. It is
#     assumed to be located in the project root. You may need to change it if
#     using features such as memory protection (MPU) or TCM, so make sure you
#     know the language, it's not that complicated if you spend some time to
#     learn about ELF files and get used to the symbols/terminology.
#
# Explanation:
#    -T: Specifies location of linker script.
# Refs:
set(BOOT_LINKER_FLAGS "-Wl,-T${CMAKE_CURRENT_SOURCE_DIR}/samv71q21b_flash.ld")

# -= POSIX environment/libc settings =-
# 
# Background:
#   The ARM GCC toolchain (arm-none-eabi-gcc) comes with a port of the
#   'newlib-nano' libc implementation. This libc gets linked implicitly (unless
#   stopped by passing -nostdlib) and provides a default implementation of the
#   C runtime (crt0.S). We do want newlib because it provides nice things like
#   C++ support (without exceptions) that is hard to do on our own, and we're
#   not that starved for flash space.
#   
#   Although the default Reset_Handler implementation provided in the startup
#   file does all the chores like relocating the executable and IVT into RAM,
#   clearing the zero segment and initializing libc, some configuration is still
#   required before we're able to use it for our cases.
#   Namely, since C originated from POSIX, the user must provide definitions for
#   the following POSIX syscalls:
#   - _exit
#   - _write
#   - _close
#   - _read
#   - _lseek
#   - _sbrk
#
# Explanation:
#  - --defsym=__bss_start__/__bss_end__: The compiled version of newlib-nano included
#    with GCC (13.2 as of 2024-Jun-25) requires definitions for the symbols denoting
#    the start and end of .bss section, named __bss_start__ and __bss_end__ respectively.
#    However, the corresponding symbols in the startup file and linker script are _sbss and
#    _ebss, which causes a linker error. Although applying --gc-sections would technically
#    fix the issue (especially if libc is not used at all), the definition is kept for
#    explicitness.
#  - --specs=nosys.specs (TODO)
# Refs (TODO):
# - https://web.archive.org/web/20230103002604/https://ww1.microchip.com/downloads/aemDocuments/documents/OTH/ProductDocuments/LegacyCollaterals/Frequently-Asked-Questions-4.9.3.26.txt
set(LIBC_LINKER_FLAGS "-Wl,--defsym=__bss_start__=_sbss -Wl,--defsym=__bss_end__=_ebss")

# -= Advanced optimization settings =-
#
# Section optimization flags.
# Explanation:
#   -ffunction/data-sections: place each function or constant data item inside
#    its own section within the ELF file. This allows the linker to perform a
#    simple link-time optimization by deleting any unused sections/symbols with
#    the -Wl,--gc-sections` flag, resulting in smaller binaries.
#
#    NOTE: Disabling this might introduce linker errors, due to the crt0.S
#    file (C runtime) having references to missing syscall implementations that
#    get removed by --gc-sections at link time.
set(SECTION_OPT_FLAGS "-ffunction-sections -fdata-sections")
set(SECTION_LINK_FLAGS "-Wl,--gc-sections")

# Default C compiler flags
set(CMAKE_C_FLAGS_DEBUG_INIT "${BASIC_WARNING_FLAGS} ${DEBUG_FLAGS}")
set(CMAKE_C_FLAGS_DEBUG "${CMAKE_C_FLAGS_DEBUG_INIT}" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELEASE_INIT "${BASIC_WARNING_FLAGS} ${RELEASE_FLAGS}")
set(CMAKE_C_FLAGS_RELEASE "${CMAKE_C_FLAGS_RELEASE_INIT}" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_MINSIZEREL_INIT "${BASIC_WARNING_FLAGS} ${MINSIZEREL_FLAGS}")
set(CMAKE_C_FLAGS_MINSIZEREL "${CMAKE_C_FLAGS_MINSIZEREL_INIT}" CACHE STRING "" FORCE)
set(CMAKE_C_FLAGS_RELWITHDEBINFO_INIT "${BASIC_WARNING_FLAGS} ${RELWITHDEBINFO_FLAGS}")
set(CMAKE_C_FLAGS_RELWITHDEBINFO "${CMAKE_C_FLAGS_RELWITHDEBINFO_INIT}" CACHE STRING "" FORCE)
# Default C++ compiler flags
set(CMAKE_CXX_FLAGS_DEBUG_INIT "${CMAKE_C_FLAGS_DEBUG_INIT}")
set(CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG_INIT}" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_RELEASE_INIT "${CMAKE_C_FLAGS_RELEASE_INIT}")
set(CMAKE_CXX_FLAGS_RELEASE "${CMAKE_CXX_FLAGS_RELEASE_INIT}" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_MINSIZEREL_INIT "${CMAKE_C_FLAGS_MINSIZEREL_INIT}")
set(CMAKE_CXX_FLAGS_MINSIZEREL "${CMAKE_CXX_FLAGS_MINSIZEREL_INIT}" CACHE STRING "" FORCE)
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT "${CMAKE_C_FLAGS_RELWITHDEBINFO_INIT}")
set(CMAKE_CXX_FLAGS_RELWITHDEBINFO "${CMAKE_CXX_FLAGS_RELWITHDEBINFO_INIT}" CACHE STRING "" FORCE)

string(CONCAT CMAKE_C_FLAGS "${DEVICE_FLAGS} ${SECTION_OPT_FLAGS}")
string(CONCAT CMAKE_CXX_FLAGS "${DEVICE_FLAGS} ${SECTION_OPT_FLAGS}")

string(CONCAT CMAKE_EXE_LINKER_FLAGS "${BASIC_LINKER_FLAGS} ${BOOT_LINKER_FLAGS} ${LIBC_LINKER_FLAGS} ${SECTION_LINK_FLAGS}")

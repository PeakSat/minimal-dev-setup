cmake_minimum_required(VERSION 3.19.2)

project(OBC_SOFTWARE C CXX ASM)

add_library(CMSIS_Core INTERFACE) # this is only headers
target_include_directories(CMSIS_Core INTERFACE lib/CMSIS/CMSIS/Core/Include/)

add_library(SAMV71Q21B_DFP OBJECT) # if made a static library the linker will ignore the startup file
target_include_directories(SAMV71Q21B_DFP PUBLIC lib/SAMV71_DFP/samv71b/include/)
target_sources(SAMV71Q21B_DFP
	PRIVATE 
	lib/SAMV71_DFP/samv71b/gcc/gcc/startup_samv71q21b.c
)
target_compile_definitions(SAMV71Q21B_DFP PUBLIC "__ATSAMV71Q21B__") # MPLAB propagates this to all files, idk why yet. certainly is used to select the exact SAMV71 variant from the DFP
target_link_libraries(SAMV71Q21B_DFP PRIVATE CMSIS_Core)
file(REAL_PATH lib/SAMV71_DFP/samv71b/gcc/gcc/samv71q21b_flash.ld LINKER_SCRIPT_ABSPATH)
set_target_properties(SAMV71Q21B_DFP PROPERTIES LINKER_SCRIPT_PATH ${LINKER_SCRIPT_ABSPATH})

add_executable(${PROJECT_NAME}.elf)
get_target_property(LINKER_SCRIPT SAMV71Q21B_DFP LINKER_SCRIPT_PATH)
target_include_directories(${PROJECT_NAME}.elf PRIVATE include/)
target_sources(${PROJECT_NAME}.elf PRIVATE src/main.c)
target_link_libraries(${PROJECT_NAME}.elf PRIVATE SAMV71Q21B_DFP CMSIS_Core)
target_link_options(${PROJECT_NAME}.elf
        PRIVATE
        "LINKER:--gc-sections" # without this linking fails with 'undefined reference to __bss_start/__bss_end'. MPLAB also passes this
        #"LINKER:--print-memory-usage"
        "--specs=nosys.specs" # stubs out a bunch of system functions (write, close, lread, sbrk) that are OS-dependent. where we're going there's no such luxury such as an OS
        #"LINKER:-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map"
        "LINKER:-T${LINKER_SCRIPT}" # specify how each section will be laid out
)
#get_target_property(LINKER_SCRIPT SAMV71Q21B_DFP LINKER_SCRIPT_PATH)
#set_target_properties(SAMV71Q21B_DFP PROPERTIES LINK_DEPENDS ${LINKER_SCRIPT})
#target_compile_definitions(${PROJECT_NAME}.elf "ARM_MATH_CM7" "ARM_MATH_MATRIX_CHECK" "ARM_MATH_ROUNDING" "__FPU_PRESENT=1")

#add_library(SAMV71Q21B_DFP INTERFACE)
#target_include_directories(SAMV71Q21B_DFP INTERFACE src/packs/ATSAMV71Q21B_DFP/)

#add_library(SAMV71_Peripherals_Base)
#target_include_directories(SAMV71_Peripherals_Base PRIVATE src/config/default/)
#target_sources(SAMV71_Peripherals_Base
#        PRIVATE
#        src/config/default/peripheral/clk/plib_clk.c
#        src/config/default/peripheral/efc/plib_efc.c
#        src/config/default/peripheral/nvic/plib_nvic.c
#        src/config/default/peripheral/pio/plib_pio.c
#)
#target_link_libraries(SAMV71_Peripherals_Base PRIVATE SAMV71Q21B_DFP SAMV71Q21B_CMSIS)

#add_library(SAMV71_Peripherals_Systick)
#target_include_directories(SAMV71_Peripherals_Systick PRIVATE src/config/default/)
#target_sources(SAMV71_Peripherals_Systick
#        PRIVATE
#        src/config/default/peripheral/systick/plib_systick.c
#)
#target_link_libraries(SAMV71_Peripherals_Systick PRIVATE SAMV71Q21B_DFP SAMV71Q21B_CMSIS)

#add_library(SAMV71_DeviceConfig)
#target_include_directories(SAMV71_DeviceConfig PRIVATE src/config/default/)
#target_sources(SAMV71_DeviceConfig
#        PRIVATE
#        src/config/default/exceptions.c
#        src/config/default/initialization.c
#        src/config/default/interrupts.c
#        src/config/default/libc_syscalls.c
#        support/src_gcc_toolchain/startup_gcc.c
#        support/src_gcc_toolchain/libc_syscalls.c
#)
#target_link_libraries(SAMV71_DeviceConfig PRIVATE SAMV71Q21B_DFP SAMV71Q21B_CMSIS SAMV71_Peripherals_Base)

# Startup file for GCC, as used in peaksat/obc-software
#add_library(SAMV71_Startup)
#target_include_directories(SAMV71_Startup PRIVATE src/config/default/)
#target_sources(SAMV71_Startup
#        PRIVATE
#
#)
#target_link_libraries(SAMV71_Startup PRIVATE SAMV71Q21B_DFP SAMV71Q21B_CMSIS)

#add_executable(${PROJECT_NAME}.elf)
#target_include_directories(${PROJECT_NAME}.elf PRIVATE src/config/default/)
#target_sources(${PROJECT_NAME}.elf PRIVATE src/main.c)
#target_link_libraries(${PROJECT_NAME}.elf PRIVATE SAMV71_DeviceConfig SAMV71_Peripherals_Systick SAMV71_Peripherals_Base SAMV71Q21B_DFP SAMV71Q21B_CMSIS)
#target_link_options(${PROJECT_NAME}.elf
#        PRIVATE
#        "LINKER:-gc-sections"
#        "LINKER:--print-memory-usage"
#        "LINKER:-Map=${PROJECT_BINARY_DIR}/${PROJECT_NAME}.map"
#        "LINKER:-T${CMAKE_SOURCE_DIR}/support/src_gcc_toolchain/ATSAMD21J18A.ld"
#        #"LINKER:-T${CMAKE_SOURCE_DIR}/support/ATSAMV71Q21B.ld"
#)
#target_compile_definitions(${PROJECT_NAME}.elf PRIVATE "ARM_MATH_CM7" "ARM_MATH_MATRIX_CHECK" "ARM_MATH_ROUNDING" "__FPU_PRESENT=1")

#add_compile_definitions(LOGLEVEL_TRACE)

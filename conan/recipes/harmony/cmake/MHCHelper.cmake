include(FindJava)
include(UseJava)
#include(FindPackageHandleStandardArgs)

# CMake integration for Harmony 3 Configurator
# Author: Grigoris Pavlakis <grigpavl@ece.auth.gr>, <g.pavlakis@spacedot.gr>
#
# Sources:
# https://developerhelp.microchip.com/xwiki/bin/view/software-tools/harmony/archive/mhc-overview/

# From Microchip documentation, Java is needed for MHC
find_package(Java 1.8 COMPONENTS Runtime REQUIRED)
if (NOT Java_FOUND)
    message(FATAL_ERROR "Java 8 or later is needed for MHC")
endif ()
if (Java_VERSION_MAJOR GREATER 8)
    message(STATUS "Using Java ${Java_VERSION} for MHC. In case of problems, try Java 8.")
endif ()

# From Microchip documentation, package names of MHC components.
# A "package" is basically a Git repo cloned by the "Content Manager" in a
# subdirectory with its name. These names are expected by MHC as they are.
set(HARMONY_MHC_DIRNAME "mhc")
set(HARMONY_DEV_PACKS_DIRNAME "dev_packs")
set(HARMONY_CSP_DIRNAME "csp")

# HACK: The <blablabla_INCLUDE_DIR> is always defined for CMake builds to be
# equal to $conan_package_dir/include, even if no headers are specified. Going
# one level back we can get the actual Harmony root. Note that 'harmony' is in
# small letters because it is derived from the Conan package name. 
cmake_path(GET harmony_INCLUDE_DIR PARENT_PATH HARMONY_FW_ROOT)

# Sanity check: Verify that the detected MHC dir at least contains a mhc.jar file
find_jar(HARMONY_MHC_EXECUTABLE_JAR NAMES "mhc" PATHS "${HARMONY_FW_ROOT}/${HARMONY_MHC_DIRNAME}")
if (HARMONY_MHC_EXECUTABLE_JAR STREQUAL "HARMONY_MHC_EXECUTABLE_JAR-NOTFOUND")
    message(FATAL_ERROR "mhc.jar not found at path ${HARMONY_FW_ROOT}/${HARMONY_MHC_DIRNAME}/ !")
else ()
    # hide mhc's variable from public view to prevent confusion
    mark_as_advanced(HARMONY_MHC_EXECUTABLE_JAR)
endif ()

# the slash is important in -fw! (otherwise MHC won't recognise parts of the root)
# workdir set to within MHC, it is MHC's baked-in assumption that people will cd to it
# and run it by hand
add_custom_target(mcu_config
        COMMAND "${Java_JAVA_EXECUTABLE}" "-jar" "${HARMONY_MHC_EXECUTABLE_JAR}" "-fw=${HARMONY_FW_ROOT}/" "-mode=gui"
        COMMENT "Launching MHC..."
        WORKING_DIRECTORY "${HARMONY_FW_ROOT}/${HARMONY_MHC_DIRNAME}"
        VERBATIM
)

function(add_harmony_config)
    cmake_parse_arguments(HARMONY_MHC "" "MCU_MODEL" "YAML_FILES" "${ARGN}")
    # STEP 1: sanitization
    # project.yml and settings.yml files contain PC-specific paths,
    # and are not portable between computers. GraphSettings.yml on the other
    # hand, although portable, can be easily generated by CMake during the
    # configure step, allowing us to use an MHC export dir immediately.
    list(FILTER HARMONY_MHC_YAML_FILES EXCLUDE REGEX "^.*project|settings|GraphSettings\.yml")

    # we don't support any other MCU models, but could be a nice extension and
    # being defensive costs nothing
    if (NOT HARMONY_MHC_MCU_MODEL STREQUAL "ATSAMV71Q21B")
        message(FATAL_ERROR "Unknown MCU: ${HARMONY_MHC_MCU_MODEL}")
    endif ()

    foreach (YAML_FILE IN LISTS HARMONY_MHC_YAML_FILES)
        # use absolute paths (with resolved links) for normalization purposes
        file(REAL_PATH ${YAML_FILE} _yaml_realpath)
        list(APPEND HARMONY_MHC_YAML_ABSPATHS ${_yaml_realpath})
    endforeach ()

    # STEP 1.1: change tracking - "config ID"
    # calculate SHA256-hash-of-SHA256 hashes of the involved files. any unchanged
    # configs should be located in the same directory
    foreach (YAML_FILE IN LISTS HARMONY_MHC_YAML_ABSPATHS)
        file(SHA256 ${YAML_FILE} _hash)
        list(APPEND _yml_hashes ${_hash})
        # mark explicitly as configure-time deps, to rerun CMake in case of any change
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${YAML_FILE}")
    endforeach ()
    list(JOIN _yml_hashes "" _yml_hash_concat)
    string(SHA256 HARMONY_MHC_CONFIG_ID ${_yml_hash_concat})

    # STEP 2: Create working directory and copy files into expected structure
    set(HARMONY_MHC_GEN_WORKDIR "${CMAKE_CURRENT_BINARY_DIR}/Generated/MHC-${HARMONY_MHC_CONFIG_ID}/")
    set(HARMONY_MHC_CONFIG_DIR "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/default.mhc/")
    file(MAKE_DIRECTORY "${HARMONY_MHC_GEN_WORKDIR}")
    file(MAKE_DIRECTORY "${HARMONY_MHC_CONFIG_DIR}")
    foreach (YAML_FILE IN LISTS HARMONY_MHC_YAML_ABSPATHS)
        configure_file(${YAML_FILE} "${HARMONY_MHC_CONFIG_DIR}" COPYONLY)
    endforeach ()

    # STEP 2.1: Generate project.yml/settings.yml (they contain Conan-specific paths different on each PC)
    set(HARMONY_MHC_SETTINGS_YML_CMSISPATH "${HARMONY_FW_ROOT}/${HARMONY_DEV_PACKS_DIRNAME}/arm/CMSIS/${CMSIS_VERSION_STRING}")
    set(HARMONY_MHC_SETTINGS_YML_DFPPATH "${HARMONY_FW_ROOT}/${HARMONY_DEV_PACKS_DIRNAME}/Microchip/SAMV71_DFP/${SAMV71-DFP_VERSION_STRING}/samv71b/atdf/${HARMONY_MHC_MCU_MODEL}.atdf")
    cmake_path(RELATIVE_PATH HARMONY_MHC_SETTINGS_YML_CMSISPATH BASE_DIRECTORY ${HARMONY_FW_ROOT})
    cmake_path(RELATIVE_PATH HARMONY_MHC_SETTINGS_YML_DFPPATH BASE_DIRECTORY ${HARMONY_FW_ROOT})
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/project.yml.in" "${HARMONY_MHC_CONFIG_DIR}/project.yml")
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/settings.yml.in" "${HARMONY_MHC_CONFIG_DIR}/settings.yml")
    configure_file("${CMAKE_CURRENT_FUNCTION_LIST_DIR}/GraphSettings.yml.in" "${HARMONY_MHC_CONFIG_DIR}/GraphSettings.yml")

    # STEP 3: Generate code
    # Basic CMake rule: All source file names must be known to CMake before build
    # system generation. Normally we would use add_custom_command() to generate
    # our files at build time and track them this way. However, we have no way of
    # knowing the exact file names. Therefore, generating at configure time and
    # globbing the generated files is the only way to do our job here.
    message(STATUS "Generating Harmony source files for configuration...")
    execute_process(
            COMMAND "${Java_JAVA_EXECUTABLE}" "-jar" "${HARMONY_MHC_EXECUTABLE_JAR}" "-fw=${HARMONY_FW_ROOT}/" "-mode=gen" "-c=${HARMONY_MHC_CONFIG_DIR}"
            WORKING_DIRECTORY "${HARMONY_FW_ROOT}/${HARMONY_MHC_DIRNAME}"
            OUTPUT_QUIET
            COMMAND_ERROR_IS_FATAL ANY
    )
    # we don't use CONFIGURE_DEPENDS because the YAML files are marked as such,
    # thus only changes to them will force a reconfiguration
    file(GLOB HARMONY_MHC_PERIPHERAL_DRIVER_SRCS "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/peripheral/*/*.c")

    # STEP 4: Remove the 'packs' dir
    # This folder is copy-pasted from the SAMV71 DFP. Since the Conan package is the
    # 'source of truth', removing the folder forces CMake to use Conan's version,
    # making the DFP dependency explicit and letting CLion know of the *actual* file used
    # in compilation.
    file(REMOVE_RECURSE "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/packs/")

    add_library(mhc-gen-plib)
    target_include_directories(mhc-gen-plib
            PUBLIC "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/peripheral/"
            INTERFACE "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/"
            PRIVATE "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/"
    )
    target_sources(mhc-gen-plib PRIVATE ${HARMONY_MHC_PERIPHERAL_DRIVER_SRCS})
    target_link_libraries(mhc-gen-plib PRIVATE samv71-dfp::Core)

    add_library(mhc-gen-irq)
    target_include_directories(mhc-gen-irq PRIVATE "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/")
    target_sources(mhc-gen-irq
            PRIVATE
                "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/interrupts.c"
                "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/exceptions.c"
    )
    target_link_libraries(mhc-gen-irq PRIVATE samv71-dfp::Core)

    add_library(mhc-gen-sysinit)
    target_include_directories(mhc-gen-sysinit PRIVATE "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/")
    target_sources(mhc-gen-sysinit PRIVATE "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/initialization.c")
    target_link_libraries(mhc-gen-sysinit PRIVATE samv71-dfp::Core mhc-gen-plib)

    # TODO: support multiple, named configurations as completely separate target sets and generation dirs
    add_library(Harmony::PeripheralDrivers ALIAS mhc-gen-plib)
    add_library(Harmony::Interrupts ALIAS mhc-gen-irq)
    add_library(Harmony::SysInit ALIAS mhc-gen-sysinit)

endfunction()

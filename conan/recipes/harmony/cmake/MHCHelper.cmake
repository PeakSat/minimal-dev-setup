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
endif()
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
else()
    # hide mhc's variable from public view to prevent confusion
    mark_as_advanced(HARMONY_MHC_EXECUTABLE_JAR)
endif ()

# the slash is important in -fw! (otherwise MHC won't recognise parts of the root)
# workdir set to within MHC, it is MHC's baked-in assumption that people will cd to it
# and run it by hand
add_custom_target(mcuconfig 
    COMMAND "${Java_JAVA_EXECUTABLE}" "-jar" "${HARMONY_MHC_EXECUTABLE_JAR}" "-fw=${HARMONY_FW_ROOT}/" "-mode=gui"
    WORKING_DIRECTORY "${HARMONY_FW_ROOT}/${HARMONY_MHC_DIRNAME}"
    VERBATIM
)

function(add_harmony_config _targetname _configdir)
    cmake_path(GET "${_configdir}" FILENAME MHC_CONFIG_DIR_NAME)
    file(REAL_PATH "${_configdir}" MHC_CONFIG_DIR_ABSPATH)

    string(SHA1 MHC_CONFIG_DIR_ABSPATH_HASH "${MHC_CONFIG_DIR_ABSPATH}")

    set(MHC_OUTPUT_PATH "${CMAKE_CURRENT_BINARY_DIR}/Generated/MHC-${MHC_CONFIG_DIR_NAME}-${MHC_CONFIG_DIR_ABSPATH_HASH}")
#    # copy given config to internal dir, blasting any previous ones
    file(REMOVE_RECURSE ${MHC_OUTPUT_PATH})
    file(COPY ${MHC_CONFIG_DIR_ABSPATH} DESTINATION "${MHC_OUTPUT_PATH}/firmware/src/config/${MHC_CONFIG_DIR_NAME}/")

endfunction()

# IMPORTANT: CRITICAL TRICKERY AHEAD
# MHC expects the CSP (chip support package, aka peripheral drivers) and the DFP
# (device family package) to be located within the framework path at:
# - $HARMONY_FW_DIR/csp for the CSP
# - $HARMONY_FW_DIR/dev_packs/arm/CMSIS/<VERSION> for the CMSIS package
# - $HARMONY_FW_DIR/dev_packs/Microchip/<DFP_NAME>/<VERSION> for the DFP.
#
# This assumption is so heavily baked into MHC, to the point that it
# crashes/misbehaves/fails in weird and horrible ways when loading a given project,
# despite supposedly offering a choice for alternative paths for the CSP and DFP.
#
# The contents of the framework path are normally maintained by the Content Manager,
# but:
# - it's way too heavy, complex and buggy for what it does (it clones Git repos)
# - it doesn't let us control versions for MHC, CSP and DFP, which results in
#   breaking builds as different dev setups may have slightly different versions
#   of each component.
#
# Since we want the CSP and DFP versions to be externally controlled, e.g. via Conan,
# CMake temporarily manipulates the framework path using symlinks to the version-
# controlled CSP and DFP, so as to fool MHC into thinking it resides on an actual
# framework path as usually done by the Content Manager.
#
# These assumptions are made for this trickery to work:
# - $HARMONY_FW_DIR is user-writable
# - $HARMONY_FW_DIR contains nothing else except the "mhc" directory with the
#   MHC configurator
# - $HARMONY_FW_DIR shall only be modified by CMake, and strictly follows the
#   structure described above.
#
# IDEA: why not just pass an MHC_DIR and use said path to entirely fake HARMONY_FW_DIR
# IDEA: package up each Harmony component into Conan (they are all versioned) and
# create for MHC a cmake file which will trick it into using the fake environment
# we created
#
# Integrating into Conan is not without risks - it's easier to replace a bunch of
# CMake targets 

#if(MHC_FOUND)
#    cmake_path(GET HARMONY_MHC_EXECUTABLE_JAR PARENT_PATH HARMONY_MHC_DIR)
#    set(HARMONY_FAKE_FW_PATH "${CMAKE_CURRENT_BINARY_DIR}/Generated/HarmonyFwPath/") # MHC-${MHC_CONFIG_NAME_NOEXT}-${MHC_CONFIG_DIR_ABSPATH_HASH}")

#    if (NOT EXISTS HARMONY_FAKE_FW_PATH)
#        file(MAKE_DIRECTORY "${HARMONY_FAKE_FW_PATH}")
#        file(MAKE_DIRECTORY "${HARMONY_FAKE_FW_PATH}/dev_packs/arm/CMSIS")
#        file(MAKE_DIRECTORY "${HARMONY_FAKE_FW_PATH}/dev_packs/Microchip/SAMV71_DFP")
#        file(CREATE_LINK "${HARMONY_MHC_DIR}" "${HARMONY_FAKE_FW_PATH}/${HARMONY_MHC_DIRNAME}" SYMBOLIC)
#        file(CREATE_LINK "${CMAKE_SOURCE_DIR}/lib/csp/" "${HARMONY_FAKE_FW_PATH}/csp" SYMBOLIC)
#        file(CREATE_LINK "${CMAKE_SOURCE_DIR}/lib/CMSIS/" "${HARMONY_FAKE_FW_PATH}/dev_packs/arm/CMSIS/5.4.0" SYMBOLIC)
#        file(CREATE_LINK "${CMAKE_SOURCE_DIR}/lib/SAMV71_DFP/" "${HARMONY_FAKE_FW_PATH}/dev_packs/Microchip/SAMV71_DFP/8.9.110" SYMBOLIC)
#    endif ()
#endif ()
# All Harmony packages assume that:
# - each is contained in its own folder, named after the package
# - all of them are located within a directory that Microchip calls the
#   "framework path".
# The framework path by default is $HOME/Harmony3 on Linux, but can be set
## by the "HARMONY_FW_DIR" variable.
#set(HARMONY_FW_ABSPATH "")
#if (${HARMONY_FW_DIR})
#    get_filename_component(HARMONY_FW_ABSPATH "${HARMONY_FW_DIR}" REALPATH)
#else ()
#    get_filename_component(HARMONY_FW_ABSPATH "$ENV{HOME}/Harmony3" REALPATH)
#endif ()


#function(add_harmony_config _targetname _cfgdir)

#
#    # set up the fake symlinks (HARMONY_ROOT must be writable)
#    execute_process(
##            OUTPUT ${MHC_OUTPUT_PATH}
#            COMMAND "${Java_JAVA_EXECUTABLE} -jar ${MHC_EXECUTABLE_JAR} -fw=${HARMONY_ROOT_ABSPATH} -mode=gen -c ${MHC_OUTPUT_PATH}/firmware/src/config/${MHC_CONFIG_NAME_NOEXT}/${MHC_CONFIG_NAME_NOEXT}.mhc"
#            WORKING_DIRECTORY "${HARMONY_ROOT_ABSPATH}/mhc"
#            OUTPUT_VARIABLE MHC_RES
#            COMMAND_ECHO STDOUT
#    )
#    message(STATUS "MHC-RES: ${MHC_RES}")
#endfunction()
    
# NOTE: we need to make sure that this runs after find_package(CSP)
# has run, in order to create the fake symlinks and then tear them down

# MHC (Microchip Harmony Configurator) is a java program. Supported
# officially on 8 only, but no problems found with up to Java 17
#find_package(Java 1.8 COMPONENTS Runtime REQUIRED)
#find_program(MHC NAMES "mhc.jar" PATHS "${HARMONY_DIR}/mhc/")

#find_package_handle_standard_args(Harmony REQUIRED_VARS MHC)

#if (MHC)
    # hide MHC's variable from public view to prevent confusion
    #    mark_as_advanced(MHC)
    # grab prefix, library flags and compiler flags
    #    execute_process(COMMAND "${Java_JAVA_EXECUTABLE}" "-jar ${MHC_JAR}" "-mode=gui" "-fw=${HARMONY_DIR}" OUTPUT_STRIP_TRAILING_WHITESPACE)
    #execute_process(COMMAND "${OTAWA_CONFIG_EXECUTABLE}" "--libs" "-r" OUTPUT_VARIABLE OTAWA_LDFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
    #execute_process(COMMAND "${OTAWA_CONFIG_EXECUTABLE}" "--prefix" OUTPUT_VARIABLE OTAWA_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
    #separate_arguments(OTAWA_CFLAGS UNIX_COMMAND ${OTAWA_CFLAGS})
    #separate_arguments(OTAWA_LDFLAGS UNIX_COMMAND ${OTAWA_LDFLAGS})
    #endif()


#if (OTAWA_FOUND AND NOT TARGET OTAWA::OTAWA)
#    add_library(OTAWA::OTAWA INTERFACE IMPORTED)
#    target_compile_options(OTAWA::OTAWA INTERFACE "${OTAWA_CFLAGS}")
#    target_link_options(OTAWA::OTAWA INTERFACE "${OTAWA_LDFLAGS}")
#    target_include_directories(OTAWA::OTAWA INTERFACE "${OTAWA_PREFIX}/include/")
#endif ()


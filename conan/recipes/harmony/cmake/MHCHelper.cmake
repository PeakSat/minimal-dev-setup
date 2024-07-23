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
    # and are not portable between computers. CMake will create them for the build.
    list(FILTER HARMONY_MHC_YAML_FILES EXCLUDE REGEX "^.*project|settings\.yml")

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

    #    if (NOT EXISTS "Graph")
    #        # NOTE: GraphSettings.yml must be present! I think this records the connections
    # between peripherals (PLIB) and
    #        drivers.
    #    endif ()

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
    string(SHA256 HARMONY_MHC_CONFIG_ID _yml_hash_concat)

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
    # TODO: restrict header access
    target_include_directories(mhc-gen-plib PUBLIC "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/")
    target_sources(mhc-gen-plib PRIVATE ${HARMONY_MHC_PERIPHERAL_DRIVER_SRCS})
    target_link_libraries(mhc-gen-plib PRIVATE samv71-dfp::Core)

    add_library(mhc-gen-irq)
    target_include_directories(mhc-gen-irq PUBLIC "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/")
    target_sources(mhc-gen-irq
            PRIVATE
                "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/interrupts.c"
                "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/exceptions.c"
    )
    target_link_libraries(mhc-gen-irq PRIVATE samv71-dfp::Core)

    add_library(mhc-gen-sysinit)
    target_include_directories(mhc-gen-sysinit PUBLIC "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/")
    target_sources(mhc-gen-sysinit PRIVATE "${HARMONY_MHC_GEN_WORKDIR}/firmware/src/config/default/initialization.c")
    target_link_libraries(mhc-gen-sysinit PRIVATE samv71-dfp::Core mhc-gen-plib)

    # TODO: support multiple, named configurations as completely separate target sets and generation dirs
    add_library(Harmony::PeripheralDrivers ALIAS mhc-gen-plib)
    add_library(Harmony::Interrupts ALIAS mhc-gen-irq)
    add_library(Harmony::SysInit ALIAS mhc-gen-sysinit)

endfunction()

# MHC generates an MPLAB project for XC32. Since we use GCC, I've observed that the only
# actually useful files for us are the generated peripheral drivers "peripheral/*" and
# their dependencies. All others are copy-pasted from the XC32-specific section of the
# SAMV71 DFP, and we have no use for them.

# TODO: explain why I'm using globbing here although it's bad (dirs only, CONFIGURE_DEPENDS)
# Sadly we don't have a way to predict the names of each PLIB directory,
# which means globbing, which is Really Bad (TM) for build system robustness. CMake's
# shtick is that knowing the list of source files beforehand (via CMakeLists) means that
# dependency tracking can be done easily and reliably
#  can predict the source files
#    # from the dir name, avoiding recursion and constraining the GLOB to only one level
#    #
# A common workaround for the main danger of GLOB (stale source files) is CONFIGURE_DEPENDS,
# introduced in CMake 3.20. CONFIGURE_DEPENDS will rerun the glob that specifies it on every build,
# just in case, and trigger a CMake rerun if changes in the glob's results are detected. Doing it only
# in directory level means that CMake reruns only if entirely new peripherals are introduced. Changing
# configs on the same peripheral should only trigger the generator and keep the actual list
# of source files stable the vast majority of the time.

#file(REAL_PATH ${_configdir} HARMONY_MHC_CONFIG_DIR_ABSPATH)
# STEP 1: sanity checks for the candidate directory.
# Invariants: dir must contain project.yml file AND project.yml must contain "projectName" string

#if(NOT EXISTS "${HARMONY_MHC_CONFIG_DIR_ABSPATH}/project.yml")
#    message(FATAL_ERROR "project.yml not found in directory ${HARMONY_MHC_CONFIG_DIR_ABSPATH}")
#endif()
#file(READ "${HARMONY_MHC_CONFIG_DIR_ABSPATH}/project.yml" HARMONY_MHC_PROJECT_YML_CONTENTS)
#string(FIND "${HARMONY_MHC_PROJECT_YML_CONTENTS}" "projectName" TMP_MATCH)
#if (${TMP_MATCH} EQUAL -1)
#    message(FATAL_ERROR "${HARMONY_MHC_CONFIG_DIR_ABSPATH} does not contain a valid MHC configuration")
#endif()

# -- ASSUMPTION: from now on _configdir is a directory containing a valid set of
# MHC configuration files (.yml)
# STEP 2: read off MHC config info (config name) with regex
#file(READ "${HARMONY_MHC_CONFIG_DIR_ABSPATH}/settings.yml" HARMONY_MHC_SETTINGS_YML_CONTENTS)
#message(STATUS "Found valid MHC configuration TODONAME")

# STEP 3: get a list of all yaml files within HARMONY_MHC_CONFIG_DIR_ABSPATH.
# HACK: Globbing is BAD. It breaks CMake's dependency tracking and makes builds
# unreliable because CMake has no way to know when files get added or removed.
# Despite this, I'm forced to use it here because I don't control the file names
# of the MHC files, and MHC generates a new yaml file for each instantiated component.
# - I can't know yaml filenames in advance
# - CONFIGURE_DEPENDS will force CMake to rerun the globs at build time and at least it won't
# be as broken as a plain glob, but is not a portable solution.
#file(GLOB HARMONY_MHC_CONFIG_USER_YAML "${HARMONY_MHC_CONFIG_DIR_ABSPATH}/*.yml" CONFIGURE_DEPENDS)
# STEP 3: Create working directory for configuration
#string(SHA1 HARMONY_MHC_CONFIG_DIR_ABSPATH_SHA1 "${HARMONY_MHC_CONFIG_DIR_ABSPATH}")
#set(HARMONY_MHC_CONFIG_WORKDIR "${CMAKE_CURRENT_BINARY_DIR}/Generated/MHC-TODONAME-${HARMONY_MHC_CONFIG_DIR_ABSPATH_SHA1}/")

# STEP 4: This is the tricky part: we have to create a pipeline that always runs before
# each build, and does the following:
# - copy all user configs in the proper places
# - do nothing
# - copy back workdir to user
# - codegen
# The pipeline must allow for reconfiguration with 'make mcu_reconfig'. When this is run:
# - copy all configs in the workdir
# - launch MHC using the workdir copy. saves go to this copy
# - copy back workdir to user
# - codegen

# STEP XX: Code generation, always last step
#add_custom_command(
#    COMMAND "${Java_JAVA_EXECUTABLE}" "-jar" "${HARMONY_MHC_EXECUTABLE_JAR}" "-fw=${HARMONY_FW_ROOT}/" "-mode=gen" "-c=${HARMONY_MHC_CONFIG_WORKDIR}"
#    DEPENDS ${}
#    WORKING_DIRECTORY "${HARMONY_FW_ROOT}/${HARMONY_MHC_DIRNAME}"
#    VERBATIM
#)
#set(HARMONY_MHC_CONFIG_DIR "mhc-config")
#set(HARMONY_MHC_CONFIG_PATH "${CMAKE_SOURCE_DIR}/${MHC_CONFIG_DIR}")

#if(EXISTS "${HARMONY_MHC_CONFIG_PATH}/project.yml")
#    file(READ "${HARMONY_MHC_CONFIG_PATH}/project.yml" HARMONY_MHC_PROJECT_FILE)
#    string(FIND "${HARMONY_MHC_PROJECT_FILE}" "projectName" TMP_MATCH)
#    if (${TMP_MATCH} EQUAL -1)
#        message(FATAL_ERROR "${HARMONY_MHC_CONFIG_PATH} doesn't contain a valid MHC configuration")
#    else()

#message(STATUS ${matchres})
#    message(STATUS "Probable MHC configuration detected. Enabling reconfig.")
#    add_custom_target(mcu_reconfig
#        COMMAND "${Java_JAVA_EXECUTABLE}" "-jar" "${HARMONY_MHC_EXECUTABLE_JAR}" "-fw=${HARMONY_FW_ROOT}/" "-mode=gui" "-c=${MHC_CONFIG_PATH}"
#        WORKING_DIRECTORY "${HARMONY_FW_ROOT}/${HARMONY_MHC_DIRNAME}"
#        VERBATIM
#)

#)
#else()
#    message(STATUS "Project does not contain MHC configuration, disabling reconfig. Place yaml files under ${MHC_CONFIG_PATH} and ensure the configuration name is set to 'default'")
#endif()


# ============= OLD BELOW - IGNORE ==================

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


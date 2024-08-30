# Structure loosely inspired from https://github.com/libhal/freertos/
# (Apache-licensed).
#
# We don't use it directly because that package is a bit too
# specific for use with 'libhal'

from conan import ConanFile
from conan.tools.files import get, save, copy
from conan.tools.cmake import CMake, cmake_layout
from conan.errors import ConanInvalidConfiguration

import os

class FreeRTOS(ConanFile):
    name = "freertos"
    version = "11.1.0"
    description = "Conan recipe for FreeRTOS"
    license = "MIT"
    homepage = "https://www.freertos.org"
    topics = ("freertos", "rtos", "threads", "tasks", "multithreading")

    settings = "build_type", "arch", "compiler"
    generators = "CMakeDeps", "CMakeToolchain"

    # BE CAREFUL! Options marked as "ANY" have no validation (apart from containing
    # a value) and are passed directly to the generated header file.
    # Unfortunately Conan doesn't support numerical options with ranges,
    # so we have to make do.

    options = {
        "FREERTOS_HEAP": ["NO_HEAP", 1, 2, 3, 4, 5],
        "USE_DEFAULT_CONFIGASSERT": [True, False],
        "configCPU_CLOCK_HZ": ["ANY"], #arm_unsigned_long_option,
        "configTICK_RATE_HZ": ["ANY"], #arm_int_option,
        "configUSE_PREEMPTION": [True, False],
        "configUSE_TIME_SLICING": [True, False],
        "configUSE_PORT_OPTIMIZED_TASK_SELECTION": [True, False],
        "configUSE_TICKLESS_IDLE": [True, False],
        "configMAX_PRIORITIES": ["ANY"], #arm_int_option,
        "configPRIO_BITS": ["ANY"], # arm_int_option
        "configMINIMAL_STACK_SIZE": ["ANY"], #arm_int_option,
        "configMAX_TASK_NAME_LEN": ["ANY"], #arm_int_option,
        "configMAX_TICK_TYPE_WIDTH_IN_BITS": ["TICK_TYPE_WIDTH_64_BITS"],
        "configIDLE_SHOULD_YIELD": [True, False],
        "configTASK_NOTIFICATION_ARRAY_ENTRIES": ["ANY"], # arm_int_option,
        "configQUEUE_REGISTRY_SIZE": ["ANY"], #arm_int_option,
        "configENABLE_BACKWARD_COMPATIBILITY": [True, False],
        "configNUM_THREAD_LOCAL_STORAGE_POINTERS": ["ANY"], #arm_int_option,
        "configUSE_MINI_LIST_ITEM": ["ANY"], #arm_int_option,
        "configSTACK_DEPTH_TYPE": ["uint8_t", "uint16_t", "uint32_t", "uint64_t", "size_t"],
        "configMESSAGE_BUFFER_LENGTH_TYPE": ["uint8_t", "uint16_t", "uint32_t", "uint64_t", "size_t"],
        "configHEAP_CLEAR_MEMORY_ON_FREE": [True, False],
        "configSTATS_BUFFER_MAX_LENGTH": ["ANY"], #arm_int_option,
        "configUSE_NEWLIB_REENTRANT": [True, False],
        "configUSE_TIMERS": [True, False],
        "configUSE_16_BIT_TICKS": [True, False],
        "configTIMER_TASK_PRIORITY": ["ANY"], #arm_int_option,
        "configTIMER_TASK_STACK_DEPTH": ["ANY"], #arm_int_option,
        "configTIMER_QUEUE_LENGTH": ["ANY"], #arm_int_option,
        "configUSE_EVENT_GROUPS": [True, False],
        "configUSE_STREAM_BUFFERS": [True, False],
        "configSUPPORT_STATIC_ALLOCATION": [True, False],
        "configSUPPORT_DYNAMIC_ALLOCATION": [True, False],
        "configTOTAL_HEAP_SIZE": ["ANY"], #arm_int_option,
        "configAPPLICATION_ALLOCATED_HEAP": [True, False],
        "configSTACK_ALLOCATION_FROM_SEPARATE_HEAP": [True, False],
        "configENABLE_HEAP_PROTECTOR": [True, False],
        "configKERNEL_INTERRUPT_PRIORITY": ["ANY"], #arm_int_option,
        "configMAX_SYSCALL_INTERRUPT_PRIORITY": ["ANY"], #arm_int_option,
        "configMAX_API_CALL_INTERRUPT_PRIORITY": ["ANY"], #arm_int_option,
        "configUSE_IDLE_HOOK": [True, False],
        "configUSE_TICK_HOOK": [True, False],
        "configUSE_MALLOC_FAILED_HOOK": [True, False],
        "configUSE_DAEMON_TASK_STARTUP_HOOK": [True, False],
        "configUSE_SB_COMPLETED_CALLBACK": [True, False],
        "configCHECK_FOR_STACK_OVERFLOW": [0, 1, 2], # 0=no check, 1=bounds check only, 2=check for stack corruption
        "configGENERATE_RUN_TIME_STATS": [True, False],
        "configUSE_TRACE_FACILITY": [True, False],
        "configUSE_STATS_FORMATTING_FUNCTIONS": [True, False],
        "configUSE_CO_ROUTINES": [True, False],
        "configMAX_CO_ROUTINE_PRIORITIES": ["ANY"], #arm_int_option,
        "configINCLUDE_APPLICATION_DEFINED_PRIVILEGED_FUNCTIONS": [True, False],
        "configTOTAL_MPU_REGIONS": ["ANY"], #arm_int_option,
        "configTEX_S_C_B_FLASH": ["ANY"], #arm_unsigned_long_option,
        "configTEX_S_C_B_SRAM": ["ANY"], #arm_unsigned_long_option,
        "configENFORCE_SYSTEM_CALLS_FROM_KERNEL_ONLY": [True, False],
        "configALLOW_UNPRIVILEGED_CRITICAL_SECTIONS": [True, False],
        "configUSE_MPU_WRAPPERS_V1": [True, False],
        "configPROTECTED_KERNEL_OBJECT_POOL_SIZE": ["ANY"], #arm_int_option,
        "configSYSTEM_CALL_STACK_SIZE": ["ANY"], #arm_int_option,
        "configENABLE_ACCESS_CONTROL_LIST": [True, False],
        "configRUN_MULTIPLE_PRIORITIES": [True, False],
        "configUSE_CORE_AFFINITY": [True, False],
        "configTASK_DEFAULT_CORE_AFFINITY": ["tskNO_AFFINITY"],
        "configUSE_TASK_PREEMPTION_DISABLE": [True, False],
        "configUSE_PASSIVE_IDLE_HOOK": [True, False],
        "configTIMER_SERVICE_TASK_CORE_AFFINITY": ["tskNO_AFFINITY"],
        "secureconfigMAX_SECURE_CONTEXTS": ["ANY"], #arm_int_option,
        "configKERNEL_PROVIDED_STATIC_MEMORY": [True, False],
        "configENABLE_TRUSTZONE": [True, False],
        "configRUN_FREERTOS_SECURE_ONLY": [True, False],
        "configENABLE_MPU": [True, False],
        "configENABLE_FPU": [True, False],
        "configENABLE_MVE": [True, False],
        "configCHECK_HANDLER_INSTALLATION": [True, False],
        "configUSE_TASK_NOTIFICATIONS": [True, False],
        "configUSE_MUTEXES": [True, False],
        "configUSE_RECURSIVE_MUTEXES": [True, False],
        "configUSE_COUNTING_SEMAPHORES": [True, False],
        "configUSE_QUEUE_SETS": [True, False],
        "configUSE_APPLICATION_TASK_TAG": [True, False],
        "configUSE_POSIX_ERRNO": [True, False],
        "INCLUDE_vTaskPrioritySet": [True, False],
        "INCLUDE_uxTaskPriorityGet": [True, False],
        "INCLUDE_vTaskDelete": [True, False],
        "INCLUDE_vTaskSuspend": [True, False],
        "INCLUDE_xResumeFromISR": [True, False],
        "INCLUDE_vTaskDelayUntil": [True, False],
        "INCLUDE_vTaskDelay": [True, False],
        "INCLUDE_xTaskGetSchedulerState": [True, False],
        "INCLUDE_xTaskGetCurrentTaskHandle": [True, False],
        "INCLUDE_uxTaskGetStackHighWaterMark": [True, False],
        "INCLUDE_xTaskGetIdleTaskHandle": [True, False],
        "INCLUDE_eTaskGetState": [True, False],
        "INCLUDE_xEventGroupSetBitFromISR": [True, False],
        "INCLUDE_xTimerPendFunctionCall": [True, False],
        "INCLUDE_xTaskAbortDelay": [True, False],
        "INCLUDE_xTaskGetHandle": [True, False],
        "INCLUDE_xTaskResumeFromISR": [True, False],
    }

    default_options = {
        "FREERTOS_HEAP": 3,
        "USE_DEFAULT_CONFIGASSERT": False,
        "configCPU_CLOCK_HZ": 20000000,
        "configTICK_RATE_HZ": 100,
        "configUSE_PREEMPTION": True,
        "configUSE_TIME_SLICING": False,
        "configUSE_PORT_OPTIMIZED_TASK_SELECTION": False,
        "configUSE_TICKLESS_IDLE": False,
        "configMAX_PRIORITIES": 5,
        "configPRIO_BITS": 3,
        "configMINIMAL_STACK_SIZE": 128,
        "configMAX_TASK_NAME_LEN": 16,
        "configMAX_TICK_TYPE_WIDTH_IN_BITS": "TICK_TYPE_WIDTH_64_BITS",
        "configIDLE_SHOULD_YIELD": True,
        "configTASK_NOTIFICATION_ARRAY_ENTRIES": 1, # 1
        "configQUEUE_REGISTRY_SIZE": 0, # 0
        "configENABLE_BACKWARD_COMPATIBILITY": False,
        "configNUM_THREAD_LOCAL_STORAGE_POINTERS": 0,
        "configUSE_MINI_LIST_ITEM": 1,
        "configSTACK_DEPTH_TYPE": "size_t",
        "configMESSAGE_BUFFER_LENGTH_TYPE": "size_t",
        "configHEAP_CLEAR_MEMORY_ON_FREE": True,
        "configSTATS_BUFFER_MAX_LENGTH": 0xFFFF, # (remember to print as hex)
        "configUSE_NEWLIB_REENTRANT": False,
        "configUSE_TIMERS": True,
        "configUSE_16_BIT_TICKS": False,
        "configTIMER_TASK_PRIORITY": 4, # = configMAX_PRIORITIES - 1
        "configTIMER_TASK_STACK_DEPTH": 128, # = configMINIMAL_STACK_SIZE
        "configTIMER_QUEUE_LENGTH": 10,
        "configUSE_EVENT_GROUPS": True,
        "configUSE_STREAM_BUFFERS": True,
        "configSUPPORT_STATIC_ALLOCATION": True,
        "configSUPPORT_DYNAMIC_ALLOCATION": True,
        "configTOTAL_HEAP_SIZE": 4096,
        "configAPPLICATION_ALLOCATED_HEAP": False,
        "configSTACK_ALLOCATION_FROM_SEPARATE_HEAP": False,
        "configENABLE_HEAP_PROTECTOR": False,
        "configKERNEL_INTERRUPT_PRIORITY": 0,
        "configMAX_SYSCALL_INTERRUPT_PRIORITY": 0,
        "configMAX_API_CALL_INTERRUPT_PRIORITY": 0,
        "configUSE_IDLE_HOOK": False,
        "configUSE_TICK_HOOK": False,
        "configUSE_MALLOC_FAILED_HOOK": False,
        "configUSE_DAEMON_TASK_STARTUP_HOOK": False,
        "configUSE_SB_COMPLETED_CALLBACK": False,
        "configCHECK_FOR_STACK_OVERFLOW": 2,
        "configGENERATE_RUN_TIME_STATS": False,
        "configUSE_TRACE_FACILITY": False,
        "configUSE_STATS_FORMATTING_FUNCTIONS": False,
        "configUSE_CO_ROUTINES": False,
        "configMAX_CO_ROUTINE_PRIORITIES": 1,
        "configINCLUDE_APPLICATION_DEFINED_PRIVILEGED_FUNCTIONS": False,
        "configTOTAL_MPU_REGIONS": 8,
        "configTEX_S_C_B_FLASH": 0x07, # 0x07UL (remember the hex and cast)
        "configTEX_S_C_B_SRAM": 0x07, # 0x07UL (remember the hex and cast)
        "configENFORCE_SYSTEM_CALLS_FROM_KERNEL_ONLY": True,
        "configALLOW_UNPRIVILEGED_CRITICAL_SECTIONS": False,
        "configUSE_MPU_WRAPPERS_V1": False,
        "configPROTECTED_KERNEL_OBJECT_POOL_SIZE": 10,
        "configSYSTEM_CALL_STACK_SIZE": 128,
        "configENABLE_ACCESS_CONTROL_LIST": True,
        "configRUN_MULTIPLE_PRIORITIES": False,
        "configUSE_CORE_AFFINITY": False,
        "configTASK_DEFAULT_CORE_AFFINITY": "tskNO_AFFINITY",
        "configUSE_TASK_PREEMPTION_DISABLE": False,
        "configUSE_PASSIVE_IDLE_HOOK": False,
        "configTIMER_SERVICE_TASK_CORE_AFFINITY": "tskNO_AFFINITY",
        "secureconfigMAX_SECURE_CONTEXTS": 5,
        "configKERNEL_PROVIDED_STATIC_MEMORY": True,
        "configENABLE_TRUSTZONE": True,
        "configRUN_FREERTOS_SECURE_ONLY": True,
        "configENABLE_MPU": True,
        "configENABLE_FPU": True,
        "configENABLE_MVE": True,
        "configCHECK_HANDLER_INSTALLATION": True,
        "configUSE_TASK_NOTIFICATIONS": True,
        "configUSE_MUTEXES": True,
        "configUSE_RECURSIVE_MUTEXES": True,
        "configUSE_COUNTING_SEMAPHORES": True,
        "configUSE_QUEUE_SETS": False,
        "configUSE_APPLICATION_TASK_TAG": False,
        "configUSE_POSIX_ERRNO": False,
        "INCLUDE_vTaskPrioritySet": True,
        "INCLUDE_uxTaskPriorityGet": True,
        "INCLUDE_vTaskDelete": True,
        "INCLUDE_vTaskSuspend": True,
        "INCLUDE_xResumeFromISR": True,
        "INCLUDE_vTaskDelayUntil": True,
        "INCLUDE_vTaskDelay": True,
        "INCLUDE_xTaskGetSchedulerState": True,
        "INCLUDE_xTaskGetCurrentTaskHandle": True,
        "INCLUDE_uxTaskGetStackHighWaterMark": False,
        "INCLUDE_xTaskGetIdleTaskHandle": False,
        "INCLUDE_eTaskGetState": False,
        "INCLUDE_xEventGroupSetBitFromISR": True,
        "INCLUDE_xTimerPendFunctionCall": False,
        "INCLUDE_xTaskAbortDelay": False,
        "INCLUDE_xTaskGetHandle": False,
        "INCLUDE_xTaskResumeFromISR": True
    }

    # Check the documentation for the rest of the available attributes
    def source(self):
        get(self, **self.conan_data["sources"][self.version], strip_root=True)

    def layout(self):
        cmake_layout(self)

    def generate(self):
        definitions = [
            f"#define {opt_name} {self._to_freertos_define(opt_name, opt_value)}"
            for opt_name, opt_value in self.options.items()
            if opt_name != "FREERTOS_HEAP"] # CMake option, not applicable in FreeRTOSConfig.h

        header_file = (
            f"#ifndef GEN_FREERTOSCONFIG_H\n"
            f"#define GEN_FREERTOSCONFIG_H\n\n"
            + "\n".join(definitions)
            + (
                "\n\n#define configASSERT( x ) if( ( x ) == 0 ) { taskDISABLE_INTERRUPTS(); for( ;; ); }\n\n"
                if self.options.get_safe("USE_DEFAULT_CONFIGASSERT")
                else ""
            )
            + f"\n\n#endif // GEN_FREERTOSCONFIG_H\n"
        )

        print(header_file)
        save(self, os.path.join(self.source_folder, "include/FreeRTOSConfig.h"), header_file)
        # let's reuse CMake's install machinery
        cmake_install_directive = (
            "\n\ninstall(TARGETS freertos_kernel)\n"
            "install(FILES $<TARGET_OBJECTS:freertos_kernel_port> DESTINATION lib)\n"
        )
        save(self, os.path.join(self.source_folder, "CMakeLists.txt"), cmake_install_directive, append=True)

    def build(self):
        cmake = CMake(self)
        freertos_cmake_variables = {
            "FREERTOS_PORT": self._get_freertos_port(),
            # deprecated in 11.1 but still supported in the foreseeable future,
            # and honestly let's not generate a CMakeLists.txt too until we are
            # forced to
            "FREERTOS_CONFIG_FILE_DIRECTORY": os.path.join(self.source_folder, "include/"),
            "CMAKE_C_OUTPUT_EXTENSION": "obj" # for consistency
        }
        heap_impl = self.options.get_safe("FREERTOS_HEAP")
        if heap_impl != "NO_HEAP":
            freertos_cmake_variables["FREERTOS_HEAP"] = int(str(heap_impl))

        cmake.configure(variables=freertos_cmake_variables)
        cmake.build()

    def package(self):
        cmake = CMake(self)
        cmake.install()
        # Included CMakeLists has no install target, so we just copy the
        # files ourselves.
        # Main FreeRTOS headers
        copy(self, "*.h", os.path.join(self.source_folder, "include"), os.path.join(self.package_folder, "include"))
        # Port-specific headers
        compiler_id, arch_id = self._get_freertos_port().split("_", 1)
        copy(self, f"portable/{compiler_id.upper()}/{arch_id}/r0p1/portmacro.h", self.source_folder, os.path.join(self.package_folder, "include"), keep_path=False)

    def package_info(self):
        self.cpp_info.includedirs = ['include']
        self.cpp_info.libdirs = ["lib"]
        self.cpp_info.libs = ["freertos_kernel"]
        self.cpp_info.objects = ["lib/port.c.obj"]
        self.cpp_info.set_property("cmake_target_name", "freertos")

    def _to_freertos_define(self, option_name, option_value):
        match option_value:
            case "True":
                return 1
            case "False":
                return 0
            case str(): #
                match option_name:
                    # These options are specially-cased to preserve
                    # casting/annotations as it was on original FreeRTOSConfig.h
                    case "configCPU_CLOCK_HZ":
                        return f"( (unsigned long ) {int(option_value)})"
                    case "configSTATS_BUFFER_MAX_LENGTH":
                        return hex(int(option_value))
                    case "configTEX_S_C_B_SRAM" | "configTEX_S_C_B_FLASH":
                        return f"{hex(int(option_value))}UL"

                return str(option_value)
            case _:
                raise ConanInvalidConfiguration(f"Invalid option {option_name}={option_value}")

    def _get_freertos_port(self):
        architecture = str(self.settings.arch)
        match architecture:
            case "cortex-m0" | "cortex-m0+":
                return "GCC_ARM_CM0"
            case "cortex-m3":
                return "GCC_ARM_CM3"
            case "cortex-m4":
                return "GCC_ARM_CM3"  # Use CM3's implementation for CM4 without FPU
            case "cortex-m4f":
                return "GCC_ARM_CM4F"
            # armv7 is Conan's default arch name we use everywhere else, and
            # let's not force users to carry around yet another file with custom
            # arch definitions
            case "cortex-m7" | "armv7":
                return "GCC_ARM_CM7"
            case _:
                raise ConanInvalidConfiguration(
                    f"The architecture '{architecture}' is not supported!"
                )

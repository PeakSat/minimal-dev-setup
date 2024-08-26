# Structure loosely inspired from https://github.com/libhal/freertos/
# (Apache-licensed).
#
# We don't use it directly because that package is a bit too
# specific for use with 'libhal'

from conan import ConanFile
from conan.tools.files import get
from conan.tools.cmake import CMake, cmake_layout
_default_freertosconfig_contents = """
        "#define configCPU_CLOCK_HZ    ( ( unsigned long ) 20000000 )",
        "#define configTICK_RATE_HZ                         100",
        "#define configUSE_PREEMPTION                       1", OK BOOL
        "#define configUSE_TIME_SLICING                     0", OK BOOL
        "#define configUSE_PORT_OPTIMISED_TASK_SELECTION    0", OK BOOL
        "#define configUSE_TICKLESS_IDLE                    0", OK BOOL
        "#define configMAX_PRIORITIES                       5",
        "#define configMINIMAL_STACK_SIZE                   128",
        "#define configMAX_TASK_NAME_LEN                    16",
        "#define configTICK_TYPE_WIDTH_IN_BITS              TICK_TYPE_WIDTH_64_BITS",
        "#define configIDLE_SHOULD_YIELD                    1", OK BOOL
        "#define configTASK_NOTIFICATION_ARRAY_ENTRIES      1",
        "#define configQUEUE_REGISTRY_SIZE                  0",
        "#define configENABLE_BACKWARD_COMPATIBILITY        0", OK BOOL
        "#define configNUM_THREAD_LOCAL_STORAGE_POINTERS    0",
        "#define configUSE_MINI_LIST_ITEM                   1",
        "#define configSTACK_DEPTH_TYPE                     size_t",
        "#define configMESSAGE_BUFFER_LENGTH_TYPE           size_t",
        "#define configHEAP_CLEAR_MEMORY_ON_FREE            1", OK BOOL
        "#define configSTATS_BUFFER_MAX_LENGTH              0xFFFF",
        "#define configUSE_NEWLIB_REENTRANT                 0", OK BOOL
        "#define configUSE_TIMERS                1", OK BOOL
        "#define configTIMER_TASK_PRIORITY       ( configMAX_PRIORITIES - 1 )",
        "#define configTIMER_TASK_STACK_DEPTH    configMINIMAL_STACK_SIZE",
        "#define configTIMER_QUEUE_LENGTH        10",
        "#define configUSE_EVENT_GROUPS    1", OK BOOL
        "#define configUSE_STREAM_BUFFERS    1", OK BOOL
        "#define configSUPPORT_STATIC_ALLOCATION              1", OK BOOL
        "#define configSUPPORT_DYNAMIC_ALLOCATION             1", OK BOOL
        "#define configTOTAL_HEAP_SIZE                        4096",
        "#define configAPPLICATION_ALLOCATED_HEAP             0",
        "#define configSTACK_ALLOCATION_FROM_SEPARATE_HEAP    0",
        "#define configENABLE_HEAP_PROTECTOR                  0", OK BOOL
        "#define configKERNEL_INTERRUPT_PRIORITY          0",
        "#define configMAX_SYSCALL_INTERRUPT_PRIORITY     0",
        "#define configMAX_API_CALL_INTERRUPT_PRIORITY    0",
        "#define configUSE_IDLE_HOOK                   0", OK BOOL
        "#define configUSE_TICK_HOOK                   0", OK BOOL
        "#define configUSE_MALLOC_FAILED_HOOK          0", OK BOOL
        "#define configUSE_DAEMON_TASK_STARTUP_HOOK    0", OK BOOL
        "#define configUSE_SB_COMPLETED_CALLBACK       0", OK BOOL
        "#define configCHECK_FOR_STACK_OVERFLOW        2",
        "#define configGENERATE_RUN_TIME_STATS           0", OK BOOL
        "#define configUSE_TRACE_FACILITY                0", OK BOOL
        "#define configUSE_STATS_FORMATTING_FUNCTIONS    0", OK BOOL 
        "#define configUSE_CO_ROUTINES              0", OK BOOL
        "#define configMAX_CO_ROUTINE_PRIORITIES    1",
        "#define configINCLUDE_APPLICATION_DEFINED_PRIVILEGED_FUNCTIONS    0", OK BOOL
        "#define configTOTAL_MPU_REGIONS                                   8",
        "#define configTEX_S_C_B_FLASH                                     0x07UL",
        "#define configTEX_S_C_B_SRAM                                      0x07UL",
        "#define configENFORCE_SYSTEM_CALLS_FROM_KERNEL_ONLY               1", OK BOOL
        "#define configALLOW_UNPRIVILEGED_CRITICAL_SECTIONS                0", OK BOOL
        "#define configUSE_MPU_WRAPPERS_V1                                 0", OK BOOL
        "#define configPROTECTED_KERNEL_OBJECT_POOL_SIZE                   10",
        "#define configSYSTEM_CALL_STACK_SIZE                              128",
        "#define configENABLE_ACCESS_CONTROL_LIST                          1", OK BOOL
        "#define configRUN_MULTIPLE_PRIORITIES             0", OK BOOL
        "#define configUSE_CORE_AFFINITY                   0", OK BOOL
        "#define configTASK_DEFAULT_CORE_AFFINITY          tskNO_AFFINITY",
        "#define configUSE_TASK_PREEMPTION_DISABLE         0", OK BOOL
        "#define configUSE_PASSIVE_IDLE_HOOK               0", OK BOOL
        "#define configTIMER_SERVICE_TASK_CORE_AFFINITY    tskNO_AFFINITY",
        "#define secureconfigMAX_SECURE_CONTEXTS        5",
        "#define configKERNEL_PROVIDED_STATIC_MEMORY    1", OK BOOL
        "#define configENABLE_TRUSTZONE            1", OK BOOL
        "#define configRUN_FREERTOS_SECURE_ONLY    1", OK BOOL
        "#define configENABLE_MPU                  1", OK BOOL
        "#define configENABLE_FPU                  1", OK BOOL
        "#define configENABLE_MVE                  1", OK BOOL
        "#define configCHECK_HANDLER_INSTALLATION    1", OK BOOL
        "#define configUSE_TASK_NOTIFICATIONS           1", OK BOOL
        "#define configUSE_MUTEXES                      1", OK BOOL
        "#define configUSE_RECURSIVE_MUTEXES            1", OK BOOL
        "#define configUSE_COUNTING_SEMAPHORES          1", OK BOOL
        "#define configUSE_QUEUE_SETS                   0", OK BOOL
        "#define configUSE_APPLICATION_TASK_TAG         0", OK BOOL
        "#define configUSE_POSIX_ERRNO                  0", OK BOOL
        "#define INCLUDE_vTaskPrioritySet               1", OK BOOL
        "#define INCLUDE_uxTaskPriorityGet              1", OK BOOL
        "#define INCLUDE_vTaskDelete                    1", OK BOOL
        "#define INCLUDE_vTaskSuspend                   1", OK BOOL
        "#define INCLUDE_xResumeFromISR                 1", OK BOOL
        "#define INCLUDE_vTaskDelayUntil                1", OK BOOL
        "#define INCLUDE_vTaskDelay                     1", OK BOOL
        "#define INCLUDE_xTaskGetSchedulerState         1", OK BOOL
        "#define INCLUDE_xTaskGetCurrentTaskHandle      1", OK BOOL
        "#define INCLUDE_uxTaskGetStackHighWaterMark    0", OK BOOL
        "#define INCLUDE_xTaskGetIdleTaskHandle         0", OK BOOL
        "#define INCLUDE_eTaskGetState                  0", OK BOOL
        "#define INCLUDE_xEventGroupSetBitFromISR       1", OK BOOL
        "#define INCLUDE_xTimerPendFunctionCall         0", OK BOOL
        "#define INCLUDE_xTaskAbortDelay                0", OK BOOL
        "#define INCLUDE_xTaskGetHandle                 0", OK BOOL
        "#define INCLUDE_xTaskResumeFromISR             1", OK BOOL
"""
class FreeRTOS(ConanFile):
    name = "freertos"
    version = "11.1.0"
    description = "Conan recipe for FreeRTOS"
    license = "MIT"
    homepage = "https://www.freertos.org"
    topics = ("freertos", "rtos", "threads", "tasks", "multithreading")

    settings = "build_type"
    generators = "CMakeDeps", "CMakeToolchain"

    options = {
        "configUSE_PREEMPTION": [True, False],
        "configUSE_TIME_SLICING": [True, False],
        "configUSE_PORT_OPTIMIZED_TASK_SELECTION": [True, False],
        "configUSE_TICKLESS_IDLE": [True, False],
        "configIDLE_SHOULD_YIELD": [True, False],
        "configENABLE_BACKWARD_COMPATIBILITY": [True, False],
        "configHEAP_CLEAR_MEMORY_ON_FREE": [True, False],
        "configUSE_NEWLIB_REENTRANT": [True, False],
        "configUSE_TIMERS": [True, False],
        "configUSE_EVENT_GROUPS": [True, False],
        "configUSE_STREAM_BUFFERS": [True, False],
        "configSUPPORT_STATIC_ALLOCATION": [True, False],
        "configSUPPORT_DYNAMIC_ALLOCATION": [True, False],
        "configENABLE_HEAP_PROTECTOR": [True, False],
        "configUSE_IDLE_HOOK": [True, False],
        "configUSE_TICK_HOOK": [True, False],
        "configUSE_MALLOC_FAILED_HOOK": [True, False],
        "configUSE_DAEMON_TASK_STARTUP_HOOK": [True, False],
        "configUSE_SB_COMPLETED_CALLBACK": [True, False],
        "configGENERATE_RUN_TIME_STATS": [True, False],
        "configUSE_TRACE_FACILITY": [True, False],
        "configUSE_STATS_FORMATTING_FUNCTIONS": [True, False],
        "configUSE_CO_ROUTINES": [True, False],
        "configINCLUDE_APPLICATION_DEFINED_PRIVILEGED_FUNCTIONS": [True, False],
        "configENFORCE_SYSTEM_CALLS_FROM_KERNEL_ONLY": [True, False],
        "configALLOW_UNPRIVILEGED_CRITICAL_SECTIONS": [True, False],
        "configUSE_MPU_WRAPPERS_V1": [True, False],
        "configENABLE_ACCESS_CONTROL_LIST": [True, False],
        "configRUN_MULTIPLE_PRIORITIES": [True, False],
        "configUSE_CORE_AFFINITY": [True, False],
        "configUSE_TASK_PREEMPTION_DISABLE": [True, False],
        "configUSE_PASSIVE_IDLE_HOOK": [True, False],
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
        "configUSE_PREEMPTION": True,
        "configUSE_TIME_SLICING": False,
        "configUSE_PORT_OPTIMIZED_TASK_SELECTION": False,
        "configUSE_TICKLESS_IDLE": False,
        "configIDLE_SHOULD_YIELD": True,
        "configENABLE_BACKWARD_COMPATIBILITY": False,
        "configHEAP_CLEAR_MEMORY_ON_FREE": True,
        "configUSE_NEWLIB_REENTRANT": False,
        "configUSE_TIMERS": True,
        "configUSE_EVENT_GROUPS": True,
        "configUSE_STREAM_BUFFERS": True,
        "configSUPPORT_STATIC_ALLOCATION": True,
        "configSUPPORT_DYNAMIC_ALLOCATION": True,
        "configENABLE_HEAP_PROTECTOR": False,
        "configUSE_IDLE_HOOK": False,
        "configUSE_TICK_HOOK": False,
        "configUSE_MALLOC_FAILED_HOOK": False,
        "configUSE_DAEMON_TASK_STARTUP_HOOK": False,
        "configUSE_SB_COMPLETED_CALLBACK": False,
        "configGENERATE_RUN_TIME_STATS": False,
        "configUSE_TRACE_FACILITY": False,
        "configUSE_STATS_FORMATTING_FUNCTIONS": False,
        "configUSE_CO_ROUTINES": False,
        "configINCLUDE_APPLICATION_DEFINED_PRIVILEGED_FUNCTIONS": False,
        "configENFORCE_SYSTEM_CALLS_FROM_KERNEL_ONLY": True,
        "configALLOW_UNPRIVILEGED_CRITICAL_SECTIONS": False,
        "configUSE_MPU_WRAPPERS_V1": False,
        "configENABLE_ACCESS_CONTROL_LIST": True,
        "configRUN_MULTIPLE_PRIORITIES": False,
        "configUSE_CORE_AFFINITY": False,
        "configUSE_TASK_PREEMPTION_DISABLE": False,
        "configUSE_PASSIVE_IDLE_HOOK": False,
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
        pass

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        # copy(self, "*.h", self.source_folder, join(self.package_folder, "include"), keep_path=False)
        pass

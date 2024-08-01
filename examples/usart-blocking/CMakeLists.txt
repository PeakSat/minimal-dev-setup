cmake_minimum_required(VERSION 3.27.8)
project(BlockingUSART LANGUAGES C CXX)

find_package(SAMV71-DFP COMPONENTS SAMV71Q21B REQUIRED)

find_package(Harmony REQUIRED)

add_harmony_config(
        MCU_MODEL ATSAMV71Q21B
        YAML_FILES mcu-config/core.yml mcu-config/dfp.yml mcu-config/efc.yml mcu-config/usart1.yml
)

add_executable(BlockingUSART src/main.c)

target_link_libraries(BlockingUSART
        PRIVATE
            samv71-dfp::SAMV71Q21B::Startup
            samv71-dfp::SAMV71Q21B::Linker::Flash
            Harmony::PeripheralDrivers
            Harmony::SysInit
)

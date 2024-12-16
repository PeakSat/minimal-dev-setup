cmake_minimum_required(VERSION 3.19.2)

project(Blinky C)

find_package(Harmony REQUIRED)
find_package(SAMV71-DFP COMPONENTS SAMV71Q21B REQUIRED)

add_harmony_config(
        MCU_MODEL ATSAMV71Q21B
        YAML_FILES
            ./mcu-config/core.yml
            ./mcu-config/dfp.yml
            ./mcu-config/efc.yml
)

add_executable(Blinky)
target_include_directories(Blinky PRIVATE include/)
target_sources(Blinky PRIVATE src/main.c)
target_link_libraries(Blinky PRIVATE samv71-dfp::SAMV71Q21B::Startup samv71-dfp::SAMV71Q21B::Linker::Flash Harmony::SysInit Harmony::PeripheralDrivers)

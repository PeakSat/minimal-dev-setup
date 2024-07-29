cmake_minimum_required(VERSION 3.19.2)

project(OBC_SOFTWARE C CXX ASM)

find_package(Harmony REQUIRED)
find_package(SAMV71-DFP COMPONENTS SAMV71Q21B REQUIRED)

# TODO: support multiple config names in separate directories (CONFIG_NAME argument)
add_harmony_config(
        MCU_MODEL ATSAMV71Q21B
        YAML_FILES
            ./mcu-config/core.yml
            ./mcu-config/dfp.yml
            ./mcu-config/efc.yml
            ./mcu-config/usart1.yml
)

add_executable(${PROJECT_NAME})
target_include_directories(${PROJECT_NAME} PRIVATE include/)
target_sources(${PROJECT_NAME} PRIVATE src/main.c)
target_link_libraries(${PROJECT_NAME} PRIVATE samv71-dfp::SAMV71Q21B::Startup samv71-dfp::SAMV71Q21B::Linker::Flash Harmony::SysInit Harmony::PeripheralDrivers)

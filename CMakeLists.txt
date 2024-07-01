cmake_minimum_required(VERSION 3.19.2)

project(OBC_SOFTWARE C CXX ASM)

find_package(CMSIS COMPONENTS Core REQUIRED)

add_library(SAMV71Q21B_DFP OBJECT) # if made a static library the linker will ignore the startup file
target_include_directories(SAMV71Q21B_DFP PUBLIC lib/SAMV71_DFP/samv71b/include/)
target_sources(SAMV71Q21B_DFP
	PRIVATE 
	lib/SAMV71_DFP/samv71b/gcc/gcc/startup_samv71q21b.c
)
target_link_libraries(SAMV71Q21B_DFP PRIVATE CMSIS::Core)

add_executable(${PROJECT_NAME})
target_include_directories(${PROJECT_NAME} PRIVATE include/)
target_sources(${PROJECT_NAME} PRIVATE src/main.c)
target_link_libraries(${PROJECT_NAME} PRIVATE SAMV71Q21B_DFP CMSIS::Core)

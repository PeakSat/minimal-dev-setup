# SAMV71 blinky example

This example blinks the User LED on a SAMV71 Xplained Ultra board
with a 1 sec interval.

## Building

To build this, run the following (assuming you have installed the 
Conan packages)
- `conan build . -pr=baremetal-samv71-armv7 -s build_type=Debug`

If for some reason you want to run the build manually, these are
the steps:
- `conan install . -pr=baremetal-samv71-armv7`
- `cmake . -Bbuild/Debug -DCMAKE_BUILD_TYPE=Debug -DCMAKE_TOOLCHAIN_FILE=./build/Debug/generators/conan_toolchain.cmake -GNinja`
- `cd build/Debug/`
- `ninja`

The produced `Blinky.elf` file can be found under `./build/Debug/`.
For a release build, change `Debug` to `Release` in all the commands above.

## Uploading

Use your favorite debug/flash tool for uploading. Refer to your tool's documentation
or to the main `README.md` file for a basic procedure using [OpenOCD](https://openocd.org/)


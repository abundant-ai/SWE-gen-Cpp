Projects that want to consume the library via CMake cannot reliably use `find_package(cppformat REQUIRED)` without first doing a separate install step, and using the library directly from an existing build tree is not properly supported. In particular, when a consumer configures a project that depends on cppformat, CMake fails to locate or import the cppformat target because the build/install tree does not provide a complete CMake package configuration (config file + exported targets) that `find_package` can use transitively.

Update the CMake packaging so that cppformat provides proper CMake package configuration and exported targets usable by `find_package(cppformat REQUIRED)`.

Expected behavior:
- A consuming project with a `CMakeLists.txt` that calls:
  ```cmake
  cmake_minimum_required(VERSION 2.8.12)
  project(cppformat-test)

  find_package(cppformat REQUIRED)

  add_executable(cppformat-test main.cpp)
  target_link_libraries(cppformat-test cppformat)
  ```
  should configure successfully and build.
- This should work when cppformat is:
  1) installed into the consumer’s `CMAKE_INSTALL_PREFIX` (no extra hints needed),
  2) installed into a non-default prefix by setting `-Dcppformat_DIR=<prefix>/lib/cmake/cppformat`,
  3) only built (not installed) by setting `-Dcppformat_DIR=<cppformat_build_dir>`.
- The exported `cppformat` target should be importable and correctly carry its include directories and any needed compile definitions (e.g., when built as a shared library, consumers should receive the definition that enables the correct import/export behavior).
- Packaging and install/export generation must work for out-of-source builds (building in a separate build directory) without requiring in-source artifacts.

Actual behavior to fix:
- `find_package(cppformat REQUIRED)` either fails during CMake configure because the package config/export files are missing or incomplete, or it succeeds but the imported target is not usable (e.g., missing include paths/definitions), forcing users to install manually or hardcode include/link paths instead of using `find_package` and `target_link_libraries(cppformat)`.

After the fix, consumers should be able to include headers like:
```cpp
#include <cppformat/format.h>
```
and link against the `cppformat` target found by `find_package` without additional manual configuration.
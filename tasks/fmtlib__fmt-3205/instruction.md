Downstream CMake projects that consume fmt via add_subdirectory() can have their chosen C++ standard silently overridden by fmt’s CMake configuration.

A common modern setup is that the consuming project enables its desired C++ standard using target_compile_features() (e.g., requesting C++17 on its own targets) rather than setting the global CMAKE_CXX_STANDARD variable. When fmt is added as a subdirectory, fmt’s CMake logic currently hardcodes CMAKE_CXX_STANDARD (and related variables) to ensure fmt is compiled with at least a baseline standard (e.g., C++11/14). This global assignment leaks into the parent project’s configuration and can downgrade/override the consumer’s standard selection, breaking builds or changing compilation flags unexpectedly.

Reproduction example:
- A top-level project defines an executable/library target and uses target_compile_features(<target> PRIVATE cxx_std_17) (or similar) to require C++17.
- The same project adds fmt via add_subdirectory(fmt).
- After configuration/generation, the consuming target or other targets may end up compiling with fmt’s default standard instead of the requested one unless the user preemptively sets CMAKE_CXX_STANDARD before adding fmt.

Expected behavior:
- Adding fmt as a subdirectory must not override the parent project’s chosen language standard policy.
- fmt should express its own minimum required C++ standard via target-level requirements so it compiles correctly without forcing global CMAKE_CXX_STANDARD on the entire build.
- Projects using find_package(FMT) or add_subdirectory(fmt) should both work without requiring consumers to set CMAKE_CXX_STANDARD globally.

Actual behavior:
- fmt’s CMake configuration sets CMAKE_CXX_STANDARD (and/or related global CMake C++ standard variables), which can override a downstream project that relies on target_compile_features() to select its standard.

Implement the change so that fmt advertises/enforces its minimum C++ standard using target_compile_features() (e.g., cxx_std_11 or cxx_std_14 as appropriate) on its exported targets (including the header-only target if present), instead of hardcoding CMAKE_CXX_STANDARD globally. If this requires raising the minimum supported CMake version to one that supports the needed cxx_std_* compile features, adjust the project’s minimum accordingly so configuration is consistent.
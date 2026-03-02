Building the project with CMake currently fails in some configurations due to incorrect example source listings and missing/incorrect CMake targets expected by consumers.

One visible failure happens when configuring/building the examples: CMake references an example source file named `bench.cpp`, but that source file does not exist in the examples sources. As a result, CMake errors out with a message like “Cannot find source file: bench.cpp”, preventing the examples from being generated/built.

In addition, consumers that link against the library in a target-based way (including the project’s own unit tests) expect to be able to link with a CMake target named `spdlog::spdlog`. In some build setups, that target does not exist (or is not consistently defined), causing CMake configuration or link steps to fail when `target_link_libraries(... spdlog::spdlog)` is used.

There is also a compilation/build issue in the “multisink” example (or multisink-related code) where the build fails under stricter compiler settings/toolchains.

The build system should be updated so that:

- Configuring/building examples does not reference non-existent files like `bench.cpp`; generating and building examples should succeed.
- A `spdlog::spdlog` CMake target is available and usable for `target_link_libraries` by downstream targets (including tests), so that `target_link_libraries(<exe> PRIVATE spdlog::spdlog)` works reliably.
- The multisink example/build should compile successfully across supported compilers/standard modes.

A minimal reproduction is:

1) Configure with CMake and enable building examples.
2) Attempt to build.

Expected behavior: configuration and compilation succeed.
Actual behavior: configuration/build fails due to the missing `bench.cpp` reference and/or missing `spdlog::spdlog` target, and the multisink build fails in some environments.
Projects embedding spdlog currently have to use it header-only, which forces widespread recompilation when spdlog implementation details change. There needs to be a supported build configuration that lets consumers choose between using spdlog as a header-only dependency or as a precompiled library (static or shared), without changing the public API surface.

Add a compile-time/build option (e.g., a CMake option and corresponding preprocessor define such as `SPDLOG_HEADER_ONLY` vs `SPDLOG_LIBRARY`) that allows building and consuming spdlog in these modes:

1) Header-only: consumers include headers and do not need to link to a spdlog library target.
2) Library: spdlog is built as a library and consumers link against it.
   - The library mode must support both shared and static builds.

In library mode, it must be possible to link an executable against spdlog (e.g., a unit test runner) using normal target linkage (linking to `spdlog`) and have it compile and run successfully.

Expected behavior:
- With default options, `make all` followed by running the project’s unit tests should succeed.
- When configured to build spdlog as a static library, building and running the unit tests should still succeed.
- Consumers using a package manager workflow (e.g., Conan) must be able to build and consume both shared and static variants of the library, and a minimal consumer package test should still compile and run.
- Public headers and user-facing APIs remain unchanged; only the build/consumption model changes.

Actual behavior to address:
- There is currently no supported configuration switch to choose between header-only and precompiled usage, so consumers cannot avoid full-project recompilation when spdlog changes.

Implement the build-system changes needed so that selecting header-only vs library mode is a first-class, supported configuration, and ensure the library target can be linked by downstream executables in both shared and static configurations.
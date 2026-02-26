Building google/benchmark on Windows with LLVM clang++ targeting the MSVC ABI (e.g., `clang++` with target `x86_64-pc-windows-msvc`) fails during the build of the C++03 compatibility compile check.

When configuring with CMake and building in Release mode using Ninja, the compilation of the project’s C++03 test is incorrectly performed with a C++11+ standard enabled (for example `-std=c++14`). As a result, compilation stops with errors like:

```
error: C++11 or greater detected. Should be C++03.
error: C++11 or greater detected by the library. BENCHMARK_HAS_CXX11 is defined.
```

This happens because the build system treats “MSVC-ABI compilers” inconsistently: many Windows-specific decisions are currently keyed off the `MSVC` CMake variable, but CMake only sets `MSVC` for compilers that emulate the `cl` command-line interface (MSVC itself and clang-cl). Plain `clang++` uses a GCC-like CLI, so `MSVC` is false even when the compiler is still targeting the MSVC ABI. The build logic therefore fails to apply the same MSVC-ABI handling to `clang++`, leading to incorrect flags/standard selection for the C++03-only compilation check.

Update the CMake configuration so that any compiler targeting the MSVC ABI is treated consistently, including `clang++` targeting MSVC. In particular, the logic that decides how to perform MSVC-specific checks and how to apply compiler/standard flags must recognize MSVC ABI targeting not only via `MSVC`, but also via `CMAKE_CXX_SIMULATE_ID` being `MSVC`. After the change, a clean configure and build on Windows using clang++ targeting MSVC must successfully compile the C++03 test with C++03 mode (not C++11+), and the overall library build should complete successfully.
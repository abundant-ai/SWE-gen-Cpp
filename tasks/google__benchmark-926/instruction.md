CMake consumers currently cannot reliably link Google Benchmark using consistent namespaced targets across both integration styles (using `find_package(benchmark)` vs embedding via `add_subdirectory`). When the project is added via `add_subdirectory`, the build only defines non-namespaced targets (e.g. `benchmark` and `benchmark_main`). As a result, users (and in-tree targets) must switch their `target_link_libraries(...)` entries depending on how Benchmark is consumed, which is error-prone and breaks builds that expect namespaced targets like `benchmark::benchmark`.

Update the CMake project so that it always provides the canonical namespaced targets `benchmark::benchmark` and `benchmark::benchmark_main` when built as a subproject. These namespaced targets should behave as aliases to the existing underlying targets, so that linking with either `benchmark::benchmark` or `benchmark` works when using `add_subdirectory`, and `benchmark::benchmark` / `benchmark::benchmark_main` remain the expected targets when using `find_package`.

After adding the aliases, internal targets within the repository that link against Benchmark should also link using the namespaced targets (e.g. use `target_link_libraries(... benchmark::benchmark ...)` and `target_link_libraries(... benchmark::benchmark_main ...)`) so that mis-typed or missing targets are caught by CMake’s namespacing rules.

Expected behavior:
- A project that does `add_subdirectory(<benchmark-source>)` can link with `target_link_libraries(app PRIVATE benchmark::benchmark)` and it configures and builds successfully.
- A project that uses `find_package(benchmark CONFIG REQUIRED)` can link with `target_link_libraries(app PRIVATE benchmark::benchmark)` and it continues to work as before.
- Similarly, `benchmark::benchmark_main` is available and linkable in both cases.

Actual behavior (current):
- With `add_subdirectory`, `benchmark::benchmark` and `benchmark::benchmark_main` are not defined, so CMake configuration fails when a consumer tries to link against those namespaced targets (typically with an error like “Target \"benchmark::benchmark\" not found”).
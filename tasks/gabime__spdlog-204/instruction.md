Building and testing spdlog via CMake lacks reliable, configurable targets for examples/tests/benchmarks, and the build system does not catch missing header dependencies early.

Currently, attempting to build the project’s examples via CMake can fail (including crashes during configuration/build), and there is no supported way to selectively enable/disable building tests and benchmarks from the top-level configuration. Additionally, headers can accidentally compile only when included indirectly through other headers; when a user includes a single spdlog header in isolation, compilation may fail due to missing required standard/library includes.

The build should support a clean, top-level CMake workflow where a user can configure and build everything from the repository root with options to enable examples, tests, and benchmarks. In particular:

- CMake configuration from the repository root should be able to build the examples without crashing.
- Add a build option `SPDLOG_BUILD_TESTS` that, when enabled, builds the unit tests and makes them runnable via CTest (e.g., `ctest` / `make test`). When disabled, tests should not be built.
- Add a build option `SPDLOG_BUILD_BENCHMARKS` that, when enabled, builds benchmarks and runs them via CTest. When disabled, benchmarks should not be built or run.
- Add an automated check that verifies each public spdlog header can be compiled when included alone. The check should compile a tiny program that does nothing except `#include <that_header>` and return 0. This ensures every header includes all of its own dependencies (no reliance on transitive includes). This check should be enabled when `SPDLOG_BUILD_TESTS` is enabled.
- Benchmark integrations may rely on optional third-party libraries; when those dependencies are absent, the corresponding benchmark should be skipped without failing the overall build/test run.

Example expected workflow:

```sh
mkdir build
cd build
cmake .. -DSPDLOG_BUILD_EXAMPLES=1 -DSPDLOG_BUILD_TESTS=1 -DSPDLOG_BUILD_BENCHMARKS=1
cmake --build .
ctest
```

Expected behavior: configuration succeeds; examples build when enabled; tests build and run when enabled; benchmarks build and run when enabled; and the header self-containment check fails the test run if any single spdlog header cannot compile by itself due to missing includes.

Actual behavior to fix: example builds can fail/crash under CMake; there are no reliable build options to toggle tests/benchmarks; and missing header dependencies are not detected until downstream users include headers in isolation, causing compilation errors.
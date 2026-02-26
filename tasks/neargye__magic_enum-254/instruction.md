Bazel users cannot currently consume the project via Bazel’s module system (bzlmod) in a way that is compatible with the Bazel Central Registry workflow, and the Bazel build is not reliably portable across platforms—particularly on Windows with MSVC.

When a consumer attempts to depend on the library using bzlmod (e.g. adding `bazel_dep(name = "magic_enum", version = "0.8.2")` in `MODULE.bazel`), the dependency is not usable as a standard module: the module metadata and exposed Bazel targets are not arranged to support a clean external dependency, and test-only dependencies/frameworks risk being pulled in as part of what would be published.

Additionally, building on Windows with MSVC fails due to compiler options being expressed in GCC/Clang form (e.g. using `-std=c++17`), but MSVC expects the `/std:c++17` form. The build should select the appropriate C++17 flag depending on the compiler/toolchain so that consumers can build the library with Bazel on Windows using MSVC without manual patching.

Expected behavior:
- A Bazel user can add a bzlmod dependency on `magic_enum` in `MODULE.bazel` and build against it as an external dependency without needing a WORKSPACE-based setup.
- Example targets are scoped as examples (not mixed with the main exported targets) so consuming the module doesn’t inadvertently pull in example build targets.
- Tests and testing frameworks (e.g. Catch2) are not part of what a downstream user would get when depending on the published module; tests should be isolated so the main module remains lightweight for publication.
- The Bazel build compiles successfully on Windows with MSVC by using MSVC-compatible C++ standard flags (`/std:c++17`) instead of GCC/Clang flags (`-std=c++17`), while still working on non-MSVC toolchains.

Actual behavior:
- Using bzlmod to depend on the library is not supported cleanly (module metadata/structure and exposed targets are not suitable for BCR-style consumption).
- The Bazel build uses incompatible C++ standard flags on MSVC, causing compilation failures on Windows.

Implement bzlmod-ready module support and ensure the Bazel C++ compile options are toolchain-aware so the same module builds correctly across platforms, including Windows/MSVC.
Building google/benchmark in Release mode with NVIDIA’s NVHPC toolchain (nvc++ 22.5) fails when warnings are treated as errors. The build emits diagnostics that are warnings for other compilers but are treated as errors by nvc++ in this configuration.

Reproduction: configure a project that depends on google/benchmark using CMake with `-DCMAKE_BUILD_TYPE=Release` and `-DCMAKE_CXX_COMPILER=nvc++` (for example with additional flags such as `-stdpar=multicore`), then build the benchmark library/targets. With `BENCHMARK_ENABLE_WERROR` enabled (or equivalent warning-as-error behavior), compilation fails.

Two specific failures that must be addressed:

1) A “declared but never referenced” diagnostic is produced for a helper function with signature similar to:

```cpp
double MakeTime(const rusage& ru);
```

nvc++ diagnoses this as an error in this build, preventing successful compilation.

2) A compile-time assertion using `offsetof` fails under nvc++ with the error:

```
offsetof applied to a type other than a standard-layout class
```

This occurs in code that applies `offsetof` to `benchmark::State` (or an internal `State` type) to assert layout/offset constraints. Under nvc++, the type is not considered standard-layout for purposes of `offsetof`, so the build fails.

Expected behavior: the project should build successfully with nvc++ 22.5 in Release mode without requiring consumers to disable `BENCHMARK_ENABLE_WERROR`. Warnings that are specific to NVHPC/nvc++ should be handled so they do not break the build, and the code should avoid using `offsetof` in a way that is ill-formed when the type is not standard-layout.

The fix should ensure:
- nvc++ can compile the library sources with warnings-as-errors enabled.
- The `offsetof`-based check on `State` no longer triggers the “non standard-layout” error under nvc++.
- Any NVHPC-specific warnings that previously broke the build are either avoided by code changes or cleanly suppressed only for NVHPC where appropriate, without affecting behavior for other compilers.
Building Catch2 with GCC/Clang when `-Wold-style-cast` is enabled (and especially when warnings are treated as errors via `-Werror`) currently fails due to remaining C-style casts in the codebase.

Two known failures occur in benchmark-related code:

1) In `Catch::Benchmark::Detail::bootstrap(...)` (which returns `Catch::Benchmark::Estimate<double>`), compilation fails because a probability is computed using a C-style cast in a division:

```cpp
// Fails with -Wold-style-cast
... / (double)n;
```

This must compile cleanly under `-Wold-style-cast` while preserving the same runtime behavior and numeric result (i.e., still performing a floating-point division rather than integer division).

2) In a lambda used in the benchmark implementation, compilation fails due to an `int` conversion done via an old-style cast:

```cpp
// Fails with -Wold-style-cast
return (int)(-2. * k0 / (k1 + std::sqrt(det)));
```

This conversion must also compile cleanly under `-Wold-style-cast` while keeping the same semantics of converting the computed floating-point expression to an `int`.

Expected behavior: Catch2 (including amalgamated builds, if generated as part of the project’s distribution) should compile without any `-Wold-style-cast` diagnostics in these benchmark-related functions, so that enabling `-Werror -Wold-style-cast` does not break users’ CI.

Actual behavior: Compilation fails with errors like `error: use of old-style cast to ‘double’ [-Werror=old-style-cast]` and `error: use of old-style cast to ‘int’ [-Werror=old-style-cast]` originating from the benchmark bootstrap logic/lambda.
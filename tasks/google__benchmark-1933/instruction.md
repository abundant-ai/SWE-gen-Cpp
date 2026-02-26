Running clang-tidy across the google/benchmark codebase reports multiple warnings/errors that indicate real correctness and maintainability problems, not just style. These diagnostics currently prevent a clean clang-tidy run and, in some configurations, lead to fragile behavior in the benchmark registration/execution tests.

The issues include:

- Unsafe or discouraged global state patterns used by the benchmarking tests/utilities (for example, heap-allocated non-const global objects used as shared queues/state across tests). These patterns are flagged by clang-tidy (e.g., guidelines around avoiding non-const globals and ensuring deterministic lifetime/ownership).

- Other global clang-tidy failures collected in issue #1925 that must be resolved so that clang-tidy can complete without emitting warnings/errors for the affected code paths.

The project should be updated so that:

- Benchmarks and their tests continue to behave the same from the user’s point of view. For example:
  - Benchmarks registered via `BENCHMARK(...)`, `BENCHMARK_F(...)`, `BENCHMARK_REGISTER_F(...)`, and `RegisterBenchmark(...)` must still register and execute as before.
  - `RunSpecifiedBenchmarks(...)` must still run only the benchmarks matching `FLAGS_benchmark_filter`, honoring `FLAGS_benchmark_repetitions` and `BM_DECLARE_bool(benchmark_enable_random_interleaving)` when enabled.
  - Setup/teardown hooks (`->Setup(...)`, `->Teardown(...)`, and fixture `SetUp(...)`) must still be invoked exactly as intended: once per run in single-threaded cases, and once per thread-group as appropriate in multi-threaded cases.

- The code should no longer trigger the clang-tidy diagnostics described in issue #1925 for the touched areas (in particular warnings/errors related to global state, lifetime/ownership, and other project-wide clang-tidy checks that currently fail).

If you reproduce by running clang-tidy over the project with the repository’s clang-tidy configuration, the run should complete cleanly (for the modified components) while preserving the existing benchmark execution semantics and test expectations described above.
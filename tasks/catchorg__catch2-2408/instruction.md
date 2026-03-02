Catch2 currently has no dedicated way to disable benchmarks at runtime without changing compilation flags or restructuring tests. Add a new command-line option `--skip-benchmarks` that causes Catch2 to run zero benchmarks when the option is provided.

When a test case contains benchmark invocations (e.g., `BENCHMARK(...)` or `BENCHMARK_ADVANCED(...)`), running the test executable with `--skip-benchmarks` should still execute the normal test assertions/sections, but all benchmark measurements must be skipped (i.e., benchmark bodies must not be executed and no benchmark results should be produced).

The option must be recognized by the command-line parser (it should be accepted as a valid flag alongside existing options), and it must be propagated into the runtime configuration so that the benchmark runner can decide to bypass running benchmarks.

Expected behavior examples:
- Running without `--skip-benchmarks` executes benchmarks normally and produces benchmark output/results.
- Running with `--skip-benchmarks` executes the surrounding test case logic (e.g., `CHECK`/`REQUIRE` statements and non-benchmark sections) but does not execute any benchmark functions and does not report benchmark timings.

The new flag should be stable in combination with other typical CLI options (such as selecting test cases by name or tags) and should not require users to add tags or duplicate code just to avoid running benchmarks.
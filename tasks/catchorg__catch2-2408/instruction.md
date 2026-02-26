Catch2 currently provides benchmarking macros (e.g., BENCHMARK and BENCHMARK_ADVANCED) that execute benchmark measurements during a normal test run. There is no way to disable execution of benchmarks at runtime without using compile-time switches or restructuring tests (e.g., tags/duplicate setup code). This is a problem when developers want to run assertions and test logic but avoid the extra time spent in benchmarks, and they want to do so without triggering a full recompilation.

Add a new command-line option `--skip-benchmarks` that, when provided, causes Catch2 to run zero benchmarks. The rest of the test cases must still run normally, including any assertions before/after benchmark blocks.

Expected behavior:
- Running a test binary with `--skip-benchmarks` should not execute any benchmark measurements registered via `BENCHMARK(...) { ... }` or `BENCHMARK_ADVANCED(...)(Catch::Benchmark::Chronometer ...) { ... }`.
- Skipping benchmarks must not skip the surrounding test cases themselves. For example, a test case that contains both `CHECK(...)`/`REQUIRE(...)` assertions and one or more BENCHMARK blocks should still evaluate the assertions and report their results; only the benchmark runs should be suppressed.
- The option should integrate with normal command line handling (it must be accepted by the parser, appear in `--help` output if applicable, and not be treated as an unrecognized argument).
- When `--skip-benchmarks` is not provided, benchmarking behavior should remain unchanged.

Actual behavior to fix:
- Passing `--skip-benchmarks` is currently unsupported and benchmarks still run (or the option is rejected/ignored). Users cannot disable benchmarks at runtime without compile-time configuration or test restructuring.

Reproduction example:
- Create a test case that contains assertions plus multiple `BENCHMARK`/`BENCHMARK_ADVANCED` blocks. Running the binary normally executes the benchmarks. Running the binary with `--skip-benchmarks` should execute the assertions but none of the benchmark blocks should run or be reported as executed.
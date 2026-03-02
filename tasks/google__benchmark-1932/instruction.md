Running Google Benchmark with certain command-line flags triggers clang-tidy cppcoreguidelines warnings/errors, and in some cases causes incorrect behavior in how configuration is reported to reporters.

In particular, the library should correctly parse and propagate the value of the `--benchmark_min_time` flag when it is specified in different forms:

- `--benchmark_min_time=<NUM>x` should be treated as an explicit iteration count and the executed benchmark run should report exactly `<NUM>` iterations via the `Run::iterations` value provided to `ConsoleReporter::ReportRuns(const std::vector<Run>&)`.
- `--benchmark_min_time=<NUM>` (no suffix) and `--benchmark_min_time=<NUM>s` should be treated as a minimum time in seconds and should be reported consistently to reporters via `ConsoleReporter::ReportRunsConfig(double min_time, bool has_explicit_iters, IterationCount iters)`.

Currently, when initializing and running benchmarks with these flags, the behavior is not reliable: reporters do not consistently receive the expected min_time/iteration configuration, and the `x`-suffixed form does not consistently result in the requested fixed iteration count being reflected in the reported run.

Reproduction examples:

1) Initialize and run a benchmark with `--benchmark_min_time=4x`. After `RunSpecifiedBenchmarks`, the single reported run for the benchmark should have `iterations == 4`.

2) Initialize and run a benchmark with `--benchmark_min_time=4` and with `--benchmark_min_time=4.0s`. In both cases, the reporter’s `ReportRunsConfig` callback should receive `min_time == 4.0` (within floating-point epsilon), and the benchmark should execute normally.

Additionally, running clang-tidy with `cppcoreguidelines` checks enabled should not produce warnings/errors for these code paths (for example around const-correctness and safe pointer/array usage in argument handling and reporter interfaces).

Fix the implementation so that these three flag forms behave as described, the correct values are delivered through the existing reporter callbacks (`ReportRuns` / `ReportRunsConfig`), and the codebase no longer triggers clang-tidy cppcoreguidelines findings in the affected areas.
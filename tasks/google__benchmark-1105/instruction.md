Google Benchmark currently runs benchmarks in a fixed, deterministic order across all configured argument instances, and when repetitions are enabled it tends to run the same benchmark instance back-to-back. This can amplify run-to-run variance because measurements become correlated with process dynamic state (cache warmup, allocator state, scheduling), especially when multiple benchmark instances are affected similarly within a run.

Implement “random interleaving” so that when the feature is enabled, the library can interleave benchmark instances in a randomized order across repetitions, while keeping the command-line interface compatible. The goal is to reduce variance by shuffling execution order without requiring users to change how they invoke benchmarks.

A new boolean flag must control the behavior: `--benchmark_enable_random_interleaving`.

Behavior requirements:

When `benchmark_enable_random_interleaving` is disabled (the legacy behavior), running `RunSpecifiedBenchmarks(...)` with a filter that matches a parameterized benchmark (multiple argument instances) must execute those instances in deterministic registration order. If repetitions are set to N (via the repetitions flag), each benchmark instance must still be executed N times, and under the legacy mode those N executions for a given instance must occur contiguously (i.e., the same instance repeated N times before moving to the next matched instance).

When `benchmark_enable_random_interleaving` is enabled and repetitions are greater than 1, the execution order across repetitions must be randomized/interleaved such that:

- Every matched benchmark instance is executed exactly `benchmark_repetitions` times.
- Executions should be interleaved across different benchmark instances rather than running the same instance N times in a row.
- The ordering should not be purely deterministic by registration order; it must incorporate randomness so that consecutive runs are less correlated.

The feature request also requires that enabling random interleaving does not require users to change their command line for typical usage. The intended effect is equivalent to running with `--benchmark_repetitions=12` and `--benchmark_min_time=0.042` (approximately `0.5 / 12`) so that total benchmark wall time remains close to the default minimum time budget. Disabling random interleaving should allow users to revert to the legacy single-repetition behavior (e.g., `--benchmark_enable_random_interleaving=false --benchmark_repetitions=1 --benchmark_min_time=0.5`).

To keep overhead bounded, introduce and honor a double flag `--benchmark_random_interleaving_max_overhead` that limits how much additional time (as a fraction/ratio of baseline) random interleaving is allowed to introduce due to increased setup/teardown, additional repetitions, or reduced per-repetition minimum time. The library should adjust effective repetitions and/or minimum time to stay within this overhead constraint.

Ensure that benchmark setup/teardown hooks (e.g., per-benchmark or per-thread setup/teardown mechanisms exposed via the public API) still behave correctly under random interleaving: setup must occur before a benchmark run and teardown after it, and randomization must not cause hooks to be skipped or executed out of order relative to each individual benchmark execution.

After implementation, running a filtered set of benchmark instances with repetitions should still produce valid results and should not change the set of matched benchmarks; only the execution ordering and repetition/min_time scheduling should differ when random interleaving is enabled.
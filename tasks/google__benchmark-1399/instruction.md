Benchmarks can have significantly slower performance in the first few iterations due to effects like cache warming or runtime initialization. The framework currently starts measuring immediately, so early slow iterations skew the reported results and can also influence how many iterations are chosen to satisfy the minimum measurement time.

Add support for a warmup phase that runs before the benchmark’s measured phase. Users must be able to configure a minimum warmup duration, both via the public benchmark registration API and via a command-line flag.

Required behavior:
- Introduce a per-benchmark setting `MinWarmUpTime(double seconds)` similar in spirit to `MinTime(double seconds)`.
- Introduce a command-line option `--benchmark_min_warmup_time=<seconds>` that sets a default minimum warmup time.
- When a benchmark runs, it must first execute a warmup phase for at least the configured warmup duration (if any). All timing data from the warmup phase must be discarded and must not affect the reported statistics.
- The warmup phase must not be used to determine the iteration count for the actual benchmark measurement phase. After warmup completes, the benchmark must proceed to determine iteration count and measurement normally using `MinTime` and the existing iteration scaling logic.
- Benchmarks with an explicit iteration count set via `Iterations(N)` must still respect that iteration count for the measured phase (i.e., the requested measured iterations remain exactly `N`), while still allowing the warmup phase to occur beforehand.
- Benchmark naming must reflect the configured warmup value when present: `BenchmarkName::str()` should include a `min_warmup_time:<value>s` component (e.g., `min_warmup_time:3.5s`) in the same style as existing components like `min_time:<value>s`.

Example expectations:
- If a benchmark is registered with `MinWarmUpTime(0.8)`, it should run some number of warmup iterations taking at least ~0.8 seconds total, then run the measured benchmark as usual, reporting results that do not include warmup.
- If a benchmark uses both `MinTime(0.1)` and `MinWarmUpTime(0.2)`, it should warm up first for at least ~0.2 seconds, then measure for at least ~0.1 seconds (subject to existing rules).

The goal is that users benchmarking code with a “cold start” can enable warmup so that the reported performance reflects steady-state behavior rather than initial transient slow iterations.
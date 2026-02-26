When using performance counters via libpfm (e.g., running benchmarks with a flag like `--benchmark_perf_counters=CYCLES`), counter metrics are only reported for the first few benchmark permutations, while later permutations are missing user counter results. This happens in parameterized benchmarks that generate many permutations (for example via an arguments product), where metrics should be produced for every permutation run.

The underlying failure mode is that multiple pinned perf events end up being created in the same thread over the course of running all permutations. Creating multiple pinned instances is unsupported on some systems and causes `PerfCounters::Snapshot(PerfCounterValues* values)` to fail at read time (even if initialization and creation appeared to succeed), which then prevents metrics from being recorded for subsequent permutations.

Fix the performance counter measurement flow so that pinned perf events are not repeatedly created per permutation in a way that accumulates multiple pinned instances in the same thread. `PerfCountersMeasurement` should reuse/cache a `PerfCounters` instance appropriately across benchmark runs so that `PerfCounters::Snapshot(...)` continues to succeed for every permutation.

Expected behavior:
- After `PerfCounters::Initialize()` succeeds and `PerfCounters::Create({...})` returns a valid instance, repeated calls to `Snapshot(PerfCounterValues*)` should keep succeeding and return monotonically increasing counter values for the lifetime of the measurement.
- When running a benchmark with many permutations and `--benchmark_perf_counters=<counter list>`, every permutation should include the requested counter metrics in the output; later permutations must not lose counters due to snapshot/read failures.

Actual behavior to eliminate:
- For workloads with many permutations, only the first few permutations show counter results; later ones do not.
- `PerfCounters::Snapshot(...)` can fail after multiple pinned events have been created in the same thread during the benchmark process, even though the counters were initially valid.
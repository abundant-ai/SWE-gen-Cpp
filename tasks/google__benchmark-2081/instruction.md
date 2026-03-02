Multi-threaded benchmarks report incorrect values for counters marked as rates.

When a user creates a counter with `benchmark::Counter::kIsRate`, the library should report a global rate over the whole benchmark run (e.g., operations per second across all threads). In multi-threaded runs, the current behavior effectively computes the rate per thread because the denominator uses the sum of elapsed seconds across all threads, rather than the benchmark’s overall elapsed time.

This also breaks `benchmark::Counter::kAvgThreadsRate`: it ends up dividing by the number of threads on top of an already per-thread computation, producing misleading “average thread rate” values.

Reproduction example:

```c++
static void BM_IntegerAddition(benchmark::State& state) {
  for (auto _ : state) {
    std::this_thread::sleep_for(std::chrono::seconds(1));
    benchmark::DoNotOptimize(1 + 2);
  }
  state.counters["counter"] = benchmark::Counter(1);
  state.counters["counter_rate"] = benchmark::Counter(1, benchmark::Counter::kIsRate);
  state.counters["counter_thread_rate"] =
      benchmark::Counter(1, benchmark::Counter::kAvgThreadsRate);
}

BENCHMARK(BM_IntegerAddition)
    ->Threads(1)
    ->Threads(10)
    ->Iterations(1)
    ->UseRealTime();
```

Actual behavior in a 10-thread run: the global rate `counter_rate` is ~1/s and `counter_thread_rate` is ~0.1/s, even though the total work done is 10x.

Expected behavior:
- For `kIsRate`, the reported rate should scale with the number of threads when each thread contributes work. In the example above, with ~1 second wall time:
  - `Threads(1)` should report ~1/s
  - `Threads(10)` should report ~10/s
- For `kAvgThreadsRate`, the reported value should represent the per-thread average rate. In the same example:
  - `Threads(10)` should report ~1/s

Implement the correct aggregation so that rate counters (`kIsRate` and the derived semantics used by `kAvgThreadsRate`) use an appropriate time base for multi-threaded benchmarks: the overall benchmark elapsed time (wall time when using real time, or CPU time where applicable), not the sum of per-thread elapsed times. This should also ensure that output formats (console/JSON/CSV/tabular) consistently reflect these corrected rate calculations for both single-threaded and multi-threaded runs.
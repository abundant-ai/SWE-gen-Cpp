When using the benchmark binary with the `--benchmark_perf_counters` flag, providing multiple perf counter names as a comma-separated list does not parse correctly. For example:

```
./benchmark_bin --benchmark_perf_counters=instructions,cache-misses,branch-misses
```

Instead of treating this as three counters (`instructions`, `cache-misses`, `branch-misses`), the program attempts to interpret `cache-misses,branch-misses` as a single counter name and fails with an error like:

```
Unknown counter name: cache-misses,branch-misses
```

The `--benchmark_perf_counters` argument parsing should split the provided value on commas and register/enable each counter name individually. The parsing must correctly handle more than two counters in the list, and it must not concatenate remaining counters into a single name.

After the fix, running with `--benchmark_perf_counters=instructions,cache-misses,branch-misses` should not emit an “Unknown counter name” error due to incorrect splitting; each counter should be validated and handled independently according to the existing perf-counter lookup/registration logic.
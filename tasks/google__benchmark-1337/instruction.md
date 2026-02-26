The benchmark framework currently reports times in nanoseconds by default, and the only way to change the displayed time unit is to set it per benchmark (for example, `BENCHMARK(BM_test)->Unit(benchmark::kMillisecond);`). This is repetitive when a user wants all benchmarks in a binary to use the same unit.

Add support for a global default time unit that can be set for the whole program. Users should be able to set the default via a command-line flag `--benchmark_time_unit=<unit>` (e.g. `--benchmark_time_unit=ms`) so that benchmarks without an explicitly set unit report using that unit instead of the current default of nanoseconds.

Also provide a C++ API function `benchmark::SetDefaultTimeUnit(TimeUnit unit)` that can be called early in `main()` (or before benchmarks are constructed/registered) to set the program-wide default time unit.

Behavior requirements:
- If no default is set (neither via flag nor by calling `SetDefaultTimeUnit`), `Benchmark::GetTimeUnit()` for a benchmark that did not explicitly set a unit must return `benchmark::kNanosecond`.
- If `SetDefaultTimeUnit(benchmark::kMillisecond)` is called, then `Benchmark::GetTimeUnit()` for a benchmark that did not explicitly set a unit must return `benchmark::kMillisecond`.
- If a benchmark explicitly sets its unit via `Benchmark::Unit(...)`, that explicit unit must take precedence over the global default even if the default is later changed. For example, if a benchmark calls `Unit(benchmark::kMillisecond)` and the global default is then set to `benchmark::kMicrosecond`, `GetTimeUnit()` must still return `benchmark::kMillisecond` for that benchmark.

The command-line `--benchmark_time_unit` behavior should be consistent with the C++ API: specifying the flag should set the same global default time unit as calling `SetDefaultTimeUnit`, and it should only affect benchmarks that did not explicitly set a unit.

Time unit parsing for the flag should accept the standard unit names used by the library (e.g. `ns`, `us`, `ms`, `s`) and apply the chosen unit globally.
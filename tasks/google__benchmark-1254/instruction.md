Some users need to programmatically read and/or set the active benchmark filter (the value normally supplied via the --benchmark_filter command-line flag). This currently isn’t reliably possible across the two supported flag implementations (Abseil flags vs the library’s built-in flag parser): code that uses absl::SetFlags to set --benchmark_filter will not work when the library is built with benchmark-flags, and there is no stable, non-hacky API for reading the effective filter value after initialization.

Add a supported API to retrieve the current benchmark filter string. The API must be available via the public benchmark header and behave consistently regardless of which flag backend is compiled in.

Specifically, implement a function with the signature:

```cpp
namespace benchmark {
const char* GetBenchmarkFilter();
}
```

Expected behavior:
- When the program is started with `--benchmark_filter=<value>` and `benchmark::Initialize(&argc, argv)` is called, `benchmark::GetBenchmarkFilter()` must return a C string equal to `<value>`.
- `benchmark::GetBenchmarkFilter()` must reflect the currently active filter value used by the benchmark framework (not an unrelated default or an empty value).
- Overriding the benchmark selection by passing an explicit specification string to `benchmark::RunSpecifiedBenchmarks(reporter, spec)` must still work even if the flag value is set to something else (e.g., the flag is `BM_NotChosen` but calling `RunSpecifiedBenchmarks(..., "BM_Chosen")` must execute `BM_Chosen`).

Failure mode to fix:
- In some builds/configurations, calling `benchmark::GetBenchmarkFilter()` after initialization does not return the same value as provided via `--benchmark_filter=...`, causing programs to observe a different filter than the one actually set (or to be unable to query it at all).

The implementation should ensure the returned pointer remains valid for as long as the benchmark library needs it (i.e., callers can compare it with `strcmp` after `Initialize`).
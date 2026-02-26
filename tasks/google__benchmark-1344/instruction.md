Custom benchmark reporters currently cannot reliably fall back to the library’s default “display” reporter because the logic for choosing/constructing that default reporter is not exposed via the public API. As a result, a custom reporter has no supported way to delegate output to “whatever reporter the benchmark would have used by default” under the current configuration/flags.

Expose a public API that allows users to create the default display reporter as a `std::unique_ptr<BenchmarkReporter>` (or equivalent ownership-returning handle used by the project), so that custom reporters can compose/forward to it without guessing benchmark configuration.

After this change, user code should be able to do something like:

```cpp
std::unique_ptr<benchmark::BenchmarkReporter> fallback =
    benchmark::CreateDefaultDisplayReporter();
```

and then use `fallback` as the reporter passed to `benchmark::RunSpecifiedBenchmarks(...)` or as a delegated reporter inside a custom reporter implementation.

The created reporter must behave identically to the reporter that would be used when running benchmarks without explicitly supplying a custom reporter (i.e., it must respect the library’s usual selection of the default “display” reporter and the relevant configuration that influences it).
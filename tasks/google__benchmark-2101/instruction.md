The library’s documented API encourages users to pass around a benchmark object to configure arguments (e.g., calling Arg(), Range(), Apply(), Unit(), etc.), but the type exposed for this is currently ::benchmark::internal::Benchmark, which is an internal-only class. This is confusing and also makes user code depend on the internal namespace.

Expose the Benchmark class as a public API type named ::benchmark::Benchmark that can be used anywhere users currently use ::benchmark::internal::Benchmark. Code such as:

```cpp
void CustomArgs(benchmark::Benchmark* b) {
  for (int i = 0; i < 10; ++i) b->Arg(i);
}

BENCHMARK(BM_basic)->Apply(CustomArgs);
```

must compile and work, with CustomArgs receiving a ::benchmark::Benchmark*.

For backward compatibility, existing code that still refers to ::benchmark::internal::Benchmark must continue to compile, but it should be deprecated (as a forwarding alias) in favor of ::benchmark::Benchmark.

After introducing the deprecated alias, the library’s own implementation must not trigger deprecation warnings when it refers to Benchmark internally. Any internal uses that currently name ::benchmark::internal::Benchmark need to be updated to explicitly use ::benchmark::Benchmark so that builds configured to treat deprecation warnings as errors do not fail.

Expected behavior:
- Users can use ::benchmark::Benchmark as a public type for configuring benchmarks (Arg/Args/Ranges/Range/DenseRange/Iterations/Repetitions/MinTime/MinWarmUpTime/UseRealTime/ThreadRange/ThreadPerCpu/Unit/Apply/Setup/Teardown/etc.).
- Existing code using ::benchmark::internal::Benchmark continues to compile, but produces a deprecation warning.
- The project itself builds cleanly without emitting deprecation warnings from its own internal references to Benchmark.
- Creating subclasses of benchmark::Benchmark and calling methods like GetTimeUnit()/Unit()/SetDefaultTimeUnit continues to behave the same (default time unit behavior remains correct).
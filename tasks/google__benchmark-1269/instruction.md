The benchmark library currently has no way to register per-benchmark setup/teardown callbacks that run outside the timed benchmark loop. Add an API on benchmark registration objects to support setup and teardown functions so users can write:

```cpp
static void MySetup(const benchmark::State& state) { /* ... */ }
static void MyTeardown(const benchmark::State& state) { /* ... */ }

static void BM_Foo(benchmark::State& state) {
  for (auto _ : state) {
    // timed work
  }
}

BENCHMARK(BM_Foo)->Setup(MySetup)->Teardown(MyTeardown);
```

The setup/teardown callbacks must be invoked with the following behavior:

- For single-threaded benchmarks, `Setup(const benchmark::State&)` and `Teardown(const benchmark::State&)` are called exactly once per benchmark run.
- For multi-threaded benchmarks (configured via `Threads(n)`), `Setup` and `Teardown` are called exactly once per thread-group run (not once per thread). They must be called only from the thread with `state.thread_index() == 0`.
- The callbacks must not run inside the timed region of the benchmark loop; they are intended for preparing and cleaning up state around the measurement.
- The callbacks must work correctly when the benchmark uses argument generators like `Arg(...)` and when it uses `Repetitions(k)`: for each repetition and each distinct argument instance, the setup and teardown must run once for that run.
- The callbacks must compose correctly with fixture benchmarks (`benchmark::Fixture`). If a benchmark is registered with both a fixture and a per-benchmark `Setup`, both must be invoked (fixture `SetUp` as usual, and the new per-benchmark `Setup` as well), without suppressing either.

If `Setup`/`Teardown` are not provided, benchmarks should behave exactly as before.

The new API should be available on the benchmark registration fluent interface (the object returned by `BENCHMARK(...)` and similar registration macros), using method names `Setup(...)` and `Teardown(...)` that accept a function pointer/callable compatible with `void(const benchmark::State&)`.

Currently, attempts to use this API either do not compile (because `Setup`/`Teardown` are missing) or the callbacks are not invoked with the correct frequency/threading semantics. Implement the API and execution semantics so that the described scenarios behave correctly, including correct `thread_index()` constraints for callback invocation.
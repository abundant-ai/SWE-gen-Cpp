Multi-threaded benchmarks currently assume the library owns thread creation/joining via its internal threading implementation. This prevents users from running benchmarks under alternative threading APIs or custom scheduling/execution environments (e.g., custom thread pools, fibers, platform-specific thread APIs). A new API is needed that lets the user supply the mechanism that runs N “benchmark threads” while keeping the benchmark function and measurement logic unchanged.

Implement support for a user-provided thread runner abstraction, centered around a base class named `benchmark::ThreadRunnerBase` with a virtual method `RunThreads(const std::function<void(int)>& fn)`. A benchmark must be able to register a factory for this runner via a fluent benchmark configuration call `ThreadRunner(...)` that receives the requested thread count and returns `std::unique_ptr<benchmark::ThreadRunnerBase>`. When a benchmark is configured with `Threads(N)` and a `ThreadRunner(...)` factory, the benchmark execution should call the runner’s `RunThreads` exactly once for that benchmark run, and `RunThreads` must invoke the provided function once per logical benchmark thread, passing a stable per-thread index in the range `[0, N-1]`.

The benchmark must continue to work correctly under the existing timing modes and options when a custom thread runner is used, including:

- Default timing (including `SetIterationTime(...)` usage)
- `UseRealTime()`
- `UseManualTime()`
- `MeasureProcessCPUTime()` (alone or combined with `UseRealTime()`)

In particular, a benchmark that uses manual timing should be able to call `state.SetIterationTime(seconds)` inside the benchmark loop, and the reported iteration time/rate counters must be computed correctly for multi-threaded execution under the custom runner.

The library must also correctly synchronize benchmark completion and results aggregation without relying on internal thread-management assumptions that are no longer valid when thread creation/joining happens inside user code. Running with a custom `ThreadRunnerBase` must not deadlock, hang, or race when collecting per-thread results/counters, and benchmark output must be identical in meaning to the built-in threading path.

Example expected usage:

```cpp
class MyRunner : public benchmark::ThreadRunnerBase {
 public:
  explicit MyRunner(int num_threads);
  void RunThreads(const std::function<void(int)>& fn) override;
};

static void BM_Something(benchmark::State& state) {
  for (auto _ : state) {
    // work
    state.SetIterationTime(0.050); // when using manual time
  }
  state.counters["invtime"] = benchmark::Counter{1, benchmark::Counter::kIsRate};
}

BENCHMARK(BM_Something)
  ->Iterations(1)
  ->ThreadRunner([](int n) { return std::make_unique<MyRunner>(n); })
  ->Threads(4)
  ->UseManualTime();
```

This should run the benchmark with 4 logical benchmark threads executed via `MyRunner::RunThreads`, with correct timing/counters and no reliance on the library’s internal thread spawning/joining behavior.
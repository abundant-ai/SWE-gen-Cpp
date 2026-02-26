When a benchmark calls `benchmark::State::SkipWithError()` before entering the benchmark loop, the framework can legitimately return from the benchmark function without ever reaching a point where `State::KeepRunning()` (or related loop helpers) returns `false`. Currently, this scenario can trigger a hard assertion failure during execution:

```
Check `st.iterations() >= st.max_iterations' failed. Benchmark returned before State::KeepRunning() returned false!
```

This happens when the runner expects that if the benchmark function returns, then the state must have completed its iteration contract (i.e., enough iterations were run / the loop naturally terminated). That assumption is invalid if the benchmark has already been marked as failed/skipped via `SkipWithError()` and exits early.

Update the benchmark execution logic so that if the `State` has an error condition set (via `SkipWithError()`), the runner does not enforce the “must have run until KeepRunning returned false” invariant. In other words, an early return before any iterations have started must be allowed when the benchmark has been marked with an error.

The behavior should be consistent across the different looping styles:
- A benchmark that only calls `state.SkipWithError("error message")` and returns should complete without assertion and report an errored run with the same error message.
- A benchmark that calls `state.SkipWithError("error message")` and then uses `while (state.KeepRunning()) { ... }` should not execute the loop body, should not assert, and should report an errored run.
- The same must hold for `KeepRunningBatch(...)` and the range-for loop form (`for (auto _ : state)`).

Additionally, when an error is set during execution (e.g., inside a `KeepRunning()` loop after at least one iteration), the run should be reported as errored with the provided message, without crashing, and the iteration accounting should remain valid for the non-error case.

The `benchmark::BenchmarkReporter::Run` results must reflect the error status (`error_occurred == true`) and preserve the provided `error_message` for these early-exit error cases.
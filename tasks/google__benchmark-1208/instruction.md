The benchmarking state object currently exposes thread-related information via publicly accessible data members (notably the total number of threads and the current thread’s index). Some downstream users and style guides disallow direct access to class data members even when they are const, and relying on public fields makes future internal redesign harder.

Add accessor methods on the benchmark state type so callers can retrieve:

- the current thread index via `thread_index()`
- the number of threads participating via `threads()`

Existing benchmarks and fixtures should be able to use these accessors during `SetUp`, `TearDown`, and benchmark execution to coordinate per-thread behavior. For example, code that conditionally initializes shared fixture state only on the first thread should work when written as:

```cpp
void SetUp(const benchmark::State& state) {
  if (state.thread_index() == 0) {
    // one-time initialization
  }
}
```

And code that gates behavior based on both the thread index and total thread count should work when written as:

```cpp
if (state.range(0) == 1 && state.thread_index() <= (state.threads() / 2)) {
  state.SkipWithError("error message");
}
```

At the same time, direct access to the underlying fields (e.g., `state.thread_index` and `state.threads`) must be deprecated (not removed), so existing code continues to compile but produces deprecation diagnostics when accessing those fields directly. The new accessor-based code paths must preserve existing behavior for multithreaded benchmarks, fixture setup/teardown, and skipping with an error during or before iteration.

If `SkipWithError("error message")` is invoked in these scenarios, the run should be reported as an error with the error message preserved exactly as provided, and benchmarks should not continue executing benchmarked iterations after the skip is triggered for that thread.
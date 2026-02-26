Benchmarks need a way to be skipped with an informational message that is not treated as an error, and the current skip/error reporting API has caused a public API break.

Two related problems need to be addressed:

1) Add support for skipping a benchmark with a message that is not an error.

The public benchmark state API should provide a method `benchmark::State::SkipWithMessage(const char* msg)`.

When `SkipWithMessage()` is called:
- The benchmark run should be marked as skipped, and the provided text should be recorded as the skip message.
- The skip should be treated as a non-error skip (distinct from `SkipWithError()`), so reporters and results aggregation can distinguish “skipped due to error” vs “skipped with message/info”.
- If timing is running, it must be stopped, and the benchmark should not continue running iterations after the skip is requested.
- Calling `SkipWithMessage()` before the benchmark starts running (before any `KeepRunning()` / `KeepRunningBatch()` / range-based loop iteration) must prevent entering the benchmark loop.
- Calling `SkipWithMessage()` during execution must stop further iterations cleanly.

2) Ensure reporter-visible run information correctly reflects skip status and message, and avoid breaking existing users relying on older fields.

`benchmark::BenchmarkReporter::Run` must expose enough information for reporters and downstream users to determine:
- whether the run was skipped due to an error vs skipped with a non-error message
- the message associated with the skip

In particular, for runs skipped due to an error (triggered by `benchmark::State::SkipWithError("...")`):
- `run.skipped` should indicate “skipped with error”
- `run.skip_message` should contain the error message
- `run.iterations` should reflect that the benchmark did not perform meaningful iterations (typically zero, depending on how the library represents skipped runs)

For runs that are not skipped:
- `run.skipped` should indicate “not skipped”
- `run.skip_message` should be empty
- `run.iterations` should be non-zero when the benchmark runs normally

Additionally, address the compatibility concern raised by removal of `BenchmarkReporter::Run::error_occurred` and `BenchmarkReporter::Run::error_message`. Code written against older versions should not face an abrupt compile break without a transition path. Provide a backward-compatible way for existing code to compile while still supporting the newer skip representation, and ensure the skip/error information remains accurately reported through the reporter interface.
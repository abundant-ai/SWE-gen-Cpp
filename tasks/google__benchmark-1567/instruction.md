Several parts of the benchmarking API still traffic in `const char*` for benchmark names, labels, and skip/error messages, which causes inconsistent string handling across the library. In particular, code that sets or stores labels/messages can end up keeping pointers to temporary or short-lived buffers, and callers who pass dynamically constructed strings (or strings derived from temporary objects) can observe incorrect output later (e.g., empty labels, corrupted text, or mismatches when comparing the reported benchmark name/label/message).

Update the benchmark registration and reporting path so that benchmark names, report labels, and skip/error messages are stored and reported as owning `std::string` values (or otherwise guarantee ownership/lifetime), rather than relying on raw `const char*` pointers.

The following user-visible behaviors must work reliably:

- Registering benchmarks by name using `benchmark::RegisterBenchmark(...)` must preserve the exact benchmark name in later reporting. This includes registering via literals and via names provided from data structures such as arrays of `{name, label}` pairs.

- Benchmarks that set a label via `benchmark::State::SetLabel(...)` must report the exact label text in `BenchmarkReporter::Run::report_label`. If no label is set, `report_label` must be empty.

- Benchmarks that call `benchmark::State::SkipWithError("error message")` must be marked as skipped with error, and `BenchmarkReporter::Run::skip_message` must exactly match the provided message string. This must hold when skipping before any iterations begin and when skipping during execution.

- Any accessor used by reporters to retrieve the benchmark name (for example `BenchmarkReporter::Run::benchmark_name()`) must continue to return the correct name string and be consistent with the stored name.

Overall, passing string data into registration, labeling, and skipping should be safe regardless of whether the caller passes a string literal, a `std::string`, or a `const char*` originating from a temporary/short-lived object; the library must not retain dangling pointers, and reported values must match exactly what was provided.
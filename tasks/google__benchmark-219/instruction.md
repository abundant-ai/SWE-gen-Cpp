The benchmark reporting system currently writes its output directly to default process streams (typically stdout/stderr) in a way that cannot be reliably captured or redirected by callers. This makes it hard to unit test reporter output and also prevents embedding applications from controlling where benchmark output and diagnostics go.

Update the reporter infrastructure so that all reporters consistently write to user-provided streams for both normal output and error/diagnostic output.

In particular:
- When a caller constructs or configures a reporter (including built-in reporters such as the console reporter and structured output reporters like JSON and CSV), it should be possible to supply an output stream and an error stream.
- All text produced by reporters must be sent to the configured output stream, not directly to global stdout.
- All diagnostics, warnings, and error messages produced during reporting must be sent to the configured error stream, not directly to global stderr.
- The change must be applied consistently across the reporting pipeline so that running benchmarks through the normal entry points still produces the same content by default (i.e., default behavior continues to write to stdout/stderr when no custom streams are provided), but becomes capturable when custom streams are passed.
- The behavior must be consistent across reporter formats: console output, JSON output, and CSV output should each write only to the configured output stream for their main report, while any error messages go only to the configured error stream.

After the change, it must be possible for a program to run benchmarks with a reporter configured with string/stringstream-backed streams and then examine the produced output and error content deterministically. For example, a caller should be able to run benchmarks with a console reporter and later assert that the produced output contains the expected benchmark header/context lines and benchmark result lines, without any output leaking to the process’s real stdout/stderr.

If multiple reporters are combined or wrapped (for example, a custom BenchmarkReporter that forwards to multiple underlying reporters), stream configuration must not cause inconsistent behavior between them: forwarding should preserve each reporter’s configured streams, and the reporting methods (ReportContext, ReportRuns, ReportComplexity, Finalize) should behave the same as before except for using the provided streams.
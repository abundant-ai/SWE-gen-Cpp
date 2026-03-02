Users need to be able to configure a custom end-of-line (EOL) string on a per-formatter basis when using spdlog’s pattern formatting. Today, log output always ends with the platform default EOL (as exposed via `spdlog::details::os::default_eol`), which makes it impossible to emit logs with a different line terminator (e.g., `"\n"` on Windows, `"\r\n"` on Linux, or a custom delimiter) without post-processing.

Add support for specifying a custom EOL for a `spdlog::pattern_formatter` (or the pattern-based formatter used by `logger::set_pattern(...)`). If the user does not specify an EOL explicitly, behavior must remain unchanged and continue using the system default EOL.

Expected behavior:
- When a logger is configured with `logger::set_pattern("%v")` and the user has not configured any custom EOL, each log call that produces a line must end with `spdlog::details::os::default_eol` (current behavior).
- When a custom EOL is provided to the pattern formatter, each formatted log line must end with that custom EOL instead of `spdlog::details::os::default_eol`.
- The custom EOL setting must be scoped to that formatter instance (or that logger’s formatter), so different loggers/formatters can use different EOLs without affecting each other.

A simple scenario that must work:
```cpp
std::ostringstream oss;
auto sink = std::make_shared<spdlog::sinks::ostream_sink_mt>(oss);
spdlog::logger lg("oss", sink);
lg.set_pattern("%v");
lg.info("Hello");
// Output should be "Hello" followed by the formatter’s EOL.
```
With default settings, the output ends in `spdlog::details::os::default_eol`. With a user-specified custom EOL, the output ends in that custom EOL.

Ensure that log level filtering still behaves the same (e.g., if the logger level is `err`, calling `info(...)` must not emit anything, regardless of EOL configuration).
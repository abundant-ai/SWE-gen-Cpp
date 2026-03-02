Building spdlog with an external fmt library can fail or lose compile-time format string validation depending on the fmt major version and how spdlog forwards format strings.

There are two related problems to fix:

1) Compatibility/build failure with fmt 7.x when spdlog is configured to use an external fmt
When compiling spdlog 1.9.x against fmt 7.1.3 (e.g., GCC 10.2.0 with SPDLOG_FMT_EXTERNAL=ON), compilation fails with errors like:

```
error: 'format_string' is not a member of 'fmt'
```

This happens because spdlog references `fmt::format_string` in type traits / overload selection even though that type is not available (or differs) in the targeted fmt version. Spdlog must compile cleanly with fmt 7.x in external-fmt mode.

2) Compile-time format string validation is not properly enabled (and may be accidentally bypassed)
With newer fmt versions (fmt 8+), format string validation rules changed, and spdlog currently converts format strings to `string_view` before validation occurs. This conversion prevents fmt from performing compile-time checking for calls that should be checked.

Expected behavior:
- When using spdlog logging APIs such as `logger->info("Test message {}", 2)` (and similarly `debug`, `trace`, `warn`, `error`, `critical`), literal format strings should be validated at compile time when the underlying fmt version supports it.
- Runtime format strings must still be supported via `fmt::runtime(...)`, e.g. `logger->info(fmt::runtime("Test message {} {}"), 1);` should compile and run.
- Invalid format strings passed as runtime strings (via `fmt::runtime`) must not cause compile-time errors; instead they should be handled at runtime, and spdlog’s configured error handler must be invoked. For example, if `logger->set_error_handler(...)` throws a custom exception type, then calling `logger->info(fmt::runtime("Bad format msg {} {}"), "xxx")` should trigger the error handler and propagate that custom exception.
- Basic logging to stdout/stderr and colored stdout/stderr loggers created via `spdlog::stdout_logger_st`, `spdlog::stdout_logger_mt`, `spdlog::stderr_logger_st`, `spdlog::stderr_logger_mt`, `spdlog::stdout_color_st`, `spdlog::stdout_color_mt`, `spdlog::stderr_color_st`, and `spdlog::stderr_color_mt` must continue to work with pattern setting and level setting.
- If wide-character logging is enabled (`SPDLOG_WCHAR_TO_UTF8_SUPPORT`), wide format strings like `L"Test wchar_api {}"` should continue to work with arguments (wstring, integers, etc.) without breaking format checking behavior.

Actual behavior:
- External fmt 7.1.3 builds can fail with `fmt::format_string` missing.
- With fmt 8+, passing literal format strings through spdlog does not reliably benefit from compile-time validation because the string is converted before fmt can validate it.

Implement changes so that spdlog:
- Uses the correct fmt format-string types/overloads for the detected fmt version (and does not unconditionally depend on `fmt::format_string` when it is unavailable).
- Preserves compile-time format string checking for literal format strings where supported, while still supporting runtime format strings via `fmt::runtime`.
- Keeps existing error-handling behavior: formatting failures should invoke the logger error handler and allow user-provided handlers to throw and be observed by callers.
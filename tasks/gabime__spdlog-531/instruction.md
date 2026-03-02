spdlog currently assumes fmt-style (“{}”) formatting for its variadic logging calls (e.g., logger->info("value {}", 1)). This blocks adoption in codebases that already use printf-style format strings (e.g., "%d", "%s") and expect those to work without rewriting large amounts of logging calls.

Add support for printf-style formatting throughout the standard spdlog logging API, gated by a compile-time definition named SPDLOG_FMT_PRINTF. When SPDLOG_FMT_PRINTF is defined, calls such as:

- logger->info("Test message %d", 1)
- logger->info("Bad format msg %s %s", "xxx")
- logger->trace_if(flag, "val=%d", 3)

must treat the format string as printf-style and format using fmt’s printf support. When SPDLOG_FMT_PRINTF is not defined, spdlog must keep its existing behavior (fmt-style with “{}”).

This must work consistently across:

- All log levels (trace/debug/info/warn/error/critical)
- Conditional logging APIs like trace_if/debug_if/info_if/warn_if/error_if/critical_if
- File loggers and rotating/daily loggers when using set_pattern("%v") (the formatted message should be exactly what’s written)

Error handling behavior must remain correct in both modes:

- If formatting fails (e.g., a format string expects more arguments than provided), the logger must invoke the configured error handler.
- With a custom error handler installed via set_error_handler(...), a formatting error must propagate as whatever the handler throws.
- With the default error handler, a formatting error should not produce a partially formatted log entry; subsequent valid log calls must still work.

The expected observable behavior in printf mode includes:

- Logging two messages with "Test message %d" and values 1 then 2 should produce two lines: "Test message 1" and "Test message 2".
- When a sink throws during log writing, spdlog should route that failure to the error handler as it does today; enabling printf mode must not change that behavior.
- For conditional logging APIs, when the condition is false, nothing should be logged; when true, the message must be formatted according to the selected style.

Implement the compile-time switch so projects can choose one style globally (no runtime switching required), and ensure builds without SPDLOG_FMT_PRINTF remain source- and behavior-compatible with existing spdlog usage.
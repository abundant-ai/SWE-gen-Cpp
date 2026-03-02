spdlog currently requires users to write explicit `if` statements to guard log calls when they only want to emit a message if a condition is true. Users want to write conditional logging in a single call, e.g. `logger->warn_if(response.size() > 16777215, "...")`, without manually wrapping the call in `if (...) { ... }`.

Add support for conditional logging methods on `spdlog::logger` for each log level:
- `trace_if(bool cond, ...)`
- `debug_if(bool cond, ...)`
- `info_if(bool cond, ...)`
- `warn_if(bool cond, ...)`
- `error_if(bool cond, ...)`
- `critical_if(bool cond, ...)`

These methods must support the same call patterns as the existing level methods: both logging a single message object and format-string based logging with variadic arguments.

Expected behavior:
- When `cond` is `true`, `*_if` behaves exactly like the corresponding non-conditional method (`trace`, `debug`, etc.), including formatting and emitting the message according to the logger’s current level and sinks.
- When `cond` is `false`, nothing is logged (no output is produced).
- The conditional check must prevent formatting/work from happening when `cond` is `false` (i.e., do not eagerly format the message).
- Conditional methods must respect the logger’s level: if the logger is configured to filter out a level, calling `*_if(true, ...)` at that filtered level must still produce no output.

Wide-character formatting should also work in builds where wide-char to UTF-8 support is enabled: the `*_if` overloads that accept `const wchar_t*` format strings should compile and behave the same as their non-conditional counterparts.

Example usage that should work:
```cpp
spdlog::logger logger(...);
logger.set_level(spdlog::level::warn);

logger.info_if(true, "hello");          // no output because level filters it
logger.warn_if(false, "skipped");       // no output because condition is false
logger.warn_if(true, "value={}", 42);   // outputs: value=42
```

The API should be available in released versions (not only on a development branch), so code written against `spdlog::logger::warn_if` and similar compiles without requiring custom wrappers.
Logging to FILE-backed outputs currently uses the standard C library `fwrite()` on all platforms. This adds avoidable locking overhead and increases per-call latency. The logging library should use an unlocked variant of fwrite when the platform provides one, while preserving identical output and behavior.

When writing formatted log messages to a `FILE*` (e.g., file sink / stdout / stderr sinks that ultimately emit via stdio), the implementation should prefer:

- On POSIX/glibc-like platforms: `fwrite_unlocked()` when available.
- On Windows/MSVC: `_fwrite_nolock()` when available.
- Otherwise: fall back to `fwrite()`.

The change must be transparent to users: calling typical logging APIs such as `spdlog::logger::info(...)` and related level-gated methods must produce the same bytes as before (including respecting the configured pattern and end-of-line behavior) and must not alter log level filtering. In particular, basic message formatting like logging `"Hello"` should still emit exactly `Hello` (followed by the default end-of-line for the active configuration), and logging should still be suppressed when the logger level is higher than the message level.

Ensure the unlocked write path is only selected when it is actually available for the target platform/toolchain (builds must succeed on Linux/macOS and Windows), and that the fallback path continues to work everywhere.

If the platform-specific unlocked function is not declared without additional feature macros, the library should still compile cleanly (no implicit declaration / missing prototype issues) and continue to use the safe fallback.
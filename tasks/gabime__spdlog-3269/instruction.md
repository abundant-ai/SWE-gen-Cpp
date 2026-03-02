`spdlog::sinks::rotating_file_sink` currently only rotates log files when the configured size threshold is exceeded. Some applications need to trigger rotation on-demand (e.g., after a user action or at a specific point in program flow) without waiting for the file to reach `max_size`.

Add support for manually forcing a rotation of a `rotating_file_sink` instance at runtime.

When a logger is created with a rotating sink (for example via `spdlog::rotating_logger_mt(...)` or by directly constructing/owning a `spdlog::sinks::rotating_file_sink_mt` / `_st`), callers should be able to request rotation explicitly (e.g., via a public method on the sink such as `rotate_now()` or equivalent).

Expected behavior when manual rotation is triggered:
- The current active log file should be closed/renamed using the same naming/retention rules as size-based rotation (i.e., it should behave like an immediate rotation event, reusing the existing `max_files` policy).
- After rotation, subsequent log messages should be written to a fresh base log file.
- Manual rotation should work even if the current file is well below `max_size`.
- Manual rotation should be safe to call multiple times and should not corrupt the rotation sequence or lose messages.

The feature should be available for both the multithreaded and single-threaded rotating sink variants.

A minimal usage example of the desired capability:
```cpp
auto logger = spdlog::rotating_logger_mt("logger", "logs/app.log", 1024 * 1024, 3);
logger->info("before");

// obtain the rotating sink and force a rotation
auto sink = std::dynamic_pointer_cast<spdlog::sinks::rotating_file_sink_mt>(logger->sinks().front());
sink->rotate_now();

logger->info("after");
```

After calling the manual rotation method, the message "after" must not be appended to the same file that contains "before"; it must be written to the newly created base file after rotation.

Currently, attempting to implement this behavior requires copying the entire rotating sink implementation because the rotation operation is not externally accessible. Provide an official API that enables this manual rotation behavior without requiring users to fork/copy the sink implementation.
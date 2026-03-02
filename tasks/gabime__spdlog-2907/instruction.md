spdlog currently lacks support for Mapped Diagnostic Context (MDC): a per-thread key/value context that can be attached to log events and rendered via the pattern formatter. Users need to be able to set contextual fields (e.g., “log zone”, request id, subsystem) once and have them automatically included in formatted log output without creating separate loggers per module.

Implement an MDC facility under the public API `spdlog::mdc` that provides at least the following functions:

- `spdlog::mdc::put(const std::string &key, const std::string &value)` to add or update a context entry for the current thread.
- `spdlog::mdc::remove(const std::string &key)` to remove a key from the current thread’s context.
- The MDC must be thread-local: values set in one thread must not appear in another thread’s log output.

Extend `spdlog::pattern_formatter` to support a new pattern flag `%&` that renders the current thread’s MDC content into the log line.

Formatting requirements for `%&`:

- When multiple MDC entries exist, render them as space-separated `key:value` pairs, in insertion order for that thread (so that putting key1 then key2 yields `key1:value1 key2:value2`).
- Updating an existing key via `put()` must update its value in subsequent output.
- Removing a key via `remove()` must omit it from subsequent output.
- When the MDC is empty, `%&` should render as an empty string (i.e., produce nothing between surrounding delimiters).

Example expected behavior:

```cpp
spdlog::mdc::put("mdc_key_1", "mdc_value_1");
spdlog::mdc::put("mdc_key_2", "mdc_value_2");

auto formatter = std::make_shared<spdlog::pattern_formatter>("\n");
formatter->set_pattern("[%n] [%l] [%&] %v");

spdlog::memory_buf_t formatted;
spdlog::details::log_msg msg(spdlog::source_loc{}, "logger-name", spdlog::level::info, "some message");
formatter->format(msg, formatted);

// Expected formatted output:
// [logger-name] [info] [mdc_key_1:mdc_value_1 mdc_key_2:mdc_value_2] some message

spdlog::mdc::remove("mdc_key_2");
```

After removal, the MDC portion should no longer include `mdc_key_2:mdc_value_2`. Also ensure that MDC content does not leak across threads when logging concurrently.
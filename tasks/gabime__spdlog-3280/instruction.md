Basic file sinks currently only support truncation at construction time (via the existing constructor flag) and do not provide a way to clear the log file after the sink/logger has been created. This makes it impossible to implement “clear log now” behavior without switching to a rotating sink or recreating the sink/logger.

Add support for on-demand truncation for basic file sinks.

When a user constructs a sink like:

```cpp
const bool truncate = true;
auto sink = std::make_shared<spdlog::sinks::basic_file_sink_mt>(filename, truncate);
auto logger = std::make_shared<spdlog::logger>("simple_file_logger", sink);
```

they should be able to call:

```cpp
sink->truncate();
```

to immediately truncate the underlying log file to empty.

Expected behavior:
- After writing some log messages and flushing, the file contains those messages.
- Calling `spdlog::sinks::basic_file_sink_mt::truncate()` (and the corresponding `*_st` variant) clears the file contents so that subsequent reads show it as empty (line count becomes 0).
- After truncating, further logging continues normally and new messages are written to the now-empty file.
- The operation should be safe to call while the sink is in use (respecting the sink’s thread-safety model: `_mt` must be safe under concurrent use; `_st` does not need to add extra synchronization beyond its normal expectations).

Actual behavior to fix:
- There is no supported `truncate()` operation on a basic file sink, so attempting to clear the file on demand is not possible, and scenarios that expect the file to become empty after `sink->truncate()` do not work.

Implement the new `truncate()` API on basic file sinks so that the above sequence results in the file being cleared and subsequent writes producing only the new messages.
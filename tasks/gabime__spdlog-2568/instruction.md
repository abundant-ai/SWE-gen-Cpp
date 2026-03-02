When using spdlog’s backtrace feature, calling dump_backtrace() on a logger that has backtrace enabled but has not captured any messages currently emits two marker lines:

"****************** Backtrace Start ******************"
"****************** Backtrace End ********************"

This is noisy in setups where many cloned loggers share sinks but only some of them actually record backtrace messages, because empty loggers still print the start/end lines.

Change the behavior of spdlog::logger::dump_backtrace() (and the equivalent behavior for spdlog::async_logger) so that it produces no output at all when the backtrace buffer is empty. In other words, if no messages are currently stored in the backtrace ring buffer for that logger, dump_backtrace() should be a no-op and must not log the start/end markers.

Expected behavior:
- If backtrace is enabled and at least one message has been buffered, dump_backtrace() should log the start marker, then the buffered messages (up to the configured backtrace size, in order), then the end marker.
- If backtrace is enabled but no messages have been buffered, dump_backtrace() should not emit anything (no start marker, no end marker, no blank lines).
- The behavior should be consistent for both synchronous loggers (spdlog::logger) and asynchronous loggers (spdlog::async_logger), including ensuring the async dump completes without emitting marker lines for an empty buffer.

A simple reproduction is:

```cpp
auto sink = /* any sink */;
spdlog::logger logger("name", sink);
logger.set_pattern("%v");
logger.enable_backtrace(5);
logger.dump_backtrace();
```

This should leave the sink with no additional logged lines.
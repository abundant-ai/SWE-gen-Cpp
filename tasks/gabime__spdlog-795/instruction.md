In async logging mode, when the queue is full and the overflow policy is configured to drop/override messages (e.g., dropping the oldest message to make room), users currently have no way to know that messages were discarded. This makes it difficult to size the queue appropriately or alert when data loss occurs.

Add a counter that increments every time a log message is overridden/dropped due to async queue overflow (specifically for the non-blocking discard behavior such as `async_overflow_policy::overrun_oldest`). Expose this counter so that callers can query it from the async thread pool object.

Expected behavior:
- When using an async logger with `async_overflow_policy::block`, no messages should be dropped; after producing and flushing a workload, querying the thread pool via `spdlog::details::thread_pool::overrun_counter()` should return `0`.
- When using an async logger with a discard/override overflow policy (e.g., `async_overflow_policy::overrun_oldest`) under load such that the queue overflows, some messages will be dropped; `spdlog::details::thread_pool::overrun_counter()` should be greater than `0` after logging.

API requirement:
- Implement a public method `overrun_counter()` on `spdlog::details::thread_pool` that returns the number of dropped/overridden messages observed so far.

Reproduction example:
```cpp
auto tp = std::make_shared<spdlog::details::thread_pool>(queue_size, 1);
auto logger = std::make_shared<spdlog::async_logger>("as", sink, tp,
                                                     spdlog::async_overflow_policy::overrun_oldest);
for (size_t i = 0; i < messages; i++) {
    logger->info("Hello message");
}
// Under sustained load with small queue_size, some messages are dropped
auto dropped = tp->overrun_counter();
// dropped should be > 0 in this scenario
```

The counter must reflect actual drops/overrides performed by the async infrastructure (not merely attempts), and it should be safe to query after logging has occurred.
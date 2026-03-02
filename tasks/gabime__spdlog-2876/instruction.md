Async logging currently supports overflow handling via policies such as `spdlog::async_overflow_policy::block` and `spdlog::async_overflow_policy::overrun_oldest`. A new policy, `spdlog::async_overflow_policy::discard_new`, needs to be supported for `spdlog::async_logger` and related async creation APIs.

When an async logger is configured with `discard_new` and its queue is full, new log messages must be dropped (the earliest queued messages must be preserved). This differs from `overrun_oldest`, which drops older messages to make room.

The thread pool used by async logging must expose a counter for how many messages were discarded due to `discard_new` overflow (e.g., `discard_counter()`), similar to the existing overrun counter behavior. When overflow happens under `discard_new`, `discard_counter()` must increase, and the sink should observe fewer processed messages than were submitted.

Expected behavior:

- Creating an async logger with `spdlog::async_overflow_policy::discard_new` must compile and work.
- Under load (e.g., small queue, slow sink), calling `logger->info(...)` repeatedly should result in `sink->msg_counter()` being less than the number of submitted messages, because some were discarded.
- In that same scenario, `thread_pool->discard_counter()` must be greater than 0.
- Existing behavior must remain unchanged:
  - With `block`, no messages should be lost and the overrun/discard counters should remain 0.
  - With `overrun_oldest`, messages may be lost and `thread_pool->overrun_counter()` should be greater than 0 when overflow occurs.
- Async non-blocking factory creation (e.g., `spdlog::create_async_nb(...)`) must still create a working async logger and continue to drop messages when overloaded; `discard_new` must be supported as a selectable overflow policy in the same way other policies are.

If `discard_new` is not implemented, typical failures include compilation errors due to missing enum handling and/or runtime behavior where overflow still overwrites old messages or does not increment the correct counter. Implement `discard_new` so that overflow drops only the newly arriving log events and records those drops via the discard counter.
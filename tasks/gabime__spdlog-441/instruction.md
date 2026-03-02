When using an asynchronous logger configured with `spdlog::async_overflow_policy::discard_log_msg`, log records are silently dropped once the queue overflows. This makes it difficult to diagnose missing log lines.

Add an optional feature (disabled by default) that counts how many messages were discarded due to overflow and emits a warning from the async worker thread indicating how many messages were dropped.

Reproduction scenario:
- Create an `spdlog::async_logger` with a very small queue size (e.g., 2) and `spdlog::async_overflow_policy::discard_log_msg`.
- Rapidly log more messages than the queue can hold (e.g., 8 messages).
- Flush and destroy the logger.

Expected behavior:
- If the feature is enabled at compile time (via `SPDLOG_ASYNC_COUNT_DISCARDED_MSG`), the output produced by the logger should include a warning message containing the text `Dropped 6 messages` for the scenario above (queue size 2, 8 log calls). The warning should be emitted by the async worker thread based on the number of records that were actually discarded.

Actual behavior:
- Discarded messages are currently silent; no warning is printed even when messages are dropped.

Requirements:
- The feature must be disabled by default and only active when `SPDLOG_ASYNC_COUNT_DISCARDED_MSG` is defined.
- The warning must be generated from the async logging machinery (worker thread) rather than from the caller thread.
- The count must reflect the number of discarded log messages due to queue overflow while the async logger is active (not a per-call guess).

The goal is to make lost messages visible when `discard_log_msg` is used, without changing default behavior when the feature macro is not defined.
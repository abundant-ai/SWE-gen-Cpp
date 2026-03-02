Logging currently does not allow reliably attaching a caller-supplied timestamp to a log event across both the low-level sink path and the high-level logger API. When a user wants multiple log calls to share the exact same timestamp (e.g., to preserve an externally captured time_point), the library should allow constructing a log message with an explicit std::chrono::system_clock::time_point and also allow calling the logger with an explicit time_point.

Implement support for an explicit timestamp in both of these places:

1) spdlog::details::log_msg must be constructible with an explicit std::chrono::system_clock::time_point, along with source location, logger name, level, and message text. Constructing a log_msg with the same provided time_point multiple times and passing it to a sink’s log(const log_msg&) must result in identical formatted timestamps (when the sink pattern includes time).

2) spdlog::logger must provide an overload of log(...) that accepts an explicit std::chrono::system_clock::time_point as the first argument, alongside spdlog::source_loc, spdlog::level::level_enum, and a format string + arguments (or equivalent formatted message parameters consistent with existing logger::log overloads). Multiple calls to this overload using the same time_point must produce output lines with identical timestamps.

Behavioral expectations:
- If five log_msg instances are created with the same time_point and logged to a sink with a pattern that prints time, the rendered time portion must be identical for those entries.
- If several logger.log(time_point, source_loc, level, ...) calls are made with the same time_point, the rendered time portion must be identical for those entries.
- A normal logger.log(source_loc, level, ...) call that does not provide a time_point must use the current time, and therefore should differ from the explicitly provided time_point entries when time advances.

The goal is to ensure the explicitly supplied time_point is preserved end-to-end and not overwritten by “now()” during logging/formatting.
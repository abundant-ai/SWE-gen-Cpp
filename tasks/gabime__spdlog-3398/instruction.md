spdlog currently provides `spdlog::register_logger()` and `spdlog::drop(name)` but no safe, single operation to replace an already-registered logger under the same name. Users who need to swap a logger’s sinks at runtime (while other threads may call `spdlog::get(name)` concurrently) are forced to do a non-atomic sequence like `drop(name)` followed by `register_logger(new_logger)`. This introduces a race window where another thread can call `spdlog::get("mylibraryname")` after the drop and before the register and unexpectedly get `nullptr` (or otherwise fail to retrieve the logger), even though the intent is to “replace” the logger.

Implement a new API function in the `spdlog` namespace named `spdlog::register_or_replace(std::shared_ptr<spdlog::logger> logger)` that atomically replaces any existing registered logger with the same `logger->name()`.

Expected behavior:
- If no logger is currently registered under `logger->name()`, `register_or_replace` should register the provided logger so that `spdlog::get(logger->name())` returns the same `std::shared_ptr`.
- If a logger is already registered under that name, `register_or_replace` should replace it so that subsequent calls to `spdlog::get(name)` return the new `std::shared_ptr`.
- The operation must not create a gap where `spdlog::get(name)` can fail between “drop” and “register”; replacement should behave like a single registry update.
- Existing `std::shared_ptr<spdlog::logger>` references held by other threads to the old logger must remain valid and continue to work until all references are released (i.e., replacing the registry entry must not invalidate or destroy the old logger prematurely).

A minimal example of the scenario that must be supported:
```cpp
auto logger1 = std::make_shared<spdlog::logger>("null_logger", sink1);
spdlog::register_logger(logger1);
// later
auto logger2 = std::make_shared<spdlog::logger>("null_logger", sink2);
spdlog::register_or_replace(logger2);
// now get() must return logger2
```

After the call to `spdlog::register_or_replace(logger2)`, `spdlog::get("null_logger")` should return `logger2` (pointer equality via shared_ptr), not the previously registered `logger1`.

This new API should coexist with existing semantics where `spdlog::register_logger()` continues to reject/throw when registering a duplicate name (in exception-enabled builds), while `register_or_replace()` intentionally does not fail in that case and instead overwrites the registry mapping.
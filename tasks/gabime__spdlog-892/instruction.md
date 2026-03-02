Add a global option to spdlog that disables the automatic global registration of loggers created via the convenience creation APIs.

Currently, calling spdlog::create<...>(name, ...) automatically registers the created logger in the global registry. This forces logger names to be globally unique and causes spdlog::create to throw spdlog::spdlog_ex when a logger with the same name already exists. This makes it difficult to create short-lived or per-component loggers (including multiple loggers with the same name) without re-implementing the full setup logic that create() applies (sync/async selection, global level, flush policy, etc.).

Implement a global flag (e.g., spdlog::set_automatic_registration(bool) or equivalent) that defaults to the current behavior (automatic registration enabled). When this option is disabled:

- Loggers created via spdlog::create<...>(...) (both sync and async variants) must NOT be added to the global registry.
- Because they are not registered, creating multiple loggers via spdlog::create with the same name must be allowed and must not throw due to name collisions.
- Even though they are not registered, these loggers must still be initialized as create() normally would at creation time (respect current global settings such as global log level, flush policy, etc.).
- Since unregistered loggers are not part of the global registry, subsequent changes to global settings via registry-wide operations (for example a global formatter change) must not retroactively affect already-created unregistered loggers.

The existing registry APIs must keep their current semantics for registered loggers:

- spdlog::get(name) should only find registered loggers; unregistered loggers created while automatic registration is disabled must not be returned.
- spdlog::register_logger(logger) should still register a logger explicitly, and name uniqueness must still be enforced for registration.
- spdlog::drop(name), spdlog::drop_all(), and spdlog::apply_all(...) must continue to operate only on registered loggers.

Reproduction example of the desired behavior:

- With automatic registration enabled (default):
  - spdlog::drop_all();
  - spdlog::create<spdlog::sinks::null_sink_mt>("same");
  - spdlog::get("same") returns non-null.
  - Calling spdlog::create<spdlog::sinks::null_sink_mt>("same") again throws spdlog::spdlog_ex.

- With automatic registration disabled:
  - spdlog::drop_all();
  - spdlog::set_automatic_registration(false);
  - auto a = spdlog::create<spdlog::sinks::null_sink_mt>("same");
  - auto b = spdlog::create<spdlog::sinks::null_sink_mt>("same");
  - Neither call throws.
  - spdlog::get("same") returns nullptr (because neither logger was registered).
  - If a logger is explicitly registered via spdlog::register_logger(...), then spdlog::get(name) returns it and registering/creating another registered logger with the same name should still throw as before.

The change should preserve backward compatibility when the option is not set (or set to true): behavior must remain identical to current spdlog.
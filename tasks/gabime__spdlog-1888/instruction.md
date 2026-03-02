spdlog exposes log level name strings via `spdlog::level::to_string_view(level_enum)`, but currently customizing those strings requires rebuilding with `SPDLOG_LEVEL_NAMES` (e.g., vendoring/cloning the library just to change displayed level names). Add a runtime API to override the string representation for a specific log level without changing build-time macros.

Implement `spdlog::level::set_string_view(spdlog::level::level_enum level, spdlog::string_view_t new_name)` so that after calling it, `spdlog::level::to_string_view(level)` returns the overridden value for that level.

Expected behavior:
- By default, `to_string_view()` returns the standard names: `trace`, `debug`, `info`, `warning`, `error`, `critical`, `off`.
- After calling `spdlog::level::set_string_view(spdlog::level::info, "INF")`, `spdlog::level::to_string_view(spdlog::level::info)` must return `"INF"`.
- It must be possible to restore the default behavior by setting the string back, e.g. `set_string_view(spdlog::level::info, "info")` then `to_string_view(info)` returns `"info"`.

The change must not break existing behavior of other level-related functions (e.g., `spdlog::level::to_short_c_str(level)` should continue returning the unchanged one-letter codes like `"I"` for info).
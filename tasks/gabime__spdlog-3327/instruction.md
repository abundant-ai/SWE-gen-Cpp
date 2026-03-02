`spdlog::cfg::load_env_levels()` currently only reads configuration from the `SPDLOG_LEVEL` environment variable. This is limiting for applications that want to control logging via a project-specific variable name (for example `MYAPP_LEVEL`) without reusing the global `SPDLOG_LEVEL`.

Update the configuration API so callers can load logger levels from a custom environment variable name.

When `SPDLOG_LEVEL` is set to a valid level specification like `"l1=warn"`, calling `spdlog::cfg::load_env_levels()` must continue to set logger `l1`’s level to `warn`.

Additionally, add an overload (or parameterized form) such that calling `spdlog::cfg::load_env_levels("MYAPP_LEVEL")` reads the `MYAPP_LEVEL` environment variable instead of `SPDLOG_LEVEL`. For example, if `MYAPP_LEVEL` is set to `"l1=trace"`, then after calling `load_env_levels("MYAPP_LEVEL")` the existing logger named `l1` must have its level updated to `trace`.

This change must not have side effects on the default logger’s level: after calling `load_env_levels()` or `load_env_levels(custom_name)`, the default logger should remain at its previous level (e.g., `info` unless explicitly changed elsewhere).
When emitting YAML scalars from floating-point values, yaml-cpp currently may output a value with no decimal point when the formatted result is an integer (for example, emitting 1.0 may produce `1` depending on precision/formatting). This makes it impossible for callers to force a YAML representation that visibly remains a floating-point number.

Add a new public emitter setting `Emitter::SetEnforceFloatDot(bool b)` that controls this behavior. When this setting is enabled, emitting any floating-point value (float/double/long double as applicable) must ensure the serialized scalar contains a decimal point; if the formatted output would otherwise contain no `.` (and no other decimal-point representation), append `.0` to the emitted scalar. Examples of expected output when enforcement is enabled:

- Emitting `1.0` should produce `1.0` (not `1`).
- Emitting `0.0` should produce `0.0`.
- Emitting `-2.0` should produce `-2.0`.
- Emitting `3.14` should remain `3.14` (no extra `.0`).

When the setting is disabled (the default), existing emission behavior must remain unchanged.

The setting must interact correctly with existing emitter numeric formatting controls such as `SetFloatPrecision(...)` / `SetDoublePrecision(...)` (i.e., enforcement applies after the normal precision/formatting rules have produced their string form, and only adds `.0` when the resulting representation would otherwise contain no dot). The emitter output must remain valid YAML scalars, and `Emitter::good()` should remain true for these operations (no new emitter errors).
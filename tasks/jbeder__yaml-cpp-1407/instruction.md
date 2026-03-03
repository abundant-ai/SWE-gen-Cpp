The YAML emitter currently does not provide a way to force floating-point scalars to include an explicit fractional part when the formatted value would otherwise look like an integer (e.g., emitting `1.0` may produce `1` depending on formatting/precision). This causes round-tripping/consumer ambiguity where a value intended to be a float is serialized as an integer-like scalar.

Add a new public API on `YAML::Emitter`:

```cpp
Emitter& SetEnforceFloatDot(bool b);
```

When `SetEnforceFloatDot(true)` is enabled, any emitted floating-point value (float/double/long double as supported by the library) must contain a decimal dot in its scalar representation. If the normal formatting would produce no `'.'` character (for example `1`, `-2`, or `3e5` depending on formatting), the emitter must append `.0` to ensure a dot is present (e.g., `1` becomes `1.0`). When `SetEnforceFloatDot(false)` (the default), existing behavior must remain unchanged.

This setting must integrate correctly with existing emitter formatting controls such as `SetFloatPrecision(...)` / `SetDoublePrecision(...)` and any float styling logic already present. It should apply only to floating-point emissions (not integers), and it should not break emitting special float values (e.g., NaN/inf) or quoted/explicit string scalars.

Example expected behavior:

```cpp
YAML::Emitter out;
out.SetEnforceFloatDot(true);
out << 1.0;
// expected output: "1.0" (not "1")
```

The change should be covered by emitter integration behavior so that enabling/disabling the setting clearly affects output, while the default output for existing code remains the same.
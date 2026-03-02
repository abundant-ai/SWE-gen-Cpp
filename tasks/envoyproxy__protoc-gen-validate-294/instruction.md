Generating Java validators for protobuf `map` fields can produce uncompilable Java code when constraints target map keys or values of certain numeric types (notably `long`, `float`, and `double`). The generated validator emits numeric literals without the required Java literal suffix, which causes compilation errors.

This happens because `javaTypeLiteralSuffixFor(...)` does not properly handle `map` fields. When constraints are applied under `map.keys` or `map.values`, the generator should infer the *effective* scalar type being constrained (the map key type or the map value type) and append the correct Java literal suffix when emitting constant numeric values.

Examples of constraints that must generate valid Java code:

- A map with `sint64` keys using a numeric comparison constraint such as `map.keys.sint64.lt = 0` should generate a Java numeric literal appropriate for `long` (e.g., `0L`, not `0`).
- A map with `float` values with numeric constraints should use `f/F` suffixed float literals when needed.
- A map with `double` values with numeric constraints should emit `d/D` suffixed double literals when needed.

Currently, when these constraints are used on maps, no suffix is appended at all, leading to Java compilation failures in the generated validator source.

Update `javaTypeLiteralSuffixFor(...)` so that when it is asked for a literal suffix for a `map` field, it determines whether the active constraint is targeting the map keys or the map values, derives the corresponding Java type (matching the same key/value type selection behavior used by `javaTypeFor(...)`), and returns the correct literal suffix for that derived type. As a result, Java code generation for map key/value numeric constraints must compile successfully and enforce the intended comparisons at runtime.
Introduce a new API for validating whether an integral/raw value corresponds to a valid enumerator: `contains_value<E>(value)`.

Currently, validating a value that comes from outside the program (e.g., a numeric value from serialization or an API) is awkward because the closest existing approach relies on creating an enum instance first (often via `static_cast<E>(value)`) and then using existing enum utilities. Casting an arbitrary underlying value to an enum can be undefined behavior when the enum’s underlying type is not explicitly known/safe, and it also makes call sites harder to read.

Add `contains_value<E>(value)` so callers can write:

```cpp
bool ok = magic_enum::contains_value<Color>(raw);
```

and get `true` only when `raw` exactly matches one of the enumerators of `E`, otherwise `false`.

The function should work for scoped and unscoped enums, for enums with negative values, and for enums with explicitly customized ranges. It must accept raw numeric inputs without requiring the caller to first construct an enum value.

Also ensure the internal index/value lookup used by the library can be called without requiring an enum instance created from an arbitrary integral (to avoid UB). In particular, enum index resolution should support being driven directly from the enum’s underlying type value, while still allowing existing enum-based calls to work.

Example expectations:
- For `enum class Color { RED = -12, GREEN = 7, BLUE = 15 };`, `contains_value<Color>(-12)` is `true`, `contains_value<Color>(0)` is `false`.
- For an enum where some enumerators are outside the configured min/max range, `contains_value` must return `false` for those out-of-range values.
- The API should be usable in constexpr contexts where the rest of the library supports constexpr.

Implement this new function and ensure it integrates consistently with existing `enum_cast`, `enum_index`, and other enum lookup utilities so behavior remains coherent across the library.
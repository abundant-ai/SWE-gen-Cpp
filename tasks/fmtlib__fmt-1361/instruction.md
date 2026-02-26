When formatting floating-point values with the Grisu-based formatter enabled, `float` values are currently formatted as if they were first promoted to `double`, producing overly long decimal expansions. For example, formatting `0.1f` with `fmt::format("{}", 0.1f)` currently yields `"0.10000000149011612"`, which matches formatting `double(0.1f)`, but it should instead produce the shortest correctly rounded representation for the original single-precision value: `"0.1"`.

The Grisu path needs to support IEEE-754 single precision (`float`) directly, including computing the correct upper/lower boundaries for a `float` (these boundaries are not the same as when treating the value as a `double`). After the fix, formatting with the default `{}` specifier should produce a “prettified” shortest string for `float` values (e.g., `0.1f -> "0.1"`) while preserving existing behavior for `double` (e.g., `double(0.1f) -> "0.10000000149011612"`). Existing handling of special values (NaN/inf), zero, rounding behavior, and fallback formatting for `double` must continue to work as before.

Reproduction:
```cpp
fmt::format("{}", 0.1f);          // expected "0.1"
fmt::format("{}", double(0.1f));  // expected "0.10000000149011612"
```

The fix should ensure the Grisu formatting code path selects the correct logic for `float` inputs (including correct boundary calculations for single precision) so that `float` formatting no longer depends on `double`-precision boundaries.
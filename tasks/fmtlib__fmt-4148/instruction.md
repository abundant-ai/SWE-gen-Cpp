Two related issues exist in fmt’s standard-library support.

1) `fmt::is_formattable<void>` is currently broken and can hard-error at compile time. Users expect `fmt::is_formattable<void>::value == false`, but attempting to instantiate it causes a compilation failure due to forming a reference to `void` inside the `is_formattable` implementation. This must be fixed so that checking formattability for `void` is well-formed and yields `false` without producing a substitution/instantiation error.

2) Formatting `std::expected<void, E>` should be supported (when the error type `E` itself is formattable). Add a `formatter<std::expected<void, E>, Char>` specialization (or equivalent behavior) such that:

- If the expected contains a value (i.e., `has_value()` is true), formatting with `{}` produces exactly `expected()`.
- If the expected contains an error, formatting with `{}` produces `unexpected(<formatted error>)` where the error is formatted using the library’s existing escaping/alternative formatting used for other `std::expected`/`std::unexpected`-style outputs.

The new formatter must not require `void` to be formattable, and it must only participate when `E` is formattable for the given character type (e.g., guarded by `fmt::is_formattable<E, Char>` or an equivalent constraint).

After these changes:

- Code that evaluates `fmt::is_formattable<void>::value` should compile cleanly and evaluate to `false`.
- Code like `fmt::format("{}", std::expected<void, E>{})` should compile and return `"expected()"`.
- Code like `fmt::format("{}", std::unexpected<E>(err))` (as stored in `std::expected<void, E>`) should produce `"unexpected(...)"` with the error formatted appropriately.

If `E` is not formattable, attempting to format `std::expected<void, E>` should fail in the same way other non-formattable types fail (i.e., no accidental hard error from the `void` handling; it should be excluded by constraints).
Two issues need to be fixed in fmt’s standard-library support and formattability detection.

1) `fmt::is_formattable<void>` is broken and causes a hard compilation error.

Expected behavior: querying the trait should be well-formed and evaluate to `false`:

```cpp
static_assert(fmt::is_formattable<void>::value == false);
```

Actual behavior: attempting to instantiate the trait for `void` fails to compile with an error like:

```
error: forming reference to void
... required from ... fmt::is_formattable<void> ...
```

This indicates `fmt::is_formattable<T, Char>` (and/or the internal mapping used to compute it) must treat `void` as not formattable without attempting to form `T&` or otherwise create invalid references.

2) Add support for formatting `std::expected<void, E>`.

Currently, formatting an `std::expected<void, E>` either fails to compile (no matching formatter / not formattable) or does not produce the desired output.

Expected behavior when calling `fmt::format("{}", value)` on `std::expected<void, E>`:

- If `value.has_value()` is true, formatting should produce exactly:

```
expected()
```

- If `value.has_value()` is false, formatting should produce:

```
unexpected(<formatted error>)
```

where `<formatted error>` is the formatted representation of `value.error()` using fmt’s normal formatting rules for `E`, and should work when `E` is formattable for the selected character type.

The implementation should be compatible with `fmt/std.h` usage so that including it enables formatting of `std::expected<void, E>` for appropriate `E`. The formattability of `std::expected<void, E>` should depend on `E` being formattable, and formatting must not require `void` itself to be formattable.
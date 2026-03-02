Compile-time format string checking fails when using a named argument whose value is a custom type with a valid fmt::formatter specialization.

A minimal example is:

```cpp
#include <fmt/format.h>

struct E {};

template<>
struct fmt::formatter<E> : fmt::formatter<std::string_view> {
  auto format(E, auto& ctx) const {
    return fmt::formatter<std::string_view>::format("42", ctx);
  }
};

void f() {
  using namespace fmt::literals;
  (void)fmt::format("{a}", "a"_a = E());
}
```

When compiled in C++20/C++23 modes, this should compile successfully (because E is formattable). Instead, the library triggers a compile-time failure during format string checking, attempting to instantiate a formatter for an internal “statically named argument” wrapper type rather than for the wrapped user type.

The compilation error observed is of the form:

```
error: use of deleted function
'fmt::v8::detail::fallback_formatter<T, Char, Enable>::fallback_formatter()'
```

coming from instantiations involving:

- `fmt::v8::detail::parse_format_specs<...>()`
- `fmt::v8::detail::format_string_checker<...>`
- `fmt::v8::detail::fallback_formatter<statically_named_arg<...>>`

Expected behavior: compile-time checking should correctly recognize that the named argument wraps a value of type `E` and should validate/parse the format specs against `fmt::formatter<E>` (or the mapped type used for `E`), so that `fmt::format("{a}", "a"_a = E())` compiles.

Actual behavior: compile-time checking treats the named-argument wrapper itself as the formatting type, fails `has_formatter` for it, and tries to instantiate a deleted fallback formatter, causing compilation to fail.

Fix the compile-time format checking logic so that named arguments (including statically named arguments created via the "name"_a literal) are checked against the underlying argument value type, not against the wrapper type. This should work for custom types with user-provided `fmt::formatter<T>` specializations, and should preserve expected behavior for cases that are meant to fail at compile time (invalid format strings/specs).
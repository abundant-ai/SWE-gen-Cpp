`FMT_COMPILE()` currently fails to work correctly with user-defined/custom types that provide a `fmt::formatter<T>` specialization. In particular, when formatting with a compile-time format string via `fmt::format(FMT_COMPILE("{}"), value)`, a custom type that is otherwise formattable at runtime does not format correctly at compile time.

A common failing scenario is a custom formatter whose `format` member function is `const`-qualified (e.g., `template <typename FormatContext> constexpr auto format(T, FormatContext& ctx) const -> decltype(ctx.out())`). This const-qualified `format` method is the standard shape used by many custom formatters, and it should be supported by compile-time formatting just as it is by runtime formatting.

Expected behavior: When a type `T` has a valid `fmt::formatter<T>` specialization with a `constexpr parse(...)` and a `const`-qualified `format(...)`, calling `fmt::format(FMT_COMPILE("{}"), T{})` should compile and produce the same output as runtime formatting with `"{}"`. The custom formatting logic should be honored (including any parsed specifiers), and the call should not fall back to runtime formatting in C++17+ environments where `if constexpr` is available.

Actual behavior: With `FMT_COMPILE`, the custom formatter path is not correctly selected/instantiated for such custom types, so formatting either fails to compile or does not use the custom formatter at compile time.

Reproduction example (should work):

```cpp
struct test_formattable {};

template <> struct fmt::formatter<test_formattable> : fmt::formatter<const char*> {
  char word_spec = 'f';

  constexpr auto parse(fmt::format_parse_context& ctx) {
    auto it = ctx.begin(), end = ctx.end();
    if (it == end || *it == '}') return it;
    if (*it == 'f' || *it == 'b') word_spec = *it++;
    if (it != end && *it != '}') throw fmt::format_error("invalid format");
    return it;
  }

  template <typename FormatContext>
  constexpr auto format(test_formattable, FormatContext& ctx) const
      -> decltype(ctx.out()) {
    return fmt::formatter<const char*>::format(word_spec == 'f' ? "foo" : "bar", ctx);
  }
};

auto s1 = fmt::format(FMT_COMPILE("{}"), test_formattable{});      // should be "foo"
auto s2 = fmt::format(FMT_COMPILE("{:b}"), test_formattable{});    // should be "bar"
```

Implement/restore proper `FMT_COMPILE` support for custom formatters so that const-qualified `formatter<T>::format(...)` works in compile-time formatting and produces the expected output for both default formatting and when a simple custom specifier is used.
Custom types with user-defined `fmt::formatter<T>` do not work correctly with compile-time formatting via `FMT_COMPILE()`. When a type has a custom formatter with a `constexpr` `parse` function and a `format` member that is `const`-qualified (e.g., `template <typename FormatContext> constexpr auto format(T, FormatContext& ctx) const -> decltype(ctx.out())`), formatting with `fmt::format(FMT_COMPILE("{}"), value)` should successfully compile and produce the same output as runtime formatting.

Currently, `FMT_COMPILE()` fails to format such custom types: compile-time formatting either fails to compile or fails to dispatch to the user-defined `formatter<T>::format` as expected. This makes compile-time formatting unusable for user-defined types and contradicts the expected behavior that `FMT_COMPILE` should support the same formatter customization mechanism as normal `fmt::format`.

Reproduction example:

```cpp
struct test_formattable {};

template <> struct fmt::formatter<test_formattable> : fmt::formatter<const char*> {
  char word_spec = 'f';

  constexpr auto parse(fmt::format_parse_context& ctx) {
    auto it = ctx.begin(), end = ctx.end();
    if (it == end || *it == '}') return it;
    if (it != end && (*it == 'f' || *it == 'b')) word_spec = *it++;
    if (it != end && *it != '}') throw fmt::format_error("invalid format");
    return it;
  }

  template <typename FormatContext>
  constexpr auto format(test_formattable, FormatContext& ctx) const
      -> decltype(ctx.out()) {
    return fmt::formatter<const char*>::format(word_spec == 'f' ? "foo" : "bar", ctx);
  }
};

auto s = fmt::format(FMT_COMPILE("{}"), test_formattable{});
// expected: "foo"
```

Expected behavior:
- `fmt::format(FMT_COMPILE("{}"), test_formattable{})` compiles.
- It uses the custom formatter and returns `"foo"` by default.
- Specifiers handled in `parse` are honored under `FMT_COMPILE`, e.g. `fmt::format(FMT_COMPILE("{:b}"), test_formattable{})` returns `"bar"`.

Actual behavior:
- `FMT_COMPILE` does not correctly support custom formatters for user-defined types (either compilation fails or formatting doesn’t route through the custom `formatter<T>`), even when the formatter is `constexpr`-friendly and the `format` method is `const`-qualified.

Fix compile-time formatting so that `FMT_COMPILE()` supports custom types using the standard `fmt::formatter<T>` customization point (including `const`-qualified `format` methods) and produces the same results as runtime formatting for these cases.
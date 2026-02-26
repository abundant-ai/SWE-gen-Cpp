`fmt::formatted_size` used to be usable in constant evaluation for C++20 builds (it was `constexpr`-enabled), which allowed computing the exact formatted output size at compile time and then formatting into a fixed-size buffer.

After a recent change, `fmt::formatted_size(...)` is no longer `constexpr` in the compiled-formatting API, which breaks compile-time formatting patterns that rely on `fmt::detail::udl_compiled_string` formats. Code like the following should compile in C++20/C++23 constant-evaluation contexts, but currently fails because the size computation is no longer constant-evaluable:

```cpp
template <fmt::detail::udl_compiled_string format, auto... values>
constexpr std::string_view constexpr_format() {
  static constexpr auto str = [] {
    constexpr auto result_length = fmt::formatted_size(format, values...);
    auto result = std::array<char, result_length>{};
    fmt::format_to(result.data(), format, values...);
    return result;
  }();
  return std::string_view(str.data(), str.size());
}
```

Expected behavior: when compiling with a C++20-capable compiler, `fmt::formatted_size` should be `constexpr`-usable for compiled format strings so that `result_length` can be computed at compile time (assuming the provided format and arguments are compatible with compile-time formatting).

Actual behavior: `fmt::formatted_size` is not `constexpr`, preventing `result_length` from being a constant expression and breaking compile-time formatting use cases.

In addition, enabling the fix for constexpr support must not introduce (or must resolve) a Visual Studio 2019 compilation error involving `fmt::detail::buffer<char>::append` failing to match/specialize during builds that use explicit instantiations. A failing build reports errors of the form:

- `error C2672: 'fmt::v11::detail::buffer<T>::append': no matching overloaded function found`
- `error C2893: Failed to specialize function template 'void fmt::v11::detail::buffer<T>::append(const U *,const U *)'` (with `T=char`, `U=Char`)

The library should build on MSVC 2019 with the relevant explicit-instantiation configuration enabled while also restoring constant-evaluable `fmt::formatted_size` behavior for compiled format strings in C++20 mode. Compile-time formatting via `FMT_COMPILE(...)` should continue to work for typical argument types (integers, floats, bool, char, strings, and custom formatters with `constexpr` parse/format where applicable).
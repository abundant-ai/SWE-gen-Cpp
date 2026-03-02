In C++20/23 builds, compile-time formatting workflows that previously worked using `fmt::formatted_size()` regressed: `fmt::formatted_size()` is no longer usable in constant evaluation, which prevents computing the required buffer size at compile time for `FMT_COMPILE`/compiled format strings.

A typical use case is a constexpr helper that builds a preformatted string as a `static constexpr` object inside a `constexpr` function. For example, code like this should compile and be constant-evaluated:

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

Currently, this pattern fails because `fmt::formatted_size(...)` is not `constexpr` in C++20 mode, and related counting functionality used by `formatted_size()` is also not usable in constant evaluation (e.g., counting/size computation via internal counting buffer/iterator).

Expected behavior: when compiling with C++20 (and newer), `fmt::formatted_size()` should be constexpr-capable for compiled format strings and constexpr-friendly arguments, so that it can be used to compute sizes in constant evaluation and enable fully compile-time formatting pipelines.

Actual behavior: `fmt::formatted_size()` cannot be evaluated at compile time, causing compilation failures when it is used in a `constexpr` context (such as initializing `constexpr` variables or `static constexpr` members).

Additionally, enabling/reintroducing constexpr and/or compile-time formatting support must not break MSVC 2019 builds. There is a known MSVC 2019 compilation error involving template overload resolution/specialization for `fmt::detail::buffer<T>::append` when certain explicit instantiations are not enabled. Building the library on Visual Studio 2019 should succeed without errors like:

```
error C2672: 'fmt::v11::detail::buffer<T>::append': no matching overloaded function found
error C2893: Failed to specialize function template 'void fmt::v11::detail::buffer<T>::append(const U *,const U *)'
```

The fix should restore constexpr usability of `fmt::formatted_size()` for C++20 compile-time formatting while preserving correct runtime behavior of `fmt::format(FMT_COMPILE("..."), ...)` across common types and keeping MSVC 2019 builds working (including the explicit instantiation configuration needed to avoid the `buffer::append` errors).
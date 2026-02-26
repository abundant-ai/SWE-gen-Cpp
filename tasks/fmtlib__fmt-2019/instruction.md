Compile-time formatting prepared via the compile-time API is not usable in constant-evaluated contexts under C++20, even for basic supported types (bool, integers, and strings). When users prepare a format with the compile-time API (e.g., via `FMT_COMPILE` / `fmt::detail::compile<...>(...)`) and then use it with `fmt::format`/`fmt::format_to`, the library should be able to execute the formatting during constant evaluation when the format string and arguments allow it.

Currently, attempting to rely on constant evaluation either fails to compile (because code paths are not `constexpr`-friendly) or silently falls back to runtime behavior, preventing use in `constexpr` expressions. This affects both narrow and wide format strings.

The library needs to support a minimal subset of compile-time formatting in C++20 constant evaluation:

- Preparing a compiled format from a string literal for a given argument list must work for both `"..."` and `L"..."`.
- Formatting with a prepared compiled format must correctly produce the expected output for basic cases such as:
  - `"test {}"` with an integer argument producing `"test 42"`
  - `L"test {}"` with an integer argument producing `L"test 42"`
  - Concatenating literal text and a single replacement field like `"4{}"` with `2` producing `"42"`
- Using a prepared compiled format with `fmt::format_to` must work when writing into:
  - a fixed-size character buffer via the checked-output helper (`fmt::detail::make_checked(...)`) for both `char` and `wchar_t`
  - a mutable output iterator such as `std::string::iterator` / `std::wstring::iterator`

To enable this, constant-evaluation-aware code paths must be available under C++20:

- Add a C++20-specific constexpr configuration macro (`FMT_CONSTEXPR20`) that allows marking functions constexpr only when the standard permits it.
- Provide `fmt::detail::is_constant_evaluated()` that calls `std::is_constant_evaluated()` when available and otherwise returns `false`, and use it where needed so compile-time formatting chooses constexpr-friendly behavior during constant evaluation without breaking older standard libraries.

The goal is not full feature parity at compile time. It is acceptable that pointers, floating-point formatting, and advanced format specifications (width/precision/padding/colors/locales) remain unsupported in constant evaluation for now. However, the basic integer/bool/string cases above must compile and produce correct results when used through the compile-time API.
Formatting wide-character (and other non-`char`) output involving `std::bitset` and padding currently fails and can crash.

1) `std::bitset` formatting is not properly supported for xchar output.
When calling `fmt::format` with a wide format string, e.g.:

```cpp
auto bs = std::bitset<6>(42);
auto s1 = fmt::format(L"{}", bs);
auto s2 = fmt::format(L"{:0>8}", bs);
auto s3 = fmt::format(L"{:-^12}", bs);
```

Expected results:
- `s1 == L"101010"`
- `s2 == L"00101010"` (left padded with `L'0'` to width 8)
- `s3 == L"---101010---"` (centered with `L'-'` to width 12)

Actual behavior: this use either fails to compile or triggers a crash depending on attempted workarounds.

2) There is a segfault related to copying/propagating the format `fill` character(s) when formatting non-`char` output.
A crash has been observed after a recent change when formatting styled output such as:

```cpp
std::ostringstream stream;
std::string line;
stream << fmt::format("{}", fmt::styled(line, fmt::fg(fmt::terminal_color::blue))) << "\n";
```

This can segfault with a backtrace indicating a null `this` in `fmt::detail::buffer<char>::append`, originating from internal copy/append operations during formatting of a `styled_arg`.

Separately, when attempting to enable wide `std::bitset` formatting via a nested formatter, a crash occurs during padding when `nested_formatter::write_padded` propagates fill into a new `basic_specs` via `set_fill(...)`. The failure mode is consistent with `basic_specs::fill<Char>()` returning `nullptr` for non-`char` types and that null pointer being used to build a `basic_string_view<Char>` for `set_fill`, leading to invalid memory access.

Expected behavior:
- `basic_specs` fill handling must be safe for all supported character types (`char`, `wchar_t`, `char16_t`, `char32_t`). Copying or propagating fill from one specs object to another must never create a null pointer string view or otherwise lead to UB.
- `nested_formatter::write_padded` must correctly preserve fill and alignment for xchar contexts.
- `formatter<std::bitset<N>, Char>` must work for `Char = wchar_t` (and other xchar types), including width/alignment/fill, without requiring user code changes.

Implement the necessary fixes so that the wide `std::bitset` formatting examples above produce the exact expected strings, and formatting styled output no longer segfaults.
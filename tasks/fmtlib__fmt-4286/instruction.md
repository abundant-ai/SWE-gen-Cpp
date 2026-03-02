Formatting a std::bitset with wide-character format strings (e.g., wchar_t/char16_t/char32_t) is currently broken and can crash at runtime when padding/alignment uses a fill character.

Reproduction:
```cpp
#include <bitset>
#include <fmt/std.h>

auto bs = std::bitset<6>(42);
auto s1 = fmt::format(L"{}", bs);        // should be L"101010"
auto s2 = fmt::format(L"{:0>8}", bs);    // should be L"00101010"
auto s3 = fmt::format(L"{:-^12}", bs);   // should be L"---101010---"
```

Expected behavior:
- `fmt::format(L"{}", std::bitset<6>(42))` returns `L"101010"`.
- Width/alignment/fill should work the same way as for narrow strings, e.g. `L"{:0>8}"` produces `L"00101010"` and `L"{:-^12}"` produces `L"---101010---"`.
- No crash should occur.

Actual behavior:
- The wide-character formatting either fails to compile in some configurations (because the bitset formatter uses a narrow `string_view`-based nested formatter) or, after making it compile, can segfault at runtime during formatting with padding.
- The crash happens while copying/applying the fill character in the padding logic: the fill pointer for non-`char` types can become null, and then code tries to build a `basic_string_view<Char>` from it and/or copy it, leading to invalid memory access.

Another observed crash (related to the same regression in fill copying) can be triggered when formatting styled output, e.g.:
```cpp
std::ostringstream stream;
std::string line;
stream << fmt::format("{}", fmt::styled(line, fmt::fg(fmt::terminal_color::blue)))
       << "\n";
```
This can crash with a backtrace showing a null `this` in `fmt::detail::buffer<char>::append`, indicating corruption/invalid state during formatting.

Required fix:
- Make `formatter<std::bitset<N>, Char>` support xchar format strings correctly by using the appropriate `basic_string_view<Char>`-based nested formatting so that wide-character formatting compiles and behaves like the `char` case.
- Fix the bug in the padding/fill handling (involving copying fill from `basic_specs` and/or applying it in `nested_formatter::write_padded`) so that fill is correctly preserved for all character types and never produces a null pointer/invalid view.
- After the fix, the wide-character bitset formatting examples above must work and must not crash, and formatting styled strings must also no longer segfault.
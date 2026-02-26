Locale-aware formatting with the `n` presentation type ignores the locale’s digit grouping rules. In C++ locales, numeric grouping is controlled by both `std::numpunct<Char>::thousands_sep()` and `std::numpunct<Char>::grouping()`. Currently, formatting with `fmt::format(loc, "{:n}", value)` uses the thousands separator character but effectively applies a fixed 3-digit grouping, which produces incorrect output for locales (or custom `numpunct`) that specify no grouping or non-3-digit grouping.

Reproducible examples:

1) If a locale specifies an empty grouping string (meaning “no grouping”), `std::stringstream` will not insert any separators, but `fmt` currently still inserts separators:

```cpp
struct no_grouping : std::numpunct<char> {
  std::string do_grouping() const { return ""; }
};
std::locale loc(std::locale("en-US"), new no_grouping);

std::stringstream ss;
ss.imbue(loc);
ss << 100000;           // expected: "100000"

fmt::format(loc, "{:n}", 100000);  // should be: "100000" (currently formats like "100,000")
```

2) If a locale specifies a non-uniform grouping pattern (e.g. Indian-style grouping), `fmt` should follow it but currently still groups by 3:

```cpp
struct special_grouping : std::numpunct<char> {
  std::string do_grouping() const { return "\03\02"; }
};
std::locale loc(std::locale("en-US"), new special_grouping);

std::stringstream ss;
ss.imbue(loc);
ss << 100000;           // expected: "1,00,000"

fmt::format(loc, "{:n}", 100000);  // should be: "1,00,000" (currently formats like "100,000")
```

The same behavior should work for both `char` and `wchar_t` locales.

The fix should make `n` formatting honor `std::numpunct<Char>::grouping()`:
- If `grouping()` is empty, no thousands separators should be inserted.
- If `grouping()` specifies a pattern (e.g. `"\03\02"`), separators should be inserted according to that pattern, repeating the last group size as appropriate.
- Group sizes like `"\01"` should be handled correctly even for very large integers.
- This should apply consistently to locale-aware integer formatting via `fmt::format(locale, "{:n}", ...)`, `fmt::vformat(locale, "{:n}", ...)`, and `fmt::format_to(..., locale, "{:n}", ...)`, and to locale-aware floating-point formatting (ensuring the locale decimal point is still used for `n`).
Range formatting with {fmt} is missing/incorrect for the proposed “range formatter” structure (based on P2286/P2585), especially around the `n` specifier and nested/element format specifications. Formatting of ranges should support both the default bracketed form and the `n` “no brackets” form, including correct propagation of per-element format specs through nested ranges.

When formatting C-style arrays, `std::vector`, nested `std::vector<std::vector<int>>`, and associative containers like `std::map<std::string,int>` and `std::set<std::string>`, the output should match these behaviors:

- Default range formatting should include delimiters appropriate to the range kind:
  - Sequences format like `[1, 2, 3]`.
  - Maps format like `{"one": 1, "two": 2}` (key/value pairs separated by `: ` and overall wrapped in `{}`), with string keys quoted.
  - Sets format like `{"one", "two"}` (overall wrapped in `{}`), with string elements quoted.
- The `n` specifier on a range should suppress the outer range brackets/braces while still formatting elements normally and still using the correct separators.
  - Example: formatting `std::vector<int>{1,2,3}` with `{:n}` should produce `1, 2, 3`.
  - Example: formatting `std::map<std::string,int>{{"one",1},{"two",2}}` with `{:n}` should produce `"one": 1, "two": 2`.
- Range formatting must support an “element format spec” introduced after an extra `:` inside the range format spec, and it must work for both simple and nested ranges:
  - Example: formatting `std::vector<int>{1,2,3,5,7,11}` with `{::#x}` should produce `[0x1, 0x2, 0x3, 0x5, 0x7, 0xb]` (outer range keeps brackets; element spec `#x` applies to each element).
  - Example: formatting the same vector with `{:n:#x}` should produce `0x1, 0x2, 0x3, 0x5, 0x7, 0xb` (no brackets; element spec `#x` applies).
  - For nested ranges, the element spec should apply at the correct nesting level:
    - Formatting `std::vector<std::vector<int>>{{1,2},{3,5},{7,11}}` with `{:::#x}` should produce `[[0x1, 0x2], [0x3, 0x5], [0x7, 0xb]]` (inner integers are hex-formatted; both outer and inner ranges keep brackets).
    - Formatting the same nested vector with `{:n:n:#x}` should produce `0x1, 0x2, 0x3, 0x5, 0x7, 0xb` (both outer and inner ranges use `n`, resulting in a flat, bracketless join; element spec `#x` applies to the integers).
- C-style arrays of string literals should be formatted as a range of strings by default, including quotes, but the range `n` modifier and the “raw element string” behavior must be handled correctly:
  - Formatting `const char*[]{"1234","abcd"}` with `{}` should produce `["1234", "abcd"]`.
  - Formatting the same with `{:n}` should produce `"1234", "abcd"`.
  - Formatting the same with `{:n:}` should produce `1234, abcd` (no outer brackets and string elements formatted without quotes when the element spec is empty after the second `:`).

Additionally, formatting should work for ranges found via ADL `begin`/`end` (a type that is not a standard container but provides `begin(const T&)`/`end(const T&)` free functions). Formatting such a single-element range should produce `[42]`.

Overall, implement/adjust the range formatter parsing and formatting so that `fmt::format` correctly interprets the `n` range specifier, supports the structured “range spec + element spec” parsing with nested ranges, and produces the expected delimiters, quoting, and separators for sequences, sets, and maps.
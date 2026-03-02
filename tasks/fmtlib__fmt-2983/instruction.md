Range formatting in {fmt} is incomplete and doesn’t support the standardized “range formatter” structure described in P2286/P2585, particularly around the `n` (no-brackets) specifier and how element format specs are applied (including for nested ranges). This leads to incorrect output when formatting C-style arrays, standard containers (vector, map, set), and nested ranges with element-specific format specs.

When calling `fmt::format` on ranges/containers, the library should support range formatting with these behaviors:

- Default range formatting adds appropriate brackets/braces and quotes, e.g.:
  - `fmt::format("{}", std::vector<int>{1,2,3})` should produce `"[1, 2, 3]"`.
  - `fmt::format("{}", std::map<std::string,int>{{"one",1},{"two",2}})` should produce `"{\"one\": 1, \"two\": 2}"`.
  - `fmt::format("{}", std::set<std::string>{"one","two"})` should produce `"{\"one\", \"two\"}"`.

- The `n` range specifier suppresses the outer range delimiters but keeps the normal element formatting, e.g.:
  - `fmt::format("{:n}", std::vector<int>{1,2,3})` should produce `"1, 2, 3"`.
  - `fmt::format("{:n}", std::map<std::string,int>{{"one",1},{"two",2}})` should produce `"\"one\": 1, \"two\": 2"`.

- Range formatting must support forwarding an element format spec after a `:` that applies to each element, including for nested ranges (multiple `:` levels). Examples:
  - `fmt::format("{::#x}", std::vector<int>{1,2,3})` should produce `"[0x1, 0x2, 0x3]"`.
  - `fmt::format("{:n:#x}", std::vector<int>{1,2,3})` should produce `"0x1, 0x2, 0x3"`.
  - For a nested range like `std::vector<std::vector<int>>{{1,2},{3,5}}`, element specs must be able to target inner elements:
    - `fmt::format("{:::#x}", v)` should produce `"[[0x1, 0x2], [0x3, 0x5]]"`.
    - `fmt::format("{:n:n:#x}", v)` should flatten the delimiter suppression appropriately and produce `"0x1, 0x2, 0x3, 0x5"`.

- C-style arrays must be treated as ranges, including nested (2D) arrays and arrays of string literals:
  - `fmt::format("{}", int[]{1,2,3})` should produce `"[1, 2, 3]"`.
  - `fmt::format("{}", int[][2]{{1,2},{3,5}})` should produce `"[[1, 2], [3, 5]]"`.
  - For `const char*[]` elements, default formatting should quote strings, but element formatting can be overridden:
    - `fmt::format("{}", arr)` -> `["1234", "abcd"]`
    - `fmt::format("{:n}", arr)` -> `"1234", "abcd"`
    - `fmt::format("{:n:}", arr)` -> `1234, abcd` (no quotes due to explicit element formatting)

- Types that are ranges via ADL `begin`/`end` must also be formattable as ranges. For a type `adl::box` with `begin(const box&)` and `end(const box&)` returning a pointer range over one `int`, `fmt::format("{}", adl::box{42})` should produce `"[42]"`.

Implement/adjust the range-format-spec parsing and range formatting logic so that `fmt::format` produces the outputs above, including correct handling of nested range formatting levels, delimiter suppression with `n`, and element-format forwarding via additional `:` segments.
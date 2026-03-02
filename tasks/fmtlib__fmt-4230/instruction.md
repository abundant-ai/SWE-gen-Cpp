`fmt::join` currently works for `std::tuple` but fails for user-defined “tuple-like” types that model the standard tuple interface (i.e., provide `std::tuple_size<T>`, `std::tuple_element<I, T>`, and `std::get<I>(t)` so they can be used with structured bindings). This prevents libraries that replicate tuple semantics from using `{fmt}`’s join functionality.

Reproduction example:

```cpp
std::tuple<int, int> t1{1, 2};
auto s1 = fmt::format("{}", fmt::join(t1, " x "));
// expected: "1 x 2" (this already works)

my_tuple<int, int> t2{1, 2};
auto s2 = fmt::format("{}", fmt::join(t2, " x "));
// expected: "1 x 2" but currently this does not compile / is not supported
```

`fmt::join(tuple_like, sep)` should accept any tuple-like object (including non-`std::tuple` types) as long as it satisfies the tuple-like protocol via `std::tuple_size`, `std::tuple_element`, and `std::get`. The resulting join view should format each element in index order and place the separator string between elements, matching the existing behavior for `std::tuple`.

Expected behavior:
- `fmt::format("{}", fmt::join(t, "-"))` produces the concatenation of formatted tuple elements separated by `"-"` for both `std::tuple` and custom tuple-like types.
- Empty/separators behavior should match existing `std::tuple` handling (no leading/trailing separator; separator only between elements).

Actual behavior:
- For tuple-like types that are not `std::tuple`, calling `fmt::join(t, sep)` fails to compile or is not recognized as a supported joinable type, even though `std::get`/`std::tuple_size` are available.
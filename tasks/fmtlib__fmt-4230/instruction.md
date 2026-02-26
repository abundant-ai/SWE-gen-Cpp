`fmt::join` currently works for `std::tuple` but fails to compile (or is not selectable) for non-`std::tuple` types that are still “tuple-like”, i.e., types that expose the standard tuple interface via `std::tuple_size<T>`, `std::tuple_element<I, T>`, and `std::get<I>(t)` (including types that support structured bindings).

This prevents users who have tuple-like types (for example, custom tuple implementations or library types that model the tuple protocol) from using the same formatting and joining functionality that works with `std::tuple`.

Reproduction example:

```cpp
std::tuple<int, int> t1{1, 2};
auto s1 = fmt::format("{}", fmt::join(t1, " x "));
// expected: "1 x 2"

my_tuple<int, int> t2{1, 2};
auto s2 = fmt::format("{}", fmt::join(t2, " x "));
// expected: "1 x 2" but currently does not work
```

Expected behavior:
- `fmt::join(t, sep)` should accept any tuple-like object `t` (including non-`std::tuple` types) when `std::tuple_size` and `std::get` are available for the type.
- Formatting a join view of such a tuple-like object should produce the elements in order, separated by the provided separator, with no surrounding brackets/parentheses added by `join` itself (e.g., `1 x 2`).
- It should work for const and non-const tuple-like objects and for arbitrary element types that are individually formattable by `{fmt}`.

Actual behavior:
- `fmt::join` is not usable with tuple-like objects that are not `std::tuple` (even though they satisfy the tuple protocol), resulting in compilation failure / overload resolution failure.

Implement support so that tuple-like objects are treated equivalently to `std::tuple` for `fmt::join` (and any internal join formatting path it relies on), using the tuple protocol (`std::tuple_size`/`std::get`) as the detection mechanism.
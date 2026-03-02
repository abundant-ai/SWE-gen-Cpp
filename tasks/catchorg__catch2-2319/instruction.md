Catch2 is missing generic range quantifier matchers that can validate boolean-like elements across arbitrary ranges. Users need three new matchers that can be used with REQUIRE_THAT on any “range” supported by Catch2’s generic range matching (e.g., standard containers, initializer lists, and types that only provide begin/end via ADL, including ranges where begin and end have different types).

Add the following generic range matchers:

- `AllTrue` — matches a range if every element in the range evaluates to `true`.
- `AnyTrue` — matches a range if at least one element in the range evaluates to `true`.
- `NoneTrue` — matches a range if no element in the range evaluates to `true`.

These matchers should integrate with Catch2’s matcher framework so they can be used like:

```cpp
REQUIRE_THAT(get_bools(), AllTrue());
REQUIRE_THAT(get_bools(), AnyTrue());
REQUIRE_THAT(get_bools(), NoneTrue());
```

Expected behavior:
- `AllTrue` should succeed for an empty range (vacuously true), and fail if any element is `false`.
- `AnyTrue` should fail for an empty range, succeed if at least one element is `true`.
- `NoneTrue` should succeed for an empty range, and fail if any element is `true`.

The matchers must work with elements that are `bool` as well as elements that are convertible to `bool` (e.g., proxy/reference types or custom types with explicit/implicit boolean conversion).

When a match fails, the matcher’s description should clearly communicate what was expected (all/any/none true) and the mismatch should be reportable through Catch2’s normal matcher diagnostics (so that failing assertions provide useful output rather than a compilation error or an unhelpful message).

Also ensure these new matchers compose correctly with existing matcher infrastructure for ranges (i.e., they should accept any range type supported by Catch2’s generic range matching, not require a specific container type or iterator category).
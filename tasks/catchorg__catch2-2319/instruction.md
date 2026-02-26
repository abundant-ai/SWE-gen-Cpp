Catch2 is missing generic range quantifier matchers that let users assert properties over any iterable range using the new generic matcher support. Users want to be able to construct a matcher from a single element-matcher and then apply it to an arbitrary range in `REQUIRE_THAT`/`CHECK_THAT`.

Add three new generic range matchers named `AllTrue`, `AnyTrue`, and `NoneTrue`.

`AllTrue` should match a range if every element in the range compares equal to `true` (i.e., is truthy as a boolean value). `AnyTrue` should match a range if at least one element is `true`. `NoneTrue` should match a range if no elements are `true`.

They must work with a wide variety of range types Catch2 supports for container/range matchers, including:
- Standard containers (e.g., `std::vector`, `std::list`, etc.)
- Ranges that rely on ADL `begin`/`end`
- Ranges where `begin` and `end` have different types (sentinel-style end)

The matchers should provide useful failure descriptions consistent with existing matcher output (e.g., describing the quantifier that failed and indicating that the range did not satisfy the condition).

Example expected usage:
```cpp
REQUIRE_THAT(get_flags(), AllTrue());
REQUIRE_THAT(get_numbers(), NoneTrue());
REQUIRE_THAT(get_flags(), AnyTrue());
```

Expected behavior details:
- For an empty range: `AllTrue` should succeed (vacuously true), while `AnyTrue` should fail, and `NoneTrue` should succeed.
- For a range containing both `true` and `false`: `AllTrue` should fail, `AnyTrue` should succeed, `NoneTrue` should fail.
- The matchers must be usable in typical matcher compositions where applicable (e.g., wrapped in `!` negation) without compilation errors.

Currently, these matchers do not exist (or do not work generically across supported ranges), preventing the above usage and causing compilation failures or incorrect matching behavior. Implement the matchers and ensure they integrate with Catch2’s existing matcher APIs so they can be used via `REQUIRE_THAT(range, <matcher>)` on generic ranges.
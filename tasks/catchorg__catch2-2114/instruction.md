Catch2 currently lacks generic range quantifier matchers that can assert that all/any/none elements of an arbitrary range satisfy a provided element matcher. Add three new generic range matchers named `AllMatch`, `AnyMatch`, and `NoneMatch`.

These matchers must be constructible from a single inner matcher (an element matcher) and their `match` method must accept a *generic range* (i.e., something iterable via `begin`/`end`, including types that rely on ADL `begin/end` and ranges where `begin()` and `end()` return different types). The matchers must work with standard containers (e.g., `std::vector`, `std::list`, `std::map`), fixed-size arrays, and user-defined range-like types.

Expected usage should compile and behave as follows:
```cpp
REQUIRE_THAT(get_keys(), AllMatch(KeyPattern({1, 2, 3})));
REQUIRE_THAT(get_numbers(), NoneMatch(IsOdd{}));
REQUIRE_THAT(get_strings(), AnyMatch(Contains("webscale") && !Contains("MongoDB")));
```

Semantics:
- `AllMatch(m)` succeeds if every element in the input range matches `m`. For an empty range, it should succeed (vacuous truth).
- `AnyMatch(m)` succeeds if at least one element in the input range matches `m`. For an empty range, it should fail.
- `NoneMatch(m)` succeeds if no element in the input range matches `m`. For an empty range, it should succeed.

The matchers must be compatible with Catch2’s matcher composition (e.g., `&&`, `||`, `!` on matchers) so that composing matchers like `Contains("x") && !Contains("y")` inside `AnyMatch(...)` works.

When a match fails, the failure description should be meaningful and reflect the quantifier and the underlying matcher (e.g., `AllMatch` should communicate that at least one element did not satisfy the inner matcher; `NoneMatch` should communicate that at least one element unexpectedly matched). The matchers must not require copying the range elements and should iterate the provided range in a standard single-pass manner.

At the moment, attempting to use `AllMatch`, `AnyMatch`, or `NoneMatch` should result in missing symbol/type errors (or inability to match generic ranges); after implementation, the above usage and the described edge cases (including ADL-only `begin/end` and differing `begin/end` types) must compile and behave according to the stated semantics.
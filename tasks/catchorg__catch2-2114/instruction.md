Catch2 is missing three generic range quantifier matchers requested in issue #2109: `AllMatch`, `AnyMatch`, and `NoneMatch`.

These matchers should be constructible from a single element matcher, and their `match` operation must accept a *generic range* (not just a specific container type). The intent is that they work with the existing matcher composition system (e.g., combining matchers with `&&` and `!`) and with the new generic matcher support.

Expected usage includes:

```cpp
REQUIRE_THAT(get_keys(), AllMatch(KeyPattern({1, 2, 3})));
REQUIRE_THAT(get_numbers(), NoneMatch(IsOdd{}));
REQUIRE_THAT(get_strings(), AnyMatch(Contains("webscale") && !Contains("MongoDB")));
```

Behavior required:
- `AllMatch(m)` succeeds if every element in the provided range matches `m`. It fails if at least one element does not match `m`.
- `AnyMatch(m)` succeeds if at least one element in the provided range matches `m`. It fails if no element matches `m`.
- `NoneMatch(m)` succeeds if no elements in the provided range match `m`. It fails if at least one element matches `m`.

The range input must be treated generically: it should work for standard containers (e.g., `std::vector`, `std::list`, `std::array`), associative containers where appropriate, and also for user-defined ranges that are only iterable via `begin(r)`/`end(r)` found by ADL. It must also support ranges where `begin()` and `end()` return different types (a “two-type range”), so the matching logic cannot assume `begin` and `end` have the same iterator type.

These matchers should integrate with Catch2’s matcher diagnostics:
- They must provide a meaningful textual description (e.g., describing that the range should have any/all/none elements matching the underlying matcher).
- On failure, the produced message should make it clear which quantifier failed and should incorporate the underlying element matcher’s description so users can understand what was being searched for/required.

Currently, the requested APIs are not available and/or do not compile when used as above with generic ranges and composed matchers. Implement the three matchers so that the examples compile and the described semantics hold across the supported range shapes.
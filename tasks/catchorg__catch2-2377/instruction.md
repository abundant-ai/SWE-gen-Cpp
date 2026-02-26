Catch2’s generic range matchers are missing two commonly expected matchers for validating the exact contents of a range: `ElementsAre` and `UnorderedElementsAre`. Catch2 v3 supports type-generic matchers, so these matchers should work with arbitrary range types (anything usable with `begin`/`end` through ADL) as long as the elements are comparable.

Implement two new matchers under the `Catch::Matchers` API:

1) `ElementsAre(...)`

When a user writes something like

```cpp
using Catch::Matchers::ElementsAre;

REQUIRE_THAT(actualRange, ElementsAre(expectedRange));
```

the match should succeed only if:
- `actualRange` and `expectedRange` have the same length, and
- for each position `i`, `actualRange[i]` matches `expectedRange[i]`.

`ElementsAre` must support construction arguments that are either:
- exact values (e.g., `ElementsAre(1, 2, 3)`), or
- matchers for the element type (e.g., `ElementsAre(GreaterThan(0), Equals(5), _ )`-style usage where supported by existing matcher conventions).

It must also support comparing ranges whose element types differ, as long as they are equality-comparable (e.g., a `std::vector<int>` compared against a range of `char` values).

Additionally, `ElementsAre` must allow using an STL-like binary predicate instead of default equality (i.e., not hard-coded to `std::equal_to`). For example, users should be able to supply a predicate that defines element-wise equivalence.

2) `UnorderedElementsAre(...)`

When a user writes

```cpp
using Catch::Matchers::UnorderedElementsAre;

REQUIRE_THAT(actualRange, UnorderedElementsAre(expectedRange));
```

the match should succeed only if:
- `actualRange` and `expectedRange` have the same length, and
- `actualRange` contains the same elements as `expectedRange` ignoring order (i.e., it is a permutation match).

`UnorderedElementsAre` must also support mixed construction arguments (exact values and/or matchers) and must allow comparing differing element types when they are comparable.

As with `ElementsAre`, `UnorderedElementsAre` must permit supplying an STL-like predicate to define equivalence instead of relying solely on `operator==`/`std::equal_to`.

Both matchers should integrate with `REQUIRE_THAT`/`CHECK_THAT` and produce clear matcher descriptions/messages consistent with other Catch2 matchers when they fail (e.g., indicating size mismatch and/or which elements failed to match).
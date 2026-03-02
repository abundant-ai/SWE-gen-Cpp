Catch2 v3’s generic matcher support is missing two commonly expected range matchers: `ElementsAre` and `UnorderedElementsAre`. Users should be able to assert that an input range matches an expected sequence either in exact order or in any permutation. Currently, there is no `ElementsAre(...)` / `UnorderedElementsAre(...)` matcher API that can be used with `REQUIRE_THAT(range, ...)`, so these assertions cannot be expressed using the new generic matcher facilities.

Implement two generic range matchers:

1) `ElementsAre(expected)`
When used as `REQUIRE_THAT(actualRange, ElementsAre(expectedRangeOrList))`, the matcher should succeed only if:
- `actualRange` and `expected` have the same length, and
- each element compares equal in the same position.

2) `UnorderedElementsAre(expected)`
When used as `REQUIRE_THAT(actualRange, UnorderedElementsAre(expectedRangeOrList))`, the matcher should succeed only if:
- `actualRange` and `expected` have the same length, and
- `actualRange` contains the same multiset of elements as `expected` (order does not matter, duplicates must match by count).

Both matchers must work with Catch2’s type-generic matcher model:
- Construction takes a range (or range-like input) as the expected values.
- The `match` operation takes the actual range being asserted on.
- The element types of `actualRange` and `expected` are allowed to differ as long as they are comparable under the chosen comparison (e.g., comparing `std::vector<int>` to `std::array<char, N>` should be supported if the element comparison is valid).

Element-wise comparison customization is required:
- By default, comparisons should use `std::equal_to`-like equality.
- Users must also be able to provide an STL-style binary predicate to define equality between an element from the actual range and an element from the expected range.

Expected elements should support both raw values and matchers:
- Each “expected element” provided to `ElementsAre`/`UnorderedElementsAre` may be either a concrete value or a matcher that can be applied to the corresponding actual element.
- For `ElementsAre`, matcher-valued expectations apply positionally.
- For `UnorderedElementsAre`, matcher-valued expectations must be satisfied by some one-to-one assignment between actual elements and expected matchers/values (i.e., a permutation/matching problem; duplicates and multiple matchers must be handled correctly).

The matchers must provide useful descriptions for failure messages, consistent with other Catch2 matchers (e.g., describing that the range differs, whether it was an ordering mismatch vs missing/extra elements, and including the expected representation).

After implementing these matchers, they should be usable alongside existing generic range matchers (such as other quantifier/range matchers), and they should work with non-standard ranges that rely on ADL `begin/end` and ranges whose begin/end iterator types differ, as long as they are iterable in a forward manner.
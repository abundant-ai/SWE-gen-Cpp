Composable matchers in Catch2 are currently tied to a single concrete argument type via inheritance from `Catch::MatcherBase<T>`. This prevents writing matchers that can accept multiple different, but comparable, argument types (e.g., comparing a `std::vector<int>` to a `std::array<int, N>` or `std::list<int>`), and also makes it impossible to use matchers with inputs that cannot be bound as `const T&` (e.g., certain range/view types that mutate internal state while iterating and therefore cannot be `const`).

The matcher API needs to support “generic” matchers that are not parameterized by a single `T`, while still allowing them to be composed with existing typed matchers using `&&`, `||`, and `!`, and without breaking existing `MatcherBase<T>`-derived matchers.

Implement support for a new generic matcher base (exposed as `Catch::MatcherGenericBase`) that enables defining matchers with a templated `match` member, e.g.

```cpp
template <typename Range>
struct EqualsRangeMatcher : Catch::MatcherGenericBase {
    EqualsRangeMatcher(Range const& range);

    template <typename OtherRange>
    bool match(OtherRange const& other) const;

    std::string describe() const override;
};
```

With this capability, the following kind of usage must compile and work as expected:

```cpp
std::array<int, 3> container{1,2,3};
std::array<int, 3> a{1,2,3};
std::vector<int> b{0,1,2};
std::list<int> c{4,5,6};

CHECK_THAT(container, EqualsRange(a) || EqualsRange(b) || EqualsRange(c));
```

Expected behavior:
- A generic matcher (derived from `Catch::MatcherGenericBase`) can be used with `CHECK_THAT`/`REQUIRE_THAT` against different argument types, as long as its templated `match` can be instantiated for that argument.
- Generic matchers can be combined with `&&`, `||`, and `!`, including mixing generic matchers and classic `Catch::MatcherBase<T>` matchers in the same expression.
- Existing matchers derived from `Catch::MatcherBase<T>` continue to work unchanged and remain composable.
- The generic matcher mechanism must address the const-reference limitation from the reported issue: matchers should no longer force the matched value to be accepted only as `const T&` in a way that blocks matching non-const-iterable views/ranges; users should be able to write matchers that accept inputs in a way compatible with non-const iteration (e.g., by value or non-const reference) when needed.

Actual current behavior to fix:
- Matchers are type-locked to `T` through `MatcherBase<T>` and thus cannot naturally compare different container/range types.
- Composable matchers require a shared `MatcherBase<T>`, making it difficult to author reusable range/container matchers that work across multiple types.
- Matching fails (at compile time) for inputs that cannot be bound as `const&` due to internal mutation during iteration, because the matcher interface requires `match(T const&)` for a fixed `T`.

After the change, users should be able to implement and compose generic matchers via `Catch::MatcherGenericBase` and use them seamlessly with `CHECK_THAT`/`REQUIRE_THAT`, including for heterogeneous container/range comparisons and for non-const-iterable view types.
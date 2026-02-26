Catch2’s composable matchers are currently tied to a single concrete argument type via `MatcherBase<T>`. This prevents writing matchers that can be applied to different, but compatible, argument types. For example, an equality-style matcher can compare `std::vector<int>` to `std::vector<int>`, but cannot be used to compare `std::vector<int>` to `std::array<int, N>` or `std::list<int>` even when the comparison logic is well-defined.

This limitation also shows up when trying to match values that cannot be treated as const during matching (e.g., certain range-v3 views that mutate internal state during iteration). Because matchers commonly accept the matched value as `T const&`, such non-const-iterable values cannot be used with `CHECK_THAT`/`REQUIRE_THAT`.

The matcher framework should support “generic” matchers whose `match` operation can be templated on the argument type, without breaking existing `MatcherBase<T>` matchers and while still allowing composition with `&&`, `||`, and `!` across both generic and non-generic matchers.

After the change, users should be able to write a matcher by inheriting from `Catch::MatcherGenericBase` and providing a templated `match` function, e.g.

```cpp
template<typename Range>
struct EqualsRangeMatcher : Catch::MatcherGenericBase {
    EqualsRangeMatcher(Range const& range) : range{range} {}

    template<typename OtherRange>
    bool match(OtherRange const& other) const {
        using std::begin;
        using std::end;
        return std::equal(begin(range), end(range), begin(other), end(other));
    }

    std::string describe() const override {
        return "Equals: " + Catch::rangeToString(range);
    }

    Range const& range;
};

template<typename Range>
auto EqualsRange(Range const& range) -> EqualsRangeMatcher<Range> {
    return EqualsRangeMatcher<Range>{range};
}
```

And then use it with different container types in a single composed expression:

```cpp
std::array<int, 3> container{1,2,3};
std::array<int, 3> a{1,2,3};
std::vector<int> b{0,1,2};
std::list<int> c{4,5,6};

CHECK_THAT(container, EqualsRange(a) || EqualsRange(b) || EqualsRange(c));
```

`CHECK_THAT`/`REQUIRE_THAT` must accept such generic matchers, including when they are composed via `&&`, `||`, and `!` with other matchers. Existing matchers deriving from `MatcherBase<T>` must continue to work unchanged.

Additionally, matching should not require the matched value to be `const`-iterable in cases where the underlying matcher logic can operate on a non-const value. In other words, the matcher infrastructure should not inherently force the matched argument to be passed only as `T const&` when a generic matcher can instead match on a non-const reference/value as needed.

If the generic matcher is used in contexts that previously compiled with `MatcherBase<T>`, compilation should remain successful, and failure messages should still use the matcher’s `describe()` text for reporting.
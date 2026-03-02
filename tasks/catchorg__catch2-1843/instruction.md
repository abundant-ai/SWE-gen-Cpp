Catch2 matchers currently require their input argument type to be fixed and taken as a const reference via MatcherBase<T> (e.g., bool match(T const&) const). This causes two practical problems:

1) Some values cannot be matched because they are not const-iterable or otherwise require non-const access during matching (e.g., certain range/view types that mutate internal state while iterating). When users write REQUIRE_THAT(value, matcher), the framework forces the match operation to treat the value as const, making these types unusable with matchers.

2) Composable matchers are not reusable across different but compatible argument types. For example, an equality-style range matcher can compare std::vector<int> to std::vector<int>, but users cannot easily write a single composable matcher that can be applied to std::array<int, N>, std::vector<int>, std::list<int>, etc., and then freely combine it with other matchers using operator||, operator&&, and operator!.

Implement support for “generic” matchers that:

- Allow writing matchers that are generic over the matched argument type, e.g. a matcher type derived from Catch::MatcherGenericBase, whose match function is a function template such as:

  template <typename OtherRange>
  bool match(OtherRange const& other) const;

  and whose describe() function still returns a std::string.

- Preserve compatibility with existing non-generic matchers derived from Catch::MatcherBase<T> and ensure they keep working unchanged with REQUIRE_THAT / CHECK_THAT.

- Support composing generic matchers with other generic matchers and with non-generic matchers using logical combinators (operator||, operator&&, operator!). The composed matcher must still be usable in REQUIRE_THAT / CHECK_THAT and must produce a sensible description via describe().

- Address the “non-constable value” use case: it must be possible for the matcher framework to accept matching inputs in a way that does not require binding the matched value as const in all cases. In particular, users should be able to match values that cannot be iterated when const (e.g. stateful views) by providing an overload/path that does not force a const reference.

A motivating usage that should compile and work is:

  std::array<int, 3> container{1,2,3};
  std::array<int, 3> a{1,2,3};
  std::vector<int> b{0,1,2};
  std::list<int> c{4,5,6};

  CHECK_THAT(container, EqualsRange(a) || EqualsRange(b) || EqualsRange(c));

where EqualsRange returns a matcher that can match against multiple container/range types, and the logical composition (||) between these matchers is supported.

After the change, users should be able to define their own generic matchers by inheriting from Catch::MatcherGenericBase, implementing a templated match method, and using them in REQUIRE_THAT/CHECK_THAT and in compositions with ||/&&/! without needing to derive from MatcherBase<T> for every possible T. Existing matchers such as the exception matcher pattern (a class deriving from Catch::MatcherBase<SpecialException> overriding bool match(SpecialException const&) const) must continue to behave the same way.
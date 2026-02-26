When formatting values with the ostream formatter (e.g., calling fmt::format("{}", value)), the library determines whether a type is streamable by checking whether an expression like `std::declval<std::ostream&>() << std::declval<const T&>()` is well-formed. This detection currently breaks for pathological but legal user types that overload the comma operator in a way that interferes with unevaluated `decltype(...)`/SFINAE checks.

A concrete failure pattern is:
- A type provides an `operator<<` overload that returns a proxy object (not `std::ostream&`).
- There is also an overloaded `operator,` that can bind to that proxy object.

In this situation, simply forming the stream expression inside `decltype(...)` can accidentally involve the overloaded comma operator (because of how the detection idiom is written), causing `is_streamable`-style traits to produce the wrong result or fail to compile. As a result, code that should compile and format the object via ostream support either fails to compile, or incorrectly reports that the type is not streamable.

The library should be robust against overloaded comma operators during streamability detection. Formatting should compile and work normally for streamable types even if they define a comma operator that could match intermediate expressions. In particular, the streamability trait used by `fmt/ostream.h` should treat a type as streamable if `os << value` is valid, regardless of any unrelated `operator,` overloads.

Example scenario that must compile and work:
- Define `struct type_with_comma_op {};`
- Provide `template <typename U> void operator,(type_with_comma_op, const U&);`
- Provide `template <typename U> type_with_comma_op operator<<(U&, const Date&);`
Then formatting a `Date` via `fmt::format("{}", date)` must compile and produce the same output as streaming `date` into an ostream.

Fix the streamability detection (and any related `decltype`/SFINAE expressions used for ostream support) so that overloaded comma operators cannot affect the check. The expected behavior is that ostream-based formatting continues to work and compile in the presence of such comma-operator overloads, without requiring users to avoid these operators.
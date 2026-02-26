Add support for an “enum fusing” utility that allows users to combine two enum values into a single value suitable for use in a single switch/case chain, effectively emulating a 2D switch (switching on pairs of enums).

Currently, the library provides rich enum reflection utilities, but it lacks a way to reliably fuse two enum values (potentially with non-contiguous ranges and custom enum_range specializations) into a unique, deterministic fused representation. Users want to write code like:

```cpp
enum class A { ... };
enum class B { ... };

switch (magic_enum::enum_fuse(a, b)) {
  case magic_enum::enum_fuse(A::X, B::Y):
    // ...
    break;
  case magic_enum::enum_fuse(A::X, B::Z):
    // ...
    break;
}
```

Implement a public API that provides this functionality.

Requirements:
- Provide a function named `magic_enum::enum_fuse` that accepts two enum values (potentially different enum types) and returns a fused value that can be used in `switch` statements and compared for equality.
- `magic_enum::enum_fuse(e1, e2)` must produce the same result wherever it is called for the same pair `(e1, e2)`, and different pairs should not collide within the supported ranges.
- The fused result must be usable as a `case` label when both inputs are constant expressions.
- The implementation must work with enums that:
  - have negative and positive underlying values,
  - have non-contiguous values,
  - use customized ranges via `magic_enum::customize::enum_range<T>`.
- The function should remain well-formed only for enum types supported by the library (consistent with existing “supported enum” constraints).

The goal is to let users implement “2D switch/case” logic without manual encoding of pairs or ad-hoc hashing, while preserving compile-time usability and correctness across different enum ranges.
The library provides enum reflection utilities, but it currently lacks constexpr-friendly container types that let users build compile-time mappings and sets keyed by enum values and/or enum bitflags. Add a new set of container types under the public API namespace `magic_enum::containers` that can be used in constant evaluation and provide predictable behavior across C++17/C++20/C++23 compilers.

Implement constexpr containers that support:

- `magic_enum::containers::array<Enum, T>`: a dense, enum-indexed array for enums with a known sequence of values from `magic_enum::enum_values<Enum>()`. It must be constructible in a `constexpr` context from an initializer of per-enumerator values (in enumerator order) and provide element access by enum key (e.g., `operator[](Enum)`), iteration, and basic container APIs (`size()`, `begin()/end()`, `empty()` as appropriate). Element access should return `T&` for non-const containers and `T const&` for const containers, so that const-correctness is preserved.

- `magic_enum::containers::bitset<Enum>` and/or a flag-oriented container: for enums used as bitflags (e.g., values like 1,2,4,...) it should support compile-time set operations. It must allow setting/testing bits by enum value, bitwise combination of enum flags (when `magic_enum::bitwise_operators` are enabled), and should interoperate naturally with those operators.

- Stream output support for the containers when `magic_enum::ostream_operators` are used, so printing a container that stores values per enumerator produces stable, readable output (at minimum it must compile and not produce ambiguous overload errors).

The containers must handle edge cases:

- Empty enums (no enumerators): constructing containers for an empty enum should compile, `size()` should be 0, iteration should be valid, and element access APIs should not cause hard compilation errors unless actually invoked.

- Non-contiguous enums (e.g., 1,2,4): `containers::array` should still map based on `enum_values` order rather than assuming contiguous integer ranges.

- Constexpr usability: it must be possible to declare these containers as `constexpr` variables and use their APIs in constant evaluation (including element access and simple queries), without requiring dynamic allocation.

If the current behavior results in compilation failures (e.g., non-constexpr operations, missing overloads, incorrect constness, or inability to build mappings for bitflag enums), fix the implementation so these containers compile and behave correctly across the supported language standards.
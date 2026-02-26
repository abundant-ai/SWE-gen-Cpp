`magic_enum::enum_cast` does not correctly handle “flags” enums (bitmask-style enums intended to be combined with bitwise operators). When users pass a string that represents a combination of multiple enumerators, `enum_cast` should parse it into the corresponding combined value, but it currently fails (returns an empty optional) or interprets the input incorrectly.

Implement flags-aware casting so that `enum_cast<E>(...)` supports both single enumerator names and combinations for flag enums. The API should behave as follows:

- For non-flags enums, behavior must remain unchanged: `enum_cast<Color>("RED")` returns `Color::RED`, case-insensitive matching should still work when a comparator is provided, and unknown names (e.g. `"None"`) should return an empty optional.
- For flags enums, `enum_cast` should accept strings containing multiple flag names and return the bitwise-OR of the matched enumerator values.
- The function should tolerate common separators and whitespace between tokens (for example, inputs like `"A|B"`, `"A | B"`, and similar tokenized forms should be parsed as `E::A | E::B`).
- If any token in the combined string does not match a valid enumerator name for the enum type, the cast should fail and return an empty optional (rather than partially applying known tokens).
- Flags parsing should work with both `enum_cast<E>(std::string_view)` and the overload that accepts a custom character comparator (used for case-insensitive matching).
- References should be handled consistently with the existing API (e.g., `enum_cast<Color&>("GREEN")` continues to work for non-flags; similarly, flags enums should not regress reference handling where it is supported).

Example expected behavior (illustrative):

```cpp
enum class Perm { Read = 1, Write = 2, Exec = 4 };

auto p1 = magic_enum::enum_cast<Perm>("Read");
// p1 has value Perm::Read

auto p2 = magic_enum::enum_cast<Perm>("Read|Write");
// p2 has value static_cast<Perm>(1 | 2)

auto p3 = magic_enum::enum_cast<Perm>("read | write", case_insensitive_cmp);
// p3 has combined value

auto p4 = magic_enum::enum_cast<Perm>("Read|Nope");
// p4 is empty
```

Ensure the behavior is consistent at compile time where `enum_cast` is used in constant expressions (i.e., do not break existing `constexpr` use cases for simple casts), and do not regress existing `enum_cast` behavior for standard (non-bitmask) enums.
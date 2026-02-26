The library currently doesn’t provide a supported way to selectively disable specific enumerator values from being considered “valid” by the reflection utilities (e.g., iteration, counting, name/value mapping). Users need a customization point that can be specialized per-enum to mark certain values as invalid so they are excluded from magic_enum results.

Implement a new customization hook in the magic_enum::customize namespace:

```cpp
template <typename E>
constexpr bool magic_enum::customize::enum_valid(E value) noexcept;
```

It must be possible for users to specialize it for their enum type, for example:

```cpp
enum class Color { RED = -12, GREEN = 7, BLUE = 15 };

template <>
constexpr bool magic_enum::customize::enum_valid<Color>(Color value) noexcept {
  return value == Color::RED ? false : true;
}
```

Expected behavior: when enum_valid<E>(value) returns false for an enumerator, that enumerator must be treated as if it does not exist by the library’s public APIs. Concretely, the following behaviors should hold for any enum type E:

- magic_enum::enum_name(value) should behave as “no name” for disabled values (i.e., return an empty string_view / no result consistent with existing behavior for invalid values).
- magic_enum::enum_cast<E>(name) must not return disabled values, even if the name matches.
- magic_enum::enum_values<E>() must not include disabled enumerators.
- magic_enum::enum_entries<E>() must not include disabled enumerators.
- magic_enum::enum_count<E>() must reflect only enabled enumerators.
- Any other API that enumerates or validates enum values should respect enum_valid, so that disabled values are consistently excluded across the library.

Default behavior: if the user does not provide a specialization of magic_enum::customize::enum_valid for E, all values that are otherwise considered valid by the library should remain valid (i.e., the customization point should default to returning true).

The change should work together with existing customization points such as magic_enum::customize::enum_range<E> and magic_enum::customize::enum_name<E>(value), and should support different underlying enum types and ranges (including negative values and non-scoped enums).
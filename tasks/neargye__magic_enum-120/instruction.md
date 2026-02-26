Users need a single compile-time API that works for both regular enums and “flags” enums without duplicating code paths or instantiating both the flags and non-flags implementations.

Currently, if a project wants to process an enum type where some enums are treated as flags (power-of-two bitmask style) and others are not, they must write code with repeated `if constexpr (IsFlags)` branches to choose between `magic_enum::enum_*` and `magic_enum::flags::enum_*` APIs. This is awkward and, more importantly, users require that only the selected path is instantiated/evaluated at compile time (to avoid extra template instantiations and compile-time/memory overhead).

Add a unified “enum-flags” API that can be called with an enum type and a compile-time boolean indicating whether to use flags semantics. The unified API must expose equivalents of the existing APIs:

- `magic_enum::enum_count<E>()` and `magic_enum::flags::enum_count<E>()`
- `magic_enum::enum_names<E>()` and `magic_enum::flags::enum_names<E>()`
- `magic_enum::enum_value<E, I>()` and `magic_enum::flags::enum_value<E, I>()`

The unified API should allow code like:

```cpp
template <typename E, bool IsFlags>
constexpr auto n = magic_enum::enum_count<E, IsFlags>();

template <typename E, bool IsFlags>
constexpr auto names = magic_enum::enum_names<E, IsFlags>();

template <typename E, bool IsFlags, std::size_t I>
constexpr E v = magic_enum::enum_value<E, IsFlags, I>();
```

(or equivalent naming/placement, but the call site must not need to reference a separate `flags` namespace).

Expected behavior:
- When `IsFlags` is `false`, the unified API must behave identically to the existing non-flags API for all supported enum types (including customized names via `magic_enum::customize::enum_name`, customized ranges via `magic_enum::customize::enum_range`, and enums with negative/positive values).
- When `IsFlags` is `true`, the unified API must behave identically to the existing flags API for flags enums (including enums marked as flags via `magic_enum::customize::is_flags_enum<E>`, large underlying integer types such as `std::uint64_t`, and configurations that support aliases or non-ASCII enumerator names).
- Only the selected implementation must be instantiated: calling the unified API with `IsFlags=true` must not require the non-flags machinery for that enum type to be instantiated, and vice versa.

The change should preserve existing APIs (`magic_enum::enum_*` and `magic_enum::flags::enum_*`) while adding the unified overloads/templates so users can write one routine that works for either mode by passing `IsFlags` as a template parameter.